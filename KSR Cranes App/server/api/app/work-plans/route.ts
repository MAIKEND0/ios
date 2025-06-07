import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import jwt from "jsonwebtoken";
import { s3Clientksrtimesheets } from "../../../../lib/s3Clientksrtimesheets";
import { PutObjectCommand } from "@aws-sdk/client-s3";
import { v4 as uuidv4 } from 'uuid';
import { Readable } from 'stream';

const SECRET = process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET!;

// Interfejs dla żądania tworzenia/aktualizacji planu pracy
interface WorkPlanRequest {
  task_id: number;
  weekNumber: number;
  year: number;
  status: 'DRAFT' | 'PUBLISHED';
  description?: string;
  additional_info?: string;
  attachment?: {
    fileName: string;
    fileData: string; // base64
  };
  assignments: {
    employee_id: number;
    work_date: string; // ISO date (YYYY-MM-DD)
    start_time?: string; // HH:mm format (e.g., "08:00", "17:30")
    end_time?: string; // HH:mm format (e.g., "08:00", "17:30")
    notes?: string;
  }[];
}

// Interfejs dla odpowiedzi
interface WorkPlanResponse {
  work_plan_id: number;
  message: string;
  attachment_url?: string;
}

// Interfejs dla odpowiedzi DELETE
interface DeleteWorkPlanResponse {
  success: boolean;
  message: string;
}

// Struktura do przechowywania informacji o przetwarzanych żądaniach
const processingJobs = new Map<string, {
  status: 'processing' | 'completed' | 'failed';
  attachmentUrl?: string;
  error?: string;
  createdAt: Date;
}>();

// Okresowe czyszczenie starych zadań
setInterval(() => {
  const now = new Date();
  for (const [jobId, job] of processingJobs.entries()) {
    if (now.getTime() - job.createdAt.getTime() > 3600000) { // 1 godzina
      processingJobs.delete(jobId);
    }
  }
}, 300000); // Co 5 minut

// Funkcja autoryzacji
async function authenticate(req: NextRequest) {
  const auth = req.headers.get("authorization")?.split(" ");
  if (auth?.[0] !== "Bearer" || !auth[1]) {
    throw new Error("Unauthorized");
  }
  try {
    const decoded = jwt.verify(auth[1], SECRET) as { id: number, role: string };
    if (decoded.role !== "byggeleder") {
      throw new Error("Unauthorized: Invalid role");
    }
    return decoded;
  } catch {
    throw new Error("Invalid token");
  }
}

// Funkcja walidacji formatu czasu HH:mm
function validateTimeFormat(time: string): boolean {
  const timeRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;
  return timeRegex.test(time);
}

