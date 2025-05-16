// Features/Worker/WorkHourEntry+Extensions.swift
import Foundation

// Extensions for the WorkHourEntry struct to add formatting methods
extension WorkHourEntry {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone.current // Użyj lokalnej strefy czasowej
        return formatter.string(from: date)
    }
    
    var formattedStartTime: String {
        guard let time = startTime else { return "-" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current // Użyj lokalnej strefy czasowej
        return formatter.string(from: time)
    }
    
    var formattedEndTime: String {
        guard let time = endTime else { return "-" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current // Użyj lokalnej strefy czasowej
        return formatter.string(from: time)
    }
    
    // Adding for APIService.WorkHourEntry
    static var workDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone.current // Użyj lokalnej strefy czasowej
        return formatter.string(from: Date())
    }
    
    static var startTimeFormatted: String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current // Użyj lokalnej strefy czasowej
        return formatter.string(from: Date())
    }
    
    static var endTimeFormatted: String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current // Użyj lokalnej strefy czasowej
        return formatter.string(from: Date())
    }
}

// Extension for APIService.WorkHourEntry to add the same formatting methods
extension APIService.WorkHourEntry {
    var workDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone.current // Użyj lokalnej strefy czasowej
        return formatter.string(from: work_date)
    }
    
    var startTimeFormatted: String? {
        guard let time = start_time else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current // Użyj lokalnej strefy czasowej
        return formatter.string(from: time)
    }
    
    var endTimeFormatted: String? {
        guard let time = end_time else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current // Użyj lokalnej strefy czasowej
        return formatter.string(from: time)
    }
}
