// src/app/api/app/chef/tasks/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";
import { createTaskAssignmentNotification } from "../../../../../lib/notificationService";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/tasks
 * Pobiera zadania z filtrami i opcjami + equipment requirements
 */
export async function GET(request: Request): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const projectId = searchParams.get('project_id');
    const supervisorId = searchParams.get('supervisor_id');
    const isActive = searchParams.get('is_active');
    const search = searchParams.get('search');
    const includeProject = searchParams.get('include_project') !== 'false';
    const includeAssignments = searchParams.get('include_assignments') !== 'false';
    const includeEquipment = searchParams.get('include_equipment') !== 'false';
    const limit = parseInt(searchParams.get('limit') || '50');
    const offset = parseInt(searchParams.get('offset') || '0');
    
    // Build where clause
    const where: any = {};
    
    if (projectId) {
      where.project_id = parseInt(projectId);
    }
    
    if (supervisorId) {
      where.supervisor_id = parseInt(supervisorId);
    }
    
    if (isActive !== null) {
      where.isActive = isActive === 'true';
    } else {
      where.isActive = true; // Default to active tasks
    }
    
    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
        { supervisor_name: { contains: search, mode: 'insensitive' } }
      ];
    }

    const tasks = await prisma.tasks.findMany({
      where,
      orderBy: { created_at: "desc" },
      take: limit,
      skip: offset,
      include: {
        ...(includeProject && {
          Projects: {
            select: {
              project_id: true,
              title: true,
              status: true,
              Customers: {
                select: {
                  customer_id: true,
                  name: true
                }
              }
            }
          }
        }),
        ...(includeAssignments && {
          TaskAssignments: {
            include: {
              Employees: {
                select: {
                  employee_id: true,
                  name: true,
                  email: true,
                  role: true,
                  phone_number: true,
                  profilePictureUrl: true
                }
              },
              CraneModel: {
                select: {
                  id: true,
                  name: true,
                  code: true
                }
              }
            }
          }
        }),
        // Supervisor employee details if internal
        Employees: {
          select: {
            employee_id: true,
            name: true,
            email: true,
            phone_number: true,
            role: true
          }
        },
        // ✅ DODANO: Include equipment relations
        ...(includeEquipment && {
          CraneModel: {
            select: {
              id: true,
              name: true,
              code: true,
              description: true,
              maxLoadCapacity: true,
              maxHeight: true,
              maxRadius: true,
              brand: {
                select: {
                  id: true,
                  name: true,
                  code: true,
                  logoUrl: true
                }
              },
              type: {
                select: {
                  id: true,
                  name: true,
                  code: true,
                  description: true
                }
              }
            }
          },
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
              website: true,
              description: true
            }
          }
        })
      }
    });

    // Get total count for pagination
    const totalCount = await prisma.tasks.count({ where });
    const hasMore = offset + limit < totalCount;

    // Transform tasks to include assignment count and equipment info
    const tasksWithStats = tasks.map(task => {
      // Parse required certificates from crane category
      let requiredCertificates: number[] = [];
      if (task.CraneCategory?.required_certificates) {
        try {
          const requiredCerts = JSON.parse(task.CraneCategory.required_certificates as string);
          if (Array.isArray(requiredCerts)) {
            requiredCertificates = requiredCerts.map(id => parseInt(id)).filter(id => !isNaN(id));
          }
        } catch (e) {
          console.error("[API] Error parsing required certificates for task", task.task_id, ":", e);
        }
      }

      return {
        ...task,
        assignments_count: task.TaskAssignments?.length || 0,
        project_title: task.Projects?.title || "No Project",
        // ✅ DODANO: Equipment summary for quick reference
        equipment_summary: {
          required_crane_types: task.required_crane_types ? 
            (Array.isArray(task.required_crane_types) ? task.required_crane_types : []) : [],
          has_preferred_model: !!task.preferred_crane_model_id,
          has_category: !!task.equipment_category_id,
          has_brand: !!task.equipment_brand_id,
          // Include full objects for convenience if loaded
          preferred_crane_model: task.CraneModel || null,
          equipment_category: task.CraneCategory || null,
          equipment_brand: task.CraneBrand || null
        },
        // ✅ ADD: Include required certificates from category
        required_certificates: requiredCertificates
      };
    });

    return NextResponse.json({
      tasks: tasksWithStats,
      total_count: totalCount,
      has_more: hasMore
    }, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/app/chef/tasks:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * POST /api/app/chef/tasks
 * Tworzy nowe zadanie z możliwością utworzenia external supervisora + equipment requirements
 */
export async function POST(request: Request): Promise<NextResponse> {
  try {
    const body = await request.json();
    
    // Walidacja wymaganych pól
    if (!body.title || !body.project_id) {
      return NextResponse.json(
        { error: "Missing required fields: title and project_id" },
        { status: 400 }
      );
    }

    // Sprawdź czy projekt istnieje
    const project = await prisma.projects.findUnique({
      where: { project_id: parseInt(body.project_id) }
    });
    
    if (!project) {
      return NextResponse.json(
        { error: "Project not found" },
        { status: 404 }
      );
    }

    console.log("[API] Creating task with equipment requirements:", {
      title: body.title,
      project_id: body.project_id,
      required_crane_types: body.required_crane_types,
      preferred_crane_model_id: body.preferred_crane_model_id,
      equipment_category_id: body.equipment_category_id,
      equipment_brand_id: body.equipment_brand_id
    });

    // Użyj transakcji
    const result = await prisma.$transaction(async (tx) => {
      let supervisorId = body.supervisor_id ? parseInt(body.supervisor_id) : null;
      
      // Jeśli podano external supervisor data, ale nie ma supervisor_id, utwórz nowego pracownika
      if (!supervisorId && body.supervisor_email && body.supervisor_name) {
        // Sprawdź czy pracownik o tym emailu już istnieje
        const existingSupervisor = await tx.employees.findUnique({
          where: { email: body.supervisor_email }
        });
        
        if (existingSupervisor) {
          supervisorId = existingSupervisor.employee_id;
        } else {
          // Utwórz nowego supervisora jako external employee
          const newSupervisor = await tx.employees.create({
            data: {
              email: body.supervisor_email,
              name: body.supervisor_name,
              role: 'byggeleder', // default supervisor role
              password_hash: '', // External supervisor, no login needed
              phone_number: body.supervisor_phone || null,
              is_activated: false, // External supervisor, not activated for app login
              address: null,
              emergency_contact: null,
              cpr_number: null,
              birth_date: null,
              has_driving_license: null,
              driving_license_category: null,
              driving_license_expiration: null,
              profilePictureUrl: null
            }
          });
          supervisorId = newSupervisor.employee_id;
        }
      }

      // ✅ DODANO: Przygotuj equipment data
      const equipmentData: any = {};
      
      // Required crane types (array of IDs)
      if (body.required_crane_types && Array.isArray(body.required_crane_types)) {
        equipmentData.required_crane_types = body.required_crane_types;
      }
      
      // Preferred crane model
      if (body.preferred_crane_model_id) {
        equipmentData.preferred_crane_model_id = parseInt(body.preferred_crane_model_id);
      }
      
      // Equipment category
      if (body.equipment_category_id) {
        equipmentData.equipment_category_id = parseInt(body.equipment_category_id);
      }
      
      // Equipment brand
      if (body.equipment_brand_id) {
        equipmentData.equipment_brand_id = parseInt(body.equipment_brand_id);
      }

      // ✅ Management Calendar Fields - validate enums
      const taskStatus = body.status && ['planned', 'in_progress', 'completed', 'cancelled', 'overdue'].includes(body.status) 
        ? body.status : 'planned';
      const taskPriority = body.priority && ['low', 'medium', 'high', 'critical'].includes(body.priority) 
        ? body.priority : 'medium';

      // Utwórz zadanie z equipment requirements i management calendar fields
      const newTask = await tx.tasks.create({
        data: {
          project_id: parseInt(body.project_id),
          title: body.title.trim(),
          description: body.description?.trim(),
          deadline: body.deadline ? new Date(body.deadline) : null,
          start_date: body.start_date ? new Date(body.start_date) : null,
          status: taskStatus,
          priority: taskPriority,
          estimated_hours: body.estimated_hours ? parseFloat(body.estimated_hours) : null,
          required_operators: body.required_operators ? parseInt(body.required_operators) : 1,
          client_equipment_info: body.client_equipment_info?.trim() || null,
          supervisor_id: supervisorId,
          supervisor_name: body.supervisor_name?.trim(),
          supervisor_email: body.supervisor_email?.trim(),
          supervisor_phone: body.supervisor_phone?.trim(),
          isActive: true,
          ...equipmentData  // ✅ DODANO: Include equipment fields
        }
      });

      console.log("[API] ✅ Task created with equipment:", {
        task_id: newTask.task_id,
        required_crane_types: newTask.required_crane_types,
        preferred_crane_model_id: newTask.preferred_crane_model_id,
        equipment_category_id: newTask.equipment_category_id,
        equipment_brand_id: newTask.equipment_brand_id
      });

      // Jeśli podano employee_ids, utwórz task assignments
      if (body.employee_ids && Array.isArray(body.employee_ids)) {
        const assignments = await Promise.all(
          body.employee_ids.map(async (employeeId: number) => {
            // Sprawdź czy pracownik istnieje
            const employee = await tx.employees.findUnique({
              where: { employee_id: employeeId }
            });
            
            if (!employee) {
              throw new Error(`Employee with ID ${employeeId} not found`);
            }

            return tx.taskAssignments.create({
              data: {
                task_id: newTask.task_id,
                employee_id: employeeId,
                assigned_at: new Date(),
                // ✅ ENHANCED: Use preferred crane model if available
                crane_model_id: equipmentData.preferred_crane_model_id || null
              }
            });
          })
        );

      }

      return {
        task: newTask,
        assignedEmployeeIds: body.employee_ids || []
      };
    });

    // Create notifications for assigned employees after transaction
    if (result.assignedEmployeeIds && Array.isArray(result.assignedEmployeeIds)) {
      try {
        await Promise.all(
          result.assignedEmployeeIds.map((employeeId: number) =>
            createTaskAssignmentNotification(
              employeeId,
              result.task.task_id,
              result.task.title,
              parseInt(body.project_id)
            )
          )
        );
        console.log(`[API] Created ${result.assignedEmployeeIds.length} task assignment notifications for task ${result.task.task_id}`);
      } catch (notificationError) {
        console.error("[API] Failed to create task assignment notifications:", notificationError);
        // Don't fail the entire request if notifications fail
      }
    }

    // Pobierz pełne zadanie z relacjami INCLUDING equipment relations
    const fullTask = await prisma.tasks.findUnique({
      where: { task_id: result.task.task_id },
      include: {
        Projects: {
          select: {
            project_id: true,
            title: true,
            status: true
          }
        },
        TaskAssignments: {
          include: {
            Employees: {
              select: {
                employee_id: true,
                name: true,
                email: true,
                role: true
              }
            },
            CraneModel: {
              select: {
                id: true,
                name: true,
                code: true
              }
            }
          }
        },
        Employees: {
          select: {
            employee_id: true,
            name: true,
            email: true,
            phone_number: true,
            role: true
          }
        },
        // ✅ DODANO: Include equipment relations
        CraneModel: {
          select: {
            id: true,
            name: true,
            code: true,
            description: true,
            maxLoadCapacity: true,
            maxHeight: true,
            maxRadius: true,
            brand: {
              select: {
                id: true,
                name: true,
                code: true,
                logoUrl: true
              }
            },
            type: {
              select: {
                id: true,
                name: true,
                code: true,
                description: true
              }
            }
          }
        },
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
            website: true,
            description: true
          }
        }
      }
    });

    // Parse required certificates from crane category
    let requiredCertificates: number[] = [];
    if (fullTask?.CraneCategory?.required_certificates) {
      try {
        const requiredCerts = JSON.parse(fullTask.CraneCategory.required_certificates as string);
        if (Array.isArray(requiredCerts)) {
          requiredCertificates = requiredCerts.map(id => parseInt(id)).filter(id => !isNaN(id));
        }
      } catch (e) {
        console.error("[API] Error parsing required certificates:", e);
      }
    }

    // ✅ ENHANCED: Transform response to include parsed equipment info
    const enhancedTask = {
      ...fullTask,
      // ✅ Parse required_crane_types JSON field for convenience
      equipment_requirements: {
        required_crane_types: fullTask?.required_crane_types ? 
          (Array.isArray(fullTask.required_crane_types) ? fullTask.required_crane_types : []) : [],
        preferred_crane_model_id: fullTask?.preferred_crane_model_id,
        equipment_category_id: fullTask?.equipment_category_id,
        equipment_brand_id: fullTask?.equipment_brand_id,
        // Include full objects for convenience
        preferred_crane_model: fullTask?.CraneModel,
        equipment_category: fullTask?.CraneCategory,
        equipment_brand: fullTask?.CraneBrand
      },
      // ✅ ADD: Include required certificates from category
      required_certificates: requiredCertificates
    };

    console.log("[API] ✅ Returning created task with equipment:", {
      task_id: enhancedTask.task_id,
      equipment_requirements: enhancedTask.equipment_requirements
    });

    return NextResponse.json(enhancedTask, { status: 201 });

  } catch (err: any) {
    console.error("Błąd POST /api/app/chef/tasks:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}
