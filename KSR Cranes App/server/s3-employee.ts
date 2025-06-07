// src/lib/s3-employee.ts
import { S3 } from "@aws-sdk/client-s3";

// Walidacja zmiennych środowiskowych
const requiredEnvVars = [
  "KSR_EMPLOYEES_SPACES_REGION",
  "KSR_EMPLOYEES_KEY",
  "KSR_EMPLOYEES_SECRET",
  "KSR_EMPLOYEES_SPACES_BUCKET",
  "KSR_EMPLOYEES_KEY_SPACES_ENDPOINT"
];

for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    throw new Error(`Missing required environment variable: ${envVar}`);
  }
}

export const EMPLOYEE_BUCKET_NAME = process.env.KSR_EMPLOYEES_SPACES_BUCKET || "ksr-employees";

// Endpoint dla DigitalOcean Spaces
const region = process.env.KSR_EMPLOYEES_SPACES_REGION;
const spacesEndpoint = `https://${process.env.KSR_EMPLOYEES_KEY_SPACES_ENDPOINT}`;

export const s3ClientEmployees = new S3({
  forcePathStyle: false,
  endpoint: spacesEndpoint,
  region: region,
  credentials: {
    accessKeyId: process.env.KSR_EMPLOYEES_KEY!,
    secretAccessKey: process.env.KSR_EMPLOYEES_SECRET!,
  },
});

// Helper function dla generowania URLs
export function getEmployeeProfileImageUrl(employeeId: string, filename: string): string {
  const baseUrl = process.env.KSR_EMPLOYEES_CDN_ENABLED === "true"
    ? `https://${EMPLOYEE_BUCKET_NAME}.${region}.cdn.digitaloceanspaces.com`
    : `https://${EMPLOYEE_BUCKET_NAME}.${region}.digitaloceanspaces.com`;
  return `${baseUrl}/profiles/${employeeId}/${filename}`;
}