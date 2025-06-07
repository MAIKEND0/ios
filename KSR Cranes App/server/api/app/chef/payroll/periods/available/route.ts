// src/app/api/app/chef/payroll/periods/available/route.ts
// CORRECTED VERSION with proper bi-weekly periods (18-19, 20-21, etc.)

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

// Explicit cache configuration for Next.js 15
export const dynamic = 'force-dynamic';

// Types matching iOS app expectations
interface PayrollPeriodOption {
  id: number;
  title: string;
  start_date: string; // ISO date string
  end_date: string; // ISO date string
  available_hours: number;
  estimated_amount: number;
}

interface ErrorResponse {
  error: string;
  message?: string;
  details?: any;
}

// Helper function to get week number
function getWeekNumber(date: Date): number {
  const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
  const pastDaysOfYear = (date.getTime() - firstDayOfYear.getTime()) / 86400000;
  return Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7);
}

// Helper function to get Monday of the week
function getMondayOfWeek(date: Date): Date {
  const day = date.getDay();
  const diff = date.getDate() - day + (day === 0 ? -6 : 1); // Adjust when day is Sunday
  return new Date(date.setDate(diff));
}

// Helper function to get bi-weekly payroll periods
function getBiWeeklyPeriod(weekNumber: number): { startWeek: number; endWeek: number } {
  // Ensure we always get even-numbered weeks for payroll periods
  // 18-19, 20-21, 22-23, etc.
  if (weekNumber % 2 === 0) {
    // Even week - this is the start of bi-weekly period
    return { startWeek: weekNumber, endWeek: weekNumber + 1 };
  } else {
    // Odd week - get the previous even week as start
    return { startWeek: weekNumber - 1, endWeek: weekNumber };
  }
}

// Helper function to get start date of a specific week number
function getStartDateOfWeek(year: number, weekNumber: number): Date {
  const firstDayOfYear = new Date(year, 0, 1);
  const firstMonday = new Date(firstDayOfYear);
  
  // Find first Monday of the year
  const dayOfWeek = firstDayOfYear.getDay();
  const daysToMonday = dayOfWeek === 0 ? 1 : (8 - dayOfWeek); // If Sunday, add 1, else 8 - dayOfWeek
  firstMonday.setDate(firstDayOfYear.getDate() + daysToMonday - 1);
  
  // Add weeks to get to the target week
  const targetDate = new Date(firstMonday);
  targetDate.setDate(firstMonday.getDate() + (weekNumber - 1) * 7);
  
  return targetDate;
}

// Helper function to calculate period dates
function calculatePeriodDates() {
  const now = new Date();
  const currentYear = now.getFullYear();
  const currentWeekNumber = getWeekNumber(now);
  
  const periods: Array<{
    id: number;
    title: string;
    startDate: Date;
    endDate: Date;
  }> = [];

  // Current bi-weekly period
  const currentPeriod = getBiWeeklyPeriod(currentWeekNumber);
  const currentPeriodStart = getStartDateOfWeek(currentYear, currentPeriod.startWeek);
  const currentPeriodEnd = new Date(currentPeriodStart);
  currentPeriodEnd.setDate(currentPeriodStart.getDate() + 13); // 2 weeks - 1 day, then end of day
  currentPeriodEnd.setHours(23, 59, 59, 999);
  
  periods.push({
    id: 1,
    title: `Current Period (Weeks ${currentPeriod.startWeek}-${currentPeriod.endWeek})`,
    startDate: currentPeriodStart,
    endDate: currentPeriodEnd
  });

  // Previous bi-weekly period
  const previousPeriodStartWeek = currentPeriod.startWeek - 2;
  const previousPeriodEndWeek = currentPeriod.startWeek - 1;
  
  if (previousPeriodStartWeek > 0) {
    const previousPeriodStart = getStartDateOfWeek(currentYear, previousPeriodStartWeek);
    const previousPeriodEnd = new Date(previousPeriodStart);
    previousPeriodEnd.setDate(previousPeriodStart.getDate() + 13);
    previousPeriodEnd.setHours(23, 59, 59, 999);
    
    periods.push({
      id: 2,
      title: `Previous Period (Weeks ${previousPeriodStartWeek}-${previousPeriodEndWeek})`,
      startDate: previousPeriodStart,
      endDate: previousPeriodEnd
    });
  }

  // Last completed bi-weekly period (if current is not complete)
  const lastCompletedStartWeek = currentPeriod.startWeek - 4;
  const lastCompletedEndWeek = currentPeriod.startWeek - 3;
  
  if (lastCompletedStartWeek > 0) {
    const lastCompletedStart = getStartDateOfWeek(currentYear, lastCompletedStartWeek);
    const lastCompletedEnd = new Date(lastCompletedStart);
    lastCompletedEnd.setDate(lastCompletedStart.getDate() + 13);
    lastCompletedEnd.setHours(23, 59, 59, 999);
    
    periods.push({
      id: 3,
      title: `Completed Period (Weeks ${lastCompletedStartWeek}-${lastCompletedEndWeek})`,
      startDate: lastCompletedStart,
      endDate: lastCompletedEnd
    });
  }

  // Monthly period (current month) - for management overview
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  monthEnd.setHours(23, 59, 59, 999);
  
  periods.push({
    id: 4,
    title: `This Month (${monthStart.toLocaleDateString('en-US', { month: 'long' })})`,
    startDate: monthStart,
    endDate: monthEnd
  });

  // Previous month - for historical data
  const prevMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const prevMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0);
  prevMonthEnd.setHours(23, 59, 59, 999);
  
  periods.push({
    id: 5,
    title: `Last Month (${prevMonthStart.toLocaleDateString('en-US', { month: 'long' })})`,
    startDate: prevMonthStart,
    endDate: prevMonthEnd
  });

  return periods;
}

