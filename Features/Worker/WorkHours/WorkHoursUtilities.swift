//
//  WorkHoursUtilities.swift
//  KSR Cranes App
//
//  Utilities and helper functions for Work Hours functionality
//

import SwiftUI
import Foundation

// MARK: - Work Hours Calculation Utilities
struct WorkHoursCalculator {
    
    /// Calculate total work hours from time interval, accounting for breaks
    static func calculateHours(start: Date, end: Date, pauseMinutes: Int = 0) -> Double {
        let interval = end.timeIntervalSince(start)
        let pauseSeconds = Double(pauseMinutes) * 60
        return max(0, (interval - pauseSeconds) / 3600)
    }
    
    /// Calculate hours for a work entry
    static func calculateHours(for entry: WorkerAPIService.WorkHourEntry) -> Double {
        guard let start = entry.start_time, let end = entry.end_time else { return 0 }
        return calculateHours(start: start, end: end, pauseMinutes: entry.pause_minutes ?? 0)
    }
    
    /// Calculate total hours for multiple entries
    static func calculateTotalHours(for entries: [WorkerAPIService.WorkHourEntry]) -> Double {
        return entries.reduce(0.0) { sum, entry in
            sum + calculateHours(for: entry)
        }
    }
    
    /// Calculate total kilometers for entries
    static func calculateTotalKm(for entries: [WorkerAPIService.WorkHourEntry]) -> Double {
        return entries.reduce(0.0) { sum, entry in
            sum + (entry.km ?? 0.0)
        }
    }
    
    /// Get unique work days from entries
    static func getUniqueWorkDays(from entries: [WorkerAPIService.WorkHourEntry]) -> Int {
        Set(entries.map { Calendar.current.startOfDay(for: $0.work_date) }).count
    }
    
    /// Calculate average hours per day
    static func calculateAverageHoursPerDay(for entries: [WorkerAPIService.WorkHourEntry]) -> Double {
        let totalHours = calculateTotalHours(for: entries)
        let uniqueDays = getUniqueWorkDays(from: entries)
        return uniqueDays > 0 ? totalHours / Double(uniqueDays) : 0
    }
}

// MARK: - Date Formatting Utilities
struct WorkHoursDateFormatter {
    
    static let shared = WorkHoursDateFormatter()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    private let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    /// Format date for section headers (Today, Yesterday, Day name, or full date)
    func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isToday(date) {
            return "Today"
        } else if calendar.isYesterday(date) {
            return "Yesterday"
        } else if calendar.isThisWeek(date) {
            return dayFormatter.string(from: date)
        } else {
            return longDateFormatter.string(from: date)
        }
    }
    
    /// Format time for display (handles nil gracefully)
    func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        return timeFormatter.string(from: date)
    }
    
    /// Format date range for display
    func formatDateRange(start: Date, end: Date) -> String {
        return "\(mediumDateFormatter.string(from: start)) - \(mediumDateFormatter.string(from: end))"
    }
}

// MARK: - Work Entry Extensions (extending existing extensions)
extension WorkerAPIService.WorkHourEntry {
    /// Computed property for calculated hours
    var calculatedHours: Double {
        return WorkHoursCalculator.calculateHours(for: self)
    }
    
    /// Check if entry has any time recorded
    var hasTimeRecorded: Bool {
        return start_time != nil && end_time != nil
    }
    
    /// Check if entry is complete (has required fields)
    var isComplete: Bool {
        return hasTimeRecorded && task_id > 0
    }
    
    /// Get time range as string
    var timeRangeString: String {
        guard let start = startTimeFormatted, let end = endTimeFormatted else {
            return "No time recorded"
        }
        return "\(start) – \(end)"
    }
}

// MARK: - Filter Utilities
struct WorkHoursFilters {
    
    /// Filter entries by task ID
    static func filterByTask(_ entries: [WorkerAPIService.WorkHourEntry], taskId: Int) -> [WorkerAPIService.WorkHourEntry] {
        guard taskId != 0 else { return entries }
        return entries.filter { $0.task_id == taskId }
    }
    
    /// Filter entries by status
    static func filterByStatus(_ entries: [WorkerAPIService.WorkHourEntry], status: EntryStatus) -> [WorkerAPIService.WorkHourEntry] {
        return entries.filter { effectiveStatus(for: $0) == status }
    }
    
