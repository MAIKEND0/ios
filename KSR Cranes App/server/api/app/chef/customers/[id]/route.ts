// src/app/api/app/chef/customers/[id]/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";
import { z } from "zod";

// Validation schemas
const UpdateCustomerSchema = z.object({
  name: z.string().min(2, "Company name must be at least 2 characters").max(255, "Company name must be less than 255 characters"),
  contact_email: z.string().email("Invalid email format").optional().nullable(),
  phone: z.string().min(8, "Phone number must be at least 8 characters").max(15, "Phone number must be less than 15 characters").optional().nullable(),
  address: z.string().max(255, "Address must be less than 255 characters").optional().nullable(),
  cvr: z.string().regex(/^\d{8}$/, "CVR must be exactly 8 digits").optional().nullable(),
});

// Response types
interface CustomerResponse {
  customer_id: number;
  name: string;
  contact_email: string | null;
  phone: string | null;
  address: string | null;
  cvr_nr: string | null;
  created_at: Date | null;
}

interface ErrorResponse {
  error: string;
  message?: string;
  details?: any;
}

interface DeleteResponse {
  success: boolean;
  message: string;
}

// Helper function to format customer data for iOS app
function formatCustomerForApp(customer: any): CustomerResponse {
  return {
    customer_id: customer.customer_id,
    name: customer.name,
    contact_email: customer.contact_email,
    phone: customer.phone,
    address: customer.address,
    cvr_nr: customer.cvr_nr,
    created_at: customer.created_at,
  };
}

// Helper function to handle database errors
function handleDatabaseError(error: any): NextResponse<ErrorResponse> {
  console.error("[Customer API] Database error:", error);
  
  if (error.code === 'P2002') {
    return NextResponse.json(
      { 
        error: "Duplicate entry", 
        message: "A customer with this information already exists",
        details: error.meta 
      }, 
      { status: 409 }
    );
  }
  
  if (error.code === 'P2025') {
    return NextResponse.json(
      { 
        error: "Not found", 
        message: "Customer not found" 
      }, 
      { status: 404 }
    );
  }
  
  return NextResponse.json(
    { 
      error: "Database error", 
      message: "An error occurred while processing your request" 
    }, 
    { status: 500 }
  );
}

// Helper function to validate customer ID
function validateCustomerId(id: string): number | null {
  const customerId = parseInt(id);
  if (isNaN(customerId) || customerId <= 0) {
    return null;
  }
  return customerId;
}

