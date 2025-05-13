//
//  WorkHourEntry.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import Foundation

struct WorkHourEntry: Identifiable, Codable {
    var id: String?
    var date: Date
    var startTime: Date
    var endTime: Date
    var projectId: String
    var description: String?
    var employeeId: String
    
    // Computed property for total hours
    var totalHours: Double {
        let difference = endTime.timeIntervalSince(startTime)
        return difference / 3600 // Convert seconds to hours
    }
    
    // Formatted total hours
    var formattedTotalHours: String {
        let totalSeconds = endTime.timeIntervalSince(startTime)
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        return "\(hours)h \(minutes)m"
    }
    
    // Example data
    static var example: WorkHourEntry {
        WorkHourEntry(
            id: "1",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: Date()) ?? Date(),
            projectId: "project-123",
            description: "Crane installation work",
            employeeId: "emp-456"
        )
    }
}

// Add this in a separate file in the same folder (Core/Models/Announcement.swift)
struct Announcement: Identifiable, Codable {
    var id: String
    var title: String
    var content: String
    var publishedAt: Date
    var expiresAt: Date?
    var priority: AnnouncementPriority
    
    // Example data
    static var examples: [Announcement] {
        [
            Announcement(
                id: "ann-1",
                title: "Office Closed for Holiday",
                content: "The office will be closed on Monday for the national holiday.",
                publishedAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                priority: .normal
            ),
            Announcement(
                id: "ann-2",
                title: "New Project in Malmö",
                content: "Looking for crane operators interested in working on our new project in Malmö.",
                publishedAt: Date(),
                expiresAt: nil,
                priority: .high
            )
        ]
    }
}

enum AnnouncementPriority: String, Codable {
    case low
    case normal
    case high
}
