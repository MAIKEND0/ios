// src/app/api/app/chef/customers/search/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";
import { z } from "zod";

// Validation schema for search parameters
const SearchParamsSchema = z.object({
  q: z.string().min(1, "Search query is required").max(255, "Search query too long"),
  limit: z.coerce.number().min(1).max(100).optional().default(20),
  offset: z.coerce.number().min(0).optional().default(0),
  include_projects: z.coerce.boolean().optional().default(false),
  include_stats: z.coerce.boolean().optional().default(false),
});

// Response types
interface CustomerSearchResult {
  customer_id: number;
  name: string;
  contact_email: string | null;
  phone: string | null;
  address: string | null;
  cvr_nr: string | null;
  created_at: Date | null;
  project_count?: number;
  hiring_request_count?: number;
  recent_projects?: any[];
  match_fields?: string[];
}

interface SearchResponse {
  customers: CustomerSearchResult[];
  total: number;
  query: string;
  has_more: boolean;
  pagination: {
    limit: number;
    offset: number;
    total_pages: number;
    current_page: number;
  };
}

interface ErrorResponse {
  error: string;
  message?: string;
  details?: any;
}

// Helper function to determine which fields matched the search
function getMatchingFields(customer: any, searchQuery: string): string[] {
  const matches: string[] = [];
  const query = searchQuery.toLowerCase();
  
  if (customer.name?.toLowerCase().includes(query)) {
    matches.push('name');
  }
  if (customer.contact_email?.toLowerCase().includes(query)) {
    matches.push('email');
  }
  if (customer.phone?.includes(query)) {
    matches.push('phone');
  }
  if (customer.cvr_nr?.includes(query)) {
    matches.push('cvr');
  }
  if (customer.address?.toLowerCase().includes(query)) {
    matches.push('address');
  }
  
  return matches;
}

// Helper function to format customer data for search results
function formatCustomerSearchResult(
  customer: any, 
  searchQuery: string, 
  includeProjects: boolean = false,
  includeStats: boolean = false
): CustomerSearchResult {
  const result: CustomerSearchResult = {
    customer_id: customer.customer_id,
    name: customer.name,
    contact_email: customer.contact_email,
    phone: customer.phone,
    address: customer.address,
    cvr_nr: customer.cvr_nr,
    created_at: customer.created_at,
    match_fields: getMatchingFields(customer, searchQuery),
  };

  if (includeStats && customer._count) {
    result.project_count = customer._count.Projects;
    result.hiring_request_count = customer._count.hiringRequests;
  }

  if (includeProjects && customer.Projects) {
    result.recent_projects = customer.Projects.slice(0, 3);
  }

  return result;
}

// GET /api/app/chef/customers/search - Search customers
export async function GET(request: NextRequest): Promise<NextResponse<SearchResponse | ErrorResponse>> {
  try {
    console.log("[Customers Search API] Search request received");
    
    const { searchParams } = new URL(request.url);
    
    // Extract and validate search parameters
    const rawParams = {
      q: searchParams.get("q"),
      limit: searchParams.get("limit"),
      offset: searchParams.get("offset"),
      include_projects: searchParams.get("include_projects"),
      include_stats: searchParams.get("include_stats"),
    };

    const validationResult = SearchParamsSchema.safeParse(rawParams);
    if (!validationResult.success) {
      console.log("[Customers Search API] Validation failed:", validationResult.error.errors);
      return NextResponse.json(
        { 
          error: "Invalid search parameters", 
          message: "Please check your search parameters",
          details: validationResult.error.errors 
        }, 
        { status: 400 }
      );
    }

    const { q: searchQuery, limit, offset, include_projects, include_stats } = validationResult.data;

    console.log(`[Customers Search API] Searching for: "${searchQuery}" with limit: ${limit}, offset: ${offset}`);

    // Build the search where clause
    const whereClause = {
      OR: [
        { name: { contains: searchQuery } },
        { contact_email: { contains: searchQuery } },
        { phone: { contains: searchQuery } },
        { cvr_nr: { contains: searchQuery } },
        { address: { contains: searchQuery } },
      ],
    };

    // Build include clause based on parameters
    const includeClause: any = {};
    
    if (include_stats) {
      includeClause._count = {
        select: {
          Projects: true,
          hiringRequests: true,
        },
      };
    }

    if (include_projects) {
      includeClause.Projects = {
        select: {
          project_id: true,
          title: true,
          status: true,
          start_date: true,
          created_at: true,
        },
        orderBy: { created_at: 'desc' },
        take: 5,
      };
    }

    // Execute search queries
    const [customers, totalCount] = await Promise.all([
      prisma.customers.findMany({
        where: whereClause,
        include: includeClause,
        orderBy: [
          { name: 'asc' }, // Primary sort by name for consistent results
          { created_at: 'desc' }, // Secondary sort by creation date
        ],
        take: limit,
        skip: offset,
      }),
      prisma.customers.count({
        where: whereClause,
      }),
    ]);

    // Format results
    const formattedCustomers = customers.map(customer => 
      formatCustomerSearchResult(customer, searchQuery, include_projects, include_stats)
    );

    // Calculate pagination info
    const totalPages = Math.ceil(totalCount / limit);
    const currentPage = Math.floor(offset / limit) + 1;
    const hasMore = offset + limit < totalCount;

    const response: SearchResponse = {
      customers: formattedCustomers,
      total: totalCount,
      query: searchQuery,
      has_more: hasMore,
      pagination: {
        limit,
        offset,
        total_pages: totalPages,
        current_page: currentPage,
      },
    };

    console.log(`[Customers Search API] Found ${formattedCustomers.length} customers out of ${totalCount} total matches`);
    
    return NextResponse.json(response, { status: 200 });
  } catch (error) {
    console.error("[Customers Search API] Search error:", error);
    return NextResponse.json(
      { 
        error: "Search failed", 
        message: "An error occurred while searching customers" 
      }, 
      { status: 500 }
    );
  }
}