// Endpoint POST - tworzenie planu pracy
export async function POST(req: NextRequest) {
  const startTime = Date.now();
  console.log(`[POST /api/app/work-plans] Start: ${new Date(startTime).toISOString()}`);

  let jobId = "";
  try {
    if (!process.env.JWT_SECRET) {
      throw new Error("JWT_SECRET is missing");
    }
    if (!process.env.KSR_WORKPLANS_KEY || !process.env.KSR_WORKPLANS_SECRET || 
        !process.env.KSR_WORKPLANS_SPACES_BUCKET || !process.env.KSR_WORKPLANS_KEY_SPACES_ENDPOINT || 
        !process.env.KSR_WORKPLANS_SPACES_REGION) {
      throw new Error("KSR_WORKPLANS configuration is missing");
    }

    const { id: supervisorId } = await authenticate(req);
    const body = await req.json() as WorkPlanRequest;

    const { task_id, weekNumber, year, status, description, additional_info, attachment, assignments } = body;

    if (!task_id || !weekNumber || !year || !status || !Array.isArray(assignments) || assignments.length === 0) {
      throw new Error("Required fields missing: task_id, weekNumber, year, status, or assignments");
    }

    // Sprawdź, czy zadanie istnieje i należy do supervisora
    const task = await prisma.tasks.findUnique({
      where: { task_id },
      select: { task_id: true, supervisor_id: true },
    });
    if (!task || task.supervisor_id !== supervisorId) {
      throw new Error(`Unauthorized: Task ${task_id} does not belong to supervisor`);
    }

    // Walidacja przypisań
    const employeeIds = [...new Set(assignments.map(a => a.employee_id))];
    const validEmployees = await prisma.taskAssignments.findMany({
      where: { task_id, employee_id: { in: employeeIds } },
      select: { employee_id: true },
    });
    const validEmployeeIds = new Set(validEmployees.map(e => e.employee_id));
    for (const assignment of assignments) {
      if (!validEmployeeIds.has(assignment.employee_id)) {
        throw new Error(`Employee ${assignment.employee_id} is not assigned to task ${task_id}`);
      }
      if (!assignment.work_date) {
        throw new Error("work_date is required for each assignment");
      }
      if ((assignment.start_time && !assignment.end_time) || (!assignment.start_time && assignment.end_time)) {
        throw new Error("Both start_time and end_time must be provided or neither");
      }
      // Walidacja formatu czasu HH:mm
      if (assignment.start_time && !validateTimeFormat(assignment.start_time)) {
        throw new Error(`Invalid start_time format: ${assignment.start_time}. Expected HH:mm format (e.g., "08:00")`);
      }
      if (assignment.end_time && !validateTimeFormat(assignment.end_time)) {
        throw new Error(`Invalid end_time format: ${assignment.end_time}. Expected HH:mm format (e.g., "17:30")`);
      }
    }

    // Utwórz zadanie przetwarzania
    jobId = uuidv4();
    processingJobs.set(jobId, {
      status: 'processing',
      createdAt: new Date(),
    });

    let attachmentUrl: string | undefined;

    // Przesyłanie załącznika do S3 (jeśli istnieje)
    if (attachment) {
      const { fileName, fileData } = attachment;
      if (!fileName || !fileData) {
        throw new Error("Attachment fileName or fileData missing");
      }

      const fileExtension = fileName.split('.').pop()?.toLowerCase();
      if (!['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'].includes(fileExtension || '')) {
        throw new Error("Unsupported file type");
      }

      const s3Path = `workplans/task_${task_id}/${jobId}/${fileName}`;
      const fileBuffer = Buffer.from(fileData, 'base64');

      const command = new PutObjectCommand({
        Bucket: process.env.KSR_WORKPLANS_SPACES_BUCKET,
        Key: s3Path,
        Body: fileBuffer,
        ContentType: getContentType(fileExtension),
        ACL: "public-read",
      });

      await s3Clientksrtimesheets.send(command);

      attachmentUrl = `https://${process.env.KSR_WORKPLANS_SPACES_BUCKET}.${process.env.KSR_WORKPLANS_KEY_SPACES_ENDPOINT}/${s3Path}`;
      console.log(`[POST /api/app/work-plans] Attachment uploaded to S3: ${attachmentUrl}`);
    }

    console.log(`[POST /api/app/work-plans] Creating work plan with ${assignments.length} assignments for week ${weekNumber}/${year}`);

    // Tworzenie planu pracy w bazie - teraz start_time i end_time są VARCHAR(5)
    const workPlan = await prisma.workPlans.create({
      data: {
        task_id,
        weekNumber,
        year,
        created_by: supervisorId,
        status,
        description,
        additional_info,
        attachment_url: attachmentUrl,
        WorkPlanAssignments: {
          create: assignments.map(assignment => {
            console.log(`[POST /api/app/work-plans] Creating assignment for employee ${assignment.employee_id}, date: ${assignment.work_date}, time: ${assignment.start_time} - ${assignment.end_time}`);
            return {
              employee_id: assignment.employee_id,
              work_date: new Date(assignment.work_date),
              start_time: assignment.start_time || null, // Now stored as VARCHAR(5) "HH:mm"
              end_time: assignment.end_time || null, // Now stored as VARCHAR(5) "HH:mm"  
              notes: assignment.notes,
            };
          }),
        },
      },
      select: {
        work_plan_id: true,
      },
    });

    processingJobs.set(jobId, {
      status: 'completed',
      attachmentUrl,
      createdAt: new Date(),
    });

    console.log(`[POST /api/app/work-plans] Completed in ${Date.now() - startTime}ms`);

    return NextResponse.json(
      {
        work_plan_id: workPlan.work_plan_id,
        message: `Work plan ${status === 'DRAFT' ? 'saved as draft' : 'published'}`,
        attachment_url: attachmentUrl,
      } as WorkPlanResponse,
      { status: 201 }
    );
  } catch (e: any) {
    console.error("Error in POST /api/app/work-plans:", e);
    const code =
      e.message === "Unauthorized" ? 401 :
      e.message.includes("Required fields missing") ||
      e.message.includes("Employee") ||
      e.message.includes("work_date") ||
      e.message.includes("start_time") ||
      e.message.includes("end_time") ||
      e.message.includes("Invalid") ||
      e.message.includes("Unsupported file type") ? 400 :
      e.message.includes("JWT_SECRET") ||
      e.message.includes("KSR_WORKPLANS_KEY") ||
      e.message.includes("KSR_WORKPLANS_SECRET") ||
      e.message.includes("KSR_WORKPLANS_SPACES_BUCKET") ||
      e.message.includes("KSR_WORKPLANS_KEY_SPACES_ENDPOINT") ||
      e.message.includes("KSR_WORKPLANS_SPACES_REGION") ? 500 :
      e.message.includes("Unique constraint failed") ? 409 :
      500;

    if (jobId) {
      processingJobs.set(jobId, {
        status: 'failed',
        error: e.message,
        createdAt: new Date(),
      });
    }

    return NextResponse.json(
      { error: e.message },
      { status: code }
    );
  }
}

