// src/app/api/app/chef/payroll/dashboard/stats/route.ts - COMPLETE VERSION WITH ID FIXES

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

// Explicit cache configuration for Next.js 15
export const dynamic = 'force-dynamic';

// Types matching iOS app expectations
interface PayrollDashboardStats {
  pending_hours: number;
  ready_employees: number;
  total_amount: number;
  active_batches: number;
  current_period: PayrollPeriod;
  period_progress: number;
  last_updated: string; // ISO date string
}

interface PayrollPeriod {
  id: number;
  year: number;
  period_number: number;
  start_date: string; // ISO date string
  end_date: string; // ISO date string
  status: string;
  week_number: number;
  display_name: string;
  week_display_name: string;
  is_current_period: boolean;
}

interface PayrollPendingItem {
  id: number; // FIXED: Added missing id field
  title: string;
  subtitle: string;
  priority: string; // 'high' | 'medium' | 'low'
  time_ago: string;
  requires_action: boolean;
  icon: string;
  related_id?: number;
  type: string;
}

interface PayrollActivity {
  id: number; // FIXED: Added missing id field
  title: string;
  description: string;
  timestamp: string; // ISO date string
  type: string;
  related_id?: number;
}

interface ErrorResponse {
  error: string;
  message?: string;
  details?: any;
}

// Helper function to get date ranges
function getDateRanges() {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay() + 1); // Monday
  const endOfWeek = new Date(startOfWeek);
  endOfWeek.setDate(startOfWeek.getDate() + 6); // Sunday
  const startOfYear = new Date(now.getFullYear(), 0, 1);

  return {
    now,
    startOfMonth,
    startOfLastMonth,
    endOfLastMonth,
    startOfWeek,
    endOfWeek,
    startOfYear
  };
}

// Helper function to calculate week number
function getWeekNumber(date: Date): number {
  const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
  const pastDaysOfYear = (date.getTime() - firstDayOfYear.getTime()) / 86400000;
  return Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7);
}

