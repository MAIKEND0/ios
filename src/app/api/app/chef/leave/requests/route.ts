// /api/app/chef/leave/requests - Chef/Manager leave request management
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

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
            email: true
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

    return NextResponse.json({
      requests: leaveRequests,
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
    const updateData: any = {
      approved_by: parseInt(body.approver_id),
      approved_at: new Date()
    };

    if (action === 'approve') {
      updateData.status = 'APPROVED';
    } else if (action === 'reject') {
      updateData.status = 'REJECTED';
      updateData.rejection_reason = body.rejection_reason || 'No reason provided';
    } else if (action === 'cancel') {
      updateData.status = 'CANCELLED';
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

    // Update the leave request
    const updatedRequest = await prisma.leaveRequests.update({
      where: { id: parseInt(body.id) },
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
            email: true
          }
        }
      }
    });

    return NextResponse.json({
      success: true,
      request: updatedRequest,
      message: `Leave request ${action}d successfully`
    });

  } catch (error: any) {
    console.error("Error updating leave request:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}