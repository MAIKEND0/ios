// /api/app/worker/leave/[id]/documents - Leave document management (sick notes, etc.)
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

// GET /api/app/worker/leave/[id]/documents - Get documents for a leave request
export async function GET(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const params = await context.params;
    const leaveRequestId = parseInt(params.id);
    const { searchParams } = new URL(request.url);
    const employeeId = searchParams.get("employee_id");

    if (!employeeId) {
      return NextResponse.json({ error: "Missing employee_id parameter" }, { status: 400 });
    }

    // Verify the leave request exists and belongs to the employee
    const leaveRequest = await prisma.leaveRequests.findUnique({
      where: { id: leaveRequestId },
      select: {
        id: true,
        employee_id: true,
        type: true,
        sick_note_url: true,
        status: true
      }
    });

    if (!leaveRequest) {
      return NextResponse.json({ error: "Leave request not found" }, { status: 404 });
    }

    if (leaveRequest.employee_id !== parseInt(employeeId)) {
      return NextResponse.json({ error: "Not authorized to access this leave request" }, { status: 403 });
    }

    // For now, we only store sick_note_url in the leave request
    // In a full implementation, you might have a separate documents table
    const documents = [];
    
    if (leaveRequest.sick_note_url) {
      documents.push({
        id: `sick_note_${leaveRequest.id}`,
        type: 'sick_note',
        url: leaveRequest.sick_note_url,
        filename: `sick_note_${leaveRequest.id}.pdf`,
        uploaded_at: null, // Would need to track this separately
        file_size: null,    // Would need to track this separately
        mime_type: 'application/pdf'
      });
    }

    return NextResponse.json({
      leave_request_id: leaveRequestId,
      documents: documents,
      total_documents: documents.length,
      can_upload: leaveRequest.type === 'SICK' && leaveRequest.status === 'PENDING'
    });

  } catch (error: any) {
    console.error("Error fetching leave documents:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST /api/app/worker/leave/[id]/documents - Upload document for leave request
export async function POST(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const params = await context.params;
    const leaveRequestId = parseInt(params.id);
    const formData = await request.formData();
    
    const file = formData.get('file') as File;
    const employeeId = formData.get('employee_id') as string;
    const documentType = formData.get('document_type') as string || 'sick_note';

    if (!file || !employeeId) {
      return NextResponse.json({
        error: "Missing required fields: file, employee_id"
      }, { status: 400 });
    }

    // Verify the leave request exists and belongs to the employee
    const leaveRequest = await prisma.leaveRequests.findUnique({
      where: { id: leaveRequestId },
      select: {
        id: true,
        employee_id: true,
        type: true,
        status: true
      }
    });

    if (!leaveRequest) {
      return NextResponse.json({ error: "Leave request not found" }, { status: 404 });
    }

    if (leaveRequest.employee_id !== parseInt(employeeId)) {
      return NextResponse.json({ error: "Not authorized to upload to this leave request" }, { status: 403 });
    }

    // Only allow document uploads for sick leave
    if (leaveRequest.type !== 'SICK') {
      return NextResponse.json({
        error: "Document uploads are only allowed for sick leave requests"
      }, { status: 400 });
    }

    // Validate file type and size
    const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'];
    const maxSize = 5 * 1024 * 1024; // 5MB

    if (!allowedTypes.includes(file.type)) {
      return NextResponse.json({
        error: `Invalid file type. Allowed types: ${allowedTypes.join(', ')}`
      }, { status: 400 });
    }

    if (file.size > maxSize) {
      return NextResponse.json({
        error: "File size too large. Maximum size is 5MB"
      }, { status: 400 });
    }

    // In a real implementation, you would upload to S3 here
    // For now, we'll simulate the upload and store a mock URL
    const timestamp = Date.now();
    const fileExtension = file.name.split('.').pop();
    const fileName = `sick_note_${leaveRequestId}_${timestamp}.${fileExtension}`;
    
    // Mock S3 URL - in real implementation, use AWS SDK to upload
    const mockS3Url = `https://ksrcranes-documents.s3.eu-west-1.amazonaws.com/leave-documents/${employeeId}/${fileName}`;
    
    // Simulate file upload processing
    const fileBuffer = await file.arrayBuffer();
    console.log(`Simulating upload of ${file.name} (${fileBuffer.byteLength} bytes) to S3...`);
    
    // In real implementation:
    // const uploadResult = await s3Client.upload({
    //   Bucket: 'ksrcranes-documents',
    //   Key: `leave-documents/${employeeId}/${fileName}`,
    //   Body: fileBuffer,
    //   ContentType: file.type,
    //   ACL: 'private'
    // }).promise();

    // Update the leave request with the document URL
    const updatedLeaveRequest = await prisma.leaveRequests.update({
      where: { id: leaveRequestId },
      data: {
        sick_note_url: mockS3Url
      },
      select: {
        id: true,
        sick_note_url: true,
        type: true,
        status: true
      }
    });

    // Create audit log
    try {
      await prisma.leaveAuditLog.create({
        data: {
          leave_request_id: leaveRequestId,
          employee_id: parseInt(employeeId),
          action: 'MODIFIED' as any,
          old_values: { sick_note_url: null },
          new_values: { sick_note_url: mockS3Url },
          performed_by: parseInt(employeeId),
          notes: `Uploaded ${documentType}: ${file.name}`
        }
      });
    } catch (auditError) {
      console.warn("Failed to create audit log:", auditError);
    }

    return NextResponse.json({
      success: true,
      document: {
        id: `sick_note_${leaveRequestId}`,
        type: documentType,
        url: mockS3Url,
        filename: fileName,
        original_filename: file.name,
        file_size: file.size,
        mime_type: file.type,
        uploaded_at: new Date().toISOString()
      },
      message: "Document uploaded successfully"
    }, { status: 201 });

  } catch (error: any) {
    console.error("Error uploading leave document:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// DELETE /api/app/worker/leave/[id]/documents - Remove document from leave request
export async function DELETE(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const params = await context.params;
    const leaveRequestId = parseInt(params.id);
    const { searchParams } = new URL(request.url);
    const employeeId = searchParams.get("employee_id");
    const documentType = searchParams.get("document_type") || "sick_note";

    if (!employeeId) {
      return NextResponse.json({ error: "Missing employee_id parameter" }, { status: 400 });
    }

    // Verify the leave request exists and belongs to the employee
    const leaveRequest = await prisma.leaveRequests.findUnique({
      where: { id: leaveRequestId },
      select: {
        id: true,
        employee_id: true,
        type: true,
        status: true,
        sick_note_url: true
      }
    });

    if (!leaveRequest) {
      return NextResponse.json({ error: "Leave request not found" }, { status: 404 });
    }

    if (leaveRequest.employee_id !== parseInt(employeeId)) {
      return NextResponse.json({ error: "Not authorized to modify this leave request" }, { status: 403 });
    }

    // Only allow deletion if request is still pending
    if (leaveRequest.status !== 'PENDING') {
      return NextResponse.json({
        error: "Cannot delete documents from processed leave requests"
      }, { status: 400 });
    }

    if (!leaveRequest.sick_note_url) {
      return NextResponse.json({ error: "No document found to delete" }, { status: 404 });
    }

    // In real implementation, delete from S3
    // await s3Client.deleteObject({
    //   Bucket: 'ksrcranes-documents',
    //   Key: extractKeyFromUrl(leaveRequest.sick_note_url)
    // }).promise();

    // Update the leave request to remove the document URL
    await prisma.leaveRequests.update({
      where: { id: leaveRequestId },
      data: {
        sick_note_url: null
      }
    });

    // Create audit log
    try {
      await prisma.leaveAuditLog.create({
        data: {
          leave_request_id: leaveRequestId,
          employee_id: parseInt(employeeId),
          action: 'MODIFIED' as any,
          old_values: { sick_note_url: leaveRequest.sick_note_url },
          new_values: { sick_note_url: null },
          performed_by: parseInt(employeeId),
          notes: `Deleted ${documentType} document`
        }
      });
    } catch (auditError) {
      console.warn("Failed to create audit log:", auditError);
    }

    return NextResponse.json({
      success: true,
      message: "Document deleted successfully"
    });

  } catch (error: any) {
    console.error("Error deleting leave document:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}