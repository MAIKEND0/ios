// /api/app/chef/certificates/[id] - Individual certificate type operations
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// GET /api/app/chef/certificates/[id] - Get specific certificate type
export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const certificateId = parseInt(id);

    if (isNaN(certificateId)) {
      return NextResponse.json({ error: "Invalid certificate ID" }, { status: 400 });
    }

    const certificateType = await prisma.certificateTypes.findUnique({
      where: { certificate_type_id: certificateId }
    });

    if (!certificateType) {
      return NextResponse.json({ error: "Certificate type not found" }, { status: 404 });
    }

    return NextResponse.json(certificateType);
  } catch (error: any) {
    console.error("[API] Error fetching certificate type:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PUT /api/app/chef/certificates/[id] - Update certificate type
export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const certificateId = parseInt(id);
    const body = await request.json();

    if (isNaN(certificateId)) {
      return NextResponse.json({ error: "Invalid certificate ID" }, { status: 400 });
    }

    // Check if certificate type exists
    const existing = await prisma.certificateTypes.findUnique({
      where: { certificate_type_id: certificateId }
    });

    if (!existing) {
      return NextResponse.json({ error: "Certificate type not found" }, { status: 404 });
    }

    // Check if new code conflicts with another certificate
    if (body.code && body.code !== existing.code) {
      const codeExists = await prisma.certificateTypes.findFirst({
        where: {
          code: body.code,
          NOT: { certificate_type_id: certificateId }
        }
      });

      if (codeExists) {
        return NextResponse.json(
          { error: "Certificate type with this code already exists" },
          { status: 409 }
        );
      }
    }

    // Update certificate type
    const updated = await prisma.certificateTypes.update({
      where: { certificate_type_id: certificateId },
      data: {
        code: body.code || existing.code,
        name_da: body.name_da || existing.name_da,
        name_en: body.name_en || existing.name_en,
        description: body.description !== undefined ? body.description : existing.description,
        equipment_types: body.equipment_types !== undefined ? body.equipment_types : existing.equipment_types,
        capacity_range: body.capacity_range !== undefined ? body.capacity_range : existing.capacity_range,
        requires_medical: body.requires_medical !== undefined ? body.requires_medical : existing.requires_medical,
        min_age: body.min_age !== undefined ? body.min_age : existing.min_age,
        is_active: body.is_active !== undefined ? body.is_active : existing.is_active
      }
    });

    return NextResponse.json(updated);
  } catch (error: any) {
    console.error("[API] Error updating certificate type:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// DELETE /api/app/chef/certificates/[id] - Deactivate certificate type
export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const certificateId = parseInt(id);

    if (isNaN(certificateId)) {
      return NextResponse.json({ error: "Invalid certificate ID" }, { status: 400 });
    }

    // Check if certificate type exists
    const existing = await prisma.certificateTypes.findUnique({
      where: { certificate_type_id: certificateId }
    });

    if (!existing) {
      return NextResponse.json({ error: "Certificate type not found" }, { status: 404 });
    }

    // Check if certificate is in use by any workers
    const inUse = await prisma.workerSkills.findFirst({
      where: { certificate_type_id: certificateId }
    });

    if (inUse) {
      // Soft delete - just deactivate
      await prisma.certificateTypes.update({
        where: { certificate_type_id: certificateId },
        data: { is_active: false }
      });

      return NextResponse.json({
        success: true,
        message: "Certificate type deactivated (in use by workers)"
      });
    } else {
      // Hard delete if not in use
      await prisma.certificateTypes.delete({
        where: { certificate_type_id: certificateId }
      });

      return NextResponse.json({
        success: true,
        message: "Certificate type deleted permanently"
      });
    }
  } catch (error: any) {
    console.error("[API] Error deleting certificate type:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}