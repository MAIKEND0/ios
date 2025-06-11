// /api/app/chef/workers/update-leave-statuses - Daily update of worker statuses based on leave
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// POST /api/app/chef/workers/update-leave-statuses
// This should be called daily by a cron job or scheduled task
export async function POST(request: Request) {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    // Find all approved leave requests that start today
    const startingToday = await prisma.leaveRequests.findMany({
      where: {
        status: 'APPROVED',
        start_date: {
          gte: today,
          lt: new Date(today.getTime() + 24 * 60 * 60 * 1000)
        }
      },
      include: {
        Employees_LeaveRequests_employee_idToEmployees: true
      }
    });
    
    // Find all approved leave requests that end today
    const endingToday = await prisma.leaveRequests.findMany({
      where: {
        status: 'APPROVED',
        end_date: {
          gte: today,
          lt: new Date(today.getTime() + 24 * 60 * 60 * 1000)
        }
      },
      include: {
        Employees_LeaveRequests_employee_idToEmployees: true
      }
    });
    
    let updatedCount = 0;
    
    // Update workers starting leave today
    for (const leave of startingToday) {
      let newStatus = 'aktiv';
      if (leave.type === 'VACATION') {
        newStatus = 'ferie';
      } else if (leave.type === 'SICK' || leave.type === 'EMERGENCY') {
        newStatus = 'sygemeldt';
      }
      
      await prisma.employees.update({
        where: { employee_id: leave.employee_id },
        data: { 
          is_activated: false
          // TODO: When database has status column: status: newStatus
        }
      });
      
      updatedCount++;
      console.log(`Worker ${leave.Employees_LeaveRequests_employee_idToEmployees.name} status changed to ${newStatus} (leave starts today)`);
    }
    
    // Update workers ending leave today
    for (const leave of endingToday) {
      // Check if they have another active leave starting tomorrow
      const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);
      const hasOngoingLeave = await prisma.leaveRequests.findFirst({
        where: {
          employee_id: leave.employee_id,
          status: 'APPROVED',
          start_date: { lte: tomorrow },
          end_date: { gte: tomorrow }
        }
      });
      
      if (!hasOngoingLeave) {
        await prisma.employees.update({
          where: { employee_id: leave.employee_id },
          data: { 
            is_activated: true
            // TODO: When database has status column: status: 'aktiv'
          }
        });
        
        updatedCount++;
        console.log(`Worker ${leave.Employees_LeaveRequests_employee_idToEmployees.name} status changed to aktiv (leave ends today)`);
      }
    }
    
    return NextResponse.json({
      success: true,
      message: `Updated status for ${updatedCount} workers`,
      details: {
        starting_leave: startingToday.length,
        ending_leave: endingToday.length,
        updated: updatedCount
      }
    });
    
  } catch (error: any) {
    console.error("Error updating worker statuses:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// GET /api/app/chef/workers/update-leave-statuses - Check which workers need status update
export async function GET(request: Request) {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);
    
    // Find workers with active leave
    const workersOnLeave = await prisma.leaveRequests.findMany({
      where: {
        status: 'APPROVED',
        start_date: { lte: today },
        end_date: { gte: today }
      },
      include: {
        Employees_LeaveRequests_employee_idToEmployees: {
          select: {
            employee_id: true,
            name: true,
            is_activated: true
          }
        }
      }
    });
    
    // Find workers starting leave tomorrow
    const startingTomorrow = await prisma.leaveRequests.findMany({
      where: {
        status: 'APPROVED',
        start_date: {
          gte: tomorrow,
          lt: new Date(tomorrow.getTime() + 24 * 60 * 60 * 1000)
        }
      },
      include: {
        Employees_LeaveRequests_employee_idToEmployees: {
          select: {
            employee_id: true,
            name: true
          }
        }
      }
    });
    
    return NextResponse.json({
      workers_on_leave_today: workersOnLeave.map(l => ({
        worker_id: l.employee_id,
        worker_name: l.Employees_LeaveRequests_employee_idToEmployees.name,
        leave_type: l.type,
        start_date: l.start_date,
        end_date: l.end_date,
        current_status_active: l.Employees_LeaveRequests_employee_idToEmployees.is_activated
      })),
      starting_leave_tomorrow: startingTomorrow.map(l => ({
        worker_id: l.employee_id,
        worker_name: l.Employees_LeaveRequests_employee_idToEmployees.name,
        leave_type: l.type,
        start_date: l.start_date
      }))
    });
    
  } catch (error: any) {
    console.error("Error checking worker statuses:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}