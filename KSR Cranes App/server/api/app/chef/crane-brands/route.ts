// src/app/api/app/chef/crane-brands/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/crane-brands
 * Pobiera dostępne marki żurawi
 */
export async function GET(request: Request): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const isActive = searchParams.get('is_active');
    const includeModelsCount = searchParams.get('include_models_count') === 'true';
    const search = searchParams.get('search');
    
    const where: any = {};
    
    if (isActive !== null) {
      where.isActive = isActive === 'true';
    } else {
      where.isActive = true;
    }
    
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { code: { contains: search, mode: 'insensitive' } }
      ];
    }

    const craneBrands = await prisma.craneBrand.findMany({
      where,
      include: {
        ...(includeModelsCount && {
          _count: {
            select: { craneModels: true }
          }
        })
      },
      orderBy: { name: 'asc' }
    });

    return NextResponse.json(craneBrands, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/app/chef/crane-brands:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}