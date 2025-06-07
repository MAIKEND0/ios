// src/app/api/app/chef/projects/[id]/billing-settings/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/projects/[id]/billing-settings
 * Pobiera wszystkie ustawienia rozliczeniowe dla projektu
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const projectId = parseInt(id, 10);
    
    if (isNaN(projectId)) {
      return NextResponse.json({ error: "Invalid project ID" }, { status: 400 });
    }

    // Sprawdź czy projekt istnieje
    const project = await prisma.projects.findUnique({
      where: { project_id: projectId }
    });

    if (!project) {
      return NextResponse.json({ error: "Project not found" }, { status: 404 });
    }

    const { searchParams } = new URL(request.url);
    const currentOnly = searchParams.get('current_only') === 'true';

    let where: any = { project_id: projectId };

    if (currentOnly) {
      const now = new Date();
      where = {
        ...where,
        effective_from: { lte: now },
        OR: [
          { effective_to: null },
          { effective_to: { gte: now } }
        ]
      };
    }

    const billingSettings = await prisma.billingSettings.findMany({
      where,
      orderBy: { effective_from: 'desc' }
    });

    return NextResponse.json(billingSettings, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/app/chef/projects/[id]/billing-settings:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * POST /api/app/chef/projects/[id]/billing-settings
 * Tworzy nowe ustawienia rozliczeniowe dla projektu
 */
export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const projectId = parseInt(id, 10);
    
    if (isNaN(projectId)) {
      return NextResponse.json({ error: "Invalid project ID" }, { status: 400 });
    }

    const body = await request.json();

    // Walidacja wymaganych pól
    const requiredFields = ['normal_rate', 'weekend_rate', 'overtime_rate1', 'overtime_rate2', 'weekend_overtime_rate1', 'weekend_overtime_rate2', 'effective_from'];
    const missingFields = requiredFields.filter(field => body[field] === undefined || body[field] === null);
    
    if (missingFields.length > 0) {
      return NextResponse.json(
        { error: `Missing required fields: ${missingFields.join(', ')}` },
        { status: 400 }
      );
    }

    // Sprawdź czy projekt istnieje
    const project = await prisma.projects.findUnique({
      where: { project_id: projectId }
    });

    if (!project) {
      return NextResponse.json({ error: "Project not found" }, { status: 404 });
    }

    // Walidacja dat
    const effectiveFrom = new Date(body.effective_from);
    const effectiveTo = body.effective_to ? new Date(body.effective_to) : null;

    if (effectiveTo && effectiveFrom >= effectiveTo) {
      return NextResponse.json(
        { error: "effective_from must be before effective_to" },
        { status: 400 }
      );
    }

    // Sprawdź czy nie ma konfliktu z istniejącymi ustawieniami
    const conflictingSettings = await prisma.billingSettings.findFirst({
      where: {
        project_id: projectId,
        OR: [
          {
            // Nowe ustawienia zaczynają się w trakcie istniejących
            effective_from: { lte: effectiveFrom },
            OR: [
              { effective_to: null },
              { effective_to: { gte: effectiveFrom } }
            ]
          },
          {
            // Nowe ustawienia kończą się w trakcie istniejących (jeśli mają datę końcową)
            ...(effectiveTo && {
              effective_from: { lte: effectiveTo },
              OR: [
                { effective_to: null },
                { effective_to: { gte: effectiveTo } }
              ]
            })
          }
        ]
      }
    });

    if (conflictingSettings) {
      return NextResponse.json(
        { 
          error: "Date range conflicts with existing billing settings",
          conflicting_setting_id: conflictingSettings.setting_id,
          conflict_period: {
            from: conflictingSettings.effective_from,
            to: conflictingSettings.effective_to
          }
        },
        { status: 409 }
      );
    }

    // Utwórz nowe ustawienia rozliczeniowe
    const newBillingSettings = await prisma.billingSettings.create({
      data: {
        project_id: projectId,
        normal_rate: parseFloat(body.normal_rate),
        weekend_rate: parseFloat(body.weekend_rate),
        overtime_rate1: parseFloat(body.overtime_rate1),
        overtime_rate2: parseFloat(body.overtime_rate2),
        weekend_overtime_rate1: parseFloat(body.weekend_overtime_rate1),
        weekend_overtime_rate2: parseFloat(body.weekend_overtime_rate2),
        effective_from: effectiveFrom,
        effective_to: effectiveTo
      }
    });

    return NextResponse.json(newBillingSettings, { status: 201 });

  } catch (err: any) {
    console.error("Błąd POST /api/app/chef/projects/[id]/billing-settings:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}