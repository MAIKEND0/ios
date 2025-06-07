// /api/app/chef/leave/balance/recalculate - Recalculate leave balances based on approved requests
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

// POST /api/app/chef/leave/balance/recalculate - Recalculate all leave balances
export async function POST(request: Request) {
  try {
    const body = await request.json();
    
    // Basic security - require confirmation
    if (body.confirm !== "RECALCULATE_BALANCES") {
      return NextResponse.json({
        error: "Missing confirmation. Send { confirm: 'RECALCULATE_BALANCES' }"
      }, { status: 400 });
    }

    // Get all leave balances and recalculate them
    const allBalances = await prisma.leaveBalance.findMany({
      include: {
        Employees: {
          select: { name: true }
        }
      }
    });

    let updatedCount = 0;

    for (const balance of allBalances) {
      // Calculate sick days used for this employee/year
      const sickDaysUsed = await prisma.leaveRequests.aggregate({
        where: {
          employee_id: balance.employee_id,
          type: 'SICK',
          status: 'APPROVED',
          start_date: {
            gte: new Date(`${balance.year}-01-01`),
            lt: new Date(`${balance.year + 1}-01-01`)
          }
        },
        _sum: { total_days: true }
      });

      // Calculate vacation days used for this employee/year
      const vacationDaysUsed = await prisma.leaveRequests.aggregate({
        where: {
          employee_id: balance.employee_id,
          type: 'VACATION',
          status: 'APPROVED',
          start_date: {
            gte: new Date(`${balance.year}-01-01`),
            lt: new Date(`${balance.year + 1}-01-01`)
          }
        },
        _sum: { total_days: true }
      });

      // Calculate personal days used for this employee/year
      const personalDaysUsed = await prisma.leaveRequests.aggregate({
        where: {
          employee_id: balance.employee_id,
          type: 'PERSONAL',
          status: 'APPROVED',
          start_date: {
            gte: new Date(`${balance.year}-01-01`),
            lt: new Date(`${balance.year + 1}-01-01`)
          }
        },
        _sum: { total_days: true }
      });

      // Update the balance
      await prisma.leaveBalance.update({
        where: {
          employee_id_year: {
            employee_id: balance.employee_id,
            year: balance.year
          }
        },
        data: {
          sick_days_used: sickDaysUsed._sum.total_days || 0,
          vacation_days_used: vacationDaysUsed._sum.total_days || 0,
          personal_days_used: personalDaysUsed._sum.total_days || 0
        }
      });

      updatedCount++;
    }

    // Find employees with approved requests but no balance record
    const approvedRequests = await prisma.leaveRequests.findMany({
      where: {
        status: 'APPROVED'
      },
      select: {
        employee_id: true,
        start_date: true
      }
    });

    const missingBalances: Array<{employee_id: number, year: number}> = [];
    
    for (const request of approvedRequests) {
      const year = request.start_date.getFullYear();
      
      // Check if balance exists for this employee/year
      const existingBalance = await prisma.leaveBalance.findUnique({
        where: {
          employee_id_year: {
            employee_id: request.employee_id,
            year: year
          }
        }
      });
      
      if (!existingBalance && !missingBalances.find(mb => mb.employee_id === request.employee_id && mb.year === year)) {
        missingBalances.push({ employee_id: request.employee_id, year: year });
      }
    }

    // Create missing balance records
    for (const missing of missingBalances) {
      // Calculate totals for this employee/year
      const sickDaysUsed = await prisma.leaveRequests.aggregate({
        where: {
          employee_id: missing.employee_id,
          type: 'SICK',
          status: 'APPROVED',
          start_date: {
            gte: new Date(`${missing.year}-01-01`),
            lt: new Date(`${missing.year + 1}-01-01`)
          }
        },
        _sum: { total_days: true }
      });

      const vacationDaysUsed = await prisma.leaveRequests.aggregate({
        where: {
          employee_id: missing.employee_id,
          type: 'VACATION',
          status: 'APPROVED',
          start_date: {
            gte: new Date(`${missing.year}-01-01`),
            lt: new Date(`${missing.year + 1}-01-01`)
          }
        },
        _sum: { total_days: true }
      });

      const personalDaysUsed = await prisma.leaveRequests.aggregate({
        where: {
          employee_id: missing.employee_id,
          type: 'PERSONAL',
          status: 'APPROVED',
          start_date: {
            gte: new Date(`${missing.year}-01-01`),
            lt: new Date(`${missing.year + 1}-01-01`)
          }
        },
        _sum: { total_days: true }
      });

      await prisma.leaveBalance.create({
        data: {
          employee_id: missing.employee_id,
          year: missing.year,
          vacation_days_total: 25,
          vacation_days_used: vacationDaysUsed._sum.total_days || 0,
          sick_days_used: sickDaysUsed._sum.total_days || 0,
          personal_days_total: 5,
          personal_days_used: personalDaysUsed._sum.total_days || 0,
          carry_over_days: 0
        }
      });
    }

    // Get verification data
    const verification = await prisma.leaveBalance.findMany({
      include: {
        Employees: {
          select: { name: true }
        }
      },
      orderBy: [
        { Employees: { name: 'asc' } },
        { year: 'asc' }
      ]
    });

    return NextResponse.json({
      success: true,
      message: "Leave balances recalculated successfully",
      updated_balances: updatedCount,
      missing_balances_created: missingBalances.length,
      verification: verification
    });

  } catch (error: any) {
    console.error("Error recalculating leave balances:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// GET /api/app/chef/leave/balance/recalculate - Show current balance discrepancies
export async function GET(request: Request) {
  try {
    // Get all leave balances and check for discrepancies
    const allBalances = await prisma.leaveBalance.findMany({
      include: {
        Employees: {
          select: { name: true }
        }
      }
    });

    const discrepancies = [];

    for (const balance of allBalances) {
      // Calculate actual days from approved requests
      const sickDaysActual = await prisma.leaveRequests.aggregate({
        where: {
          employee_id: balance.employee_id,
          type: 'SICK',
          status: 'APPROVED',
          start_date: {
            gte: new Date(`${balance.year}-01-01`),
            lt: new Date(`${balance.year + 1}-01-01`)
          }
        },
        _sum: { total_days: true }
      });

      const vacationDaysActual = await prisma.leaveRequests.aggregate({
        where: {
          employee_id: balance.employee_id,
          type: 'VACATION',
          status: 'APPROVED',
          start_date: {
            gte: new Date(`${balance.year}-01-01`),
            lt: new Date(`${balance.year + 1}-01-01`)
          }
        },
        _sum: { total_days: true }
      });

      const personalDaysActual = await prisma.leaveRequests.aggregate({
        where: {
          employee_id: balance.employee_id,
          type: 'PERSONAL',
          status: 'APPROVED',
          start_date: {
            gte: new Date(`${balance.year}-01-01`),
            lt: new Date(`${balance.year + 1}-01-01`)
          }
        },
        _sum: { total_days: true }
      });

      const actualSick = sickDaysActual._sum.total_days || 0;
      const actualVacation = vacationDaysActual._sum.total_days || 0;
      const actualPersonal = personalDaysActual._sum.total_days || 0;

      // Check for discrepancies
      if (balance.sick_days_used !== actualSick || 
          balance.vacation_days_used !== actualVacation || 
          balance.personal_days_used !== actualPersonal) {
        discrepancies.push({
          name: balance.Employees?.name,
          employee_id: balance.employee_id,
          year: balance.year,
          balance_sick_days: balance.sick_days_used,
          actual_sick_days: actualSick,
          balance_vacation_days: balance.vacation_days_used,
          actual_vacation_days: actualVacation,
          balance_personal_days: balance.personal_days_used,
          actual_personal_days: actualPersonal
        });
      }
    }

    // Find missing balances (same logic as in POST)
    const approvedRequests = await prisma.leaveRequests.findMany({
      where: { status: 'APPROVED' },
      include: {
        Employees_LeaveRequests_employee_idToEmployees: {
          select: { name: true }
        }
      }
    });

    const missingBalances = [];
    const checkedCombinations = new Set();

    for (const request of approvedRequests) {
      const year = request.start_date.getFullYear();
      const key = `${request.employee_id}-${year}`;
      
      if (!checkedCombinations.has(key)) {
        checkedCombinations.add(key);
        
        const existingBalance = await prisma.leaveBalance.findUnique({
          where: {
            employee_id_year: {
              employee_id: request.employee_id,
              year: year
            }
          }
        });
        
        if (!existingBalance) {
          const requestCount = await prisma.leaveRequests.count({
            where: {
              employee_id: request.employee_id,
              status: 'APPROVED',
              start_date: {
                gte: new Date(`${year}-01-01`),
                lt: new Date(`${year + 1}-01-01`)
              }
            }
          });

          missingBalances.push({
            name: request.Employees_LeaveRequests_employee_idToEmployees?.name,
            employee_id: request.employee_id,
            year: year,
            approved_requests: requestCount
          });
        }
      }
    }

    return NextResponse.json({
      discrepancies: discrepancies,
      missing_balances: missingBalances,
      needs_recalculation: (discrepancies as any[]).length > 0 || (missingBalances as any[]).length > 0
    });

  } catch (error: any) {
    console.error("Error checking leave balance discrepancies:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}