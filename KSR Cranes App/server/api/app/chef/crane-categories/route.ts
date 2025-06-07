// src/app/api/app/chef/crane-categories/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/crane-categories
 * Pobiera dostępne kategorie żurawi
 */
export async function GET(request: Request): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const isActive = searchParams.get('is_active');
    const includeTypesCount = searchParams.get('include_types_count') === 'true';
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
        { code: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } }
      ];
    }

    const craneCategories = await prisma.craneCategory.findMany({
      where,
      include: {
        ...(includeTypesCount && {
          _count: {
            select: { craneTypes: true }
          }
        })
      },
      orderBy: { displayOrder: 'asc' }
    });

    return NextResponse.json(craneCategories, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/app/chef/crane-categories:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}