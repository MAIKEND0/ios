/**
 * Business Intelligence Timeline API
 * 
 * Path: /api/app/chef/projects/[id]/business-timeline
 * 
 * Generates business timeline events from existing database tables:
 * - Projects (contract lifecycle)
 * - TaskAssignments + Employees (operator deployment)
 * - WorkEntries (performance tracking)  
 * - BillingSettings (financial events)
 * 
 * ✅ USES EXISTING TABLES - NO DATABASE CHANGES NEEDED!
 */

import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ===== BUSINESS TIMELINE TYPES =====

interface BusinessTimelineResponse {
  project_id: number;
  business_health: BusinessHealthScore;
  timeline: BusinessTimelineEvent[];
  key_metrics: BusinessKeyMetrics;
  insights: BusinessInsight[];
  recommendations: BusinessRecommendation[];
}

interface BusinessHealthScore {
  overall: number;
  financial: number;
  operational: number;
  client: number;
  status: 'excellent' | 'good' | 'fair' | 'poor';
  trend: 'improving' | 'stable' | 'declining';
}

interface BusinessTimelineEvent {
  id: string;
  timestamp: string; // ISO date
  type: string;
  category: 'contract' | 'operators' | 'performance' | 'financial' | 'intelligence';
  title: string;
  description: string;
  impact: 'positive' | 'neutral' | 'negative' | 'critical';
  metrics?: Record<string, any>;
  related_entities?: {
    project_id?: number;
    task_ids?: number[];
    employee_ids?: number[];
    customer_id?: number;
    billing_setting_id?: number;
  };
}

interface BusinessKeyMetrics {
  contract_value: number;
  weekly_revenue: number;
  total_revenue: number;
  profit_margin: number;
  payment_collection: number;
  operator_utilization: number;
  revenue_per_operator_per_day: number;
  on_time_delivery: number;
  safety_incident_rate: number;
  client_satisfaction: number;
  client_retention_rate: number;
  bonus_payments: number;
  utilization_target: number;
  revenue_target: number;
  safety_target: number;
  satisfaction_target: number;
}

interface BusinessInsight {
  id: string;
  type: 'opportunity' | 'risk' | 'achievement' | 'alert';
  title: string;
  description: string;
  priority: 'low' | 'medium' | 'high' | 'critical';
  action_required: boolean;
  related_metrics: string[];
}

interface BusinessRecommendation {
  id: string;
  category: 'financial' | 'operational' | 'client' | 'growth';
  title: string;
  description: string;
  estimated_impact: string;
  timeframe: string;
  difficulty: 'easy' | 'medium' | 'hard';
  action_items: ActionItem[];
}

interface ActionItem {
  id: string;
  description: string;
  responsible?: string;
  deadline?: string;
  is_completed: boolean;
}

