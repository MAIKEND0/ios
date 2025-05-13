//
//  WorkerModels.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import Foundation

// Model dla wpisu godzin pracy
struct WorkHourEntry: Identifiable, Codable {
    var id: String?
    var date: Date
    var startTime: Date
    var endTime: Date
    var projectId: String
    var description: String?
    var employeeId: String
    var createdAt: Date?
    var updatedAt: Date?
    
    // Obliczanie całkowitej liczby godzin
    var totalHours: Double {
        let difference = endTime.timeIntervalSince(startTime)
        return difference / 3600 // Konwersja sekund na godziny
    }
    
    // Sformatowana liczba godzin (np. "8h 30m")
    var formattedTotalHours: String {
        let totalSeconds = endTime.timeIntervalSince(startTime)
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        return "\(hours)h \(minutes)m"
    }
    
    // Przykładowe dane do podglądu
    static var example: WorkHourEntry {
        WorkHourEntry(
            id: "1",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: Date()) ?? Date(),
            projectId: "project-123",
            description: "Praca przy montażu dźwigu",
            employeeId: "emp-456",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// Model dla ogłoszeń
struct Announcement: Identifiable, Codable {
    var id: String
    var title: String
    var content: String
    var publishedAt: Date
    var expiresAt: Date?
    var priority: AnnouncementPriority
    
    // Przykładowe dane do podglądu
    static var examples: [Announcement] {
        [
            Announcement(
                id: "ann-1",
                title: "Zamknięcie biura na święta",
                content: "Biuro będzie zamknięte w dniach 24-26 grudnia.",
                publishedAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                priority: .normal
            ),
            Announcement(
                id: "ann-2",
                title: "Nowy projekt w Malmö",
                content: "Rozpoczynamy nowy projekt w Malmö. Poszukujemy chętnych operatorów do pracy.",
                publishedAt: Date(),
                expiresAt: nil,
                priority: .high
            )
        ]
    }
}

// Enum dla priorytetów ogłoszeń
enum AnnouncementPriority: String, Codable {
    case low
    case normal
    case high
}
