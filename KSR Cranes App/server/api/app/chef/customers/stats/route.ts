// src/app/api/app/chef/customers/stats/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// Response types
interface CustomerStats {
  total_customers: number;
  new_this_month: number;
  new_this_week: number;
  new_today: number;
  customers_with_projects: number;
  customers_without_projects: number;
  customers_with_active_projects: number;
  customers_with_email: number;
  customers_with_phone: number;
  customers_with_cvr: number;
  customers_with_address: number;
  total_projects: number;
  total_hiring_requests: number;
  average_projects_per_customer: number;
  top_customers_by_projects: TopCustomer[];
  recent_customers: RecentCustomer[];
  monthly_growth: MonthlyGrowth[];
}

interface TopCustomer {
  customer_id: number;
  name: string;
  project_count: number;
  hiring_request_count: number;
  latest_project_date: Date | null;
}

interface RecentCustomer {
  customer_id: number;
  name: string;
  contact_email: string | null;
  created_at: Date | null;
  days_since_created: number;
}

interface MonthlyGrowth {
  month: string;
  year: number;
  customer_count: number;
  cumulative_count: number;
}

interface ErrorResponse {
  error: string;
  message?: string;
}

// Helper function to get date ranges
function getDateRanges() {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay()); // Start of week (Sunday)
  startOfWeek.setHours(0, 0, 0, 0);
  
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const startOfYear = new Date(now.getFullYear(), 0, 1);
  
  return {
    startOfToday,
    startOfWeek,
    startOfMonth,
    startOfYear,
  };
}

// Helper function to calculate days since creation
function calculateDaysSince(date: Date | null): number {
  if (!date) return 0;
  const now = new Date();
  const diffTime = Math.abs(now.getTime() - date.getTime());
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
}

