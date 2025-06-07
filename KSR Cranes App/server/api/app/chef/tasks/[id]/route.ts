// src/app/api/app/chef/tasks/[id]/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";
import { createNotification } from "../../../../../../lib/notificationService";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

// Helper function to safely check if required_crane_types is a non-empty array
function hasRequiredCraneTypes(craneTypes: any): boolean {
  return Array.isArray(craneTypes) && craneTypes.length > 0;
}

// Helper function to safely get crane types as array
function getCraneTypesArray(craneTypes: any): string[] {
  return Array.isArray(craneTypes) ? craneTypes : [];
}

/**
 * GET /api/app/chef/tasks/[id]
 * Pobiera szczegóły pojedynczego zadania z equipment requirements
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const taskId = parseInt(id, 10);
    
    if (isNaN(taskId)) {
      return NextResponse.json({ error: "Invalid task ID" }, { status: 400 });
    }

    const { searchParams } = new URL(request.url);
    const includeWorkEntries = searchParams.get('include_work_entries') === 'true';
    const includeEquipment = searchParams.get('include_equipment') !== 'false'; // default true

    const task = await prisma.tasks.findUnique({
      where: { task_id: taskId },
      include: {
        Projects: {
          include: {
            Customers: {
              select: {
                customer_id: true,
                name: true,
                contact_email: true,
                phone: true
              }
            }
          }
        },
        TaskAssignments: {
          include: {
            Employees: {
              select: {
                employee_id: true,
                name: true,
                email: true,
                role: true,
                phone_number: true,
                profilePictureUrl: true,
                has_driving_license: true,
                driving_license_category: true
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
          }
        },
        Employees: {
          select: {
            employee_id: true,
            name: true,
            email: true,
            phone_number: true,
            role: true,
            profilePictureUrl: true
          }
        },
        ...(includeWorkEntries && {
          WorkEntries: {
            where: { isActive: true },
            include: {
              Employees: {
                select: {
                  employee_id: true,
                  name: true
                }
              }
            },
            orderBy: { work_date: 'desc' }
          }
        }),
        conversation: {
          include: {
            conversationParticipants: {
              include: {
                employee: {
                  select: {
                    employee_id: true,
                    name: true,
                    role: true
                  }
                }
              }
            }
          }
        },
        // ✅ DODANO: Include equipment relations
        ...(includeEquipment && {
          CraneModel: {
            select: {
              id: true,
              name: true,
              code: true,
              description: true,
              maxLoadCapacity: true,
              maxHeight: true,
              maxRadius: true,
              enginePower: true,
              specifications: true,
              imageUrl: true,
              brand: {
                select: {
                  id: true,
                  name: true,
                  code: true,
                  logoUrl: true,
                  website: true
                }
              },
              type: {
                select: {
                  id: true,
                  name: true,
                  code: true,
                  description: true,
                  category: {
                    select: {
                      id: true,
                      name: true,
                      code: true
                    }
                  }
                }
              }
            }
          },
          CraneCategory: {
            select: {
              id: true,
              name: true,
              code: true,
              description: true,
              iconUrl: true,
              displayOrder: true
            }
          },
          CraneBrand: {
            select: {
              id: true,
              name: true,
              code: true,
              logoUrl: true,
              website: true,
              description: true,
              foundedYear: true,
              headquarters: true
            }
          }
        })
      }
    });

    if (!task) {
      return NextResponse.json({ error: "Task not found" }, { status: 404 });
    }

    // Oblicz statystyki zadania
    const statistics = await getTaskStatistics(taskId);

    // ✅ DODANO: Enhanced task response with equipment information
    const enhancedTask = {
      ...task,
      statistics,
      // ✅ Parse and structure equipment requirements with proper type checking
      equipment_requirements: {
        required_crane_types: getCraneTypesArray(task.required_crane_types),
        preferred_crane_model_id: task.preferred_crane_model_id,
        equipment_category_id: task.equipment_category_id,
        equipment_brand_id: task.equipment_brand_id,
        // Include full objects for convenience
        preferred_crane_model: task.CraneModel,
        equipment_category: task.CraneCategory,
        equipment_brand: task.CraneBrand,
        // Equipment summary for quick checks with proper type checking
        has_equipment_requirements: !!(
          hasRequiredCraneTypes(task.required_crane_types) || 
          task.preferred_crane_model_id || 
          task.equipment_category_id || 
          task.equipment_brand_id
        )
      }
    };

    return NextResponse.json(enhancedTask, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/app/chef/tasks/[id]:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * PATCH /api/app/chef/tasks/[id]
 * Aktualizuje zadanie włącznie z equipment requirements
 */
