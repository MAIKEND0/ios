// Corrected code for src/app/api/app/signature/route.ts
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import jwt from "jsonwebtoken";
import { s3Clientksrtimesheets } from "../../../../lib/s3Clientksrtimesheets";
import { PutObjectCommand } from "@aws-sdk/client-s3";
import { v4 as uuidv4 } from 'uuid';

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

export async function POST(req: NextRequest) {
    try {
        const { id: supervisorId } = await authenticate(req);
        const { signatureBase64 } = await req.json();

        if (!signatureBase64) {
            return NextResponse.json({ error: "signatureBase64 is required" }, { status: 400 });
        }

        const signatureId = uuidv4();
        const s3Path = `supervisor_${supervisorId}/signatures/${signatureId}.png`;

        const signatureBuffer = Buffer.from(signatureBase64, "base64");
        const command = new PutObjectCommand({
            Bucket: process.env.KSR_TIMESHEETS_SPACES_BUCKET,
            Key: s3Path,
            Body: signatureBuffer,
            ContentType: "image/png",
            ACL: "public-read",
        });

        await s3Clientksrtimesheets.send(command);

        const baseDomain = process.env.KSR_TIMESHEETS_SPACES_BUCKET + "." + process.env.KSR_TIMESHEETS_KEY_SPACES_ENDPOINT;
        const signatureUrl = `https://${baseDomain}/${s3Path}`;

        // Dezaktywuj poprzednie podpisy supervisora - using correct field names
        await prisma.supervisorSignatures.updateMany({
            where: { supervisor_id: supervisorId, is_active: true },
            data: { is_active: false },
        });

        // Zapisz nowy podpis - using correct field names
        await prisma.supervisorSignatures.create({
            data: {
                signature_id: signatureId,
                supervisor_id: supervisorId,
                signature_url: signatureUrl,
                created_at: new Date(),
                is_active: true,
            },
        });

        return NextResponse.json({ signatureId, signatureUrl }, { status: 201 });
    } catch (e: any) {
        console.error("Error in POST /api/app/signature:", e);
        return NextResponse.json({ error: e.message }, { status: e.message === "Unauthorized" ? 401 : 500 });
    }
}