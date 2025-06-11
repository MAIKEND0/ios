//src/app/api/app/work-entries/route.ts
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import dayjs from "dayjs";
import isoWeek from "dayjs/plugin/isoWeek";
import jwt from "jsonwebtoken";
import sgMail from "@sendgrid/mail";
import { PushNotificationService } from "../../../../lib/pushNotificationService";
import { createNotification } from "../../../../lib/notificationService";

dayjs.extend(isoWeek);

const SECRET = process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET!;
const SECRET_KEY = process.env.JWT_SECRET || "tajny_klucz";

async function authenticate(req: NextRequest) {
  const auth = req.headers.get("authorization")?.split(" ");
  if (auth?.[0] !== "Bearer" || !auth[1]) {
    throw new Error("Unauthorized");
  }
  try {
    return jwt.verify(auth[1], SECRET) as { id: number };
  } catch {
    throw new Error("Invalid token");
  }
}

export async function GET(req: NextRequest) {
  try {
    const { id: employeeId } = await authenticate(req);
    const { searchParams } = new URL(req.url);
    const mondayParam = searchParams.get("selectedMonday");
    const isDraftParam = searchParams.get("is_draft");

    if (!mondayParam) {
      return NextResponse.json({ error: "selectedMonday is required" }, { status: 400 });
    }

    const monday = dayjs(mondayParam, "YYYY-MM-DD");
    if (!monday.isValid()) {
      return NextResponse.json({ error: "Invalid date" }, { status: 400 });
    }

    const start = monday.startOf("isoWeek").toDate();
    const end = monday.endOf("isoWeek").toDate();

    const where: any = {
      employee_id: employeeId,
      work_date: { gte: start, lte: end },
    };
    if (isDraftParam != null) {
      where.is_draft = isDraftParam === "true";
    }

    const entries = await prisma.workEntries.findMany({
      where,
      include: { Tasks: true },
      orderBy: { work_date: "desc" },
    });
    return NextResponse.json(entries);
  } catch (e: any) {
    console.error("GET /api/app/work-entries error:", e);
    return NextResponse.json({ error: e.message }, { status: e.message === "Unauthorized" ? 401 : 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    if (!process.env.JWT_SECRET) {
      throw new Error("JWT_SECRET is missing");
    }
    if (!process.env.SENDGRID_API_KEY) {
      throw new Error("SENDGRID_API_KEY is missing");
    }

    const { id: employeeId } = await authenticate(req);
    const { entries } = await req.json();

    if (!Array.isArray(entries)) {
      return NextResponse.json({ error: "entries must be an array" }, { status: 400 });
    }

    let hasSubmitted = false;
    let taskId: number | null = null;
    let weekStartDate: string | null = null;
    const updatedEntries: any[] = [];

    await Promise.all(
      entries.map(async (e: any) => {
        const dateObj = new Date(e.work_date);
        if (isNaN(dateObj.getTime())) {
          throw new Error(`Invalid work_date format: ${e.work_date}`);
        }

        const finalStatus = e.is_draft === false ? "submitted" : "pending";

        const existing = await prisma.workEntries.findUnique({
          where: {
            employee_id_task_id_work_date: {
              employee_id: employeeId,
              task_id: e.task_id,
              work_date: dateObj,
            },
          },
        });

        if (existing && ["submitted", "confirmed"].includes(existing.status)) {
          throw new Error(
            `Cannot modify entry with status ${existing.status} for date ${e.work_date}`
          );
        }

        if (finalStatus === "submitted" && !hasSubmitted) {
          hasSubmitted = true;
          taskId = e.task_id;
          const entryDate = dayjs(dateObj);
          if (!entryDate.isValid()) {
            throw new Error(`Invalid entry date: ${e.work_date}`);
          }
          weekStartDate = entryDate.startOf("isoWeek").format("YYYY-MM-DD");
        }

        const kmValue = e.km !== undefined && e.km !== null ? Number(e.km) : 0.00;

        let upsertResult;
        if (e.entry_id && e.entry_id !== 0) {
          upsertResult = await prisma.workEntries.upsert({
            where: {
              entry_id: e.entry_id,
            },
            create: {
              employee_id: employeeId,
              task_id: e.task_id,
              work_date: dateObj,
              start_time: e.start_time ? new Date(e.start_time) : null,
              end_time: e.end_time ? new Date(e.end_time) : null,
              pause_minutes: e.pause_minutes || 0,
              km: kmValue,
              description: e.description || "",
              status: finalStatus,
              confirmation_status: e.confirmation_status || "pending",
              is_draft: !!e.is_draft,
            },
            update: {
              start_time: e.start_time ? new Date(e.start_time) : undefined,
              end_time: e.end_time ? new Date(e.end_time) : undefined,
              pause_minutes: e.pause_minutes ?? undefined,
              km: kmValue,
              description: e.description ?? undefined,
              status: finalStatus,
              confirmation_status: e.confirmation_status ?? undefined,
              is_draft: !!e.is_draft,
            },
            select: {
              entry_id: true,
              employee_id: true,
              task_id: true,
              work_date: true,
              start_time: true,
              end_time: true,
              pause_minutes: true,
              status: true,
              confirmation_status: true,
              description: true,
              km: true,
            },
          });
        } else {
          upsertResult = await prisma.workEntries.upsert({
            where: {
              employee_id_task_id_work_date: {
                employee_id: employeeId,
                task_id: e.task_id,
                work_date: dateObj,
              },
            },
            create: {
              employee_id: employeeId,
              task_id: e.task_id,
              work_date: dateObj,
              start_time: e.start_time ? new Date(e.start_time) : null,
              end_time: e.end_time ? new Date(e.end_time) : null,
              pause_minutes: e.pause_minutes || 0,
              km: kmValue,
              description: e.description || "",
              status: finalStatus,
              confirmation_status: e.confirmation_status || "pending",
              is_draft: !!e.is_draft,
            },
            update: {
              start_time: e.start_time ? new Date(e.start_time) : undefined,
              end_time: e.end_time ? new Date(e.end_time) : undefined,
              pause_minutes: e.pause_minutes ?? undefined,
              km: kmValue,
              description: e.description ?? undefined,
              status: finalStatus,
              confirmation_status: e.confirmation_status ?? undefined,
              is_draft: !!e.is_draft,
            },
            select: {
              entry_id: true,
              employee_id: true,
              task_id: true,
              work_date: true,
              start_time: true,
              end_time: true,
              pause_minutes: true,
              status: true,
              confirmation_status: true,
              description: true,
              km: true,
            },
          });
        }

        updatedEntries.push(upsertResult);
      })
    );

    let confirmationResponse = {};
    if (hasSubmitted && taskId && weekStartDate) {
      try {
        const token = await sendConfirmationEmail(employeeId, taskId, weekStartDate);
        confirmationResponse = {
          confirmationSent: true,
          confirmationToken: token,
        };
      } catch (emailError: any) {
        console.error("Failed to send confirmation email:", emailError.message);
        confirmationResponse = {
          confirmationSent: false,
          confirmationError: emailError.message,
        };
      }
    }

    return NextResponse.json(
      {
        message: "Upsert OK",
        entries: updatedEntries,
        ...confirmationResponse,
      },
      { status: 201 }
    );
  } catch (e: any) {
    console.error("Error in POST /api/app/work-entries:", e);
    const code =
      e.message === "Unauthorized"
        ? 401
        : e.message.includes("submitted") || e.message.includes("confirmed")
        ? 400
        : e.message.includes("JWT_SECRET") || e.message.includes("SENDGRID_API_KEY")
        ? 500
        : e.message.includes("work_date")
        ? 400
        : e.message.includes("Unique constraint failed")
        ? 409
        : 500;
    return NextResponse.json({ error: e.message }, { status: code });
  }
}

export async function DELETE(req: NextRequest) {
  try {
    const { id: employeeId } = await authenticate(req);
    const { searchParams } = new URL(req.url);
    const entryId = parseInt(searchParams.get("id") || "0");

    if (!entryId) {
      return NextResponse.json({ error: "Entry ID is required" }, { status: 400 });
    }

    const employee = await prisma.employees.findUnique({
      where: { employee_id: employeeId },
    });
    if (!employee) {
      return NextResponse.json({ error: "Employee not found" }, { status: 404 });
    }

    const existingEntry = await prisma.workEntries.findUnique({
      where: { entry_id: entryId },
    });
    if (!existingEntry) {
      return NextResponse.json({ error: "Work entry not found" }, { status: 404 });
    }

    if (existingEntry.employee_id !== employeeId) {
      return NextResponse.json({ error: "Unauthorized: Cannot delete another employee's entry" }, { status: 401 });
    }

    if (["submitted", "confirmed"].includes(existingEntry.status)) {
      return NextResponse.json(
        { error: `Cannot delete entry with status ${existingEntry.status}` },
        { status: 400 }
      );
    }

    await prisma.workEntries.delete({
      where: { entry_id: entryId },
    });

    return NextResponse.json({
      success: true,
      message: "Work entry deleted successfully",
    });
  } catch (e: any) {
    console.error("DELETE /api/app/work-entries error:", e);
    return NextResponse.json(
      { error: e.message },
      {
        status:
          e.message === "Unauthorized" || e.message.includes("Unauthorized")
            ? 401
            : e.message.includes("not found")
            ? 404
            : e.message.includes("status")
            ? 400
            : 500,
      }
    );
  }
}

async function sendConfirmationEmail(employeeId: number, taskId: number, weekStart: string): Promise<string> {
  console.log(">>> Sending confirmation email for submitted work entries <<<");
  try {
    const dateObj = dayjs(weekStart, "YYYY-MM-DD");
    if (!dateObj.isValid()) {
      throw new Error(`Invalid date format for weekStart: ${weekStart}`);
    }

    const task = await prisma.tasks.findUnique({
      where: { task_id: taskId },
      include: { Projects: true },
    });
    if (!task) {
      throw new Error("Task not found");
    }

    const supervisorEmail = task.supervisor_email;
    const supervisorName = task.supervisor_name || "Kære leder";
    if (!supervisorEmail) {
      throw new Error("Supervisor email not found for this task");
    }

    const employee = await prisma.employees.findUnique({
      where: { employee_id: employeeId },
      select: { name: true },
    });
    if (!employee) {
      throw new Error("Employee not found");
    }
    const employeeName = employee.name || "Ukendt Medarbejder";

    sgMail.setApiKey(process.env.SENDGRID_API_KEY!);

    const isoWeekNumber = dateObj.isoWeek();
    const year = dateObj.year();

    const token = jwt.sign(
      { taskId, weekStart, supervisorId: task.supervisor_id, email: supervisorEmail },
      SECRET_KEY,
      { expiresIn: "24h" }
    );

    const taskTitle = task.title || "(Ukendt Opgave)";
    const projectTitle = task.Projects?.title || "(Ukendt Projekt)";

    const mailSubject = `Timer til godkendelse – UGE #${isoWeekNumber} ${year}`;

    const mailText = `
Hej ${supervisorName},

Jeg vil gerne bede dig godkende de timer, som ${employeeName} har sendt til projektet "${projectTitle}"
og opgaven "${taskTitle}" 
(uge nr. ${isoWeekNumber}, start: ${weekStart}).

Disse timer udgør grundlaget for fakturering til kunden, 
så vi beder dig omhyggeligt at kontrollere dem.

Du kan se/tjekke timerne ved at klikke på nedenstående link:
https://www.ksrcranes.dk/customer/confirm-hours?token=${token}

Tak for samarbejdet.
Med venlig hilsen,
KSR Cranes

---
[INFO]
Projekt-ID: ${task?.Projects?.project_id || "?"}
Opgave-ID: ${taskId}
Medarbejder-ID: ${employeeId}
Startdato (uge): ${weekStart}
Token: ${token}
    `.trim();

    const mailHtml = `
<p>Hej ${supervisorName},</p>

<p>
  Jeg vil gerne bede dig godkende de timer, som 
  <strong>${employeeName}</strong> har sendt til projektet 
  <strong>"${projectTitle}"</strong> og opgaven 
  <strong>"${taskTitle}"</strong> 
  (uge nr. ${isoWeekNumber}, start: ${weekStart}).
</p>

<p>
  Disse timer udgør grundlaget for fakturering til kunden, 
  så vi beder dig omhyggeligt at kontrollere dem.
</p>

<p>
  Du kan se/tjekke timerne ved at klikke na poniżejstående link:<br/>
  <a href="https://www.ksrcranes.dk/customer/confirm-hours?token=${token}">
    Bekræft timer
  </a>
</p>

<p>Tak for samarbejdet.</p>
<p>Med venlig hilsen,<br/>
KSR Cranes</p>

<hr/>
<p style="font-size: 0.85em; color: #666;">
  <strong>[INFO]</strong><br/>
  Projekt-ID: ${task?.Projects?.project_id || "?"}<br/>
  Opgave-ID: ${taskId}<br/>
  Medarbejder-ID: ${employeeId}<br/>
  Startdato (uge): ${weekStart}<br/>
  Token: ${token}<br/>
</p>
    `.trim();

    const msg = {
      to: supervisorEmail,
      from: process.env.EMAIL_USER || "info@ksrcranes.dk",
      subject: mailSubject,
      text: mailText,
      html: mailHtml,
    };
    await sgMail.send(msg);

    const chefs = await prisma.employees.findMany({
      where: { role: "chef" },
    });

    for (const boss of chefs) {
      const finalMessage = `
        Timer til godkendelse – "${projectTitle}" / "${taskTitle}"
        Uge ${isoWeekNumber}, start: ${weekStart}
        ${employeeName} har indsendt timer.
        
        Disse timer udgør grundlaget for fakturering, så kontrollér dem venligst omhyggeligt.
      `.trim();

      // Create notification in database with push notification
      const notification = await createNotification({
        employeeId: boss.employee_id,
        type: "HOURS_SUBMITTED",
        title: `⏰ New Hours Submitted - Week ${isoWeekNumber}`,
        message: finalMessage,
        taskId: taskId,
        projectId: task?.Projects?.project_id || null,
        priority: "NORMAL",
        category: "HOURS",
        actionRequired: true,
      });

      console.log(`[WORK ENTRIES] ✅ Notification created for chef ${boss.employee_id} for submitted hours (ID: ${notification.notification_id})`);
      // Note: Push notification is automatically sent by createNotification function
    }

    return token;
  } catch (err: any) {
    throw new Error(`Failed to send confirmation: ${err.message}`);
  }
}
