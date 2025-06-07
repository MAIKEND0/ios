// src/app/api/app/chef/customers/[id]/logo/presigned/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../../../lib/prisma";
import { CustomerLogoService } from "../../../../../../../../lib/s3-customer-logo";
import { z } from "zod";

interface PresignedUrlResponse {
  success: boolean;
  data: {
    upload_url: string;
    logo_key: string;
    logo_url: string;
    expires_in: number;
  };
}

interface ErrorResponse {
  error: string;
  message: string;
  details?: any;
}

// Validation schema for presigned URL request
const PresignedUrlSchema = z.object({
  fileName: z.string().min(1, "File name is required"),
  contentType: z.string().regex(/^image\/(jpeg|jpg|png|gif|webp|svg\+xml)$/, "Invalid image content type"),
  fileSize: z.number().max(5 * 1024 * 1024, "File size must be less than 5MB"),
});

// GET /api/app/chef/customers/[id]/logo/presigned - Get presigned URL for direct upload
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse<PresignedUrlResponse | ErrorResponse>> {
  try {
    const { id } = await params;
    const customerId = parseInt(id);
    
    if (isNaN(customerId)) {
      return NextResponse.json(
        { error: "Invalid customer ID", message: "Customer ID must be a valid number" },
        { status: 400 }
      );
    }

    console.log(`[Logo Presigned API] GET request for customer ${customerId}`);

    // Check if customer exists
    const customer = await prisma.customers.findUnique({
      where: { customer_id: customerId },
      select: { customer_id: true, name: true }
    });

    if (!customer) {
      return NextResponse.json(
        { error: "Customer not found", message: `Customer with ID ${customerId} does not exist` },
        { status: 404 }
      );
    }

    // Get query parameters
    const { searchParams } = new URL(request.url);
    const fileName = searchParams.get('fileName');
    const contentType = searchParams.get('contentType');
    const fileSize = searchParams.get('fileSize');

    console.log(`[Logo Presigned API] Parameters - fileName: ${fileName}, contentType: ${contentType}, fileSize: ${fileSize}`);

    // Validate parameters
    const validationResult = PresignedUrlSchema.safeParse({
      fileName,
      contentType,
      fileSize: fileSize ? parseInt(fileSize) : 0,
    });

    if (!validationResult.success) {
      console.log(`[Logo Presigned API] Validation failed:`, validationResult.error.errors);
      return NextResponse.json(
        {
          error: "Invalid parameters",
          message: "Please provide valid file information",
          details: validationResult.error.errors,
        },
        { status: 400 }
      );
    }

    const { fileName: validFileName, contentType: validContentType } = validationResult.data;

    // Generate presigned URL
    const presignedResult = await CustomerLogoService.generatePresignedUploadUrl(
      customerId,
      validFileName,
      validContentType
    );

    console.log(`[Logo Presigned API] Generated presigned URL for customer ${customerId}, key: ${presignedResult.logoKey}`);

    return NextResponse.json({
      success: true,
      data: {
        upload_url: presignedResult.uploadUrl,
        logo_key: presignedResult.logoKey,
        logo_url: presignedResult.logoUrl,
        expires_in: 300, // 5 minutes
      },
    }, { 
      status: 200,
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
      }
    });

  } catch (error) {
    console.error("[Logo Presigned API] Error:", error);
    return NextResponse.json(
      {
        error: "Failed to generate upload URL",
        message: error instanceof Error ? error.message : "An error occurred while generating the upload URL",
      },
      { status: 500 }
    );
  }
}