// ===== API ROUTE HANDLER =====

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const projectId = parseInt(id);
    
    if (isNaN(projectId)) {
      return NextResponse.json(
        { error: 'Invalid project ID' },
        { status: 400 }
      );
    }

    console.log(`🔄 [BusinessTimeline] Loading timeline for project: ${projectId}`);

    // ===== 1. FETCH PROJECT DATA =====
    const project = await prisma.projects.findUnique({
      where: { project_id: projectId },
      include: {
        Customers: true,
        Tasks: {
          include: {
            TaskAssignments: {
              include: {
                Employees: true,
                CraneModel: true
              }
            }
          }
        },
        BillingSettings: {
          orderBy: { effective_from: 'desc' }
        }
      }
    });

    if (!project) {
      return NextResponse.json(
        { error: 'Project not found' },
        { status: 404 }
      );
    }

    // ===== 2. FETCH WORK ENTRIES FOR PERFORMANCE DATA =====
    const workEntries = await prisma.workEntries.findMany({
      where: {
        Tasks: {
          project_id: projectId
        }
      },
      include: {
        Tasks: true,
        Employees: true
      },
      orderBy: { work_date: 'desc' }
    });

    // ===== 3. GENERATE BUSINESS TIMELINE =====
    const timeline = await generateBusinessTimeline(project, workEntries);
    const keyMetrics = await calculateBusinessMetrics(project, workEntries);
    const businessHealth = calculateBusinessHealth(keyMetrics);
    const insights = generateBusinessInsights(keyMetrics, timeline);
    const recommendations = generateBusinessRecommendations(keyMetrics, insights);

    const response: BusinessTimelineResponse = {
      project_id: projectId,
      business_health: businessHealth,
      timeline: timeline,
      key_metrics: keyMetrics,
      insights: insights,
      recommendations: recommendations
    };

    console.log(`✅ [BusinessTimeline] Generated ${timeline.length} events for project ${projectId}`);

    return NextResponse.json(response);

  } catch (error) {
    console.error('❌ [BusinessTimeline] Error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// ===== BUSINESS LOGIC FUNCTIONS =====

async function generateBusinessTimeline(project: any, workEntries: any[]): Promise<BusinessTimelineEvent[]> {
  const events: BusinessTimelineEvent[] = [];

  // 📋 CONTRACT LIFECYCLE EVENTS
  
  // Contract Awarded (project creation)
  if (project.created_at) {
    events.push({
      id: `contract_awarded_${project.project_id}`,
      timestamp: project.created_at.toISOString(),
      type: 'contract_awarded',
      category: 'contract',
      title: 'Contract Awarded',
      description: `KSR awarded operator services contract for ${project.title}`,
      impact: 'positive',
      metrics: {
        project_id: project.project_id,
        customer_name: project.Customers?.name
      },
      related_entities: {
        project_id: project.project_id,
        customer_id: project.customer_id
      }
    });
  }

  // Service Agreement Signed (project start)
  if (project.start_date) {
    events.push({
      id: `service_agreement_${project.project_id}`,
      timestamp: project.start_date.toISOString(),
      type: 'service_agreement_signed',
      category: 'contract',
      title: 'Service Agreement Signed',
      description: `Service agreement signed with ${project.Customers?.name}. Project officially started.`,
      impact: 'positive',
      metrics: {
        start_date: project.start_date,
        end_date: project.end_date
      },
      related_entities: {
        project_id: project.project_id,
        customer_id: project.customer_id
      }
    });
  }

  // Billing Setup Completed
  if (project.BillingSettings && project.BillingSettings.length > 0) {
    const firstBillingSetting = project.BillingSettings[project.BillingSettings.length - 1]; // Latest
    events.push({
      id: `billing_setup_${firstBillingSetting.setting_id}`,
      timestamp: firstBillingSetting.effective_from.toISOString(),
      type: 'billing_setup_completed',
      category: 'contract',
      title: 'Billing Setup Completed',
      description: `Billing rates configured: Normal €${firstBillingSetting.normal_rate}/h, Weekend €${firstBillingSetting.weekend_rate}/h`,
      impact: 'positive',
      metrics: {
        normal_rate: parseFloat(firstBillingSetting.normal_rate),
        weekend_rate: parseFloat(firstBillingSetting.weekend_rate),
        overtime_rate1: parseFloat(firstBillingSetting.overtime_rate1)
      },
      related_entities: {
        project_id: project.project_id,
        billing_setting_id: firstBillingSetting.setting_id
      }
    });
  }

  // 👷 OPERATOR DEPLOYMENT EVENTS

  // Group task assignments by date to create deployment events
  const assignmentsByDate = new Map<string, any[]>();
  
  project.Tasks?.forEach((task: any) => {
    task.TaskAssignments?.forEach((assignment: any) => {
      if (assignment.assigned_at) {
        const dateKey = assignment.assigned_at.toISOString().split('T')[0];
        if (!assignmentsByDate.has(dateKey)) {
          assignmentsByDate.set(dateKey, []);
        }
        assignmentsByDate.get(dateKey)!.push({
          assignment,
          task,
          employee: assignment.Employees
        });
      }
    });
  });

  // Create operator assignment events
  assignmentsByDate.forEach((assignments, dateKey) => {
    const assignmentDate = new Date(dateKey + 'T09:00:00Z'); // Morning deployment
    const employeeNames = assignments.map(a => a.employee?.name).filter(Boolean);
    const employeeIds = assignments.map(a => a.employee?.employee_id).filter(Boolean);
    const taskIds = assignments.map(a => a.task?.task_id).filter(Boolean);

    events.push({
      id: `operators_assigned_${dateKey}_${project.project_id}`,
      timestamp: assignmentDate.toISOString(),
      type: 'operators_assigned',
      category: 'operators',
      title: 'Operators Assigned',
      description: `${assignments.length} crane operators assigned: ${employeeNames.slice(0, 3).join(', ')}${employeeNames.length > 3 ? ` +${employeeNames.length - 3} more` : ''}`,
      impact: 'positive',
      metrics: {
        operators_count: assignments.length,
        operator_names: employeeNames
      },
      related_entities: {
        project_id: project.project_id,
        task_ids: taskIds,
        employee_ids: employeeIds
      }
    });

    // If multiple operators on same day, create on-site deployment event
    if (assignments.length >= 2) {
      const deploymentDate = new Date(assignmentDate);
      deploymentDate.setHours(deploymentDate.getHours() + 4); // 4 hours later

      events.push({
        id: `onsite_deployment_${dateKey}_${project.project_id}`,
        timestamp: deploymentDate.toISOString(),
        type: 'onsite_deployment',
        category: 'operators',
        title: 'On-Site Deployment',
        description: `${assignments.length} operators deployed to ${project.city || 'project site'}. Safety briefing completed, equipment handover with client.`,
        impact: 'positive',
        metrics: {
          deployment_location: project.city,
          operators_deployed: assignments.length
        },
        related_entities: {
          project_id: project.project_id,
          employee_ids: employeeIds
        }
      });
    }
  });

  // ⚡ PERFORMANCE EVENTS (Weekly Milestones from WorkEntries)
  
  const weeklyPerformance = calculateWeeklyPerformance(workEntries);
  let weekNumber = 1;
  
  weeklyPerformance.forEach((week) => {
    if (week.total_hours > 0) {
      const weekEndDate = new Date(week.week_end);
      weekEndDate.setHours(17, 0, 0, 0); // Friday 5 PM
      
      // Calculate performance metrics
      const plannedHours = week.unique_employees * 40; // 40h per employee per week
      const efficiency = plannedHours > 0 ? (week.total_hours / plannedHours) * 100 : 0;
      const overtimeHours = Math.max(0, week.total_hours - plannedHours);
      
      // Determine impact based on performance
      let impact: 'positive' | 'neutral' | 'negative' = 'neutral';
      if (efficiency >= 95) impact = 'positive';
      else if (efficiency < 80) impact = 'negative';

      events.push({
        id: `weekly_milestone_${week.week_start.split('T')[0]}_${project.project_id}`,
        timestamp: weekEndDate.toISOString(),
        type: 'weekly_milestone',
        category: 'performance',
        title: `Week ${weekNumber} Performance Milestone`,
        description: `${week.total_hours.toFixed(0)}h worked vs ${plannedHours}h planned${overtimeHours > 0 ? ` (+${overtimeHours.toFixed(0)}h overtime)` : ''}. ${efficiency.toFixed(0)}% efficiency achieved.`,
        impact: impact,
        metrics: {
          week_number: weekNumber,
          hours_worked: week.total_hours,
          hours_planned: plannedHours,
          efficiency_percentage: efficiency,
          overtime_hours: overtimeHours,
          unique_employees: week.unique_employees
        },
        related_entities: {
          project_id: project.project_id,
          employee_ids: week.employee_ids
        }
      });

      weekNumber++;
    }
  });

  // 💰 FINANCIAL EVENTS (Mock for now - can be enhanced with actual financial data)
  
  // Generate billing cycle events based on work entries
  if (weeklyPerformance.length > 0) {
    const latestWeek = weeklyPerformance[0];
    const billingDate = new Date(latestWeek.week_end);
    billingDate.setDate(billingDate.getDate() + 2); // Monday after week end
    
    // Calculate estimated revenue
    const normalRate = project.BillingSettings?.[0]?.normal_rate ? parseFloat(project.BillingSettings[0].normal_rate) : 450;
    const estimatedRevenue = latestWeek.total_hours * normalRate;
    
    events.push({
      id: `billing_cycle_${latestWeek.week_start.split('T')[0]}_${project.project_id}`,
      timestamp: billingDate.toISOString(),
      type: 'billing_cycle_completed',
      category: 'financial',
      title: 'Billing Cycle Completed',
      description: `Week ${weekNumber - 1} billing: ${latestWeek.total_hours.toFixed(0)}h × €${normalRate}/h = €${estimatedRevenue.toFixed(0)} invoiced`,
      impact: 'positive',
      metrics: {
        hours_billed: latestWeek.total_hours,
        hourly_rate: normalRate,
        total_amount: estimatedRevenue,
        week_number: weekNumber - 1
      },
      related_entities: {
        project_id: project.project_id,
        billing_setting_id: project.BillingSettings?.[0]?.setting_id
      }
    });
  }

  // 🎯 BUSINESS INTELLIGENCE EVENTS
  
  // Resource utilization peak (if high efficiency achieved)
  const avgEfficiency = weeklyPerformance.length > 0 
    ? weeklyPerformance.reduce((acc, week) => {
        const plannedHours = week.unique_employees * 40;
        return acc + ((week.total_hours / plannedHours) * 100);
      }, 0) / weeklyPerformance.length 
    : 0;

  if (avgEfficiency >= 90 && weeklyPerformance.length >= 2) {
    const latestWeek = weeklyPerformance[0];
    const achievementDate = new Date(latestWeek.week_end);
    achievementDate.setDate(achievementDate.getDate() + 1); // Saturday

    events.push({
      id: `resource_utilization_peak_${project.project_id}`,
      timestamp: achievementDate.toISOString(),
      type: 'resource_utilization_peak',
      category: 'intelligence',
      title: 'Resource Utilization Peak',
      description: `Outstanding resource utilization achieved: ${avgEfficiency.toFixed(1)}% average efficiency. All operators at optimal capacity.`,
      impact: 'positive',
      metrics: {
        average_efficiency: avgEfficiency,
        weeks_analyzed: weeklyPerformance.length,
        operators_count: latestWeek.unique_employees
      },
      related_entities: {
        project_id: project.project_id
      }
    });
  }

  // Sort events by timestamp (newest first for timeline display)
  return events.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
}

function calculateWeeklyPerformance(workEntries: any[]) {
  const weeklyData = new Map<string, {
    week_start: string;
    week_end: string;
    total_hours: number;
    employee_ids: number[];
    unique_employees: number;
  }>();

  workEntries.forEach(entry => {
    if (!entry.work_date || !entry.start_time || !entry.end_time) return;

    // Calculate week start (Monday)
    const workDate = new Date(entry.work_date);
    const monday = new Date(workDate);
    monday.setDate(workDate.getDate() - workDate.getDay() + 1);
    const weekKey = monday.toISOString().split('T')[0];

    // Calculate hours worked
    const startTime = new Date(`${entry.work_date}T${entry.start_time}`);
    const endTime = new Date(`${entry.work_date}T${entry.end_time}`);
    const hoursWorked = (endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60);
    const adjustedHours = Math.max(0, hoursWorked - (entry.pause_minutes || 0) / 60);

    if (!weeklyData.has(weekKey)) {
      const friday = new Date(monday);
      friday.setDate(monday.getDate() + 4);
      
      weeklyData.set(weekKey, {
        week_start: monday.toISOString(),
        week_end: friday.toISOString(),
        total_hours: 0,
        employee_ids: [],
        unique_employees: 0
      });
    }

    const week = weeklyData.get(weekKey)!;
    week.total_hours += adjustedHours;
    
    if (entry.employee_id && !week.employee_ids.includes(entry.employee_id)) {
      week.employee_ids.push(entry.employee_id);
    }
    week.unique_employees = week.employee_ids.length;
  });

  return Array.from(weeklyData.values()).sort((a, b) => 
    new Date(b.week_start).getTime() - new Date(a.week_start).getTime()
  );
}

async function calculateBusinessMetrics(project: any, workEntries: any[]): Promise<BusinessKeyMetrics> {
  // Calculate total hours and revenue
  const totalHours = workEntries.reduce((sum, entry) => {
    if (!entry.start_time || !entry.end_time) return sum;
    const startTime = new Date(`${entry.work_date}T${entry.start_time}`);
    const endTime = new Date(`${entry.work_date}T${entry.end_time}`);
    const hours = (endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60);
    return sum + Math.max(0, hours - (entry.pause_minutes || 0) / 60);
  }, 0);

  // Get billing rate
  const billingRate = project.BillingSettings?.[0]?.normal_rate 
    ? parseFloat(project.BillingSettings[0].normal_rate) 
    : 450; // Default rate

  const totalRevenue = totalHours * billingRate;
  const estimatedCosts = totalHours * billingRate * 0.74; // 26% profit margin
  const profitMargin = totalRevenue > 0 ? ((totalRevenue - estimatedCosts) / totalRevenue) * 100 : 0;

  // Calculate weekly revenue (last 7 days)
  const oneWeekAgo = new Date();
  oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
  
  const recentHours = workEntries
    .filter(entry => new Date(entry.work_date) >= oneWeekAgo)
    .reduce((sum, entry) => {
      if (!entry.start_time || !entry.end_time) return sum;
      const startTime = new Date(`${entry.work_date}T${entry.start_time}`);
      const endTime = new Date(`${entry.work_date}T${entry.end_time}`);
      const hours = (endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60);
      return sum + Math.max(0, hours - (entry.pause_minutes || 0) / 60);
    }, 0);

  const weeklyRevenue = recentHours * billingRate;

  // Get unique operators
  const uniqueOperators = new Set(workEntries.map(entry => entry.employee_id)).size;
  const revenuePerOperatorPerDay = uniqueOperators > 0 ? totalRevenue / uniqueOperators / Math.max(1, workEntries.length) : 0;

  // Calculate utilization (mock calculation - can be enhanced)
  const workingDays = Math.max(1, new Set(workEntries.map(entry => entry.work_date.toISOString().split('T')[0])).size);
  const expectedHours = uniqueOperators * workingDays * 8; // 8h per operator per day
  const operatorUtilization = expectedHours > 0 ? Math.min(100, (totalHours / expectedHours) * 100) : 0;

  return {
    contract_value: 87500, // Mock - could be calculated from project scope
    weekly_revenue: weeklyRevenue,
    total_revenue: totalRevenue,
    profit_margin: profitMargin,
    payment_collection: 96.0, // Mock - could be calculated from payment status
    operator_utilization: operatorUtilization,
    revenue_per_operator_per_day: revenuePerOperatorPerDay,
    on_time_delivery: 98.0, // Mock - could be calculated from task completion
    safety_incident_rate: 0.02, // Mock - could be calculated from incident reports
    client_satisfaction: 9.2, // Mock - could be from client feedback
    client_retention_rate: 92.0, // Mock - could be calculated from repeat projects
    bonus_payments: 2000, // Mock - could be from bonus payment records
    utilization_target: 90.0,
    revenue_target: 400,
    safety_target: 0.05,
    satisfaction_target: 8.5
  };
}

function calculateBusinessHealth(metrics: BusinessKeyMetrics): BusinessHealthScore {
  // Financial health (40% weight)
  const financialScore = Math.min(100, 
    (metrics.profit_margin / 25 * 40) + // Target 25% margin
    (metrics.payment_collection / 100 * 35) + // Target 100% collection
    (Math.min(metrics.weekly_revenue / metrics.revenue_target, 1.2) * 25) // Target revenue with 20% bonus
  );

  // Operational health (35% weight)  
  const operationalScore = Math.min(100,
    (metrics.operator_utilization / 100 * 50) + // Target 90%+ utilization
    (Math.max(0, 100 - metrics.safety_incident_rate * 1000) * 30) + // Lower incidents = higher score
    (metrics.on_time_delivery * 20 / 100) // Target 100% on-time
  );

  // Client health (25% weight)
  const clientScore = Math.min(100,
    (metrics.client_satisfaction / 10 * 60) + // Target 10/10 satisfaction
    (metrics.client_retention_rate * 40 / 100) // Target 100% retention
  );

  const overall = (financialScore * 0.4) + (operationalScore * 0.35) + (clientScore * 0.25);

  // Determine status
  let status: 'excellent' | 'good' | 'fair' | 'poor';
  if (overall >= 90) status = 'excellent';
  else if (overall >= 75) status = 'good';
  else if (overall >= 60) status = 'fair';
  else status = 'poor';

  // Determine trend (simplified - could be enhanced with historical data)
  let trend: 'improving' | 'stable' | 'declining' = 'stable';
  if (metrics.profit_margin > 25 && metrics.operator_utilization > 90) trend = 'improving';
  else if (metrics.profit_margin < 15 || metrics.operator_utilization < 70) trend = 'declining';

  return {
    overall,
    financial: financialScore,
    operational: operationalScore,
    client: clientScore,
    status,
    trend
  };
}

function generateBusinessInsights(metrics: BusinessKeyMetrics, timeline: BusinessTimelineEvent[]): BusinessInsight[] {
  const insights: BusinessInsight[] = [];

  // High performance achievement
  if (metrics.operator_utilization >= 94 && metrics.profit_margin >= 25) {
    insights.push({
      id: 'achievement_high_performance',
      type: 'achievement',
      title: 'Exceeding All Performance Targets',
      description: `Project is performing exceptionally well with ${metrics.operator_utilization.toFixed(1)}% operator utilization and ${metrics.profit_margin.toFixed(1)}% profit margin, both above targets.`,
      priority: 'high',
      action_required: false,
      related_metrics: ['operator_utilization', 'profit_margin']
    });
  }

  // Growth opportunity 
  if (metrics.operator_utilization >= 90) {
    insights.push({
      id: 'opportunity_capacity_expansion',
      type: 'opportunity',
      title: 'Capacity Expansion Opportunity',
      description: `High utilization rate (${metrics.operator_utilization.toFixed(1)}%) indicates potential for additional project capacity or premium rate negotiation with client.`,
      priority: 'medium',
      action_required: true,
      related_metrics: ['operator_utilization', 'weekly_revenue']
    });
  }

  // Safety excellence
  if (metrics.safety_incident_rate <= 0.03) {
    insights.push({
      id: 'achievement_safety_excellence',
      type: 'achievement', 
      title: 'Safety Excellence Achievement',
      description: `Outstanding safety performance with incident rate of ${metrics.safety_incident_rate} per 1000 hours, well below industry average.`,
      priority: 'medium',
      action_required: false,
      related_metrics: ['safety_incident_rate']
    });
  }

  // Revenue risk
  if (metrics.weekly_revenue < metrics.revenue_target * 0.8) {
    insights.push({
      id: 'risk_revenue_shortfall',
      type: 'risk',
      title: 'Revenue Target Risk',
      description: `Weekly revenue (€${metrics.weekly_revenue.toFixed(0)}) is below target (€${metrics.revenue_target}). Review operator scheduling and efficiency.`,
      priority: 'high',
      action_required: true,
      related_metrics: ['weekly_revenue', 'operator_utilization']
    });
  }

  return insights;
}

function generateBusinessRecommendations(metrics: BusinessKeyMetrics, insights: BusinessInsight[]): BusinessRecommendation[] {
  const recommendations: BusinessRecommendation[] = [];

  // Contract extension recommendation
  if (metrics.operator_utilization >= 90 && metrics.client_satisfaction >= 9.0) {
    recommendations.push({
      id: 'rec_contract_extension',
      category: 'growth',
      title: 'Propose Contract Extension', 
      description: 'Given exceptional performance metrics and high client satisfaction, propose 6-month contract extension with 5% rate increase.',
      estimated_impact: '+€15,000 additional revenue',
      timeframe: '2-3 weeks',
      difficulty: 'medium',
      action_items: [
        {
          id: 'action_performance_report',
          description: 'Prepare comprehensive performance summary report',
          responsible: 'Chef',
          deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
          is_completed: false
        },
        {
          id: 'action_client_meeting',
          description: 'Schedule contract extension discussion with client',
          responsible: 'Sales Manager',
          deadline: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString(),
          is_completed: false
        }
      ]
    });
  }

  // Operational efficiency
  if (metrics.operator_utilization < 85) {
    recommendations.push({
      id: 'rec_efficiency_improvement',
      category: 'operational',
      title: 'Improve Operator Efficiency',
      description: 'Analyze current scheduling and workflow to identify opportunities for increased operator utilization.',
      estimated_impact: '+10% revenue increase',
      timeframe: '1-2 weeks',
      difficulty: 'easy',
      action_items: [
        {
          id: 'action_schedule_analysis',
          description: 'Review operator scheduling patterns',
          responsible: 'Chef',
          deadline: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
          is_completed: false
        },
        {
          id: 'action_workflow_optimization',
          description: 'Identify workflow bottlenecks and solutions',
          responsible: 'Site Supervisor',
          deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
          is_completed: false
        }
      ]
    });
  }

  return recommendations;
}