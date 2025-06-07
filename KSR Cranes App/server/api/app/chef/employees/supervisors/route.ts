// src/app/api/app/chef/employees/supervisors/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/employees/supervisors
 * Pobiera listę pracowników z rolami supervisor/chef którzy mogą być supervisorami zadań
 */
export async function GET(request: Request): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const includeExternal = searchParams.get('include_external') === 'true';
    
    // Pobierz pracowników z odpowiednimi rolami
    const supervisors = await prisma.employees.findMany({
      where: {
        role: {
          in: ['byggeleder', 'chef']
        },
        is_activated: true
      },
      select: {
        employee_id: true,
        name: true,
        email: true,
        role: true,
        phone_number: true,
        profilePictureUrl: true,
        address: true,
        has_driving_license: true,
        driving_license_category: true,
        driving_license_expiration: true
      },
      orderBy: [
        { role: 'asc' }, // chef first, then byggeleder
        { name: 'asc' }
      ]
    });

    // Jeśli includeExternal, dodaj też "external" supervisors (ci z is_activated = false)
    let allSupervisors = supervisors;
    
    if (includeExternal) {
      const externalSupervisors = await prisma.employees.findMany({
        where: {
          role: {
            in: ['byggeleder', 'chef']
          },
          is_activated: false,
          email: { not: null }
        },
        select: {
          employee_id: true,
          name: true,
          email: true,
          role: true,
          phone_number: true,
          profilePictureUrl: true,
          address: true,
          has_driving_license: true,
          driving_license_category: true,
          driving_license_expiration: true
        },
        orderBy: { name: 'asc' }
      });
      
      allSupervisors = [...supervisors, ...externalSupervisors];
    }

    return NextResponse.json(allSupervisors, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/app/chef/employees/supervisors:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}