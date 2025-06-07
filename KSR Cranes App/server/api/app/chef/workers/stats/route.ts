// /api/app/chef/workers/stats - Statystyki ogólne pracowników
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// GET /api/app/chef/workers/stats - Ogólne statystyki pracowników
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const includeInactive = searchParams.get("include_inactive") === "true";

    // Pobranie wszystkich pracowników (nie chef/system)
    const whereClause: any = {
      role: {
        in: ['arbejder', 'byggeleder'] as any
      }
    };

    if (!includeInactive) {
      whereClause.is_activated = true;
    }

    const workers = await prisma.employees.findMany({
      where: whereClause,
      select: {
        employee_id: true,
        name: true,
        role: true,
        operator_normal_rate: true,
        is_activated: true,
        created_at: true
      }
    });

    // Obliczanie statystyk
    const totalWorkers = workers.length;
    const activeWorkers = workers.filter(w => w.is_activated).length;
    const inactiveWorkers = totalWorkers - activeWorkers;

    // Średnia stawka godzinowa
    const totalRates = workers.reduce((sum, w) => sum + Number(w.operator_normal_rate || 0), 0);
    const averageHourlyRate = totalWorkers > 0 ? totalRates / totalWorkers : 0;

    // Ostatnie zatrudnienia (ostatnie 30 dni)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const recentHires = workers
      .filter(w => w.created_at && w.created_at >= thirtyDaysAgo)
      .map(w => ({
        worker_id: w.employee_id,
        name: w.name,
        hire_date: w.created_at,
        employment_type: mapRoleToEmploymentType(w.role),
        days_since_hire: Math.floor((Date.now() - (w.created_at?.getTime() || 0)) / (1000 * 60 * 60 * 24))
      }));

    // Top performers (mock data - w przyszłości z rzeczywistych statystyk)
    const topPerformers = workers
      .slice(0, 5)
      .map(w => ({
        worker_id: w.employee_id,
        name: w.name,
        hours_this_month: Math.floor(Math.random() * 160) + 80, // Mock data
        efficiency_rating: 0.85 + Math.random() * 0.15, // Mock data
        projects_completed: Math.floor(Math.random() * 5) + 1 // Mock data
      }));

    // Breakdown by employment type
    const employmentTypeBreakdown = [
      {
        employment_type: "fuld_tid",
        count: workers.filter(w => w.role === 'arbejder').length,
        percentage: totalWorkers > 0 ? (workers.filter(w => w.role === 'arbejder').length / totalWorkers) * 100 : 0
      },
      {
        employment_type: "byggeleder",
        count: workers.filter(w => w.role === 'byggeleder').length,
        percentage: totalWorkers > 0 ? (workers.filter(w => w.role === 'byggeleder').length / totalWorkers) * 100 : 0
      }
    ];

    // Status breakdown
    const statusBreakdown = [
      {
        status: "aktiv",
        count: activeWorkers,
        percentage: totalWorkers > 0 ? (activeWorkers / totalWorkers) * 100 : 0
      },
      {
        status: "inaktiv",
        count: inactiveWorkers,
        percentage: totalWorkers > 0 ? (inactiveWorkers / totalWorkers) * 100 : 0
      }
    ];

    const stats = {
      total_workers: totalWorkers,
      active_workers: activeWorkers,
      inactive_workers: inactiveWorkers,
      total_hours_this_month: 0, // TODO: calculate from WorkEntries
      total_earnings_this_month: 0, // TODO: calculate from WorkEntries
      average_hourly_rate: averageHourlyRate,
      top_performers: topPerformers,
      employment_type_breakdown: employmentTypeBreakdown,
      status_breakdown: statusBreakdown,
      recent_hires: recentHires
    };

    return NextResponse.json(stats);
  } catch (error: any) {
    console.error("Error fetching worker stats:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// Helper function
function mapRoleToEmploymentType(role: string): string {
  switch (role) {
    case 'arbejder': return 'fuld_tid';
    case 'byggeleder': return 'fuld_tid';
    default: return 'fuld_tid';
  }
}