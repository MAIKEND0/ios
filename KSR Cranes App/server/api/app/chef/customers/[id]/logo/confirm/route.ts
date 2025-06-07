// src/app/api/app/chef/customers/[id]/logo/confirm/route.ts - ZAKTUALIZOWANY ISTNIEJĄCY PLIK

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../../../lib/prisma";
import { CustomerLogoService } from "../../../../../../../../lib/s3-customer-logo";
import { z } from "zod";

interface LogoUploadResponse {
  success: boolean;
  message: string;
  data: {
    logo_url: string;
    logo_uploaded_at: Date;
  };
}

interface ErrorResponse {
  error: string;
  message: string;
  details?: any;
}

// Validation schema for confirm request
const LogoConfirmSchema = z.object({
  logo_key: z.string().min(1, "Logo key is required"),
  logo_url: z.string().url("Invalid logo URL"),
});

// PUT /api/app/chef/customers/[id]/logo/confirm - Confirm logo upload after presigned URL usage
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse<LogoUploadResponse | ErrorResponse>> {
  try {
    const { id } = await params;
    const customerId = parseInt(id);
    
    if (isNaN(customerId)) {
      return NextResponse.json(
        { error: "Invalid customer ID", message: "Customer ID must be a valid number" },
        { status: 400 }
      );
    }

    console.log(`[Logo Confirm API] PUT request for customer ${customerId}`);

    const body = await request.json();
    console.log(`[Logo Confirm API] Request body:`, body);

    // Validate request body
    const validationResult = LogoConfirmSchema.safeParse(body);
    
    if (!validationResult.success) {
      console.log(`[Logo Confirm API] Validation failed:`, validationResult.error.errors);
      return NextResponse.json(
        {
          error: "Invalid request data",
          message: "Please provide valid logo key and URL",
          details: validationResult.error.errors,
        },
        { status: 400 }
      );
    }

    const { logo_key, logo_url } = validationResult.data;

    // Check if customer exists
    const customer = await prisma.customers.findUnique({
      where: { customer_id: customerId },
      select: { customer_id: true, name: true, logo_key: true }
    });

    if (!customer) {
      return NextResponse.json(
        { error: "Customer not found", message: `Customer with ID ${customerId} does not exist` },
        { status: 404 }
      );
    }

    // Delete old logo if exists and is different from new one
    if (customer.logo_key && customer.logo_key !== logo_key) {
      try {
        await CustomerLogoService.deleteCustomerLogo(customer.logo_key);
        console.log(`[Logo Confirm API] Deleted old logo for customer ${customerId}: ${customer.logo_key}`);
      } catch (error) {
        console.warn(`[Logo Confirm API] Failed to delete old logo: ${error}`);
        // Continue with update even if deletion fails
      }
    }

    // Update database with new logo info
    const updatedCustomer = await prisma.customers.update({
      where: { customer_id: customerId },
      data: {
        logo_url,
        logo_key,
        logo_uploaded_at: new Date(),
      },
      select: {
        customer_id: true,
        name: true,
        logo_url: true,
        logo_uploaded_at: true
      }
    });

    console.log(`[Logo Confirm API] Logo confirmed for customer ${customerId}: ${logo_url}`);

    return NextResponse.json({
      success: true,
      message: `Logo upload confirmed for ${updatedCustomer.name}`,
      data: {
        logo_url: updatedCustomer.logo_url!,
        logo_uploaded_at: updatedCustomer.logo_uploaded_at!,
      },
    }, { 
      status: 200,
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
      }
    });

  } catch (error) {
    console.error("[Logo Confirm API] Error:", error);
    
    // Handle database errors
    if (error && typeof error === 'object' && 'code' in error) {
      if (error.code === 'P2025') {
        return NextResponse.json(
          { 
            error: "Customer not found", 
            message: "Customer not found or has been deleted" 
          }, 
          { status: 404 }
        );
      }
    }

    return NextResponse.json(
      {
        error: "Confirmation failed",
        message: error instanceof Error ? error.message : "An error occurred while confirming the logo upload",
      },
      { status: 500 }
    );
  }
}