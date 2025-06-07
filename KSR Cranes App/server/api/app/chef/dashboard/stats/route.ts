// src/app/api/app/chef/dashboard/stats/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// Explicit cache configuration for Next.js 15
export const dynamic = 'force-dynamic';

// Types matching iOS app expectations
interface DashboardOverview {
  total_customers: number;
  active_projects: number;
  pending_requests: number;
  monthly_revenue: number;
  growth_percentage: number;
  last_updated: string; // ISO date string
}

interface CustomerMetrics {
  total: number;
  new_this_month: number;
  new_this_week: number;
  active: number;
  inactive: number;
  top_customers: TopCustomer[];
}

interface TopCustomer {
  customer_id: number;
  name: string;
  project_count: number;
  total_revenue: number;
  last_project: string | null; // ISO date string
}

interface ProjectMetrics {
  total: number;
  active: number;
  completed: number;
  pending: number;
  on_hold: number;
  completion_rate: number;
  average_duration: number; // in days
  upcoming_deadlines: ProjectDeadline[];
}

interface ProjectDeadline {
  project_id: number;
  title: string;
  customer_name: string;
  deadline: string; // ISO date string
  days_remaining: number;
  status: string;
}

interface HiringRequestMetrics {
  total: number;
  pending: number;
  approved: number;
  rejected: number;
  fulfilled: number;
  avg_response_time: number; // in hours
  urgent_requests: number;
  recent_requests: RecentHiringRequest[];
}

interface RecentHiringRequest {
  request_id: number;
  customer_name: string;
  project_title: string;
  position: string;
  urgency: string;
  submitted_at: string; // ISO date string
  status: string;
}

interface RevenueMetrics {
  this_month: number;
  last_month: number;
  year_to_date: number;
  projected_monthly: number;
  growth_rate: number;
  top_revenue_streams: RevenueStream[];
  monthly_trend: MonthlyRevenue[];
}

interface RevenueStream {
  id: number;
  source: string;
  amount: number;
  percentage: number;
  trend: string;
}

interface MonthlyRevenue {
  month: string;
  year: number;
  revenue: number;
  project_count: number;
}

interface PerformanceMetrics {
  customer_satisfaction: number;
  on_time_delivery: number;
  resource_utilization: number;
  avg_project_duration: number;
  repeat_customer_rate: number;
  operational_efficiency: number;
}

interface RecentActivity {
  id: number;
  type: string;
  title: string;
  description: string;
  timestamp: string; // ISO date string
  related_entity: string | null;
  related_entity_id: number | null;
  importance: string;
}

interface UpcomingTask {
  id: number;
  title: string;
  description: string;
  due_date: string; // ISO date string
  priority: string;
  assigned_to: string | null;
  related_project: string | null;
  related_customer: string | null;
  completed: boolean;
}

interface ChefDashboardStats {
  overview: DashboardOverview;
  customers: CustomerMetrics;
  projects: ProjectMetrics;
  hiring_requests: HiringRequestMetrics;
  revenue: RevenueMetrics;
  performance: PerformanceMetrics;
  recent_activity: RecentActivity[];
  upcoming_tasks: UpcomingTask[];
}

interface ErrorResponse {
  error: string;
  message?: string;
  details?: any;
}

// Helper function to get date ranges
function getDateRanges() {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay());
  const startOfYear = new Date(now.getFullYear(), 0, 1);

  return {
    now,
    startOfMonth,
    startOfLastMonth,
    endOfLastMonth,
    startOfWeek,
    startOfYear
  };
}

// Helper function to calculate days between dates
function daysBetween(date1: Date, date2: Date): number {
  const diffTime = Math.abs(date2.getTime() - date1.getTime());
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
}

