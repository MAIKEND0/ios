// /api/app/chef/workers/[id]/status - Zarządzanie statusem pracownika
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

// PUT /api/app/chef/workers/[id]/status - Aktualizacja statusu pracownika
export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);
    const body = await request.json();

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    const { status } = body;

    if (!status) {
      return NextResponse.json({ error: "Status is required" }, { status: 400 });
    }

    // Walidacja statusu
    const allowedStatuses = ['aktiv', 'inaktiv', 'sygemeldt', 'ferie', 'opsagt'];
    if (!allowedStatuses.includes(status)) {
      return NextResponse.json({ 
        error: `Invalid status. Allowed values: ${allowedStatuses.join(', ')}` 
      }, { status: 400 });
    }

    // Sprawdzenie czy pracownik istnieje
    const existingWorker = await prisma.employees.findUnique({
      where: { 
        employee_id: workerId,
        role: { in: ['arbejder', 'byggeleder'] as any }
      }
    });

    if (!existingWorker) {
      return NextResponse.json({ error: "Worker not found" }, { status: 404 });
    }

    // Mapowanie statusu na pole is_activated
    const isActivated = mapStatusToActivated(status);
    
    // Dodatkowe działania w zależności od statusu
    const updateData: any = {
      is_activated: isActivated
    };

    // Jeśli pracownik jest zwalniany, dodaj timestamp
    if (status === 'opsagt') {
      // Można dodać pole termination_date w przyszłości
      updateData.is_activated = false;
    }

    // Aktualizacja w bazie danych
    const updatedWorker = await prisma.employees.update({
      where: { employee_id: workerId },
      data: updateData
    });

    // Logowanie zmiany statusu
    console.log(`Worker ${workerId} status changed to: ${status} (activated: ${isActivated})`);

    // TODO: Wysłanie notyfikacji do pracownika o zmianie statusu
    // TODO: Logowanie w audit log

    // Mapowanie do formatu iOS
    const mappedWorker = {
      employee_id: updatedWorker.employee_id,
      name: updatedWorker.name,
      email: updatedWorker.email,
      phone: updatedWorker.phone_number,
      address: updatedWorker.address,
      hourly_rate: Number(updatedWorker.operator_normal_rate || 0),
      employment_type: mapRoleToEmploymentType(updatedWorker.role),
      status: status, // Używamy przekazanego statusu
      profile_picture_url: updatedWorker.profilePictureUrl,
      created_at: updatedWorker.created_at,
      last_active: null,
      stats: {
        hours_this_week: 0,
        hours_this_month: 0,
        active_projects: 0,
        completed_tasks: 0,
        approval_rate: 1.0,
        last_timesheet_date: null
      }
    };

    return NextResponse.json(mappedWorker);

  } catch (error: any) {
    console.error("Error updating worker status:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// GET /api/app/chef/workers/[id]/status - Pobieranie historii statusów (opcjonalne)
export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    // Sprawdzenie czy pracownik istnieje
    const worker = await prisma.employees.findUnique({
      where: { 
        employee_id: workerId,
        role: { in: ['arbejder', 'byggeleder'] as any }
      }
    });

    if (!worker) {
      return NextResponse.json({ error: "Worker not found" }, { status: 404 });
    }

    // Aktualny status
    const currentStatus = worker.is_activated ? "aktiv" : "inaktiv";

    // TODO: W przyszłości można dodać tabelę status_history
    // Obecnie zwracamy tylko aktualny status
    const statusInfo = {
      worker_id: workerId,
      current_status: currentStatus,
      last_updated: worker.created_at, // Placeholder
      status_history: [] // TODO: Implementacja historii statusów
    };

    return NextResponse.json(statusInfo);

  } catch (error: any) {
    console.error("Error fetching worker status:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// Helper functions
function mapStatusToActivated(status: string): boolean {
  switch (status) {
    case 'aktiv':
      return true;
    case 'inaktiv':
    case 'sygemeldt':
    case 'ferie':
    case 'opsagt':
      return false;
    default:
      return true; // Default to active for unknown statuses
  }
}

function mapRoleToEmploymentType(role: string): string {
  switch (role) {
    case 'arbejder': return 'fuld_tid';
    case 'byggeleder': return 'fuld_tid';
    default: return 'fuld_tid';
  }
}