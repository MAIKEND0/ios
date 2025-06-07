// src/app/api/app/notifications/[id]/read/route.ts
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";
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

// PATCH - oznacz powiadomienie jako przeczytane
export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: employeeId } = await authenticate(req);
    const { id } = await params; // Odczytanie id z Promise
    const notificationId = parseInt(id);

    if (isNaN(notificationId)) {
      return NextResponse.json(
        { error: "Invalid notification ID" },
        { status: 400 }
      );
    }

    // Sprawdź czy powiadomienie należy do tego pracownika
    const notification = await prisma.notifications.findUnique({
      where: { notification_id: notificationId },
      select: { employee_id: true, is_read: true },
    });

    if (!notification) {
      return NextResponse.json(
        { error: "Notification not found" },
        { status: 404 }
      );
    }

    if (notification.employee_id !== employeeId) {
      return NextResponse.json(
        { error: "Unauthorized: Not your notification" },
        { status: 403 }
      );
    }

    // Oznacz jako przeczytane
    const updatedNotification = await prisma.notifications.update({
      where: { notification_id: notificationId },
      data: { is_read: true },
    });

    console.log(`[API] Marked notification ${notificationId} as read for employee ${employeeId}`);
    return NextResponse.json({
      success: true,
      notification: updatedNotification,
    });
  } catch (e: any) {
    console.error("PATCH /api/app/notifications/[id]/read error:", e);
    return NextResponse.json(
      { error: e.message },
      { status: e.message.includes("Unauthorized") ? 401 : 500 }
    );
  }
}