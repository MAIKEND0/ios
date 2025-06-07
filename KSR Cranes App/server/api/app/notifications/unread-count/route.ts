// =============================================================================
// PLIK 3: src/app/api/app/notifications/unread-count/route.ts
// =============================================================================

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../lib/prisma";
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

// GET - liczba nieprzeczytanych powiadomień
export async function GET(req: NextRequest) {
  try {
    const { id: employeeId } = await authenticate(req);

    const unreadCount = await prisma.notifications.count({
      where: {
        employee_id: employeeId,
        is_read: false,
      }
    });

    console.log(`[API] Unread notifications count for employee ${employeeId}: ${unreadCount}`);
    return NextResponse.json({ unread_count: unreadCount });
  } catch (e: any) {
    console.error("GET /api/app/notifications/unread-count error:", e);
    return NextResponse.json(
      { error: e.message },
      { status: e.message.includes("Unauthorized") ? 401 : 500 }
    );
  }
}
