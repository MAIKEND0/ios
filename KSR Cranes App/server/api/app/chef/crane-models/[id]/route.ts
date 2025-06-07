// src/app/api/app/chef/crane-models/[id]/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/crane-models/[id]
 * Pobiera szczegóły pojedynczego modelu żurawia
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const modelId = parseInt(id, 10);
    
    if (isNaN(modelId)) {
      return NextResponse.json({ error: "Invalid crane model ID" }, { status: 400 });
    }

    const craneModel = await prisma.craneModel.findUnique({
      where: { id: modelId },
      include: {
        brand: {
          select: {
            id: true,
            name: true,
            code: true,
            logoUrl: true,
            website: true,
            description: true,
            foundedYear: true,
            headquarters: true
          }
        },
        type: {
          include: {
            category: {
              select: {
                id: true,
                name: true,
                code: true,
                description: true,
                iconUrl: true
              }
            }
          }
        },
        // Include related assignments if needed for usage statistics
        TaskAssignments: {
          where: {
            Tasks: { isActive: true }
          },
          include: {
            Tasks: {
              select: {
                task_id: true,
                title: true,
                Projects: {
                  select: {
                    project_id: true,
                    title: true
                  }
                }
              }
            },
            Employees: {
              select: {
                employee_id: true,
                name: true
              }
            }
          }
        }
      }
    });

    if (!craneModel) {
      return NextResponse.json({ error: "Crane model not found" }, { status: 404 });
    }

    // Calculate usage statistics
    const currentAssignments = craneModel.TaskAssignments.length;
    const uniqueProjects = new Set(
      craneModel.TaskAssignments.map(ta => ta.Tasks.Projects?.project_id).filter(Boolean)
    ).size;
    const uniqueOperators = new Set(
      craneModel.TaskAssignments.map(ta => ta.employee_id)
    ).size;

    const response = {
      ...craneModel,
      // Usage statistics
      usage_statistics: {
        current_assignments: currentAssignments,
        active_projects: uniqueProjects,
        assigned_operators: uniqueOperators,
        assignments: craneModel.TaskAssignments.map(ta => ({
          task_id: ta.Tasks.task_id,
          task_title: ta.Tasks.title,
          project_id: ta.Tasks.Projects?.project_id,
          project_title: ta.Tasks.Projects?.title,
          operator_name: ta.Employees.name,
          assigned_at: ta.assigned_at
        }))
      }
    };

    return NextResponse.json(response, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/app/chef/crane-models/[id]:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}