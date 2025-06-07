// /api/app/chef/workers/[id]/documents - Zarządzanie dokumentami pracowników na S3
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";
import {
  ListObjectsV2Command,
  PutObjectCommand,
  GetObjectCommand,
  CopyObjectCommand,
  DeleteObjectCommand,
  ListObjectsV2CommandOutput,
  CopyObjectCommandInput,
  DeleteObjectCommandInput,
  PutObjectCommandInput,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { s3ClientEmployees, EMPLOYEE_BUCKET_NAME, getEmployeeDocumentUrl } from "../../../../../../../lib/s3-employee";

const BUCKET_NAME = EMPLOYEE_BUCKET_NAME;

// GET /api/app/chef/workers/[id]/documents - Lista dokumentów pracownika
export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
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

    const { searchParams } = new URL(request.url);
    const customPrefix = searchParams.get("prefix");
    
    // Prefix dla dokumentów pracownika: documents/{id}/
    const prefix = customPrefix || `documents/${workerId}/`;
    
    console.log(`Listing documents for worker ${workerId} with prefix: ${prefix}`);

    const listOutput: ListObjectsV2CommandOutput = await s3ClientEmployees.send(
      new ListObjectsV2Command({
        Bucket: BUCKET_NAME,
        Prefix: prefix,
      })
    );

    // Generowanie presigned URLs dla dokumentów
    const documents = await Promise.all(
      (listOutput.Contents || []).map(async (item) => {
        if (!item.Key) return null;
        
        const url = await getSignedUrl(
          s3ClientEmployees,
          new GetObjectCommand({
            Bucket: BUCKET_NAME,
            Key: item.Key,
          }),
          { expiresIn: 3600 } // URL ważny przez 1 godzinę
        );

        // Ekstrakcja nazwy pliku z klucza
        const fileName = item.Key.split('/').pop() || item.Key;
        const fileExtension = fileName.split('.').pop()?.toLowerCase() || '';
        
        // Kategoryzacja dokumentów
        const category = categorizeDocument(fileName, fileExtension);

        return {
          key: item.Key,
          name: fileName,
          lastModified: item.LastModified,
          size: item.Size,
          url,
          category,
          extension: fileExtension,
          isFolder: item.Key.endsWith('/') || item.Size === 0
        };
      })
    );

    const filteredDocuments = documents.filter(Boolean);
    
    // Grupowanie dokumentów po kategoriach
    const categorizedDocuments = groupDocumentsByCategory(filteredDocuments);

    return NextResponse.json({
      worker_id: workerId,
      worker_name: worker.name,
      documents: filteredDocuments,
      categories: categorizedDocuments,
      total_count: filteredDocuments.length
    });

  } catch (error: any) {
    console.error(`Error listing documents for worker ${id}:`, error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST /api/app/chef/workers/[id]/documents - Upload dokumentów
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
    const files = formData.getAll("files") as File[];
    const category = formData.get("category") as string || "general";

    if (!files || files.length === 0) {
      return NextResponse.json({ error: "No files provided" }, { status: 400 });
    }

    console.log(`Uploading ${files.length} documents for worker ${workerId}`);

    const results: any[] = [];

    for (const file of files) {
      // Walidacja rozmiaru pliku (max 10MB per file)
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (file.size > maxSize) {
        console.warn(`File ${file.name} too large: ${file.size} bytes`);
        continue;
      }

      const arrayBuffer = await file.arrayBuffer();
      const buffer = Buffer.from(arrayBuffer);

      // Generowanie unikalnej nazwy pliku
      const fileExtension = file.name.split('.').pop() || '';
      const sanitizedFileName = sanitizeFileName(file.name);
      const timestamp = Date.now();
      const fileName = `${timestamp}_${sanitizedFileName}`;
      
      // Struktura folderów: documents/{id}/{category}/{fileName}
      const key = `documents/${workerId}/${category}/${fileName}`;

      // Określenie typu zawartości
      const contentType = getContentType(file.type, fileExtension);

      const putParams: PutObjectCommandInput = {
        Bucket: BUCKET_NAME,
        Key: key,
        Body: buffer,
        ContentType: contentType,
        ACL: "private", // Dokumenty prywatne
        Metadata: {
          'original-name': file.name,
          'worker-id': workerId.toString(),
          'worker-name': worker.name,
          'category': category,
          'upload-date': new Date().toISOString(),
          'file-size': file.size.toString()
        }
      };

      await s3ClientEmployees.send(new PutObjectCommand(putParams));

      results.push({
        name: file.name,
        key,
        category,
        size: file.size,
        contentType
      });

      console.log(`Document uploaded: ${key}`);
    }

    return NextResponse.json({
      success: true,
      message: `${results.length} documents uploaded successfully`,
      uploaded: results,
      worker_id: workerId
    });

  } catch (error: any) {
    console.error(`Error uploading documents for worker ${id}:`, error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PATCH /api/app/chef/workers/[id]/documents - Przenoszenie/zmiana nazwy dokumentu
export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    const body = await request.json();
    const { fromKey, toKey, newCategory } = body;

    if (!fromKey) {
      return NextResponse.json({ error: "fromKey is required" }, { status: 400 });
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

    let finalToKey = toKey;

    // Jeśli podano nową kategorię, generuj nowy klucz
    if (newCategory && !toKey) {
      const fileName = fromKey.split('/').pop();
      finalToKey = `documents/${workerId}/${newCategory}/${fileName}`;
    }

    if (!finalToKey) {
      return NextResponse.json({ error: "toKey or newCategory is required" }, { status: 400 });
    }

    console.log(`Moving document from ${fromKey} to ${finalToKey}`);

    // Kopiowanie pliku
    const copyParams: CopyObjectCommandInput = {
      Bucket: BUCKET_NAME,
      CopySource: `${BUCKET_NAME}/${fromKey}`,
      Key: finalToKey,
      ACL: "private",
      MetadataDirective: 'COPY'
    };

    await s3ClientEmployees.send(new CopyObjectCommand(copyParams));

    // Usunięcie starego pliku
    const deleteParams: DeleteObjectCommandInput = {
      Bucket: BUCKET_NAME,
      Key: fromKey,
    };

    await s3ClientEmployees.send(new DeleteObjectCommand(deleteParams));

    console.log(`Document moved successfully from ${fromKey} to ${finalToKey}`);

    return NextResponse.json({
      success: true,
      message: "Document moved successfully",
      from_key: fromKey,
      to_key: finalToKey
    });

  } catch (error: any) {
    console.error(`Error moving document for worker ${id}:`, error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// DELETE /api/app/chef/workers/[id]/documents - Usuwanie dokumentu
export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const workerId = parseInt(id);

    if (isNaN(workerId)) {
      return NextResponse.json({ error: "Invalid worker ID" }, { status: 400 });
    }

    const { searchParams } = new URL(request.url);
    const keyToDelete = searchParams.get("key");

    if (!keyToDelete) {
      return NextResponse.json({ error: "key parameter is required" }, { status: 400 });
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

    // Sprawdzenie czy klucz należy do tego pracownika
    if (!keyToDelete.startsWith(`documents/${workerId}/`)) {
      return NextResponse.json({ error: "Unauthorized access to document" }, { status: 403 });
    }

    console.log(`Deleting document: ${keyToDelete}`);

    const deleteParams: DeleteObjectCommandInput = {
      Bucket: BUCKET_NAME,
      Key: keyToDelete,
    };

    await s3ClientEmployees.send(new DeleteObjectCommand(deleteParams));

    console.log(`Document deleted successfully: ${keyToDelete}`);

    return NextResponse.json({
      success: true,
      message: "Document deleted successfully",
      deleted_key: keyToDelete
    });

  } catch (error: any) {
    console.error(`Error deleting document for worker ${id}:`, error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// Helper functions
function categorizeDocument(fileName: string, extension: string): string {
  const lowerFileName = fileName.toLowerCase();
  const lowerExtension = extension.toLowerCase();

  // Kategorie dokumentów
  if (['pdf', 'doc', 'docx'].includes(lowerExtension)) {
    if (lowerFileName.includes('contract') || lowerFileName.includes('kontrakt')) {
      return 'contracts';
    }
    if (lowerFileName.includes('certificate') || lowerFileName.includes('certifikat')) {
      return 'certificates';
    }
    if (lowerFileName.includes('license') || lowerFileName.includes('licens')) {
      return 'licenses';
    }
    return 'documents';
  }

  if (['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(lowerExtension)) {
    return 'photos';
  }

  if (['xls', 'xlsx', 'csv'].includes(lowerExtension)) {
    return 'reports';
  }

  return 'general';
}

function groupDocumentsByCategory(documents: any[]): { [key: string]: any[] } {
  return documents.reduce((groups, doc) => {
    const category = doc.category || 'general';
    if (!groups[category]) {
      groups[category] = [];
    }
    groups[category].push(doc);
    return groups;
  }, {});
}

function sanitizeFileName(fileName: string): string {
  // Usunięcie znaków specjalnych i zastąpienie spacjami podkreśleniami
  return fileName
    .replace(/[^a-zA-Z0-9.\-_]/g, '_')
    .replace(/_{2,}/g, '_')
    .toLowerCase();
}

function getContentType(fileType: string, extension: string): string {
  if (fileType && fileType !== 'application/octet-stream') {
    return fileType;
  }

  // Fallback based on extension
  const contentTypes: { [key: string]: string } = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'txt': 'text/plain',
    'csv': 'text/csv'
  };

  return contentTypes[extension.toLowerCase()] || 'application/octet-stream';
}