// Endpoint PUT - aktualizacja planu pracy
export async function PUT(req: NextRequest) {
  const startTime = Date.now();
  console.log(`[PUT /api/app/work-plans] Start: ${new Date(startTime).toISOString()}`);

  let jobId = "";
  try {
    if (!process.env.JWT_SECRET) {
      throw new Error("JWT_SECRET is missing");
    }
    if (!process.env.KSR_WORKPLANS_KEY || !process.env.KSR_WORKPLANS_SECRET || 
        !process.env.KSR_WORKPLANS_SPACES_BUCKET || !process.env.KSR_WORKPLANS_KEY_SPACES_ENDPOINT || 
        !process.env.KSR_WORKPLANS_SPACES_REGION) {
      throw new Error("KSR_WORKPLANS configuration is missing");
    }

    const { id: supervisorId } = await authenticate(req);
    const work_plan_id = parseInt(req.nextUrl.searchParams.get('id') || '');
    if (!work_plan_id) {
      throw new Error("Work plan ID is missing");
    }

    const body = await req.json() as WorkPlanRequest;
    const { task_id, weekNumber, year, status, description, additional_info, attachment, assignments } = body;

    if (!task_id || !weekNumber || !year || !status || !Array.isArray(assignments) || assignments.length === 0) {
      throw new Error("Required fields missing: task_id, weekNumber, year, status, or assignments");
    }

    // Sprawdź, czy plan pracy istnieje i należy do supervisora
    const existingWorkPlan = await prisma.workPlans.findUnique({
      where: { work_plan_id },
      select: { work_plan_id: true, created_by: true, task_id: true },
    });
    if (!existingWorkPlan || existingWorkPlan.created_by !== supervisorId) {
      throw new Error(`Unauthorized: Work plan ${work_plan_id} does not belong to supervisor`);
    }

    // Sprawdź, czy zadanie istnieje i należy do supervisora
    const task = await prisma.tasks.findUnique({
      where: { task_id },
      select: { task_id: true, supervisor_id: true },
    });
    if (!task || task.supervisor_id !== supervisorId) {
      throw new Error(`Unauthorized: Task ${task_id} does not belong to supervisor`);
    }

    // Walidacja przypisań
    const employeeIds = [...new Set(assignments.map(a => a.employee_id))];
    const validEmployees = await prisma.taskAssignments.findMany({
      where: { task_id, employee_id: { in: employeeIds } },
      select: { employee_id: true },
    });
    const validEmployeeIds = new Set(validEmployees.map(e => e.employee_id));
    for (const assignment of assignments) {
      if (!validEmployeeIds.has(assignment.employee_id)) {
        throw new Error(`Employee ${assignment.employee_id} is not assigned to task ${task_id}`);
      }
      if (!assignment.work_date) {
        throw new Error("work_date is required for each assignment");
      }
      if ((assignment.start_time && !assignment.end_time) || (!assignment.start_time && assignment.end_time)) {
        throw new Error("Both start_time and end_time must be provided or neither");
      }
      // Walidacja formatu czasu HH:mm
      if (assignment.start_time && !validateTimeFormat(assignment.start_time)) {
        throw new Error(`Invalid start_time format: ${assignment.start_time}. Expected HH:mm format (e.g., "08:00")`);
      }
      if (assignment.end_time && !validateTimeFormat(assignment.end_time)) {
        throw new Error(`Invalid end_time format: ${assignment.end_time}. Expected HH:mm format (e.g., "17:30")`);
      }
    }

    // Utwórz zadanie przetwarzania
    jobId = uuidv4();
    processingJobs.set(jobId, {
      status: 'processing',
      createdAt: new Date(),
    });

    let attachmentUrl: string | undefined;

    // Przesyłanie załącznika do S3 (jeśli istnieje)
    if (attachment) {
      const { fileName, fileData } = attachment;
      if (!fileName || !fileData) {
        throw new Error("Attachment fileName or fileData missing");
      }

      const fileExtension = fileName.split('.').pop()?.toLowerCase();
      if (!['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'].includes(fileExtension || '')) {
        throw new Error("Unsupported file type");
      }

      const s3Path = `workplans/task_${task_id}/${jobId}/${fileName}`;
      const fileBuffer = Buffer.from(fileData, 'base64');

      const command = new PutObjectCommand({
        Bucket: process.env.KSR_WORKPLANS_SPACES_BUCKET,
        Key: s3Path,
        Body: fileBuffer,
        ContentType: getContentType(fileExtension),
        ACL: "public-read",
      });

      await s3Clientksrtimesheets.send(command);

      attachmentUrl = `https://${process.env.KSR_WORKPLANS_SPACES_BUCKET}.${process.env.KSR_WORKPLANS_KEY_SPACES_ENDPOINT}/${s3Path}`;
      console.log(`[PUT /api/app/work-plans] Attachment uploaded to S3: ${attachmentUrl}`);
    }

    console.log(`[PUT /api/app/work-plans] Updating work plan ${work_plan_id} with ${assignments.length} assignments for week ${weekNumber}/${year}`);

    // Aktualizacja planu pracy w bazie - teraz start_time i end_time są VARCHAR(5)
    const workPlan = await prisma.workPlans.update({
      where: { work_plan_id },
      data: {
        task_id,
        weekNumber,
        year,
        status,
        description,
        additional_info,
        attachment_url: attachmentUrl,
        WorkPlanAssignments: {
          deleteMany: {},
          create: assignments.map(assignment => {
            console.log(`[PUT /api/app/work-plans] Creating assignment for employee ${assignment.employee_id}, date: ${assignment.work_date}, time: ${assignment.start_time} - ${assignment.end_time}`);
            return {
              employee_id: assignment.employee_id,
              work_date: new Date(assignment.work_date),
              start_time: assignment.start_time || null, // Now stored as VARCHAR(5) "HH:mm"
              end_time: assignment.end_time || null, // Now stored as VARCHAR(5) "HH:mm"
              notes: assignment.notes,
            };
          }),
        },
      },
      select: {
        work_plan_id: true,
      },
    });

    processingJobs.set(jobId, {
      status: 'completed',
      attachmentUrl,
      createdAt: new Date(),
    });

    console.log(`[PUT /api/app/work-plans] Completed in ${Date.now() - startTime}ms`);

    return NextResponse.json(
      {
        work_plan_id: workPlan.work_plan_id,
        message: `Work plan ${status === 'DRAFT' ? 'updated as draft' : 'published'}`,
        attachment_url: attachmentUrl,
      } as WorkPlanResponse,
      { status: 200 }
    );
  } catch (e: any) {
    console.error("Error in PUT /api/app/work-plans:", e);
    const code =
      e.message === "Unauthorized" ? 401 :
      e.message.includes("Work plan ID is missing") ||
      e.message.includes("Required fields missing") ||
      e.message.includes("Employee") ||
      e.message.includes("work_date") ||
      e.message.includes("start_time") ||
      e.message.includes("end_time") ||
      e.message.includes("Invalid") ||
      e.message.includes("Unsupported file type") ? 400 :
      e.message.includes("JWT_SECRET") ||
      e.message.includes("KSR_WORKPLANS_KEY") ||
      e.message.includes("KSR_WORKPLANS_SECRET") ||
      e.message.includes("KSR_WORKPLANS_SPACES_BUCKET") ||
      e.message.includes("KSR_WORKPLANS_KEY_SPACES_ENDPOINT") ||
      e.message.includes("KSR_WORKPLANS_SPACES_REGION") ? 500 :
      e.message.includes("Unique constraint failed") ? 409 :
      500;

    if (jobId) {
      processingJobs.set(jobId, {
        status: 'failed',
        error: e.message,
        createdAt: new Date(),
      });
    }

    return NextResponse.json(
      { error: e.message },
      { status: code }
    );
  }
}

