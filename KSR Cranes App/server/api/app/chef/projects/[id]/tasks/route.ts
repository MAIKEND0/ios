// src/app/api/app/chef/projects/[id]/tasks/route.ts
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * POST /api/app/chef/projects/[id]/tasks
 * Tworzy nowe zadanie dla konkretnego projektu z obsługą equipment requirements
 */
export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const projectId = parseInt(id, 10);
    
    if (isNaN(projectId)) {
      return NextResponse.json({ error: "Invalid project ID" }, { status: 400 });
    }

    const body = await request.json();
    
    // Walidacja wymaganych pól
    if (!body.title) {
      return NextResponse.json(
        { error: "Missing required field: title" },
        { status: 400 }
      );
    }

    // Sprawdź czy projekt istnieje
    const project = await prisma.projects.findUnique({
      where: { project_id: projectId, isActive: true }
    });
    
    if (!project) {
      return NextResponse.json(
        { error: "Project not found" },
        { status: 404 }
      );
    }

    console.log("[API] Creating task with equipment requirements:", {
      title: body.title,
      required_crane_types: body.required_crane_types,
      preferred_crane_model_id: body.preferred_crane_model_id,
      equipment_category_id: body.equipment_category_id,
      equipment_brand_id: body.equipment_brand_id
    });

    // Użyj transakcji
    const result = await prisma.$transaction(async (tx) => {
      let supervisorId = body.supervisor_id ? parseInt(body.supervisor_id) : null;
      
      // Jeśli podano external supervisor data, utwórz nowego pracownika
      if (!supervisorId && body.supervisor_email && body.supervisor_name) {
        const existingSupervisor = await tx.employees.findUnique({
          where: { email: body.supervisor_email }
        });
        
        if (existingSupervisor) {
          supervisorId = existingSupervisor.employee_id;
        } else {
          const newSupervisor = await tx.employees.create({
            data: {
              email: body.supervisor_email,
              name: body.supervisor_name,
              role: 'byggeleder',
              password_hash: '',
              phone_number: body.supervisor_phone || null,
              is_activated: false,
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

      // Utwórz zadanie z equipment requirements
      const newTask = await tx.tasks.create({
        data: {
          project_id: projectId,
          title: body.title.trim(),
          description: body.description?.trim(),
          deadline: body.deadline ? new Date(body.deadline) : null,
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

      return newTask;
    });

    // Pobierz pełne zadanie z relacjami INCLUDING equipment relations
    const fullTask = await prisma.tasks.findUnique({
      where: { task_id: result.task_id },
      include: {
        Projects: {
          select: {
            project_id: true,
            title: true,
            status: true
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
            maxRadius: true
          }
        },
        CraneCategory: {
          select: {
            id: true,
            name: true,
            code: true,
            description: true
          }
        },
        CraneBrand: {
          select: {
            id: true,
            name: true,
            code: true,
            logoUrl: true
          }
        }
      }
    });

    return NextResponse.json(fullTask, { status: 201 });

  } catch (err: any) {
    console.error("Błąd POST /api/app/chef/projects/[id]/tasks:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}