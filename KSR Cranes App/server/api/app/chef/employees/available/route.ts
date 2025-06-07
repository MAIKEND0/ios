// src/app/api/app/chef/employees/available/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/employees/available
 * Pobiera listę dostępnych pracowników do przypisania do zadań
 */
export async function GET(request: Request): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const excludeTaskId = searchParams.get('exclude_task_id');
    const date = searchParams.get('date');
    const craneTypes = searchParams.get('crane_types');
    const includeAvailability = searchParams.get('include_availability') === 'true';
    const search = searchParams.get('search');
    const role = searchParams.get('role');
    
    // Build where clause for workers
    const where: any = {
      role: 'arbejder', // Only workers
      is_activated: true
    };
    
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } }
      ];
    }
    
    if (role && role !== 'arbejder') {
      where.role = role; // Allow filtering by other roles if needed
    }

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

    // Filter by crane types if specified
    let filteredWorkers = workers;
    if (craneTypes) {
      const requiredCraneTypeIds = craneTypes.split(',').map(id => parseInt(id.trim()));
      filteredWorkers = workers.filter(worker => 
        worker.EmployeeCraneTypes.some(ect => 
          requiredCraneTypeIds.includes(ect.CraneTypes.crane_type_id)
        )
      );
    }

    // Add availability information if requested
    const workersWithAvailability = includeAvailability 
      ? await Promise.all(filteredWorkers.map(async (worker) => {
          const availability = await getWorkerAvailability(
            worker.employee_id, 
            date ? new Date(date) : null,
            excludeTaskId ? parseInt(excludeTaskId) : null
          );
          return {
            employee: worker,
            availability,
            crane_types: worker.EmployeeCraneTypes.map(ect => ect.CraneTypes)
          };
        }))
      : filteredWorkers.map(worker => ({
          employee: worker,
          availability: null,
          crane_types: worker.EmployeeCraneTypes.map(ect => ect.CraneTypes)
        }));

    // Calculate totals
    const totalAvailable = includeAvailability 
      ? workersWithAvailability.filter(w => w.availability?.is_available).length
      : workersWithAvailability.length;
    
    const totalWithConflicts = includeAvailability 
      ? workersWithAvailability.filter(w => w.availability && !w.availability.is_available).length
      : 0;

    return NextResponse.json({
      workers: workersWithAvailability,
      total_available: totalAvailable,
      total_with_conflicts: totalWithConflicts
    }, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/app/chef/employees/available:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * Helper function to calculate worker availability
 */
async function getWorkerAvailability(
  employeeId: number, 
  targetDate: Date | null = null, 
  excludeTaskId: number | null = null
) {
  const now = new Date();
  const checkDate = targetDate || now;
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
          { deadline: null }, // Tasks without deadline might conflict
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
  const startOfWeek = new Date(checkDate);
  startOfWeek.setDate(checkDate.getDate() - checkDate.getDay() + 1); // Monday
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
      const startTime = new Date(entry.start_time);
      const endTime = new Date(entry.end_time);
      const hours = (endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60);
      const pauseHours = (entry.pause_minutes || 0) / 60;
      return total + Math.max(0, hours - pauseHours);
    }
    return total;
  }, 0);

  // Calculate monthly work hours
  const startOfMonth = new Date(checkDate.getFullYear(), checkDate.getMonth(), 1);
  const endOfMonth = new Date(checkDate.getFullYear(), checkDate.getMonth() + 1, 0);

  const monthlyEntries = await prisma.workEntries.findMany({
    where: {
      employee_id: employeeId,
      work_date: {
        gte: startOfMonth,
        lte: endOfMonth
      },
      isActive: true
    },
    select: {
      start_time: true,
      end_time: true,
      pause_minutes: true
    }
  });

  const monthlyHours = monthlyEntries.reduce((total, entry) => {
    if (entry.start_time && entry.end_time) {
      const startTime = new Date(entry.start_time);
      const endTime = new Date(entry.end_time);
      const hours = (endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60);
      const pauseHours = (entry.pause_minutes || 0) / 60;
      return total + Math.max(0, hours - pauseHours);
    }
    return total;
  }, 0);

  // Determine next available date if conflicts exist
  let nextAvailableDate = null;
  if (conflictingTasks.length > 0) {
    const latestDeadline = conflictingTasks.reduce((latest, ct) => {
      const taskDeadline = ct.Tasks.deadline ? new Date(ct.Tasks.deadline) : null;
      if (!taskDeadline) return latest;
      return !latest || taskDeadline > latest ? taskDeadline : latest;
    }, null as Date | null);
    
    if (latestDeadline) {
      nextAvailableDate = new Date(latestDeadline);
      nextAvailableDate.setDate(latestDeadline.getDate() + 1);
    }
  }

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
    work_hours_this_month: Math.round(monthlyHours * 100) / 100,
    max_weekly_hours: 40,
    next_available_date: nextAvailableDate
  };
}