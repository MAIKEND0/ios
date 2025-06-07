// /api/app/chef/leave/requests - Chef/Manager leave request management
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";
import { createNotification } from "../../../../../../lib/notificationService";

// GET /api/app/chef/leave/requests - Get all team leave requests with filtering
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    
    // Filtering parameters
    const status = searchParams.get("status");
    const employeeId = searchParams.get("employee_id");
    const leaveType = searchParams.get("type");
    const startDate = searchParams.get("start_date");
    const endDate = searchParams.get("end_date");
    const pendingOnly = searchParams.get("pending_only") === "true";
    const limit = searchParams.get("limit") ? parseInt(searchParams.get("limit")!) : 50;
    const offset = searchParams.get("offset") ? parseInt(searchParams.get("offset")!) : 0;

    // Build where clause
    const whereClause: any = {};

    // Filter by status
    if (status) {
      whereClause.status = status.toUpperCase();
    } else if (pendingOnly) {
      whereClause.status = 'PENDING';
    }

    // Filter by employee
    if (employeeId) {
      whereClause.employee_id = parseInt(employeeId);
    }

    // Filter by leave type
    if (leaveType) {
      whereClause.type = leaveType.toUpperCase();
    }

    // Filter by date range
    if (startDate || endDate) {
      whereClause.start_date = {};
      if (startDate) whereClause.start_date.gte = new Date(startDate);
      if (endDate) whereClause.start_date.lte = new Date(endDate);
    }

    // Only include workers and managers (not system users)
    whereClause.Employees_LeaveRequests_employee_idToEmployees = {
      role: {
        in: ['arbejder', 'byggeleder']
      }
    };

    // Fetch leave requests
    const leaveRequests = await prisma.leaveRequests.findMany({
      where: whereClause,
      include: {
        Employees_LeaveRequests_employee_idToEmployees: {
          select: {
            employee_id: true,
            name: true,
            email: true,
            role: true,
            profilePictureUrl: true
          }
        },
        Employees_LeaveRequests_approved_byToEmployees: {
          select: {
            employee_id: true,
            name: true,
            email: true,
            role: true
          }
        }
      },
      orderBy: [
        { status: 'asc' }, // Pending first
        { created_at: 'desc' }
      ],
      skip: offset,
      take: limit
    });

    // Get total count for pagination
    const totalCount = await prisma.leaveRequests.count({ where: whereClause });

    // Get summary statistics
    const statusCounts = await prisma.leaveRequests.groupBy({
      by: ['status'],
      where: {
        Employees_LeaveRequests_employee_idToEmployees: {
          role: {
            in: ['arbejder', 'byggeleder']
          }
        }
      },
      _count: {
        status: true
      }
    });

    const stats = {
      total: totalCount,
      pending: statusCounts.find(s => s.status === 'PENDING')?._count.status || 0,
      approved: statusCounts.find(s => s.status === 'APPROVED')?._count.status || 0,
      rejected: statusCounts.find(s => s.status === 'REJECTED')?._count.status || 0,
      cancelled: statusCounts.find(s => s.status === 'CANCELLED')?._count.status || 0
    };

    // Map Prisma relationship names to iOS expected field names
    const mappedRequests = leaveRequests.map(request => ({
      ...request,
      employee: request.Employees_LeaveRequests_employee_idToEmployees,
      approver: request.Employees_LeaveRequests_approved_byToEmployees,
      // Remove the Prisma relationship fields to keep response clean
      Employees_LeaveRequests_employee_idToEmployees: undefined,
      Employees_LeaveRequests_approved_byToEmployees: undefined
    }));

    return NextResponse.json({
      requests: mappedRequests,
      pagination: {
        limit,
        offset,
        total: totalCount,
        has_more: (offset + limit) < totalCount
      },
      statistics: stats
    });

  } catch (error: any) {
    console.error("Error fetching leave requests:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PUT /api/app/chef/leave/requests - Approve/reject leave request
export async function PUT(request: Request) {
  try {
    const body = await request.json();

    if (!body.id || !body.action || !body.approver_id) {
      return NextResponse.json({
        error: "Missing required fields: id, action, approver_id"
      }, { status: 400 });
    }

    const validActions = ['approve', 'reject', 'cancel'];
    if (!validActions.includes(body.action.toLowerCase())) {
      return NextResponse.json({
        error: `Invalid action. Must be one of: ${validActions.join(', ')}`
      }, { status: 400 });
    }

    // Find the leave request
    const leaveRequest = await prisma.leaveRequests.findUnique({
      where: { id: parseInt(body.id) },
      include: {
        Employees_LeaveRequests_employee_idToEmployees: {
          select: { name: true, email: true, role: true }
        }
      }
    });

    if (!leaveRequest) {
      return NextResponse.json({ error: "Leave request not found" }, { status: 404 });
    }

    // Check if request can be modified
    if (leaveRequest.status !== 'PENDING') {
      return NextResponse.json({
        error: `Cannot ${body.action} a ${leaveRequest.status.toLowerCase()} request`
      }, { status: 400 });
    }

    // Verify approver exists and has appropriate role
    const approver = await prisma.employees.findUnique({
      where: { employee_id: parseInt(body.approver_id) },
      select: { employee_id: true, name: true, role: true }
    });

    if (!approver) {
      return NextResponse.json({ error: "Approver not found" }, { status: 404 });
    }

    if (!['chef', 'byggeleder'].includes(approver.role)) {
      return NextResponse.json({
        error: "Only managers and chefs can approve leave requests"
      }, { status: 403 });
    }

    // Prepare update data
    const action = body.action.toLowerCase();
    const updateData: any = {};

    if (action === 'approve') {
      updateData.status = 'APPROVED';
      updateData.approved_by = parseInt(body.approver_id);
      updateData.approved_at = new Date();
      console.log("DEBUG: Setting approved_by to:", parseInt(body.approver_id));
    } else if (action === 'reject') {
      updateData.status = 'REJECTED';
      updateData.rejection_reason = body.rejection_reason || 'No reason provided';
      // Don't set approved_by for rejections
    } else if (action === 'cancel') {
      updateData.status = 'CANCELLED';
      // Don't set approved_by for cancellations
    }

    // For vacation approvals, check if there's sufficient balance
    if (action === 'approve' && leaveRequest.type === 'VACATION') {
      const year = leaveRequest.start_date.getFullYear();
      const balance = await prisma.leaveBalance.findUnique({
        where: {
          employee_id_year: {
            employee_id: leaveRequest.employee_id,
            year: year
          }
        }
      });

      if (balance) {
        const availableDays = (balance.vacation_days_total! + balance.carry_over_days!) - balance.vacation_days_used!;
        if (leaveRequest.total_days > availableDays) {
          return NextResponse.json({
            error: `Insufficient vacation days. Available: ${availableDays}, Requested: ${leaveRequest.total_days}`
          }, { status: 400 });
        }
      }
    }

    // Update the leave request with trigger-safe approach
    console.log("About to update leave request with data:", JSON.stringify(updateData, null, 2));
    console.log("Request ID:", parseInt(body.id));
    console.log("Approver ID:", parseInt(body.approver_id));
    console.log("Approver exists:", approver ? "YES" : "NO");
    console.log("Approver details:", approver);
    
    let updatedRequest;
    
    try {
      console.log("DEBUG: Using standard Prisma update with fixed triggers");
      
      // Standard Prisma update - triggers should now work without transaction conflicts
      updatedRequest = await prisma.leaveRequests.update({
        where: { 
          id: parseInt(body.id),
          status: 'PENDING' // Only update if still pending
        },
        data: updateData,
        include: {
          Employees_LeaveRequests_employee_idToEmployees: {
            select: {
              employee_id: true,
              name: true,
              email: true,
              role: true
            }
          },
          Employees_LeaveRequests_approved_byToEmployees: {
            select: {
              employee_id: true,
              name: true,
              email: true,
              role: true
            }
          }
        }
      });
      
      if (!updatedRequest) {
        return NextResponse.json({ 
          error: "Leave request not found after update" 
        }, { status: 404 });
      }
      
      console.log("DEBUG: Prisma update successful with fixed triggers!");
      
    } catch (updateError: any) {
      console.error("Leave request update failed completely:", updateError);
      console.error("Update error code:", updateError.code);
      console.error("Update error message:", updateError.message);
      
      return NextResponse.json({ 
        error: "Failed to update leave request", 
        details: updateError.message,
        code: updateError.code,
        hint: "All update methods failed. Please check database triggers and permissions."
      }, { status: 500 });
    }

    // Update leave balance when approving requests
    if (action === 'approve') {
      const year = leaveRequest.start_date.getFullYear();
      
      try {
        // Use direct SQL to update leave balance to avoid any potential trigger conflicts
        // First, ensure the balance record exists
        await prisma.$executeRaw`
          INSERT IGNORE INTO LeaveBalance (employee_id, year, vacation_days_total, vacation_days_used, sick_days_used, personal_days_total, personal_days_used, carry_over_days, created_at, updated_at) 
          VALUES (${leaveRequest.employee_id}, ${year}, 25, 0, 0, 5, 0, 0, NOW(), NOW())
        `;
        
        // Update the appropriate balance field based on leave type
        if (leaveRequest.type === 'VACATION') {
          await prisma.$executeRaw`
            UPDATE LeaveBalance 
            SET vacation_days_used = vacation_days_used + ${leaveRequest.total_days},
                updated_at = NOW()
            WHERE employee_id = ${leaveRequest.employee_id} AND year = ${year}
          `;
        } else if (leaveRequest.type === 'SICK') {
          await prisma.$executeRaw`
            UPDATE LeaveBalance 
            SET sick_days_used = sick_days_used + ${leaveRequest.total_days},
                updated_at = NOW()
            WHERE employee_id = ${leaveRequest.employee_id} AND year = ${year}
          `;
        } else if (leaveRequest.type === 'PERSONAL') {
          await prisma.$executeRaw`
            UPDATE LeaveBalance 
            SET personal_days_used = personal_days_used + ${leaveRequest.total_days},
                updated_at = NOW()
            WHERE employee_id = ${leaveRequest.employee_id} AND year = ${year}
          `;
        }
        
        console.log("DEBUG: Leave balance updated successfully via direct SQL");
        
      } catch (balanceError) {
        console.error("Error updating leave balance:", balanceError);
        // Don't fail the entire request if balance update fails
        // The triggers will handle balance updates, this is just a backup
      }
    }

    // Create notification for the employee about the decision
    try {
      const notificationType = action === 'approve' ? 'LEAVE_REQUEST_APPROVED' : 'LEAVE_REQUEST_REJECTED';
      const title = action === 'approve' ? 'Leave request approved' : 'Leave request rejected';
      const message = action === 'approve' 
        ? `Your ${leaveRequest.type.toLowerCase()} leave request has been approved.`
        : `Your ${leaveRequest.type.toLowerCase()} leave request has been rejected. ${body.rejection_reason ? 'Reason: ' + body.rejection_reason : ''}`;

      console.log("Creating notification with type:", notificationType);
      
      await createNotification({
        employeeId: leaveRequest.employee_id,
        type: notificationType as any,
        title: title,
        message: message,
        category: 'LEAVE',
        priority: action === 'reject' ? 'HIGH' : 'NORMAL',
        actionRequired: action === 'reject',
        senderId: parseInt(body.approver_id),
        targetEmployeeId: leaveRequest.employee_id,
        metadata: {
          leave_type: leaveRequest.type,
          start_date: leaveRequest.start_date.toISOString(),
          end_date: leaveRequest.end_date.toISOString(),
          action: action,
          approver_name: approver.name,
          rejection_reason: body.rejection_reason || null
        }
      });

    } catch (notificationError) {
      console.error("Error creating leave decision notification:", notificationError);
      // Don't fail the main request if notifications fail
    }

    // Map Prisma relationship names to iOS expected field names
    const mappedRequest = {
      ...updatedRequest,
      employee: updatedRequest.Employees_LeaveRequests_employee_idToEmployees,
      approver: updatedRequest.Employees_LeaveRequests_approved_byToEmployees,
      // Remove the Prisma relationship fields to keep response clean
      Employees_LeaveRequests_employee_idToEmployees: undefined,
      Employees_LeaveRequests_approved_byToEmployees: undefined
    };

    return NextResponse.json({
      success: true,
      request: mappedRequest,
      message: `Leave request ${action}d successfully`
    });

  } catch (error: any) {
    console.error("Error updating leave request:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