// Endpoint DELETE - usuwanie planu pracy
export async function DELETE(req: NextRequest) {
  const startTime = Date.now();
  console.log(`[DELETE /api/app/work-plans] Start: ${new Date(startTime).toISOString()}`);

  try {
    const { id: supervisorId } = await authenticate(req);
    const work_plan_id = parseInt(req.nextUrl.searchParams.get('id') || '');
    
    if (!work_plan_id) {
      throw new Error("Work plan ID is missing");
    }

    console.log(`[DELETE /api/app/work-plans] Attempting to delete work plan ${work_plan_id} by supervisor ${supervisorId}`);

    // Sprawdź, czy plan pracy istnieje i należy do supervisora
    const existingWorkPlan = await prisma.workPlans.findUnique({
      where: { work_plan_id },
      select: { 
        work_plan_id: true, 
        created_by: true, 
        task_id: true,
        status: true,
        Tasks: {
          select: {
            title: true
          }
        }
      },
    });

    if (!existingWorkPlan) {
      throw new Error(`Work plan ${work_plan_id} not found`);
    }

    if (existingWorkPlan.created_by !== supervisorId) {
      throw new Error(`Unauthorized: Work plan ${work_plan_id} does not belong to supervisor ${supervisorId}`);
    }

    // Opcjonalnie: Można dodać ograniczenie, że tylko plany DRAFT mogą być usuwane
    // if (existingWorkPlan.status === 'PUBLISHED') {
    //   throw new Error(`Cannot delete published work plan ${work_plan_id}`);
    // }

    console.log(`[DELETE /api/app/work-plans] Deleting work plan ${work_plan_id} (${existingWorkPlan.Tasks?.title || 'Unknown task'})`);

    // Usuń plan pracy wraz z wszystkimi assignments (CASCADE powinno działać automatycznie)
    await prisma.workPlans.delete({
      where: { work_plan_id },
    });

    console.log(`[DELETE /api/app/work-plans] Successfully deleted work plan ${work_plan_id} in ${Date.now() - startTime}ms`);

    return NextResponse.json(
      {
        success: true,
        message: `Work plan for "${existingWorkPlan.Tasks?.title || 'Unknown task'}" has been successfully deleted.`
      } as DeleteWorkPlanResponse,
      { status: 200 }
    );

  } catch (e: any) {
    console.error("Error in DELETE /api/app/work-plans:", e);
    
    const code =
      e.message === "Unauthorized" || e.message.includes("does not belong to supervisor") ? 401 :
      e.message.includes("Work plan ID is missing") || e.message.includes("not found") ? 400 :
      e.message.includes("Cannot delete published") ? 403 :
      500;

    return NextResponse.json(
      { 
        success: false,
        message: e.message 
      } as DeleteWorkPlanResponse,
      { status: code }
    );
  }
}

