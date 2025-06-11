// /api/app/chef/workers/[id] - Operacje na konkretnym pracowniku
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// GET /api/app/chef/workers/[id] - Szczegóły pracownika
export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);
    
    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    const worker = await prisma.employees.findUnique({
      where: { 
        employee_id: workerId,
        role: {
          in: ['arbejder', 'byggeleder'] as any // Tylko pracownicy, nie chef/system
        }
      },
      select: {
        employee_id: true,
        name: true,
        email: true,
        phone_number: true,
        address: true,
        operator_normal_rate: true,
        role: true,
        profilePictureUrl: true,
        created_at: true,
        is_activated: true,
        birth_date: true,
        has_driving_license: true,
        emergency_contact: true,
        cpr_number: true,
        driving_license_category: true,
        driving_license_expiration: true,
        // Include certificates
        WorkerSkills: {
          include: {
            CertificateTypes: true
          }
        }
      }
    });

    if (!worker) {
      return NextResponse.json({ error: "Worker not found" }, { status: 404 });
    }

    // Pobieranie dodatkowych danych
    const workEntries = await prisma.workEntries.findMany({
      where: { 
        employee_id: workerId,
        created_at: {
          gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) // ostatnie 30 dni
        }
      },
      include: {
        Tasks: {
          include: {
            Projects: true
          }
        }
      },
      orderBy: { created_at: 'desc' },
      take: 10
    });

    // Obliczanie statystyk
    const thisWeekStart = new Date();
    thisWeekStart.setDate(thisWeekStart.getDate() - thisWeekStart.getDay());
    thisWeekStart.setHours(0, 0, 0, 0);

    const thisMonthStart = new Date();
    thisMonthStart.setDate(1);
    thisMonthStart.setHours(0, 0, 0, 0);

    const hoursThisWeek = workEntries
      .filter(entry => entry.created_at && entry.created_at >= thisWeekStart)
      .reduce((sum, entry) => {
        if (entry.start_time && entry.end_time) {
          const hours = (entry.end_time.getTime() - entry.start_time.getTime()) / (1000 * 60 * 60);
          return sum + hours;
        }
        return sum;
      }, 0);

    const hoursThisMonth = workEntries
      .filter(entry => entry.created_at && entry.created_at >= thisMonthStart)
      .reduce((sum, entry) => {
        if (entry.start_time && entry.end_time) {
          const hours = (entry.end_time.getTime() - entry.start_time.getTime()) / (1000 * 60 * 60);
          return sum + hours;
        }
        return sum;
      }, 0);

    const activeProjects = [...new Set(workEntries.map(entry => entry.Tasks.project_id))].length;
    const completedTasks = workEntries.filter(entry => entry.status === 'confirmed').length;
    const approvalRate = workEntries.length > 0 ? 
      workEntries.filter(entry => entry.confirmation_status === 'confirmed').length / workEntries.length : 
      1.0;

    // Recent activity
    const recentActivity = workEntries.slice(0, 5).map(entry => ({
      id: entry.entry_id,
      type: "timesheet_submitted",
      description: `Submitted timesheet for ${entry.Tasks.Projects.title}`,
      timestamp: entry.created_at,
      project_title: entry.Tasks.Projects.title,
      metadata: {}
    }));

    // Current assignments (active tasks)
    const currentAssignments = await prisma.taskAssignments.findMany({
      where: { employee_id: workerId },
      include: {
        Tasks: {
          include: {
            Projects: {
              include: {
                Customers: true
              }
            }
          }
        }
      },
      orderBy: { assigned_at: 'desc' },
      take: 5
    });

    const mappedAssignments = currentAssignments.map(assignment => ({
      id: assignment.assignment_id,
      project_id: assignment.Tasks.project_id,
      project_title: assignment.Tasks.Projects.title,
      customer_name: assignment.Tasks.Projects.Customers?.name || "Unknown",
      role: "Operator",
      start_date: assignment.assigned_at || new Date(),
      end_date: null,
      status: "aktiv",
      hourly_rate: Number(worker.operator_normal_rate || 0)
    }));

    // Map certificates
    const certificates = worker.WorkerSkills.map(skill => ({
      skill_id: skill.skill_id,
      certificate_type_id: skill.certificate_type_id,
      certificate_type: skill.CertificateTypes ? {
        code: skill.CertificateTypes.code,
        name_en: skill.CertificateTypes.name_en,
        name_da: skill.CertificateTypes.name_da,
        description: skill.CertificateTypes.description
      } : null,
      skill_name: skill.skill_name,
      skill_level: skill.skill_level,
      is_certified: skill.is_certified,
      certification_number: skill.certification_number,
      certification_expires: skill.certification_expires,
      years_experience: skill.years_experience,
      crane_type_specialization: skill.crane_type_specialization,
      notes: skill.notes
    }));

    // Mapowanie do formatu iOS
    const workerDetail = {
      employee_id: worker.employee_id,
      name: worker.name,
      email: worker.email,
      phone: worker.phone_number,
      address: worker.address,
      hourly_rate: Number(worker.operator_normal_rate || 0),
      employment_type: mapRoleToEmploymentType(worker.role),
      status: worker.is_activated ? "aktiv" : "inaktiv",
      profile_picture_url: worker.profilePictureUrl,
      created_at: worker.created_at,
      last_active: workEntries[0]?.created_at || null,
      hire_date: worker.birth_date, // Using birth_date as hire_date placeholder
      notes: worker.emergency_contact, // Using emergency_contact as notes placeholder
      certificates: certificates,
      detailed_stats: {
        total_hours: hoursThisMonth * 4, // Rough estimate for total hours
        hours_this_week: hoursThisWeek,
        hours_this_month: hoursThisMonth,
        hours_this_year: hoursThisMonth * 12, // Rough estimate
        active_projects: activeProjects,
        completed_projects: 0, // TODO: implement
        total_tasks: workEntries.length,
        completed_tasks: completedTasks,
        approval_rate: approvalRate,
        average_rating: 4.5, // Mock data
        total_earnings: hoursThisMonth * Number(worker.operator_normal_rate || 0),
        last_timesheet_date: workEntries[0]?.created_at || null,
        efficiency_score: 0.85 + Math.random() * 0.15 // Mock data
      },
      current_assignments: mappedAssignments,
      recent_activity: recentActivity,
      rates_history: [] // TODO: implement rates history
    };

    return NextResponse.json(workerDetail);
  } catch (error: any) {
    console.error("Error fetching worker details:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PUT /api/app/chef/workers/[id] - Aktualizacja pracownika
export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);
    const body = await request.json();

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    // Sprawdzenie czy pracownik istnieje
    const existingWorker = await prisma.employees.findUnique({
      where: { employee_id: workerId }
    });

    if (!existingWorker) {
      return NextResponse.json({ error: "Worker not found" }, { status: 404 });
    }

    // Sprawdzenie czy email nie jest już używany przez innego pracownika
    if (body.email && body.email !== existingWorker.email) {
      const emailExists = await prisma.employees.findFirst({
        where: {
          email: body.email,
          NOT: { employee_id: workerId }
        }
      });

      if (emailExists) {
        return NextResponse.json(
          { error: "Email is already used by another worker" },
          { status: 409 }
        );
      }
    }

    // Przygotowanie danych do aktualizacji
    const updateData: any = {};
    
    if (body.name !== undefined) updateData.name = body.name;
    if (body.email !== undefined) updateData.email = body.email;
    if (body.phone !== undefined) updateData.phone_number = body.phone;
    if (body.address !== undefined) updateData.address = body.address;
    if (body.hourly_rate !== undefined) updateData.operator_normal_rate = body.hourly_rate;
    if (body.employment_type !== undefined) updateData.role = mapEmploymentTypeToRole(body.employment_type) as any;
    if (body.status !== undefined) updateData.is_activated = body.status === "aktiv";
    if (body.notes !== undefined) updateData.emergency_contact = body.notes;

    // Aktualizacja w bazie
    const updatedWorker = await prisma.employees.update({
      where: { employee_id: workerId },
      data: updateData
    });

    // Handle certificate updates if provided
    if (body.certificates !== undefined) {
      console.log("[API] Updating certificates for worker:", workerId, body.certificates);
      
      // Remove all existing certificates
      await prisma.workerSkills.deleteMany({
        where: { employee_id: workerId }
      });
      
      // Add new certificates
      if (body.certificates && Array.isArray(body.certificates) && body.certificates.length > 0) {
        const certificatePromises = body.certificates.map(async (cert: any) => {
          return prisma.workerSkills.create({
            data: {
              employee_id: workerId,
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
    }

    // Fetch updated worker with certificates
    const workerWithCertificates = await prisma.employees.findUnique({
      where: { employee_id: workerId },
      include: {
        WorkerSkills: {
          include: {
            CertificateTypes: true
          }
        }
      }
    });

    // Map certificates
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

    // Mapowanie do formatu iOS
    const mappedWorker = {
      employee_id: updatedWorker.employee_id,
      name: updatedWorker.name,
      email: updatedWorker.email,
      phone: updatedWorker.phone_number,
      address: updatedWorker.address,
      hourly_rate: Number(updatedWorker.operator_normal_rate || 0),
      employment_type: mapRoleToEmploymentType(updatedWorker.role),
      status: updatedWorker.is_activated ? "aktiv" : "inaktiv",
      profile_picture_url: updatedWorker.profilePictureUrl,
      created_at: updatedWorker.created_at,
      last_active: null,
      stats: {
        hours_this_week: 0,
        hours_this_month: 0,
        active_projects: 0,
        completed_tasks: 0,
        approval_rate: 1.0,
        last_timesheet_date: null
      },
      certificates: certificates
    };

    return NextResponse.json(mappedWorker);
  } catch (error: any) {
    console.error("Error updating worker:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// DELETE /api/app/chef/workers/[id] - Usuwanie pracownika
export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    // Sprawdzenie czy pracownik istnieje
    const existingWorker = await prisma.employees.findUnique({
      where: { employee_id: workerId }
    });

    if (!existingWorker) {
      return NextResponse.json({ error: "Worker not found" }, { status: 404 });
    }

    // Sprawdzenie czy pracownik ma aktywne wpisy pracy
    const activeWorkEntries = await prisma.workEntries.findFirst({
      where: {
        employee_id: workerId,
        status: {
          in: ['pending', 'submitted']
        }
      }
    });

    if (activeWorkEntries) {
      return NextResponse.json(
        { error: "Cannot delete worker with active work entries. Please complete or reject all pending entries first." },
        { status: 409 }
      );
    }

    // Deaktywacja zamiast usuwania (soft delete)
    await prisma.employees.update({
      where: { employee_id: workerId },
      data: { 
        is_activated: false,
        email: `deleted_${Date.now()}_${existingWorker.email}` // Prevent email conflicts
      }
    });

    return NextResponse.json({
      success: true,
      message: "Worker deactivated successfully",
      worker_id: workerId
    });
  } catch (error: any) {
    console.error("Error deleting worker:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
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