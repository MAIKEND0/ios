// /api/app/chef/leave/calendar - Chef leave calendar view
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// GET /api/app/chef/leave/calendar - Get team leave calendar for date range
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get("start_date");
    const endDate = searchParams.get("end_date");
    
    if (!startDate || !endDate) {
      return NextResponse.json({ 
        error: "start_date and end_date parameters are required" 
      }, { status: 400 });
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    // Get all approved leave requests in the date range
    const leaveRequests = await prisma.leaveRequests.findMany({
      where: {
        status: 'APPROVED',
        OR: [
          {
            start_date: {
              gte: start,
              lte: end
            }
          },
          {
            end_date: {
              gte: start,
              lte: end
            }
          },
          {
            AND: [
              { start_date: { lte: start } },
              { end_date: { gte: end } }
            ]
          }
        ],
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
            role: true,
            profilePictureUrl: true
          }
        }
      },
      orderBy: {
        start_date: 'asc'
      }
    });

    // Group leave requests by date
    const calendar: Array<{
      date: string;
      employees_on_leave: Array<{
        employee_id: number;
        employee_name: string;
        leave_type: string;
        is_half_day: boolean;
        profile_picture_url: string | null;
      }>;
    }> = [];

    // Generate all dates in range
    const currentDate = new Date(start);
    while (currentDate <= end) {
      const dateString = currentDate.toISOString().split('T')[0];
      
      // Find employees on leave for this date
      const employeesOnLeave = leaveRequests
        .filter(req => {
          const reqStart = new Date(req.start_date);
          const reqEnd = new Date(req.end_date);
          return currentDate >= reqStart && currentDate <= reqEnd;
        })
        .map(req => ({
          employee_id: req.employee_id,
          employee_name: req.Employees_LeaveRequests_employee_idToEmployees?.name || 'Unknown',
          leave_type: req.type,
          is_half_day: req.half_day || false,
          profile_picture_url: req.Employees_LeaveRequests_employee_idToEmployees?.profilePictureUrl || null
        }));

      // Only include dates with employees on leave
      if (employeesOnLeave.length > 0) {
        calendar.push({
          date: dateString,
          employees_on_leave: employeesOnLeave
        });
      }

      // Move to next day
      currentDate.setDate(currentDate.getDate() + 1);
    }

    return NextResponse.json(calendar);

  } catch (error: any) {
    console.error("Error fetching leave calendar:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
