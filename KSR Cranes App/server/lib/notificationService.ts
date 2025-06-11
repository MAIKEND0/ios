import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

// Worker Availability Matrix Endpoint
// Provides detailed worker availability and utilization data

interface WorkerAvailabilityMatrix {
  dateRange: {
    startDate: string;
    endDate: string;
  };
  workers: WorkerAvailabilityRow[];
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

interface WorkerAvailabilityRow {
  id: number;
  worker: {
    id: number;
    name: string;
    role: string;
    email: string;
    phone?: string;
    skills: any[];
    profilePictureUrl?: string;
    isActive: boolean;
    hireDate?: string;
  };
  dailyAvailability: Record<string, DayAvailability>;
  weeklyStats: {
    totalHours: number;
    utilization: number;
    projectCount: number;
    taskCount: number;
    averageDaily: number;
    peakDay?: string;
    efficiency?: number;
  };
  monthlyStats?: any;
}

interface DayAvailability {
  status: string;
  assignedHours: number;
  maxCapacity: number;
  projects: any[];
  tasks: any[];
  leaveInfo?: any;
  conflicts: any[];
  workPlan?: any;
}

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('start_date');
    const endDate = searchParams.get('end_date');
    const workerIdsParam = searchParams.get('worker_ids');
    const skillFilter = searchParams.get('skill_filter');

    if (!startDate || !endDate) {
      return NextResponse.json(
        { error: 'start_date and end_date parameters are required' },
        { status: 400 }
      );
    }

    const startDateObj = new Date(startDate);
    const endDateObj = new Date(endDate);
    
    console.log(`[WorkerAvailability] Fetching availability from ${startDate} to ${endDate}`);

    // Parse worker IDs if provided
    const workerIds = workerIdsParam ? 
      workerIdsParam.split(',').map(id => parseInt(id.trim())).filter(id => !isNaN(id)) : 
      undefined;

    // Build worker filter criteria
    const workerFilter: any = {
      role: { in: ['arbejder', 'byggeleder'] },
      is_activated: true
    };

    if (workerIds && workerIds.length > 0) {
      workerFilter.employee_id = { in: workerIds };
    }

    // Fetch workers
    const workers = await prisma.employees.findMany({
      where: workerFilter,
      select: {
        employee_id: true,
        name: true,
        role: true,
        email: true,
        phone_number: true,
        created_at: true,
        profilePictureUrl: true
      }
    });

    console.log(`[WorkerAvailability] Found ${workers.length} workers`);

    // Generate date range for daily availability
    const dateRange: Date[] = [];
    const currentDate = new Date(startDateObj);
    while (currentDate <= endDateObj) {
      dateRange.push(new Date(currentDate));
      currentDate.setDate(currentDate.getDate() + 1);
    }

    const workerRows: WorkerAvailabilityRow[] = [];
    let totalOnLeave = 0;
    let totalSick = 0;

