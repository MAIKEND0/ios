// /api/app/supervisor/workers/route.ts
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
    const decoded = jwt.verify(auth[1], SECRET) as { id: number; role: string };
    
    // Allow both byggeleder and chef roles to access supervisor endpoints
    if (decoded.role !== "byggeleder" && decoded.role !== "chef") {
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
    
    console.log(`[SUPERVISOR WORKERS] 🔍 Fetching workers for supervisor ID: ${supervisorId}`);
    
    // Get workers assigned to tasks supervised by this supervisor
    const workers = await prisma.employees.findMany({
      where: {
        role: "arbejder", // Only workers
        is_activated: true,
        TaskAssignments: {
          some: {
            Tasks: {
              supervisor_id: supervisorId
            }
          }
        }
      },
      include: {
        TaskAssignments: {
          where: {
            Tasks: {
              supervisor_id: supervisorId
            }
          },
          include: {
            Tasks: {
              select: {
                task_id: true,
                title: true,
                description: true,
                deadline: true,
                supervisor_id: true,
                Projects: {
                  select: {
                    project_id: true,
                    title: true
                  }
                }
              }
            }
          }
        }
      }
    });

    // Transform the data to match expected format
    const formattedWorkers = workers.map(worker => ({
      employee_id: worker.employee_id,
      name: worker.name,
      email: worker.email,
      phone_number: worker.phone_number,
      assignedTasks: worker.TaskAssignments.map(assignment => {
        const task = assignment.Tasks;
        
        // Convert deadline to proper ISO string or null
        let deadline = task.deadline ? task.deadline.toISOString() : null;
        
        // Validate ISO 8601 format
        if (deadline && !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.*Z$/.test(deadline)) {
          console.warn(`[SUPERVISOR WORKERS] Invalid deadline format for task_id ${task.task_id}: ${deadline}`);
          deadline = null;
        }
        
        return {
          task_id: task.task_id,
          title: task.title,
          description: task.description,
          deadline,
          project: task.Projects ? {
            project_id: task.Projects.project_id,
            title: task.Projects.title
          } : null,
          supervisor_id: task.supervisor_id
        };
      })
    }));

    console.log(`[SUPERVISOR WORKERS] ✅ Found ${formattedWorkers.length} workers for supervisor ${supervisorId}`);
    
    return NextResponse.json(formattedWorkers);

  } catch (e: any) {
    console.error("[SUPERVISOR WORKERS] ❌ Error:", e);
    
    const isUnauthorized = e.message.includes("Unauthorized");
    return NextResponse.json(
      { error: e.message }, 
      { status: isUnauthorized ? 401 : 500 }
    );
  }
}