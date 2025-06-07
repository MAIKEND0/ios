// src/app/api/app/chef/task-assignments/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";
import { createTaskAssignmentNotification, createNotification } from "../../../../../lib/notificationService";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/task-assignments
 * Pobiera przypisania zadań z filtrami
 */
export async function GET(request: Request): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const taskId = searchParams.get('task_id');
    const employeeId = searchParams.get('employee_id');
    const projectId = searchParams.get('project_id');
    const includeAvailability = searchParams.get('include_availability') === 'true';
    
    // Build query based on provided parameters
    const where: any = {};
    if (taskId) where.task_id = parseInt(taskId);
    if (employeeId) where.employee_id = parseInt(employeeId);
    
    // If project_id is provided, add a nested filter for the Tasks relation
    if (projectId) {
      where.Tasks = {
        project_id: parseInt(projectId)
      };
    }
    
    const taskAssignments = await prisma.taskAssignments.findMany({
      where,
      include: {
        Employees: {
          select: {
            employee_id: true,
            name: true,
            email: true,
            phone_number: true,
            profilePictureUrl: true,
            role: true,
            has_driving_license: true,
            driving_license_category: true,
            EmployeeCraneTypes: {
              include: {
                CraneTypes: {
                  select: {
                    crane_type_id: true,
                    name: true,
                    description: true
                  }
                }
              }
            }
          }
        },
        Tasks: {
          select: {
            task_id: true,
            title: true,
            description: true,
            deadline: true,
            Projects: {
              select: {
                project_id: true,
                title: true,
                status: true
              }
            }
          }
        },
        CraneModel: {
          select: {
            id: true,
            name: true,
            code: true,
            description: true,
            maxLoadCapacity: true,
            maxHeight: true
          }
        }
      },
      orderBy: {
        assigned_at: 'desc'
      }
    });

    // Add availability info if requested
    const assignmentsWithAvailability = includeAvailability 
      ? await Promise.all(taskAssignments.map(async (assignment) => {
          const availability = await getWorkerAvailability(assignment.employee_id, assignment.Tasks.deadline);
          return { ...assignment, availability };
        }))
      : taskAssignments;
    
    return NextResponse.json(assignmentsWithAvailability, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/app/chef/task-assignments:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * POST /api/app/chef/task-assignments
 * Tworzy nowe przypisanie pracownika do zadania
 */
export async function POST(request: Request): Promise<NextResponse> {
  try {
    const body = await request.json();
    
    // Sprawdź czy to bulk assignment czy pojedynczy
    if (body.assignments && Array.isArray(body.assignments)) {
      return handleBulkAssignment(body);
    }
    
    const { task_id, employee_id, crane_model_id, hiring_request_id } = body;
    
    if (!task_id || !employee_id) {
      return NextResponse.json(
        { error: 'Missing task_id or employee_id' },
        { status: 400 }
      );
    }
    
    // Sprawdź czy pracownik i zadanie istnieją
    const [employee, task] = await Promise.all([
      prisma.employees.findUnique({ 
        where: { employee_id: Number(employee_id) },
        select: { employee_id: true, name: true, email: true, role: true }
      }),
      prisma.tasks.findUnique({ 
        where: { task_id: Number(task_id) },
        include: { 
          Projects: {
            select: { project_id: true, title: true }
          }
        }
      })
    ]);
    
    if (!employee) {
      return NextResponse.json(
        { error: 'Employee not found' },
        { status: 404 }
      );
    }
    
    if (!task) {
      return NextResponse.json(
        { error: 'Task not found' },
        { status: 404 }
      );
    }
    
    // Sprawdź czy przypisanie już istnieje
    const existingAssignment = await prisma.taskAssignments.findFirst({
      where: {
        task_id: Number(task_id),
        employee_id: Number(employee_id)
      }
    });
    
    if (existingAssignment) {
      return NextResponse.json(
        { 
          message: "Assignment already exists",
          assignment: existingAssignment 
        },
        { status: 200 }
      );
    }

    // Użyj transakcji do utworzenia przypisania
    const result = await prisma.$transaction(async (tx) => {
      // Utwórz nowe przypisanie
      const newAssignment = await tx.taskAssignments.create({
        data: {
          task_id: Number(task_id),
          employee_id: Number(employee_id),
          crane_model_id: crane_model_id ? Number(crane_model_id) : null,
          assigned_at: new Date()
        }
      });
      
      // Zaktualizuj hiring request jeśli podano
      if (hiring_request_id) {
        await tx.operatorHiringRequest.update({
          where: { id: Number(hiring_request_id) },
          data: {
            assignedTaskId: Number(task_id),
            assignedOperatorId: Number(employee_id),
            assignedProjectId: task.Projects?.project_id
          }
        });
      }
      
      return newAssignment;
    });
    
    // Create notification for assigned employee
    try {
      await createTaskAssignmentNotification(
        Number(employee_id),
        Number(task_id),
        task.title,
        task.Projects?.project_id
      );
      console.log(`[API] Created task assignment notification for employee ${employee_id}, task ${task_id}`);
    } catch (notificationError) {
      console.error("[API] Failed to create task assignment notification:", notificationError);
      // Don't fail the entire request if notifications fail
    }
    
    // Pobierz pełne przypisanie z relacjami
    const fullAssignment = await prisma.taskAssignments.findUnique({
      where: { assignment_id: result.assignment_id },
      include: {
        Employees: {
          select: {
            employee_id: true,
            name: true,
            email: true,
            role: true
          }
        },
        Tasks: {
          select: {
            task_id: true,
            title: true,
            Projects: {
              select: {
                project_id: true,
                title: true
              }
            }
          }
        },
        CraneModel: {
          select: {
            id: true,
            name: true,
            code: true
          }
        }
      }
    });
    
    return NextResponse.json(fullAssignment, { status: 201 });

  } catch (err: any) {
    console.error("Błąd POST /api/app/chef/task-assignments:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * DELETE /api/app/chef/task-assignments?assignment_id=X
 * Usuwa przypisanie zadania
 */
export async function DELETE(request: Request): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const assignmentId = searchParams.get('assignment_id');
    
    if (!assignmentId) {
      return NextResponse.json(
        { error: 'Missing assignment_id parameter' },
        { status: 400 }
      );
    }
    
    // Pobierz szczegóły przypisania przed usunięciem
    const assignment = await prisma.taskAssignments.findUnique({
      where: { assignment_id: parseInt(assignmentId) },
      include: {
        Employees: {
          select: { employee_id: true, name: true }
        },
        Tasks: {
          select: { 
            task_id: true, 
            title: true,
            Projects: {
              select: { project_id: true }
            }
          }
        }
      }
    });
    
    if (!assignment) {
      return NextResponse.json(
        { error: 'Task assignment not found' },
        { status: 404 }
      );
    }

    // Użyj transakcji do usunięcia
    const result = await prisma.$transaction(async (tx) => {
      // Znajdź hiring requests powiązane z tym przypisaniem
      const hiringRequests = await tx.operatorHiringRequest.findMany({
        where: {
          assignedTaskId: assignment.task_id,
          assignedOperatorId: assignment.employee_id
        }
      });
      
      // Wyczyść przypisania w hiring requests
      if (hiringRequests.length > 0) {
        await tx.operatorHiringRequest.updateMany({
          where: {
            assignedTaskId: assignment.task_id,
            assignedOperatorId: assignment.employee_id
          },
          data: {
            assignedTaskId: null,
            assignedOperatorId: null,
            assignedProjectId: null
          }
        });
      }
      
      // Usuń przypisanie
      await tx.taskAssignments.delete({
        where: { assignment_id: parseInt(assignmentId) }
      });

      // Store assignment info for notification after transaction
      return {
        employee_id: assignment.employee_id,
        task_id: assignment.task_id,
        task_title: assignment.Tasks.title,
        project_id: assignment.Tasks.Projects?.project_id
      };
    });
    
    // Create unassignment notification
    try {
      await createNotification({
        employeeId: result.employee_id,
        type: 'TASK_UNASSIGNED',
        title: 'Task unassigned',
        message: `Du er ikke længere tildelt opgaven: ${result.task_title}`,
        taskId: result.task_id,
        projectId: result.project_id,
        priority: 'NORMAL',
        category: 'TASK',
        actionRequired: false,
      });
      console.log(`[API] Created task unassignment notification for employee ${result.employee_id}, task ${result.task_id}`);
    } catch (notificationError) {
      console.error("[API] Failed to create task unassignment notification:", notificationError);
      // Don't fail the entire request if notifications fail
    }
    
    return NextResponse.json({
      success: true,
      message: "Assignment removed successfully",
      employee_name: assignment.Employees.name,
      task_title: assignment.Tasks.title
    }, { status: 200 });

  } catch (err: any) {
    console.error("Błąd DELETE /api/app/chef/task-assignments:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * Helper function - Bulk assignment creation
 */
async function handleBulkAssignment(body: any): Promise<NextResponse> {
  const { task_id, assignments } = body;
  
  if (!task_id || !assignments || !Array.isArray(assignments)) {
    return NextResponse.json(
      { error: 'Missing task_id or assignments array' },
      { status: 400 }
    );
  }

  try {
    // Sprawdź czy zadanie istnieje
    const task = await prisma.tasks.findUnique({
      where: { task_id: Number(task_id) },
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
              task_id: Number(task_id),
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
              task_id: Number(task_id),
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
          result.created.map(async (assignment: any) => {
            // Get task details for the notification
            const task = await prisma.tasks.findUnique({
              where: { task_id: assignment.task_id },
              include: {
                Projects: {
                  select: { project_id: true }
                }
              }
            });
            
            if (task) {
              return createTaskAssignmentNotification(
                assignment.employee_id,
                assignment.task_id,
                task.title,
                task.Projects?.project_id
              );
            }
          })
        );
        console.log(`[API] Created ${result.created.length} bulk task assignment notifications`);
      } catch (notificationError) {
        console.error("[API] Failed to create bulk assignment notifications:", notificationError);
        // Don't fail the entire request if notifications fail
      }
    }

    return NextResponse.json({
      success: true,
      message: `${result.created.length} assignments created successfully`,
      created_assignments: result.created,
      errors: result.errors
    }, { status: 201 });

  } catch (err: any) {
    console.error("Błąd bulk assignment:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * Helper function - Get worker availability
 */
async function getWorkerAvailability(employeeId: number, deadline: Date | null) {
  const now = new Date();
  const weekFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
  const checkUntil = deadline || weekFromNow;

  // Sprawdź konflikty w zadaniach
  const conflictingTasks = await prisma.taskAssignments.findMany({
    where: {
      employee_id: employeeId,
      Tasks: {
        isActive: true,
        OR: [
          { deadline: null }, // Zadania bez deadline mogą kolidować
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
            select: { title: true }
          }
        }
      }
    }
  });

  // Oblicz godziny pracy w tym tygodniu
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay() + 1); // Monday
  const endOfWeek = new Date(startOfWeek);
  endOfWeek.setDate(startOfWeek.getDate() + 6); // Sunday

  const weeklyHours = await prisma.workEntries.findMany({
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

  const totalWeeklyHours = weeklyHours.reduce((total, entry) => {
    if (entry.start_time && entry.end_time) {
      const hours = (new Date(entry.end_time).getTime() - new Date(entry.start_time).getTime()) / (1000 * 60 * 60);
      const pauseHours = (entry.pause_minutes || 0) / 60;
      return total + Math.max(0, hours - pauseHours);
    }
    return total;
  }, 0);

  return {
    is_available: conflictingTasks.length === 0 && totalWeeklyHours < 40,
    conflicting_tasks: conflictingTasks.map(ct => ({
      task_id: ct.Tasks.task_id,
      task_title: ct.Tasks.title,
      project_title: ct.Tasks.Projects?.title,
      deadline: ct.Tasks.deadline
    })),
    work_hours_this_week: Math.round(totalWeeklyHours * 100) / 100,
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