// GET /api/app/chef/dashboard/stats - Fetch dashboard statistics
export async function GET(request: NextRequest): Promise<NextResponse<ChefDashboardStats | ErrorResponse>> {
  try {
    console.log("[Dashboard API] GET request received");
    
    const dateRanges = getDateRanges();

    // Fetch all basic counts in parallel
    const [
      totalCustomers,
      newCustomersThisMonth,
      newCustomersThisWeek,
      totalProjects,
      activeProjects,
      completedProjects,
      pendingProjects,
      onHoldProjects,
      totalHiringRequests,
      pendingHiringRequests,
      approvedHiringRequests,
      rejectedHiringRequests,
      totalTasks,
      upcomingTasks
    ] = await Promise.all([
      // Customer counts
      prisma.customers.count(),
      prisma.customers.count({
        where: { created_at: { gte: dateRanges.startOfMonth } }
      }),
      prisma.customers.count({
        where: { created_at: { gte: dateRanges.startOfWeek } }
      }),
      
      // Project counts
      prisma.projects.count(),
      prisma.projects.count({
        where: { status: 'aktiv' }
      }),
      prisma.projects.count({
        where: { status: 'afsluttet' }
      }),
      prisma.projects.count({
        where: { status: 'afventer' }
      }),
      prisma.projects.count({
        where: { status: 'afsluttet' } // Using completed as "on hold" placeholder
      }),
      
      // Hiring request counts
      prisma.operatorHiringRequest.count(),
      prisma.operatorHiringRequest.count({
        where: { status: 'PENDING' }
      }),
      prisma.operatorHiringRequest.count({
        where: { status: 'APPROVED' }
      }),
      prisma.operatorHiringRequest.count({
        where: { status: 'REJECTED' }
      }),
      
      // Task counts
      prisma.tasks.count(),
      prisma.tasks.findMany({
        where: {
          deadline: { gte: dateRanges.now },
          isActive: true
        },
        include: {
          Projects: {
            include: {
              Customers: true
            }
          }
        },
        orderBy: { deadline: 'asc' },
        take: 10
      })
    ]);

    // Fetch top customers with project counts
    const topCustomersData = await prisma.customers.findMany({
      include: {
        _count: {
          select: {
            Projects: true,
            hiringRequests: true
          }
        },
        Projects: {
          orderBy: { created_at: 'desc' },
          take: 1,
          select: {
            created_at: true
          }
        }
      },
      orderBy: {
        Projects: {
          _count: 'desc'
        }
      },
      take: 5
    });

    // Fetch recent hiring requests
    const recentHiringRequests = await prisma.operatorHiringRequest.findMany({
      include: {
        customer: true
      },
      orderBy: { createdAt: 'desc' },
      take: 10
    });

    // Fetch upcoming project deadlines
    const upcomingProjectDeadlines = await prisma.projects.findMany({
      where: {
        end_date: { gte: dateRanges.now },
        status: 'aktiv'
      },
      include: {
        Customers: true
      },
      orderBy: { end_date: 'asc' },
      take: 5
    });

    // Calculate customer metrics
    const activeCustomers = await prisma.customers.count({
      where: {
        Projects: {
          some: {
            status: 'aktiv'
          }
        }
      }
    });

    const topCustomers: TopCustomer[] = topCustomersData.map(customer => ({
      customer_id: customer.customer_id,
      name: customer.name,
      project_count: customer._count.Projects,
      total_revenue: 50000 + Math.random() * 100000, // Mock revenue data
      last_project: customer.Projects[0]?.created_at?.toISOString() || null
    }));

    // Calculate project metrics
    const completionRate = totalProjects > 0 ? (completedProjects / totalProjects) * 100 : 0;
    
    // Calculate average project duration (mock calculation)
    const avgProjectDuration = 45; // Mock data - in real implementation, calculate from actual project data

    const projectDeadlines: ProjectDeadline[] = upcomingProjectDeadlines.map(project => ({
      project_id: project.project_id,
      title: project.title,
      customer_name: project.Customers?.name || 'Unknown Customer',
      deadline: project.end_date?.toISOString() || new Date().toISOString(),
      days_remaining: project.end_date ? daysBetween(dateRanges.now, project.end_date) : 0,
      status: project.status || 'unknown'
    }));

    // Calculate hiring request metrics
    const fulfilledHiringRequests = await prisma.operatorHiringRequest.count({
      where: { status: 'COMPLETED' }
    });

    const avgResponseTime = 4.2; // Mock data - calculate from actual status change history

    const urgentRequests = await prisma.operatorHiringRequest.count({
      where: {
        status: 'PENDING',
        startDate: { lte: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) } // Within 7 days
      }
    });

    const recentRequests: RecentHiringRequest[] = recentHiringRequests.slice(0, 5).map(request => ({
      request_id: request.id,
      customer_name: request.customer?.name || request.companyName || 'Unknown',
      project_title: request.projectName,
      position: request.serviceType,
      urgency: request.startDate <= new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) ? 'high' : 'normal',
      submitted_at: request.createdAt.toISOString(),
      status: request.status.toLowerCase()
    }));

    // Mock revenue data (in real implementation, calculate from actual billing data)
    const thisMonthRevenue = 145000 + Math.random() * 50000;
    const lastMonthRevenue = 128000 + Math.random() * 40000;
    const yearToDateRevenue = thisMonthRevenue * (dateRanges.now.getMonth() + 1);
    const growthRate = lastMonthRevenue > 0 ? ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100 : 0;

    const revenueStreams: RevenueStream[] = [
      {
        id: 1,
        source: "Crane Operations",
        amount: thisMonthRevenue * 0.6,
        percentage: 60,
        trend: "up"
      },
      {
        id: 2,
        source: "Equipment Rental",
        amount: thisMonthRevenue * 0.4,
        percentage: 40,
        trend: "stable"
      }
    ];

    // Mock recent activity
    const recentActivity: RecentActivity[] = [
      {
        id: 1,
        type: "project_completed",
        title: "Project Completed",
        description: "Construction project finished successfully",
        timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
        related_entity: "project",
        related_entity_id: activeProjects > 0 ? 1 : null,
        importance: "high"
      },
      {
        id: 2,
        type: "customer_added",
        title: "New Customer",
        description: "New customer registered in the system",
        timestamp: new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString(),
        related_entity: "customer",
        related_entity_id: totalCustomers > 0 ? 1 : null,
        importance: "medium"
      }
    ];

    // Format upcoming tasks
    const formattedUpcomingTasks: UpcomingTask[] = upcomingTasks.slice(0, 10).map((task, index) => ({
      id: task.task_id,
      title: task.title,
      description: task.description || "No description available",
      due_date: task.deadline?.toISOString() || new Date().toISOString(),
      priority: task.deadline && daysBetween(dateRanges.now, task.deadline) <= 3 ? "high" : "medium",
      assigned_to: task.supervisor_name || null,
      related_project: task.Projects?.title || null,
      related_customer: task.Projects?.Customers?.name || null,
      completed: false
    }));

    // Build dashboard stats response
    const dashboardStats: ChefDashboardStats = {
      overview: {
        total_customers: totalCustomers,
        active_projects: activeProjects,
        pending_requests: pendingHiringRequests,
        monthly_revenue: thisMonthRevenue,
        growth_percentage: growthRate,
        last_updated: dateRanges.now.toISOString()
      },
      customers: {
        total: totalCustomers,
        new_this_month: newCustomersThisMonth,
        new_this_week: newCustomersThisWeek,
        active: activeCustomers,
        inactive: totalCustomers - activeCustomers,
        top_customers: topCustomers
      },
      projects: {
        total: totalProjects,
        active: activeProjects,
        completed: completedProjects,
        pending: pendingProjects,
        on_hold: onHoldProjects,
        completion_rate: completionRate,
        average_duration: avgProjectDuration,
        upcoming_deadlines: projectDeadlines
      },
      hiring_requests: {
        total: totalHiringRequests,
        pending: pendingHiringRequests,
        approved: approvedHiringRequests,
        rejected: rejectedHiringRequests,
        fulfilled: fulfilledHiringRequests,
        avg_response_time: avgResponseTime,
        urgent_requests: urgentRequests,
        recent_requests: recentRequests
      },
      revenue: {
        this_month: thisMonthRevenue,
        last_month: lastMonthRevenue,
        year_to_date: yearToDateRevenue,
        projected_monthly: thisMonthRevenue * 1.1,
        growth_rate: growthRate,
        top_revenue_streams: revenueStreams,
        monthly_trend: [] // Empty for now, can be populated with historical data
      },
      performance: {
        customer_satisfaction: 4.8,
        on_time_delivery: 92.0,
        resource_utilization: 85.5,
        avg_project_duration: avgProjectDuration,
        repeat_customer_rate: 78.0,
        operational_efficiency: 88.5
      },
      recent_activity: recentActivity,
      upcoming_tasks: formattedUpcomingTasks
    };

    console.log(`[Dashboard API] Generated dashboard stats for ${totalCustomers} customers, ${totalProjects} projects`);
    
    return NextResponse.json(dashboardStats, { 
      status: 200,
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
      }
    });
  } catch (error) {
    console.error("[Dashboard API] GET error:", error);
    return NextResponse.json(
      { 
        error: "Failed to fetch dashboard statistics", 
        message: "An error occurred while fetching dashboard data" 
      }, 
      { status: 500 }
    );
  }
}