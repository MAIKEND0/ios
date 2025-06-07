// ==========================================================================
// 1. GET /api/app/chef/payroll/batches/route.ts - Fetch all payroll batches
// ==========================================================================

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// Explicit cache configuration for Next.js 15
export const dynamic = 'force-dynamic';

// Types matching iOS app expectations
interface PayrollBatch {
  id: number;
  batch_number: string;
  period_start: string; // ISO date string
  period_end: string; // ISO date string
  year: number;
  period_number: number;
  total_employees: number;
  total_hours: number;
  total_amount: number;
  status: string;
  created_by: number;
  created_at: string; // ISO date string
  approved_by?: number;
  approved_at?: string; // ISO date string
  sent_to_zenegy_at?: string; // ISO date string
  zenegy_sync_status?: string;
  notes?: string;
}

interface ErrorResponse {
  error: string;
  message?: string;
  details?: any;
}

// GET /api/app/chef/payroll/batches - Fetch all payroll batches
export async function GET(request: NextRequest): Promise<NextResponse<PayrollBatch[] | ErrorResponse>> {
  try {
    console.log("[Payroll Batches API] GET request received");
    
    const { searchParams } = new URL(request.url);
    const status = searchParams.get('status');
    const year = searchParams.get('year');
    const limit = searchParams.get('limit');

    // Check if PayrollBatches table exists
    let batches: PayrollBatch[] = [];
    
    try {
      // Try to query PayrollBatches table
      const whereClause: any = {};
      
      if (status) {
        whereClause.status = status;
      }
      
      if (year) {
        whereClause.year = parseInt(year);
      }

      const batchesResult = await prisma.$queryRaw`
        SELECT 
          id,
          batch_number,
          period_start,
          period_end,
          year,
          period_number,
          total_employees,
          total_hours,
          total_amount,
          status,
          created_by,
          created_at,
          approved_by,
          approved_at,
          sent_to_zenegy_at,
          zenegy_sync_status,
          notes
        FROM PayrollBatches 
        WHERE (${status ? `status = '${status}'` : '1=1'})
          AND (${year ? `year = ${parseInt(year)}` : '1=1'})
        ORDER BY created_at DESC
        ${limit ? `LIMIT ${parseInt(limit)}` : ''}
      ` as any[];

      batches = batchesResult.map((batch: any) => ({
        id: batch.id,
        batch_number: batch.batch_number,
        period_start: batch.period_start.toISOString(),
        period_end: batch.period_end.toISOString(),
        year: batch.year,
        period_number: batch.period_number,
        total_employees: batch.total_employees,
        total_hours: parseFloat(batch.total_hours || '0'),
        total_amount: parseFloat(batch.total_amount || '0'),
        status: batch.status,
        created_by: batch.created_by,
        created_at: batch.created_at.toISOString(),
        approved_by: batch.approved_by,
        approved_at: batch.approved_at?.toISOString(),
        sent_to_zenegy_at: batch.sent_to_zenegy_at?.toISOString(),
        zenegy_sync_status: batch.status,
        notes: batch.notes
      }));

      console.log(`[Payroll Batches API] Found ${batches.length} batches`);
      
    } catch (error) {
      console.log("[Payroll Batches API] PayrollBatches table not found, returning empty array");
      batches = [];
    }
    
    return NextResponse.json(batches, { 
      status: 200,
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
      }
    });
  } catch (error) {
    console.error("[Payroll Batches API] GET error:", error);
    return NextResponse.json(
      { 
        error: "Failed to fetch payroll batches", 
        message: "An error occurred while fetching payroll batch data",
        details: error instanceof Error ? error.message : "Unknown error"
      }, 
      { status: 500 }
    );
  }
}

// ==========================================================================
// 2. POST /api/app/chef/payroll/batches/route.ts - Create new payroll batch
// ==========================================================================

interface CreateBatchRequest {
  period_start: string; // ISO date string
  period_end: string; // ISO date string
  work_entry_ids: number[];
  notes?: string;
}

