import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";

export async function GET(req: NextRequest) {
  try {
    // 1) Pobranie payloadu z middleware (zawiera user.id i role)
    const payloadHeader = req.headers.get("x-decoded-user-payload");
    if (!payloadHeader) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }
    const { id, role } = JSON.parse(payloadHeader);
    const employeeId = Number(id);

    // 2) Opcjonalny filtr po projekcie
    const url = new URL(req.url);
    const projectParam = url.searchParams.get("project_id");
    const projectFilter = projectParam
      ? { project_id: Number(projectParam) }
      : {};

    let tasks;
    
    // 3) Różna logika dla supervisora (byggeleder) i zwykłego pracownika
    if (role === "byggeleder") {
      // Dla supervisora: Pobieramy zadania, gdzie jest on supervisorem
      tasks = await prisma.tasks.findMany({
        where: {
          supervisor_id: employeeId,
          isActive: true,
          ...projectFilter
        },
        orderBy: { task_id: "desc" },
        include: {
          Projects: {
            select: {
              project_id: true,
              title: true,
              description: true,
              start_date: true,
              end_date: true,
              street: true,
              city: true,
              zip: true,
              status: true,
              Customers: {
                select: {
                  customer_id: true,
                  name: true
                }
              }
            }
          },
          // Dodajemy relacje do nowych pól
          CraneCategory: {
            select: {
              id: true,
              name: true,
              code: true,
              description: true,
              iconUrl: true
            }
          },
          CraneBrand: {
            select: {
              id: true,
              name: true,
              code: true,
              logoUrl: true,
              website: true
            }
          },
          CraneModel: {
            select: {
              id: true,
              name: true,
              code: true,
              description: true,
              maxLoadCapacity: true,
              maxHeight: true,
              maxRadius: true,
              enginePower: true,
              specifications: true,
              imageUrl: true,
              brochureUrl: true,
              videoUrl: true
            }
          }
        }
      });
      
      console.log(`[API] Fetched ${tasks.length} supervisor tasks for employeeId: ${employeeId}`);
    } else {
      // Dla pracownika: Pobieramy zadania przypisane do pracownika
      tasks = await prisma.tasks.findMany({
        where: {
          TaskAssignments: {
            some: { employee_id: employeeId }
          },
          ...projectFilter
        },
        orderBy: { task_id: "desc" },
        include: {
          Projects: {
            select: {
              project_id: true,
              title: true,
              description: true,
              start_date: true,
              end_date: true,
              street: true,
              city: true,
              zip: true,
              status: true,
              Customers: {
                select: {
                  customer_id: true,
                  name: true
                }
              }
            }
          },
          TaskAssignments: {
            where: { employee_id: employeeId },
            include: { 
              Employees: true,
              CraneModel: {
                select: {
                  id: true,
                  name: true,
                  code: true,
                  description: true,
                  maxLoadCapacity: true,
                  maxHeight: true,
                  maxRadius: true,
                  enginePower: true,
                  specifications: true,
                  imageUrl: true,
                  brochureUrl: true,
                  videoUrl: true
                }
              }
            }
          },
          // Dodajemy relacje do nowych pól
          CraneCategory: {
            select: {
              id: true,
              name: true,
              code: true,
              description: true,
              iconUrl: true
            }
          },
          CraneBrand: {
            select: {
              id: true,
              name: true,
              code: true,
              logoUrl: true,
              website: true
            }
          },
          CraneModel: {
            select: {
              id: true,
              name: true,
              code: true,
              description: true,
              maxLoadCapacity: true,
              maxHeight: true,
              maxRadius: true,
              enginePower: true,
              specifications: true,
              imageUrl: true,
              brochureUrl: true,
              videoUrl: true
            }
          }
        }
      });
      
      console.log(`[API] Fetched ${tasks.length} assigned tasks for employeeId: ${employeeId}`);
    }

    // 4) Formatowanie odpowiedzi dla frontendu
    const formattedTasks = tasks.map(task => {
      console.log(`[API] Task ${task.task_id}, Project: ${JSON.stringify(task.Projects)}`);
      return {
        task_id: task.task_id,
        title: task.title,
        description: task.description,
        deadline: task.deadline ? task.deadline.toISOString() : null,
        created_at: task.created_at ? task.created_at.toISOString() : null,
        
        // Supervisor info
        supervisor_id: task.supervisor_id,
        supervisor_email: task.supervisor_email,
        supervisor_phone: task.supervisor_phone,
        supervisor_name: task.supervisor_name,
        
        // Crane requirements - nowe pola
        required_crane_types: task.required_crane_types || null,
        preferred_crane_model_id: task.preferred_crane_model_id,
        equipment_category_id: task.equipment_category_id,
        equipment_brand_id: task.equipment_brand_id,
        
        // Crane details - relacje
        crane_category: task.CraneCategory ? {
          id: task.CraneCategory.id,
          name: task.CraneCategory.name,
          code: task.CraneCategory.code,
          description: task.CraneCategory.description,
          iconUrl: task.CraneCategory.iconUrl
        } : null,
        
        crane_brand: task.CraneBrand ? {
          id: task.CraneBrand.id,
          name: task.CraneBrand.name,
          code: task.CraneBrand.code,
          logoUrl: task.CraneBrand.logoUrl,
          website: task.CraneBrand.website
        } : null,
        
        preferred_crane_model: task.CraneModel ? {
          id: task.CraneModel.id,
          name: task.CraneModel.name,
          code: task.CraneModel.code,
          description: task.CraneModel.description,
          maxLoadCapacity: task.CraneModel.maxLoadCapacity,
          maxHeight: task.CraneModel.maxHeight,
          maxRadius: task.CraneModel.maxRadius,
          enginePower: task.CraneModel.enginePower,
          specifications: task.CraneModel.specifications,
          imageUrl: task.CraneModel.imageUrl,
          brochureUrl: task.CraneModel.brochureUrl,
          videoUrl: task.CraneModel.videoUrl
        } : null,
        
        // Project info
        project: task.Projects ? {
          project_id: task.Projects.project_id,
          title: task.Projects.title,
          description: task.Projects.description,
          start_date: task.Projects.start_date?.toISOString() || null,
          end_date: task.Projects.end_date?.toISOString() || null,
          street: task.Projects.street,
          city: task.Projects.city,
          zip: task.Projects.zip,
          status: task.Projects.status,
          customer: task.Projects.Customers ? {
            customer_id: task.Projects.Customers.customer_id,
            name: task.Projects.Customers.name
          } : null
        } : null,
        
        // Task assignments (tylko dla pracowników)
        assignments: role !== "byggeleder" && task.TaskAssignments ? task.TaskAssignments.map(assignment => ({
          assignment_id: assignment.assignment_id,
          assigned_at: assignment.assigned_at?.toISOString() || null,
          crane_model_id: assignment.crane_model_id,
          assigned_crane_model: assignment.CraneModel ? {
            id: assignment.CraneModel.id,
            name: assignment.CraneModel.name,
            code: assignment.CraneModel.code,
            description: assignment.CraneModel.description,
            maxLoadCapacity: assignment.CraneModel.maxLoadCapacity,
            maxHeight: assignment.CraneModel.maxHeight,
            maxRadius: assignment.CraneModel.maxRadius,
            enginePower: assignment.CraneModel.enginePower,
            specifications: assignment.CraneModel.specifications,
            imageUrl: assignment.CraneModel.imageUrl,
            brochureUrl: assignment.CraneModel.brochureUrl,
            videoUrl: assignment.CraneModel.videoUrl
          } : null
        })) : []
      };
    });

    return NextResponse.json(formattedTasks);
  } catch (e: any) {
    console.error("[API] Error in tasks endpoint:", e);
    return NextResponse.json(
      { error: e.message || "Internal server error" },
      { status: e.message === "Unauthorized" ? 401 : 500 }
    );
  }
}