// /api/app/chef/workers - Lista pracowników dla Chef'a
import { NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";

// GET /api/app/chef/workers - Lista wszystkich pracowników z filtrowaniem
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    
    // Parametry filtrowania
    const search = searchParams.get("search");
    const limit = searchParams.get("limit") ? parseInt(searchParams.get("limit")!) : undefined;
    const offset = searchParams.get("offset") ? parseInt(searchParams.get("offset")!) : 0;
    const includeProfileImage = searchParams.get("include_profile_image") === "true";
    const includeStats = searchParams.get("include_stats") === "true";

    // Budowanie query filtrów
    const whereClause: any = {
      // Tylko pracownicy, nie chef/system
      role: {
        in: ['arbejder', 'byggeleder'] as any
      }
    };

    // Filtr wyszukiwania
    if (search) {
      whereClause.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
        { phone_number: { contains: search, mode: 'insensitive' } }
      ];
    }

    // Pobieranie pracowników
    const workers = await prisma.employees.findMany({
      where: whereClause,
      select: {
        employee_id: true,
        name: true,
        email: true,
        phone_number: true,
        address: true,
        operator_normal_rate: true,
        role: true, // wykorzystamy jako employment_type
        profilePictureUrl: includeProfileImage,
        created_at: true,
        is_activated: true, // wykorzystamy jako status
        // Dodatkowe pola jeśli potrzebne
        birth_date: true,
        has_driving_license: true,
        emergency_contact: true,
        // Include certificates if requested
        WorkerSkills: searchParams.get("include_certificates") === "true" ? {
          include: {
            CertificateTypes: true
          }
        } : false
      },
      orderBy: { name: "asc" },
      skip: offset,
      take: limit
    });

    // Pobieranie statystyk dla każdego pracownika (jeśli włączone)
    const mappedWorkers = await Promise.all(workers.map(async (worker) => {
      let stats = null;
      
      if (includeStats) {
        // Obliczanie rzeczywistych statystyk z bazy danych
        const now = new Date();
        const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay() + 1)); // Poniedziałek
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        
        // Active tasks (z TaskAssignments)
        const activeTasks = await prisma.taskAssignments.count({
          where: {
            employee_id: worker.employee_id,
            Tasks: {
              isActive: true
            }
          }
        });
        
        // Work entries this week
        const weekWorkEntries = await prisma.workEntries.aggregate({
          where: {
            employee_id: worker.employee_id,
            work_date: {
              gte: startOfWeek
            },
            status: {
              in: ['confirmed', 'submitted']
            }
          },
          _sum: {
            pause_minutes: true
          },
          _count: true
        });
        
        // Work entries this month
        const monthWorkEntries = await prisma.workEntries.aggregate({
          where: {
            employee_id: worker.employee_id,
            work_date: {
              gte: startOfMonth
            },
            status: {
              in: ['confirmed', 'submitted']
            }
          },
          _sum: {
            pause_minutes: true
          },
          _count: true
        });
        
        // Completed tasks (assuming WorkEntries with 'confirmed' status)
        const completedTasks = await prisma.workEntries.groupBy({
          by: ['task_id'],
          where: {
            employee_id: worker.employee_id,
            status: 'confirmed'
          }
        });
        
        // Total tasks assigned
        const totalTasks = await prisma.taskAssignments.count({
          where: {
            employee_id: worker.employee_id
          }
        });
        
        // Last timesheet date
        const lastWorkEntry = await prisma.workEntries.findFirst({
          where: {
            employee_id: worker.employee_id,
            status: {
              in: ['confirmed', 'submitted']
            }
          },
          orderBy: {
            work_date: 'desc'
          },
          select: {
            work_date: true
          }
        });
        
        // Obliczanie godzin z WorkEntries (start_time - end_time - pause_minutes)
        const calculateHours = async (dateFilter: any) => {
          const entries = await prisma.workEntries.findMany({
            where: {
              employee_id: worker.employee_id,
              work_date: dateFilter,
              status: {
                in: ['confirmed', 'submitted']
              },
              start_time: { not: null },
              end_time: { not: null }
            },
            select: {
              start_time: true,
              end_time: true,
              pause_minutes: true
            }
          });
          
          let totalMinutes = 0;
          entries.forEach(entry => {
            if (entry.start_time && entry.end_time) {
              const start = new Date(entry.start_time).getTime();
              const end = new Date(entry.end_time).getTime();
              const workMinutes = (end - start) / (1000 * 60);
              const pauseMinutes = entry.pause_minutes || 0;
              totalMinutes += (workMinutes - pauseMinutes);
            }
          });
          
          return totalMinutes / 60; // convert to hours
        };
        
        const hoursThisWeek = await calculateHours({ gte: startOfWeek });
        const hoursThisMonth = await calculateHours({ gte: startOfMonth });
        
        // Approval rate (confirmed vs total work entries)
        const totalWorkEntries = await prisma.workEntries.count({
          where: { employee_id: worker.employee_id }
        });
        const confirmedWorkEntries = await prisma.workEntries.count({
          where: { 
            employee_id: worker.employee_id,
            status: 'confirmed'
          }
        });
        
        const approvalRate = totalWorkEntries > 0 ? confirmedWorkEntries / totalWorkEntries : 1.0;
        
        stats = {
          hours_this_week: Math.round(hoursThisWeek * 10) / 10, // round to 1 decimal
          hours_this_month: Math.round(hoursThisMonth * 10) / 10,
          active_tasks: activeTasks,
          completed_tasks: completedTasks.length,
          total_tasks: totalTasks,
          approval_rate: Math.round(approvalRate * 100) / 100, // round to 2 decimals
          last_timesheet_date: lastWorkEntry?.work_date || null
        };
      }
      
      // Map certificates if included
      let certificates = undefined;
      if (worker.WorkerSkills && Array.isArray(worker.WorkerSkills)) {
        certificates = worker.WorkerSkills.map((skill: any) => ({
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
          years_experience: skill.years_experience
        }));
      }

      return {
        employee_id: worker.employee_id,
        name: worker.name,
        email: worker.email,
        phone: worker.phone_number,
        address: worker.address,
        hourly_rate: Number(worker.operator_normal_rate || 0),
        employment_type: mapRoleToEmploymentType(worker.role),
        status: await getWorkerStatus(worker),
        profile_picture_url: worker.profilePictureUrl,
        created_at: worker.created_at,
        last_active: null, // TODO: implement tracking
        stats: stats,
        certificates: certificates
      };
    }));

    return NextResponse.json(mappedWorkers);
  } catch (error: any) {
    console.error("Error fetching workers:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST /api/app/chef/workers - Dodawanie nowego pracownika
export async function POST(request: Request) {
  try {
    const body = await request.json();

    // Walidacja wymaganych pól
    if (!body.name || !body.email || !body.hourly_rate || !body.employment_type) {
      return NextResponse.json(
        { error: "Missing required fields: name, email, hourly_rate, employment_type" },
        { status: 400 }
      );
    }

    // Sprawdzenie czy email już istnieje
    const existingWorker = await prisma.employees.findUnique({
      where: { email: body.email }
    });

    if (existingWorker) {
      return NextResponse.json(
        { error: "Worker with this email already exists" },
        { status: 409 }
      );
    }

    // Tworzenie nowego pracownika
    const newWorker = await prisma.employees.create({
      data: {
        name: body.name,
        email: body.email,
        role: mapEmploymentTypeToRole(body.employment_type) as any,
        password_hash: "temp_hash", // TODO: implement proper password generation
        operator_normal_rate: body.hourly_rate,
        phone_number: body.phone || null,
        address: body.address || null,
        is_activated: body.status !== "inaktiv",
        birth_date: body.hire_date ? new Date(body.hire_date) : null,
        emergency_contact: body.notes || null
      }
    });

    // Add certificates if provided
    if (body.certificates && Array.isArray(body.certificates)) {
      console.log("[API] Adding certificates for new worker:", body.certificates);
      
      // Create WorkerSkills entries for each certificate
      const certificatePromises = body.certificates.map(async (cert: any) => {
        return prisma.workerSkills.create({
          data: {
            employee_id: newWorker.employee_id,
            certificate_type_id: cert.certificate_type_id,
            skill_name: cert.skill_name || `Certificate ${cert.certificate_type_id}`,
            skill_level: cert.skill_level || "certified",
            is_certified: true,
            certification_number: cert.certification_number || null,
            certification_expires: cert.certification_expires ? new Date(cert.certification_expires) : null,
            years_experience: cert.years_experience || 0,
            crane_type_specialization: cert.crane_type_specialization || null,
            notes: cert.notes || null
          }
        });
      });

      await Promise.all(certificatePromises);
    }

    // Fetch the created worker with certificates
    const workerWithCertificates = await prisma.employees.findUnique({
      where: { employee_id: newWorker.employee_id },
      include: {
        WorkerSkills: {
          include: {
            CertificateTypes: true
          }
        }
      }
    });

    // Map certificates if included
    const certificates = workerWithCertificates?.WorkerSkills?.map(skill => ({
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
      years_experience: skill.years_experience
    })) || [];

    // Mapowanie do formatu iOS (nowy pracownik ma puste statystyki)
    const mappedWorker = {
      employee_id: newWorker.employee_id,
      name: newWorker.name,
      email: newWorker.email,
      phone: newWorker.phone_number,
      address: newWorker.address,
      hourly_rate: Number(newWorker.operator_normal_rate || 0),
      employment_type: mapRoleToEmploymentType(newWorker.role),
      status: await getWorkerStatus(newWorker),
      profile_picture_url: newWorker.profilePictureUrl,
      created_at: newWorker.created_at,
      last_active: null,
      stats: {
        hours_this_week: 0,
        hours_this_month: 0,
        active_tasks: 0,
        completed_tasks: 0,
        total_tasks: 0,
        approval_rate: 1.0,
        last_timesheet_date: null
      },
      certificates: certificates
    };

    return NextResponse.json(mappedWorker, { status: 201 });
  } catch (error: any) {
    console.error("Error creating worker:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// Helper function to determine worker status based on leave
async function getWorkerStatus(worker: any): Promise<string> {
  // First check if worker is activated
  if (!worker.is_activated) {
    // Check if they have active leave
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const activeLeave = await prisma.leaveRequests.findFirst({
      where: {
        employee_id: worker.employee_id,
        status: 'APPROVED',
        start_date: { lte: today },
        end_date: { gte: today }
      }
    });
    
    if (activeLeave) {
      if (activeLeave.type === 'VACATION') {
        return 'ferie';
      } else if (activeLeave.type === 'SICK' || activeLeave.type === 'EMERGENCY') {
        return 'sygemeldt';
      }
    }
    
    // If no active leave but is_activated is false, return inaktiv
    return 'inaktiv';
  }
  
  // Worker is activated
  return 'aktiv';
}

// Helper functions
function mapRoleToEmploymentType(role: string): string {
  switch (role) {
    case 'arbejder': return 'fuld_tid';
    case 'byggeleder': return 'fuld_tid';
    default: return 'fuld_tid';
  }
}

function mapEmploymentTypeToRole(employmentType: string): string {
  switch (employmentType) {
    case 'fuld_tid': return 'arbejder';
    case 'deltid': return 'arbejder';
    case 'timebaseret': return 'arbejder';
    case 'freelancer': return 'arbejder';
    case 'praktikant': return 'arbejder';
    default: return 'arbejder';
  }
}
