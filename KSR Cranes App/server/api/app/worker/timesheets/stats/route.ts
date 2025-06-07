// src/app/api/app/worker/timesheets/stats/route.ts
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";
import jwt from "jsonwebtoken";

const SECRET = process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET!;

console.log("[INIT] Loading worker timesheets stats endpoint module");

async function authenticate(req: NextRequest) {
    console.log("[worker/timesheets/stats] Starting authentication");
    const auth = req.headers.get("authorization")?.split(" ");
    if (auth?.[0] !== "Bearer" || !auth[1]) {
        console.log("[worker/timesheets/stats] No bearer token provided");
        throw new Error("Unauthorized");
    }
    try {
        const decoded = jwt.verify(auth[1], SECRET) as { id: number, role: string };
        if (decoded.role !== "arbejder") {
            console.log(`[worker/timesheets/stats] Invalid role: ${decoded.role}`);
            throw new Error("Unauthorized: Invalid role");
        }
        console.log(`[worker/timesheets/stats] Authentication successful: worker ID=${decoded.id}`);
        return decoded;
    } catch (error) {
        console.log("[worker/timesheets/stats] JWT verification failed:", error);
        throw new Error("Invalid token");
    }
}

export async function GET(req: NextRequest) {
    console.log("[worker/timesheets/stats] Received GET request");
    try {
        const { id: workerId } = await authenticate(req);
        
        // Get employee_id from query params
        const { searchParams } = new URL(req.url);
        const employeeId = searchParams.get('employee_id');
        
        if (!employeeId) {
            console.log("[worker/timesheets/stats] Missing employee_id parameter");
            return NextResponse.json(
                { error: "employee_id parameter is required" },
                { status: 400 }
            );
        }

        // Verify that the authenticated worker matches the requested employee_id
        const employeeIdNum = parseInt(employeeId, 10);
        if (workerId !== employeeIdNum) {
            console.log(`[worker/timesheets/stats] Worker ${workerId} trying to access stats for employee ${employeeIdNum}`);
            return NextResponse.json(
                { error: "Unauthorized: Cannot access other employee's statistics" },
                { status: 403 }
            );
        }

        console.log(`[worker/timesheets/stats] Fetching statistics for employeeId=${employeeIdNum}`);
        
        // Get current date info
        const now = new Date();
        const currentWeek = getWeek(now);
        const currentYear = now.getFullYear();
        const currentMonth = now.getMonth() + 1;

        // Fetch all timesheets for the worker
        const allTimesheets = await prisma.timesheet.findMany({
            where: {
                WorkEntries: {
                    some: {
                        employee_id: employeeIdNum,
                        confirmation_status: "confirmed"
                    }
                }
            },
            select: {
                id: true,
                task_id: true,
                weekNumber: true,
                year: true,
                created_at: true,
                updated_at: true
            }
        });

        // Calculate this week's timesheets
        const thisWeekTimesheets = allTimesheets.filter(t => 
            t.weekNumber === currentWeek && t.year === currentYear
        );

        // Calculate this month's timesheets
        const thisMonthTimesheets = allTimesheets.filter(t => {
            // Convert week number to month
            const date = getDateFromWeekNumber(t.weekNumber, t.year);
            return date.getMonth() + 1 === currentMonth && t.year === currentYear;
        });

        // Get unique tasks
        const uniqueTasks = new Set(allTimesheets.map(t => t.task_id));

        // Find oldest and newest timesheets
        const sortedTimesheets = allTimesheets.sort((a, b) => {
            if (a.year !== b.year) return a.year - b.year;
            return a.weekNumber - b.weekNumber;
        });

        const oldestTimesheet = sortedTimesheets[0];
        const newestTimesheet = sortedTimesheets[sortedTimesheets.length - 1];

        // Get detailed stats for current period
        const currentPeriodStats = await prisma.workEntries.aggregate({
            where: {
                employee_id: employeeIdNum,
                confirmation_status: "confirmed",
                work_date: {
                    gte: getStartOfWeek(now),
                    lte: getEndOfWeek(now)
                }
            },
            _sum: {
                km: true,
                pause_minutes: true
            },
            _count: {
                entry_id: true
            }
        });

        // Get monthly stats
        const monthlyStats = await prisma.workEntries.aggregate({
            where: {
                employee_id: employeeIdNum,
                confirmation_status: "confirmed",
                work_date: {
                    gte: new Date(currentYear, currentMonth - 1, 1),
                    lt: new Date(currentYear, currentMonth, 1)
                }
            },
            _sum: {
                km: true,
                pause_minutes: true
            },
            _count: {
                entry_id: true
            }
        });

        const stats = {
            totalTimesheets: allTimesheets.length,
            thisWeekTimesheets: thisWeekTimesheets.length,
            thisMonthTimesheets: thisMonthTimesheets.length,
            uniqueTasks: uniqueTasks.size,
            oldestTimesheet: oldestTimesheet ? {
                weekNumber: oldestTimesheet.weekNumber,
                year: oldestTimesheet.year,
                date: oldestTimesheet.created_at?.toISOString() || null
            } : null,
            newestTimesheet: newestTimesheet ? {
                weekNumber: newestTimesheet.weekNumber,
                year: newestTimesheet.year,
                date: newestTimesheet.created_at?.toISOString() || null
            } : null,
            currentWeekStats: {
                entries: currentPeriodStats._count.entry_id,
                totalKm: currentPeriodStats._sum.km ? parseFloat(currentPeriodStats._sum.km.toString()) : 0,
                totalPauseMinutes: currentPeriodStats._sum.pause_minutes || 0
            },
            currentMonthStats: {
                entries: monthlyStats._count.entry_id,
                totalKm: monthlyStats._sum.km ? parseFloat(monthlyStats._sum.km.toString()) : 0,
                totalPauseMinutes: monthlyStats._sum.pause_minutes || 0
            }
        };

        console.log("[worker/timesheets/stats] Returning statistics");
        return NextResponse.json(stats);
    } catch (e: any) {
        console.error("[worker/timesheets/stats] GET /api/app/worker/timesheets/stats error:", e);
        return NextResponse.json(
            { error: e.message },
            { status: e.message.includes("Unauthorized") ? 401 : 
                     e.message.includes("Cannot access") ? 403 : 500 }
        );
    }
}

// Helper functions
function getWeek(date: Date): number {
    const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
    const weekNo = Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
    return weekNo;
}

function getDateFromWeekNumber(weekNumber: number, year: number): Date {
    const jan1 = new Date(year, 0, 1);
    const daysOffset = (weekNumber - 1) * 7;
    const date = new Date(jan1.getTime() + daysOffset * 24 * 60 * 60 * 1000);
    return date;
}

function getStartOfWeek(date: Date): Date {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1); // Adjust when day is Sunday
    return new Date(d.setDate(diff));
}

function getEndOfWeek(date: Date): Date {
    const startOfWeek = getStartOfWeek(date);
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(endOfWeek.getDate() + 6);
    endOfWeek.setHours(23, 59, 59, 999);
    return endOfWeek;
}