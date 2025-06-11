// /api/app/chef/workers/with-certificates - Find workers with specific certificates
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// GET /api/app/chef/workers/with-certificates - Find workers with specific certificates
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    
    // Get certificate IDs from query params
    const certificateIds = searchParams.getAll("certificate_ids").map(id => parseInt(id)).filter(id => !isNaN(id));
    const includeExpired = searchParams.get("include_expired") === "true";
    const includeStats = searchParams.get("include_stats") === "true";
    
    if (certificateIds.length === 0) {
      return NextResponse.json({ error: "No certificate IDs provided" }, { status: 400 });
    }

    // Build where clause for workers with ALL specified certificates
    const whereClause: any = {
      role: {
        in: ['arbejder', 'byggeleder'] as any
      },
      is_activated: true
    };

    // Additional filter for certificate expiry if not including expired
    const certificateWhereClause: any = {
      certificate_type_id: {
        in: certificateIds
      },
      is_certified: true
    };

    if (!includeExpired) {
      certificateWhereClause.OR = [
        { certification_expires: null },
        { certification_expires: { gte: new Date() } }
      ];
    }

    // Find workers who have ALL the required certificates
    const workersWithCertificates = await prisma.employees.findMany({
      where: {
        ...whereClause,
        WorkerSkills: {
          some: certificateWhereClause
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
        WorkerSkills: {
          where: certificateWhereClause,
          include: {
            CertificateTypes: true
          }
        }
      }
    });

    // Filter to only include workers who have ALL required certificates
    const filteredWorkers = workersWithCertificates.filter(worker => {
      const workerCertIds = worker.WorkerSkills.map(skill => skill.certificate_type_id).filter(id => id !== null);
      return certificateIds.every(certId => workerCertIds.includes(certId));
    });

    // Map to expected format
    const mappedWorkers = await Promise.all(filteredWorkers.map(async (worker) => {
      let stats = null;
      
      if (includeStats) {
        // Calculate basic stats
        const now = new Date();
        const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay() + 1));
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        
        const activeTasks = await prisma.taskAssignments.count({
          where: {
            employee_id: worker.employee_id,
            Tasks: {
              isActive: true
            }
          }
        });
        
        stats = {
          hours_this_week: 0,
          hours_this_month: 0,
          active_tasks: activeTasks,
          completed_tasks: 0,
          total_tasks: activeTasks,
          approval_rate: 1.0,
          last_timesheet_date: null
        };
      }

      // Map certificates
      const certificates = worker.WorkerSkills.map(skill => ({
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
      
      return {
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
        last_active: null,
        stats: stats,
        certificates: certificates
      };
    }));

    const response = {
      workers: mappedWorkers,
      total_count: mappedWorkers.length,
      page: 1,
      limit: mappedWorkers.length,
      has_more: false
    };

    return NextResponse.json(response);
  } catch (error: any) {
    console.error("[API] Error finding workers with certificates:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// Helper function
function mapRoleToEmploymentType(role: string): string {
  switch (role) {
    case 'arbejder': return 'fuld_tid';
    case 'byggeleder': return 'fuld_tid';
    default: return 'fuld_tid';
  }
}