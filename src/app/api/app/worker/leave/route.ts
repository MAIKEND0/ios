// /api/app/worker/leave - Worker leave management endpoints
import { NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";

// GET /api/app/worker/leave - Get worker's own leave requests and balance
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const employeeId = searchParams.get("employee_id");
    const year = searchParams.get("year") ? parseInt(searchParams.get("year")!) : new Date().getFullYear();
    const status = searchParams.get("status");
    const limit = searchParams.get("limit") ? parseInt(searchParams.get("limit")!) : 50;
    const offset = searchParams.get("offset") ? parseInt(searchParams.get("offset")!) : 0;

    if (!employeeId) {
      return NextResponse.json({ error: "Missing employee_id parameter" }, { status: 400 });
    }

    // Build where clause for leave requests
    const whereClause: any = {
      employee_id: parseInt(employeeId)
    };

    if (status) {
      whereClause.status = status.toUpperCase();
    }

    // Get leave requests
    const leaveRequests = await prisma.leaveRequests.findMany({
      where: whereClause,
      include: {
        Employees_LeaveRequests_employee_idToEmployees: {
          select: { name: true, email: true }
        },
        Employees_LeaveRequests_approved_byToEmployees: {
          select: { name: true, email: true }
        }
      },
      orderBy: { created_at: 'desc' },
      skip: offset,
      take: limit
    });

    // Get leave balance for current year
    const leaveBalance = await prisma.leaveBalance.findUnique({
      where: {
        employee_id_year: {
          employee_id: parseInt(employeeId),
          year: year
        }
      }
    });

    // Calculate remaining days
    const balance = leaveBalance ? {
      ...leaveBalance,
      vacation_days_remaining: (leaveBalance.vacation_days_total! + leaveBalance.carry_over_days!) - leaveBalance.vacation_days_used!,
      personal_days_remaining: leaveBalance.personal_days_total! - leaveBalance.personal_days_used!
    } : null;

    // Get upcoming public holidays
    const upcomingHolidays = await prisma.publicHolidays.findMany({
      where: {
        date: {
          gte: new Date(),
          lte: new Date(new Date().setMonth(new Date().getMonth() + 3)) // next 3 months
        }
      },
      orderBy: { date: 'asc' }
    });

    return NextResponse.json({
      leave_requests: leaveRequests,
      leave_balance: balance,
      upcoming_holidays: upcomingHolidays,
      pagination: {
        limit,
        offset,
        total: await prisma.leaveRequests.count({ where: whereClause })
      }
    });

  } catch (error: any) {
    console.error("Error fetching worker leave data:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST /api/app/worker/leave - Submit new leave request
export async function POST(request: Request) {
  try {
    const body = await request.json();

    // Validate required fields
    if (!body.employee_id || !body.type || !body.start_date || !body.end_date) {
      return NextResponse.json({
        error: "Missing required fields: employee_id, type, start_date, end_date"
      }, { status: 400 });
    }

    // Validate leave type
    const validTypes = ['VACATION', 'SICK', 'PERSONAL', 'PARENTAL', 'COMPENSATORY', 'EMERGENCY'];
    if (!validTypes.includes(body.type.toUpperCase())) {
      return NextResponse.json({
        error: `Invalid leave type. Must be one of: ${validTypes.join(', ')}`
      }, { status: 400 });
    }

    // Validate dates
    const startDate = new Date(body.start_date);
    const endDate = new Date(body.end_date);
    
    if (startDate > endDate) {
      return NextResponse.json({
        error: "Start date cannot be after end date"
      }, { status: 400 });
    }

    // Check if employee exists and is active
    const employee = await prisma.employees.findUnique({
      where: { employee_id: parseInt(body.employee_id) },
      select: { employee_id: true, name: true, is_activated: true, role: true }
    });

    if (!employee) {
      return NextResponse.json({ error: "Employee not found" }, { status: 404 });
    }

    if (!employee.is_activated) {
      return NextResponse.json({ error: "Employee account is not active" }, { status: 403 });
    }

    // For vacation requests, check available balance
    if (body.type.toUpperCase() === 'VACATION') {
      const year = startDate.getFullYear();
      const leaveBalance = await prisma.leaveBalance.findUnique({
        where: {
          employee_id_year: {
            employee_id: parseInt(body.employee_id),
            year: year
          }
        }
      });

      if (leaveBalance) {
        const availableDays = (leaveBalance.vacation_days_total! + leaveBalance.carry_over_days!) - leaveBalance.vacation_days_used!;
        
        // Calculate work days for the request
        const workDays = await calculateWorkDays(startDate, endDate);
        const requestDays = body.half_day ? Math.max(1, Math.floor(workDays / 2)) : workDays;
        
        if (requestDays > availableDays) {
          return NextResponse.json({
            error: `Insufficient vacation days. Available: ${availableDays}, Requested: ${requestDays}`
          }, { status: 400 });
        }
      }
    }

    // Check for overlapping leave requests
    const overlappingRequests = await prisma.leaveRequests.findFirst({
      where: {
        employee_id: parseInt(body.employee_id),
        status: {
          in: ['PENDING', 'APPROVED']
        },
        OR: [
          {
            start_date: { lte: endDate },
            end_date: { gte: startDate }
          }
        ]
      }
    });

    if (overlappingRequests) {
      return NextResponse.json({
        error: "Overlapping leave request already exists for these dates"
      }, { status: 409 });
    }

    // Calculate work days for the request
    const workDays = await calculateWorkDays(startDate, endDate);
    const isAutoApproved = body.type.toUpperCase() === 'SICK' && body.emergency_leave;

    // Create the leave request
    const newLeaveRequest = await prisma.leaveRequests.create({
      data: {
        employee_id: parseInt(body.employee_id),
        type: body.type.toUpperCase() as any,
        start_date: startDate,
        end_date: endDate,
        total_days: workDays,
        half_day: body.half_day || false,
        reason: body.reason || null,
        emergency_leave: body.emergency_leave || false,
        sick_note_url: body.sick_note_url || null,
        status: isAutoApproved ? 'APPROVED' : 'PENDING',
        ...(isAutoApproved ? {
          approved_by: parseInt(body.employee_id), // Auto-approve by the employee themselves for emergency sick leave
          approved_at: new Date()
        } : {})
      },
      include: {
        Employees_LeaveRequests_employee_idToEmployees: {
          select: { name: true, email: true }
        }
      }
    });

    // Update leave balance for auto-approved emergency sick leave
    if (isAutoApproved) {
      const year = startDate.getFullYear();
      
      // Find or create leave balance for this year
      let balance = await prisma.leaveBalance.findUnique({
        where: {
          employee_id_year: {
            employee_id: parseInt(body.employee_id),
            year: year
          }
        }
      });

      if (!balance) {
        // Create initial balance if it doesn't exist
        balance = await prisma.leaveBalance.create({
          data: {
            employee_id: parseInt(body.employee_id),
            year: year,
            vacation_days_total: 25,
            vacation_days_used: 0,
            sick_days_used: 0,
            personal_days_total: 5,
            personal_days_used: 0,
            carry_over_days: 0
          }
        });
      }

      // Update sick days used
      await prisma.leaveBalance.update({
        where: {
          employee_id_year: {
            employee_id: parseInt(body.employee_id),
            year: year
          }
        },
        data: {
          sick_days_used: balance.sick_days_used! + workDays
        }
      });
    }

    // Create notification for manager/chef about new leave request
    try {
      // Find managers/chefs to notify
      const managersAndChefs = await prisma.employees.findMany({
        where: {
          role: {
            in: ['chef', 'byggeleder']
          },
          is_activated: true
        },
        select: { employee_id: true }
      });

      // Create notifications for all managers/chefs
      for (const manager of managersAndChefs) {
        await prisma.notifications.create({
          data: {
            employee_id: manager.employee_id,
            notification_type: 'LEAVE_REQUEST_SUBMITTED',
            title: `New ${body.type.toLowerCase()} leave request`,
            message: `${employee.name} submitted a ${body.type.toLowerCase()} leave request from ${startDate.toDateString()} to ${endDate.toDateString()}`,
            is_read: false,
            category: 'LEAVE',
            priority: body.emergency_leave ? 'HIGH' : 'NORMAL',
            action_required: true,
            action_url: `/leave/requests/${newLeaveRequest.id}`,
            sender_id: parseInt(body.employee_id),
            target_employee_id: manager.employee_id,
            metadata: JSON.stringify({
              leave_type: body.type,
              start_date: startDate.toISOString(),
              end_date: endDate.toISOString(),
              employee_name: employee.name,
              emergency: body.emergency_leave || false
            })
          }
        });
      }

      // Create confirmation notification for the worker
      await prisma.notifications.create({
        data: {
          employee_id: parseInt(body.employee_id),
          notification_type: 'LEAVE_REQUEST_SUBMITTED',
          title: 'Leave request submitted',
          message: `Your ${body.type.toLowerCase()} leave request has been submitted successfully and is pending approval.`,
          is_read: false,
          category: 'LEAVE',
          priority: 'NORMAL',
          action_required: false,
          metadata: JSON.stringify({
            leave_type: body.type,
            start_date: startDate.toISOString(),
            end_date: endDate.toISOString(),
            status: isAutoApproved ? 'approved' : 'pending'
          })
        }
      });

    } catch (notificationError) {
      console.error("Error creating leave request notifications:", notificationError);
      // Don't fail the main request if notifications fail
    }

    return NextResponse.json(newLeaveRequest, { status: 201 });

  } catch (error: any) {
    console.error("Error creating leave request:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PUT /api/app/worker/leave - Update pending leave request
export async function PUT(request: Request) {
  try {
    const body = await request.json();

    if (!body.id || !body.employee_id) {
      return NextResponse.json({
        error: "Missing required fields: id, employee_id"
      }, { status: 400 });
    }

    // Find the leave request
    const existingRequest = await prisma.leaveRequests.findUnique({
      where: { id: parseInt(body.id) }
    });

    if (!existingRequest) {
      return NextResponse.json({ error: "Leave request not found" }, { status: 404 });
    }

    // Check ownership
    if (existingRequest.employee_id !== parseInt(body.employee_id)) {
      return NextResponse.json({ error: "Not authorized to modify this request" }, { status: 403 });
    }

    // Only allow updates to pending requests
    if (existingRequest.status !== 'PENDING') {
      return NextResponse.json({
        error: "Can only update pending leave requests"
      }, { status: 400 });
    }

    // Prepare update data
    const updateData: any = {};
    
    if (body.start_date) updateData.start_date = new Date(body.start_date);
    if (body.end_date) updateData.end_date = new Date(body.end_date);
    if (body.reason !== undefined) updateData.reason = body.reason;
    if (body.half_day !== undefined) updateData.half_day = body.half_day;
    if (body.sick_note_url !== undefined) updateData.sick_note_url = body.sick_note_url;

    // Validate dates if being updated
    if (updateData.start_date && updateData.end_date) {
      if (updateData.start_date > updateData.end_date) {
        return NextResponse.json({
          error: "Start date cannot be after end date"
        }, { status: 400 });
      }
    }

    const updatedRequest = await prisma.leaveRequests.update({
      where: { id: parseInt(body.id) },
      data: updateData,
      include: {
        Employees_LeaveRequests_employee_idToEmployees: {
          select: { name: true, email: true }
        },
        Employees_LeaveRequests_approved_byToEmployees: {
          select: { name: true, email: true }
        }
      }
    });

    return NextResponse.json(updatedRequest);

  } catch (error: any) {
    console.error("Error updating leave request:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// Helper function to calculate work days
async function calculateWorkDays(startDate: Date, endDate: Date): Promise<number> {
  let workDays = 0;
  let currentDate = new Date(startDate);

  // Get holidays in the date range
  const holidays = await prisma.publicHolidays.findMany({
    where: {
      date: {
        gte: startDate,
        lte: endDate
      },
      is_national: true
    }
  });

  const holidayDates = new Set(holidays.map(h => h.date.toISOString().split('T')[0]));

  while (currentDate <= endDate) {
    const dayOfWeek = currentDate.getDay();
    const dateString = currentDate.toISOString().split('T')[0];
    
    // Check if it's a weekday (Monday=1 to Friday=5) and not a holiday
    if (dayOfWeek >= 1 && dayOfWeek <= 5 && !holidayDates.has(dateString)) {
      workDays++;
    }
    
    currentDate.setDate(currentDate.getDate() + 1);
  }

  return workDays;
}