// POST /api/app/chef/payroll/batches - Create new payroll batch
export async function POST(request: NextRequest): Promise<NextResponse<PayrollBatch | ErrorResponse>> {
  try {
    console.log("[Payroll Batches API] POST request received");
    
    const body: CreateBatchRequest = await request.json();
    const { period_start, period_end, work_entry_ids, notes } = body;

    // Validate request
    if (!period_start || !period_end || !work_entry_ids || work_entry_ids.length === 0) {
      return NextResponse.json(
        { error: "Missing required fields: period_start, period_end, work_entry_ids" },
        { status: 400 }
      );
    }

    const startDate = new Date(period_start);
    const endDate = new Date(period_end);
    const year = startDate.getFullYear();
    
    // Calculate period number (bi-weekly periods)
    const weekOfYear = Math.ceil((startDate.getTime() - new Date(year, 0, 1).getTime()) / (7 * 24 * 60 * 60 * 1000));
    const periodNumber = Math.ceil(weekOfYear / 2);

    // Generate batch number
    const batchNumber = `${year}-${String(periodNumber).padStart(2, '0')}`;

    console.log(`[Payroll Batches API] Creating batch ${batchNumber} with ${work_entry_ids.length} work entries`);

    // Fetch work entries to calculate totals
    const workEntries = await prisma.workEntries.findMany({
      where: {
        entry_id: { in: work_entry_ids },
        confirmation_status: 'confirmed',
        isActive: true,
        sent_to_payroll: false
      },
      include: {
        Employees: {
          select: {
            employee_id: true,
            name: true
          }
        }
      }
    });

    if (workEntries.length === 0) {
      return NextResponse.json(
        { error: "No valid work entries found for the provided IDs" },
        { status: 400 }
      );
    }

    // Calculate totals
    let totalHours = 0;
    const uniqueEmployees = new Set<number>();
    const defaultHourlyRate = 450; // DKK per hour

    for (const entry of workEntries) {
      uniqueEmployees.add(entry.employee_id);
      
      if (entry.start_time && entry.end_time) {
        const startTime = new Date(entry.start_time);
        const endTime = new Date(entry.end_time);
        const totalMinutes = (endTime.getTime() - startTime.getTime()) / (1000 * 60);
        const pauseMinutes = entry.pause_minutes || 0;
        const workedMinutes = Math.max(0, totalMinutes - pauseMinutes);
        const workedHours = workedMinutes / 60;
        
        totalHours += workedHours;
      }
    }

    const totalAmount = totalHours * defaultHourlyRate;

    try {
      // Create payroll batch using Prisma ORM
      const batch = await prisma.payrollBatches.create({
        data: {
          batch_number: batchNumber,
          period_start: startDate,
          period_end: endDate,
          year: year,
          period_number: periodNumber,
          total_employees: uniqueEmployees.size,
          total_hours: totalHours,
          status: 'draft',
          created_by: 1,
          notes: notes || null
        }
      });

      // Mark work entries as sent to payroll
      await prisma.workEntries.updateMany({
        where: {
          entry_id: { in: work_entry_ids }
        },
        data: {
          sent_to_payroll: true
        }
      });

      console.log(`[Payroll Batches API] Created batch ${batchNumber} successfully`);

      const response: PayrollBatch = {
        id: batch.id,
        batch_number: batch.batch_number,
        period_start: batch.period_start.toISOString(),
        period_end: batch.period_end.toISOString(),
        year: batch.year,
        period_number: batch.period_number,
        total_employees: batch.total_employees,
        total_hours: parseFloat(batch.total_hours.toString()),
        total_amount: totalAmount,
        status: batch.status,
        created_by: batch.created_by,
        created_at: batch.created_at.toISOString(),
        approved_by: batch.approved_by,
        approved_at: batch.approved_at?.toISOString(),
        sent_to_zenegy_at: batch.sent_to_zenegy_at?.toISOString(),
        zenegy_sync_status: batch.status,
        notes: batch.notes
      };

      return NextResponse.json(response, { status: 201 });

    } catch (dbError) {
      console.error("[Payroll Batches API] Database error:", dbError);
      return NextResponse.json(
        { 
          error: "Failed to create payroll batch", 
          message: "Database error occurred while creating the batch",
          details: dbError instanceof Error ? dbError.message : "Database operation failed"
        }, 
        { status: 500 }
      );
    }

  } catch (error) {
    console.error("[Payroll Batches API] POST error:", error);
    return NextResponse.json(
      { 
        error: "Failed to create payroll batch", 
        message: "An error occurred while creating the payroll batch",
        details: error instanceof Error ? error.message : "Unknown error"
      }, 
      { status: 500 }
    );
  }
}