export async function PATCH(
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

    // Sprawdź czy zadanie istnieje
    const existingTask = await prisma.tasks.findUnique({
      where: { task_id: taskId }
    });

    if (!existingTask) {
      return NextResponse.json({ error: "Task not found" }, { status: 404 });
    }

    console.log("[API] Updating task with equipment:", {
      task_id: taskId,
      equipment_updates: {
        required_crane_types: body.required_crane_types,
        preferred_crane_model_id: body.preferred_crane_model_id,
        equipment_category_id: body.equipment_category_id,
        equipment_brand_id: body.equipment_brand_id
      }
    });

    // Przygotuj dane do aktualizacji
    const updateData: any = {};
    
    // Basic task fields
    if (body.title !== undefined) updateData.title = body.title.trim();
    if (body.description !== undefined) updateData.description = body.description?.trim();
    if (body.deadline !== undefined) updateData.deadline = body.deadline ? new Date(body.deadline) : null;
    if (body.supervisor_name !== undefined) updateData.supervisor_name = body.supervisor_name?.trim();
    if (body.supervisor_email !== undefined) updateData.supervisor_email = body.supervisor_email?.trim();
    if (body.supervisor_phone !== undefined) updateData.supervisor_phone = body.supervisor_phone?.trim();
    if (body.supervisor_id !== undefined) updateData.supervisor_id = body.supervisor_id ? parseInt(body.supervisor_id) : null;
    if (body.isActive !== undefined) updateData.isActive = body.isActive;

    // ✅ DODANO: Equipment fields with proper validation
    if (body.required_crane_types !== undefined) {
      updateData.required_crane_types = Array.isArray(body.required_crane_types) 
        ? body.required_crane_types 
        : [];
    }
    
    if (body.preferred_crane_model_id !== undefined) {
      updateData.preferred_crane_model_id = body.preferred_crane_model_id 
        ? parseInt(body.preferred_crane_model_id) 
        : null;
    }
    
    if (body.equipment_category_id !== undefined) {
      updateData.equipment_category_id = body.equipment_category_id 
        ? parseInt(body.equipment_category_id) 
        : null;
    }
    
    if (body.equipment_brand_id !== undefined) {
      updateData.equipment_brand_id = body.equipment_brand_id 
        ? parseInt(body.equipment_brand_id) 
        : null;
    }

    // Walidacja supervisor_id jeśli się zmienia
    if (updateData.supervisor_id && updateData.supervisor_id !== existingTask.supervisor_id) {
      const supervisor = await prisma.employees.findUnique({
        where: { employee_id: updateData.supervisor_id }
      });
      
      if (!supervisor) {
        return NextResponse.json({ error: "Supervisor not found" }, { status: 404 });
      }
    }

    // ✅ Walidacja equipment IDs jeśli się zmieniają
    if (updateData.preferred_crane_model_id && updateData.preferred_crane_model_id !== existingTask.preferred_crane_model_id) {
      const craneModel = await prisma.craneModel.findUnique({
        where: { id: updateData.preferred_crane_model_id }
      });
      
      if (!craneModel) {
        return NextResponse.json({ error: "Crane model not found" }, { status: 404 });
      }
    }

    if (updateData.equipment_category_id && updateData.equipment_category_id !== existingTask.equipment_category_id) {
      const category = await prisma.craneCategory.findUnique({
        where: { id: updateData.equipment_category_id }
      });
      
      if (!category) {
        return NextResponse.json({ error: "Equipment category not found" }, { status: 404 });
      }
    }

    if (updateData.equipment_brand_id && updateData.equipment_brand_id !== existingTask.equipment_brand_id) {
      const brand = await prisma.craneBrand.findUnique({
        where: { id: updateData.equipment_brand_id }
      });
      
      if (!brand) {
        return NextResponse.json({ error: "Equipment brand not found" }, { status: 404 });
      }
    }

    // Aktualizuj zadanie
    const updatedTask = await prisma.tasks.update({
      where: { task_id: taskId },
      data: updateData,
      include: {
        Projects: {
          select: {
            project_id: true,
            title: true,
            status: true
          }
        },
        TaskAssignments: {
          include: {
            Employees: {
              select: {
                employee_id: true,
                name: true,
                email: true,
                role: true
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
        },
        Employees: {
          select: {
            employee_id: true,
            name: true,
            email: true,
            phone_number: true,
            role: true
          }
        },
        // ✅ DODANO: Include updated equipment relations
        CraneModel: {
          select: {
            id: true,
            name: true,
            code: true,
            description: true,
            maxLoadCapacity: true,
            maxHeight: true,
            maxRadius: true,
            brand: {
              select: {
                id: true,
                name: true,
                code: true,
                logoUrl: true
              }
            },
            type: {
              select: {
                id: true,
                name: true,
                code: true
              }
            }
          }
        },
        CraneCategory: {
          select: {
            id: true,
            name: true,
            code: true,
            description: true,
            iconUrl: true
          }
        },
        CraneBrand: {
          select: {
            id: true,
            name: true,
            code: true,
            logoUrl: true,
            website: true
          }
        }
      }
    });

    console.log("[API] ✅ Task updated with equipment:", {
      task_id: updatedTask.task_id,
      required_crane_types: updatedTask.required_crane_types,
      preferred_crane_model_id: updatedTask.preferred_crane_model_id,
      equipment_category_id: updatedTask.equipment_category_id,
      equipment_brand_id: updatedTask.equipment_brand_id
    });

    // ✅ Enhanced response with equipment information and proper type checking
    const enhancedTask = {
      ...updatedTask,
      equipment_requirements: {
        required_crane_types: getCraneTypesArray(updatedTask.required_crane_types),
        preferred_crane_model_id: updatedTask.preferred_crane_model_id,
        equipment_category_id: updatedTask.equipment_category_id,
        equipment_brand_id: updatedTask.equipment_brand_id,
        preferred_crane_model: updatedTask.CraneModel,
        equipment_category: updatedTask.CraneCategory,
        equipment_brand: updatedTask.CraneBrand
      }
    };

    return NextResponse.json(enhancedTask, { status: 200 });

  } catch (err: any) {
    console.error("Błąd PATCH /api/app/chef/tasks/[id]:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * DELETE /api/app/chef/tasks/[id]
 * Soft delete zadania (ustawia isActive na false)
 */
export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const taskId = parseInt(id, 10);
    
    if (isNaN(taskId)) {
      return NextResponse.json({ error: "Invalid task ID" }, { status: 400 });
    }

    // Sprawdź czy zadanie istnieje
    const existingTask = await prisma.tasks.findUnique({
      where: { task_id: taskId },
      include: {
        TaskAssignments: {
          include: {
            Employees: {
              select: { name: true }
            }
          }
        }
      }
    });

    if (!existingTask) {
      return NextResponse.json({ error: "Task not found" }, { status: 404 });
    }

    // Użyj transakcji do "usunięcia" zadania
    const result = await prisma.$transaction(async (tx) => {
      // Zlicz wpisy pracy które będą dezaktywowane
      const affectedWorkEntries = await tx.workEntries.count({
        where: { task_id: taskId, isActive: true }
      });

      // Dezaktywuj wpisy pracy
      await tx.workEntries.updateMany({
        where: { task_id: taskId },
        data: { isActive: false }
      });

      // Usuń task assignments (hard delete, bo to tylko relacje)
      await tx.taskAssignments.deleteMany({
        where: { task_id: taskId }
      });

      // Dezaktywuj zadanie
      await tx.tasks.update({
        where: { task_id: taskId },
        data: { isActive: false }
      });

      return {
        assignments: existingTask.TaskAssignments,
        title: existingTask.title,
        work_entries: affectedWorkEntries,
        reassigned_workers: existingTask.TaskAssignments.map(a => a.Employees.name).join(', ')
      };
    });

    // Create task completion notifications for assigned employees
    if (result.assignments && result.assignments.length > 0) {
      try {
        await Promise.all(
          result.assignments.map((assignment: any) =>
            createNotification({
              employeeId: assignment.employee_id,
              type: 'TASK_COMPLETED',
              title: 'Task completed',
              message: `Opgave "${result.title}" er blevet afsluttet`,
              taskId: taskId,
              priority: 'NORMAL',
              category: 'TASK',
              actionRequired: false,
            })
          )
        );
        console.log(`[API] Created ${result.assignments.length} task completion notifications for task ${taskId}`);
      } catch (notificationError) {
        console.error("[API] Failed to create task completion notifications:", notificationError);
        // Don't fail the entire request if notifications fail
      }
    }

    return NextResponse.json({
      success: true,
      message: "Task archived successfully",
      reassigned_workers: result.assignments,
      affected_resources: {
        assignments: result.assignments,
        work_entries: result.work_entries
      }
    }, { status: 200 });

  } catch (err: any) {
    console.error("Błąd DELETE /api/app/chef/tasks/[id]:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * Helper function to get task statistics
 */
async function getTaskStatistics(taskId: number) {
  const [
    assignmentsCount,
    workEntriesCount,
    totalHours,
    pendingHours,
    completedHours
  ] = await Promise.all([
    // Liczba przypisanych pracowników
    prisma.taskAssignments.count({
      where: { task_id: taskId }
    }),
    
    // Liczba wpisów pracy
    prisma.workEntries.count({
      where: { task_id: taskId, isActive: true }
    }),
    
    // Całkowite godziny (wszystkie statusy)
    prisma.workEntries.findMany({
      where: { task_id: taskId, isActive: true },
      select: { start_time: true, end_time: true, pause_minutes: true }
    }).then(entries => {
      return entries.reduce((total, entry) => {
        if (entry.start_time && entry.end_time) {
          const hours = (new Date(entry.end_time).getTime() - new Date(entry.start_time).getTime()) / (1000 * 60 * 60);
          const pauseHours = (entry.pause_minutes || 0) / 60;
          return total + Math.max(0, hours - pauseHours);
        }
        return total;
      }, 0);
    }),
    
    // Oczekujące godziny
    prisma.workEntries.findMany({
      where: { 
        task_id: taskId, 
        isActive: true,
        status: 'pending'
      },
      select: { start_time: true, end_time: true, pause_minutes: true }
    }).then(entries => {
      return entries.reduce((total, entry) => {
        if (entry.start_time && entry.end_time) {
          const hours = (new Date(entry.end_time).getTime() - new Date(entry.start_time).getTime()) / (1000 * 60 * 60);
          const pauseHours = (entry.pause_minutes || 0) / 60;
          return total + Math.max(0, hours - pauseHours);
        }
        return total;
      }, 0);
    }),
    
    // Zatwierdzone godziny
    prisma.workEntries.findMany({
      where: { 
        task_id: taskId, 
        isActive: true,
        status: 'confirmed'
      },
      select: { start_time: true, end_time: true, pause_minutes: true }
    }).then(entries => {
      return entries.reduce((total, entry) => {
        if (entry.start_time && entry.end_time) {
          const hours = (new Date(entry.end_time).getTime() - new Date(entry.start_time).getTime()) / (1000 * 60 * 60);
          const pauseHours = (entry.pause_minutes || 0) / 60;
          return total + Math.max(0, hours - pauseHours);
        }
        return total;
      }, 0);
    })
  ]);

  return {
    assignments_count: assignmentsCount,
    work_entries_count: workEntriesCount,
    total_hours: Math.round(totalHours * 100) / 100,
    pending_hours: Math.round(pendingHours * 100) / 100,
    completed_hours: Math.round(completedHours * 100) / 100,
    completion_percentage: totalHours > 0 ? Math.round((completedHours / totalHours) * 100) : 0
  };
}