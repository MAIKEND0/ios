//
//  WorkHourEntry.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import Foundation

// Pomocnik dla formatowania dat ISO8601
extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let iso8601DateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

// Enum dla statusu wpisu
enum EntryStatus: String, Codable {
    case draft = "draft"
    case pending = "pending"
    case submitted = "submitted"
    case confirmed = "confirmed"
    case rejected = "rejected"
}

// Enum dla statusu potwierdzenia
enum ConfirmationStatus: String, Codable {
    case pending = "pending"
    case submitted = "submitted"
    case confirmed = "confirmed"
    case rejected = "rejected"
}

struct WorkHourEntry: Identifiable, Codable {
    var id: String?
    var date: Date
    var startTime: Date?
    var endTime: Date?
    var projectId: String
    var description: String?
    var employeeId: String
    var pauseMinutes: Int = 0
    var status: EntryStatus = .pending
    var confirmationStatus: ConfirmationStatus = .pending
    var confirmedBy: String?
    var confirmedAt: Date?
    var isDraft: Bool = true
    var isActive: Bool = true
    var createdAt: Date?
    var updatedAt: Date?
    
    // Klucze kodujące do mapowania nazw pól JSON
    enum CodingKeys: String, CodingKey {
        case id
        case date = "work_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case projectId = "project_id"
        case description
        case employeeId = "employee_id"
        case pauseMinutes = "pause_minutes"
        case status
        case confirmationStatus = "confirmation_status"
        case confirmedBy = "confirmed_by"
        case confirmedAt = "confirmed_at"
        case isDraft = "is_draft"
        case isActive
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Własny inicjalizator dla dekodowania
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        
        // Dekodowanie daty
        if let dateString = try container.decodeIfPresent(String.self, forKey: .date) {
            if let parsedDate = DateFormatter.iso8601DateOnly.date(from: dateString) {
                date = parsedDate
            } else {
                throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Date format invalid")
            }
        } else {
            date = Date() // Domyślna wartość
        }
        
        // Dekodowanie czasu rozpoczęcia
        if let startTimeString = try container.decodeIfPresent(String.self, forKey: .startTime) {
            startTime = DateFormatter.iso8601Full.date(from: startTimeString)
        } else {
            startTime = nil
        }
        
        // Dekodowanie czasu zakończenia
        if let endTimeString = try container.decodeIfPresent(String.self, forKey: .endTime) {
            endTime = DateFormatter.iso8601Full.date(from: endTimeString)
        } else {
            endTime = nil
        }
        
        projectId = try container.decodeIfPresent(String.self, forKey: .projectId) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        employeeId = try container.decodeIfPresent(String.self, forKey: .employeeId) ?? ""
        pauseMinutes = try container.decodeIfPresent(Int.self, forKey: .pauseMinutes) ?? 0
        
        // Dekodowanie statusów
        if let statusString = try container.decodeIfPresent(String.self, forKey: .status),
           let decodedStatus = EntryStatus(rawValue: statusString) {
            status = decodedStatus
        } else {
            status = .pending
        }
        
        if let confirmationStatusString = try container.decodeIfPresent(String.self, forKey: .confirmationStatus),
           let decodedConfStatus = ConfirmationStatus(rawValue: confirmationStatusString) {
            confirmationStatus = decodedConfStatus
        } else {
            confirmationStatus = .pending
        }
        
        confirmedBy = try container.decodeIfPresent(String.self, forKey: .confirmedBy)
        
        // Dekodowanie daty potwierdzenia
        if let confirmedAtString = try container.decodeIfPresent(String.self, forKey: .confirmedAt) {
            confirmedAt = DateFormatter.iso8601Full.date(from: confirmedAtString)
        } else {
            confirmedAt = nil
        }
        
        isDraft = try container.decodeIfPresent(Bool.self, forKey: .isDraft) ?? true
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        
        // Dekodowanie daty utworzenia
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = DateFormatter.iso8601Full.date(from: createdAtString)
        } else {
            createdAt = nil
        }
        
