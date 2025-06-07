// /api/app/chef/leave/balance - Chef leave balance management
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// GET /api/app/chef/leave/balance - Get all employees' leave balances
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const year = searchParams.get("year") ? parseInt(searchParams.get("year")!) : new Date().getFullYear();
    const employeeId = searchParams.get("employee_id");
    const lowBalance = searchParams.get("low_balance") === "true";

    // Build where clause
    const whereClause: any = {
      year: year,
      Employees: {
        role: { in: ['arbejder', 'byggeleder'] },
        is_activated: true
      }
    };

    if (employeeId) {
      whereClause.employee_id = parseInt(employeeId);
    }

    // Get leave balances
    const leaveBalances = await prisma.leaveBalance.findMany({
      where: whereClause,
      include: {
        Employees: {
          select: {
            employee_id: true,
            name: true,
            email: true,
            role: true,
            created_at: true
          }
        }
      },
      orderBy: { Employees: { name: 'asc' } }
    });

    // Calculate additional fields and filter if needed
    const enrichedBalances = leaveBalances.map(balance => {
      const vacationRemaining = (balance.vacation_days_total! + balance.carry_over_days!) - balance.vacation_days_used!;
      const personalRemaining = balance.personal_days_total! - balance.personal_days_used!;
      const carryOverExpiringSoon = balance.carry_over_expires ? 
        new Date(balance.carry_over_expires) <= new Date(Date.now() + 60 * 24 * 60 * 60 * 1000) : false; // expires within 60 days

      return {
        ...balance,
        vacation_days_remaining: vacationRemaining,
        personal_days_remaining: personalRemaining,
        carry_over_expiring_soon: carryOverExpiringSoon,
        vacation_utilization_percent: balance.vacation_days_total! > 0 
          ? Math.round((balance.vacation_days_used! / balance.vacation_days_total!) * 100)
          : 0,
        personal_utilization_percent: balance.personal_days_total! > 0
          ? Math.round((balance.personal_days_used! / balance.personal_days_total!) * 100)
          : 0,
        needs_attention: vacationRemaining < 5 || carryOverExpiringSoon || vacationRemaining > 20
      };
    }).filter(balance => {
      // Filter for low balance if requested
      if (lowBalance) {
        return balance.vacation_days_remaining < 10 || balance.carry_over_expiring_soon;
      }
      return true;
    });

    // Summary statistics
    const summary = {
      total_employees: enrichedBalances.length,
      total_vacation_days_allocated: enrichedBalances.reduce((sum, b) => sum + b.vacation_days_total!, 0),
      total_vacation_days_used: enrichedBalances.reduce((sum, b) => sum + b.vacation_days_used!, 0),
      total_vacation_days_remaining: enrichedBalances.reduce((sum, b) => sum + b.vacation_days_remaining, 0),
      employees_with_low_balance: enrichedBalances.filter(b => b.vacation_days_remaining < 10).length,
      employees_with_expiring_carryover: enrichedBalances.filter(b => b.carry_over_expiring_soon).length,
      average_vacation_utilization: enrichedBalances.length > 0
        ? Math.round(enrichedBalances.reduce((sum, b) => sum + b.vacation_utilization_percent, 0) / enrichedBalances.length)
        : 0
    };

    return NextResponse.json({
      balances: enrichedBalances,
      summary: summary,
      year: year
    });

  } catch (error: any) {
    console.error("Error fetching leave balances:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PUT /api/app/chef/leave/balance - Adjust employee leave balance
export async function PUT(request: Request) {
  try {
    const body = await request.json();

    if (!body.employee_id || !body.year) {
      return NextResponse.json({
        error: "Missing required fields: employee_id, year"
      }, { status: 400 });
    }

    // Verify employee exists and is active
    const employee = await prisma.employees.findUnique({
      where: { employee_id: parseInt(body.employee_id) },
      select: { employee_id: true, name: true, role: true, is_activated: true }
    });

    if (!employee) {
      return NextResponse.json({ error: "Employee not found" }, { status: 404 });
    }

    if (!employee.is_activated) {
      return NextResponse.json({ error: "Employee is not active" }, { status: 400 });
    }

    // Find or create leave balance
    let leaveBalance = await prisma.leaveBalance.findUnique({
      where: {
        employee_id_year: {
          employee_id: parseInt(body.employee_id),
          year: parseInt(body.year)
        }
      }
    });

    // Prepare update data
    const updateData: any = {};
    
    if (body.vacation_days_total !== undefined) updateData.vacation_days_total = parseInt(body.vacation_days_total);
    if (body.vacation_days_used !== undefined) updateData.vacation_days_used = parseInt(body.vacation_days_used);
    if (body.personal_days_total !== undefined) updateData.personal_days_total = parseInt(body.personal_days_total);
    if (body.personal_days_used !== undefined) updateData.personal_days_used = parseInt(body.personal_days_used);
    if (body.sick_days_used !== undefined) updateData.sick_days_used = parseInt(body.sick_days_used);
    if (body.carry_over_days !== undefined) updateData.carry_over_days = parseInt(body.carry_over_days);
    if (body.carry_over_expires !== undefined) {
      updateData.carry_over_expires = body.carry_over_expires ? new Date(body.carry_over_expires) : null;
    }

    // Validate the data
    Object.entries(updateData).forEach(([key, value]) => {
      if (typeof value === 'number' && value < 0) {
        throw new Error(`${key} cannot be negative`);
      }
    });

    // Create or update the balance
    if (leaveBalance) {
      leaveBalance = await prisma.leaveBalance.update({
        where: {
          employee_id_year: {
            employee_id: parseInt(body.employee_id),
            year: parseInt(body.year)
          }
        },
        data: updateData,
        include: {
          Employees: {
            select: { name: true, email: true, role: true }
          }
        }
      });
    } else {
      leaveBalance = await prisma.leaveBalance.create({
        data: {
          Employees: {
            connect: { employee_id: parseInt(body.employee_id) }
          },
          year: parseInt(body.year),
          vacation_days_total: 25, // Danish standard
          vacation_days_used: 0,
          personal_days_total: 5,
          personal_days_used: 0,
          sick_days_used: 0,
          carry_over_days: 0,
          ...updateData
        },
        include: {
          Employees: {
            select: { name: true, email: true, role: true }
          }
        }
      });
    }

    // Calculate additional fields for response
    const enrichedBalance = {
      ...leaveBalance,
      vacation_days_remaining: (leaveBalance.vacation_days_total! + leaveBalance.carry_over_days!) - leaveBalance.vacation_days_used!,
      personal_days_remaining: leaveBalance.personal_days_total! - leaveBalance.personal_days_used!,
      vacation_utilization_percent: leaveBalance.vacation_days_total! > 0 
        ? Math.round((leaveBalance.vacation_days_used! / leaveBalance.vacation_days_total!) * 100)
        : 0
    };

    return NextResponse.json({
      success: true,
      balance: enrichedBalance,
      message: "Leave balance updated successfully"
    });

  } catch (error: any) {
    console.error("Error updating leave balance:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
