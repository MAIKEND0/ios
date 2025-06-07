// src/app/api/app/supervisor/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import dayjs from "dayjs";
import isoWeek from "dayjs/plugin/isoWeek";
import jwt from "jsonwebtoken";

dayjs.extend(isoWeek);

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

    const { searchParams } = new URL(req.url);
    const mondayParam = searchParams.get("selectedMonday");
    const isDraftParam = searchParams.get("is_draft");
    const allPendingParam = searchParams.get("allPending"); // Nowy parametr

    // Jeśli żądany jest widok wszystkich wpisów (allPending=true)
    if (allPendingParam === "true") {
      const where: any = {
        Tasks: {
          supervisor_id: supervisorId
        },
        confirmation_status: { not: "confirmed" } // Tylko niezatwierdzone
      };
      
      if (isDraftParam != null) {
        where.is_draft = isDraftParam === "true";
      }

      const entries = await prisma.workEntries.findMany({
        where,
        include: { 
          Tasks: {
            include: {
              Projects: {
                include: {
                  Customers: true
                }
              }
            }
          },
          Employees: true
        },
        orderBy: { work_date: "desc" },
      });

      console.log(
        `[API] Fetched all pending entries for supervisor ${supervisorId}: ${entries.length} entries`
      );
      return NextResponse.json(entries);
    }

    // Jeśli żądany jest filtr po tygodniu (istniejąca funkcjonalność)
    if (!mondayParam) {
      return NextResponse.json(
        { error: "selectedMonday is required" },
        { status: 400 }
      );
    }

    const monday = dayjs(mondayParam, "YYYY-MM-DD");
    if (!monday.isValid()) {
      return NextResponse.json({ error: "Invalid date" }, { status: 400 });
    }

    const start = monday.startOf("isoWeek").toDate();
    const end = monday.endOf("isoWeek").toDate();

    const where: any = {
      Tasks: {
        supervisor_id: supervisorId
      },
      work_date: { gte: start, lte: end },
    };
    if (isDraftParam != null) {
      where.is_draft = isDraftParam === "true";
    }

    const entries = await prisma.workEntries.findMany({
      where,
      include: { 
        Tasks: {
          include: {
            Projects: {
              include: {
                Customers: true
              }
            }
          }
        },
        Employees: true
      },
      orderBy: { work_date: "desc" },
    });

    console.log(
      `[API] Fetched entries for supervisor ${supervisorId} for week of ${mondayParam}: ${entries.length} entries`
    );
    return NextResponse.json(entries);
  } catch (e: any) {
    console.error("GET /api/app/supervisor error:", e);
    return NextResponse.json(
      { error: e.message },
      { status: e.message.includes("Unauthorized") ? 401 : 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    if (!process.env.JWT_SECRET) {
      throw new Error("JWT_SECRET is missing");
    }

    const { id: supervisorId } = await authenticate(req);

    const { entries } = await req.json();
    if (!Array.isArray(entries)) {
      return NextResponse.json(
        { error: "entries must be an array" },
        { status: 400 }
      );
    }

    const updatedEntries: any[] = [];

    await Promise.all(
      entries.map(async (e: any) => {
        // Validate required fields
        if (!e.entry_id) {
          throw new Error("entry_id is required");
        }
        if (!e.confirmation_status) {
          throw new Error("confirmation_status is required");
        }
        if (!e.work_date) {
          throw new Error("work_date is required");
        }

        const dateObj = new Date(e.work_date);
        if (isNaN(dateObj.getTime())) {
          throw new Error(`Invalid work_date format: ${e.work_date}`);
        }

        // Get existing entry
        const existing = await prisma.workEntries.findUnique({
          where: { entry_id: e.entry_id },
          select: { employee_id: true, task_id: true, status: true, work_date: true }
        });
        if (!existing) {
          throw new Error(`Entry with entry_id ${e.entry_id} not found`);
        }

        // Use task_id and employee_id from request or existing entry
        const task_id = e.task_id || existing.task_id;
        const employee_id = e.employee_id || existing.employee_id;
        if (!task_id) {
          throw new Error(`task_id is required for entry_id ${e.entry_id}`);
        }
        if (!employee_id) {
          throw new Error(`employee_id is required for entry_id ${e.entry_id}`);
        }

        // Verify task belongs to supervisor
        const task = await prisma.tasks.findUnique({
          where: { task_id: task_id },
          select: { supervisor_id: true }
        });
        if (!task || task.supervisor_id !== supervisorId) {
          throw new Error(`Unauthorized: Task ${task_id} does not belong to supervisor`);
        }

        // Prevent modification of confirmed entries
        if (existing.status === "confirmed") {
          throw new Error(
            `Cannot modify entry with status ${existing.status} for date ${e.work_date}`
          );
        }

        // Preserve existing status
        const finalStatus = existing.status || "pending";

        // Upsert using entry_id
        const upsertResult = await prisma.workEntries.upsert({
          where: {
            entry_id: e.entry_id,
          },
          create: {
            entry_id: e.entry_id,
            employee_id: employee_id,
            task_id: task_id,
            work_date: dateObj,
            start_time: e.start_time ? new Date(e.start_time) : null,
            end_time: e.end_time ? new Date(e.end_time) : null,
            pause_minutes: e.pause_minutes || 0,
            description: e.description || "",
            status: finalStatus,
            confirmation_status: e.confirmation_status || "pending",
            is_draft: !!e.is_draft,
          },
          update: {
            confirmation_status: e.confirmation_status,
            work_date: dateObj,
            task_id: task_id,
            employee_id: employee_id,
            start_time: e.start_time ? new Date(e.start_time) : undefined,
            end_time: e.end_time ? new Date(e.end_time) : undefined,
            pause_minutes: e.pause_minutes ?? undefined,
            description: e.description ?? undefined,
            status: finalStatus,
            is_draft: !!e.is_draft,
          },
        });

        updatedEntries.push(upsertResult);
      })
    );

    return NextResponse.json(
      {
        message: "Upsert OK",
        entries: updatedEntries,
      },
      { status: 201 }
    );
  } catch (e: any) {
    console.error("Error in POST /api/app/supervisor:", e);
    const code =
      e.message === "Unauthorized"
        ? 401
        : e.message.includes("confirmed")
        ? 400
        : e.message.includes("JWT_SECRET")
        ? 500
        : e.message.includes("work_date") ||
          e.message.includes("entry_id") ||
          e.message.includes("confirmation_status") ||
          e.message.includes("task_id") ||
          e.message.includes("employee_id")
        ? 400
        : e.message.includes("Unique constraint failed")
        ? 409
        : 500;
    return NextResponse.json(
      { error: e.message },
      { status: code }
    );
  }
}
