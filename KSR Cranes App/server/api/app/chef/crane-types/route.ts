// src/app/api/app/chef/crane-types/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/crane-types
 * Pobiera dostępne typy żurawi z pełnymi danymi kategorii
 */
export async function GET(request: Request): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const categoryId = searchParams.get('category_id');
    const isActive = searchParams.get('is_active');
    const includeModelsCount = searchParams.get('include_models_count') === 'true';
    
    const where: any = {};
    
    if (categoryId) {
      where.categoryId = parseInt(categoryId);
    }
    
    if (isActive !== null) {
      where.isActive = isActive === 'true';
    } else {
      where.isActive = true;
    }

    console.log(`🔍 [crane-types] Fetching types with filters:`, where);

    const craneTypes = await prisma.craneType.findMany({
      where,
      include: {
        // ✅ FIXED: Include ALL required category fields that Swift expects
        category: {
          select: {
            id: true,
            name: true,
            code: true,
            description: true,
            iconUrl: true,
            displayOrder: true,  // ✅ DODANO: Brakujące pole używane w orderBy
            isActive: true,      // ✅ DODANO: Pole wymagane przez Swift model
            createdAt: true,     // ✅ DODANO: Pole wymagane przez Swift model
            updatedAt: true      // ✅ DODANO: Pole wymagane przez Swift model
          }
        },
        ...(includeModelsCount && {
          _count: {
            select: { craneModels: true }
          }
        })
      },
      orderBy: [
        { category: { displayOrder: 'asc' } },
        { displayOrder: 'asc' },
        { name: 'asc' }
      ]
    });

    console.log(`✅ [crane-types] Found ${craneTypes.length} types`);
    
    // ✅ DODANO: Debug logging dla pierwszego elementu
    if (craneTypes.length > 0) {
      console.log(`🔍 [crane-types] First type structure:`, {
        id: craneTypes[0].id,
        name: craneTypes[0].name,
        categoryId: craneTypes[0].categoryId,
        category: {
          id: craneTypes[0].category.id,
          name: craneTypes[0].category.name,
          displayOrder: craneTypes[0].category.displayOrder,
          hasAllRequiredFields: {
            displayOrder: craneTypes[0].category.displayOrder !== undefined,
            isActive: craneTypes[0].category.isActive !== undefined,
            createdAt: craneTypes[0].category.createdAt !== undefined,
            updatedAt: craneTypes[0].category.updatedAt !== undefined
          }
        }
      });
    }

    return NextResponse.json(craneTypes, { status: 200 });

  } catch (err: any) {
    console.error("❌ [crane-types] Error:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}