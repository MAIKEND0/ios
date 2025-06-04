// Features/Worker/EditableWorkEntry.swift

import Foundation

/// Lekki, mutowalny model wpisu godzin pracy do UI
struct EditableWorkEntry: Identifiable {
    let id: Int
    let date: Date

    var startTime: Date?
    var endTime: Date?
    var pauseMinutes: Int
    var notes: String
    var isDraft: Bool
    var status: String

    /// Całkowite godziny pracy (hours)
    var totalHours: Double {
        guard let s = startTime, let e = endTime else { return 0 }
        let interval = e.timeIntervalSince(s) - Double(pauseMinutes) * 60
        return max(0, interval / 3600)
    }

    /// Inicjalizacja z APIService.WorkHourEntry
    init(from api: APIService.WorkHourEntry) {
        self.id           = api.entry_id
        self.date         = api.work_date
        self.startTime    = api.start_time
        self.endTime      = api.end_time
        self.pauseMinutes = api.pause_minutes ?? 0
        self.notes        = ""                   // jeśli API będzie zwracać opis, dodaj mapowanie
        self.isDraft      = api.is_draft ?? true
        self.status       = api.status ?? "pending"
    }

    /// Pusty wpis dla dni bez danych
    init(date: Date) {
        self.id           = Int(date.timeIntervalSince1970)
        self.date         = date
        self.startTime    = nil
        self.endTime      = nil
        self.pauseMinutes = 0
        self.notes        = ""
        self.isDraft      = true
        self.status       = "pending"
    }
}
