// src/app/api/app/chef/projects/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/chef/projects
 * Pobiera wszystkie aktywne projekty z dodatkowymi statystykami
 */
export async function GET(request: Request): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get('search');
    const status = searchParams.get('status');
    const customerId = searchParams.get('customer_id');
    const includeStats = searchParams.get('include_stats') === 'true';
    const limit = parseInt(searchParams.get('limit') || '50');
    const offset = parseInt(searchParams.get('offset') || '0');

    // Build where clause
    const where: any = { isActive: true };
    
    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
        { Customers: { name: { contains: search, mode: 'insensitive' } } }
      ];
    }
    
    if (status) {
      where.status = status;
    }
    
    if (customerId) {
      where.customer_id = parseInt(customerId);
    }

    // Base query
    const projects = await prisma.projects.findMany({
      where,
      orderBy: { created_at: "desc" },
      take: limit,
      skip: offset,
      include: {
        Customers: true,
        Tasks: {
          where: { isActive: true },
          select: {
            task_id: true,
            title: true,
            deadline: true,
            TaskAssignments: {
              include: {
                Employees: {
                  select: {
                    employee_id: true,
                    name: true,
                    email: true,
                    role: true
                  }
                }
              }
            }
          }
        },
        BillingSettings: {
          where: {
            OR: [
              { effective_to: null },
              { effective_to: { gte: new Date() } }
            ]
          },
          orderBy: { effective_from: 'desc' },
          take: 1
        }
      }
    });

    // Add statistics if requested
    const projectsWithStats = includeStats ? await Promise.all(
      projects.map(async (project) => {
        const tasksCount = await prisma.tasks.count({
          where: { project_id: project.project_id, isActive: true }
        });
        
        // Poprawka: użyj findMany z distinct zamiast count z distinct
        const assignedWorkers = await prisma.taskAssignments.findMany({
          where: {
            Tasks: {
              project_id: project.project_id,
              isActive: true
            }
          },
          select: {
            employee_id: true
          },
          distinct: ['employee_id']
        });

        const assignedWorkersCount = assignedWorkers.length;

        const completedTasks = await prisma.tasks.count({
          where: {
            project_id: project.project_id,
            isActive: false // completed tasks are marked as inactive
          }
        });

        const completionPercentage = tasksCount > 0 ? 
          Math.round((completedTasks / (tasksCount + completedTasks)) * 100) : 0;

        return {
          ...project,
          tasks_count: tasksCount,
          assigned_workers_count: assignedWorkersCount,
          completion_percentage: completionPercentage
        };
      })
    ) : projects;

    // Get total count for pagination
    const totalCount = await prisma.projects.count({ where });
    const hasMore = offset + limit < totalCount;

    return NextResponse.json({
      projects: projectsWithStats,
      total_count: totalCount,
      has_more: hasMore
    }, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/chef/projects:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * POST /api/chef/projects
 * Tworzy nowy projekt wraz z ustawieniami rozliczeniowymi
 */
export async function POST(request: Request): Promise<NextResponse> {
  try {
    const body = await request.json();
    
    // Walidacja wymaganych pól
    if (!body.title || !body.customer_id) {
      return NextResponse.json(
        { error: "Missing required fields: title and customer_id" },
        { status: 400 }
      );
    }

    // Sprawdź czy klient istnieje
    const customer = await prisma.customers.findUnique({
      where: { customer_id: parseInt(body.customer_id) }
    });
    
    if (!customer) {
      return NextResponse.json(
        { error: "Customer not found" },
        { status: 404 }
      );
    }

    // Użyj transakcji do utworzenia projektu i ustawień rozliczeniowych
    const result = await prisma.$transaction(async (tx) => {
      // Utwórz projekt
      const newProject = await tx.projects.create({
        data: {
          title: body.title.trim(),
          description: body.description?.trim(),
          start_date: body.start_date ? new Date(body.start_date) : null,
          end_date: body.end_date ? new Date(body.end_date) : null,
          status: body.status || 'afventer',
          customer_id: parseInt(body.customer_id),
          street: body.street?.trim(),
          city: body.city?.trim(),
          zip: body.zip?.trim(),
          isActive: true
        }
      });

      // Utwórz ustawienia rozliczeniowe jeśli podano
      let billingSettings = null;
      if (body.billing_settings) {
        const billing = body.billing_settings;
        billingSettings = await tx.billingSettings.create({
          data: {
            project_id: newProject.project_id,
            normal_rate: parseFloat(billing.normal_rate) || 0,
            weekend_rate: parseFloat(billing.weekend_rate) || 0,
            overtime_rate1: parseFloat(billing.overtime_rate1) || 0,
            overtime_rate2: parseFloat(billing.overtime_rate2) || 0,
            weekend_overtime_rate1: parseFloat(billing.weekend_overtime_rate1) || 0,
            weekend_overtime_rate2: parseFloat(billing.weekend_overtime_rate2) || 0,
            effective_from: billing.effective_from ? new Date(billing.effective_from) : new Date(),
            effective_to: billing.effective_to ? new Date(billing.effective_to) : null
          }
        });
      }

      return { project: newProject, billing_settings: billingSettings };
    });

    // Pobierz pełny projekt z relacjami
    const fullProject = await prisma.projects.findUnique({
      where: { project_id: result.project.project_id },
      include: {
        Customers: true,
        BillingSettings: true
      }
    });

    return NextResponse.json({
      project: fullProject,
      billing_settings: result.billing_settings
    }, { status: 201 });

  } catch (err: any) {
    console.error("Błąd POST /api/chef/projects:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}