// Endpoint GET - pobieranie planów pracy
export async function GET(req: NextRequest) {
  try {
    const { id: supervisorId } = await authenticate(req);
    const weekNumber = req.nextUrl.searchParams.get('weekNumber') ? parseInt(req.nextUrl.searchParams.get('weekNumber')!) : undefined;
    const year = req.nextUrl.searchParams.get('year') ? parseInt(req.nextUrl.searchParams.get('year')!) : undefined;

    const workPlans = await prisma.workPlans.findMany({
      where: {
        created_by: supervisorId,
        ...(weekNumber && year ? { weekNumber, year } : {}),
      },
      include: {
        Tasks: {
          select: {
            task_id: true,
            title: true,
          },
        },
        WorkPlanAssignments: {
          select: {
            assignment_id: true,
            employee_id: true,
            work_date: true,
            start_time: true,
            end_time: true,
            notes: true,
          },
        },
        Employees: {
          select: {
            name: true,
          },
        },
      },
    });

    const response = workPlans.map(plan => ({
      work_plan_id: plan.work_plan_id,
      task_id: plan.task_id,
      task_title: plan.Tasks?.title || "Unknown",
      weekNumber: plan.weekNumber,
      year: plan.year,
      status: plan.status,
      creator_name: plan.Employees?.name || "Unknown",
      description: plan.description,
      additional_info: plan.additional_info,
      attachment_url: plan.attachment_url,
      assignments: plan.WorkPlanAssignments.map(assignment => {
        console.log(`[GET /api/app/work-plans] Assignment ${assignment.assignment_id}: start_time="${assignment.start_time}", end_time="${assignment.end_time}"`);
        return {
          assignment_id: assignment.assignment_id,
          employee_id: assignment.employee_id,
          work_date: assignment.work_date.toISOString().split('T')[0],
          start_time: assignment.start_time || undefined, // Now returns VARCHAR(5) "HH:mm" directly
          end_time: assignment.end_time || undefined, // Now returns VARCHAR(5) "HH:mm" directly
          notes: assignment.notes,
        };
      }),
    }));

    console.log(`[GET /api/app/work-plans] Returning ${response.length} work plans for supervisor ${supervisorId}`);
    return NextResponse.json(response, { status: 200 });
  } catch (e: any) {
    console.error("Error in GET /api/app/work-plans:", e);
    return NextResponse.json({ error: e.message }, { status: e.message === "Unauthorized" ? 401 : 500 });
  }
}

// Pomocnicza funkcja do określenia Content-Type dla załącznika
function getContentType(fileExtension: string | undefined): string {
  switch (fileExtension) {
    case 'pdf': return 'application/pdf';
    case 'doc': return 'application/msword';
    case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'png': return 'image/png';
    case 'jpg':
    case 'jpeg': return 'image/jpeg';
    default: return 'application/octet-stream';
  }
}