// GET /api/app/chef/payroll/periods/available - Fetch available payroll periods
export async function GET(request: NextRequest): Promise<NextResponse<PayrollPeriodOption[] | ErrorResponse>> {
  try {
    console.log("[Payroll Periods API] GET request received");
    
    const periods = calculatePeriodDates();
    const defaultHourlyRate = 450; // DKK per hour - could be made configurable
    const periodOptions: PayrollPeriodOption[] = [];

    // For each period, calculate available hours and estimated amount
    for (const period of periods) {
      console.log(`[Payroll Periods API] Processing period: ${period.title}`);
      console.log(`[Payroll Periods API] Date range: ${period.startDate.toISOString()} to ${period.endDate.toISOString()}`);
      
      try {
        // Fetch confirmed work entries for this period that haven't been sent to payroll
        const workEntries = await prisma.workEntries.findMany({
          where: {
            confirmation_status: 'confirmed',
            isActive: true,
            start_time: { not: null },
            end_time: { not: null },
            sent_to_payroll: false,
            work_date: {
              gte: period.startDate,
              lte: period.endDate
            }
          },
          select: {
            entry_id: true,
            start_time: true,
            end_time: true,
            pause_minutes: true,
            work_date: true
          }
        });

        // Calculate total hours for this period
        let totalHours = 0;
        
        for (const entry of workEntries) {
          if (entry.start_time && entry.end_time) {
            const startTime = new Date(entry.start_time);
            const endTime = new Date(entry.end_time);
            const totalMinutes = (endTime.getTime() - startTime.getTime()) / (1000 * 60);
            const pauseMinutes = entry.pause_minutes || 0;
            const workedMinutes = Math.max(0, totalMinutes - pauseMinutes);
            const workedHours = workedMinutes / 60;
            
            totalHours += workedHours;
          }
        }

        const estimatedAmount = totalHours * defaultHourlyRate;

        periodOptions.push({
          id: period.id,
          title: period.title,
          start_date: period.startDate.toISOString(),
          end_date: period.endDate.toISOString(),
          available_hours: Math.round(totalHours * 100) / 100, // Round to 2 decimal places
          estimated_amount: Math.round(estimatedAmount)
        });

        console.log(`[Payroll Periods API] Period ${period.title}: ${workEntries.length} entries, ${totalHours.toFixed(2)}h, ${estimatedAmount.toFixed(0)} DKK`);
        
      } catch (dbError) {
        console.error(`[Payroll Periods API] Database error for period ${period.title}:`, dbError);
        
        // Add period with zero values if database query fails
        periodOptions.push({
          id: period.id,
          title: period.title,
          start_date: period.startDate.toISOString(),
          end_date: period.endDate.toISOString(),
          available_hours: 0,
          estimated_amount: 0
        });
      }
    }

    // Sort by ID to ensure consistent order (current period first)
    periodOptions.sort((a, b) => a.id - b.id);

    console.log(`[Payroll Periods API] Generated ${periodOptions.length} period options`);
    console.log(`[Payroll Periods API] Summary:`, periodOptions.map(p => ({
      id: p.id,
      title: p.title,
      hours: p.available_hours,
      amount: p.estimated_amount
    })));
    
    return NextResponse.json(periodOptions, { 
      status: 200,
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
      }
    });
  } catch (error) {
    console.error("[Payroll Periods API] GET error:", error);
    return NextResponse.json(
      { 
        error: "Failed to fetch available payroll periods", 
        message: "An error occurred while fetching payroll period data",
        details: error instanceof Error ? error.message : "Unknown error"
      }, 
      { status: 500 }
    );
  }
}

