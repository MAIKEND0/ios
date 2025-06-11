// src/app/api/app/work-entries/confirmed/route.ts - UPDATED FOR iOS COMPATIBILITY

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";
import { PushNotificationService } from "../../../../../lib/pushNotificationService";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/work-entries/confirmed
 * Pobiera potwierdzone godziny z dodatkowymi filtrami - używa istniejącej struktury
 */
export async function GET(request: NextRequest): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('start_date');
    const endDate = searchParams.get('end_date');
    const employeeId = searchParams.get('employee_id');
    const taskId = searchParams.get('task_id');
    const projectId = searchParams.get('project_id');
    const sentToPayroll = searchParams.get('sent_to_payroll');
    const limit = parseInt(searchParams.get('limit') || '100');
    const offset = parseInt(searchParams.get('offset') || '0');

    console.log("🔍 [CONFIRMED ENTRIES] Fetching confirmed work entries", {
      startDate, endDate, employeeId, taskId, projectId, sentToPayroll, limit, offset
    });

    // Build where clause - use only existing columns
    const where: any = {
      confirmation_status: 'confirmed',
      isActive: true,
      start_time: { not: null },
      end_time: { not: null }
    };

    // Check if sent_to_payroll column exists
    let hasSentToPayrollColumn = false;
    try {
      await prisma.$queryRaw`SELECT sent_to_payroll FROM WorkEntries LIMIT 1`;
      hasSentToPayrollColumn = true;
      if (sentToPayroll !== null) {
        where.sent_to_payroll = sentToPayroll === 'true';
      }
    } catch (error) {
      console.log("⚠️ [CONFIRMED ENTRIES] sent_to_payroll column not found");
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

    // Get total count
    const totalCount = await prisma.workEntries.count({ where });

    // Build select for Employees - check which columns exist
    const selectEmployees: any = {
      employee_id: true,
      name: true,
      email: true,
    };

    try {
      await prisma.$queryRaw`SELECT zenegy_employee_number FROM Employees LIMIT 1`;
      selectEmployees.zenegy_employee_number = true;
    } catch (error) {
      console.log("⚠️ [CONFIRMED ENTRIES] zenegy_employee_number column not found");
    }

    // Check if ZenegyEmployeeMapping table exists
    let includeZenegyMapping = false;
    try {
      await prisma.$queryRaw`SELECT COUNT(*) FROM ZenegyEmployeeMapping LIMIT 1`;
      includeZenegyMapping = true;
      selectEmployees.ZenegyEmployeeMapping = {
        select: {
          zenegy_employee_id: true,
          zenegy_person_id: true,
          zenegy_employment_id: true,
          sync_enabled: true
        }
      };
    } catch (error) {
      console.log("⚠️ [CONFIRMED ENTRIES] ZenegyEmployeeMapping table not found");
    }

    // Check if PayrollBatches table exists
    let includePayrollBatches = false;
    try {
      await prisma.$queryRaw`SELECT COUNT(*) FROM PayrollBatches LIMIT 1`;
      includePayrollBatches = true;
    } catch (error) {
      console.log("⚠️ [CONFIRMED ENTRIES] PayrollBatches table not found");
    }

    // Fetch entries with pagination - build include based on available tables
    const includeObject: any = {
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
    };

    if (includePayrollBatches) {
      includeObject.PayrollBatches = {
        select: {
          id: true,
          batch_number: true,
          status: true,
          created_at: true
        }
      };
    }

    const workEntries = await prisma.workEntries.findMany({
      where,
      include: includeObject,
      orderBy: [
        { work_date: 'desc' },
        { employee_id: 'asc' }
      ],
      take: limit,
      skip: offset
    });

    console.log(`📊 [CONFIRMED ENTRIES] Found ${workEntries.length} confirmed entries`);

    // Transform data for iOS app compatibility - handle missing columns safely
    const transformedEntries = workEntries.map((entry: any) => {
      // Calculate hours
      const startTime = new Date(entry.start_time!);
      const endTime = new Date(entry.end_time!);
      const totalMinutes = (endTime.getTime() - startTime.getTime()) / (1000 * 60);
      const pauseMinutes = entry.pause_minutes || 0;
      const workedMinutes = Math.max(0, totalMinutes - pauseMinutes);
      const workedHours = Math.round((workedMinutes / 60) * 100) / 100;

      // Build response object based on available data
      const transformedEntry: any = {
        entry_id: entry.entry_id,
        work_date: entry.work_date,
        start_time: entry.start_time,
        end_time: entry.end_time,
        pause_minutes: entry.pause_minutes,
        worked_hours: workedHours,
        kilometers: parseFloat(entry.km?.toString() || '0'),
        description: entry.description,
        status: entry.status,
        confirmation_status: entry.confirmation_status,
        employee: entry.Employees || null,
        task: {
          task_id: entry.Tasks?.task_id || entry.task_id,
          title: entry.Tasks?.title || 'Unknown Task',
          project: entry.Tasks?.Projects || null
        }
      };

      // Add payroll-related fields if available
      if (hasSentToPayrollColumn) {
        transformedEntry.sent_to_payroll = entry.sent_to_payroll || false;
        transformedEntry.sent_to_payroll_at = entry.sent_to_payroll_at || null;
      }

      if (includePayrollBatches) {
        transformedEntry.payroll_batch = entry.PayrollBatches || null;
      }

      if (includeZenegyMapping && entry.Employees?.ZenegyEmployeeMapping) {
        transformedEntry.zenegy_mapping = entry.Employees.ZenegyEmployeeMapping;
        transformedEntry.can_sync_to_zenegy = !!entry.Employees.ZenegyEmployeeMapping?.sync_enabled && 
                                             !!entry.Employees.ZenegyEmployeeMapping?.zenegy_employee_id;
      } else {
        transformedEntry.zenegy_mapping = null;
        transformedEntry.can_sync_to_zenegy = false;
      }

      return transformedEntry;
    });

    // Calculate summary statistics
    const summary = {
      total_entries: totalCount,
      returned_entries: transformedEntries.length,
      total_hours: transformedEntries.reduce((sum, entry) => sum + entry.worked_hours, 0),
      total_kilometers: transformedEntries.reduce((sum, entry) => sum + entry.kilometers, 0),
      unique_employees: new Set(transformedEntries.map(e => e.employee.employee_id)).size,
      unique_projects: new Set(transformedEntries.map(e => e.task.project?.project_id)).size,
      sent_to_payroll_count: hasSentToPayrollColumn ? 
        transformedEntries.filter(e => e.sent_to_payroll).length : 0,
      ready_for_payroll_count: hasSentToPayrollColumn ? 
        transformedEntries.filter(e => !e.sent_to_payroll).length : transformedEntries.length,
      employees_with_zenegy_mapping: includeZenegyMapping ? 
        new Set(
          transformedEntries
            .filter(e => e.zenegy_mapping?.zenegy_employee_id)
            .map(e => e.employee.employee_id)
        ).size : 0,
      has_sent_to_payroll_column: hasSentToPayrollColumn,
      has_zenegy_mapping_table: includeZenegyMapping,
      has_payroll_batches_table: includePayrollBatches
    };

    return NextResponse.json({
      success: true,
      data: transformedEntries,
      summary,
      pagination: {
        limit,
        offset,
        total: totalCount,
        has_more: offset + limit < totalCount
      },
      filters_applied: {
        start_date: startDate,
        end_date: endDate,
        employee_id: employeeId,
        task_id: taskId,
        project_id: projectId,
        sent_to_payroll: sentToPayroll
      }
    }, { status: 200 });

  } catch (err: any) {
    console.error("❌ [CONFIRMED ENTRIES] Error:", err);
    return NextResponse.json({ 
      success: false,
      error: getErrorMessage(err),
      details: err.message 
    }, { status: 500 });
  }
}

