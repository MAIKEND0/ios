// src/app/api/app/worker/timesheets/route.ts
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";
import jwt from "jsonwebtoken";

const SECRET = process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET!;

console.log("[INIT] Loading worker timesheets endpoint module");

async function authenticate(req: NextRequest) {
    console.log("[worker/timesheets] Starting authentication");
    const auth = req.headers.get("authorization")?.split(" ");
    if (auth?.[0] !== "Bearer" || !auth[1]) {
        console.log("[worker/timesheets] No bearer token provided");
        throw new Error("Unauthorized");
    }
    try {
        const decoded = jwt.verify(auth[1], SECRET) as { id: number, role: string };
        if (decoded.role !== "arbejder") {
            console.log(`[worker/timesheets] Invalid role: ${decoded.role}`);
            throw new Error("Unauthorized: Invalid role");
        }
        console.log(`[worker/timesheets] Authentication successful: worker ID=${decoded.id}`);
        return decoded;
    } catch (error) {
        console.log("[worker/timesheets] JWT verification failed:", error);
        throw new Error("Invalid token");
    }
}

export async function GET(req: NextRequest) {
    console.log("[worker/timesheets] Received GET request");
    try {
        const { id: workerId } = await authenticate(req);
        
        // Get employee_id from query params (required for iOS app)
        const { searchParams } = new URL(req.url);
        const employeeId = searchParams.get('employee_id');
        
        if (!employeeId) {
            console.log("[worker/timesheets] Missing employee_id parameter");
            return NextResponse.json(
                { error: "employee_id parameter is required" },
                { status: 400 }
            );
        }

        // Verify that the authenticated worker matches the requested employee_id
        const employeeIdNum = parseInt(employeeId, 10);
        if (workerId !== employeeIdNum) {
            console.log(`[worker/timesheets] Worker ${workerId} trying to access timesheets for employee ${employeeIdNum}`);
            return NextResponse.json(
                { error: "Unauthorized: Cannot access other employee's timesheets" },
                { status: 403 }
            );
        }

        console.log(`[worker/timesheets] Fetching timesheets for employeeId=${employeeIdNum}`);
        
        // Fetch timesheets where the worker has confirmed entries
        const timesheets = await prisma.timesheet.findMany({
            where: {
                WorkEntries: {
                    some: {
                        employee_id: employeeIdNum,
                        confirmation_status: "confirmed" // Only show confirmed timesheets
                    }
                }
            },
            include: {
                WorkEntries: {
                    where: {
                        employee_id: employeeIdNum,
                        confirmation_status: "confirmed"
                    },
                    include: {
                        Tasks: {
                            select: {
                                task_id: true,
                                title: true,
                                description: true,
                                Projects: {
                                    select: {
                                        project_id: true,
                                        title: true,
                                        Customers: {
                                            select: {
                                                customer_id: true,
                                                name: true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            orderBy: [
                { year: 'desc' },
                { weekNumber: 'desc' }
            ]
        });

        console.log(`[worker/timesheets] Found ${timesheets.length} timesheets`);

        // Format response
        const formattedTimesheets = timesheets.map((timesheet) => {
            // Get task info from the first work entry
            const firstEntry = timesheet.WorkEntries[0];
            const task = firstEntry?.Tasks;
            
            return {
                id: timesheet.id,
                task_id: timesheet.task_id,
                employee_id: employeeIdNum,
                weekNumber: timesheet.weekNumber,
                year: timesheet.year,
                timesheetUrl: timesheet.timesheetUrl,
                created_at: timesheet.created_at?.toISOString() || null,
                updated_at: timesheet.updated_at?.toISOString() || null,
                Tasks: task ? {
                    task_id: task.task_id,
                    title: task.title,
                    description: task.description,
                    project: task.Projects ? {
                        project_id: task.Projects.project_id,
                        title: task.Projects.title,
                        customer: task.Projects.Customers ? {
                            customer_id: task.Projects.Customers.customer_id,
                            name: task.Projects.Customers.name
                        } : null
                    } : null
                } : null,
                entriesCount: timesheet.WorkEntries.length,
                totalHours: timesheet.WorkEntries.reduce((sum, entry) => {
                    if (entry.start_time && entry.end_time) {
                        const start = new Date(entry.start_time);
                        const end = new Date(entry.end_time);
                        const hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60);
                        const pauseHours = (entry.pause_minutes || 0) / 60;
                        return sum + Math.max(0, hours - pauseHours);
                    }
                    return sum;
                }, 0),
                totalKm: timesheet.WorkEntries.reduce((sum, entry) => {
                    // Handle Prisma Decimal type
                    const km = entry.km ? parseFloat(entry.km.toString()) : 0;
                    return sum + km;
                }, 0)
            };
        });

        console.log("[worker/timesheets] Returning formatted timesheets");
        return NextResponse.json(formattedTimesheets);
    } catch (e: any) {
        console.error("[worker/timesheets] GET /api/app/worker/timesheets error:", e);
        return NextResponse.json(
            { error: e.message },
            { status: e.message.includes("Unauthorized") ? 401 : 
                     e.message.includes("Cannot access") ? 403 : 500 }
        );
    }
}