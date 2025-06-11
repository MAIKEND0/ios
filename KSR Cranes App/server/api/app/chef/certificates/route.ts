// /api/app/chef/certificates - Certificate types management
import { NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";

// GET /api/app/chef/certificates - List all certificate types
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const onlyActive = searchParams.get("only_active") === "true";

    const whereClause: any = {};
    if (onlyActive) {
      whereClause.is_active = true;
    }

    const certificateTypes = await prisma.certificateTypes.findMany({
      where: whereClause,
      orderBy: [
        { code: 'asc' }
      ]
    });

    // Map to iOS expected format
    const response = {
      certificate_types: certificateTypes.map(cert => ({
        certificate_type_id: cert.certificate_type_id,
        code: cert.code,
        name_da: cert.name_da,
        name_en: cert.name_en,
        description: cert.description,
        equipment_types: cert.equipment_types,
        capacity_range: cert.capacity_range,
        requires_medical: cert.requires_medical,
        min_age: cert.min_age,
        is_active: cert.is_active,
        created_at: cert.created_at,
        updated_at: cert.updated_at
      })),
      total_count: certificateTypes.length
    };

    return NextResponse.json(response);
  } catch (error: any) {
    console.error("[API] Error fetching certificate types:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST /api/app/chef/certificates - Create new certificate type (admin only)
export async function POST(request: Request) {
  try {
    const body = await request.json();

    // Validate required fields
    if (!body.code || !body.name_da || !body.name_en) {
      return NextResponse.json(
        { error: "Missing required fields: code, name_da, name_en" },
        { status: 400 }
      );
    }

    // Check if code already exists
    const existing = await prisma.certificateTypes.findUnique({
      where: { code: body.code }
    });

    if (existing) {
      return NextResponse.json(
        { error: "Certificate type with this code already exists" },
        { status: 409 }
      );
    }

    const newCertificateType = await prisma.certificateTypes.create({
      data: {
        code: body.code,
        name_da: body.name_da,
        name_en: body.name_en,
        description: body.description || null,
        equipment_types: body.equipment_types || null,
        capacity_range: body.capacity_range || null,
        requires_medical: body.requires_medical ?? true,
        min_age: body.min_age ?? 18,
        is_active: body.is_active ?? true
      }
    });

    return NextResponse.json(newCertificateType, { status: 201 });
  } catch (error: any) {
    console.error("[API] Error creating certificate type:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}