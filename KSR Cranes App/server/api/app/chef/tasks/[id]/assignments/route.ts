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

    // Sprawdź czy zadanie istnieje i pobierz wymagane certyfikaty i typy dźwigów
    const task = await prisma.tasks.findUnique({
      where: { task_id: taskId },
      include: {
        Projects: {
          select: { project_id: true, title: true }
        },
        CraneCategory: true
      }
    });

    if (!task) {
      return NextResponse.json(
        { error: 'Task not found' },
        { status: 404 }
      );
    }

    // Parse required certificates from crane category
    let requiredCertificateIds: number[] = [];
    if (task.CraneCategory?.required_certificates) {
      try {
        const requiredCerts = JSON.parse(task.CraneCategory.required_certificates as string);
        if (Array.isArray(requiredCerts)) {
          requiredCertificateIds = requiredCerts.map(id => parseInt(id)).filter(id => !isNaN(id));
        }
      } catch (e) {
        console.error("[API] Error parsing required certificates:", e);
      }
    }

    // Parse required crane types from task
    let requiredCraneTypeIds: number[] = [];
    if (task.required_crane_types) {
      try {
        const requiredTypes = JSON.parse(task.required_crane_types as string);
        if (Array.isArray(requiredTypes)) {
          requiredCraneTypeIds = requiredTypes.map(id => parseInt(id)).filter(id => !isNaN(id));
        }
      } catch (e) {
        console.error("[API] Error parsing required crane types:", e);
      }
    }

    // Użyj transakcji dla bulk operations
    const result = await prisma.$transaction(async (tx) => {
      const createdAssignments = [];
      const errors = [];

      for (const assignment of assignments) {
        try {
          const { employee_id, crane_model_id } = assignment;

          // Sprawdź czy pracownik istnieje i ma wymagane certyfikaty oraz uprawnienia do obsługi dźwigów
          const employee = await tx.employees.findUnique({
            where: { employee_id: Number(employee_id) },
            include: {
              WorkerSkills: {
                where: {
                  is_certified: true,
                  certificate_type_id: { in: requiredCertificateIds }
                }
              },
              EmployeeCraneTypes: {
                where: {
                  crane_type_id: { in: requiredCraneTypeIds }
                }
              }
            }
          });

          if (!employee) {
            errors.push(`Employee ${employee_id} not found`);
            continue;
          }

          // Validate certificates if required and not skipped
          if (requiredCertificateIds.length > 0 && !assignment.skip_certificate_validation) {
            const workerValidCertIds = employee.WorkerSkills
              .filter(skill => 
                skill.is_certified && 
                (!skill.certification_expires || skill.certification_expires >= new Date())
              )
              .map(skill => skill.certificate_type_id)
              .filter(id => id !== null) as number[];

            const missingCertIds = requiredCertificateIds.filter(certId => !workerValidCertIds.includes(certId));

            if (missingCertIds.length > 0) {
              errors.push(`Employee ${employee_id} missing required certificates: ${missingCertIds.join(', ')}`);
              continue;
            }
          }

          // Validate crane type skills if required and not skipped
          if (requiredCraneTypeIds.length > 0 && !assignment.skip_crane_type_validation) {
            const workerCraneTypeIds = employee.EmployeeCraneTypes
              .map(ect => ect.crane_type_id);

            const missingCraneTypeIds = requiredCraneTypeIds.filter(
              typeId => !workerCraneTypeIds.includes(typeId)
            );

            if (missingCraneTypeIds.length > 0) {
              errors.push(`Employee ${employee_id} missing required crane type skills: ${missingCraneTypeIds.join(', ')}`);
              continue;
            }
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

          // Utwórz przypisanie z management calendar fields
          const newAssignment = await tx.taskAssignments.create({
            data: {
              task_id: taskId,
              employee_id: Number(employee_id),
              crane_model_id: crane_model_id ? Number(crane_model_id) : null,
              assigned_at: new Date(),
              // ✅ MANAGEMENT CALENDAR FIELDS: Add assignment scheduling fields
              work_date: assignment.work_date ? new Date(assignment.work_date) : null,
              status: assignment.status && ['assigned', 'active', 'completed', 'cancelled'].includes(assignment.status) 
                ? assignment.status 
                : 'assigned',
              notes: assignment.notes?.trim() || null
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
