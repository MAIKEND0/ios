// src/app/api/app/projects/route.ts - SIMPLE FIX

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import jwt from "jsonwebtoken";

const SECRET = process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET!;

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

export async function GET(req: NextRequest) {
    try {
        const { id: supervisorId } = await authenticate(req);

        const projects = await prisma.projects.findMany({
            where: {
                Tasks: {
                    some: {
                        supervisor_id: supervisorId
                    }
                }
            },
            include: {
                // DODANE: Customer info
                Customers: {
                    select: {
                        customer_id: true,
                        name: true,
                        contact_email: true,
                        phone: true
                    }
                },
                // DODANE: Tasks z TaskAssignments 
                Tasks: {
                    where: {
                        supervisor_id: supervisorId,
                        isActive: true
                    },
                    select: {
                        task_id: true,
                        title: true,
                        description: true,
                        deadline: true,
                        supervisor_id: true,
                        TaskAssignments: {
                            select: {
                                employee_id: true,
                                Employees: {
                                    select: {
                                        employee_id: true,
                                        name: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        });

        // Format response
        const formattedProjects = projects.map(project => {
            // Count unique workers
            const uniqueWorkers = new Set(
                project.Tasks.flatMap(task => 
                    task.TaskAssignments.map(assignment => assignment.employee_id)
                )
            );

            return {
                project_id: project.project_id,
                title: project.title,
                description: project.description,
                start_date: project.start_date?.toISOString(),
                end_date: project.end_date?.toISOString(),
                street: project.street,
                city: project.city,
                zip: project.zip,
                status: project.status,
                
                // DODANE: Customer info
                customer: project.Customers ? {
                    customer_id: project.Customers.customer_id,
                    name: project.Customers.name,
                    contact_email: project.Customers.contact_email,
                    phone: project.Customers.phone
                } : null,
                
                // DODANE: Tasks count i workers count
                tasks: project.Tasks,
                assignedWorkersCount: uniqueWorkers.size
            };
        });

        return NextResponse.json(formattedProjects);
    } catch (e: any) {
        console.error("GET /api/app/projects error:", e);
        return NextResponse.json({ error: e.message }, { status: e.message.includes("Unauthorized") ? 401 : 500 });
    }
}