        // Dekodowanie daty aktualizacji
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = DateFormatter.iso8601Full.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }
    
    // Własny encoder dla poprawnego formatowania dat
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        
        // Kodowanie daty
        try container.encode(DateFormatter.iso8601DateOnly.string(from: date), forKey: .date)
        
        // Kodowanie czasu rozpoczęcia
        if let start = startTime {
            try container.encode(DateFormatter.iso8601Full.string(from: start), forKey: .startTime)
        } else {
            try container.encodeNil(forKey: .startTime)
        }
        
        // Kodowanie czasu zakończenia
        if let end = endTime {
            try container.encode(DateFormatter.iso8601Full.string(from: end), forKey: .endTime)
        } else {
            try container.encodeNil(forKey: .endTime)
        }
        
        try container.encode(projectId, forKey: .projectId)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(employeeId, forKey: .employeeId)
        try container.encode(pauseMinutes, forKey: .pauseMinutes)
        try container.encode(status.rawValue, forKey: .status)
        try container.encode(confirmationStatus.rawValue, forKey: .confirmationStatus)
        try container.encodeIfPresent(confirmedBy, forKey: .confirmedBy)
        
        // Kodowanie daty potwierdzenia
        if let confirmedAt = confirmedAt {
            try container.encode(DateFormatter.iso8601Full.string(from: confirmedAt), forKey: .confirmedAt)
        } else {
            try container.encodeNil(forKey: .confirmedAt)
        }
        
        try container.encode(isDraft, forKey: .isDraft)
        try container.encode(isActive, forKey: .isActive)
        
        // Kodowanie daty utworzenia
        if let createdAt = createdAt {
            try container.encode(DateFormatter.iso8601Full.string(from: createdAt), forKey: .createdAt)
        } else {
            try container.encodeNil(forKey: .createdAt)
        }
        
        // Kodowanie daty aktualizacji
        if let updatedAt = updatedAt {
            try container.encode(DateFormatter.iso8601Full.string(from: updatedAt), forKey: .updatedAt)
        } else {
            try container.encodeNil(forKey: .updatedAt)
        }
    }
    
    // Standardowy inicjalizator
    init(
        id: String? = nil,
        date: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        projectId: String,
        description: String? = nil,
        employeeId: String,
        pauseMinutes: Int = 0,
        status: EntryStatus = .pending,
        confirmationStatus: ConfirmationStatus = .pending,
        confirmedBy: String? = nil,
        confirmedAt: Date? = nil,
        isDraft: Bool = true,
        isActive: Bool = true,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.projectId = projectId
        self.description = description
        self.employeeId = employeeId
        self.pauseMinutes = pauseMinutes
        self.status = status
        self.confirmationStatus = confirmationStatus
        self.confirmedBy = confirmedBy
        self.confirmedAt = confirmedAt
        self.isDraft = isDraft
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed property for total hours
    var totalHours: Double {
        guard let start = startTime, let end = endTime else { return 0 }
        let difference = end.timeIntervalSince(start)
        return max((difference / 3600) - Double(pauseMinutes) / 60, 0)
    }
    
    // Formatted total hours
    var formattedTotalHours: String {
        let hours = Int(totalHours)
        let minutes = Int((totalHours - Double(hours)) * 60)
        
        return "\(hours)h \(minutes)m"
    }
    
    // Day of week
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    // Example data
    static var example: WorkHourEntry {
        WorkHourEntry(
            id: "1",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
            endTime: Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: Date()),
            projectId: "project-123",
            description: "Crane installation work",
            employeeId: "emp-456",
            pauseMinutes: 30,
            status: .pending,
            isDraft: true
        )
    }
}

// Pomocnicze rozszerzenie dla wygodnej obsługi opcjonalnych String
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self == nil || self == ""
    }
}
