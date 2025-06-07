// src/app/api/app/chef/customers/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";
import { z } from "zod";

// Explicit cache configuration for Next.js 15
export const dynamic = 'force-dynamic';

// Validation schemas
const CreateCustomerSchema = z.object({
  name: z.string().min(2, "Company name must be at least 2 characters").max(255, "Company name must be less than 255 characters"),
  contact_email: z.string().email("Invalid email format").optional().nullable(),
  phone: z.string().min(8, "Phone number must be at least 8 characters").max(15, "Phone number must be less than 15 characters").optional().nullable(),
  address: z.string().max(255, "Address must be less than 255 characters").optional().nullable(),
  cvr: z.string().regex(/^\d{8}$/, "CVR must be exactly 8 digits").optional().nullable(),
});

const UpdateCustomerSchema = CreateCustomerSchema.partial().extend({
  name: z.string().min(2, "Company name must be at least 2 characters").max(255, "Company name must be less than 255 characters"),
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
  logo_url: string | null;
  logo_uploaded_at: Date | null;
  project_count?: number;
  hiring_request_count?: number;
  recent_projects?: any[];
}

interface ErrorResponse {
  error: string;
  message?: string;
  details?: any;
}

interface SuccessResponse {
  success: boolean;
  message: string;
  data?: any;
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
    logo_url: customer.logo_url,
    logo_uploaded_at: customer.logo_uploaded_at,
  };
}

// Helper function to handle database errors
function handleDatabaseError(error: any): NextResponse<ErrorResponse> {
  console.error("[Customers API] Database error:", error);
  
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

// GET /api/app/chef/customers - Fetch all customers
export async function GET(request: NextRequest): Promise<NextResponse<CustomerResponse[] | ErrorResponse>> {
  try {
    console.log("[Customers API] GET request received");
    
    const { searchParams } = new URL(request.url);
    const search = searchParams.get("search");
    const limit = searchParams.get("limit");
    const offset = searchParams.get("offset");
    const includeLogo = searchParams.get("include_logo");

    // Input validation for query parameters
    const limitNum = limit ? parseInt(limit) : undefined;
    const offsetNum = offset ? parseInt(offset) : undefined;

    if (limit && (isNaN(limitNum!) || limitNum! < 0)) {
      return NextResponse.json(
        { 
          error: "Invalid limit", 
          message: "Limit must be a positive number" 
        }, 
        { status: 400 }
      );
    }

    if (offset && (isNaN(offsetNum!) || offsetNum! < 0)) {
      return NextResponse.json(
        { 
          error: "Invalid offset", 
          message: "Offset must be a positive number" 
        }, 
        { status: 400 }
      );
    }

    let whereClause: any = {};
    
    // Add search functionality (MySQL is case-insensitive by default)
    if (search && search.trim().length > 0) {
      const searchTerm = search.trim();
      whereClause = {
        OR: [
          { name: { contains: searchTerm } },
          { contact_email: { contains: searchTerm } },
          { phone: { contains: searchTerm } },
          { cvr_nr: { contains: searchTerm } },
          { address: { contains: searchTerm } },
        ],
      };
    }

    const customers = await prisma.customers.findMany({
      where: whereClause,
      orderBy: { created_at: "desc" },
      take: limitNum,
      skip: offsetNum,
      include: {
        Projects: {
          select: {
            project_id: true,
            title: true,
            status: true,
            created_at: true,
          },
          take: 3, // Limit to 3 recent projects for performance
          orderBy: { created_at: "desc" },
        },
        _count: {
          select: {
            Projects: true,
            hiringRequests: true,
          },
        },
      },
    });

    const formattedCustomers = customers.map(customer => ({
      ...formatCustomerForApp(customer),
      project_count: customer._count.Projects,
      hiring_request_count: customer._count.hiringRequests,
      recent_projects: customer.Projects,
    }));

    console.log(`[Customers API] Retrieved ${formattedCustomers.length} customers`);
    
    return NextResponse.json(formattedCustomers, { 
      status: 200,
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
      }
    });
  } catch (error) {
    console.error("[Customers API] GET error:", error);
    return NextResponse.json(
      { 
        error: "Failed to fetch customers", 
        message: "An error occurred while fetching customers" 
      }, 
      { status: 500 }
    );
  }
}

// POST /api/app/chef/customers - Create new customer
export async function POST(request: NextRequest): Promise<NextResponse<CustomerResponse | ErrorResponse>> {
  try {
    console.log("[Customers API] POST request received");
    
    const body = await request.json();
    console.log("[Customers API] Request body:", body);

    // Validate request body
    const validationResult = CreateCustomerSchema.safeParse(body);
    if (!validationResult.success) {
      console.log("[Customers API] Validation failed:", validationResult.error.errors);
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

    // Check if customer with same name already exists (MySQL is case-insensitive by default)
    const existingCustomer = await prisma.customers.findFirst({
      where: {
        name: {
          equals: validatedData.name
        }
      }
    });

    if (existingCustomer) {
      return NextResponse.json(
        { 
          error: "Customer already exists", 
          message: `A customer with the name "${validatedData.name}" already exists` 
        }, 
        { status: 409 }
      );
    }

    // Check CVR uniqueness if provided
    if (validatedData.cvr) {
      const existingCVR = await prisma.customers.findFirst({
        where: {
          cvr_nr: validatedData.cvr
        }
      });

      if (existingCVR) {
        return NextResponse.json(
          { 
            error: "CVR already exists", 
            message: `A customer with CVR "${validatedData.cvr}" already exists` 
          }, 
          { status: 409 }
        );
      }
    }

    // Create new customer
    const newCustomer = await prisma.customers.create({
      data: {
        name: validatedData.name.trim(),
        contact_email: validatedData.contact_email?.trim() || null,
        phone: validatedData.phone?.trim() || null,
        address: validatedData.address?.trim() || null,
        cvr_nr: validatedData.cvr?.trim() || null,
        logo_url: null,
        logo_key: null,
        logo_uploaded_at: null,
      },
    });

    const formattedCustomer = formatCustomerForApp(newCustomer);
    console.log("[Customers API] Customer created successfully:", formattedCustomer.customer_id);

    return NextResponse.json(formattedCustomer, { 
      status: 201,
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
      }
    });
  } catch (error) {
    console.error("[Customers API] POST error:", error);
    return handleDatabaseError(error);
  }
}

// PUT /api/app/chef/customers/[id] endpoint will be in a separate file
// DELETE /api/app/chef/customers/[id] endpoint will be in a separate file