// /api/app/worker/leave - Worker leave management endpoints
import { NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";
import { createNotification, NotificationCategory } from "../../../../../lib/notificationService";

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
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Reset time to compare dates only
    
    if (startDate > endDate) {
      return NextResponse.json({
        error: "Start date cannot be after end date"
      }, { status: 400 });
    }

    // Business rule validations based on leave type
    const leaveType = body.type.toUpperCase();
    
    // Sick leave date restrictions
    if (leaveType === 'SICK') {
      const maxSickLeaveDays = 3; // Maximum days in the past for sick leave
      const maxFutureDays = body.emergency_leave ? 0 : 3; // Emergency sick leave only for today/past, regular sick up to 3 days future
      
      const earliestAllowed = new Date(today);
      earliestAllowed.setDate(today.getDate() - maxSickLeaveDays);
      
      const latestAllowed = new Date(today);
      latestAllowed.setDate(today.getDate() + maxFutureDays);
      
      if (startDate < earliestAllowed) {
        return NextResponse.json({
          error: `Sick leave cannot be reported more than ${maxSickLeaveDays} days in the past`
        }, { status: 400 });
      }
      
      if (startDate > latestAllowed) {
        if (body.emergency_leave) {
          return NextResponse.json({
            error: "Emergency sick leave can only be used for today or previous days"
          }, { status: 400 });
        } else {
          return NextResponse.json({
            error: `Regular sick leave cannot be scheduled more than ${maxFutureDays} days in advance`
          }, { status: 400 });
        }
      }
    }
    
    // Vacation advance notice requirement
    if (leaveType === 'VACATION') {
      const advanceNoticeDays = 14; // 2 weeks advance notice
      const minAdvanceDate = new Date(today);
      minAdvanceDate.setDate(today.getDate() + advanceNoticeDays);
      
      if (startDate < minAdvanceDate) {
        return NextResponse.json({
          error: `Vacation requests must be submitted at least ${advanceNoticeDays} days in advance`
        }, { status: 400 });
      }
    }
    
    // Personal days advance notice
    if (leaveType === 'PERSONAL') {
      const advanceNoticeHours = 24;
      const minAdvanceDate = new Date(today);
      minAdvanceDate.setHours(today.getHours() + advanceNoticeHours);
      
      if (startDate < minAdvanceDate && !body.emergency_leave) {
        return NextResponse.json({
          error: `Personal days require at least ${advanceNoticeHours} hours advance notice unless marked as emergency`
        }, { status: 400 });
      }
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

    // Check for overlapping leave requests (both pending and approved)
    const overlappingRequests = await prisma.leaveRequests.findMany({
      where: {
        employee_id: parseInt(body.employee_id),
        status: {
          in: ['PENDING', 'APPROVED']
        },
        OR: [
          {
            // New request starts during existing leave
            start_date: { lte: startDate },
            end_date: { gte: startDate }
          },
          {
            // New request ends during existing leave
            start_date: { lte: endDate },
            end_date: { gte: endDate }
          },
          {
            // New request completely contains existing leave
            start_date: { gte: startDate },
            end_date: { lte: endDate }
          },
          {
            // Existing leave completely contains new request
            start_date: { lte: startDate },
            end_date: { gte: endDate }
          }
        ]
      },
      include: {
        Employees_LeaveRequests_employee_idToEmployees: {
          select: { name: true }
        }
      }
    });

    if (overlappingRequests.length > 0) {
      const conflictingRequest = overlappingRequests[0];
      const conflictStart = conflictingRequest.start_date.toLocaleDateString('da-DK');
      const conflictEnd = conflictingRequest.end_date.toLocaleDateString('da-DK');
      
      return NextResponse.json({
        error: `Overlapping leave request already exists from ${conflictStart} to ${conflictEnd} (Status: ${conflictingRequest.status}). Please choose different dates.`,
        conflicting_request: {
          id: conflictingRequest.id,
          type: conflictingRequest.type,
          start_date: conflictingRequest.start_date,
          end_date: conflictingRequest.end_date,
          status: conflictingRequest.status
        }
      }, { status: 409 });
    }

    // Create the leave request
    const newLeaveRequest = await prisma.leaveRequests.create({
      data: {
        employee_id: parseInt(body.employee_id),
        type: body.type.toUpperCase() as any,
        start_date: startDate,
        end_date: endDate,
        total_days: await calculateWorkDays(startDate, endDate),
        half_day: body.half_day || false,
        reason: body.reason || null,
        emergency_leave: body.emergency_leave || false,
        sick_note_url: body.sick_note_url || null,
        status: body.type.toUpperCase() === 'SICK' && body.emergency_leave ? 'APPROVED' : 'PENDING',
        ...(body.type.toUpperCase() === 'SICK' && body.emergency_leave ? {
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

    // Create notifications for Chef and Manager roles about new leave request
    try {
      // Find all users with chef or byggeleder roles to notify them
      const managersAndChefs = await prisma.employees.findMany({
        where: {
          role: {
            in: ['chef', 'byggeleder']
          },
          is_activated: true
        },
        select: { employee_id: true, name: true, role: true }
      });

      // Create notifications for each manager/chef
      const notificationPromises = managersAndChefs.map(async (manager) => {
        const leaveTypeDisplay = {
          'VACATION': 'ferie',
          'SICK': 'sygeorlov',
          'PERSONAL': 'personlig',
          'PARENTAL': 'forældreorlov',
          'COMPENSATORY': 'afspadsering',
          'EMERGENCY': 'nødstilfælde'
        }[body.type.toUpperCase()] || body.type.toLowerCase();

        const isEmergency = body.emergency_leave || body.type.toUpperCase() === 'SICK';
        
        return createNotification({
          employeeId: manager.employee_id,
          type: "LEAVE_REQUEST_SUBMITTED",
          title: `Ny ${leaveTypeDisplay}sanmodning`,
          message: `${employee.name} har indsendt en ${leaveTypeDisplay}sanmodning fra ${startDate.toLocaleDateString('da-DK')} til ${endDate.toLocaleDateString('da-DK')}.${isEmergency ? ' HASTER - sygeorlov!' : ''}`,
          priority: isEmergency ? "HIGH" : "NORMAL",
          category: "LEAVE" as NotificationCategory,
          actionRequired: newLeaveRequest.status === 'PENDING',
          metadata: {
            leave_request_id: newLeaveRequest.id.toString(),
            employee_name: employee.name,
            leave_type: body.type.toUpperCase(),
            start_date: startDate.toISOString(),
            end_date: endDate.toISOString(),
            total_days: newLeaveRequest.total_days.toString(),
            emergency: isEmergency.toString()
          }
        });
      });

      await Promise.all(notificationPromises);
      
      console.log(`[LeaveAPI] Created notifications for ${managersAndChefs.length} managers/chefs about leave request ${newLeaveRequest.id}`);
    } catch (notificationError) {
      console.error("[LeaveAPI] Failed to create notifications:", notificationError);
      // Don't fail the main request if notifications fail
    }

    // Prepare success response with confirmation details
    const leaveTypeDisplay = {
      'VACATION': 'vacation',
      'SICK': 'sick leave',
      'PERSONAL': 'personal day',
      'PARENTAL': 'parental leave',
      'COMPENSATORY': 'compensatory time',
      'EMERGENCY': 'emergency leave'
    }[newLeaveRequest.type] || newLeaveRequest.type.toLowerCase();

    const statusMessage = newLeaveRequest.status === 'APPROVED' 
      ? 'automatically approved (emergency sick leave)'
      : 'submitted and awaiting approval';

    const workDaysCount = await calculateWorkDays(startDate, endDate);
    const requestedDays = body.half_day ? Math.ceil(workDaysCount / 2) : workDaysCount;

    return NextResponse.json({
      success: true,
      leave_request: newLeaveRequest,
      confirmation: {
        message: `Your ${leaveTypeDisplay} request has been ${statusMessage}`,
        details: {
          type: leaveTypeDisplay,
          dates: `${startDate.toLocaleDateString('da-DK')} to ${endDate.toLocaleDateString('da-DK')}`,
          work_days: requestedDays,
          half_day: body.half_day || false,
          status: newLeaveRequest.status,
          next_steps: newLeaveRequest.status === 'PENDING' 
            ? 'Your manager will review and respond to your request'
            : 'Your leave has been approved and is now active'
        }
      }
    }, { status: 201 });

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

// DELETE /api/app/worker/leave - Cancel/delete leave request
export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const requestId = searchParams.get("id");
    const employeeId = searchParams.get("employee_id");

    if (!requestId || !employeeId) {
      return NextResponse.json({
        error: "Missing required parameters: id, employee_id"
      }, { status: 400 });
    }

    // Find the leave request
    const existingRequest = await prisma.leaveRequests.findUnique({
      where: { id: parseInt(requestId) },
      include: {
        Employees_LeaveRequests_employee_idToEmployees: {
          select: { name: true, email: true }
        }
      }
    });

    if (!existingRequest) {
      return NextResponse.json({ error: "Leave request not found" }, { status: 404 });
    }

    // Check ownership
    if (existingRequest.employee_id !== parseInt(employeeId)) {
      return NextResponse.json({ error: "Not authorized to cancel this request" }, { status: 403 });
    }

    // Business rules for cancellation
    if (existingRequest.status === 'PENDING') {
      // PENDING requests can be cancelled directly
      await prisma.leaveRequests.update({
        where: { id: parseInt(requestId) },
        data: { 
          status: 'CANCELLED',
          updated_at: new Date()
        }
      });

      return NextResponse.json({
        success: true,
        message: "Leave request cancelled successfully"
      });

    } else if (existingRequest.status === 'APPROVED') {
      // APPROVED requests require manager approval to cancel
      // For now, we'll mark as "cancellation requested" and notify managers
      
      // Create notifications for managers about cancellation request
      try {
        const managersAndChefs = await prisma.employees.findMany({
          where: {
            role: { in: ['chef', 'byggeleder'] },
            is_activated: true
          },
          select: { employee_id: true, name: true, role: true }
        });

        // Create notifications
        const notificationPromises = managersAndChefs.map(async (manager) => {
          return createNotification({
            employeeId: manager.employee_id,
            type: "LEAVE_REQUEST_CANCELLED",
            title: `Anmodning om annullering af godkendt orlov`,
            message: `${existingRequest.Employees_LeaveRequests_employee_idToEmployees.name} anmoder om at annullere godkendt ${existingRequest.type.toLowerCase()}orlov fra ${existingRequest.start_date.toLocaleDateString('da-DK')} til ${existingRequest.end_date.toLocaleDateString('da-DK')}.`,
            priority: "NORMAL",
            category: "LEAVE" as NotificationCategory,
            actionRequired: true,
            metadata: {
              leave_request_id: existingRequest.id.toString(),
              employee_name: existingRequest.Employees_LeaveRequests_employee_idToEmployees.name,
              leave_type: existingRequest.type,
              start_date: existingRequest.start_date.toISOString(),
              end_date: existingRequest.end_date.toISOString(),
              action_type: "CANCEL_REQUEST"
            }
          });
        });

        await Promise.all(notificationPromises);
      } catch (notificationError) {
        console.error("[LeaveAPI] Failed to create cancellation notifications:", notificationError);
      }

      return NextResponse.json({
        success: true,
        message: "Cancellation request sent to your manager for approval",
        requires_approval: true
      });

    } else {
      return NextResponse.json({
        error: `Cannot cancel leave request with status: ${existingRequest.status}`
      }, { status: 400 });
    }

  } catch (error: any) {
    console.error("Error cancelling leave request:", error);
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
    
    // Only count Monday (1) to Friday (5), excluding weekends and holidays
    if (dayOfWeek >= 1 && dayOfWeek <= 5 && !holidayDates.has(dateString)) {
      workDays++;
    }
    
    currentDate.setDate(currentDate.getDate() + 1);
  }

  return workDays;
}
