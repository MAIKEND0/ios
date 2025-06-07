// Na samym początku pliku - log inicjalizacji
console.log("[INIT] Loading upload-timesheet endpoint module");

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import jwt from "jsonwebtoken";
import { s3Clientksrtimesheets } from "../../../../lib/s3Clientksrtimesheets";
import { PutObjectCommand } from "@aws-sdk/client-s3";

// Log zmiennych środowiskowych (bez ujawniania wartości)
console.log("[upload-timesheet] Environment variables check: JWT_SECRET=", !!process.env.JWT_SECRET, 
            "KSR_TIMESHEETS_KEY=", !!process.env.KSR_TIMESHEETS_KEY,
            "KSR_TIMESHEETS_SECRET=", !!process.env.KSR_TIMESHEETS_SECRET,
            "KSR_TIMESHEETS_SPACES_BUCKET=", !!process.env.KSR_TIMESHEETS_SPACES_BUCKET,
            "KSR_TIMESHEETS_KEY_SPACES_ENDPOINT=", !!process.env.KSR_TIMESHEETS_KEY_SPACES_ENDPOINT);

const SECRET = process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET!;

async function authenticate(req: NextRequest) {
    console.log("[upload-timesheet] Starting authentication");
    const auth = req.headers.get("authorization")?.split(" ");
    if (auth?.[0] !== "Bearer" || !auth[1]) {
        console.log("[upload-timesheet] No bearer token provided");
        throw new Error("Unauthorized");
    }
    try {
        const decoded = jwt.verify(auth[1], SECRET) as { id: number, role: string };
        if (decoded.role !== "byggeleder") {
            console.log(`[upload-timesheet] Invalid role: ${decoded.role}`);
            throw new Error("Unauthorized: Invalid role");
        }
        console.log(`[upload-timesheet] Authentication successful: supervisor ID=${decoded.id}`);
        return decoded;
    } catch (error) {
        console.log("[upload-timesheet] JWT verification failed:", error);
        throw new Error("Invalid token");
    }
}

