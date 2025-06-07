// /api/app/chef/workers/[id]/rates - Zarządzanie stawkami pracownika
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

// GET /api/app/chef/workers/[id]/rates - Pobieranie stawek pracownika
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
      },
      select: {
        employee_id: true,
        name: true,
        operator_normal_rate: true,
        operator_overtime_rate1: true,
        operator_overtime_rate2: true,
        operator_weekend_rate: true,
        created_at: true
      }
    });

    if (!worker) {
      return NextResponse.json({ error: "Worker not found" }, { status: 404 });
    }

    // Pobieranie historii stawek z EmployeeOvertimeSettings
    const overtimeSettings = await prisma.employeeOvertimeSettings.findMany({
      where: { employee_id: workerId },
      orderBy: { effective_from: 'desc' }
    });

    // Formatowanie aktualnych stawek
    const currentRates = [
      {
        id: 1,
        worker_id: workerId,
        rate_type: "hourly",
        rate_amount: Number(worker.operator_normal_rate || 0),
        effective_date: worker.created_at || new Date(),
        end_date: null,
        is_active: true,
        created_at: worker.created_at || new Date()
      },
      {
        id: 2,
        worker_id: workerId,
        rate_type: "overtime",
        rate_amount: Number(worker.operator_overtime_rate1 || 0),
        effective_date: worker.created_at || new Date(),
        end_date: null,
        is_active: true,
        created_at: worker.created_at || new Date()
      },
      {
        id: 3,
        worker_id: workerId,
        rate_type: "weekend",
        rate_amount: Number(worker.operator_weekend_rate || 0),
        effective_date: worker.created_at || new Date(),
        end_date: null,
        is_active: true,
        created_at: worker.created_at || new Date()
      }
    ];

    // Historia stawek z tabeli EmployeeOvertimeSettings
    const ratesHistory = overtimeSettings.map((setting, index) => ({
      id: setting.id,
      old_rate: index < overtimeSettings.length - 1 ? Number(overtimeSettings[index + 1].overtime_rate1) : 0,
      new_rate: Number(setting.overtime_rate1),
      change_date: setting.effective_from,
      reason: "Rate adjustment",
      changed_by: "System" // TODO: Track who made the change
    }));

    return NextResponse.json({
      worker_id: workerId,
      worker_name: worker.name,
      current_rates: currentRates,
      rates_history: ratesHistory
    });

  } catch (error: any) {
    console.error("Error fetching worker rates:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PUT /api/app/chef/workers/[id]/rates - Aktualizacja stawek pracownika
export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);
    const body = await request.json();

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    // Walidacja danych wejściowych
    if (!Array.isArray(body) || body.length === 0) {
      return NextResponse.json({ 
        error: "Rates array is required" 
      }, { status: 400 });
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

    // Przygotowanie danych do aktualizacji
    const updateData: any = {};
    const effectiveDate = new Date();

    // Zapisanie starych wartości dla historii
    const oldRates = {
      normal: Number(worker.operator_normal_rate || 0),
      overtime1: Number(worker.operator_overtime_rate1 || 0),
      overtime2: Number(worker.operator_overtime_rate2 || 0),
      weekend: Number(worker.operator_weekend_rate || 0)
    };

    // Przetwarzanie nowych stawek
    for (const rate of body) {
      if (!rate.rate_type || rate.rate_amount === undefined) {
        continue;
      }

      const amount = Number(rate.rate_amount);
      if (isNaN(amount) || amount < 0) {
        return NextResponse.json({ 
          error: `Invalid rate amount for ${rate.rate_type}` 
        }, { status: 400 });
      }

      switch (rate.rate_type) {
        case 'hourly':
          updateData.operator_normal_rate = amount;
          break;
        case 'overtime':
          updateData.operator_overtime_rate1 = amount;
          break;
        case 'overtime2':
          updateData.operator_overtime_rate2 = amount;
          break;
        case 'weekend':
          updateData.operator_weekend_rate = amount;
          break;
      }
    }

    // Aktualizacja głównej tabeli pracowników
    const updatedWorker = await prisma.employees.update({
      where: { employee_id: workerId },
      data: updateData
    });

    // Sprawdzenie czy nastąpiły znaczące zmiany
    const hasSignificantChanges = 
      Math.abs(Number(updatedWorker.operator_normal_rate || 0) - oldRates.normal) > 0.01 ||
      Math.abs(Number(updatedWorker.operator_overtime_rate1 || 0) - oldRates.overtime1) > 0.01 ||
      Math.abs(Number(updatedWorker.operator_overtime_rate2 || 0) - oldRates.overtime2) > 0.01 ||
      Math.abs(Number(updatedWorker.operator_weekend_rate || 0) - oldRates.weekend) > 0.01;

    // Jeśli nastąpiły zmiany, zapisz w historii
    if (hasSignificantChanges) {
      try {
        await prisma.employeeOvertimeSettings.create({
          data: {
            employee_id: workerId,
            overtime_rate1: Number(updatedWorker.operator_overtime_rate1 || 0),
            overtime_rate2: Number(updatedWorker.operator_overtime_rate2 || 0),
            weekend_overtime_rate1: Number(updatedWorker.operator_weekend_rate || 0),
            weekend_overtime_rate2: Number(updatedWorker.operator_weekend_rate || 0),
            effective_from: effectiveDate,
            start_time: new Date(`1970-01-01T00:00:00Z`),
            end_time: new Date(`1970-01-01T23:59:59Z`)
          }
        });
      } catch (error) {
        console.warn("Could not save rate history:", error);
      }
    }

    console.log(`Rates updated for worker ${workerId}:`, updateData);

    // Formatowanie odpowiedzi
    const updatedRates = [
      {
        id: 1,
        worker_id: workerId,
        rate_type: "hourly",
        rate_amount: Number(updatedWorker.operator_normal_rate || 0),
        effective_date: effectiveDate,
        end_date: null,
        is_active: true,
        created_at: effectiveDate
      },
      {
        id: 2,
        worker_id: workerId,
        rate_type: "overtime",
        rate_amount: Number(updatedWorker.operator_overtime_rate1 || 0),
        effective_date: effectiveDate,
        end_date: null,
        is_active: true,
        created_at: effectiveDate
      },
      {
        id: 3,
        worker_id: workerId,
        rate_type: "weekend",
        rate_amount: Number(updatedWorker.operator_weekend_rate || 0),
        effective_date: effectiveDate,
        end_date: null,
        is_active: true,
        created_at: effectiveDate
      }
    ];

    return NextResponse.json(updatedRates);

  } catch (error: any) {
    console.error("Error updating worker rates:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST /api/app/chef/workers/[id]/rates - Dodawanie nowej stawki (alternatywna implementacja)
export async function POST(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);
    const body = await request.json();

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    const { rate_type, rate_amount, effective_date, reason } = body;

    if (!rate_type || rate_amount === undefined) {
      return NextResponse.json({ 
        error: "rate_type and rate_amount are required" 
      }, { status: 400 });
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

    const amount = Number(rate_amount);
    if (isNaN(amount) || amount < 0) {
      return NextResponse.json({ 
        error: "Invalid rate amount" 
      }, { status: 400 });
    }

    const effectiveDate = effective_date ? new Date(effective_date) : new Date();

    // Aktualizacja odpowiedniej stawki
    const updateData: any = {};
    let oldRate = 0;

    switch (rate_type) {
      case 'hourly':
        oldRate = Number(worker.operator_normal_rate || 0);
        updateData.operator_normal_rate = amount;
        break;
      case 'overtime':
        oldRate = Number(worker.operator_overtime_rate1 || 0);
        updateData.operator_overtime_rate1 = amount;
        break;
      case 'weekend':
        oldRate = Number(worker.operator_weekend_rate || 0);
        updateData.operator_weekend_rate = amount;
        break;
      default:
        return NextResponse.json({ 
          error: "Invalid rate_type. Allowed: hourly, overtime, weekend" 
        }, { status: 400 });
    }

    // Aktualizacja w bazie
    await prisma.employees.update({
      where: { employee_id: workerId },
      data: updateData
    });

    console.log(`New ${rate_type} rate set for worker ${workerId}: ${oldRate} -> ${amount} DKK`);

    // Zwracanie informacji o nowej stawce
    const newRate = {
      id: Date.now(), // Temporary ID
      worker_id: workerId,
      rate_type,
      rate_amount: amount,
      effective_date: effectiveDate,
      end_date: null,
      is_active: true,
      created_at: new Date(),
      old_rate: oldRate,
      change_reason: reason || "Rate adjustment"
    };

    return NextResponse.json(newRate, { status: 201 });

  } catch (error: any) {
    console.error("Error adding new worker rate:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}