// GET /api/app/chef/customers/stats - Get customer statistics
export async function GET(request: NextRequest): Promise<NextResponse<CustomerStats | ErrorResponse>> {
  try {
    console.log("[Customers Stats API] Stats request received");
    
    const { searchParams } = new URL(request.url);
    const includeMonthlyGrowth = searchParams.get("include_monthly_growth") === "true";
    const topCustomersLimit = parseInt(searchParams.get("top_customers_limit") || "10");
    const recentCustomersLimit = parseInt(searchParams.get("recent_customers_limit") || "10");

    const dateRanges = getDateRanges();

    // Execute all queries in parallel for better performance
    const [
      totalCustomers,
      newThisMonth,
      newThisWeek, 
      newToday,
      customersWithProjects,
      customersWithActiveProjects,
      customersWithEmail,
      customersWithPhone,
      customersWithCvr,
      customersWithAddress,
      totalProjects,
      totalHiringRequests,
      topCustomersByProjects,
      recentCustomers,
    ] = await Promise.all([
      // Total customers
      prisma.customers.count(),

      // New customers this month
      prisma.customers.count({
        where: {
          created_at: {
            gte: dateRanges.startOfMonth,
          },
        },
      }),

      // New customers this week
      prisma.customers.count({
        where: {
          created_at: {
            gte: dateRanges.startOfWeek,
          },
        },
      }),

      // New customers today
      prisma.customers.count({
        where: {
          created_at: {
            gte: dateRanges.startOfToday,
          },
        },
      }),

      // Customers with projects
      prisma.customers.count({
        where: {
          Projects: {
            some: {},
          },
        },
      }),

      // Customers with active projects
      prisma.customers.count({
        where: {
          Projects: {
            some: {
              status: 'aktiv',
            },
          },
        },
      }),

      // Customers with email
      prisma.customers.count({
        where: {
          contact_email: {
            not: null,
          },
        },
      }),

      // Customers with phone
      prisma.customers.count({
        where: {
          phone: {
            not: null,
          },
        },
      }),

      // Customers with CVR
      prisma.customers.count({
        where: {
          cvr_nr: {
            not: null,
          },
        },
      }),

      // Customers with address
      prisma.customers.count({
        where: {
          address: {
            not: null,
          },
        },
      }),

      // Total projects count
      prisma.projects.count(),

      // Total hiring requests count
      prisma.operatorHiringRequest.count(),

      // Top customers by project count
      prisma.customers.findMany({
        include: {
          _count: {
            select: {
              Projects: true,
              hiringRequests: true,
            },
          },
          Projects: {
            select: {
              created_at: true,
            },
            orderBy: {
              created_at: 'desc',
            },
            take: 1,
          },
        },
        orderBy: {
          Projects: {
            _count: 'desc',
          },
        },
        take: topCustomersLimit,
      }),

      // Recent customers
      prisma.customers.findMany({
        select: {
          customer_id: true,
          name: true,
          contact_email: true,
          created_at: true,
        },
        orderBy: {
          created_at: 'desc',
        },
        take: recentCustomersLimit,
      }),
    ]);

    // Calculate derived statistics
    const customersWithoutProjects = totalCustomers - customersWithProjects;
    const averageProjectsPerCustomer = totalCustomers > 0 ? totalProjects / totalCustomers : 0;

    // Format top customers
    const formattedTopCustomers: TopCustomer[] = topCustomersByProjects.map(customer => ({
      customer_id: customer.customer_id,
      name: customer.name,
      project_count: customer._count.Projects,
      hiring_request_count: customer._count.hiringRequests,
      latest_project_date: customer.Projects[0]?.created_at || null,
    }));

    // Format recent customers
    const formattedRecentCustomers: RecentCustomer[] = recentCustomers.map(customer => ({
      customer_id: customer.customer_id,
      name: customer.name,
      contact_email: customer.contact_email,
      created_at: customer.created_at,
      days_since_created: calculateDaysSince(customer.created_at),
    }));

    // Monthly growth data (optional)
    let monthlyGrowth: MonthlyGrowth[] = [];
    if (includeMonthlyGrowth) {
      const monthlyData = await prisma.$queryRaw<any[]>`
        SELECT 
          YEAR(created_at) as year,
          MONTH(created_at) as month,
          COUNT(*) as customer_count
        FROM Customers 
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
        GROUP BY YEAR(created_at), MONTH(created_at)
        ORDER BY year, month
      `;

      let cumulativeCount = 0;
      monthlyGrowth = monthlyData.map(row => {
        cumulativeCount += Number(row.customer_count);
        const monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        
        return {
          month: monthNames[row.month - 1],
          year: Number(row.year),
          customer_count: Number(row.customer_count),
          cumulative_count: cumulativeCount,
        };
      });
    }

    // Build response
    const stats: CustomerStats = {
      total_customers: totalCustomers,
      new_this_month: newThisMonth,
      new_this_week: newThisWeek,
      new_today: newToday,
      customers_with_projects: customersWithProjects,
      customers_without_projects: customersWithoutProjects,
      customers_with_active_projects: customersWithActiveProjects,
      customers_with_email: customersWithEmail,
      customers_with_phone: customersWithPhone,
      customers_with_cvr: customersWithCvr,
      customers_with_address: customersWithAddress,
      total_projects: totalProjects,
      total_hiring_requests: totalHiringRequests,
      average_projects_per_customer: Math.round(averageProjectsPerCustomer * 100) / 100,
      top_customers_by_projects: formattedTopCustomers,
      recent_customers: formattedRecentCustomers,
      monthly_growth: monthlyGrowth,
    };

    console.log(`[Customers Stats API] Stats generated successfully - Total customers: ${totalCustomers}`);
    
    return NextResponse.json(stats, { status: 200 });
  } catch (error) {
    console.error("[Customers Stats API] Stats error:", error);
    return NextResponse.json(
      { 
        error: "Failed to generate stats", 
        message: "An error occurred while generating customer statistics" 
      }, 
      { status: 500 }
    );
  }
}