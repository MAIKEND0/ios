// src/app/api/app/chef/payroll/ready/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

// Define types for better TypeScript support
interface DailySummary {
  date: string;
  hours: number;
  km: number;
  entries_count: number;
}

interface EmployeeGroup {
  employee: any;
  total_hours: number;
  total_km: number;
  total_entries: number;
  work_entries: any[];
  daily_summary: Map<string, DailySummary>;
  projects: Set<string>;
  tasks: Set<string>;
}

/**
 * GET /api/app/chef/payroll/ready
 * Pobiera godziny zatwierdzone przez supervisorów, gotowe do wysłania do payroll
 */
export async function GET(request: NextRequest): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('start_date');
    const endDate = searchParams.get('end_date');
    const employeeId = searchParams.get('employee_id');
    const taskId = searchParams.get('task_id');
    const projectId = searchParams.get('project_id');

    console.log("🔍 [PAYROLL READY] Fetching confirmed work entries", {
      startDate, endDate, employeeId, taskId, projectId
    });

    // Build where clause - use only existing columns
    const where: any = {
      confirmation_status: 'confirmed',
      isActive: true,
      start_time: { not: null },
      end_time: { not: null },
    };

    // Add sent_to_payroll filter if column exists (check in try-catch)
    let hasSentToPayrollColumn = false;
    try {
      await prisma.$queryRaw`SELECT sent_to_payroll FROM WorkEntries LIMIT 1`;
      where.sent_to_payroll = false;
      hasSentToPayrollColumn = true;
      console.log("✅ [PAYROLL READY] sent_to_payroll column exists");
    } catch (error) {
      console.log("⚠️ [PAYROLL READY] sent_to_payroll column not found, skipping filter");
    }

    // Optional filters
    if (startDate && endDate) {
      where.work_date = {
        gte: new Date(startDate),
        lte: new Date(endDate)
      };
    }

    if (employeeId) {
      where.employee_id = parseInt(employeeId);
    }

    if (taskId) {
      where.task_id = parseInt(taskId);
    }

    if (projectId) {
      where.Tasks = {
        project_id: parseInt(projectId)
      };
    }

    // Build select object based on available columns
    const selectEmployees: any = {
      employee_id: true,
      name: true,
      email: true,
    };

    // Check if zenegy_employee_number exists
    try {
      await prisma.$queryRaw`SELECT zenegy_employee_number FROM Employees LIMIT 1`;
      selectEmployees.zenegy_employee_number = true;
    } catch (error) {
      console.log("⚠️ [PAYROLL READY] zenegy_employee_number column not found");
    }

    // Check if ZenegyEmployeeMapping table exists
    let includeZenegyMapping = false;
    try {
      await prisma.$queryRaw`SELECT COUNT(*) FROM ZenegyEmployeeMapping LIMIT 1`;
      includeZenegyMapping = true;
    } catch (error) {
      console.log("⚠️ [PAYROLL READY] ZenegyEmployeeMapping table not found");
    }

    if (includeZenegyMapping) {
      selectEmployees.ZenegyEmployeeMapping = {
        select: {
          zenegy_employee_id: true,
          zenegy_person_id: true,
          zenegy_employment_id: true,
          sync_enabled: true
        }
      };
    }

    // Fetch work entries with related data
    const workEntries = await prisma.workEntries.findMany({
      where,
      include: {
        Employees: {
          select: selectEmployees
        },
        Tasks: {
          include: {
            Projects: {
              select: {
                project_id: true,
                title: true,
                customer_id: true,
                Customers: {
                  select: {
                    customer_id: true,
                    name: true
                  }
                }
              }
            }
          }
        }
      },
      orderBy: [
        { employee_id: 'asc' },
        { work_date: 'asc' }
      ]
    });

    console.log(`📊 [PAYROLL READY] Found ${workEntries.length} confirmed work entries`);

    // Group by employees
    const employeeGroups = new Map<number, EmployeeGroup>();
    let totalHours = 0;
    let totalEntries = 0;

    for (const entry of workEntries) {
      const employeeId = entry.employee_id;
      
      if (!employeeGroups.has(employeeId)) {
        employeeGroups.set(employeeId, {
          employee: entry.Employees,
          total_hours: 0,
          total_km: 0,
          total_entries: 0,
          work_entries: [],
          daily_summary: new Map<string, DailySummary>(),
          projects: new Set<string>(),
          tasks: new Set<string>()
        });
      }

      const group = employeeGroups.get(employeeId)!;
      
      // Calculate hours for this entry
      const startTime = new Date(entry.start_time!);
      const endTime = new Date(entry.end_time!);
      const totalMinutes = (endTime.getTime() - startTime.getTime()) / (1000 * 60);
      const pauseMinutes = entry.pause_minutes || 0;
      const workedMinutes = Math.max(0, totalMinutes - pauseMinutes);
      const workedHours = workedMinutes / 60;

      group.total_hours += workedHours;
      group.total_km += parseFloat(entry.km?.toString() || '0');
      group.total_entries += 1;
      group.work_entries.push(entry);
      
      // Add to daily summary
      const dateKey = entry.work_date.toISOString().split('T')[0];
      if (!group.daily_summary.has(dateKey)) {
        group.daily_summary.set(dateKey, {
          date: dateKey,
          hours: 0,
          km: 0,
          entries_count: 0
        });
      }
      const dayData = group.daily_summary.get(dateKey)!;
      dayData.hours += workedHours;
      dayData.km += parseFloat(entry.km?.toString() || '0');
      dayData.entries_count += 1;

      // Collect projects and tasks
      group.projects.add(entry.Tasks.Projects?.title || 'Unknown Project');
      group.tasks.add(entry.Tasks.title || 'Unknown Task');

      totalHours += workedHours;
      totalEntries += 1;
    }

    // Convert to final structure with proper typing
    const employeesData = Array.from(employeeGroups.values()).map(group => {
      // Convert daily summary Map to Array with proper typing
      const dailyBreakdown = Array.from(group.daily_summary.entries()).map(([dateKey, dayData]) => ({
        date: dayData.date,
        hours: Math.round(dayData.hours * 100) / 100,
        km: Math.round(dayData.km * 100) / 100,
        entries_count: dayData.entries_count
      }));

      return {
        employee: group.employee,
        total_hours: Math.round(group.total_hours * 100) / 100,
        total_km: Math.round(group.total_km * 100) / 100,
        total_entries: group.total_entries,
        daily_breakdown: dailyBreakdown,
        projects: Array.from(group.projects),
        tasks: Array.from(group.tasks),
        work_entries: group.work_entries,
        zenegy_mapping: includeZenegyMapping ? group.employee.ZenegyEmployeeMapping : null,
        has_zenegy_mapping: includeZenegyMapping ? !!group.employee.ZenegyEmployeeMapping?.zenegy_employee_id : false,
        can_sync_to_zenegy: includeZenegyMapping ? 
          (!!group.employee.ZenegyEmployeeMapping?.sync_enabled && 
           !!group.employee.ZenegyEmployeeMapping?.zenegy_employee_id) : false
      };
    });

    // Statistics
    const stats = {
      total_employees: employeesData.length,
      total_hours: Math.round(totalHours * 100) / 100,
      total_entries: totalEntries,
      employees_with_zenegy_mapping: employeesData.filter(e => e.has_zenegy_mapping).length,
      employees_ready_for_sync: employeesData.filter(e => e.can_sync_to_zenegy).length,
      has_sent_to_payroll_column: hasSentToPayrollColumn,
      has_zenegy_mapping_table: includeZenegyMapping,
      date_range: workEntries.length > 0 ? {
        start: Math.min(...workEntries.map(e => e.work_date.getTime())),
        end: Math.max(...workEntries.map(e => e.work_date.getTime()))
      } : null
    };

    console.log("✅ [PAYROLL READY] Processing completed", {
      employeesFound: stats.total_employees,
      totalHours: stats.total_hours,
      readyForSync: stats.employees_ready_for_sync
    });

    return NextResponse.json({
      success: true,
      data: employeesData,
      stats,
      filters_applied: {
        start_date: startDate,
        end_date: endDate,
        employee_id: employeeId,
        task_id: taskId,
        project_id: projectId
      }
    }, { status: 200 });

  } catch (err: any) {
    console.error("❌ [PAYROLL READY] Error:", err);
    return NextResponse.json({ 
      success: false,
      error: getErrorMessage(err),
      details: err.message 
    }, { status: 500 });
  }
}