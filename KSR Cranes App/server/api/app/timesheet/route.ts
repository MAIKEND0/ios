// src/app/api/app/timesheet/route.ts
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import jwt from "jsonwebtoken";
import { PDFDocument, rgb } from "pdf-lib";
import { s3Clientksrtimesheets } from "../../../../lib/s3Clientksrtimesheets";
import { PutObjectCommand, GetObjectCommand, HeadObjectCommand } from "@aws-sdk/client-s3";
import { v4 as uuidv4 } from 'uuid';
import { readFileSync } from 'fs';
import { join } from 'path';
import { setTimeout } from 'timers/promises';

// ========== DODANE: IMPORT NOTIFICATION SERVICE ==========
import { createRejectionNotification, createApprovalNotification, createWeekRejectionNotification } from "../../../../lib/notificationService";

// Przeniesienie logo do osobnego pliku
const logoPath = join(process.cwd(), 'public', 'images', 'logo-horizontal.png');
const logoBuffer = readFileSync(logoPath);
const logoBase64 = logoBuffer.toString('base64');

const SECRET = process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET!;

// Interfejs dla grupy wpisów
interface TaskWeekGroup {
    taskId: number;
    weekNumber: number;
    year: number;
    entries: any[];
}

// Struktura do przechowywania informacji o zadaniach
const processingJobs = new Map<string, {
    status: 'processing' | 'completed' | 'failed';
    timesheetUrl?: string;
    error?: string;
    createdAt: Date;
    requestHash?: string;
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

function getWeek(date: Date): number {
    const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
    const weekNo = Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
    return weekNo;
}

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

function createRequestHash(entries: any[]): string {
    const entryIds = entries.map(e => e.entry_id).sort().join('-');
    const statuses = entries.map(e => e.confirmation_status).join('-');
    return `${entryIds}-${statuses}`;
}

function findExistingJob(requestHash: string): { jobId: string, status: string, timesheetUrl?: string } | undefined {
    for (const [jobId, job] of processingJobs.entries()) {
        if (job.requestHash === requestHash) {
            return { jobId, status: job.status, timesheetUrl: job.timesheetUrl };
        }
    }
    return undefined;
}

export async function POST(req: NextRequest) {
    const startTime = Date.now();
    console.log(`[POST /api/app/timesheet] Start: ${new Date(startTime).toISOString()}`);

    try {
        if (!process.env.JWT_SECRET) {
            throw new Error("JWT_SECRET is missing");
        }
        if (!process.env.KSR_TIMESHEETS_KEY || !process.env.KSR_TIMESHEETS_SECRET || !process.env.KSR_TIMESHEETS_SPACES_BUCKET || !process.env.KSR_TIMESHEETS_KEY_SPACES_ENDPOINT || !process.env.KSR_TIMESHEETS_SPACES_REGION) {
            throw new Error("KSR_TIMESHEETS_KEY, KSR_TIMESHEETS_SECRET, KSR_TIMESHEETS_SPACES_BUCKET, KSR_TIMESHEETS_KEY_SPACES_ENDPOINT, or KSR_TIMESHEETS_SPACES_REGION is missing");
        }

        const { id: supervisorId } = await authenticate(req);
        const { entries, signatureId, rejectionReason } = await req.json();

        if (!Array.isArray(entries) || entries.length === 0) {
            throw new Error("entries must be an array and cannot be empty");
        }

        // Generuj unikalny hash żądania
        const requestHash = createRequestHash(entries);

        // Sprawdź, czy podobne żądanie jest już przetwarzane
        const existingJob = findExistingJob(requestHash);
        if (existingJob) {
            if (existingJob.status === 'processing') {
                return NextResponse.json(
                    { message: "Request is already being processed", jobId: existingJob.jobId },
                    { status: 202 }
                );
            } else if (existingJob.status === 'completed') {
                return NextResponse.json(
                    { 
                        message: "Upsert OK (cached)",
                        timesheetUrl: existingJob.timesheetUrl 
                    },
                    { status: 201 }
                );
            }
        }

        // Jeśli brak signatureId, zatwierdź wpisy bez generowania PDF
        if (!signatureId) {
            const updatedEntries: any[] = [];
            console.log(`[POST /api/app/timesheet] Starting upsert for ${entries.length} entries without PDF`);
            const upsertStart = Date.now();

            // Grupowanie wpisów według zadania i tygodnia
            const entriesByWeekAndTask: { [key: string]: TaskWeekGroup } = entries.reduce((acc: { [key: string]: TaskWeekGroup }, entry: any) => {
                if (!entry.work_date || !entry.task_id) return acc;
                const date = new Date(entry.work_date);
                const weekNumber = getWeek(date);
                const year = date.getFullYear();
                const key = `${entry.task_id}-${weekNumber}-${year}`;
                if (!acc[key]) {
                    acc[key] = { taskId: entry.task_id, weekNumber, year, entries: [] };
                }
                acc[key].entries.push(entry);
                return acc;
            }, {});

            // Konsolidacja zapytań do bazy
            const entryIds = entries.map(e => e.entry_id);
            const existingEntries = await prisma.workEntries.findMany({
                where: { entry_id: { in: entryIds } },
                select: { entry_id: true, employee_id: true, task_id: true, status: true, is_draft: true, work_date: true }
            });

            const tasks = await prisma.tasks.findMany({
                where: { task_id: { in: entries.map(e => e.task_id || existingEntries.find(ex => ex.entry_id === e.entry_id)?.task_id) } },
                select: { task_id: true, supervisor_id: true, project_id: true, title: true }
            });

            for (const entry of entries) {
                if (!entry.entry_id || !entry.confirmation_status || !entry.work_date) {
                    throw new Error("Required fields missing");
                }

                const existing = existingEntries.find(e => e.entry_id === entry.entry_id);
                if (!existing) {
                    throw new Error(`Entry with entry_id ${entry.entry_id} not found`);
                }

                const task_id = entry.task_id || existing.task_id;
                const employee_id = entry.employee_id || existing.employee_id;
                if (!task_id || !employee_id) {
                    throw new Error(`task_id or employee_id missing for entry_id ${entry.entry_id}`);
                }

                const task = tasks.find(t => t.task_id === task_id);
                if (!task || task.supervisor_id !== supervisorId) {
                    throw new Error(`Unauthorized: Task ${task_id} does not belong to supervisor`);
                }

                if (existing.status === "confirmed") {
                    throw new Error(`Cannot modify entry with status ${existing.status} for date ${entry.work_date}`);
                }

                const finalStatus = entry.status || existing.status || "pending";
                const finalIsDraft = entry.is_draft !== undefined ? entry.is_draft : (existing.is_draft || false);

                if (entry.confirmation_status === "rejected" && !rejectionReason) {
                    throw new Error("rejectionReason is required when rejecting an entry");
                }

                console.log(`[POST /api/app/timesheet] 🔄 Processing entry ${entry.entry_id}:`);
                console.log(`  - confirmation_status: ${entry.confirmation_status}`);
                console.log(`  - status: ${existing.status} → ${finalStatus}`);
                console.log(`  - is_draft: ${existing.is_draft} → ${finalIsDraft}`);
                console.log(`  - rejection_reason: ${entry.confirmation_status === "rejected" ? rejectionReason : 'null'}`);

                const upsertResult = await prisma.workEntries.update({
                    where: { entry_id: entry.entry_id },
                    data: { 
                        confirmation_status: entry.confirmation_status,
                        rejection_reason: entry.confirmation_status === "rejected" ? rejectionReason : null,
                        status: finalStatus,
                        is_draft: finalIsDraft
                    }
                });

                console.log(`[POST /api/app/timesheet] ✅ Entry ${entry.entry_id} updated successfully`);

                // Generowanie powiadomień o zatwierdzeniu (dla pojedynczych wpisów)
                try {
                    if (entry.confirmation_status === "confirmed") {
                        await createApprovalNotification(
                            employee_id,
                            entry.entry_id,
                            task_id,
                            task.title
                        );
                        console.log(`[POST /api/app/timesheet] Created approval notification for employee ${employee_id}, entry ${entry.entry_id}`);
                    }
                } catch (notificationError) {
                    console.error(`[POST /api/app/timesheet] Failed to create notification for entry ${entry.entry_id}:`, notificationError);
                }

                updatedEntries.push(upsertResult);
            }

            // Generowanie skonsolidowanych powiadomień dla odrzuconych wpisów
            for (const key in entriesByWeekAndTask) {
                const group = entriesByWeekAndTask[key];
                const rejectedEntries = group.entries.filter(e => e.confirmation_status === "rejected");
                if (rejectedEntries.length > 0) {
                    const task = tasks.find(t => t.task_id === group.taskId);
                    const employee_id = rejectedEntries[0].employee_id || existingEntries.find(ex => ex.entry_id === rejectedEntries[0].entry_id)?.employee_id;
                    if (employee_id && task) {
                        // Pobierz problematyczne dni z requestu, jeśli dostępne
                        const problematicDays = rejectedEntries
                            .filter(e => e.problematic === true)
                            .map(e => new Date(e.work_date).toISOString());

                        await createWeekRejectionNotification(
                            employee_id,
                            rejectedEntries.map(e => e.entry_id),
                            group.taskId,
                            rejectionReason,
                            task.title,
                            group.weekNumber,
                            group.year,
                            task.project_id,
                            problematicDays.length > 0 ? problematicDays : undefined
                        );
                        console.log(`[POST /api/app/timesheet] Created consolidated rejection notification for employee ${employee_id}, task ${group.taskId}, week ${group.weekNumber}/${group.year}`);
                    }
                }
            }

            console.log(`[POST /api/app/timesheet] Upsert completed in ${Date.now() - upsertStart}ms`);

            return NextResponse.json(
                {
                    message: "Entries approved without PDF",
                    entries: updatedEntries
                },
                { status: 200 }
            );
        }

        // Sprawdź podpis w bazie
        const signature = await prisma.supervisorSignatures.findFirst({
            where: { signature_id: signatureId, supervisor_id: supervisorId, is_active: true },
        });
        if (!signature) {
            throw new Error("Invalid or inactive signature");
        }

        // Utwórz nowe zadanie
        const jobId = uuidv4();
        processingJobs.set(jobId, {
            status: 'processing',
            createdAt: new Date(),
            requestHash
        });

        // Szybkie zapisanie danych do bazy
        const updatedEntries: any[] = [];
        console.log(`[POST /api/app/timesheet] Starting upsert for ${entries.length} entries`);
        const upsertStart = Date.now();

        // Grupowanie wpisów według zadania i tygodnia
        const entriesByWeekAndTask: { [key: string]: TaskWeekGroup } = entries.reduce((acc: { [key: string]: TaskWeekGroup }, entry: any) => {
            if (!entry.work_date || !entry.task_id) return acc;
            const date = new Date(entry.work_date);
            const weekNumber = getWeek(date);
            const year = date.getFullYear();
            const key = `${entry.task_id}-${weekNumber}-${year}`;
            if (!acc[key]) {
                acc[key] = { taskId: entry.task_id, weekNumber, year, entries: [] };
            }
            acc[key].entries.push(entry);
            return acc;
        }, {});

        // Konsolidacja zapytań do bazy
        const entryIds = entries.map(e => e.entry_id);
        const existingEntries = await prisma.workEntries.findMany({
            where: { entry_id: { in: entryIds } },
            select: { entry_id: true, employee_id: true, task_id: true, status: true, is_draft: true, work_date: true }
        });

        const tasks = await prisma.tasks.findMany({
            where: { task_id: { in: entries.map(e => e.task_id || existingEntries.find(ex => ex.entry_id === e.entry_id)?.task_id) } },
            select: { task_id: true, supervisor_id: true, project_id: true, title: true }
        });

        for (const entry of entries) {
            if (!entry.entry_id || !entry.confirmation_status || !entry.work_date) {
                processingJobs.set(jobId, {
                    status: 'failed', 
                    error: "Missing required fields",
                    createdAt: new Date(),
                    requestHash
                });
                throw new Error("Required fields missing");
            }

            const existing = existingEntries.find(e => e.entry_id === entry.entry_id);
            if (!existing) {
                throw new Error(`Entry with entry_id ${entry.entry_id} not found`);
            }

            const task_id = entry.task_id || existing.task_id;
            const employee_id = entry.employee_id || existing.employee_id;
            if (!task_id || !employee_id) {
                throw new Error(`task_id or employee_id missing for entry_id ${entry.entry_id}`);
            }

            const task = tasks.find(t => t.task_id === task_id);
            if (!task || task.supervisor_id !== supervisorId) {
                throw new Error(`Unauthorized: Task ${task_id} does not belong to supervisor`);
            }

            if (existing.status === "confirmed") {
                throw new Error(`Cannot modify entry with status ${existing.status} for date ${entry.work_date}`);
            }

            const finalStatus = entry.status || existing.status || "pending";
            const finalIsDraft = entry.is_draft !== undefined ? entry.is_draft : (existing.is_draft || false);

            if (entry.confirmation_status === "rejected" && !rejectionReason) {
                throw new Error("rejectionReason is required when rejecting an entry");
            }

            console.log(`[POST /api/app/timesheet] 🔄 Processing entry ${entry.entry_id} (with PDF):`);
            console.log(`  - confirmation_status: ${entry.confirmation_status}`);
            console.log(`  - status: ${existing.status} → ${finalStatus}`);
            console.log(`  - is_draft: ${existing.is_draft} → ${finalIsDraft}`);
            console.log(`  - rejection_reason: ${entry.confirmation_status === "rejected" ? rejectionReason : 'null'}`);

            const upsertResult = await prisma.workEntries.update({
                where: { entry_id: entry.entry_id },
                data: { 
                    confirmation_status: entry.confirmation_status,
                    rejection_reason: entry.confirmation_status === "rejected" ? rejectionReason : null,
                    status: finalStatus,
                    is_draft: finalIsDraft
                }
            });

            console.log(`[POST /api/app/timesheet] ✅ Entry ${entry.entry_id} updated successfully (with PDF)`);

            // Generowanie powiadomień o zatwierdzeniu (dla pojedynczych wpisów)
            try {
                if (entry.confirmation_status === "confirmed") {
                    await createApprovalNotification(
                        employee_id,
                        entry.entry_id,
                        task_id,
                        task.title
                    );
                    console.log(`[POST /api/app/timesheet] Created approval notification for employee ${employee_id}, entry ${entry.entry_id}`);
                }
            } catch (notificationError) {
                console.error(`[POST /api/app/timesheet] Failed to create notification for entry ${entry.entry_id}:`, notificationError);
            }

            updatedEntries.push(upsertResult);
        }

        // Generowanie skonsolidowanych powiadomień dla odrzuconych wpisów
        for (const key in entriesByWeekAndTask) {
            const group = entriesByWeekAndTask[key];
            const rejectedEntries = group.entries.filter(e => e.confirmation_status === "rejected");
            if (rejectedEntries.length > 0) {
                const task = tasks.find(t => t.task_id === group.taskId);
                const employee_id = rejectedEntries[0].employee_id || existingEntries.find(ex => ex.entry_id === rejectedEntries[0].entry_id)?.employee_id;
                if (employee_id && task) {
                    // Pobierz problematyczne dni z requestu, jeśli dostępne
                    const problematicDays = rejectedEntries
                        .filter(e => e.problematic === true)
                        .map(e => new Date(e.work_date).toISOString());

                    await createWeekRejectionNotification(
                        employee_id,
                        rejectedEntries.map(e => e.entry_id),
                        group.taskId,
                        rejectionReason,
                        task.title,
                        group.weekNumber,
                        group.year,
                        task.project_id,
                        problematicDays.length > 0 ? problematicDays : undefined
                    );
                    console.log(`[POST /api/app/timesheet] Created consolidated rejection notification for employee ${employee_id}, task ${group.taskId}, week ${group.weekNumber}/${group.year}`);
                }
            }
        }

        console.log(`[POST /api/app/timesheet] Upsert completed in ${Date.now() - upsertStart}ms`);

        // Uruchom generowanie PDF w tle
        processPdfInBackground(jobId, entries, signature.signature_url, supervisorId, requestHash)
            .catch(error => {
                console.error("Error processing PDF in background:", error);
                processingJobs.set(jobId, {
                    status: 'failed',
                    error: error.message,
                    createdAt: new Date(),
                    requestHash
                });
            });

        return NextResponse.json(
            {
                message: "Processing started",
                jobId,
                entries: updatedEntries
            },
            { status: 202 }
        );
    } catch (e: any) {
        console.error("Error in POST /api/app/timesheet:", e);
        const code =
            e.message === "Unauthorized"
                ? 401
                : e.message.includes("confirmed")
                ? 400
                : e.message.includes("JWT_SECRET") || e.message.includes("KSR_TIMESHEETS_KEY") || e.message.includes("KSR_TIMESHEETS_SECRET") || e.message.includes("KSR_TIMESHEETS_SPACES_BUCKET") || e.message.includes("KSR_TIMESHEETS_KEY_SPACES_ENDPOINT") || e.message.includes("KSR_TIMESHEETS_SPACES_REGION")
                ? 500
                : e.message.includes("work_date") || e.message.includes("entry_id") || e.message.includes("confirmation_status") || e.message.includes("task_id") || e.message.includes("employee_id") || e.message.includes("rejectionReason") || e.message.includes("signature")
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

export async function GET(req: NextRequest) {
    try {
        const { id: supervisorId } = await authenticate(req);
        const jobId = req.nextUrl.searchParams.get('jobId');

        if (!jobId) {
            return NextResponse.json({ error: "Missing jobId parameter" }, { status: 400 });
        }

        const job = processingJobs.get(jobId);
        if (!job) {
            return NextResponse.json({ error: "Job not found" }, { status: 404 });
        }

        return NextResponse.json({
            status: job.status,
            timesheetUrl: job.timesheetUrl,
            error: job.error
        });
    } catch (e: any) {
        console.error("Error in GET /api/app/timesheet:", e);
        return NextResponse.json({ error: e.message }, { status: 401 });
    }
}

async function processPdfInBackground(jobId: string, entries: any[], signatureUrl: string, supervisorId: number, requestHash: string) {
    try {
        // Timeout dla całego procesu
        const timeoutPromise = setTimeout(60000).then(() => {
            throw new Error("PDF generation timed out after 60 seconds");
        });

        const pdfGenerationPromise = (async () => {
            // Pobierz podpis z S3
            console.log(`[processPdfInBackground] Attempting to fetch signature from URL: ${signatureUrl}`);
            const signaturePath = signatureUrl.replace(`https://${process.env.KSR_TIMESHEETS_SPACES_BUCKET}.${process.env.KSR_TIMESHEETS_KEY_SPACES_ENDPOINT}/`, '');
            console.log(`[processPdfInBackground] Computed signature path: ${signaturePath}`);

            // Weryfikuj istnienie pliku w S3
            let retryCount = 0;
            const maxRetries = 3;
            let signatureBase64: string | undefined;

            while (retryCount < maxRetries) {
                try {
                    await s3Clientksrtimesheets.send(new HeadObjectCommand({
                        Bucket: process.env.KSR_TIMESHEETS_SPACES_BUCKET,
                        Key: signaturePath,
                    }));
                    console.log(`[processPdfInBackground] Signature file exists in S3: ${signaturePath}`);

                    const command = new GetObjectCommand({
                        Bucket: process.env.KSR_TIMESHEETS_SPACES_BUCKET,
                        Key: signaturePath,
                    });
                    const { Body } = await s3Clientksrtimesheets.send(command);
                    if (!Body) {
                        throw new Error(`Failed to fetch signature from S3: Empty response body`);
                    }
                    const signatureBuffer = Buffer.from(await Body.transformToByteArray());
                    signatureBase64 = signatureBuffer.toString('base64');
                    console.log(`[processPdfInBackground] Successfully fetched signature, base64 length: ${signatureBase64.length}`);
                    break;
                } catch (error) {
                    console.error(`[processPdfInBackground] Attempt ${retryCount + 1}/${maxRetries} failed to fetch signature: ${error}`);
                    retryCount++;
                    if (retryCount < maxRetries) {
                        await setTimeout(2000); // Poczekaj 2 sekundy przed ponowną próbą
                    } else {
                        throw new Error(`Failed to fetch signature from S3 after ${maxRetries} attempts: ${error}`);
                    }
                }
            }

            if (!signatureBase64) {
                throw new Error("Failed to retrieve signature from S3");
            }

            const entriesByWeekAndTask: { [key: string]: TaskWeekGroup } = entries.reduce((acc: { [key: string]: TaskWeekGroup }, entry: any) => {
                if (!entry.work_date || !entry.task_id) return acc;
                const date = new Date(entry.work_date);
                const weekNumber = getWeek(date);
                const year = date.getFullYear();
                const key = `${entry.task_id}-${weekNumber}-${year}`;
                if (!acc[key]) {
                    acc[key] = { taskId: entry.task_id, weekNumber, year, entries: [] };
                }
                acc[key].entries.push(entry);
                return acc;
            }, {});

            const confirmedGroups: TaskWeekGroup[] = Object.values(entriesByWeekAndTask).filter(group => 
                group.entries.some((e: any) => e.confirmation_status === "confirmed")
            );

            let pdfUrl: string | undefined;

            for (const group of confirmedGroups) {
                const taskId = group.taskId;
                const weekNumber = group.weekNumber;
                const year = group.year;

                const task = await prisma.tasks.findUnique({
                    where: { task_id: taskId },
                    select: { project_id: true, title: true }
                });
                const supervisor = await prisma.employees.findUnique({
                    where: { employee_id: supervisorId },
                    select: { name: true }
                });

                const detailedEntries = await prisma.workEntries.findMany({
                    where: { entry_id: { in: group.entries.map(e => e.entry_id) } },
                    include: {
                        Tasks: {
                            include: {
                                Projects: {
                                    include: {
                                        Customers: {
                                            select: {
                                                customer_id: true,
                                                name: true
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        Employees: true
                    }
                });

                const confirmedEntries = detailedEntries.filter((entry, index) => 
                    entry && group.entries[index].confirmation_status === "confirmed"
                );

                if (confirmedEntries.length > 0) {
                    const employeeId = confirmedEntries[0]?.employee_id;
                    const projectId = task?.project_id;

                    if (!employeeId || !projectId) {
                        throw new Error("Missing employee_id or project_id");
                    }

                    pdfUrl = await generateTimesheetPDF(
                        confirmedEntries,
                        supervisor?.name || "Unknown Supervisor",
                        signatureBase64,
                        employeeId,
                        projectId,
                        taskId,
                        weekNumber,
                        year
                    );

                    // Utwórz nowy rekord Timesheet
                    const timesheet = await prisma.timesheet.create({
                        data: {
                            task_id: taskId,
                            weekNumber,
                            year,
                            timesheetUrl: pdfUrl
                        }
                    });

                    // Powiąż rekordy WorkEntries z nowym Timesheet
                    await prisma.workEntries.updateMany({
                        where: { entry_id: { in: confirmedEntries.map(e => e.entry_id) } },
                        data: { timesheetId: timesheet.id }
                    });
                }
            }

            processingJobs.set(jobId, {
                status: 'completed',
                timesheetUrl: pdfUrl,
                createdAt: new Date(),
                requestHash
            });
        })();

        await Promise.race([pdfGenerationPromise, timeoutPromise]);
    } catch (error: any) {
        console.error("Error in background PDF processing:", error);
        processingJobs.set(jobId, {
            status: 'failed',
            error: error.message,
            createdAt: new Date(),
            requestHash
        });
        throw error;
    }
}

async function generateTimesheetPDF(
    entries: any[],
    supervisorName: string,
    signatureBase64: string,
    employeeId: number,
    projectId: number,
    taskId: number,
    weekNumber: number,
    year: number
): Promise<string> {
    const startTime = Date.now();
    console.log(`[generateTimesheetPDF] Start for job ${employeeId}-${taskId}-${weekNumber}-${year}`);

    try {
        const pdfDoc = await PDFDocument.create();
        const page = pdfDoc.addPage([595, 842]);
        const { width, height } = page.getSize();
        const font = await pdfDoc.embedFont('Helvetica');
        const fontSize = 12;
        const margin = 50;

        let yPosition = height - margin;

        const addText = async (text: string, size: number, options: { bold?: boolean; underline?: boolean; align?: 'left' | 'center' | 'right' } = {}) => {
            const fontToUse = options.bold ? await pdfDoc.embedFont('Helvetica-Bold') : font;
            page.drawText(text, {
                x: options.align === 'center' ? width / 2 : options.align === 'right' ? width - margin - text.length * size * 0.3 : margin,
                y: yPosition,
                size,
                font: fontToUse,
                color: rgb(0, 0, 0),
                lineHeight: size * 1.2,
                ...(options.align === 'center' && { maxWidth: width - 2 * margin, align: 'center' }),
            });
            if (options.underline) {
                const textWidth = fontToUse.widthOfTextAtSize(text, size);
                const xStart = options.align === 'center' ? (width - textWidth) / 2 : margin;
                page.drawLine({
                    start: { x: xStart, y: yPosition - 2 },
                    end: { x: xStart + textWidth, y: yPosition - 2 },
                    thickness: 1,
                    color: rgb(0, 0, 0),
                });
            }
            yPosition -= size * 1.5;
        };

        const logoImage = await pdfDoc.embedPng(logoBase64);
        const logoDims = logoImage.scaleToFit(150, 50);
        page.drawImage(logoImage, {
            x: margin,
            y: height - margin - logoDims.height,
            width: logoDims.width,
            height: logoDims.height,
        });
        yPosition -= logoDims.height + 10;

        await addText("KSR Cranes - Timesheet", 20, { align: 'center' });
        await addText("Professional Timesheet Confirmation", 14, { align: 'center' });
        yPosition -= 20;

        const firstEntry = entries[0];
        await addText("Timesheet Details", 12, { bold: true, underline: true });
        await addText(`Employee: ${firstEntry.Employees?.name || "Unknown"} (ID: ${firstEntry.employee_id})`, 12);
        await addText(`Task: ${firstEntry.Tasks?.title || "Unknown"} (ID: ${firstEntry.task_id})`, 12);
        await addText(`Project: ${firstEntry.Tasks?.Projects?.title || "Unknown"}`, 12);
        await addText(`Customer: ${firstEntry.Tasks?.Projects?.Customers?.name || "Unknown"}`, 12);
        await addText(`Week: ${weekNumber}, ${year}`, 12);
        yPosition -= 10;

        await addText("Work Hours", 12, { bold: true, underline: true });
        yPosition -= 5;
        const tableTop = yPosition;
        const columnWidths = [90, 90, 80, 80, 70, 60, 60];
        const headers = ["Date", "Day", "Start", "End", "Pause", "Hours", "Km"];
        for (let i = 0; i < headers.length; i++) {
            page.drawText(headers[i], {
                x: margin + columnWidths.slice(0, i).reduce((a, b) => a + b, 0),
                y: tableTop,
                size: 10,
                font: await pdfDoc.embedFont('Helvetica-Bold'),
                color: rgb(0, 0, 0),
            });
        }

        let rowTop = tableTop - 20;
        let totalHours = 0;
        let totalKm = 0;
        for (const entry of entries) {
            const date = new Date(entry.work_date).toLocaleDateString('da-DK');
            const day = new Date(entry.work_date).toLocaleDateString('da-DK', { weekday: 'long' });
            const start = entry.start_time ? new Date(entry.start_time).toLocaleTimeString('da-DK', { hour: '2-digit', minute: '2-digit' }) : "N/A";
            const end = entry.end_time ? new Date(entry.end_time).toLocaleTimeString('da-DK', { hour: '2-digit', minute: '2-digit' }) : "N/A";
            const pause = entry.pause_minutes != null ? `${entry.pause_minutes} min` : "N/A";
            const hours = calculateHours(entry.start_time, entry.end_time, entry.pause_minutes);
            const km = entry.km != null ? entry.km.toFixed(2) : "0.00";
            totalHours += parseFloat(hours);
            totalKm += parseFloat(km);

            const rowData = [date, day, start, end, pause, hours, km];
            for (let i = 0; i < rowData.length; i++) {
                page.drawText(rowData[i], {
                    x: margin + columnWidths.slice(0, i).reduce((a, b) => a + b, 0),
                    y: rowTop,
                    size: 10,
                    font,
                    color: rgb(0, 0, 0),
                });
            }
            rowTop -= 20;
        }

        yPosition = rowTop - 20;
        await addText(`Total Hours: ${totalHours.toFixed(2)}`, 12, { bold: true, align: 'right' });
        await addText(`Total Km: ${totalKm.toFixed(2)}`, 12, { bold: true, align: 'right' });
        yPosition -= 20;

        await addText("Approval", 12, { bold: true, underline: true });
        await addText(`Approved by: ${supervisorName}`, 12);
        await addText(`Confirmation Date: ${new Date().toLocaleDateString('da-DK')}`, 12);
        yPosition -= 10;

        await addText("Electronic Signature:", 12);
        const signatureBuffer = Buffer.from(signatureBase64, "base64");
        const signatureImage = await pdfDoc.embedPng(signatureBuffer);
        const signatureDims = signatureImage.scaleToFit(200, 60);
        page.drawImage(signatureImage, {
            x: margin,
            y: yPosition - signatureDims.height,
            width: signatureDims.width,
            height: signatureDims.height,
        });
        yPosition -= signatureDims.height + 20;

        await addText("Company Details", 12, { bold: true, underline: true });
        await addText("KSR Cranes", 12);
        await addText("Example Street 123, Copenhagen, Denmark", 12);
        await addText("CVR: 12345678", 12);
        yPosition -= 20;

        await addText("Thank you for your cooperation.", 10, { align: "center" });

        const pdfBytes = await pdfDoc.save();

        const fileName = `timesheet${employeeId}-${projectId}-${taskId}-week${weekNumber}-${year}.pdf`;
        const s3Path = `employee_${employeeId}/project_${projectId}/task_${taskId}/${fileName}`;

        const command = new PutObjectCommand({
            Bucket: process.env.KSR_TIMESHEETS_SPACES_BUCKET,
            Key: s3Path,
            Body: pdfBytes,
            ContentType: "application/pdf",
            ACL: "public-read",
        });

        await s3Clientksrtimesheets.send(command);

        const baseDomain = process.env.KSR_TIMESHEETS_SPACES_BUCKET + "." + process.env.KSR_TIMESHEETS_KEY_SPACES_ENDPOINT;
        const pdfUrl = `https://${baseDomain}/${s3Path}`;

        console.log(`[generateTimesheetPDF] Completed in ${Date.now() - startTime}ms`);
        return pdfUrl;
    } catch (e) {
        console.error("Error generating or uploading PDF:", e);
        throw new Error(`PDF generation or upload failed: ${e.message}`);
    }
}

function calculateHours(startTime: string | null, endTime: string | null, pauseMinutes: number | null): string {
    if (!startTime || !endTime) return "0.00";
    const start = new Date(startTime);
    const end = new Date(endTime);
    const interval = (end.getTime() - start.getTime()) / 1000;
    const pauseSeconds = (pauseMinutes || 0) * 60;
    const totalHours = Math.max(0, (interval - pauseSeconds) / 3600);
    return totalHours.toFixed(2);
}