export async function POST(req: NextRequest) {
    console.log("[upload-timesheet] Received POST request");
    try {
        if (!process.env.JWT_SECRET || !process.env.KSR_TIMESHEETS_KEY || !process.env.KSR_TIMESHEETS_SECRET || 
            !process.env.KSR_TIMESHEETS_SPACES_BUCKET || !process.env.KSR_TIMESHEETS_KEY_SPACES_ENDPOINT) {
            console.log("[upload-timesheet] Required environment variables are missing");
            throw new Error("Required environment variables are missing");
        }
        
        // Authenticate the request
        const { id: supervisorId } = await authenticate(req);
        
        console.log("[upload-timesheet] Parsing form data");
        const formData = await req.formData();
        const pdfFile = formData.get('pdf') as File;
        const employeeId = Number(formData.get('employeeId'));
        const taskId = Number(formData.get('taskId'));
        const weekNumber = Number(formData.get('weekNumber'));
        const year = Number(formData.get('year'));
        const entriesJson = formData.get('entries') as string;
        
        console.log(`[upload-timesheet] Form data: employeeId=${employeeId}, taskId=${taskId}, weekNumber=${weekNumber}, year=${year}`);
        console.log(`[upload-timesheet] PDF file size: ${pdfFile?.size || 'No file'}`);
        
        if (!pdfFile || !employeeId || !taskId || !weekNumber || !year || !entriesJson) {
            console.log("[upload-timesheet] Missing required fields");
            return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
        }
        
        // Parse the entries JSON
        const entryIds = JSON.parse(entriesJson) as number[];
        console.log(`[upload-timesheet] Entry IDs: ${entryIds.join(', ')}`);
        
        // Validate entries and km values
        console.log("[upload-timesheet] Validating work entries");
        const entries = await prisma.workEntries.findMany({
            where: { entry_id: { in: entryIds } },
            select: { entry_id: true, km: true },
        });

        if (entries.length !== entryIds.length) {
            console.log("[upload-timesheet] Some entries not found");
            return NextResponse.json({ error: "Some entries not found" }, { status: 404 });
        }

        // Validate km values
        console.log("[upload-timesheet] Validating km values for entries");
        const invalidKmEntries = entries.some((entry) => {
            if (entry.km == null) {
                console.log(`[upload-timesheet] Missing km for entry_id=${entry.entry_id}`);
                return true;
            }
            if (entry.km.toNumber() < 0) { // Poprawka: konwersja Decimal na number  number
                console.log(`[upload-timesheet] Negative km value for entry_id=${entry.entry_id}: ${entry.km}`);
                return true;
            }
            return false;
        });
        if (invalidKmEntries) {
            return NextResponse.json(
                { error: "Invalid or missing km values in entries" },
                { status: 400 }
            );
        }
        
        // Get the project ID from the task
        console.log(`[upload-timesheet] Fetching task data for taskId=${taskId}`);
        const task = await prisma.tasks.findUnique({
            where: { task_id: taskId },
            select: { project_id: true }
        });
        
        if (!task) {
            console.log(`[upload-timesheet] Task not found: taskId=${taskId}`);
            return NextResponse.json({ error: "Task not found" }, { status: 404 });
        }
        
        const projectId = task.project_id;
        console.log(`[upload-timesheet] Found project ID: ${projectId}`);
        
        // Convert the file to a buffer
        console.log("[upload-timesheet] Converting file to buffer");
        const pdfBuffer = Buffer.from(await pdfFile.arrayBuffer());
        
        // Construct the file path in S3 - using the same format as in timesheet/route.ts
        const fileName = `timesheet${employeeId}-${projectId}-${taskId}-week${weekNumber}-${year}.pdf`;
        const s3Path = `employee_${employeeId}/project_${projectId}/task_${taskId}/${fileName}`;
        console.log(`[upload-timesheet] S3 path: ${s3Path}`);
        
        // Upload to S3
        console.log("[upload-timesheet] Starting S3 upload");
        const command = new PutObjectCommand({
            Bucket: process.env.KSR_TIMESHEETS_SPACES_BUCKET!,
            Key: s3Path,
            Body: pdfBuffer,
            ContentType: "application/pdf",
            ACL: "public-read",
        });
        
        await s3Clientksrtimesheets.send(command);
        console.log("[upload-timesheet] S3 upload successful");
        
        // Generate the URL for the uploaded file
        const baseDomain = process.env.KSR_TIMESHEETS_SPACES_BUCKET + "." + process.env.KSR_TIMESHEETS_KEY_SPACES_ENDPOINT;
        const pdfUrl = `https://${baseDomain}/${s3Path}`;
        console.log(`[upload-timesheet] PDF URL: ${pdfUrl}`);
        
        // Create a timesheet record in the database
        console.log("[upload-timesheet] Creating timesheet record in database");
        const timesheet = await prisma.timesheet.create({
            data: {
                task_id: taskId,
                weekNumber: weekNumber,
                year: year,
                timesheetUrl: pdfUrl
            }
        });
        console.log(`[upload-timesheet] Timesheet record created: ID=${timesheet.id}`);
        
        // Update the WorkEntries with the timesheet ID
        console.log(`[upload-timesheet] Updating work entries with timesheetId=${timesheet.id}`);
        await prisma.workEntries.updateMany({
            where: { entry_id: { in: entryIds } },
            data: { timesheetId: timesheet.id }
        });
        console.log("[upload-timesheet] Work entries updated successfully");
        
        console.log("[upload-timesheet] Request processed successfully");
        return NextResponse.json({
            success: true,
            timesheetUrl: pdfUrl,
            message: "PDF uploaded successfully"
        });
        
    } catch (error: any) {
        console.error("[upload-timesheet] Error:", error);
        return NextResponse.json({ 
            error: error.message 
        }, { 
            status: error.message.includes("Unauthorized") ? 401 
                  : error.message.includes("not found") ? 404
                  : error.message.includes("Invalid or missing km") ? 400
                  : 500 
        });
    }
}