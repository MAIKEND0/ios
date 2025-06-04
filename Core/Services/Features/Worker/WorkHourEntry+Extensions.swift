//
//  WorkHourEntry+Extensions.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 14/05/2025.
//

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
    
    // Sformatowana liczba kilometrów
    var formattedKm: String {
        guard let km = km else { return "-" }
        return String(format: "%.2f km", km)
    }
}

// Extension for WorkerAPIService.WorkHourEntry to add formatting methods
extension WorkerAPIService.WorkHourEntry {
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
    
    // Sformatowana liczba kilometrów
    var kmFormatted: String {
        guard let km = km else { return "-" }
        return String(format: "%.2f km", km)
    }
}

// Extension for ManagerAPIService.WorkHourEntry to add formatting methods
extension ManagerAPIService.WorkHourEntry {
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
    
    // Sformatowana liczba kilometrów
    var kmFormatted: String {
        guard let km = km else { return "-" }
        return String(format: "%.2f km", km)
    }
}
