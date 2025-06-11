import Foundation

class CalendarCSVGenerator {
    private let viewModel: ChefManagementCalendarViewModel
    private let dateRange: (start: Date, end: Date)
    private let includeDetails: Bool
    private let includeWorkerInfo: Bool
    
    init(viewModel: ChefManagementCalendarViewModel,
         dateRange: (start: Date, end: Date),
         includeDetails: Bool,
         includeWorkerInfo: Bool) {
        self.viewModel = viewModel
        self.dateRange = dateRange
        self.includeDetails = includeDetails
        self.includeWorkerInfo = includeWorkerInfo
    }
    
    func generateCSV() async throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "KSR_Calendar_\(formatDateForFileName(dateRange.start))_\(formatDateForFileName(dateRange.end)).csv"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        var csvContent = ""
        
        // Add header
        csvContent += "KSR Cranes - Management Calendar Export\n"
        csvContent += "Generated: \(DateFormatter.userFriendly.string(from: Date()))\n"
        csvContent += "Period: \(DateFormatter.userFriendly.string(from: dateRange.start)) - \(DateFormatter.userFriendly.string(from: dateRange.end))\n\n"
        
        // Events section
        csvContent += await generateEventsCSV()
        
        // Worker availability section (if requested)
        if includeWorkerInfo {
            csvContent += "\n\n"
            csvContent += await generateWorkerAvailabilityCSV()
        }
        
        // Write to file
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        print("📊 [CSV] Generated calendar CSV: \(fileName)")
        return fileURL
    }
    
    @MainActor
    private func generateEventsCSV() async -> String {
        var csv = "CALENDAR EVENTS\n"
        csv += "Date,Time,Type,Title,Description,Priority,Status,Duration,Workers Required\n"
        
        let events = getEventsInDateRange().sorted { $0.date < $1.date }
        
        for event in events {
            let date = DateFormatter.userFriendly.string(from: event.date)
            let time = DateFormatter.time.string(from: event.date)
            let type = event.type.displayName
            let title = escapeCSV(event.title)
            let description = escapeCSV(event.description)
            let priority = event.priority.displayName
            let status = event.status.displayName
            let duration = formatDuration(event.duration)
            let workersRequired = event.resourceRequirements.first?.workerCount ?? 0
            
            csv += "\(date),\(time),\(type),\(title),\(description),\(priority),\(status),\(duration),\(workersRequired)\n"
        }
        
        return csv
    }
    
    @MainActor
    private func generateWorkerAvailabilityCSV() async -> String {
        // Access MainActor-isolated property safely
        let matrix = viewModel.workerAvailabilityMatrix
        guard let matrix = matrix else {
            return "WORKER AVAILABILITY\nNo worker availability data available\n"
        }
        
        var csv = "WORKER AVAILABILITY\n"
        csv += "Worker Name,Role,Status,Weekly Hours,Utilization %,Projects,Tasks,Leave Days\n"
        
        for workerRow in matrix.workers {
            let worker = workerRow.worker
            let stats = workerRow.weeklyStats
            
            let name = escapeCSV(worker.name)
            let role = escapeCSV(worker.role)
            let status = worker.isActive ? "Active" : "Inactive"
            let hours = String(format: "%.1f", stats.totalHours)
            let utilization = String(format: "%.0f", stats.utilization * 100)
            let projects = "\(stats.projectCount)"
            let tasks = "\(stats.taskCount)"
            let leaveInfo = getWorkerLeaveInfo(for: worker.id, from: workerRow)
            
            csv += "\(name),\(role),\(status),\(hours),\(utilization),\(projects),\(tasks),\(leaveInfo)\n"
        }
        
        return csv
    }
    
    private func getWorkerLeaveInfo(for workerId: Int, from workerRow: WorkerAvailabilityRow) -> String {
        let leaveDays = workerRow.dailyAvailability.values
            .filter { $0.status == .onLeave || $0.status == .sick }
            .count
        
        return "\(leaveDays)"
    }
    
    @MainActor
    private func getEventsInDateRange() -> [ManagementCalendarEvent] {
        return viewModel.filteredEvents.filter { event in
            event.date >= dateRange.start && event.date <= dateRange.end
        }
    }
    
    private func escapeCSV(_ text: String) -> String {
        let escaped = text.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }
    
    private func formatDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "N/A" }
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDateForFileName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}