// GET /api/app/chef/payroll/dashboard/stats - Fetch payroll dashboard statistics
export async function GET(request: NextRequest): Promise<NextResponse<{
  overview: PayrollDashboardStats;
  pending_items: PayrollPendingItem[];
  recent_activity: PayrollActivity[];
} | ErrorResponse>> {
  try {
    console.log("[Payroll Dashboard API] GET request received");
    
    const dateRanges = getDateRanges();

    // ===== 1. FETCH CONFIRMED WORK ENTRIES (READY FOR PAYROLL) =====
    
    const confirmedWorkEntries = await prisma.workEntries.findMany({
      where: {
        confirmation_status: 'confirmed',
        isActive: true,
        start_time: { not: null },
        end_time: { not: null },
        sent_to_payroll: false // Filter only entries NOT sent to payroll yet
      },
      include: {
        Employees: {
          select: {
            employee_id: true,
            name: true,
            email: true
          }
        },
        Tasks: {
          include: {
            Projects: {
              select: {
                project_id: true,
                title: true,
                customer_id: true,
                Customers: {
                  select: {
                    customer_id: true,
                    name: true
                  }
                }
              }
            }
          }
        }
      },
      orderBy: { work_date: 'desc' }
    });

    console.log(`[Payroll Dashboard API] Found ${confirmedWorkEntries.length} confirmed work entries`);

    // ===== 2. CALCULATE HOURS AND AMOUNTS =====
    
    let totalHours = 0;
    let totalAmount = 0;
    const uniqueEmployees = new Set<number>();
    const defaultHourlyRate = 450; // DKK per hour - could be made configurable

    for (const entry of confirmedWorkEntries) {
      uniqueEmployees.add(entry.employee_id);
      
      if (entry.start_time && entry.end_time) {
        const startTime = new Date(entry.start_time);
        const endTime = new Date(entry.end_time);
        const totalMinutes = (endTime.getTime() - startTime.getTime()) / (1000 * 60);
        const pauseMinutes = entry.pause_minutes || 0;
        const workedMinutes = Math.max(0, totalMinutes - pauseMinutes);
        const workedHours = workedMinutes / 60;
        
        totalHours += workedHours;
        totalAmount += workedHours * defaultHourlyRate;
      }
    }

    // ===== 3. CHECK FOR PAYROLL BATCHES (IF TABLE EXISTS) =====
    
    let activeBatches = 0;
    try {
      // Try to query PayrollBatches table if it exists
      const batchesResult = await prisma.$queryRaw`
        SELECT COUNT(*) as count FROM PayrollBatches 
        WHERE status IN ('draft', 'ready_for_approval', 'approved', 'sent_to_zenegy')
      ` as any[];
      
      activeBatches = parseInt(batchesResult[0]?.count || '0');
      console.log(`[Payroll Dashboard API] Found ${activeBatches} active payroll batches`);
    } catch (error) {
      console.log("[Payroll Dashboard API] PayrollBatches table not found, using mock data");
      activeBatches = 0; // No active batches if table doesn't exist
    }

    // ===== 4. CREATE CURRENT PERIOD =====
    
    const currentPeriod: PayrollPeriod = {
      id: 1,
      year: dateRanges.now.getFullYear(),
      period_number: Math.ceil(getWeekNumber(dateRanges.now) / 2), // Bi-weekly periods
      start_date: dateRanges.startOfWeek.toISOString(),
      end_date: dateRanges.endOfWeek.toISOString(),
      status: 'active',
      week_number: getWeekNumber(dateRanges.now),
      display_name: `Period ${Math.ceil(getWeekNumber(dateRanges.now) / 2)}/${dateRanges.now.getFullYear()}`,
      week_display_name: `Week ${getWeekNumber(dateRanges.now)} of 2`,
      is_current_period: true
    };

    // Calculate period progress (how far into the current week we are)
    const dayOfWeek = dateRanges.now.getDay();
    const periodProgress = dayOfWeek === 0 ? 1.0 : dayOfWeek / 7; // Sunday = 100%

    // ===== 5. BUILD DASHBOARD STATS =====
    
    const dashboardStats: PayrollDashboardStats = {
      pending_hours: Math.round(totalHours),
      ready_employees: uniqueEmployees.size,
      total_amount: totalAmount,
      active_batches: activeBatches,
      current_period: currentPeriod,
      period_progress: Math.round(periodProgress * 100) / 100,
      last_updated: dateRanges.now.toISOString()
    };

    // ===== 6. GENERATE PENDING ITEMS WITH IDs =====
    
    const pendingItems: PayrollPendingItem[] = [];
    let itemId = 1; // FIXED: Add counter for unique IDs

    // High priority: Many pending hours
    if (totalHours > 100) {
      pendingItems.push({
        id: itemId++, // FIXED: Add missing id field
        title: `${Math.round(totalHours)} hours pending review`,
        subtitle: `From ${uniqueEmployees.size} employees ready for payroll`,
        priority: 'high',
        time_ago: '2h ago',
        requires_action: true,
        icon: 'clock.badge.exclamationmark',
        type: 'hours_review'
      });
    }

    // Medium priority: Period deadline approaching
    if (periodProgress > 0.8) {
      const daysRemaining = 7 - dayOfWeek;
      pendingItems.push({
        id: itemId++, // FIXED: Add missing id field
        title: 'Period deadline approaching',
        subtitle: `${daysRemaining} days remaining in current period`,
        priority: 'medium',
        time_ago: '1d ago',
        requires_action: false,
        icon: 'calendar.badge.exclamationmark',
        type: 'period_deadline'
      });
    }

    // Low priority: Ready for batch creation
    if (uniqueEmployees.size >= 1) { // Lower threshold for testing
      pendingItems.push({
        id: itemId++, // FIXED: Add missing id field
        title: 'Ready for batch creation',
        subtitle: `${uniqueEmployees.size} employees ready for payroll batch`,
        priority: 'low',
        time_ago: '4h ago',
        requires_action: true,
        icon: 'plus.rectangle.on.folder',
        type: 'batch_creation'
      });
    }

    // ===== 7. GENERATE RECENT ACTIVITY WITH IDs =====
    
    const recentActivity: PayrollActivity[] = [];
    let activityId = 1; // FIXED: Add counter for activity IDs

    // Recent work entries confirmed
    const recentConfirmed = confirmedWorkEntries
      .filter(entry => {
        const entryDate = new Date(entry.work_date);
        const oneDayAgo = new Date(dateRanges.now.getTime() - 24 * 60 * 60 * 1000);
        return entryDate >= oneDayAgo;
      })
      .slice(0, 3);

    for (const entry of recentConfirmed) {
      recentActivity.push({
        id: activityId++, // FIXED: Add missing id field
        title: 'Hours confirmed',
        description: `${entry.Employees.name} - ${entry.Tasks.title} (${entry.Tasks.Projects?.title})`,
        timestamp: new Date(entry.work_date.getTime() + 17 * 60 * 60 * 1000).toISOString(), // 5 PM
        type: 'hours_confirmed',
        related_id: entry.entry_id
      });
    }

    // Mock recent batch activity if no real entries
    if (recentActivity.length === 0) {
      recentActivity.push({
        id: activityId++, // FIXED: Add missing id field
        title: 'System ready',
        description: 'Payroll system is ready for confirmed hours processing',
        timestamp: new Date(dateRanges.now.getTime() - 2 * 60 * 60 * 1000).toISOString(), // 2h ago
        type: 'system_ready'
      });
    }

    // Sort activity by timestamp (newest first)
    recentActivity.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

    const response = {
      overview: dashboardStats,
      pending_items: pendingItems,
      recent_activity: recentActivity.slice(0, 5) // Limit to 5 most recent
    };

    console.log(`[Payroll Dashboard API] Generated dashboard stats:`, {
      pending_hours: dashboardStats.pending_hours,
      ready_employees: dashboardStats.ready_employees,
      total_amount: dashboardStats.total_amount,
      active_batches: dashboardStats.active_batches,
      pending_items_count: pendingItems.length,
      recent_activity_count: recentActivity.length
    });
    
    return NextResponse.json(response, { 
      status: 200,
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
      }
    });
  } catch (error) {
    console.error("[Payroll Dashboard API] GET error:", error);
    return NextResponse.json(
      { 
        error: "Failed to fetch payroll dashboard statistics", 
        message: "An error occurred while fetching payroll dashboard data",
        details: error instanceof Error ? error.message : "Unknown error"
      }, 
      { status: 500 }
    );
  }
}