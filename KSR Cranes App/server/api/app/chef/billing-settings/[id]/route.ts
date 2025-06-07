// src/app/api/app/chef/billing-settings/[id]/route.ts

import { NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/billing-settings/[id]
 * Pobiera pojedyncze ustawienie rozliczeniowe
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const settingId = parseInt(id, 10);
    
    if (isNaN(settingId)) {
      return NextResponse.json({ error: "Invalid setting ID" }, { status: 400 });
    }

    const billingSetting = await prisma.billingSettings.findUnique({
      where: { setting_id: settingId },
      include: {
        Projects: {
          select: {
            project_id: true,
            title: true,
            status: true
          }
        }
      }
    });

    if (!billingSetting) {
      return NextResponse.json({ error: "Billing setting not found" }, { status: 404 });
    }

    return NextResponse.json(billingSetting, { status: 200 });

  } catch (err: any) {
    console.error("Błąd GET /api/app/chef/billing-settings/[id]:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * PATCH /api/app/chef/billing-settings/[id]
 * Aktualizuje ustawienia rozliczeniowe
 */
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const settingId = parseInt(id, 10);
    
    if (isNaN(settingId)) {
      return NextResponse.json({ error: "Invalid setting ID" }, { status: 400 });
    }

    const body = await request.json();

    // Sprawdź czy ustawienie istnieje
    const existingSetting = await prisma.billingSettings.findUnique({
      where: { setting_id: settingId }
    });

    if (!existingSetting) {
      return NextResponse.json({ error: "Billing setting not found" }, { status: 404 });
    }

    // Przygotuj dane do aktualizacji
    const updateData: any = {};
    
    if (body.normal_rate !== undefined) updateData.normal_rate = parseFloat(body.normal_rate);
    if (body.weekend_rate !== undefined) updateData.weekend_rate = parseFloat(body.weekend_rate);
    if (body.overtime_rate1 !== undefined) updateData.overtime_rate1 = parseFloat(body.overtime_rate1);
    if (body.overtime_rate2 !== undefined) updateData.overtime_rate2 = parseFloat(body.overtime_rate2);
    if (body.weekend_overtime_rate1 !== undefined) updateData.weekend_overtime_rate1 = parseFloat(body.weekend_overtime_rate1);
    if (body.weekend_overtime_rate2 !== undefined) updateData.weekend_overtime_rate2 = parseFloat(body.weekend_overtime_rate2);
    if (body.effective_from !== undefined) updateData.effective_from = new Date(body.effective_from);
    if (body.effective_to !== undefined) updateData.effective_to = body.effective_to ? new Date(body.effective_to) : null;

    // Walidacja dat jeśli się zmieniają
    if (updateData.effective_from || updateData.effective_to) {
      const effectiveFrom = updateData.effective_from || existingSetting.effective_from;
      const effectiveTo = updateData.effective_to !== undefined ? updateData.effective_to : existingSetting.effective_to;

      if (effectiveTo && effectiveFrom >= effectiveTo) {
        return NextResponse.json(
          { error: "effective_from must be before effective_to" },
          { status: 400 }
        );
      }

      // Sprawdź konflikty z innymi ustawieniami (pomijając aktualne)
      const conflictingSettings = await prisma.billingSettings.findFirst({
        where: {
          project_id: existingSetting.project_id,
          setting_id: { not: settingId },
          OR: [
            {
              effective_from: { lte: effectiveFrom },
              OR: [
                { effective_to: null },
                { effective_to: { gte: effectiveFrom } }
              ]
            },
            {
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
            conflicting_setting_id: conflictingSettings.setting_id
          },
          { status: 409 }
        );
      }
    }

    // Aktualizuj ustawienia
    const updatedSetting = await prisma.billingSettings.update({
      where: { setting_id: settingId },
      data: updateData,
      include: {
        Projects: {
          select: {
            project_id: true,
            title: true
          }
        }
      }
    });

    return NextResponse.json(updatedSetting, { status: 200 });

  } catch (err: any) {
    console.error("Błąd PATCH /api/app/chef/billing-settings/[id]:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}

/**
 * DELETE /api/app/chef/billing-settings/[id]
 * Usuwa ustawienia rozliczeniowe
 */
export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
): Promise<NextResponse> {
  try {
    const { id } = await params;
    const settingId = parseInt(id, 10);
    
    if (isNaN(settingId)) {
      return NextResponse.json({ error: "Invalid setting ID" }, { status: 400 });
    }

    // Sprawdź czy ustawienie istnieje
    const existingSetting = await prisma.billingSettings.findUnique({
      where: { setting_id: settingId },
      include: {
        Projects: {
          select: { title: true }
        }
      }
    });

    if (!existingSetting) {
      return NextResponse.json({ error: "Billing setting not found" }, { status: 404 });
    }

    // Sprawdź czy nie ma powiązanych wpisów pracy które używają tych stawek
    const relatedWorkEntries = await prisma.workEntries.count({
      where: {
        Tasks: {
          project_id: existingSetting.project_id
        },
        work_date: {
          gte: existingSetting.effective_from,
          ...(existingSetting.effective_to && { lte: existingSetting.effective_to })
        },
        status: 'confirmed'
      }
    });

    if (relatedWorkEntries > 0) {
      return NextResponse.json({
        error: "Cannot delete billing settings that are used by confirmed work entries",
        related_work_entries: relatedWorkEntries
      }, { status: 409 });
    }

    // Usuń ustawienia
    await prisma.billingSettings.delete({
      where: { setting_id: settingId }
    });

    return NextResponse.json({
      success: true,
      message: "Billing settings deleted successfully",
      project_title: existingSetting.Projects?.title
    }, { status: 200 });

  } catch (err: any) {
    console.error("Błąd DELETE /api/app/chef/billing-settings/[id]:", err);
    return NextResponse.json({ error: getErrorMessage(err) }, { status: 500 });
  }
}