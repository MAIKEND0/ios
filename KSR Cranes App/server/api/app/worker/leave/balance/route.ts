// /api/app/worker/leave/balance - Worker leave balance endpoints
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// GET /api/app/worker/leave/balance - Get worker's leave balance for specific year
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const employeeId = searchParams.get("employee_id");
    const year = searchParams.get("year") ? parseInt(searchParams.get("year")!) : new Date().getFullYear();

    if (!employeeId) {
      return NextResponse.json({ error: "Missing employee_id parameter" }, { status: 400 });
    }

    // Get leave balance for the specified year
    let leaveBalance = await prisma.leaveBalance.findUnique({
      where: {
        employee_id_year: {
          employee_id: parseInt(employeeId),
          year: year
        }
      }
    });

    // If no balance exists for this year, create one with defaults
    if (!leaveBalance) {
      // Check if employee exists
      const employee = await prisma.employees.findUnique({
        where: { employee_id: parseInt(employeeId) },
        select: { employee_id: true, name: true, role: true }
      });

      if (!employee) {
        return NextResponse.json({ error: "Employee not found" }, { status: 404 });
      }

      // Create default balance
      leaveBalance = await prisma.leaveBalance.create({
        data: {
          Employees: {
            connect: { employee_id: parseInt(employeeId) }
          },
          year: year,
          vacation_days_total: 25, // Danish standard
          vacation_days_used: 0,
          sick_days_used: 0,
          personal_days_total: 5,
          personal_days_used: 0,
          carry_over_days: 0
        }
      });
    }

    // Calculate remaining days
    const balanceWithRemaining = {
      ...leaveBalance,
      vacation_days_remaining: (leaveBalance.vacation_days_total! + leaveBalance.carry_over_days!) - leaveBalance.vacation_days_used!,
      personal_days_remaining: leaveBalance.personal_days_total! - leaveBalance.personal_days_used!,
      carry_over_expiring_soon: leaveBalance.carry_over_expires ? 
        new Date(leaveBalance.carry_over_expires) <= new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) : false // expires within 30 days
    };

    // Get recent leave requests affecting the balance
    const recentLeaveRequests = await prisma.leaveRequests.findMany({
      where: {
        employee_id: parseInt(employeeId),
        start_date: {
          gte: new Date(year, 0, 1), // January 1st of the year
          lte: new Date(year, 11, 31) // December 31st of the year
        },
        status: {
          in: ['APPROVED', 'PENDING']
        }
      },
      orderBy: { start_date: 'desc' },
      take: 10,
      select: {
        id: true,
        type: true,
        start_date: true,
        end_date: true,
        total_days: true,
        status: true
      }
    });

    return NextResponse.json({
      balance: balanceWithRemaining,
      recent_requests: recentLeaveRequests,
      year: year
    });

  } catch (error: any) {
    console.error("Error fetching leave balance:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}