// POST /api/app/chef/customers/search - Advanced search with body
export async function POST(request: NextRequest): Promise<NextResponse<SearchResponse | ErrorResponse>> {
  try {
    console.log("[Customers Search API] Advanced search request received");
    
    const body = await request.json();
    
    // Extended schema for POST search with more filters
    const AdvancedSearchSchema = z.object({
      query: z.string().min(1, "Search query is required").max(255, "Search query too long").optional(),
      filters: z.object({
        has_email: z.boolean().optional(),
        has_phone: z.boolean().optional(),
        has_cvr: z.boolean().optional(),
        has_address: z.boolean().optional(),
        has_projects: z.boolean().optional(),
        created_after: z.string().datetime().optional(),
        created_before: z.string().datetime().optional(),
        project_status: z.array(z.string()).optional(),
      }).optional(),
      sort: z.object({
        field: z.enum(['name', 'created_at', 'project_count']).optional().default('name'),
        direction: z.enum(['asc', 'desc']).optional().default('asc'),
      }).optional(),
      limit: z.number().min(1).max(100).optional().default(20),
      offset: z.number().min(0).optional().default(0),
      include_projects: z.boolean().optional().default(false),
      include_stats: z.boolean().optional().default(false),
    });

    const validationResult = AdvancedSearchSchema.safeParse(body);
    if (!validationResult.success) {
      return NextResponse.json(
        { 
          error: "Invalid search parameters", 
          message: "Please check your search parameters",
          details: validationResult.error.errors 
        }, 
        { status: 400 }
      );
    }

    const { query, filters, sort, limit, offset, include_projects, include_stats } = validationResult.data;

    // Build complex where clause
    const whereClause: any = { AND: [] };

    // Text search
    if (query) {
      whereClause.AND.push({
        OR: [
          { name: { contains: query } },
          { contact_email: { contains: query } },
          { phone: { contains: query } },
          { cvr_nr: { contains: query } },
          { address: { contains: query } },
        ],
      });
    }

    // Apply filters
    if (filters) {
      if (filters.has_email !== undefined) {
        whereClause.AND.push({
          contact_email: filters.has_email ? { not: null } : null,
        });
      }

      if (filters.has_phone !== undefined) {
        whereClause.AND.push({
          phone: filters.has_phone ? { not: null } : null,
        });
      }

      if (filters.has_cvr !== undefined) {
        whereClause.AND.push({
          cvr_nr: filters.has_cvr ? { not: null } : null,
        });
      }

      if (filters.has_address !== undefined) {
        whereClause.AND.push({
          address: filters.has_address ? { not: null } : null,
        });
      }

      if (filters.created_after) {
        whereClause.AND.push({
          created_at: { gte: new Date(filters.created_after) },
        });
      }

      if (filters.created_before) {
        whereClause.AND.push({
          created_at: { lte: new Date(filters.created_before) },
        });
      }

      if (filters.has_projects !== undefined) {
        whereClause.AND.push({
          Projects: filters.has_projects ? { some: {} } : { none: {} },
        });
      }
    }

    // Build include clause
    const includeClause: any = {};
    
    if (include_stats) {
      includeClause._count = {
        select: {
          Projects: true,
          hiringRequests: true,
        },
      };
    }

    if (include_projects) {
      includeClause.Projects = {
        select: {
          project_id: true,
          title: true,
          status: true,
          start_date: true,
          created_at: true,
        },
        orderBy: { created_at: 'desc' },
        take: 5,
      };
    }

    // Build order by clause
    let orderBy: any = { name: 'asc' };
    if (sort) {
      if (sort.field === 'created_at') {
        orderBy = { created_at: sort.direction };
      } else if (sort.field === 'name') {
        orderBy = { name: sort.direction };
      }
      // Note: project_count sorting would require a more complex query
    }

    // Execute search
    const [customers, totalCount] = await Promise.all([
      prisma.customers.findMany({
        where: whereClause.AND.length > 0 ? whereClause : undefined,
        include: includeClause,
        orderBy,
        take: limit,
        skip: offset,
      }),
      prisma.customers.count({
        where: whereClause.AND.length > 0 ? whereClause : undefined,
      }),
    ]);

    // Format results
    const formattedCustomers = customers.map(customer => 
      formatCustomerSearchResult(customer, query || '', include_projects, include_stats)
    );

    // Calculate pagination info
    const totalPages = Math.ceil(totalCount / limit);
    const currentPage = Math.floor(offset / limit) + 1;
    const hasMore = offset + limit < totalCount;

    const response: SearchResponse = {
      customers: formattedCustomers,
      total: totalCount,
      query: query || '',
      has_more: hasMore,
      pagination: {
        limit,
        offset,
        total_pages: totalPages,
        current_page: currentPage,
      },
    };

    console.log(`[Customers Search API] Advanced search found ${formattedCustomers.length} customers out of ${totalCount} total matches`);
    
    return NextResponse.json(response, { status: 200 });
  } catch (error) {
    console.error("[Customers Search API] Advanced search error:", error);
    return NextResponse.json(
      { 
        error: "Advanced search failed", 
        message: "An error occurred while performing advanced search" 
      }, 
      { status: 500 }
    );
  }
}