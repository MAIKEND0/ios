// /api/app/chef/workers/[id]/certificates - Worker certificate management
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

// GET /api/app/chef/workers/[id]/certificates - Get worker's certificates
export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    // Check if worker exists
    const worker = await prisma.employees.findUnique({
      where: { employee_id: workerId }
    });

    if (!worker) {
      return NextResponse.json({ error: "Worker not found" }, { status: 404 });
    }

    // Get worker's certificates from WorkerSkills
    const workerSkills = await prisma.workerSkills.findMany({
      where: { employee_id: workerId },
      include: {
        CertificateTypes: true
      },
      orderBy: { skill_name: 'asc' }
    });

    // Map to expected format
    const certificates = workerSkills.map(skill => ({
      skill_id: skill.skill_id,
      employee_id: skill.employee_id,
      certificate_type_id: skill.certificate_type_id,
      CertificateTypes: skill.CertificateTypes ? {
        certificate_type_id: skill.CertificateTypes.certificate_type_id,
        code: skill.CertificateTypes.code,
        name_da: skill.CertificateTypes.name_da,
        name_en: skill.CertificateTypes.name_en,
        description: skill.CertificateTypes.description,
        equipment_types: skill.CertificateTypes.equipment_types,
        capacity_range: skill.CertificateTypes.capacity_range,
        requires_medical: skill.CertificateTypes.requires_medical,
        min_age: skill.CertificateTypes.min_age,
        is_active: skill.CertificateTypes.is_active
      } : null,
      skill_name: skill.skill_name,
      skill_level: skill.skill_level,
      is_certified: skill.is_certified,
      certification_number: skill.certification_number,
      certification_expires: skill.certification_expires,
      years_experience: skill.years_experience,
      crane_type_specialization: skill.crane_type_specialization,
      notes: skill.notes,
      created_at: skill.created_at,
      updated_at: skill.updated_at
    }));

    const response = {
      certificates,
      total_count: certificates.length
    };

    return NextResponse.json(response);
  } catch (error: any) {
    console.error("[API] Error fetching worker certificates:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST /api/app/chef/workers/[id]/certificates - Add certificate to worker
export async function POST(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);
    const body = await request.json();

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    // Validate required fields
    if (!body.certificate_type_id || !body.skill_name || !body.skill_level) {
      return NextResponse.json(
        { error: "Missing required fields: certificate_type_id, skill_name, skill_level" },
        { status: 400 }
      );
    }

    // Check if worker exists
    const worker = await prisma.employees.findUnique({
      where: { employee_id: workerId }
    });

    if (!worker) {
      return NextResponse.json({ error: "Worker not found" }, { status: 404 });
    }

    // Check if certificate type exists
    const certificateType = await prisma.certificateTypes.findUnique({
      where: { certificate_type_id: body.certificate_type_id }
    });

    if (!certificateType) {
      return NextResponse.json({ error: "Certificate type not found" }, { status: 404 });
    }

    // Check if worker already has this certificate
    const existing = await prisma.workerSkills.findFirst({
      where: {
        employee_id: workerId,
        certificate_type_id: body.certificate_type_id
      }
    });

    if (existing) {
      return NextResponse.json(
        { error: "Worker already has this certificate" },
        { status: 409 }
      );
    }

    // Create worker skill/certificate
    const newSkill = await prisma.workerSkills.create({
      data: {
        employee_id: workerId,
        certificate_type_id: body.certificate_type_id,
        skill_name: body.skill_name,
        skill_level: body.skill_level,
        is_certified: body.is_certified || false,
        certification_number: body.certification_number || null,
        certification_expires: body.certification_expires ? new Date(body.certification_expires) : null,
        years_experience: body.years_experience || 0,
        crane_type_specialization: body.crane_type_specialization || null,
        notes: body.notes || null
      },
      include: {
        CertificateTypes: true
      }
    });

    // Map response
    const response = {
      success: true,
      message: "Certificate added successfully",
      certificate: {
        skill_id: newSkill.skill_id,
        employee_id: newSkill.employee_id,
        certificate_type_id: newSkill.certificate_type_id,
        CertificateTypes: newSkill.CertificateTypes,
        skill_name: newSkill.skill_name,
        skill_level: newSkill.skill_level,
        is_certified: newSkill.is_certified,
        certification_number: newSkill.certification_number,
        certification_expires: newSkill.certification_expires,
        years_experience: newSkill.years_experience,
        crane_type_specialization: newSkill.crane_type_specialization,
        notes: newSkill.notes,
        created_at: newSkill.created_at,
        updated_at: newSkill.updated_at
      }
    };

    return NextResponse.json(response, { status: 201 });
  } catch (error: any) {
    console.error("[API] Error adding certificate to worker:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}