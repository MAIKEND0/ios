// /api/app/chef/tasks/[id]/certificates - Get certificate requirements for task
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

// GET /api/app/chef/tasks/[id]/certificates - Get certificate requirements for a task
export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const taskId = parseInt(id);
    
    if (isNaN(taskId)) {
      return NextResponse.json({ error: "Invalid task ID" }, { status: 400 });
    }

    // Get task with crane category
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

    // Get certificate types details
    const requiredCertificates = await prisma.certificateTypes.findMany({
      where: {
        certificate_type_id: {
          in: requiredCertificateIds
        }
      }
    });

    // Get workers with the required certificates (for stats)
    const workersWithAllCertificates = await prisma.employees.count({
      where: {
        role: {
          in: ['arbejder', 'byggeleder'] as any
        },
        is_activated: true,
        AND: requiredCertificateIds.map(certId => ({
          WorkerSkills: {
            some: {
              certificate_type_id: certId,
              is_certified: true,
              OR: [
                { certification_expires: null },
                { certification_expires: { gte: new Date() } }
              ]
            }
          }
        }))
      }
    });

    const response = {
      task: {
        task_id: task.task_id,
        title: task.title,
        description: task.description,
        crane_category: task.CraneCategory ? {
          id: task.CraneCategory.id,
          name: task.CraneCategory.name,
          code: task.CraneCategory.code,
          description: task.CraneCategory.description
        } : null
      },
      required_certificates: requiredCertificates.map(cert => ({
        certificate_type_id: cert.certificate_type_id,
        code: cert.code,
        name_en: cert.name_en,
        name_da: cert.name_da,
        description: cert.description,
        category: cert.category,
        required_training_hours: cert.required_training_hours,
        validity_years: cert.validity_years
      })),
      statistics: {
        total_required_certificates: requiredCertificates.length,
        workers_with_all_certificates: workersWithAllCertificates,
        certificate_coverage: requiredCertificates.length > 0 ? 
          `${workersWithAllCertificates} workers qualified` : 
          "No certificates required"
      }
    };

    return NextResponse.json(response);
  } catch (error: any) {
    console.error("[API] Error getting task certificate requirements:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}