// /api/app/chef/leave/statistics - Chef leave statistics
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// GET /api/app/chef/leave/statistics - Get team leave statistics
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get("start_date");
    const endDate = searchParams.get("end_date");
    
    // Default to current year if no dates provided
    const currentYear = new Date().getFullYear();
    const start = startDate ? new Date(startDate) : new Date(currentYear, 0, 1);
    const end = endDate ? new Date(endDate) : new Date(currentYear, 11, 31);

    // Get all leave requests in date range for active employees
    const leaveRequests = await prisma.leaveRequests.findMany({
      where: {
        start_date: {
          gte: start,
          lte: end
        },
        Employees_LeaveRequests_employee_idToEmployees: {
          role: { in: ['arbejder', 'byggeleder'] },
          is_activated: true
        }
      },
      include: {
        Employees_LeaveRequests_employee_idToEmployees: {
          select: {
            employee_id: true,
            name: true,
            role: true
          }
        }
      }
    });

    // Calculate statistics
    const totalRequests = leaveRequests.length;
    const pendingRequests = leaveRequests.filter(req => req.status === 'PENDING').length;
    const approvedRequests = leaveRequests.filter(req => req.status === 'APPROVED').length;
    const rejectedRequests = leaveRequests.filter(req => req.status === 'REJECTED').length;

    // Team on leave today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const teamOnLeaveToday = leaveRequests.filter(req => 
      req.status === 'APPROVED' && 
      new Date(req.start_date) <= today && 
      new Date(req.end_date) >= today
    ).length;

    // Team on leave this week
    const startOfWeek = new Date(today);
    startOfWeek.setDate(today.getDate() - today.getDay());
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 6);
    
    const teamOnLeaveThisWeek = new Set(
      leaveRequests.filter(req => 
        req.status === 'APPROVED' && 
        new Date(req.start_date) <= endOfWeek && 
        new Date(req.end_date) >= startOfWeek
      ).map(req => req.employee_id)
    ).size;

    // Most common leave type
    const leaveTypeCounts = leaveRequests.reduce((acc, req) => {
      acc[req.type] = (acc[req.type] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);
    
    const mostCommonLeaveType = Object.entries(leaveTypeCounts)
      .sort(([,a], [,b]) => b - a)[0]?.[0] || null;

    // Average response time (simplified - time between created and approved/rejected)
    const processedRequests = leaveRequests.filter(req => 
      req.status !== 'PENDING' && req.approved_at
    );
    
    let averageResponseTimeHours = null;
    if (processedRequests.length > 0) {
      const totalResponseTime = processedRequests.reduce((sum, req) => {
        const created = new Date(req.created_at).getTime();
        const processed = new Date(req.approved_at!).getTime();
        return sum + (processed - created);
      }, 0);
      
      averageResponseTimeHours = Math.round(
        (totalResponseTime / processedRequests.length) / (1000 * 60 * 60)
      );
    }

    const statistics = {
      total_requests: totalRequests,
      pending_requests: pendingRequests,
      approved_requests: approvedRequests,
      rejected_requests: rejectedRequests,
      team_on_leave_today: teamOnLeaveToday,
      team_on_leave_this_week: teamOnLeaveThisWeek,
      most_common_leave_type: mostCommonLeaveType,
      average_response_time_hours: averageResponseTimeHours
    };

    return NextResponse.json(statistics);

  } catch (error: any) {
    console.error("Error fetching leave statistics:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
