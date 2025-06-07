// src/app/api/app/announcements/route.ts
import { NextRequest, NextResponse } from "next/server";

// Typy dla ogłoszeń, zgodne z modelem w iOS
type AnnouncementPriority = "low" | "normal" | "high";

interface Announcement {
  id: string;
  title: string;
  content: string;
  publishedAt: string; // ISO date string
  expiresAt: string | null; // ISO date string
  priority: AnnouncementPriority;
}

// GET - pobieranie ogłoszeń
export async function GET(request: NextRequest) {
  try {
    // Ten endpoint będzie zwracał przykładowe dane, dopóki nie zintegrujemy go z bazą
    // Gdy baza będzie gotowa, zamienimy to na rzeczywiste zapytania do bazy danych
    
    // Ustalamy datę dla przykładowych danych
    const now = new Date();
    const oneWeekLater = new Date();
    oneWeekLater.setDate(now.getDate() + 7);
    
    // Przykładowe dane
    const sampleAnnouncements: Announcement[] = [
      {
        id: "ann-1",
        title: "Zamknięcie biura na święta",
        content: "Biuro będzie zamknięte w dniach 24-26 grudnia.",
        publishedAt: now.toISOString(),
        expiresAt: oneWeekLater.toISOString(),
        priority: "normal"
      },
      {
        id: "ann-2",
        title: "Nowy projekt w Malmö",
        content: "Rozpoczynamy nowy projekt w Malmö. Poszukujemy chętnych operatorów do pracy.",
        publishedAt: now.toISOString(),
        expiresAt: null,
        priority: "high"
      }
    ];
    
    // Możesz zakomentować poniższą linię, aby zwrócić pustą tablicę
    // const announcements: Announcement[] = [];
    
    // Lub odkomentować, aby zwrócić przykładowe dane
    const announcements: Announcement[] = sampleAnnouncements;
    
    return NextResponse.json(announcements);
  } catch (error) {
    console.error("[API] Error in announcements endpoint:", error);
    return NextResponse.json(
      { error: "Failed to fetch announcements" },
      { status: 500 }
    );
  }
}

// Na przyszłość, gdy będziesz miał tabelę w bazie:
// 
// async function getAnnouncementsFromDatabase() {
//   try {
//     const announcements = await prisma.announcements.findMany({
//       where: {
//         // Możesz dodać warunki, np. tylko aktywne ogłoszenia
//         // isActive: true,
//         // expiresAt: { gt: new Date() }
//       },
//       orderBy: {
//         publishedAt: 'desc'
//       }
//     });
//     
//     return announcements;
//   } catch (error) {
//     console.error("Error fetching announcements from database:", error);
//     return [];
//   }
// }