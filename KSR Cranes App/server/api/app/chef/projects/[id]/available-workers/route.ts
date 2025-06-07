// src/app/api/app/chef/projects/[id]/available-workers/route.ts
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

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

// Helper function for worker availability (same as tasks endpoint)
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

/**
 * GET /api/app/chef/projects/[id]/available-workers
 * Pobiera dostępnych pracowników dla projektu (dla tworzenia nowych zadań)
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
    const date = searchParams.get('date');
    const craneTypes = searchParams.get('crane_types');
    const includeAvailability = searchParams.get('include_availability') === 'true';
    const excludeTaskId = searchParams.get('exclude_task_id');
    
    // Sprawdź czy projekt istnieje
    const project = await prisma.projects.findUnique({
      where: { project_id: projectId },
      select: {
        project_id: true,
        title: true,
        status: true
      }
    });

    if (!project) {
      return NextResponse.json({ error: "Project not found" }, { status: 404 });
    }

    console.log(`[API] Loading workers for project ${projectId} (${project.title})`);

    // Build where clause for workers
    const where: any = {
      role: 'arbejder', // Worker role
      is_activated: true
    };
    
    // Get workers with their crane types
    const workers = await prisma.employees.findMany({
      where,
      select: {
        employee_id: true,
        name: true,
        email: true,
        role: true,
        phone_number: true,
        profilePictureUrl: true,
        has_driving_license: true,
        driving_license_category: true,
        driving_license_expiration: true,
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
      },
      orderBy: { name: 'asc' }
    });

    console.log(`[API] Found ${workers.length} total workers`);

    // Filter by crane types if specified
    let filteredWorkers = workers;
    if (craneTypes) {
      const requiredCraneTypeIds = craneTypes.split(',').map(id => parseInt(id.trim()));
      filteredWorkers = workers.filter(worker => 
        worker.EmployeeCraneTypes.some(ect => 
          requiredCraneTypeIds.includes(ect.CraneTypes.crane_type_id)
        )
      );
      console.log(`[API] Filtered to ${filteredWorkers.length} workers with required crane types: ${craneTypes}`);
    }

    // Add availability information if requested
    const workersWithAvailability = includeAvailability 
      ? await Promise.all(filteredWorkers.map(async (worker) => {
          const availability = await getWorkerAvailability(
            worker.employee_id, 
            date ? new Date(date) : null,
            excludeTaskId ? parseInt(excludeTaskId) : null // Don't exclude any task for new task creation
          );
          return {
            employee: {
              employee_id: worker.employee_id,
              name: worker.name,
              email: worker.email,
              role: worker.role,
              phone_number: worker.phone_number,
              profile_picture_url: worker.profilePictureUrl,
              is_activated: true,
              has_driving_license: worker.has_driving_license,
              driving_license_category: worker.driving_license_category,
              driving_license_expiration: worker.driving_license_expiration
            },
            availability,
            crane_types: worker.EmployeeCraneTypes.map(ect => ({
              id: ect.CraneTypes.crane_type_id,
              name: ect.CraneTypes.name,
              description: ect.CraneTypes.description
            }))
          };
        }))
      : filteredWorkers.map(worker => ({
          employee: {
            employee_id: worker.employee_id,
            name: worker.name,
            email: worker.email,
            role: worker.role,
            phone_number: worker.phone_number,
            profile_picture_url: worker.profilePictureUrl,
            is_activated: true,
            has_driving_license: worker.has_driving_license,
            driving_license_category: worker.driving_license_category,
            driving_license_expiration: worker.driving_license_expiration
          },
          availability: null,
          crane_types: worker.EmployeeCraneTypes.map(ect => ({
            id: ect.CraneTypes.crane_type_id,
            name: ect.CraneTypes.name,
            description: ect.CraneTypes.description
          }))
        }));

    // Calculate totals
    const totalAvailable = includeAvailability 
      ? workersWithAvailability.filter(w => w.availability?.is_available).length
      : workersWithAvailability.length;
    
    const totalWithConflicts = includeAvailability 
      ? workersWithAvailability.filter(w => w.availability && !w.availability.is_available).length
      : 0;

    console.log(`[API] ✅ Returning ${workersWithAvailability.length} workers (${totalAvailable} available, ${totalWithConflicts} with conflicts)`);

    return NextResponse.json({
      workers: workersWithAvailability,
      total_available: totalAvailable,
      total_with_conflicts: totalWithConflicts,
      total_count: workersWithAvailability.length
    }, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/app/chef/projects/[id]/available-workers:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}