// src/app/api/app/chef/tasks/[id]/assignments/route.ts
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";
import { createTaskAssignmentNotification } from "../../../../../../../lib/notificationService";

// Helper function for error handling
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === 'string') {
    return error;
  }
  return 'An unexpected error occurred';
}

/**
 * POST /api/app/chef/tasks/[id]/assignments
 * Przypisuje pracowników do zadania (bulk assignment)
 */
export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const taskId = parseInt(id, 10);
    
    if (isNaN(taskId)) {
      return NextResponse.json({ error: "Invalid task ID" }, { status: 400 });
    }

    const body = await request.json();
    const { assignments } = body;
    
    if (!assignments || !Array.isArray(assignments)) {
      return NextResponse.json(
        { error: 'Missing assignments array' },
        { status: 400 }
      );
    }

    // Sprawdź czy zadanie istnieje
    const task = await prisma.tasks.findUnique({
      where: { task_id: taskId },
      include: {
        Projects: {
          select: { project_id: true, title: true }
        }
      }
    });

    if (!task) {
      return NextResponse.json(
        { error: 'Task not found' },
        { status: 404 }
      );
    }

    // Użyj transakcji dla bulk operations
    const result = await prisma.$transaction(async (tx) => {
      const createdAssignments = [];
      const errors = [];

      for (const assignment of assignments) {
        try {
          const { employee_id, crane_model_id } = assignment;

          // Sprawdź czy pracownik istnieje
          const employee = await tx.employees.findUnique({
            where: { employee_id: Number(employee_id) }
          });

          if (!employee) {
            errors.push(`Employee ${employee_id} not found`);
            continue;
          }

          // Sprawdź czy przypisanie już istnieje
          const existing = await tx.taskAssignments.findFirst({
            where: {
              task_id: taskId,
              employee_id: Number(employee_id)
            }
          });

          if (existing) {
            errors.push(`Employee ${employee_id} already assigned to this task`);
            continue;
          }

          // Utwórz przypisanie
          const newAssignment = await tx.taskAssignments.create({
            data: {
              task_id: taskId,
              employee_id: Number(employee_id),
              crane_model_id: crane_model_id ? Number(crane_model_id) : null,
              assigned_at: new Date()
            },
            include: {
              Employees: {
                select: { name: true, email: true, role: true }
              },
              CraneModel: {
                select: { name: true, code: true }
              }
            }
          });

          createdAssignments.push(newAssignment);

        } catch (error: any) {
          errors.push(`Error assigning employee ${assignment.employee_id}: ${error.message}`);
        }
      }

      return { created: createdAssignments, errors };
    });

    // Create notifications for all successful assignments
    if (result.created.length > 0) {
      try {
        await Promise.all(
          result.created.map((assignment: any) =>
            createTaskAssignmentNotification(
              assignment.employee_id,
              assignment.task_id,
              task.title,
              task.Projects?.project_id
            )
          )
        );
        console.log(`[API] Created ${result.created.length} task assignment notifications for task ${taskId}`);
      } catch (notificationError) {
        console.error("[API] Failed to create task assignment notifications:", notificationError);
        // Don't fail the entire request if notifications fail
      }
    }

    return NextResponse.json(result.created, { status: 201 });

  } catch (err: any) {
    console.error("Błąd POST /api/app/chef/tasks/[id]/assignments:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

// Helper function for worker availability (reused from other endpoints)
async function getWorkerAvailability(
  employeeId: number, 
  targetDate: Date | null = null, 
  excludeTaskId: number | null = null
) {
  const now = new Date();
  const weekFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
  const checkUntil = targetDate || weekFromNow;

  // Check for conflicting task assignments
  const conflictingTasks = await prisma.taskAssignments.findMany({
    where: {
      employee_id: employeeId,
      task_id: excludeTaskId ? { not: excludeTaskId } : undefined,
      Tasks: {
        isActive: true,
        OR: [
          { deadline: null },
          { 
            deadline: {
              gte: now,
              lte: checkUntil
            }
          }
        ]
      }
    },
    include: {
      Tasks: {
        select: {
          task_id: true,
          title: true,
          deadline: true,
          Projects: {
            select: { 
              project_id: true,
              title: true 
            }
          }
        }
      }
    }
  });

  // Calculate weekly work hours
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay() + 1); // Monday
  const endOfWeek = new Date(startOfWeek);
  endOfWeek.setDate(startOfWeek.getDate() + 6); // Sunday

  const weeklyEntries = await prisma.workEntries.findMany({
    where: {
      employee_id: employeeId,
      work_date: {
        gte: startOfWeek,
        lte: endOfWeek
      },
      isActive: true
    },
    select: {
      start_time: true,
      end_time: true,
      pause_minutes: true
    }
  });

  const weeklyHours = weeklyEntries.reduce((total, entry) => {
    if (entry.start_time && entry.end_time) {
      const hours = (new Date(entry.end_time).getTime() - new Date(entry.start_time).getTime()) / (1000 * 60 * 60);
      const pauseHours = (entry.pause_minutes || 0) / 60;
      return total + Math.max(0, hours - pauseHours);
    }
    return total;
  }, 0);

  const isAvailable = conflictingTasks.length === 0 && weeklyHours < 40;

  return {
    is_available: isAvailable,
    conflicting_tasks: conflictingTasks.map(ct => ({
      task_id: ct.Tasks.task_id,
      task_title: ct.Tasks.title,
      project_title: ct.Tasks.Projects?.title,
      project_id: ct.Tasks.Projects?.project_id,
      deadline: ct.Tasks.deadline,
      conflict_dates: ct.Tasks.deadline ? [ct.Tasks.deadline] : []
    })),
    work_hours_this_week: Math.round(weeklyHours * 100) / 100,
    work_hours_this_month: 0, // Can be calculated if needed
    max_weekly_hours: 40,
    next_available_date: conflictingTasks.length > 0 
      ? conflictingTasks.reduce((latest, ct) => {
          const taskDeadline = ct.Tasks.deadline ? new Date(ct.Tasks.deadline) : null;
          if (!taskDeadline) return latest;
          return !latest || taskDeadline > latest ? taskDeadline : latest;
        }, null as Date | null)
      : null
  };
}