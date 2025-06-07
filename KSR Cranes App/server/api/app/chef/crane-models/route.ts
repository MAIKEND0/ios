// src/app/api/app/chef/crane-models/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/crane-models
 * Pobiera dostępne modele żurawi z filtrami
 */
export async function GET(request: Request): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const typeId = searchParams.get('type_id');
    const brandId = searchParams.get('brand_id');
    const categoryId = searchParams.get('category_id');
    const search = searchParams.get('search');
    const isActive = searchParams.get('is_active');
    const includeDiscontinued = searchParams.get('include_discontinued') === 'true';
    
    // Build where clause
    const where: any = {};
    
    if (typeId) {
      where.typeId = parseInt(typeId);
    }
    
    if (brandId) {
      where.brandId = parseInt(brandId);
    }
    
    if (categoryId) {
      where.type = {
        categoryId: parseInt(categoryId)
      };
    }
    
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { code: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } }
      ];
    }
    
    if (isActive !== null) {
      where.isActive = isActive === 'true';
    } else {
      where.isActive = true; // Default to active models
    }
    
    if (!includeDiscontinued) {
      where.isDiscontinued = false;
    }

    console.log(`🔍 [crane-models] Fetching models with filters:`, where);

    const craneModels = await prisma.craneModel.findMany({
      where,
      include: {
        brand: {
          select: {
            id: true,
            name: true,
            code: true,
            logoUrl: true  // ✅ DOBRE: This field exists
          }
        },
        type: {
          select: {
            id: true,
            name: true,
            code: true,
            description: true,
            category: {
              select: {
                id: true,
                name: true,
                code: true
              }
            }
          }
        }
      },
      orderBy: [
        { brand: { name: 'asc' } },
        { name: 'asc' }
      ]
    });

    console.log(`✅ [crane-models] Found ${craneModels.length} models`);

    // Transform the response to include brand and type names at the top level
    const transformedModels = craneModels.map(model => ({
      id: model.id,
      brandId: model.brandId,
      typeId: model.typeId,
      name: model.name,
      code: model.code,
      description: model.description,
      maxLoadCapacity: model.maxLoadCapacity,
      maxHeight: model.maxHeight,
      maxRadius: model.maxRadius,
      enginePower: model.enginePower,
      specifications: model.specifications,
      imageUrl: model.imageUrl,
      brochureUrl: model.brochureUrl,
      videoUrl: model.videoUrl,
      releaseYear: model.releaseYear,
      isDiscontinued: model.isDiscontinued,
      isActive: model.isActive,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      // ✅ POPRAWIONE: Flattened brand and type info
      brand_name: model.brand.name,
      brand_code: model.brand.code,
      brand_logo_url: model.brand.logoUrl,  // ✅ DOBRE: Correctly mapped
      type_name: model.type.name,
      type_code: model.type.code,
      category_id: model.type.category.id,
      category_name: model.type.category.name,
      category_code: model.type.category.code
    }));

    // ✅ DODANO: Debug logging dla pierwszego modelu
    if (transformedModels.length > 0) {
      console.log(`🔍 [crane-models] First model structure:`, {
        id: transformedModels[0].id,
        name: transformedModels[0].name,
        brand_name: transformedModels[0].brand_name,
        type_name: transformedModels[0].type_name,
        category_name: transformedModels[0].category_name,
        hasAllFlattenedFields: {
          brand_name: transformedModels[0].brand_name !== undefined,
          brand_code: transformedModels[0].brand_code !== undefined,
          brand_logo_url: transformedModels[0].brand_logo_url !== undefined,
          type_name: transformedModels[0].type_name !== undefined,
          type_code: transformedModels[0].type_code !== undefined,
          category_id: transformedModels[0].category_id !== undefined,
          category_name: transformedModels[0].category_name !== undefined,
          category_code: transformedModels[0].category_code !== undefined
        }
      });
    }

    return NextResponse.json(transformedModels, { status: 200 });

  } catch (err: any) {
    console.error("❌ [crane-models] Error:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}