// src/app/api/app/supervisor/projects/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";
import jwt from "jsonwebtoken";

const SECRET = process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET!;

async function authenticate(req: NextRequest) {
  const auth = req.headers.get("authorization")?.split(" ");
  if (auth?.[0] !== "Bearer" || !auth[1]) {
    throw new Error("Unauthorized");
  }
  try {
    const decoded = jwt.verify(auth[1], SECRET) as { id: number; role: string };
    if (decoded.role !== "byggeleder") {
      throw new Error("Unauthorized: Invalid role");
    }
    return decoded;
  } catch {
    throw new Error("Invalid token");
  }
}

export async function GET(req: NextRequest) {
  try {
    const { id: supervisorId } = await authenticate(req);

    console.log(`[API] Fetching projects for supervisor ${supervisorId}`);

    // Pobierz wszystkie projekty gdzie supervisor ma przypisane zadania
    const projects = await prisma.projects.findMany({
      where: {
        Tasks: {
          some: {
            supervisor_id: supervisorId,
            isActive: true
          }
        }
      },
      include: {
        // Podstawowe informacje o customer
        Customers: {
          select: {
            customer_id: true,
            name: true,
            contact_email: true,
            phone: true
          }
        },
        // Wszystkie zadania supervisora w tym projekcie
        Tasks: {
          where: {
            supervisor_id: supervisorId,
            isActive: true
          },
          select: {
            task_id: true,
            title: true,
            description: true,
            deadline: true,
            supervisor_id: true,
            created_at: true,
            // Przypisania pracowników do zadań
            TaskAssignments: {
              select: {
                assignment_id: true,
                employee_id: true,
                assigned_at: true,
                Employees: {
                  select: {
                    employee_id: true,
                    name: true,
                    email: true,
                    phone_number: true,
                    role: true
                  }
                }
              }
            },
            // Pending work entries dla tego zadania
            WorkEntries: {
              where: {
                confirmation_status: { not: "confirmed" },
                is_draft: false
              },
              select: {
                entry_id: true,
                employee_id: true,
                work_date: true,
                start_time: true,
                end_time: true,
                pause_minutes: true,
                confirmation_status: true,
                status: true,
                description: true,
                km: true,
                Employees: {
                  select: {
                    employee_id: true,
                    name: true
                  }
                }
              },
              orderBy: { work_date: "desc" }
            }
          }
        }
      },
      orderBy: { created_at: "desc" }
    });

    console.log(`[API] Found ${projects.length} projects for supervisor ${supervisorId}`);

    // Formatuj dane dla frontendu
    const formattedProjects = projects.map(project => {
      // Zbierz wszystkich unikalnych pracowników z zadań
      const allWorkers = new Map();
      let totalPendingEntries = 0;
      let totalPendingHours = 0;

      project.Tasks.forEach(task => {
        // Dodaj pracowników z assignments
        task.TaskAssignments.forEach(assignment => {
          if (!allWorkers.has(assignment.employee_id)) {
            allWorkers.set(assignment.employee_id, {
              employee_id: assignment.employee_id,
              name: assignment.Employees.name,
              email: assignment.Employees.email,
              phone_number: assignment.Employees.phone_number,
              role: assignment.Employees.role,
              assigned_at: assignment.assigned_at
            });
          }
        });

        // Policz pending entries i godziny
        task.WorkEntries.forEach(entry => {
          totalPendingEntries++;
          
          if (entry.start_time && entry.end_time) {
            const startTime = new Date(entry.start_time);
            const endTime = new Date(entry.end_time);
            const hoursWorked = (endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60);
            const pauseHours = (entry.pause_minutes || 0) / 60;
            totalPendingHours += Math.max(0, hoursWorked - pauseHours);
          }
        });
      });

      // Formatuj zadania
      const formattedTasks = project.Tasks.map(task => ({
        task_id: task.task_id,
        title: task.title,
        description: task.description,
        deadline: task.deadline?.toISOString() || null,
        supervisor_id: task.supervisor_id,
        created_at: task.created_at?.toISOString() || null,
        assignedWorkers: task.TaskAssignments.map(assignment => ({
          employee_id: assignment.employee_id,
          name: assignment.Employees.name,
          email: assignment.Employees.email,
          assigned_at: assignment.assigned_at?.toISOString() || null
        })),
        pendingEntries: task.WorkEntries.map(entry => ({
          entry_id: entry.entry_id,
          employee_id: entry.employee_id,
          employee_name: entry.Employees.name,
          work_date: entry.work_date.toISOString().split('T')[0],
          start_time: entry.start_time?.toISOString() || null,
          end_time: entry.end_time?.toISOString() || null,
          pause_minutes: entry.pause_minutes || 0,
          confirmation_status: entry.confirmation_status,
          status: entry.status,
          description: entry.description,
          km: entry.km ? parseFloat(entry.km.toString()) : 0
        })),
        pendingEntriesCount: task.WorkEntries.length,
        // Zagnieżdżona informacja o projekcie dla compatibility z istniejącym kodem
        project: {
          project_id: project.project_id,
          title: project.title,
          customer: project.Customers ? {
            customer_id: project.Customers.customer_id,
            name: project.Customers.name
          } : null
        }
      }));

      const result = {
        project_id: project.project_id,
        title: project.title,
        description: project.description,
        start_date: project.start_date?.toISOString() || null,
        end_date: project.end_date?.toISOString() || null,
        street: project.street,
        city: project.city,
        zip: project.zip,
        status: project.status,
        created_at: project.created_at?.toISOString() || null,
        
        // Customer info
        customer: project.Customers ? {
          customer_id: project.Customers.customer_id,
          name: project.Customers.name,
          contact_email: project.Customers.contact_email,
          phone: project.Customers.phone
        } : null,
        
        // Tasks z pełnymi danymi
        tasks: formattedTasks,
        
        // Statystyki
        assignedWorkersCount: allWorkers.size,
        totalTasksCount: project.Tasks.length,
        totalPendingEntries: totalPendingEntries,
        totalPendingHours: Math.round(totalPendingHours * 100) / 100,
        
        // Lista wszystkich pracowników w projekcie
        allAssignedWorkers: Array.from(allWorkers.values())
      };

      console.log(`[API] Project ${project.project_id}: ${result.totalTasksCount} tasks, ${result.assignedWorkersCount} workers, ${result.totalPendingEntries} pending entries`);
      
      return result;
    });

    return NextResponse.json(formattedProjects);
  } catch (e: any) {
    console.error("GET /api/app/supervisor/projects error:", e);
    return NextResponse.json(
      { error: e.message },
      { status: e.message.includes("Unauthorized") ? 401 : 500 }
    );
  }
}