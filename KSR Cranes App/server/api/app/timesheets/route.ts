//src/app/api/app/timesheets/route.ts
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import jwt from "jsonwebtoken";

const SECRET = process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET!;

console.log("[INIT] Loading timesheets endpoint module");

async function authenticate(req: NextRequest) {
    console.log("[timesheets] Starting authentication");
    const auth = req.headers.get("authorization")?.split(" ");
    if (auth?.[0] !== "Bearer" || !auth[1]) {
        console.log("[timesheets] No bearer token provided");
        throw new Error("Unauthorized");
    }
    try {
        const decoded = jwt.verify(auth[1], SECRET) as { id: number, role: string };
        if (decoded.role !== "byggeleder") {
            console.log(`[timesheets] Invalid role: ${decoded.role}`);
            throw new Error("Unauthorized: Invalid role");
        }
        console.log(`[timesheets] Authentication successful: supervisor ID=${decoded.id}`);
        return decoded;
    } catch (error) {
        console.log("[timesheets] JWT verification failed:", error);
        throw new Error("Invalid token");
    }
}

export async function GET(req: NextRequest) {
    console.log("[timesheets] Received GET request");
    try {
        const { id: supervisorId } = await authenticate(req);

        console.log(`[timesheets] Fetching timesheets for supervisorId=${supervisorId}`);
        const timesheets = await prisma.timesheet.findMany({
            where: {
                WorkEntries: {
                    some: {
                        Tasks: {
                            supervisor_id: supervisorId,
                        },
                    },
                },
            },
            include: {
                WorkEntries: {
                    include: {
                        Tasks: {
                            select: {
                                task_id: true,
                                title: true,
                            },
                        },
                        Employees: {
                            select: {
                                name: true,
                            },
                        },
                    },
                    take: 1, // Limit to one entry to get employee_id
                },
            },
        });

        console.log(`[timesheets] Found ${timesheets.length} timesheets`);

        // Format response with ISO 8601 dates
        const formattedTimesheets = timesheets.map((timesheet) => {
            const workEntry = timesheet.WorkEntries[0] || null;
            return {
                id: timesheet.id,
                task_id: timesheet.task_id,
                employee_id: workEntry?.employee_id ?? null,
                weekNumber: timesheet.weekNumber,
                year: timesheet.year,
                timesheetUrl: timesheet.timesheetUrl,
                created_at: timesheet.created_at?.toISOString() || null,
                updated_at: timesheet.updated_at?.toISOString() || null,
                Tasks: workEntry?.Tasks || null,
                Employees: workEntry?.Employees || null,
            };
        });

        console.log("[timesheets] Returning formatted timesheets");
        return NextResponse.json(formattedTimesheets);
    } catch (e: any) {
        console.error("[timesheets] GET /api/app/timesheets error:", e);
        return NextResponse.json(
            { error: e.message },
            { status: e.message.includes("Unauthorized") ? 401 : 500 },
        );
    }
}