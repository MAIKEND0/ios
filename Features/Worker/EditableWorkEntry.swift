//
//  EditableWorkEntry.swift
//  Features/Worker/EditableWorkEntry.swift
//

import Foundation

/// Lekki, mutowalny model wpisu godzin pracy do UI
struct EditableWorkEntry: Identifiable {
    let id: Int
    var date: Date

    var startTime: Date?
    var endTime: Date?
    var pauseMinutes: Int
    var notes: String
    var isDraft: Bool
    var status: String
    var km: Double? // Dodano pole km

    /// Total work hours (in hours)
    var totalHours: Double {
        guard let s = startTime, let e = endTime else { return 0 }
        let interval = e.timeIntervalSince(s) - Double(pauseMinutes) * 60
        return max(0, interval / 3600)
    }

    /// Initialize from WorkerAPIService.WorkHourEntry
    init(from api: WorkerAPIService.WorkHourEntry) {
        self.id = api.entry_id
        // Przesuń work_date z UTC do lokalnej strefy czasowej (CEST)
        let localTimeZone = TimeZone.current
        self.date = api.work_date.addingTimeInterval(Double(localTimeZone.secondsFromGMT(for: api.work_date)))
        self.startTime = api.start_time
        self.endTime = api.end_time
        self.pauseMinutes = api.pause_minutes ?? 0
        self.notes = api.description ?? ""
        self.isDraft = api.is_draft ?? false // Upewnij się, że isDraft jest ustawiane poprawnie
        self.status = api.is_draft ?? false ? "draft" : (api.status ?? "pending")
        self.km = api.km // Mapowanie km z API
    }

    /// Empty entry for days without data
    init(date: Date) {
        self.id = Int(date.timeIntervalSince1970)
        self.date = date
        self.startTime = nil
        self.endTime = nil
        self.pauseMinutes = 0
        self.notes = ""
        self.isDraft = true
        self.status = "draft"
        self.km = nil // Domyślna wartość dla km
    }
}