/**
 * PATCH /api/app/work-entries/confirmed
 * Bulk operations on confirmed hours - UPDATED FOR iOS COMPATIBILITY
 * Supports iOS actions (approve, reject) + existing backend actions
 */
export async function PATCH(request: NextRequest): Promise<NextResponse> {
  try {
    const body = await request.json();
    const { entry_ids, action, payroll_batch_id, notes } = body;

    if (!Array.isArray(entry_ids) || entry_ids.length === 0) {
      return NextResponse.json({
        success: false,
        error: "entry_ids must be a non-empty array"
      }, { status: 400 });
    }

    console.log(`🔄 [CONFIRMED ENTRIES] Bulk operation: ${action} on ${entry_ids.length} entries`);

    // Check if required columns exist
    let hasSentToPayrollColumn = false;
    let hasPayrollBatchIdColumn = false;
    
    try {
      await prisma.$queryRaw`SELECT sent_to_payroll FROM WorkEntries LIMIT 1`;
      hasSentToPayrollColumn = true;
    } catch (error) {
      console.log("⚠️ [CONFIRMED ENTRIES] sent_to_payroll column not found");
    }

    try {
      await prisma.$queryRaw`SELECT payroll_batch_id FROM WorkEntries LIMIT 1`;
      hasPayrollBatchIdColumn = true;
    } catch (error) {
      console.log("⚠️ [CONFIRMED ENTRIES] payroll_batch_id column not found");
    }

    // Verify all entries exist and get their current state
    const existingEntries = await prisma.workEntries.findMany({
      where: {
        entry_id: { in: entry_ids },
        isActive: true
      },
      select: {
        entry_id: true,
        employee_id: true,
        task_id: true,
        work_date: true,
        confirmation_status: true,
        status: true,
        description: true
      }
    });

    if (existingEntries.length !== entry_ids.length) {
      const foundIds = existingEntries.map(e => e.entry_id);
      const missingIds = entry_ids.filter(id => !foundIds.includes(id));
      
      return NextResponse.json({
        success: false,
        error: `Some entries not found: ${missingIds.join(', ')}`
      }, { status: 404 });
    }

    // Process each action type
    let actionDescription = "";
    const successfulEntries: number[] = [];
    const failedEntries: { id: number, error: string }[] = [];

    switch (action) {
      // ===== iOS APP ACTIONS =====
      case 'approve':
        // iOS sends "approve" - we'll mark as sent to payroll
        if (!hasSentToPayrollColumn) {
          return NextResponse.json({
            success: false,
            error: "Cannot approve entries: sent_to_payroll column not found. Please run database migration."
          }, { status: 400 });
        }

        // Check if entries are confirmed
        const unconfirmedEntries = existingEntries.filter(e => e.confirmation_status !== 'confirmed');
        if (unconfirmedEntries.length > 0) {
          return NextResponse.json({
            success: false,
            error: `Cannot approve unconfirmed entries: ${unconfirmedEntries.map(e => e.entry_id).join(', ')}`
          }, { status: 400 });
        }

        // Approve entries by marking as sent to payroll
        for (const entry of existingEntries) {
          try {
            await prisma.workEntries.update({
              where: { entry_id: entry.entry_id },
              data: {
                sent_to_payroll: true,
                sent_to_payroll_at: new Date(),
                ...(hasPayrollBatchIdColumn && payroll_batch_id ? { payroll_batch_id } : {})
              }
            });
            successfulEntries.push(entry.entry_id);

            // 🚀 Send push notification to worker
            try {
              await PushNotificationService.sendToEmployee({
                employee_id: entry.employee_id,
                title: "✅ Hours Approved",
                message: `Your work hours for ${new Date(entry.work_date).toLocaleDateString()} have been approved for payroll.`,
                notification_type: "HOURS_CONFIRMED",
                priority: "NORMAL",
                category: "HOURS",
                action_required: false,
                metadata: {
                  entry_id: entry.entry_id,
                  task_id: entry.task_id,
                  work_date: entry.work_date
                }
              });
              console.log(`[WORK ENTRIES] ✅ Push notification sent for approved entry ${entry.entry_id}`);
            } catch (pushError: any) {
              console.error(`[WORK ENTRIES] ❌ Failed to send push notification for entry ${entry.entry_id}:`, pushError);
            }
          } catch (error: any) {
            failedEntries.push({ id: entry.entry_id, error: error.message });
          }
        }
        actionDescription = "approved and marked for payroll";
        break;

      case 'reject':
        // iOS sends "reject" - we'll update confirmation status
        for (const entry of existingEntries) {
          try {
            const updateData: any = {
              confirmation_status: 'rejected',
              status: 'rejected'
            };

            // Add rejection note to description if provided
            if (notes) {
              const existingDescription = entry.description || '';
              updateData.description = existingDescription + `\n[REJECTED: ${notes}]`;
            }

            await prisma.workEntries.update({
              where: { entry_id: entry.entry_id },
              data: updateData
            });
            successfulEntries.push(entry.entry_id);

            // 🚀 Send push notification to worker
            try {
              const rejectionMessage = notes 
                ? `Your work hours for ${new Date(entry.work_date).toLocaleDateString()} have been rejected. Reason: ${notes}`
                : `Your work hours for ${new Date(entry.work_date).toLocaleDateString()} have been rejected. Please review and resubmit.`;

              await PushNotificationService.sendToEmployee({
                employee_id: entry.employee_id,
                title: "❌ Hours Rejected",
                message: rejectionMessage,
                notification_type: "HOURS_REJECTED",
                priority: "HIGH",
                category: "HOURS",
                action_required: true,
                metadata: {
                  entry_id: entry.entry_id,
                  task_id: entry.task_id,
                  work_date: entry.work_date,
                  rejection_reason: notes || ''
                }
              });
              console.log(`[WORK ENTRIES] ✅ Push notification sent for rejected entry ${entry.entry_id}`);
            } catch (pushError: any) {
              console.error(`[WORK ENTRIES] ❌ Failed to send push notification for entry ${entry.entry_id}:`, pushError);
            }
          } catch (error: any) {
            failedEntries.push({ id: entry.entry_id, error: error.message });
          }
        }
        actionDescription = "rejected";
        break;

      // ===== EXISTING BACKEND ACTIONS =====
      case 'mark_sent_to_payroll':
        if (!hasSentToPayrollColumn) {
          return NextResponse.json({
            success: false,
            error: "sent_to_payroll column not found"
          }, { status: 400 });
        }
        
        for (const entry of existingEntries) {
          try {
            await prisma.workEntries.update({
              where: { entry_id: entry.entry_id },
              data: {
                sent_to_payroll: true,
                sent_to_payroll_at: new Date(),
                ...(hasPayrollBatchIdColumn && payroll_batch_id ? { payroll_batch_id } : {})
              }
            });
            successfulEntries.push(entry.entry_id);
          } catch (error: any) {
            failedEntries.push({ id: entry.entry_id, error: error.message });
          }
        }
        actionDescription = "marked as sent to payroll";
        break;
        
      case 'mark_not_sent_to_payroll':
        if (!hasSentToPayrollColumn) {
          return NextResponse.json({
            success: false,
            error: "sent_to_payroll column not found"
          }, { status: 400 });
        }
        
        for (const entry of existingEntries) {
          try {
            await prisma.workEntries.update({
              where: { entry_id: entry.entry_id },
              data: {
                sent_to_payroll: false,
                sent_to_payroll_at: null,
                ...(hasPayrollBatchIdColumn ? { payroll_batch_id: null } : {})
              }
            });
            successfulEntries.push(entry.entry_id);
          } catch (error: any) {
            failedEntries.push({ id: entry.entry_id, error: error.message });
          }
        }
        actionDescription = "marked as not sent to payroll";
        break;
        
      case 'assign_to_batch':
        if (!payroll_batch_id) {
          return NextResponse.json({
            success: false,
            error: "payroll_batch_id is required for assign_to_batch action"
          }, { status: 400 });
        }
        
        // Verify batch exists (if PayrollBatches table exists)
        try {
          const batchCheck = await prisma.$queryRaw`
            SELECT batch_number FROM PayrollBatches WHERE id = ${payroll_batch_id} LIMIT 1
          ` as any[];
          
          if (batchCheck.length === 0) {
            return NextResponse.json({
              success: false,
              error: "Payroll batch not found"
            }, { status: 404 });
          }
        } catch (error) {
          console.log("⚠️ [CONFIRMED ENTRIES] Could not verify batch existence");
        }
        
        for (const entry of existingEntries) {
          try {
            await prisma.workEntries.update({
              where: { entry_id: entry.entry_id },
              data: {
                ...(hasPayrollBatchIdColumn ? { payroll_batch_id } : {}),
                ...(hasSentToPayrollColumn ? { 
                  sent_to_payroll: true, 
                  sent_to_payroll_at: new Date() 
                } : {})
              }
            });
            successfulEntries.push(entry.entry_id);
          } catch (error: any) {
            failedEntries.push({ id: entry.entry_id, error: error.message });
          }
        }
        actionDescription = `assigned to batch ${payroll_batch_id}`;
        break;
        
      default:
        return NextResponse.json({
          success: false,
          error: `Invalid action: ${action}. Supported actions: approve, reject, mark_sent_to_payroll, mark_not_sent_to_payroll, assign_to_batch`
        }, { status: 400 });
    }

    // Get updated entries for response
    const updatedEntries = await prisma.workEntries.findMany({
      where: {
        entry_id: { in: successfulEntries }
      },
      include: {
        Employees: {
          select: {
            employee_id: true,
            name: true,
            email: true
          }
        },
        Tasks: {
          include: {
            Projects: {
              select: {
                project_id: true,
                title: true
              }
            }
          }
        }
      }
    });

    const responseEntries = updatedEntries.map(entry => {
      const response: any = {
        entry_id: entry.entry_id,
        employee_name: entry.Employees.name,
        task_title: entry.Tasks.title,
        project_title: entry.Tasks.Projects?.title,
        work_date: entry.work_date,
        confirmation_status: entry.confirmation_status,
        status: entry.status
      };

      if (hasSentToPayrollColumn) {
        response.sent_to_payroll = (entry as any).sent_to_payroll;
      }

      if (hasPayrollBatchIdColumn) {
        response.payroll_batch_id = (entry as any).payroll_batch_id;
      }

      return response;
    });

    const isFullySuccessful = failedEntries.length === 0;
    const successCount = successfulEntries.length;
    const totalRequested = entry_ids.length;

    console.log(`✅ [CONFIRMED ENTRIES] Bulk operation completed: ${successCount}/${totalRequested} entries ${actionDescription}`);

    return NextResponse.json({
      success: isFullySuccessful,
      message: isFullySuccessful 
        ? `${successCount} entries ${actionDescription}` 
        : `${successCount} of ${totalRequested} entries ${actionDescription}`,
      updated_count: successCount,
      total_requested: totalRequested,
      action: action,
      successful: successfulEntries,
      failed: failedEntries,
      updated_entries: responseEntries,
      columns_available: {
        sent_to_payroll: hasSentToPayrollColumn,
        payroll_batch_id: hasPayrollBatchIdColumn
      }
    }, { status: isFullySuccessful ? 200 : 207 }); // 207 = Multi-Status for partial success

  } catch (err: any) {
    console.error("❌ [CONFIRMED ENTRIES] Bulk operation error:", err);
    return NextResponse.json({
      success: false,
      error: getErrorMessage(err),
      details: err.message
    }, { status: 500 });
  }
}
