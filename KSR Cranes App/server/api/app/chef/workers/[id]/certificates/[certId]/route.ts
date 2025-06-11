// /api/app/chef/workers/[id]/certificates/[certId] - Individual worker certificate operations
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../../lib/prisma";

// PUT /api/app/chef/workers/[id]/certificates/[certId] - Update worker certificate
export async function PUT(request: Request, { params }: { params: Promise<{ id: string, certId: string }> }) {
  const { id, certId } = await params;
  try {
    const workerId = parseInt(id);
    const certificateId = parseInt(certId);
    const body = await request.json();

    if (isNaN(workerId) || isNaN(certificateId)) {
      return NextResponse.json({ error: "Invalid worker or certificate ID" }, { status: 400 });
    }

    // Check if worker skill/certificate exists
    const existing = await prisma.workerSkills.findFirst({
      where: {
        skill_id: certificateId,
        employee_id: workerId
      }
    });

    if (!existing) {
      return NextResponse.json({ error: "Worker certificate not found" }, { status: 404 });
    }

    // Update worker skill/certificate
    const updated = await prisma.workerSkills.update({
      where: { skill_id: certificateId },
      data: {
        skill_level: body.skill_level || existing.skill_level,
        is_certified: body.is_certified !== undefined ? body.is_certified : existing.is_certified,
        certification_number: body.certification_number !== undefined ? body.certification_number : existing.certification_number,
        certification_expires: body.certification_expires ? new Date(body.certification_expires) : existing.certification_expires,
        years_experience: body.years_experience !== undefined ? body.years_experience : existing.years_experience,
        crane_type_specialization: body.crane_type_specialization !== undefined ? body.crane_type_specialization : existing.crane_type_specialization,
        notes: body.notes !== undefined ? body.notes : existing.notes
      },
      include: {
        CertificateTypes: true
      }
    });

    // Map response
    const response = {
      success: true,
      message: "Certificate updated successfully",
      certificate: {
        skill_id: updated.skill_id,
        employee_id: updated.employee_id,
        certificate_type_id: updated.certificate_type_id,
        CertificateTypes: updated.CertificateTypes,
        skill_name: updated.skill_name,
        skill_level: updated.skill_level,
        is_certified: updated.is_certified,
        certification_number: updated.certification_number,
        certification_expires: updated.certification_expires,
        years_experience: updated.years_experience,
        crane_type_specialization: updated.crane_type_specialization,
        notes: updated.notes,
        created_at: updated.created_at,
        updated_at: updated.updated_at
      }
    };

    return NextResponse.json(response);
  } catch (error: any) {
    console.error("[API] Error updating worker certificate:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// DELETE /api/app/chef/workers/[id]/certificates/[certId] - Remove certificate from worker
export async function DELETE(request: Request, { params }: { params: Promise<{ id: string, certId: string }> }) {
  const { id, certId } = await params;
  try {
    const workerId = parseInt(id);
    const certificateId = parseInt(certId);

    if (isNaN(workerId) || isNaN(certificateId)) {
      return NextResponse.json({ error: "Invalid worker or certificate ID" }, { status: 400 });
    }

    // Check if worker skill/certificate exists
    const existing = await prisma.workerSkills.findFirst({
      where: {
        skill_id: certificateId,
        employee_id: workerId
      }
    });

    if (!existing) {
      return NextResponse.json({ error: "Worker certificate not found" }, { status: 404 });
    }

    // Delete worker skill/certificate
    await prisma.workerSkills.delete({
      where: { skill_id: certificateId }
    });

    return NextResponse.json({
      success: true,
      message: "Certificate removed successfully",
      certificate_id: certificateId
    });
  } catch (error: any) {
    console.error("[API] Error removing worker certificate:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}