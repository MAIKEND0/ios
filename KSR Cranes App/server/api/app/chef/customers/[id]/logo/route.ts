// src/app/api/app/chef/customers/[id]/logo/route.ts - ZAKTUALIZOWANY ISTNIEJĄCY PLIK

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";
import { CustomerLogoService } from "../../../../../../../lib/s3-customer-logo";

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

// POST /api/app/chef/customers/[id]/logo - Upload logo directly (multipart/form-data)
export async function POST(
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

    console.log(`[Logo Upload API] POST request for customer ${customerId}`);

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

    // Parse form data
    const formData = await request.formData();
    const file = formData.get('logo') as File;
    
    if (!file) {
      return NextResponse.json(
        { error: "No file provided", message: "Please provide a logo file" },
        { status: 400 }
      );
    }

    console.log(`[Logo Upload API] Uploading file: ${file.name}, size: ${file.size}, type: ${file.type}`);

    // Convert file to buffer
    const arrayBuffer = await file.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    // Delete old logo if exists
    if (customer.logo_key) {
      try {
        await CustomerLogoService.deleteCustomerLogo(customer.logo_key);
        console.log(`[Logo Upload API] Deleted old logo for customer ${customerId}: ${customer.logo_key}`);
      } catch (error) {
        console.warn(`[Logo Upload API] Failed to delete old logo: ${error}`);
        // Continue with upload even if deletion fails
      }
    }

    // Upload new logo (with ACL public-read)
    const uploadResult = await CustomerLogoService.uploadCustomerLogo(
      customerId,
      buffer,
      file.name,
      file.type
    );

    // Update customer record with new logo
    const updatedCustomer = await prisma.customers.update({
      where: { customer_id: customerId },
      data: {
        logo_url: uploadResult.logoUrl,
        logo_key: uploadResult.logoKey,
        logo_uploaded_at: new Date(),
      },
      select: {
        customer_id: true,
        name: true,
        logo_url: true,
        logo_uploaded_at: true
      }
    });

    console.log(`[Logo Upload API] Logo uploaded successfully for customer ${customerId}: ${uploadResult.logoUrl}`);

    return NextResponse.json({
      success: true,
      message: `Logo uploaded successfully for ${updatedCustomer.name}`,
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
    console.error("[Logo Upload API] Error:", error);
    return NextResponse.json(
      {
        error: "Upload failed",
        message: error instanceof Error ? error.message : "An error occurred while uploading the logo",
      },
      { status: 500 }
    );
  }
}

// DELETE /api/app/chef/customers/[id]/logo - Delete customer logo
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse<{ success: boolean; message: string } | ErrorResponse>> {
  try {
    const { id } = await params;
    const customerId = parseInt(id);
    
    if (isNaN(customerId)) {
      return NextResponse.json(
        { error: "Invalid customer ID", message: "Customer ID must be a valid number" },
        { status: 400 }
      );
    }

    console.log(`[Logo Delete API] DELETE request for customer ${customerId}`);

    // Check if customer exists and has a logo
    const customer = await prisma.customers.findUnique({
      where: { customer_id: customerId },
      select: { customer_id: true, name: true, logo_key: true, logo_url: true }
    });

    if (!customer) {
      return NextResponse.json(
        { error: "Customer not found", message: `Customer with ID ${customerId} does not exist` },
        { status: 404 }
      );
    }

    if (!customer.logo_key && !customer.logo_url) {
      return NextResponse.json(
        { error: "No logo found", message: `Customer ${customer.name} does not have a logo to delete` },
        { status: 404 }
      );
    }

    // Delete from storage if logo_key exists
    if (customer.logo_key) {
      try {
        await CustomerLogoService.deleteCustomerLogo(customer.logo_key);
        console.log(`[Logo Delete API] Deleted logo from storage: ${customer.logo_key}`);
      } catch (error) {
        console.error(`[Logo Delete API] Failed to delete from storage: ${error}`);
        // Continue with database update even if storage deletion fails
      }
    }

    // Update database - clear logo fields
    await prisma.customers.update({
      where: { customer_id: customerId },
      data: {
        logo_url: null,
        logo_key: null,
        logo_uploaded_at: null,
      },
    });

    console.log(`[Logo Delete API] Logo deleted successfully for customer ${customerId}`);

    return NextResponse.json({
      success: true,
      message: `Logo deleted successfully for ${customer.name}`,
    }, { 
      status: 200,
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
      }
    });

  } catch (error) {
    console.error("[Logo Delete API] Error:", error);
    
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
        error: "Delete failed",
        message: error instanceof Error ? error.message : "An error occurred while deleting the logo",
      },
      { status: 500 }
    );
  }
}