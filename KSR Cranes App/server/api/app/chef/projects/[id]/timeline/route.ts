// src/app/api/app/chef/projects/[id]/timeline/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/projects/[id]/timeline
 * Generuje timeline projektu na podstawie istniejących danych
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const projectId = parseInt(id, 10);
    
    if (isNaN(projectId)) {
      return NextResponse.json({ error: "Invalid project ID" }, { status: 400 });
    }

    // Sprawdź czy projekt istnieje
    const project = await prisma.projects.findUnique({
      where: { project_id: projectId },
      include: {
        Customers: {
          select: { name: true }
        }
      }
    });

    if (!project) {
      return NextResponse.json({ error: "Project not found" }, { status: 404 });
    }

    // Pobierz wszystkie dane potrzebne do timeline
    const [tasks, workEntries, assignments] = await Promise.all([
      // Zadania z deadlines
      prisma.tasks.findMany({
        where: { project_id: projectId },
        select: {
          task_id: true,
          title: true,
          created_at: true,
          deadline: true,
          isActive: true
        },
        orderBy: { created_at: 'asc' }
      }),

      // Wpisy pracy dla progress tracking
      prisma.workEntries.findMany({
        where: {
          Tasks: { project_id: projectId },
          isActive: true,
          status: 'confirmed'
        },
        select: {
          work_date: true,
          start_time: true,
          end_time: true,
          pause_minutes: true,
          Tasks: {
            select: {
              task_id: true,
              title: true
            }
          }
        },
        orderBy: { work_date: 'asc' }
      }),

      // Task assignments dla tracking kiedy kto został przypisany
      prisma.taskAssignments.findMany({
        where: {
          Tasks: { project_id: projectId }
        },
        select: {
          assigned_at: true,
          Employees: {
            select: {
              name: true
            }
          },
          Tasks: {
            select: {
              task_id: true,
              title: true
            }
          }
        },
        orderBy: { assigned_at: 'asc' }
      })
    ]);

    // Generuj timeline events
    const timelineEvents: Array<{
      id: string;
      title: string;
      date: Date;
      type: 'project_start' | 'project_end' | 'task_created' | 'task_deadline' | 'task_completed' | 'worker_assigned' | 'work_completed' | 'milestone';
      description?: string;
      task_id?: number;
      status: 'completed' | 'upcoming' | 'overdue' | 'in_progress';
      progress?: number;
    }> = [];

    const now = new Date();

    // 1. Project start
    if (project.start_date) {
      timelineEvents.push({
        id: `project_start_${projectId}`,
        title: 'Project Started',
        date: project.start_date,
        type: 'project_start',
        description: `Project "${project.title}" started`,
        status: project.start_date <= now ? 'completed' : 'upcoming'
      });
    }

    // 2. Project creation (jeśli nie ma start_date)
    if (!project.start_date && project.created_at) {
      timelineEvents.push({
        id: `project_created_${projectId}`,
        title: 'Project Created',
        date: project.created_at,
        type: 'project_start',
        description: `Project "${project.title}" was created`,
        status: 'completed'
      });
    }

    // 3. Task creation events
    tasks.forEach(task => {
      if (task.created_at) {
        timelineEvents.push({
          id: `task_created_${task.task_id}`,
          title: `Task Created: ${task.title}`,
          date: task.created_at,
          type: 'task_created',
          description: `New task "${task.title}" was created`,
          task_id: task.task_id,
          status: 'completed'
        });
      }
    });

    // 4. Worker assignments
    assignments.forEach((assignment, index) => {
      if (assignment.assigned_at) {
        timelineEvents.push({
          id: `assignment_${index}`,
          title: `Worker Assigned`,
          date: assignment.assigned_at,
          type: 'worker_assigned',
          description: `${assignment.Employees.name} assigned to "${assignment.Tasks.title}"`,
          task_id: assignment.Tasks.task_id,
          status: 'completed'
        });
      }
    });

    // 5. Task deadlines
    tasks.forEach(task => {
      if (task.deadline) {
        const isOverdue = task.deadline < now && task.isActive;
        const isCompleted = !task.isActive;
        
        timelineEvents.push({
          id: `task_deadline_${task.task_id}`,
          title: `Deadline: ${task.title}`,
          date: task.deadline,
          type: 'task_deadline',
          description: `Deadline for task "${task.title}"`,
          task_id: task.task_id,
          status: isCompleted ? 'completed' : isOverdue ? 'overdue' : 'upcoming'
        });
      }
    });

    // 6. Work completion milestones (group by week)
    const workByWeek = new Map<string, { hours: number; tasks: Set<number> }>();
    workEntries.forEach(entry => {
      if (entry.start_time && entry.end_time) {
        const weekKey = getWeekKey(entry.work_date);
        const hours = calculateHours(entry.start_time, entry.end_time, entry.pause_minutes);
        
        if (!workByWeek.has(weekKey)) {
          workByWeek.set(weekKey, { hours: 0, tasks: new Set() });
        }
        
        const week = workByWeek.get(weekKey)!;
        week.hours += hours;
        week.tasks.add(entry.Tasks.task_id);
      }
    });

    workByWeek.forEach((weekData, weekKey) => {
      const weekDate = getDateFromWeekKey(weekKey);
      timelineEvents.push({
        id: `work_week_${weekKey}`,
        title: `Weekly Progress`,
        date: weekDate,
        type: 'work_completed',
        description: `${Math.round(weekData.hours)} hours completed across ${weekData.tasks.size} task(s)`,
        status: 'completed',
        progress: weekData.hours
      });
    });

    // 7. Project end
    if (project.end_date) {
      const isProjectCompleted = project.status === 'afsluttet';
      timelineEvents.push({
        id: `project_end_${projectId}`,
        title: 'Project End',
        date: project.end_date,
        type: 'project_end',
        description: `Planned project completion`,
        status: isProjectCompleted ? 'completed' : project.end_date < now ? 'overdue' : 'upcoming'
      });
    }

    // Sortuj events chronologicznie
    timelineEvents.sort((a, b) => a.date.getTime() - b.date.getTime());

    // Oblicz statistics
    const totalEvents = timelineEvents.length;
    const completedEvents = timelineEvents.filter(e => e.status === 'completed').length;
    const upcomingEvents = timelineEvents.filter(e => e.status === 'upcoming').length;
    const overdueEvents = timelineEvents.filter(e => e.status === 'overdue').length;
    const currentProgress = totalEvents > 0 ? (completedEvents / totalEvents) * 100 : 0;

    // Critical path (najpilniejsze zadania)
    const criticalTasks = tasks
      .filter(task => task.deadline && task.isActive)
      .sort((a, b) => a.deadline!.getTime() - b.deadline!.getTime())
      .slice(0, 5)
      .map(task => ({
        task_id: task.task_id,
        title: task.title,
        deadline: task.deadline,
        is_overdue: task.deadline! < now,
        days_until_deadline: Math.ceil((task.deadline!.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
      }));

    // Estimated completion (na podstawie current progress)
    let estimatedEndDate = project.end_date;
    if (!estimatedEndDate && currentProgress > 0) {
      const projectDuration = project.start_date ? 
        (now.getTime() - project.start_date.getTime()) / currentProgress * 100 :
        30 * 24 * 60 * 60 * 1000; // 30 days default
      
      estimatedEndDate = new Date(now.getTime() + projectDuration);
    }

    const response = {
      project_id: projectId,
      project_title: project.title,
      events: timelineEvents,
      statistics: {
        total_events: totalEvents,
        completed_events: completedEvents,
        upcoming_events: upcomingEvents,
        overdue_events: overdueEvents,
        current_progress: Math.round(currentProgress * 100) / 100
      },
      critical_path: criticalTasks,
      estimated_end_date: estimatedEndDate,
      project_status: project.status,
      actual_start_date: project.start_date,
      planned_end_date: project.end_date
    };

    return NextResponse.json(response, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/app/chef/projects/[id]/timeline:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

// Helper functions
function getWeekKey(date: Date): string {
  const year = date.getFullYear();
  const week = getWeekNumber(date);
  return `${year}-W${week.toString().padStart(2, '0')}`;
}

function getDateFromWeekKey(weekKey: string): Date {
  const [year, week] = weekKey.split('-W').map(Number);
  const firstDayOfYear = new Date(year, 0, 1);
  const daysToAdd = (week - 1) * 7;
  return new Date(firstDayOfYear.getTime() + daysToAdd * 24 * 60 * 60 * 1000);
}

function getWeekNumber(date: Date): number {
  const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
  const pastDaysOfYear = (date.getTime() - firstDayOfYear.getTime()) / 86400000;
  return Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7);
}

function calculateHours(startTime: Date, endTime: Date, pauseMinutes: number | null): number {
  const hours = (endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60);
  const pauseHours = (pauseMinutes || 0) / 60;
  return Math.max(0, hours - pauseHours);
}