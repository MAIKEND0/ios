// src/app/api/app/chef/projects/[id]/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/chef/projects/[id]
 * Pobiera szczegóły pojedynczego projektu z pełnymi relacjami
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const projectId = parseInt(id, 10);
    
    if (isNaN(projectId)) {
      return NextResponse.json({ error: "Invalid project ID" }, { status: 400 });
    }

    const { searchParams } = new URL(request.url);
    const includeTasks = searchParams.get('include_tasks') !== 'false';
    const includeStats = searchParams.get('include_stats') !== 'false';

    const project = await prisma.projects.findUnique({
      where: { project_id: projectId },
      include: {
        Customers: true,
        BillingSettings: {
          orderBy: { effective_from: 'desc' }
        },
        ...(includeTasks && {
          Tasks: {
            where: { isActive: true },
            orderBy: { created_at: 'desc' },
            include: {
              TaskAssignments: {
                include: {
                  Employees: {
                    select: {
                      employee_id: true,
                      name: true,
                      email: true,
                      role: true,
                      phone_number: true,
                      profilePictureUrl: true
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
              }
            }
          }
        })
      }
    });

    if (!project) {
      return NextResponse.json({ error: "Project not found" }, { status: 404 });
    }

    let responseData: any = project;

    // Dodaj statystyki jeśli wymagane
    if (includeStats) {
      const stats = await getProjectStatistics(projectId);
      responseData = { ...project, statistics: stats };
    }

    return NextResponse.json(responseData, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/chef/projects/[id]:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * PATCH /api/chef/projects/[id]
 * Aktualizuje projekt
 */
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const projectId = parseInt(id, 10);
    
    if (isNaN(projectId)) {
      return NextResponse.json({ error: "Invalid project ID" }, { status: 400 });
    }

    const body = await request.json();

    // Sprawdź czy projekt istnieje
    const existingProject = await prisma.projects.findUnique({
      where: { project_id: projectId }
    });

    if (!existingProject) {
      return NextResponse.json({ error: "Project not found" }, { status: 404 });
    }

    // Przygotuj dane do aktualizacji (tylko niepuste pola)
    const updateData: any = {};
    
    if (body.title !== undefined) updateData.title = body.title.trim();
    if (body.description !== undefined) updateData.description = body.description?.trim();
    if (body.start_date !== undefined) updateData.start_date = body.start_date ? new Date(body.start_date) : null;
    if (body.end_date !== undefined) updateData.end_date = body.end_date ? new Date(body.end_date) : null;
    if (body.status !== undefined) updateData.status = body.status;
    if (body.customer_id !== undefined) updateData.customer_id = parseInt(body.customer_id);
    if (body.street !== undefined) updateData.street = body.street?.trim();
    if (body.city !== undefined) updateData.city = body.city?.trim();
    if (body.zip !== undefined) updateData.zip = body.zip?.trim();
    if (body.isActive !== undefined) updateData.isActive = body.isActive;

    // Walidacja customer_id jeśli się zmienia
    if (updateData.customer_id && updateData.customer_id !== existingProject.customer_id) {
      const customer = await prisma.customers.findUnique({
        where: { customer_id: updateData.customer_id }
      });
      
      if (!customer) {
        return NextResponse.json({ error: "Customer not found" }, { status: 404 });
      }
    }

    // Aktualizuj projekt
    const updatedProject = await prisma.projects.update({
      where: { project_id: projectId },
      data: updateData,
      include: {
        Customers: true,
        BillingSettings: {
          orderBy: { effective_from: 'desc' },
          take: 1
        }
      }
    });

    return NextResponse.json(updatedProject, { status: 200 });

  } catch (err: any) {
    console.error("Błąd PATCH /api/chef/projects/[id]:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * DELETE /api/chef/projects/[id]
 * Soft delete projektu (ustawia isActive na false)
 */
export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const projectId = parseInt(id, 10);
    
    if (isNaN(projectId)) {
      return NextResponse.json({ error: "Invalid project ID" }, { status: 400 });
    }

    // Sprawdź czy projekt istnieje
    const existingProject = await prisma.projects.findUnique({
      where: { project_id: projectId }
    });

    if (!existingProject) {
      return NextResponse.json({ error: "Project not found" }, { status: 404 });
    }

    // Użyj transakcji do "usunięcia" projektu i powiązanych zasobów
    const result = await prisma.$transaction(async (tx) => {
      // Pobierz wszystkie zadania projektu
      const tasks = await tx.tasks.findMany({
        where: { project_id: projectId },
        select: { task_id: true }
      });

      const taskIds = tasks.map(task => task.task_id);
      let affectedAssignments = 0;
      let affectedWorkEntries = 0;

      if (taskIds.length > 0) {
        // Zlicz przypisania które będą dezaktywowane
        affectedAssignments = await tx.taskAssignments.count({
          where: { task_id: { in: taskIds } }
        });

        // Zlicz wpisy pracy które będą dezaktywowane
        affectedWorkEntries = await tx.workEntries.count({
          where: { task_id: { in: taskIds }, isActive: true }
        });

        // Dezaktywuj wpisy pracy
        await tx.workEntries.updateMany({
          where: { task_id: { in: taskIds } },
          data: { isActive: false }
        });

        // Dezaktywuj zadania
        await tx.tasks.updateMany({
          where: { project_id: projectId },
          data: { isActive: false }
        });
      }

      // Dezaktywuj projekt
      await tx.projects.update({
        where: { project_id: projectId },
        data: { isActive: false }
      });

      return {
        tasks: taskIds.length,
        assignments: affectedAssignments,
        work_entries: affectedWorkEntries
      };
    });

    return NextResponse.json({
      success: true,
      message: "Project archived successfully",
      affected_resources: result
    }, { status: 200 });

  } catch (err: any) {
    console.error("Błąd DELETE /api/chef/projects/[id]:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * Helper function to get project statistics
 */
async function getProjectStatistics(projectId: number) {
  const [
    totalTasks,
    activeTasks,
    totalWorkers,
    totalHoursData, // ✅ FIXED: Renamed and corrected
    recentDeadlines
  ] = await Promise.all([
    // Całkowita liczba zadań
    prisma.tasks.count({
      where: { project_id: projectId }
    }),
    
    // Aktywne zadania
    prisma.tasks.count({
      where: { project_id: projectId, isActive: true }
    }),
    
    // Liczba unikalnych pracowników
    prisma.taskAssignments.findMany({
      where: {
        Tasks: { project_id: projectId, isActive: true }
      },
      select: { employee_id: true },
      distinct: ['employee_id']
    }).then(workers => workers.length),
    
    // ✅ FIXED: Proper work entries calculation
    prisma.workEntries.findMany({
      where: {
        Tasks: { project_id: projectId },
        isActive: true,
        status: 'confirmed',
        start_time: { not: null },
        end_time: { not: null }
      },
      select: {
        start_time: true,
        end_time: true,
        pause_minutes: true
      }
    }),
    
    // Nadchodzące deadlines
    prisma.tasks.findMany({
      where: {
        project_id: projectId,
        isActive: true,
        deadline: {
          gte: new Date(),
          lte: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 dni
        }
      },
      select: {
        task_id: true,
        title: true,
        deadline: true
      },
      orderBy: { deadline: 'asc' },
      take: 5
    })
  ]);

  // ✅ FIXED: Calculate total hours manually from time entries
  const totalHours = totalHoursData.reduce((total, entry) => {
    if (entry.start_time && entry.end_time) {
      const startTime = new Date(entry.start_time);
      const endTime = new Date(entry.end_time);
      const hours = (endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60);
      const pauseHours = (entry.pause_minutes || 0) / 60;
      return total + Math.max(0, hours - pauseHours);
    }
    return total;
  }, 0);

  const completedTasks = totalTasks - activeTasks;
  const completionPercentage = totalTasks > 0 ? 
    Math.round((completedTasks / totalTasks) * 100) : 0;

  return {
    project_id: projectId,
    total_tasks: totalTasks,
    completed_tasks: completedTasks,
    active_tasks: activeTasks,
    total_workers: totalWorkers,
    total_hours: Math.round(totalHours * 100) / 100, // ✅ FIXED: Now returns actual calculated hours
    completion_percentage: completionPercentage,
    upcoming_deadlines: recentDeadlines.map(task => ({
      task_id: task.task_id,
      title: task.title,
      deadline: task.deadline,
      days_until_deadline: Math.ceil((new Date(task.deadline!).getTime() - Date.now()) / (1000 * 60 * 60 * 24))
    }))
  };
}