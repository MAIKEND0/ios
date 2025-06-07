// /api/app/chef/workers/[id]/profile-image - Upload zdjęć profilowych na S3
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";
import {
  PutObjectCommand,
  DeleteObjectCommand,
  PutObjectCommandInput,
  DeleteObjectCommandInput,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { s3Client } from "../../../../../../../lib/s3Client";

const BUCKET_NAME = "ksrcranes-storage-bucket";

// POST /api/app/chef/workers/[id]/profile-image - Upload zdjęcia profilowego
export async function POST(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    // Sprawdzenie czy pracownik istnieje
    const worker = await prisma.employees.findUnique({
      where: { 
        employee_id: workerId,
        role: { in: ['arbejder', 'byggeleder'] as any }
      }
    });

    if (!worker) {
      return NextResponse.json({ error: "Worker not found" }, { status: 404 });
    }

    const formData = await request.formData();
    const file = formData.get("profile_image") as File;

    if (!file) {
      return NextResponse.json({ error: "No profile image provided" }, { status: 400 });
    }

    // Walidacja typu pliku
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
      return NextResponse.json(
        { error: "Invalid file type. Only JPEG, PNG, and WebP are allowed." },
        { status: 400 }
      );
    }

    // Walidacja rozmiaru (max 5MB)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      return NextResponse.json(
        { error: "File too large. Maximum size is 5MB." },
        { status: 400 }
      );
    }

    // Usunięcie poprzedniego zdjęcia profilowego jeśli istnieje
    if (worker.profilePictureUrl) {
      try {
        const oldKey = extractS3KeyFromUrl(worker.profilePictureUrl);
        if (oldKey) {
          await s3Client.send(new DeleteObjectCommand({
            Bucket: BUCKET_NAME,
            Key: oldKey
          }));
        }
      } catch (error) {
        console.warn("Could not delete old profile image:", error);
      }
    }

    // Przygotowanie pliku do uploadu
    const arrayBuffer = await file.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    
    // Generowanie unikalnej nazwy pliku
    const fileExtension = file.name.split('.').pop() || 'jpg';
    const fileName = `profile_${workerId}_${Date.now()}.${fileExtension}`;
    const key = `worker-profiles/${workerId}/${fileName}`;

    // Upload do S3
    const putParams: PutObjectCommandInput = {
      Bucket: BUCKET_NAME,
      Key: key,
      Body: buffer,
      ContentType: file.type,
      ACL: "public-read",
      Metadata: {
        'original-name': file.name,
        'worker-id': workerId.toString(),
        'upload-date': new Date().toISOString()
      }
    };

    await s3Client.send(new PutObjectCommand(putParams));

    // Generowanie publicznego URL
    const profilePictureUrl = `https://${BUCKET_NAME}.s3.amazonaws.com/${key}`;

    // Aktualizacja w bazie danych
    const updatedWorker = await prisma.employees.update({
      where: { employee_id: workerId },
      data: { profilePictureUrl }
    });

    console.log(`Profile image uploaded for worker ${workerId}: ${profilePictureUrl}`);

    return NextResponse.json({
      success: true,
      message: "Profile image uploaded successfully",
      profile_picture_url: profilePictureUrl
    });

  } catch (error: any) {
    console.error("Error uploading profile image:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// DELETE /api/app/chef/workers/[id]/profile-image - Usuwanie zdjęcia profilowego
export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    // Sprawdzenie czy pracownik istnieje
    const worker = await prisma.employees.findUnique({
      where: { 
        employee_id: workerId,
        role: { in: ['arbejder', 'byggeleder'] as any }
      }
    });

    if (!worker) {
      return NextResponse.json({ error: "Worker not found" }, { status: 404 });
    }

    if (!worker.profilePictureUrl) {
      return NextResponse.json({ error: "No profile image to delete" }, { status: 404 });
    }

    // Usunięcie z S3
    try {
      const key = extractS3KeyFromUrl(worker.profilePictureUrl);
      if (key) {
        const deleteParams: DeleteObjectCommandInput = {
          Bucket: BUCKET_NAME,
          Key: key
        };
        await s3Client.send(new DeleteObjectCommand(deleteParams));
      }
    } catch (error) {
      console.warn("Could not delete file from S3:", error);
    }

    // Aktualizacja w bazie danych
    await prisma.employees.update({
      where: { employee_id: workerId },
      data: { profilePictureUrl: null }
    });

    console.log(`Profile image deleted for worker ${workerId}`);

    return NextResponse.json({
      success: true,
      message: "Profile image deleted successfully"
    });

  } catch (error: any) {
    console.error("Error deleting profile image:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// Helper function to extract S3 key from URL
function extractS3KeyFromUrl(url: string): string | null {
  try {
    // Format: https://bucket-name.s3.amazonaws.com/key
    // or https://bucket-name.s3.region.amazonaws.com/key
    const urlObj = new URL(url);
    return urlObj.pathname.substring(1); // Remove leading slash
  } catch {
    return null;
  }
}