    /// Filter entries by date range
    static func filterByDateRange(_ entries: [WorkerAPIService.WorkHourEntry], start: Date, end: Date) -> [WorkerAPIService.WorkHourEntry] {
        return entries.filter { entry in
            entry.work_date >= start && entry.work_date < end
        }
    }
    
    /// Filter entries by search text (searches notes and task titles)
    static func filterBySearchText(_ entries: [WorkerAPIService.WorkHourEntry], searchText: String) -> [WorkerAPIService.WorkHourEntry] {
        guard !searchText.isEmpty else { return entries }
        
        let searchLower = searchText.lowercased()
        return entries.filter { entry in
            (entry.description?.lowercased().contains(searchLower) ?? false) ||
            (entry.tasks?.title.lowercased().contains(searchLower) ?? false)
        }
    }
    
    /// Apply all filters
    static func applyFilters(
        to entries: [WorkerAPIService.WorkHourEntry],
        taskId: Int = 0,
        status: EntryStatus? = nil,
        dateRange: (start: Date, end: Date)? = nil,
        searchText: String = ""
    ) -> [WorkerAPIService.WorkHourEntry] {
        
        var filteredEntries = entries
        
        // Apply task filter
        if taskId != 0 {
            filteredEntries = filterByTask(filteredEntries, taskId: taskId)
        }
        
        // Apply status filter
        if let status = status {
            filteredEntries = filterByStatus(filteredEntries, status: status)
        }
        
        // Apply date range filter
        if let dateRange = dateRange {
            filteredEntries = filterByDateRange(filteredEntries, start: dateRange.start, end: dateRange.end)
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filteredEntries = filterBySearchText(filteredEntries, searchText: searchText)
        }
        
        return filteredEntries.sorted { $0.work_date > $1.work_date }
    }
}

// MARK: - Grouping Utilities
struct WorkHoursGrouping {
    
    /// Group entries by date
    static func groupByDate(_ entries: [WorkerAPIService.WorkHourEntry]) -> [Date: [WorkerAPIService.WorkHourEntry]] {
        return Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.work_date)
        }
    }
    
    /// Group entries by task
    static func groupByTask(_ entries: [WorkerAPIService.WorkHourEntry]) -> [Int: [WorkerAPIService.WorkHourEntry]] {
        return Dictionary(grouping: entries) { entry in
            entry.task_id
        }
    }
    
    /// Group entries by status
    static func groupByStatus(_ entries: [WorkerAPIService.WorkHourEntry]) -> [EntryStatus: [WorkerAPIService.WorkHourEntry]] {
        return Dictionary(grouping: entries) { entry in
            effectiveStatus(for: entry)
        }
    }
    
    /// Group entries by week
    static func groupByWeek(_ entries: [WorkerAPIService.WorkHourEntry]) -> [Date: [WorkerAPIService.WorkHourEntry]] {
        return Dictionary(grouping: entries) { entry in
            Calendar.current.startOfWeek(for: entry.work_date)
        }
    }
}

// MARK: - Statistics Utilities
struct WorkHoursStatistics {
    let totalHours: Double
    let totalKm: Double
    let uniqueWorkDays: Int
    let averageHoursPerDay: Double
    let statusBreakdown: [EntryStatus: Int]
    let taskBreakdown: [Int: Double] // Task ID to hours
    
    init(from entries: [WorkerAPIService.WorkHourEntry]) {
        self.totalHours = WorkHoursCalculator.calculateTotalHours(for: entries)
        self.totalKm = WorkHoursCalculator.calculateTotalKm(for: entries)
        self.uniqueWorkDays = WorkHoursCalculator.getUniqueWorkDays(from: entries)
        self.averageHoursPerDay = WorkHoursCalculator.calculateAverageHoursPerDay(for: entries)
        
        // Status breakdown
        let statusGroups = WorkHoursGrouping.groupByStatus(entries)
        self.statusBreakdown = statusGroups.mapValues { $0.count }
        
        // Task breakdown
        let taskGroups = WorkHoursGrouping.groupByTask(entries)
        self.taskBreakdown = taskGroups.mapValues { taskEntries in
            WorkHoursCalculator.calculateTotalHours(for: taskEntries)
        }
    }
}

// MARK: - Validation Utilities
struct WorkHoursValidation {
    
