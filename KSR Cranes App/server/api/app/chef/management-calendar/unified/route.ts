import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '../../../../../../lib/prisma';

// Management Calendar Unified Data Endpoint
// Provides consolidated view of all calendar events (tasks, projects, leave, deadlines)

interface ManagementCalendarRequest {
  startDate: string;
  endDate: string;
  eventTypes?: string[];
  includeConflicts?: boolean;
  includeMetadata?: boolean;
  workerIds?: number[];
  projectIds?: number[];
}

interface ManagementCalendarEvent {
  id: string;
  date: string;
  endDate?: string;
  type: string;
  category: string;
  title: string;
  description: string;
  priority: string;
  status: string;
  resourceRequirements: any[];
  relatedEntities: {
    projectId?: number;
    taskId?: number;
    workerId?: number;
    leaveRequestId?: number;
    equipmentId?: number;
    workPlanId?: number;
  };
  conflicts: any[];
  actionRequired: boolean;
  metadata: {
    createdBy?: number;
    createdAt?: string;
    lastModifiedBy?: number;
    lastModifiedAt?: string;
    estimatedDuration?: number;
    actualDuration?: number;
    costEstimate?: number;
    notes?: string;
    attachments?: string[];
  };
}

interface WorkerAvailabilityMatrix {
  dateRange: {
    startDate: string;
    endDate: string;
  };
  workers: any[];
  summary: {
    totalWorkers: number;
    availableToday: number;
    onLeaveToday: number;
    sickToday: number;
    overloadedToday: number;
    averageUtilization: number;
    criticalSkillGaps: string[];
    upcomingDeadlines: number;
  };
  lastUpdated: string;
}

interface CalendarSummary {
  totalEvents: number;
  eventsByType: Record<string, number>;
  eventsByPriority: Record<string, number>;
  conflictCount: number;
  capacityUtilization: number;
  upcomingDeadlines: number;
  workersOnLeave: number;
  availableWorkers: number;
}

