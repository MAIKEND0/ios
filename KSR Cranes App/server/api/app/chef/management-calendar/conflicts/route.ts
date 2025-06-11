import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '../../../../../../lib/prisma';

// Conflict Detection Endpoint
// Analyzes potential conflicts for calendar events

interface ConflictRequest {
  event_id: string;
  date: string;
  end_date: string;
  resource_requirements: any[];
}

interface ConflictInfo {
  conflictType: string;
  conflictingEventId: string;
  severity: string;
  description: string;
  resolution?: string;
  affectedWorkers: number[];
}

export async function POST(request: NextRequest) {
  try {
    console.log('[ConflictDetection] Processing conflict detection request');
    
    const body: ConflictRequest = await request.json();
    const { event_id, date, end_date, resource_requirements } = body;

    const startDate = new Date(date);
    const endDate = new Date(end_date);
    
    console.log(`[ConflictDetection] Checking conflicts for event ${event_id} from ${date} to ${end_date}`);

    const conflicts: ConflictInfo[] = [];

    // 1. Check for leave conflicts
    try {
      const overlappingLeave = await prisma.leaveRequests.findMany({
        where: {
          status: 'APPROVED',
          start_date: { lte: endDate },
          end_date: { gte: startDate }
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

      for (const leave of overlappingLeave) {
        conflicts.push({
          conflictType: 'LEAVE_CONFLICT',
          conflictingEventId: `leave-${leave.id}`,
          severity: 'MEDIUM',
          description: `${leave.Employees_LeaveRequests_employee_idToEmployees?.name} is on ${leave.type} leave during this period`,
          resolution: 'Reschedule event or assign different worker',
          affectedWorkers: [leave.employee_id]
        });
      }

      console.log(`[ConflictDetection] Found ${overlappingLeave.length} leave conflicts`);
    } catch (error) {
      console.error('[ConflictDetection] Error checking leave conflicts:', error);
    }

    // 2. Check for task assignment conflicts
    try {
      const overlappingTasks = await prisma.tasks.findMany({
        where: {
          OR: [
            {
              AND: [
                { start_date: { lte: endDate } },
                { deadline: { gte: startDate } }
              ]
            }
          ]
        },
        include: {
          TaskAssignments: {
            include: {
              Employees: {
                select: {
                  employee_id: true,
                  name: true
                }
              }
            }
          }
        }
      });

      for (const task of overlappingTasks) {
        if (task.TaskAssignments && task.TaskAssignments.length > 0) {
          const assignedWorkers = task.TaskAssignments.map(ta => ta.employee_id);
          
          conflicts.push({
            conflictType: 'CAPACITY_EXCEEDED',
            conflictingEventId: `task-${task.task_id}`,
            severity: 'MEDIUM',
            description: `Workers already assigned to task: ${task.title}`,
            resolution: 'Check worker capacity or reassign tasks',
            affectedWorkers: assignedWorkers
          });
        }
      }

      console.log(`[ConflictDetection] Found ${overlappingTasks.length} potential task conflicts`);
    } catch (error) {
      console.error('[ConflictDetection] Error checking task conflicts:', error);
    }

    // 3. Check for equipment conflicts (simplified)
    // This would require more detailed equipment tracking
    
    console.log(`[ConflictDetection] Total conflicts found: ${conflicts.length}`);

    return NextResponse.json(conflicts);

  } catch (error) {
    console.error('[ConflictDetection] Error:', error);
    return NextResponse.json(
      { error: 'Failed to detect conflicts', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