    /// Validate that start time is before end time
    static func validateTimeRange(start: Date?, end: Date?) -> Bool {
        guard let start = start, let end = end else { return false }
        return start < end
    }
    
    /// Validate that work hours are reasonable (not more than 24 hours)
    static func validateWorkHours(start: Date?, end: Date?, pauseMinutes: Int = 0) -> Bool {
        guard validateTimeRange(start: start, end: end),
              let start = start, let end = end else { return false }
        
        let hours = WorkHoursCalculator.calculateHours(start: start, end: end, pauseMinutes: pauseMinutes)
        return hours <= 24.0 && hours > 0
    }
    
    /// Validate pause minutes are reasonable
    static func validatePauseMinutes(_ pauseMinutes: Int) -> Bool {
        return pauseMinutes >= 0 && pauseMinutes <= 480 // Max 8 hours break
    }
    
    /// Validate kilometers are reasonable
    static func validateKilometers(_ km: Double?) -> Bool {
        guard let km = km else { return true } // nil is valid
        return km >= 0 && km <= 10000 // Max 10,000 km per day
    }
    
    /// Comprehensive validation for a work entry
    static func validateWorkEntry(_ entry: WorkerAPIService.WorkHourEntry) -> [String] {
        var errors: [String] = []
        
        if !validateTimeRange(start: entry.start_time, end: entry.end_time) {
            errors.append("Invalid time range")
        }
        
        if !validateWorkHours(start: entry.start_time, end: entry.end_time, pauseMinutes: entry.pause_minutes ?? 0) {
            errors.append("Work hours must be between 0 and 24 hours")
        }
        
        if !validatePauseMinutes(entry.pause_minutes ?? 0) {
            errors.append("Break time must be between 0 and 8 hours")
        }
        
        if !validateKilometers(entry.km) {
            errors.append("Distance must be between 0 and 10,000 km")
        }
        
        if entry.task_id <= 0 {
            errors.append("Valid task must be selected")
        }
        
        return errors
    }
}

// MARK: - Export Utilities
struct WorkHoursExport {
    
    /// Generate CSV content from work entries
    static func generateCSV(from entries: [WorkerAPIService.WorkHourEntry]) -> String {
        var csv = "Date,Start Time,End Time,Hours,Break (min),Distance (km),Task,Notes,Status\n"
        
        for entry in entries.sorted(by: { $0.work_date < $1.work_date }) {
            let date = DateFormatter.isoDate.string(from: entry.work_date)
            let startTime = entry.startTimeFormatted ?? ""
            let endTime = entry.endTimeFormatted ?? ""
            let hours = String(format: "%.2f", entry.calculatedHours)
            let pauseMinutes = String(entry.pause_minutes ?? 0)
            let km = String(format: "%.2f", entry.km ?? 0)
            let task = entry.tasks?.title ?? "Task \(entry.task_id)"
            let notes = (entry.description ?? "").replacingOccurrences(of: ",", with: ";")
            let status = effectiveStatus(for: entry).displayName
            
            csv += "\(date),\(startTime),\(endTime),\(hours),\(pauseMinutes),\(km),\(task),\(notes),\(status)\n"
        }
        
        return csv
    }
    
    /// Generate summary text from work entries
    static func generateSummary(from entries: [WorkerAPIService.WorkHourEntry], title: String = "Work Hours Summary") -> String {
        let stats = WorkHoursStatistics(from: entries)
        
        var summary = "\(title)\n"
        summary += "Generated: \(DateFormatter.iso8601WithFractions.string(from: Date()))\n\n"
        summary += "SUMMARY:\n"
        summary += "Total Hours: \(String(format: "%.2f", stats.totalHours))\n"
        summary += "Total Distance: \(String(format: "%.2f", stats.totalKm)) km\n"
        summary += "Work Days: \(stats.uniqueWorkDays)\n"
        summary += "Average Hours/Day: \(String(format: "%.2f", stats.averageHoursPerDay))\n\n"
        
        summary += "STATUS BREAKDOWN:\n"
        let allStatusTypes: [EntryStatus] = [.draft, .pending, .submitted, .confirmed, .rejected]
        for status in allStatusTypes {
            let count = stats.statusBreakdown[status] ?? 0
            if count > 0 {
                summary += "\(status.displayName): \(count)\n"
            }
        }
        
        return summary
    }
}
