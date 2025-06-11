import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '../../../../../../lib/prisma';

// Schedule Validation Endpoint
// Validates proposed schedule changes for events

interface ValidationRequest {
  event_id: string;
  current_start_date: string;
  new_start_date: string;
  new_end_date?: string;
  resource_requirements: any[];
}

interface ValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
  conflicts: any[];
  suggestedAlternatives?: any[];
}

export async function POST(request: NextRequest) {
  try {
    console.log('[ScheduleValidation] Processing validation request');
    
    const body: ValidationRequest = await request.json();
    const { event_id, current_start_date, new_start_date, new_end_date, resource_requirements } = body;

    const newStartDate = new Date(new_start_date);
    const newEndDate = new_end_date ? new Date(new_end_date) : newStartDate;
    
    console.log(`[ScheduleValidation] Validating schedule change for event ${event_id}`);
    console.log(`[ScheduleValidation] New schedule: ${new_start_date} to ${new_end_date || new_start_date}`);

    const errors: string[] = [];
    const warnings: string[] = [];
    const conflicts: any[] = [];

    // 1. Basic date validation
    if (newStartDate > newEndDate) {
      errors.push('Start date cannot be after end date');
    }

    if (newStartDate < new Date()) {
      warnings.push('Scheduling event in the past');
    }

    // 2. Check for leave conflicts
    try {
      const leaveConflicts = await prisma.leaveRequests.findMany({
        where: {
          status: 'APPROVED',
          start_date: { lte: newEndDate },
          end_date: { gte: newStartDate }
        },
        include: {
          Employees_LeaveRequests_employee_idToEmployees: {
            select: {
              name: true
            }
          }
        }
      });

      if (leaveConflicts.length > 0) {
        warnings.push(`${leaveConflicts.length} workers on leave during this period`);
        
        for (const leave of leaveConflicts) {
          conflicts.push({
            conflictType: 'LEAVE_CONFLICT',
            conflictingEventId: `leave-${leave.id}`,
            severity: 'MEDIUM',
            description: `${leave.Employees_LeaveRequests_employee_idToEmployees?.name} is on ${leave.type} leave`,
            affectedWorkers: [leave.employee_id]
          });
        }
      }
    } catch (error) {
      console.error('[ScheduleValidation] Error checking leave conflicts:', error);
      warnings.push('Could not verify leave conflicts');
    }

    // 3. Check for operator capacity issues
    try {
      const overlappingAssignments = await prisma.taskAssignments.count({
        where: {
          work_date: { gte: newStartDate, lte: newEndDate },
          status: { in: ['assigned', 'active'] }
        }
      });

      const totalOperators = await prisma.employees.count({
        where: {
          role: { in: ['arbejder', 'byggeleder'] },
          is_activated: true
        }
      });

      const utilizationRate = overlappingAssignments / Math.max(totalOperators, 1);
      
      if (utilizationRate > 0.8) { // 80% utilization threshold
        warnings.push(`High operator utilization (${Math.round(utilizationRate * 100)}%) during this period`);
      }
    } catch (error) {
      console.error('[ScheduleValidation] Error checking operator capacity:', error);
    }

    // 4. Check for skill/certification requirements
    try {
      // This would need more specific task requirements to validate properly
      // For now, just a placeholder
      warnings.push('Verify operator certifications match client equipment requirements');
    } catch (error) {
      console.error('[ScheduleValidation] Error checking certifications:', error);
    }

    // 5. Weekend/Holiday validation
    const dayOfWeek = newStartDate.getDay();
    if (dayOfWeek === 0 || dayOfWeek === 6) {
      warnings.push('Event scheduled on weekend');
    }

    // 6. Business hours validation
    const hour = newStartDate.getHours();
    if (hour < 6 || hour > 18) {
      warnings.push('Event scheduled outside normal business hours');
    }

    const isValid = errors.length === 0;

    const result: ValidationResult = {
      isValid,
      errors,
      warnings,
      conflicts
    };

    console.log(`[ScheduleValidation] Validation result: ${isValid ? 'VALID' : 'INVALID'}`);
    console.log(`[ScheduleValidation] Errors: ${errors.length}, Warnings: ${warnings.length}, Conflicts: ${conflicts.length}`);

    return NextResponse.json(result);

  } catch (error) {
    console.error('[ScheduleValidation] Error:', error);
    return NextResponse.json(
      { error: 'Failed to validate schedule', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