export async function POST(request: NextRequest) {
  try {
    console.log('[ManagementCalendar] Processing unified calendar request');
    
    const body: ManagementCalendarRequest = await request.json();
    const { startDate, endDate, eventTypes = [], includeConflicts = true, includeMetadata = true } = body;

    // Parse dates
    const startDateObj = new Date(startDate);
    const endDateObj = new Date(endDate);
    
    console.log(`[ManagementCalendar] Date range: ${startDate} to ${endDate}`);
    console.log(`[ManagementCalendar] Event types: ${eventTypes.join(', ')}`);

    // Initialize response data
    const events: ManagementCalendarEvent[] = [];
    let workerAvailability: WorkerAvailabilityMatrix | null = null;
    const conflicts: any[] = [];

    // 1. Fetch Leave Events (if LEAVE type is requested)
    if (eventTypes.length === 0 || eventTypes.includes('LEAVE')) {
      try {
        const leaveRequests = await prisma.leaveRequests.findMany({
          where: {
            status: 'APPROVED',
            start_date: { gte: startDateObj },
            end_date: { lte: endDateObj }
          },
          include: {
            Employees_LeaveRequests_employee_idToEmployees: {
              select: {
                employee_id: true,
                name: true,
                role: true
              }
            }
          }
        });

        console.log(`[ManagementCalendar] Found ${leaveRequests.length} approved leave requests`);

        for (const leave of leaveRequests) {
          events.push({
            id: `leave-${leave.id}`,
            date: leave.start_date.toISOString(),
            endDate: leave.end_date.toISOString(),
            type: 'LEAVE',
            category: 'WORKFORCE',
            title: `${leave.Employees_LeaveRequests_employee_idToEmployees?.name} - ${leave.type} Leave`,
            description: leave.reason || `${leave.type} leave`,
            priority: leave.emergency_leave ? 'HIGH' : 'MEDIUM',
            status: 'ACTIVE',
            resourceRequirements: [],
            relatedEntities: {
              workerId: leave.employee_id,
              leaveRequestId: leave.id
            },
            conflicts: [],
            actionRequired: false,
            metadata: {
              createdAt: leave.created_at.toISOString(),
              notes: leave.reason
            }
          });
        }
      } catch (error) {
        console.error('[ManagementCalendar] Error fetching leave events:', error);
      }
    }

    // 2. Fetch Project Events (if PROJECT type is requested)
    if (eventTypes.length === 0 || eventTypes.includes('PROJECT')) {
      try {
        const projects = await prisma.projects.findMany({
          where: {
            OR: [
              { start_date: { gte: startDateObj, lte: endDateObj } },
              { end_date: { gte: startDateObj, lte: endDateObj } },
              {
                AND: [
                  { start_date: { lte: startDateObj } },
                  { end_date: { gte: endDateObj } }
                ]
              }
            ]
          },
          include: {
            Customers: {
              select: {
                customer_id: true,
                name: true
              }
            }
          }
        });

        console.log(`[ManagementCalendar] Found ${projects.length} active projects`);

        for (const project of projects) {
          events.push({
            id: `project-${project.project_id}`,
            date: project.start_date?.toISOString() || new Date().toISOString(),
            endDate: project.end_date?.toISOString(),
            type: 'PROJECT',
            category: 'PROJECT',
            title: project.title,
            description: `${project.Customers?.name || 'Unknown Customer'} - ${project.description || ''}`,
            priority: 'MEDIUM',
            status: project.status === 'aktiv' ? 'ACTIVE' : project.status === 'afsluttet' ? 'COMPLETED' : 'PLANNED',
            resourceRequirements: [],
            relatedEntities: {
              projectId: project.project_id
            },
            conflicts: [],
            actionRequired: false,
            metadata: {
              createdAt: project.created_at?.toISOString()
            }
          });
        }
      } catch (error) {
        console.error('[ManagementCalendar] Error fetching project events:', error);
      }
    }

    // 3. Fetch Task Events (if TASK type is requested)
    if (eventTypes.length === 0 || eventTypes.includes('TASK')) {
      try {
        const tasks = await prisma.tasks.findMany({
          where: {
            OR: [
              { deadline: { gte: startDateObj, lte: endDateObj } },
              { start_date: { gte: startDateObj, lte: endDateObj } }
            ]
          },
          include: {
            Projects: {
              select: {
                project_id: true,
                title: true
              }
            },
            TaskAssignments: {
              include: {
                Employees: {
                  select: {
                    employee_id: true,
                    name: true,
                    role: true
                  }
                }
              }
            }
          }
        });

        console.log(`[ManagementCalendar] Found ${tasks.length} active tasks`);

        for (const task of tasks) {
          const assignedOperators = task.TaskAssignments?.map((ta: any) => ({
            name: ta.Employees?.name,
            role: ta.Employees?.role,
            id: ta.Employees?.employee_id
          })).filter((emp: any) => emp.name) || [];
          
          // ✅ Use actual management calendar fields from database
          const taskPriority = task.priority || 'medium';
          const taskStatus = task.status || 'planned';
          const requiredOperators = task.required_operators || 1;
          const estimatedHours = task.estimated_hours || null;
          
          events.push({
            id: `task-${task.task_id}`,
            date: task.start_date?.toISOString() || task.deadline?.toISOString() || new Date().toISOString(),
            endDate: task.deadline?.toISOString(),
            type: 'TASK',
            category: 'OPERATOR_ASSIGNMENT',
            title: task.title,
            description: `${task.Projects?.title} - ${task.description || ''} ${task.client_equipment_info ? `(${task.client_equipment_info})` : ''}`,
            priority: taskPriority.toUpperCase(),
            status: taskStatus.toUpperCase(),
            resourceRequirements: [
              {
                skillType: 'CRANE_OPERATOR',
                workerCount: requiredOperators,
                estimatedHours: estimatedHours || 8,
                urgency: taskPriority.toUpperCase(),
                certificationRequired: true
              },
              ...assignedOperators.map((op: any) => ({
                type: 'OPERATOR',
                role: op.role,
                name: op.name,
                id: op.id
              }))
            ],
            relatedEntities: {
              projectId: task.project_id,
              taskId: task.task_id
            },
            conflicts: [],
            actionRequired: assignedOperators.length < requiredOperators,
            metadata: {
              createdAt: task.created_at?.toISOString(),
              estimatedDuration: estimatedHours ? Number(estimatedHours) * 3600 : null, // Convert to seconds
              notes: [
                assignedOperators.length > 0 ? `Operators assigned: ${assignedOperators.map(op => `${op.name} (${op.role})`).join(', ')}` : 'No operators assigned yet',
                `Required operators: ${requiredOperators}`,
                task.client_equipment_info ? `Client equipment: ${task.client_equipment_info}` : null
              ].filter(Boolean).join('. ')
            }
          });
        }
      } catch (error) {
        console.error('[ManagementCalendar] Error fetching task events:', error);
      }
    }

    // 4. Generate Crane Operator Availability Matrix
    try {
      const operators = await prisma.employees.findMany({
        where: {
          role: { in: ['arbejder', 'byggeleder'] }, // Crane operators and supervisors
          is_activated: true
        },
        select: {
          employee_id: true,
          name: true,
          role: true,
          email: true,
          phone_number: true
        }
      });

      const onLeaveToday = await prisma.leaveRequests.count({
        where: {
          status: 'APPROVED',
          start_date: { lte: new Date() },
          end_date: { gte: new Date() }
        }
      });

      const sickToday = await prisma.leaveRequests.count({
        where: {
          status: 'APPROVED',
          type: 'SICK',
          start_date: { lte: new Date() },
          end_date: { gte: new Date() }
        }
      });

      // Count active/assigned operators for today
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      const assignedToday = await prisma.taskAssignments.count({
        where: {
          work_date: today,
          status: { in: ['assigned', 'active'] }
        }
      });

      workerAvailability = {
        dateRange: {
          startDate,
          endDate
        },
        workers: [], // Simplified for now
        summary: {
          totalWorkers: operators.length,
          availableToday: operators.length - onLeaveToday,
          onLeaveToday,
          sickToday,
          overloadedToday: 0, // Operators rarely overloaded in staffing model
          averageUtilization: assignedToday / Math.max(operators.length, 1), // Assignment rate
          criticalSkillGaps: [], // Would need crane type certification data
          upcomingDeadlines: events.filter(e => e.type === 'TASK' && new Date(e.endDate || e.date) <= new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)).length
        },
        lastUpdated: new Date().toISOString()
      };

      console.log(`[ManagementCalendar] Operator availability: ${operators.length} total, ${operators.length - onLeaveToday} available, ${assignedToday} assigned`);
    } catch (error) {
      console.error('[ManagementCalendar] Error generating worker availability:', error);
    }

    // 5. Generate Calendar Summary
    const summary: CalendarSummary = {
      totalEvents: events.length,
      eventsByType: events.reduce((acc, event) => {
        acc[event.type] = (acc[event.type] || 0) + 1;
        return acc;
      }, {} as Record<string, number>),
      eventsByPriority: events.reduce((acc, event) => {
        acc[event.priority] = (acc[event.priority] || 0) + 1;
        return acc;
      }, {} as Record<string, number>),
      conflictCount: conflicts.length,
      capacityUtilization: 0.7, // Mock value
      upcomingDeadlines: events.filter(e => 
        e.type === 'TASK' && 
        e.endDate && 
        new Date(e.endDate) <= new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      ).length,
      workersOnLeave: workerAvailability?.summary.onLeaveToday || 0,
      availableWorkers: workerAvailability?.summary.availableToday || 0
    };

    const response = {
      events,
      workerAvailability,
      summary,
      conflicts,
      lastUpdated: new Date().toISOString(),
      cacheHitRate: null
    };

    console.log(`[ManagementCalendar] Returning ${events.length} events, ${conflicts.length} conflicts`);

    return NextResponse.json(response);

  } catch (error) {
    console.error('[ManagementCalendar] Unified calendar error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch unified calendar data', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
