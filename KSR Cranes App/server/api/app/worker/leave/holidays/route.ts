// /api/app/worker/leave/holidays - Public holidays calendar
import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

// GET /api/app/worker/leave/holidays - Get public holidays calendar
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const year = searchParams.get("year") ? parseInt(searchParams.get("year")!) : new Date().getFullYear();
    const upcoming = searchParams.get("upcoming") === "true";
    
    let whereClause: any = {
      year: year,
      is_national: true
    };

    // If requesting upcoming holidays, filter from today onwards
    if (upcoming) {
      whereClause.date = {
        gte: new Date()
      };
      // Remove year filter for upcoming holidays
      delete whereClause.year;
    }

    const holidays = await prisma.publicHolidays.findMany({
      where: whereClause,
      orderBy: { date: 'asc' },
      select: {
        id: true,
        date: true,
        name: true,
        description: true,
        year: true,
        is_national: true
      }
    });

    // Group holidays by month for better organization
    const holidaysByMonth: { [key: string]: any[] } = {};
    
    holidays.forEach(holiday => {
      const month = holiday.date.toISOString().slice(0, 7); // YYYY-MM format
      if (!holidaysByMonth[month]) {
        holidaysByMonth[month] = [];
      }
      holidaysByMonth[month].push({
        ...holiday,
        days_until: upcoming ? Math.ceil((holiday.date.getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24)) : null
      });
    });

    return NextResponse.json({
      holidays: holidays,
      holidays_by_month: holidaysByMonth,
      year: year,
      total_holidays: holidays.length
    });

  } catch (error: any) {
    console.error("Error fetching public holidays:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}