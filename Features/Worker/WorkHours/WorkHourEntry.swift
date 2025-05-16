// Features/Worker/Models/WorkHourEntry.swift
// KSR Cranes App
//
// Model pojedynczego wpisu godzinowego

import Foundation



struct WorkHourEntry: Identifiable, Codable {
    // Zakładamy, że backend zwraca `entry_id` jako np. Int
    // Możesz dostosować typ `id` jeśli to String
    let id: Int
    let date: Date
    let startTime: Date?
    let endTime: Date?
    let pauseMinutes: Int?
    let projectId: Int?
    let description: String?
    let status: EntryStatus
    let isDraft: Bool

    // Sformatowany łączny czas (godziny.minuty)
    var formattedTotalHours: String {
        guard
            let start = startTime,
            let end = endTime
        else { return "-" }

        let interval = end.timeIntervalSince(start)
        let hours = interval / 3600.0
        let pauseH = Double(pauseMinutes ?? 0) / 60.0
        let total = max(0, hours - pauseH)
        return String(format: "%.1f h", total)
    }
}
