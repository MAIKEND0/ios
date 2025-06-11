// /api/app/chef/certificates/expiring - Get workers with expiring certificates
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// GET /api/app/chef/certificates/expiring - Get workers with expiring certificates
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    
    // Get days parameter (default 30 days)
    const days = searchParams.get("days") ? parseInt(searchParams.get("days")!) : 30;
    const includeExpired = searchParams.get("include_expired") === "true";
    
    const now = new Date();
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + days);

    // Build where clause for expiring certificates
    const whereClause: any = {
      is_certified: true,
      certificate_type_id: { not: null }
    };

    if (includeExpired) {
      // Include both expired and expiring soon
      whereClause.OR = [
        {
          certification_expires: {
            gte: now,
            lte: futureDate
          }
        },
        {
          certification_expires: {
            lt: now
          }
        }
      ];
    } else {
      // Only expiring soon (not yet expired)
      whereClause.certification_expires = {
        gte: now,
        lte: futureDate
      };
    }

    // Get workers with expiring certificates
    const workersWithExpiringCerts = await prisma.workerSkills.findMany({
      where: whereClause,
      include: {
        Employees: {
          select: {
            employee_id: true,
            name: true,
            email: true,
            phone_number: true,
            role: true,
            is_activated: true,
            profilePictureUrl: true
          }
        },
        CertificateTypes: true
      },
      orderBy: {
        certification_expires: 'asc'
      }
    });

    // Group by worker
    const workerMap = new Map<number, any>();
    
    workersWithExpiringCerts.forEach(skill => {
      if (!skill.Employees || !skill.Employees.is_activated) return;
      
      const workerId = skill.Employees.employee_id;
      const daysUntilExpiry = skill.certification_expires ? 
        Math.ceil((skill.certification_expires.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)) : 0;
      
      if (!workerMap.has(workerId)) {
        workerMap.set(workerId, {
          employee_id: workerId,
          name: skill.Employees.name,
          email: skill.Employees.email,
          phone: skill.Employees.phone_number,
          role: skill.Employees.role,
          profile_picture_url: skill.Employees.profilePictureUrl,
          expiring_certificates: []
        });
      }
      
      const worker = workerMap.get(workerId);
      worker.expiring_certificates.push({
        skill_id: skill.skill_id,
        certificate_type_id: skill.certificate_type_id,
        certificate_type: skill.CertificateTypes ? {
          code: skill.CertificateTypes.code,
          name_en: skill.CertificateTypes.name_en,
          name_da: skill.CertificateTypes.name_da
        } : null,
        skill_name: skill.skill_name,
        certification_number: skill.certification_number,
        certification_expires: skill.certification_expires,
        days_until_expiry: daysUntilExpiry,
        is_expired: daysUntilExpiry < 0,
        urgency: daysUntilExpiry < 0 ? 'expired' : 
                 daysUntilExpiry <= 7 ? 'critical' : 
                 daysUntilExpiry <= 14 ? 'high' :
                 daysUntilExpiry <= 30 ? 'medium' : 'low'
      });
    });

    // Convert to array and sort by urgency
    const workers = Array.from(workerMap.values()).sort((a, b) => {
      const aMinDays = Math.min(...a.expiring_certificates.map((c: any) => c.days_until_expiry));
      const bMinDays = Math.min(...b.expiring_certificates.map((c: any) => c.days_until_expiry));
      return aMinDays - bMinDays;
    });

    // Calculate statistics
    const stats = {
      total_workers_affected: workers.length,
      total_certificates_expiring: workersWithExpiringCerts.length,
      expired_count: workersWithExpiringCerts.filter(s => 
        s.certification_expires && s.certification_expires < now
      ).length,
      critical_count: workersWithExpiringCerts.filter(s => {
        if (!s.certification_expires) return false;
        const days = Math.ceil((s.certification_expires.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        return days >= 0 && days <= 7;
      }).length,
      high_priority_count: workersWithExpiringCerts.filter(s => {
        if (!s.certification_expires) return false;
        const days = Math.ceil((s.certification_expires.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        return days > 7 && days <= 14;
      }).length
    };

    return NextResponse.json({
      workers: workers,
      statistics: stats,
      parameters: {
        days_ahead: days,
        include_expired: includeExpired,
        checked_at: now
      }
    });
  } catch (error: any) {
    console.error("[API] Error getting expiring certificates:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}