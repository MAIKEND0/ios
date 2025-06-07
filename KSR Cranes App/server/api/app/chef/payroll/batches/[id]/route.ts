// ==========================================================================
// 3. POST /api/app/chef/payroll/batches/[id]/approve/route.ts - Approve batch
// ==========================================================================

// This goes in a separate file: /api/app/chef/payroll/batches/[id]/approve/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

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

interface ApprovalRequest {
  approved_by: number;
  notes?: string;
}

// POST /api/app/chef/payroll/batches/[id]/approve - Approve payroll batch
export async function POST(
  request: NextRequest,
  context: { params: Promise<{ id: string }> }
): Promise<NextResponse<PayrollBatch | ErrorResponse>> {
  try {
    const params = await context.params;
    const batchId = parseInt(params.id);
    
    if (isNaN(batchId)) {
      return NextResponse.json(
        { error: "Invalid batch ID" },
        { status: 400 }
      );
    }

    console.log(`[Payroll Batches API] Approving batch ${batchId}`);

    const body: ApprovalRequest = await request.json();
    const { approved_by, notes } = body;

    if (!approved_by) {
      return NextResponse.json(
        { error: "approved_by is required" },
        { status: 400 }
      );
    }

    try {
      // Update batch status to approved
      const updatedBatch = await prisma.$queryRaw`
        UPDATE PayrollBatches 
        SET 
          status = 'approved',
          approved_by = ${approved_by},
          approved_at = ${new Date()},
          notes = COALESCE(${notes}, notes),
          updated_at = ${new Date()}
        WHERE id = ${batchId}
        RETURNING *
      ` as any[];

      if (updatedBatch.length === 0) {
        return NextResponse.json(
          { error: "Payroll batch not found" },
          { status: 404 }
        );
      }

      const batch = updatedBatch[0];

      console.log(`[Payroll Batches API] Batch ${batchId} approved successfully`);

      const response: PayrollBatch = {
        id: batch.id,
        batch_number: batch.batch_number,
        period_start: batch.period_start.toISOString(),
        period_end: batch.period_end.toISOString(),
        year: batch.year,
        period_number: batch.period_number,
        total_employees: batch.total_employees,
        total_hours: parseFloat(batch.total_hours),
        total_amount: parseFloat(batch.total_amount),
        status: batch.status,
        created_by: batch.created_by,
        created_at: batch.created_at.toISOString(),
        approved_by: batch.approved_by,
        approved_at: batch.approved_at?.toISOString(),
        sent_to_zenegy_at: batch.sent_to_zenegy_at?.toISOString(),
        zenegy_sync_status: batch.zenegy_sync_status,
        notes: batch.notes
      };

      return NextResponse.json(response, { status: 200 });

    } catch (dbError) {
      console.error("[Payroll Batches API] Database error:", dbError);
      return NextResponse.json(
        { 
          error: "Failed to approve payroll batch", 
          message: "Database error occurred while approving the batch",
          details: dbError instanceof Error ? dbError.message : "Database operation failed"
        }, 
        { status: 500 }
      );
    }

  } catch (error) {
    console.error("[Payroll Batches API] Approval error:", error);
    return NextResponse.json(
      { 
        error: "Failed to approve payroll batch", 
        message: "An error occurred while approving the payroll batch",
        details: error instanceof Error ? error.message : "Unknown error"
      }, 
      { status: 500 }
    );
  }
}