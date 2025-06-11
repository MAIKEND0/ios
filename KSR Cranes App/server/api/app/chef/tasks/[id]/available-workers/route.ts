// src/app/api/app/chef/tasks/[id]/available-workers/route.ts
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

// Helper function for worker availability
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
 * GET /api/app/chef/tasks/[id]/available-workers
 * Pobiera dostępnych pracowników dla konkretnego zadania
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
    const date = searchParams.get('date');
    const craneTypes = searchParams.get('crane_types');
    const includeAvailability = searchParams.get('include_availability') === 'true';
    
    // Sprawdź czy zadanie istnieje i pobierz wymagane certyfikaty
    const task = await prisma.tasks.findUnique({
      where: { task_id: taskId },
      include: {
        CraneCategory: true
      }
    });

    if (!task) {
      return NextResponse.json({ error: "Task not found" }, { status: 404 });
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

    // Build where clause for workers
    const where: any = {
      role: 'arbejder',
      is_activated: true
    };
    
    // Get workers with their crane types and certificates
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
        },
        // Include worker certificates
        WorkerSkills: {
          where: {
            is_certified: true,
            OR: [
              { certification_expires: null },
              { certification_expires: { gte: new Date() } }
            ]
          },
          include: {
            CertificateTypes: true
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

    // Filter by required certificates if task has them
    if (requiredCertificateIds.length > 0) {
      filteredWorkers = filteredWorkers.filter(worker => {
        const workerCertIds = worker.WorkerSkills
          .filter(skill => skill.is_certified && skill.certificate_type_id)
          .map(skill => skill.certificate_type_id!);
        
        // Check if worker has ALL required certificates
        return requiredCertificateIds.every(certId => workerCertIds.includes(certId));
      });
    }

    // Add availability information if requested
    const workersWithAvailability = includeAvailability 
      ? await Promise.all(filteredWorkers.map(async (worker) => {
          const availability = await getWorkerAvailability(
            worker.employee_id, 
            date ? new Date(date) : null,
            taskId // Exclude current task from conflicts
          );
          return {
            employee: worker,
            availability,
            crane_types: worker.EmployeeCraneTypes.map(ect => ect.CraneTypes),
            certificates: worker.WorkerSkills.map(skill => {
              const isExpired = skill.certification_expires && skill.certification_expires < new Date();
              const daysUntilExpiry = skill.certification_expires ? 
                Math.ceil((skill.certification_expires.getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24)) : null;
              
              return {
                skill_id: skill.skill_id,
                certificate_type_id: skill.certificate_type_id,
                certificate_type: skill.CertificateTypes ? {
                  code: skill.CertificateTypes.code,
                  name_en: skill.CertificateTypes.name_en,
                  name_da: skill.CertificateTypes.name_da
                } : null,
                skill_name: skill.skill_name,
                skill_level: skill.skill_level,
                is_certified: skill.is_certified,
                certification_expires: skill.certification_expires,
                years_experience: skill.years_experience,
                is_expired: isExpired,
                days_until_expiry: daysUntilExpiry,
                urgency: isExpired ? 'expired' :
                        daysUntilExpiry && daysUntilExpiry <= 7 ? 'critical' :
                        daysUntilExpiry && daysUntilExpiry <= 30 ? 'warning' : 'ok'
              };
            }),
            has_required_certificates: requiredCertificateIds.length === 0 || 
              requiredCertificateIds.every(certId => 
                worker.WorkerSkills.some(skill => 
                  skill.is_certified && skill.certificate_type_id === certId &&
                  (!skill.certification_expires || skill.certification_expires >= new Date())
                )
              ),
            certificate_validation: {
              required_count: requiredCertificateIds.length,
              valid_count: requiredCertificateIds.filter(certId => 
                worker.WorkerSkills.some(skill => 
                  skill.is_certified && skill.certificate_type_id === certId &&
                  (!skill.certification_expires || skill.certification_expires >= new Date())
                )
              ).length,
              missing_certificates: requiredCertificateIds.filter(certId => 
                !worker.WorkerSkills.some(skill => skill.is_certified && skill.certificate_type_id === certId)
              ),
              expired_certificates: worker.WorkerSkills.filter(skill => 
                skill.is_certified && requiredCertificateIds.includes(skill.certificate_type_id!) &&
                skill.certification_expires && skill.certification_expires < new Date()
              ).map(skill => skill.certificate_type_id!)
            }
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
    console.error("Błąd GET /api/app/chef/tasks/[id]/available-workers:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}