    for (const worker of workers) {
      const dailyAvailability: Record<string, DayAvailability> = {};
      let totalHours = 0;
      let assignedDays = 0;

      // Fetch leave requests for this worker in the date range
      const leaveRequests = await prisma.leaveRequests.findMany({
        where: {
          employee_id: worker.employee_id,
          status: 'APPROVED',
          start_date: { lte: endDateObj },
          end_date: { gte: startDateObj }
        }
      });

      // Fetch task assignments for this worker
      const taskAssignments = await prisma.taskAssignments.findMany({
        where: {
          employee_id: worker.employee_id
        },
        include: {
          Tasks: {
            select: {
              task_id: true,
              task_name: true,
              start_date: true,
              deadline: true,
              estimated_hours: true,
              Projects: {
                select: {
                  project_name: true
                }
              }
            }
          }
        }
      });

      // Generate daily availability for each date
      for (const date of dateRange) {
        const dateKey = date.toISOString().split('T')[0]; // YYYY-MM-DD format
        
        // Check if worker is on leave this day
        const leaveForDay = leaveRequests.find(leave => 
          date >= new Date(leave.start_date) && date <= new Date(leave.end_date)
        );

        // Check task assignments for this day
        const tasksForDay = taskAssignments.filter(assignment => {
          const task = assignment.Tasks;
          if (!task) return false;
          
          const taskStart = task.start_date ? new Date(task.start_date) : null;
          const taskEnd = task.deadline ? new Date(task.deadline) : null;
          
          if (taskStart && taskEnd) {
            return date >= taskStart && date <= taskEnd;
          }
          return false;
        });

        const estimatedHoursForDay = tasksForDay.reduce((sum, assignment) => {
          return sum + (assignment.estimated_hours || 8); // Default 8 hours if not specified
        }, 0);

        let status = 'AVAILABLE';
        if (leaveForDay) {
          status = leaveForDay.type === 'SICK' ? 'SICK' : 'ON_LEAVE';
          if (leaveForDay.type === 'SICK') totalSick++;
          else totalOnLeave++;
        } else if (estimatedHoursForDay > 8) {
          status = 'OVERLOADED';
        } else if (estimatedHoursForDay > 0) {
          status = estimatedHoursForDay >= 6 ? 'ASSIGNED' : 'PARTIALLY_BUSY';
        }

        const maxCapacity = leaveForDay ? 0 : 8; // 8 hour work day
        const assignedHours = leaveForDay ? 0 : estimatedHoursForDay;

        dailyAvailability[dateKey] = {
          status,
          assignedHours,
          maxCapacity,
          projects: [], // Simplified
          tasks: tasksForDay.map(assignment => ({
            id: assignment.assignment_id,
            taskId: assignment.task_id,
            taskName: assignment.Tasks?.task_name || '',
            projectName: assignment.Tasks?.Projects?.project_name || '',
            hours: assignment.estimated_hours || 8,
            deadline: assignment.Tasks?.deadline?.toISOString(),
            requiredSkills: [], // Would need separate skills table
            craneModel: assignment.crane_model_id?.toString()
          })),
          leaveInfo: leaveForDay ? {
            leaveRequestId: leaveForDay.id,
            type: leaveForDay.type,
            isHalfDay: leaveForDay.half_day,
            reason: leaveForDay.reason,
            approvedBy: null, // Would need to join with approver
            approvedAt: leaveForDay.approved_at?.toISOString()
          } : undefined,
          conflicts: [],
          workPlan: undefined
        };

        if (!leaveForDay) {
          totalHours += assignedHours;
          if (assignedHours > 0) assignedDays++;
        }
      }

      const utilization = totalHours > 0 ? Math.min(totalHours / (dateRange.length * 8), 1.0) : 0;

      workerRows.push({
        id: worker.employee_id,
        worker: {
          id: worker.employee_id,
          name: worker.name,
          role: worker.role,
          email: worker.email,
          phone: worker.phone_number || undefined,
          skills: [], // Would need separate skills implementation
          profilePictureUrl: worker.profilePictureUrl || undefined,
          isActive: true,
          hireDate: worker.created_at?.toISOString()
        },
        dailyAvailability,
        weeklyStats: {
          totalHours,
          utilization,
          projectCount: 0, // Would need to count unique projects
          taskCount: taskAssignments.length,
          averageDaily: assignedDays > 0 ? totalHours / assignedDays : 0,
          peakDay: undefined,
          efficiency: undefined
        }
      });
    }

    // Calculate summary statistics
    const today = new Date().toISOString().split('T')[0];
    const availableToday = workerRows.filter(row => 
      row.dailyAvailability[today]?.status === 'AVAILABLE'
    ).length;

    const averageUtilization = workerRows.length > 0 ? 
      workerRows.reduce((sum, row) => sum + row.weeklyStats.utilization, 0) / workerRows.length : 0;

    const matrix: WorkerAvailabilityMatrix = {
      dateRange: {
        startDate,
        endDate
      },
      workers: workerRows,
      summary: {
        totalWorkers: workers.length,
        availableToday,
        onLeaveToday: totalOnLeave,
        sickToday: totalSick,
        overloadedToday: workerRows.filter(row => 
          row.dailyAvailability[today]?.status === 'OVERLOADED'
        ).length,
        averageUtilization,
        criticalSkillGaps: [], // Would need skills analysis
        upcomingDeadlines: 0 // Would need deadline analysis
      },
      lastUpdated: new Date().toISOString()
    };

    console.log(`[WorkerAvailability] Returning matrix for ${workers.length} workers`);

    return NextResponse.json(matrix);

  } catch (error) {
    console.error('[WorkerAvailability] Error generating worker availability matrix:', error);
    return NextResponse.json(
      { error: 'Failed to generate worker availability matrix', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
