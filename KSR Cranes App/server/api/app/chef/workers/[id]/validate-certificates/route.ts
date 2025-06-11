// /api/app/chef/workers/[id]/validate-certificates - Validate worker certificates for task
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

// POST /api/app/chef/workers/[id]/validate-certificates - Validate worker certificates for task assignment
export async function POST(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);
    const body = await request.json();

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    if (!body.task_id) {
      return NextResponse.json({ error: "Missing required field: task_id" }, { status: 400 });
    }

    // Get task with crane category requirements
    const task = await prisma.tasks.findUnique({
      where: { task_id: body.task_id },
      include: {
        CraneCategory: true
      }
    });

    if (!task) {
      return NextResponse.json({ error: "Task not found" }, { status: 404 });
    }

    // Get worker with certificates
    const worker = await prisma.employees.findUnique({
      where: { employee_id: workerId },
      include: {
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

    // Get required certificate types
    const requiredCertificateTypes = await prisma.certificateTypes.findMany({
      where: {
        certificate_type_id: {
          in: requiredCertificateIds
        }
      }
    });

    // Check worker's certificates
    const workerCertificateIds = worker.WorkerSkills
      .filter(skill => skill.is_certified && skill.certificate_type_id)
      .map(skill => skill.certificate_type_id!);

    // Find missing certificates
    const missingCertificateIds = requiredCertificateIds.filter(
      certId => !workerCertificateIds.includes(certId)
    );

    const missingCertificates = requiredCertificateTypes.filter(
      cert => missingCertificateIds.includes(cert.certificate_type_id)
    );

    // Find expired certificates
    const now = new Date();
    const expiredCertificates = worker.WorkerSkills
      .filter(skill => {
        if (!skill.is_certified || !skill.certificate_type_id) return false;
        if (!requiredCertificateIds.includes(skill.certificate_type_id)) return false;
        if (!skill.certification_expires) return false;
        return skill.certification_expires < now;
      })
      .map(skill => ({
        skill_id: skill.skill_id,
        certificate_type_id: skill.certificate_type_id,
        certificate_type: skill.CertificateTypes,
        skill_name: skill.skill_name,
        certification_expires: skill.certification_expires,
        is_expired: true
      }));

    // Find certificates expiring soon (within 30 days)
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

    const expiringSoonCertificates = worker.WorkerSkills
      .filter(skill => {
        if (!skill.is_certified || !skill.certificate_type_id) return false;
        if (!requiredCertificateIds.includes(skill.certificate_type_id)) return false;
        if (!skill.certification_expires) return false;
        return skill.certification_expires >= now && skill.certification_expires <= thirtyDaysFromNow;
      })
      .map(skill => ({
        skill_id: skill.skill_id,
        certificate_type_id: skill.certificate_type_id,
        certificate_type: skill.CertificateTypes,
        skill_name: skill.skill_name,
        certification_expires: skill.certification_expires,
        days_until_expiry: Math.ceil((skill.certification_expires!.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
      }));

    // Determine validation result
    const isValid = missingCertificateIds.length === 0 && expiredCertificates.length === 0;

    // Build validation details
    let validationDetails = "";
    if (isValid && expiringSoonCertificates.length === 0) {
      validationDetails = `Worker has all ${requiredCertificateIds.length} required valid certificates for ${task.CraneCategory?.name || 'this task'}`;
    } else if (isValid && expiringSoonCertificates.length > 0) {
      validationDetails = `Worker qualified but has ${expiringSoonCertificates.length} certificate(s) expiring soon`;
    } else {
      const issues = [];
      if (missingCertificateIds.length > 0) {
        issues.push(`missing ${missingCertificateIds.length} required certificate(s)`);
      }
      if (expiredCertificates.length > 0) {
        issues.push(`${expiredCertificates.length} expired certificate(s)`);
      }
      validationDetails = `Worker cannot be assigned: ${issues.join(", ")}`;
    }

    const response = {
      is_valid: isValid,
      missing_certificates: missingCertificates,
      expired_certificates: expiredCertificates,
      expiring_soon_certificates: expiringSoonCertificates,
      validation_details: validationDetails,
      task_info: {
        task_id: task.task_id,
        title: task.title,
        crane_category: task.CraneCategory ? {
          id: task.CraneCategory.id,
          name: task.CraneCategory.name,
          code: task.CraneCategory.code
        } : null,
        required_certificate_count: requiredCertificateIds.length
      },
      worker_info: {
        employee_id: worker.employee_id,
        name: worker.name,
        total_certificates: worker.WorkerSkills.filter(s => s.is_certified).length,
        valid_required_certificates: requiredCertificateIds.filter(id => workerCertificateIds.includes(id)).length
      }
    };

    return NextResponse.json(response);
  } catch (error: any) {
    console.error("[API] Error validating worker certificates:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}