// GET /api/app/chef/customers/[id] - Get single customer
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse<CustomerResponse | ErrorResponse>> {
  try {
    const { id } = await params;
    console.log(`[Customer API] GET request received for ID: ${id}`);
    
    const customerId = validateCustomerId(id);
    if (!customerId) {
      return NextResponse.json(
        { 
          error: "Invalid customer ID", 
          message: "Customer ID must be a positive number" 
        }, 
        { status: 400 }
      );
    }

    const customer = await prisma.customers.findUnique({
      where: { customer_id: customerId },
      include: {
        Projects: {
          select: {
            project_id: true,
            title: true,
            status: true,
            start_date: true,
            end_date: true,
            created_at: true,
          },
          orderBy: { created_at: 'desc' },
        },
        hiringRequests: {
          select: {
            id: true,
            projectName: true,
            status: true,
            startDate: true,
            createdAt: true,
          },
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
        _count: {
          select: {
            Projects: true,
            hiringRequests: true,
          },
        },
      },
    });

    if (!customer) {
      return NextResponse.json(
        { 
          error: "Customer not found", 
          message: `Customer with ID ${customerId} does not exist` 
        }, 
        { status: 404 }
      );
    }

    const formattedCustomer = {
      ...formatCustomerForApp(customer),
      project_count: customer._count.Projects,
      hiring_request_count: customer._count.hiringRequests,
      projects: customer.Projects,
      recent_hiring_requests: customer.hiringRequests,
    };

    console.log(`[Customer API] Customer retrieved successfully: ${customerId}`);
    
    return NextResponse.json(formattedCustomer, { status: 200 });
  } catch (error) {
    console.error("[Customer API] GET error:", error);
    return NextResponse.json(
      { 
        error: "Failed to fetch customer", 
        message: "An error occurred while fetching the customer" 
      }, 
      { status: 500 }
    );
  }
}

// PUT /api/app/chef/customers/[id] - Update customer
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse<CustomerResponse | ErrorResponse>> {
  try {
    const { id } = await params;
    console.log(`[Customer API] PUT request received for ID: ${id}`);
    
    const customerId = validateCustomerId(id);
    if (!customerId) {
      return NextResponse.json(
        { 
          error: "Invalid customer ID", 
          message: "Customer ID must be a positive number" 
        }, 
        { status: 400 }
      );
    }

    const body = await request.json();
    console.log("[Customer API] Request body:", body);

    // Validate request body
    const validationResult = UpdateCustomerSchema.safeParse(body);
    if (!validationResult.success) {
      console.log("[Customer API] Validation failed:", validationResult.error.errors);
      return NextResponse.json(
        { 
          error: "Validation failed", 
          message: "Please check your input data",
          details: validationResult.error.errors 
        }, 
        { status: 400 }
      );
    }

    const validatedData = validationResult.data;

    // Check if customer exists
    const existingCustomer = await prisma.customers.findUnique({
      where: { customer_id: customerId }
    });

    if (!existingCustomer) {
      return NextResponse.json(
        { 
          error: "Customer not found", 
          message: `Customer with ID ${customerId} does not exist` 
        }, 
        { status: 404 }
      );
    }

    // Check if name is already taken by another customer
    if (validatedData.name !== existingCustomer.name) {
      const nameConflict = await prisma.customers.findFirst({
        where: {
          name: {
            equals: validatedData.name
          },
          customer_id: {
            not: customerId
          }
        }
      });

      if (nameConflict) {
        return NextResponse.json(
          { 
            error: "Customer name already exists", 
            message: `A different customer with the name "${validatedData.name}" already exists` 
          }, 
          { status: 409 }
        );
      }
    }

    // Check CVR uniqueness if provided and changed
    if (validatedData.cvr && validatedData.cvr !== existingCustomer.cvr_nr) {
      const cvrConflict = await prisma.customers.findFirst({
        where: {
          cvr_nr: validatedData.cvr,
          customer_id: {
            not: customerId
          }
        }
      });

      if (cvrConflict) {
        return NextResponse.json(
          { 
            error: "CVR already exists", 
            message: `A different customer with CVR "${validatedData.cvr}" already exists` 
          }, 
          { status: 409 }
        );
      }
    }

    // Update customer
    const updatedCustomer = await prisma.customers.update({
      where: { customer_id: customerId },
      data: {
        name: validatedData.name.trim(),
        contact_email: validatedData.contact_email?.trim() || null,
        phone: validatedData.phone?.trim() || null,
        address: validatedData.address?.trim() || null,
        cvr_nr: validatedData.cvr?.trim() || null,
      },
    });

    const formattedCustomer = formatCustomerForApp(updatedCustomer);
    console.log(`[Customer API] Customer updated successfully: ${customerId}`);

    return NextResponse.json(formattedCustomer, { status: 200 });
  } catch (error) {
    console.error("[Customer API] PUT error:", error);
    return handleDatabaseError(error);
  }
}

// DELETE /api/app/chef/customers/[id] - Delete customer
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse<DeleteResponse | ErrorResponse>> {
  try {
    const { id } = await params;
    console.log(`[Customer API] DELETE request received for ID: ${id}`);
    
    const customerId = validateCustomerId(id);
    if (!customerId) {
      return NextResponse.json(
        { 
          error: "Invalid customer ID", 
          message: "Customer ID must be a positive number" 
        }, 
        { status: 400 }
      );
    }

    // Check if customer exists
    const existingCustomer = await prisma.customers.findUnique({
      where: { customer_id: customerId },
      include: {
        _count: {
          select: {
            Projects: true,
            hiringRequests: true,
          },
        },
      },
    });

    if (!existingCustomer) {
      return NextResponse.json(
        { 
          error: "Customer not found", 
          message: `Customer with ID ${customerId} does not exist` 
        }, 
        { status: 404 }
      );
    }

    // Check if customer has associated data that would prevent deletion
    if (existingCustomer._count.Projects > 0) {
      return NextResponse.json(
        { 
          error: "Cannot delete customer", 
          message: `Customer has ${existingCustomer._count.Projects} associated project(s). Please remove or reassign projects before deleting the customer.` 
        }, 
        { status: 409 }
      );
    }

    if (existingCustomer._count.hiringRequests > 0) {
      return NextResponse.json(
        { 
          error: "Cannot delete customer", 
          message: `Customer has ${existingCustomer._count.hiringRequests} associated hiring request(s). Please handle these requests before deleting the customer.` 
        }, 
        { status: 409 }
      );
    }

    // Delete customer
    await prisma.customers.delete({
      where: { customer_id: customerId }
    });

    console.log(`[Customer API] Customer deleted successfully: ${customerId}`);

    return NextResponse.json(
      { 
        success: true, 
        message: `Customer "${existingCustomer.name}" has been deleted successfully` 
      }, 
      { status: 200 }
    );
  } catch (error) {
    console.error("[Customer API] DELETE error:", error);
    return handleDatabaseError(error);
  }
}