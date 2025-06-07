// /api/app/chef/workers/search - Wyszukiwanie pracowników
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// GET /api/app/chef/workers/search - Proste wyszukiwanie pracowników
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const query = searchParams.get("q");
    const limit = Math.min(parseInt(searchParams.get("limit") || "20"), 100);
    const offset = parseInt(searchParams.get("offset") || "0");

    if (!query || query.trim().length < 2) {
      return NextResponse.json({
        workers: [],
        total_count: 0,
        page: Math.floor(offset / limit) + 1,
        limit,
        has_more: false
      });
    }

    const trimmedQuery = query.trim();

    // Budowanie query wyszukiwania
    const whereClause = {
      role: {
        in: ['arbejder', 'byggeleder'] as any
      },
      OR: [
        { name: { contains: trimmedQuery, mode: 'insensitive' } },
        { email: { contains: trimmedQuery, mode: 'insensitive' } },
        { phone_number: { contains: trimmedQuery, mode: 'insensitive' } },
        { address: { contains: trimmedQuery, mode: 'insensitive' } }
      ]
    };

    // Zliczanie całkowitej liczby wyników
    const totalCount = await prisma.employees.count({
      where: whereClause
    });

    // Pobieranie wyników z paginacją
    const workers = await prisma.employees.findMany({
      where: whereClause,
      select: {
        employee_id: true,
        name: true,
        email: true,
        phone_number: true,
        address: true,
        operator_normal_rate: true,
        role: true,
        profilePictureUrl: true,
        created_at: true,
        is_activated: true
      },
      orderBy: [
        // Sortowanie według relevance - najpierw exact matches w nazwie
        { name: 'asc' }
      ],
      skip: offset,
      take: limit
    });

    // Mapowanie do formatu iOS
    const mappedWorkers = workers.map(worker => ({
      employee_id: worker.employee_id,
      name: worker.name,
      email: worker.email,
      phone: worker.phone_number,
      address: worker.address,
      hourly_rate: Number(worker.operator_normal_rate || 0),
      employment_type: mapRoleToEmploymentType(worker.role),
      status: worker.is_activated ? "aktiv" : "inaktiv",
      profile_picture_url: worker.profilePictureUrl,
      created_at: worker.created_at,
      last_active: null,
      stats: {
        hours_this_week: 0,
        hours_this_month: 0,
        active_projects: 0,
        completed_tasks: 0,
        approval_rate: 1.0,
        last_timesheet_date: null
      }
    }));

    const currentPage = Math.floor(offset / limit) + 1;
    const hasMore = (offset + limit) < totalCount;

    return NextResponse.json({
      workers: mappedWorkers,
      total_count: totalCount,
      page: currentPage,
      limit,
      has_more: hasMore,
      query: trimmedQuery
    });

  } catch (error: any) {
    console.error("Error searching workers:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST /api/app/chef/workers/search - Zaawansowane wyszukiwanie
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      query,
      status,
      employment_type,
      min_hourly_rate,
      max_hourly_rate,
      hired_after,
      hired_before,
      has_active_assignments,
      limit = 20,
      offset = 0
    } = body;

    // Budowanie złożonego query
    const whereClause: any = {
      role: {
        in: ['arbejder', 'byggeleder'] as any
      }
    };

    // Wyszukiwanie tekstowe
    if (query && query.trim().length >= 2) {
      whereClause.OR = [
        { name: { contains: query.trim(), mode: 'insensitive' } },
        { email: { contains: query.trim(), mode: 'insensitive' } },
        { phone_number: { contains: query.trim(), mode: 'insensitive' } },
        { address: { contains: query.trim(), mode: 'insensitive' } }
      ];
    }

    // Filtr statusu
    if (status && Array.isArray(status) && status.length > 0) {
      const statusConditions = status.map(s => {
        switch (s) {
          case 'aktiv': return { is_activated: true };
          case 'inaktiv': return { is_activated: false };
          default: return null;
        }
      }).filter(Boolean);

      if (statusConditions.length > 0) {
        whereClause.OR = [...(whereClause.OR || []), ...statusConditions];
      }
    }

    // Filtr typu zatrudnienia (mapowanie na role)
    if (employment_type && Array.isArray(employment_type) && employment_type.length > 0) {
      const mappedRoles = employment_type.map(mapEmploymentTypeToRole);
      whereClause.role = {
        in: mappedRoles
      };
    }

    // Filtr stawki godzinowej
    if (min_hourly_rate !== undefined || max_hourly_rate !== undefined) {
      whereClause.operator_normal_rate = {};
      if (min_hourly_rate !== undefined) {
        whereClause.operator_normal_rate.gte = min_hourly_rate;
      }
      if (max_hourly_rate !== undefined) {
        whereClause.operator_normal_rate.lte = max_hourly_rate;
      }
    }

    // Filtr dat zatrudnienia
    if (hired_after || hired_before) {
      whereClause.created_at = {};
      if (hired_after) {
        whereClause.created_at.gte = new Date(hired_after);
      }
      if (hired_before) {
        whereClause.created_at.lte = new Date(hired_before);
      }
    }

    // TODO: Implementacja filtru has_active_assignments
    // Wymagałoby to join z TaskAssignments
    if (has_active_assignments !== undefined) {
      // Placeholder - może być zaimplementowane później
    }

    console.log("Advanced search whereClause:", JSON.stringify(whereClause, null, 2));

    // Zliczanie wyników
    const totalCount = await prisma.employees.count({
      where: whereClause
    });

    // Pobieranie wyników
    const workers = await prisma.employees.findMany({
      where: whereClause,
      select: {
        employee_id: true,
        name: true,
        email: true,
        phone_number: true,
        address: true,
        operator_normal_rate: true,
        role: true,
        profilePictureUrl: true,
        created_at: true,
        is_activated: true
      },
      orderBy: [
        { name: 'asc' }
      ],
      skip: offset,
      take: Math.min(limit, 100) // Max 100 results per request
    });

    // Mapowanie do formatu iOS
    const mappedWorkers = workers.map(worker => ({
      employee_id: worker.employee_id,
      name: worker.name,
      email: worker.email,
      phone: worker.phone_number,
      address: worker.address,
      hourly_rate: Number(worker.operator_normal_rate || 0),
      employment_type: mapRoleToEmploymentType(worker.role),
      status: worker.is_activated ? "aktiv" : "inaktiv",
      profile_picture_url: worker.profilePictureUrl,
      created_at: worker.created_at,
      last_active: null,
      stats: {
        hours_this_week: 0,
        hours_this_month: 0,
        active_projects: 0,
        completed_tasks: 0,
        approval_rate: 1.0,
        last_timesheet_date: null
      }
    }));

    const currentPage = Math.floor(offset / limit) + 1;
    const hasMore = (offset + limit) < totalCount;

    return NextResponse.json({
      workers: mappedWorkers,
      total_count: totalCount,
      page: currentPage,
      limit,
      has_more: hasMore,
      filters_applied: {
        query: query || null,
        status,
        employment_type,
        min_hourly_rate,
        max_hourly_rate,
        hired_after,
        hired_before,
        has_active_assignments
      }
    });

  } catch (error: any) {
    console.error("Error in advanced worker search:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// Helper functions
function mapRoleToEmploymentType(role: string): string {
  switch (role) {
    case 'arbejder': return 'fuld_tid';
    case 'byggeleder': return 'fuld_tid';
    default: return 'fuld_tid';
  }
}

function mapEmploymentTypeToRole(employmentType: string): string {
  switch (employmentType) {
    case 'fuld_tid': return 'arbejder';
    case 'deltid': return 'arbejder';
    case 'timebaseret': return 'arbejder';
    case 'freelancer': return 'arbejder';
    case 'praktikant': return 'arbejder';
    default: return 'arbejder';
  }
}