import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import { createNotification } from "../../../../lib/notificationService";
import jwt from "jsonwebtoken";

const SECRET = process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET!;

async function authenticate(req: NextRequest) {
  const auth = req.headers.get("authorization")?.split(" ");
  if (auth?.[0] !== "Bearer" || !auth[1]) {
    throw new Error("Unauthorized");
  }
  try {
    const decoded = jwt.verify(auth[1], SECRET) as { id: number; role: string };
    return decoded;
  } catch {
    throw new Error("Invalid token");
  }
}

// GET - pobieranie powiadomień dla pracownika
export async function GET(req: NextRequest) {
  try {
    const { id: employeeId } = await authenticate(req);
    
    const { searchParams } = new URL(req.url);
    const limitParam = searchParams.get("limit");
    const unreadOnlyParam = searchParams.get("unread_only");
    const typeParam = searchParams.get("type");
    const sinceParam = searchParams.get("since");
    
    const limit = limitParam ? parseInt(limitParam) : 50;
    const unreadOnly = unreadOnlyParam === "true";

    const where: any = {
      employee_id: employeeId,
    };

    if (unreadOnly) {
      where.is_read = false;
    }

    if (typeParam) {
      where.notification_type = typeParam;
    }

    if (sinceParam) {
      const sinceDate = new Date(sinceParam);
      if (!isNaN(sinceDate.getTime())) {
        where.created_at = {
          gte: sinceDate
        };
      }
    }

    // ✅ POPRAWKA: Dodano obsługę relacji z Projects i pełne pola
    const notifications = await prisma.notifications.findMany({
      where,
      include: {
        Projects: {
          select: {
            title: true
          }
        }
      },
      orderBy: [
        { priority: "asc" }, // URGENT first, then HIGH, etc.
        { created_at: "desc" }
      ],
      take: limit,
    });

    // ✅ POPRAWKA: Formatowanie response z project_title
    const formattedNotifications = notifications.map(notification => ({
      notification_id: notification.notification_id,
      employee_id: notification.employee_id,
      notification_type: notification.notification_type,
      title: notification.title,
      message: notification.message,
      is_read: notification.is_read,
      created_at: notification.created_at,
      updated_at: notification.updated_at,
      work_entry_id: notification.work_entry_id,
      task_id: notification.task_id,
      project_id: notification.project_id,
      project_title: notification.Projects?.title || null,
      priority: notification.priority,
      category: notification.category,
      action_required: notification.action_required,
      action_url: notification.action_url,
      expires_at: notification.expires_at,
      read_at: notification.read_at,
      sender_id: notification.sender_id,
      target_employee_id: notification.target_employee_id,
      target_role: notification.target_role,
      metadata: notification.metadata,
    }));

    // ✅ POPRAWKA: Response zgodny z NotificationsResponse w Swift
    const response = {
      notifications: formattedNotifications,
      total_count: formattedNotifications.length,
      unread_count: formattedNotifications.filter(n => !n.is_read).length
    };

    console.log(`[API] Fetched ${formattedNotifications.length} notifications for employee ${employeeId}`);
    return NextResponse.json(response);
  } catch (e: any) {
    console.error("GET /api/app/notifications error:", e);
    return NextResponse.json(
      { error: e.message },
      { status: e.message.includes("Unauthorized") ? 401 : 500 }
    );
  }
}

// POST - tworzenie nowego powiadomienia (dla testowania)
export async function POST(req: NextRequest) {
  try {
    const { id: employeeId, role } = await authenticate(req);
    
    // Tylko administratorzy mogą tworzyć powiadomienia
    if (role !== "system" && role !== "chef") {
      return NextResponse.json(
        { error: "Insufficient permissions" },
        { status: 403 }
      );
    }

    const body = await req.json();
    const {
      target_employee_id,
      notification_type,
      title,
      message,
      work_entry_id,
      task_id,
      project_id,
      priority = "NORMAL",
      category = "SYSTEM",
      action_required = false,
      action_url,
      expires_at,
      target_role,
      metadata
    } = body;

    // Walidacja wymaganych pól
    if (!target_employee_id || !notification_type || !title || !message) {
      return NextResponse.json(
        { error: "Missing required fields: target_employee_id, notification_type, title, message" },
        { status: 400 }
      );
    }

    // Sprawdź czy target employee istnieje
    const targetEmployee = await prisma.employees.findUnique({
      where: { employee_id: target_employee_id }
    });

    if (!targetEmployee) {
      return NextResponse.json(
        { error: "Target employee not found" },
        { status: 404 }
      );
    }

    const notification = await createNotification({
      employeeId: target_employee_id,
      type: notification_type,
      title,
      message,
      workEntryId: work_entry_id || undefined,
      taskId: task_id || undefined,
      projectId: project_id || undefined,
      priority,
      category,
      actionRequired: action_required,
      actionUrl: action_url || undefined,
      expiresAt: expires_at ? new Date(expires_at) : undefined,
      senderId: employeeId,
      targetEmployeeId: target_employee_id,
      targetRole: target_role || undefined,
      metadata: metadata || undefined,
    });

    console.log(`[API] Created notification ${notification.notification_id} for employee ${target_employee_id} with push notification`);
    
    return NextResponse.json({
      success: true,
      notification_id: notification.notification_id,
      message: "Notification created successfully"
    });

  } catch (e: any) {
    console.error("POST /api/app/notifications error:", e);
    return NextResponse.json(
      { error: e.message },
      { status: 500 }
    );
  }
}
