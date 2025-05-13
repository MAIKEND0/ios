//
//  Announcement.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import Foundation

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
