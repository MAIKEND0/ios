// src/app/api/app/supervisor/profile/[supervisorId]/avatar/route.ts
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";
import { s3ClientEmployees, EMPLOYEE_BUCKET_NAME, getEmployeeProfileImageUrl } from "../../../../../../../lib/s3-employee";
import { PutObjectCommand, DeleteObjectCommand } from "@aws-sdk/client-s3";
import jwt from "jsonwebtoken";
import { v4 as uuidv4 } from "uuid";

const SECRET = process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET;

if (!SECRET) {
  throw new Error("Missing NEXTAUTH_SECRET or JWT_SECRET environment variable");
}

async function authenticate(req: NextRequest) {
  const auth = req.headers.get("authorization")?.split(" ");
  if (auth?.[0] !== "Bearer" || !auth[1]) {
    throw new Error("Unauthorized");
  }
  try {
    const decoded = jwt.verify(auth[1], SECRET) as { id: number; role: string };
    if (decoded.role !== "byggeleder") {
      throw new Error("Unauthorized: Invalid role");
    }
    return decoded;
  } catch {
    throw new Error("Invalid token");
  }
}

// POST - Upload profile picture
export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ supervisorId: string }> }
): Promise<NextResponse> {
  try {
    const { supervisorId } = await params;
    const { id: authenticatedId } = await authenticate(req);

    // Verify supervisor can only update their own profile
    if (authenticatedId.toString() !== supervisorId) {
      return NextResponse.json(
        { error: "Unauthorized: Can only update own profile" },
        { status: 403 }
      );
    }

    // Parse multipart form data
    const formData = await req.formData();
    const file = formData.get("avatar") as File;
    
    if (!file) {
      return NextResponse.json(
        { error: "No file provided" },
        { status: 400 }
      );
    }

    // Validate file type
    const allowedTypes = ["image/jpeg", "image/jpg", "image/png", "image/webp"];
    if (!allowedTypes.includes(file.type)) {
      return NextResponse.json(
        { error: "Invalid file type. Only JPEG, PNG, and WebP are allowed" },
        { status: 400 }
      );
    }

    // Validate file size (max 5MB)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      return NextResponse.json(
        { error: "File too large. Maximum size is 5MB" },
        { status: 400 }
      );
    }

    // Generate unique filename
    const fileExtension = file.name.split('.').pop() || 'jpg';
    const filename = `profile_${Date.now()}_${uuidv4()}.${fileExtension}`;
    const s3Key = `profiles/${supervisorId}/${filename}`;

    // Convert file to buffer
    const buffer = Buffer.from(await file.arrayBuffer());

    // Check if supervisor exists and get current profile picture
    const existingSupervisor = await prisma.employees.findUnique({
      where: { employee_id: parseInt(supervisorId) },
      select: { profilePictureUrl: true }
    });

    if (!existingSupervisor) {
      return NextResponse.json(
        { error: "Supervisor not found" },
        { status: 404 }
      );
    }

    // Upload to S3
    const uploadCommand = new PutObjectCommand({
      Bucket: EMPLOYEE_BUCKET_NAME,
      Key: s3Key,
      Body: buffer,
      ContentType: file.type,
      ACL: "public-read", // Make publicly accessible
      Metadata: {
        employeeId: supervisorId,
        uploadedAt: new Date().toISOString(),
      }
    });

    await s3ClientEmployees.send(uploadCommand);

    // Generate public URL
    const profileImageUrl = getEmployeeProfileImageUrl(supervisorId, filename);

    // Update database with new profile picture URL
    const updatedSupervisor = await prisma.employees.update({
      where: { employee_id: parseInt(supervisorId) },
      data: { 
        profilePictureUrl: profileImageUrl
      },
      select: {
        employee_id: true,
        name: true,
        profilePictureUrl: true
      }
    });

    // Delete old profile picture if exists
    if (existingSupervisor.profilePictureUrl) {
      try {
        const oldKey = existingSupervisor.profilePictureUrl.split('/').slice(-2).join('/');
        if (oldKey.startsWith('profiles/')) {
          const deleteCommand = new DeleteObjectCommand({
            Bucket: EMPLOYEE_BUCKET_NAME,
            Key: oldKey
          });
          await s3ClientEmployees.send(deleteCommand);
        }
      } catch (error) {
        console.warn("Failed to delete old profile picture:", error);
        // Continue anyway, don't fail the request
      }
    }

    console.log(`[API] Profile picture updated for supervisor ${supervisorId}: ${profileImageUrl}`);

    return NextResponse.json({
      success: true,
      message: "Profile picture updated successfully",
      data: {
        supervisorId: updatedSupervisor.employee_id,
        name: updatedSupervisor.name,
        profilePictureUrl: updatedSupervisor.profilePictureUrl
      }
    });

  } catch (error: any) {
    console.error("Error uploading profile picture:", error);
    return NextResponse.json(
      { 
        success: false,
        error: error.message || "Failed to upload profile picture" 
      },
      { status: error.message?.includes("Unauthorized") ? 401 : 500 }
    );
  }
}

// GET - Get current profile picture URL
export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ supervisorId: string }> }
): Promise<NextResponse> {
  try {
    await authenticate(req);
    const { supervisorId } = await params;

    const supervisor = await prisma.employees.findUnique({
      where: { employee_id: parseInt(supervisorId) },
      select: {
        employee_id: true,
        name: true,
        profilePictureUrl: true
      }
    });

    if (!supervisor) {
      return NextResponse.json(
        { error: "Supervisor not found" },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      data: {
        supervisorId: supervisor.employee_id,
        name: supervisor.name,
        profilePictureUrl: supervisor.profilePictureUrl
      }
    });

  } catch (error: any) {
    console.error("Error getting profile picture:", error);
    return NextResponse.json(
      { error: error.message || "Failed to get profile picture" },
      { status: error.message?.includes("Unauthorized") ? 401 : 500 }
    );
  }
}

// DELETE - Remove profile picture
export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ supervisorId: string }> }
): Promise<NextResponse> {
  try {
    const { id: authenticatedId } = await authenticate(req);
    const { supervisorId } = await params;

    // Verify supervisor can only update their own profile
    if (authenticatedId.toString() !== supervisorId) {
      return NextResponse.json(
        { error: "Unauthorized: Can only update own profile" },
        { status: 403 }
      );
    }

    const supervisor = await prisma.employees.findUnique({
      where: { employee_id: parseInt(supervisorId) },
      select: { profilePictureUrl: true }
    });

    if (!supervisor) {
      return NextResponse.json(
        { error: "Supervisor not found" },
        { status: 404 }
      );
    }

    // Delete from S3 if exists
    if (supervisor.profilePictureUrl) {
      try {
        const s3Key = supervisor.profilePictureUrl.split('/').slice(-2).join('/');
        if (s3Key.startsWith('profiles/')) {
          const deleteCommand = new DeleteObjectCommand({
            Bucket: EMPLOYEE_BUCKET_NAME,
            Key: s3Key
          });
          await s3ClientEmployees.send(deleteCommand);
        }
      } catch (error) {
        console.warn("Failed to delete from S3:", error);
      }
    }

    // Update database
    await prisma.employees.update({
      where: { employee_id: parseInt(supervisorId) },
      data: { 
        profilePictureUrl: null
      }
    });

    return NextResponse.json({
      success: true,
      message: "Profile picture removed successfully"
    });

  } catch (error: any) {
    console.error("Error deleting profile picture:", error);
    return NextResponse.json(
      { error: error.message || "Failed to delete profile picture" },
      { status: error.message?.includes("Unauthorized") ? 401 : 500 }
    );
  }
}