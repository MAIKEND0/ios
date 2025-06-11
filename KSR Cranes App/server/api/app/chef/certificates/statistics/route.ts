// /api/app/chef/certificates/statistics - Certificate statistics
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// GET /api/app/chef/certificates/statistics - Get certificate statistics
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const includeDetails = searchParams.get("include_details") === "true";

    // Get all certificate types
    const certificateTypes = await prisma.certificateTypes.findMany({
      orderBy: { code: 'asc' }
    });

    // Get statistics for each certificate type
    const certificateStats = await Promise.all(certificateTypes.map(async (certType) => {
      // Count workers with this certificate (valid)
      const workersWithCertificate = await prisma.workerSkills.count({
        where: {
          certificate_type_id: certType.certificate_type_id,
          is_certified: true,
          OR: [
            { certification_expires: null },
            { certification_expires: { gte: new Date() } }
          ],
          Employees: {
            role: { in: ['arbejder', 'byggeleder'] as any },
            is_activated: true
          }
        }
      });

      // Count expired certificates
      const expiredCount = await prisma.workerSkills.count({
        where: {
          certificate_type_id: certType.certificate_type_id,
          is_certified: true,
          certification_expires: { lt: new Date() },
          Employees: {
            role: { in: ['arbejder', 'byggeleder'] as any },
            is_activated: true
          }
        }
      });

      // Count expiring soon (30 days)
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
      
      const expiringSoonCount = await prisma.workerSkills.count({
        where: {
          certificate_type_id: certType.certificate_type_id,
          is_certified: true,
          certification_expires: {
            gte: new Date(),
            lte: thirtyDaysFromNow
          },
          Employees: {
            role: { in: ['arbejder', 'byggeleder'] as any },
            is_activated: true
          }
        }
      });

      // Count tasks requiring this certificate
      const tasksRequiringCert = await prisma.craneCategory.count({
        where: {
          required_certificates: {
            contains: certType.certificate_type_id.toString()
          }
        }
      });

      return {
        certificate_type_id: certType.certificate_type_id,
        code: certType.code,
        name_en: certType.name_en,
        name_da: certType.name_da,
        category: certType.category,
        statistics: {
          total_valid: workersWithCertificate,
          total_expired: expiredCount,
          expiring_soon: expiringSoonCount,
          tasks_requiring: tasksRequiringCert
        }
      };
    }));

    // Overall statistics
    const totalWorkers = await prisma.employees.count({
      where: {
        role: { in: ['arbejder', 'byggeleder'] as any },
        is_activated: true
      }
    });

    const workersWithAnyCertificate = await prisma.employees.count({
      where: {
        role: { in: ['arbejder', 'byggeleder'] as any },
        is_activated: true,
        WorkerSkills: {
          some: {
            is_certified: true,
            OR: [
              { certification_expires: null },
              { certification_expires: { gte: new Date() } }
            ]
          }
        }
      }
    });

    const totalCertificates = await prisma.workerSkills.count({
      where: {
        is_certified: true,
        Employees: {
          role: { in: ['arbejder', 'byggeleder'] as any },
          is_activated: true
        }
      }
    });

    const response: any = {
      certificate_types: certificateStats,
      overall_statistics: {
        total_workers: totalWorkers,
        workers_with_certificates: workersWithAnyCertificate,
        workers_without_certificates: totalWorkers - workersWithAnyCertificate,
        certificate_coverage_percentage: totalWorkers > 0 ? 
          Math.round((workersWithAnyCertificate / totalWorkers) * 100) : 0,
        total_certificates_issued: totalCertificates
      }
    };

    // Add detailed breakdowns if requested
    if (includeDetails) {
      // Certificate distribution by category
      const categoryDistribution = certificateStats.reduce((acc: any, cert) => {
        const category = cert.category || 'OTHER';
        if (!acc[category]) {
          acc[category] = {
            count: 0,
            valid_certificates: 0,
            expired_certificates: 0
          };
        }
        acc[category].count++;
        acc[category].valid_certificates += cert.statistics.total_valid;
        acc[category].expired_certificates += cert.statistics.total_expired;
        return acc;
      }, {});

      // Most common certificates
      const mostCommonCertificates = certificateStats
        .sort((a, b) => b.statistics.total_valid - a.statistics.total_valid)
        .slice(0, 5)
        .map(cert => ({
          code: cert.code,
          name_en: cert.name_en,
          count: cert.statistics.total_valid
        }));

      // Critical certificates (high task requirement, low worker count)
      const criticalCertificates = certificateStats
        .filter(cert => cert.statistics.tasks_requiring > 0)
        .map(cert => ({
          ...cert,
          criticality_score: cert.statistics.tasks_requiring / (cert.statistics.total_valid || 1)
        }))
        .sort((a, b) => b.criticality_score - a.criticality_score)
        .slice(0, 5)
        .map(cert => ({
          code: cert.code,
          name_en: cert.name_en,
          workers_with_cert: cert.statistics.total_valid,
          tasks_requiring: cert.statistics.tasks_requiring,
          criticality_score: Math.round(cert.criticality_score * 100) / 100
        }));

      response.detailed_breakdown = {
        by_category: categoryDistribution,
        most_common_certificates: mostCommonCertificates,
        critical_certificates: criticalCertificates
      };
    }

    return NextResponse.json(response);
  } catch (error: any) {
    console.error("[API] Error getting certificate statistics:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}