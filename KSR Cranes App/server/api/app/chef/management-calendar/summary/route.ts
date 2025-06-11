import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '../../../../../../lib/prisma';

// Management Calendar Summary Endpoint
// Provides high-level calendar statistics for a specific date

interface CalendarSummary {
  totalEvents: number;
  eventsByType: Record<string, number>;
  eventsByPriority: Record<string, number>;
  conflictCount: number;
  capacityUtilization: number;
  upcomingDeadlines: number;
  workersOnLeave: number;
  availableWorkers: number;
}

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const dateParam = searchParams.get('date');
    
    if (!dateParam) {
      return NextResponse.json(
        { error: 'Date parameter is required' },
        { status: 400 }
      );
    }

    const targetDate = new Date(dateParam);
    const startOfDay = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate());
    const endOfDay = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate(), 23, 59, 59);

    console.log(`[ManagementCalendar] Generating summary for date: ${dateParam}`);

    let totalEvents = 0;
    const eventsByType: Record<string, number> = {};
    const eventsByPriority: Record<string, number> = {};

    // 1. Count Leave Events for the date
    try {
      const leaveCount = await prisma.leaveRequests.count({
        where: {
          status: 'APPROVED',
          start_date: { lte: endOfDay },
          end_date: { gte: startOfDay }
        }
      });

      if (leaveCount > 0) {
        eventsByType['LEAVE'] = leaveCount;
        eventsByPriority['MEDIUM'] = (eventsByPriority['MEDIUM'] || 0) + leaveCount;
        totalEvents += leaveCount;
      }

      console.log(`[ManagementCalendar] Found ${leaveCount} leave events for ${dateParam}`);
    } catch (error) {
      console.error('[ManagementCalendar] Error counting leave events:', error);
    }

    // 2. Count Project Events (projects active on this date)
    try {
      const projectCount = await prisma.projects.count({
        where: {
          OR: [
            {
              AND: [
                { start_date: { lte: endOfDay } },
                { end_date: { gte: startOfDay } }
              ]
            },
            {
              AND: [
                { start_date: { lte: endOfDay } },
                { end_date: null }
              ]
            }
          ]
        }
      });

      if (projectCount > 0) {
        eventsByType['PROJECT'] = projectCount;
        eventsByPriority['MEDIUM'] = (eventsByPriority['MEDIUM'] || 0) + projectCount;
        totalEvents += projectCount;
      }

      console.log(`[ManagementCalendar] Found ${projectCount} active projects for ${dateParam}`);
    } catch (error) {
      console.error('[ManagementCalendar] Error counting project events:', error);
    }

    // 3. Count Task Events (tasks with deadlines or start dates on this date)
    try {
      const taskCount = await prisma.tasks.count({
        where: {
          OR: [
            {
              start_date: {
                gte: startOfDay,
                lte: endOfDay
              }
            },
            {
              deadline: {
                gte: startOfDay,
                lte: endOfDay
              }
            }
          ]
        }
      });

      if (taskCount > 0) {
        eventsByType['TASK'] = taskCount;
        eventsByPriority['HIGH'] = (eventsByPriority['HIGH'] || 0) + taskCount;
        totalEvents += taskCount;
      }

      console.log(`[ManagementCalendar] Found ${taskCount} task events for ${dateParam}`);
    } catch (error) {
      console.error('[ManagementCalendar] Error counting task events:', error);
    }

    // 4. Calculate upcoming deadlines (next 7 days)
    const nextWeek = new Date(targetDate.getTime() + 7 * 24 * 60 * 60 * 1000);
    let upcomingDeadlines = 0;

    try {
      upcomingDeadlines = await prisma.tasks.count({
        where: {
          deadline: {
            gte: targetDate,
            lte: nextWeek
          },
          isActive: true
        }
      });

      console.log(`[ManagementCalendar] Found ${upcomingDeadlines} upcoming deadlines`);
    } catch (error) {
      console.error('[ManagementCalendar] Error counting upcoming deadlines:', error);
    }

    // 5. Calculate worker availability for the date
    let workersOnLeave = 0;
    let availableWorkers = 0;

    try {
      const totalWorkers = await prisma.employees.count({
        where: {
          role: { in: ['arbejder', 'byggeleder'] },
          is_activated: true
        }
      });

      workersOnLeave = await prisma.leaveRequests.count({
        where: {
          status: 'APPROVED',
          start_date: { lte: endOfDay },
          end_date: { gte: startOfDay }
        }
      });

      availableWorkers = totalWorkers - workersOnLeave;

      console.log(`[ManagementCalendar] Worker availability: ${availableWorkers}/${totalWorkers} available`);
    } catch (error) {
      console.error('[ManagementCalendar] Error calculating worker availability:', error);
    }

    // 6. Generate final summary
    const summary: CalendarSummary = {
      totalEvents,
      eventsByType,
      eventsByPriority,
      conflictCount: 0, // TODO: Implement conflict detection
      capacityUtilization: totalEvents > 0 ? Math.min(totalEvents / 10, 1.0) : 0, // Simple estimation
      upcomingDeadlines,
      workersOnLeave,
      availableWorkers
    };

    console.log(`[ManagementCalendar] Summary for ${dateParam}: ${totalEvents} events, ${availableWorkers} workers available`);

    return NextResponse.json(summary);

  } catch (error) {
    console.error('[ManagementCalendar] Summary generation error:', error);
    return NextResponse.json(
      { error: 'Failed to generate calendar summary', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
