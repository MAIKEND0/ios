//
//  PayrollModels.swift
//  KSR Cranes App
//
//  🔧 FIXED: Removed duplicate types, fixed enum references
//

import Foundation
import SwiftUI

// MARK: - PayrollModels Namespace
enum PayrollModels {
    // MARK: - Batch Employee Breakdown
    struct BatchEmployeeBreakdown: Identifiable, Codable {
        let id = UUID()
        let employeeId: Int
        let name: String
        let totalHours: Double
        let totalAmount: Decimal
        
        private enum CodingKeys: String, CodingKey {
            case employeeId = "employee_id"
            case name
            case totalHours = "total_hours"
            case totalAmount = "total_amount"
        }
        
        init(employeeId: Int, name: String, totalHours: Double, totalAmount: Decimal) {
            self.employeeId = employeeId
            self.name = name
            self.totalHours = totalHours
            self.totalAmount = totalAmount
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            employeeId = try container.decode(Int.self, forKey: .employeeId)
            name = try container.decode(String.self, forKey: .name)
            totalHours = try container.decode(Double.self, forKey: .totalHours)
            totalAmount = try container.decode(Decimal.self, forKey: .totalAmount)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(employeeId, forKey: .employeeId)
            try container.encode(name, forKey: .name)
            try container.encode(totalHours, forKey: .totalHours)
            try container.encode(totalAmount, forKey: .totalAmount)
        }
    }
}

// MARK: - 🔧 REMOVED: Employee, Customer, Project definitions (use ProjectModels.swift instead)
// MARK: - 🔧 REMOVED: EmployeeRole, EmployeeCraneType enums (use ProjectModels.swift instead)

// MARK: - Dashboard Stats
struct PayrollDashboardStats: Codable {
    let pendingHours: Int
    let readyEmployees: Int
    let totalAmount: Decimal
    let activeBatches: Int
    let currentPeriod: PayrollPeriod
    let periodProgress: Double
    let lastUpdated: Date
    
    private enum CodingKeys: String, CodingKey {
        case pendingHours = "pending_hours"
        case readyEmployees = "ready_employees"
        case totalAmount = "total_amount"
        case activeBatches = "active_batches"
        case currentPeriod = "current_period"
        case periodProgress = "period_progress"
        case lastUpdated = "last_updated"
    }
    
    // Mock data removed - use real API data only
}

// MARK: - Payroll Period
struct PayrollPeriod: Codable, Identifiable {
    let id: Int
    let year: Int
    let periodNumber: Int
    let startDate: Date
    let endDate: Date
    let status: PayrollPeriodStatus
    let weekNumber: Int
    
    var displayName: String {
        "Period \(periodNumber)/\(year)"
    }
    
    var weekDisplayName: String {
        "Week \(weekNumber) of 2"
    }
    
    var isCurrentPeriod: Bool {
        let now = Date()
        return startDate <= now && now <= endDate
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case year
        case periodNumber = "period_number"
        case startDate = "start_date"
        case endDate = "end_date"
        case status
        case weekNumber = "week_number"
    }
    
    // Mock data removed - use real API data only
}

enum PayrollPeriodStatus: String, Codable, CaseIterable {
    case upcoming = "upcoming"
    case active = "active"
    case completed = "completed"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .active: return "Active"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }
    
    var color: Color {
        switch self {
        case .upcoming: return .ksrInfo
        case .active: return .ksrSuccess
        case .completed: return .ksrPrimary
        case .archived: return .ksrSecondary
        }
    }
}

// MARK: - Work Entry (Basic)
struct WorkEntry: Codable, Identifiable {
    let id: Int
    let employeeId: Int
    let projectId: Int
    let taskId: Int
    let startTime: Date
    let endTime: Date
    let hours: Double
    let hourlyRate: Decimal
    let amount: Decimal
    let notes: String?
    let status: WorkEntryStatus
    
    private enum CodingKeys: String, CodingKey {
        case id
        case employeeId = "employee_id"
        case projectId = "project_id"
        case taskId = "task_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case hours
        case hourlyRate = "hourly_rate"
        case amount
        case notes
        case status
    }
}

enum WorkEntryStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case submitted = "submitted"
    case approved = "approved"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .submitted: return "Submitted"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
    
    var color: Color {
        switch self {
        case .draft: return .ksrSecondary
        case .submitted: return .ksrWarning
        case .approved: return .ksrSuccess
        case .rejected: return .ksrError
        }
    }
}

// MARK: - Work Entry for Review
struct WorkEntryForReview: Identifiable {
    let id: Int
    let employee: Employee  // 🔧 FIXED: Use Employee from ProjectModels
    let project: Project    // 🔧 FIXED: Use Project from ProjectModels
    let task: ProjectTask   // 🔧 FIXED: Use ProjectTask from ProjectModels
    let workEntries: [WorkEntry]
    let totalHours: Double
    let totalAmount: Decimal
    let supervisorConfirmation: SupervisorConfirmation
    let periodCoverage: DateInterval
    let status: WorkEntryReviewStatus
    
    var displayDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: periodCoverage.start)) - \(formatter.string(from: periodCoverage.end))"
    }
}

// Custom Codable implementation for WorkEntryForReview
extension WorkEntryForReview: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case employee
        case project
        case task
        case workEntries = "work_entries"
        case totalHours = "total_hours"
        case totalAmount = "total_amount"
        case supervisorConfirmation = "supervisor_confirmation"
        case periodCoverage = "period_coverage"
        case status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        employee = try container.decode(Employee.self, forKey: .employee)
        project = try container.decode(Project.self, forKey: .project)
        task = try container.decode(ProjectTask.self, forKey: .task)
        workEntries = try container.decode([WorkEntry].self, forKey: .workEntries)
        totalHours = try container.decode(Double.self, forKey: .totalHours)
        totalAmount = try container.decode(Decimal.self, forKey: .totalAmount)
        supervisorConfirmation = try container.decode(SupervisorConfirmation.self, forKey: .supervisorConfirmation)
        status = try container.decode(WorkEntryReviewStatus.self, forKey: .status)
        
        // Handle DateInterval encoding/decoding
        let periodData = try container.decode([String: Date].self, forKey: .periodCoverage)
        guard let start = periodData["start"], let end = periodData["end"] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [CodingKeys.periodCoverage], debugDescription: "Missing start or end date")
            )
        }
        periodCoverage = DateInterval(start: start, end: end)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(employee, forKey: .employee)
        try container.encode(project, forKey: .project)
        try container.encode(task, forKey: .task)
        try container.encode(workEntries, forKey: .workEntries)
        try container.encode(totalHours, forKey: .totalHours)
        try container.encode(totalAmount, forKey: .totalAmount)
        try container.encode(supervisorConfirmation, forKey: .supervisorConfirmation)
        try container.encode(status, forKey: .status)
        
        // Handle DateInterval encoding
        let periodData = [
            "start": periodCoverage.start,
            "end": periodCoverage.end
        ]
        try container.encode(periodData, forKey: .periodCoverage)
    }
}

enum WorkEntryReviewStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case inReview = "in_review"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .inReview: return "In Review"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .ksrWarning
        case .approved: return .ksrSuccess
        case .rejected: return .ksrError
        case .inReview: return .ksrInfo
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.badge.exclamationmark"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .inReview: return "eye.circle.fill"
        }
    }
}

// MARK: - Supervisor Confirmation
struct SupervisorConfirmation: Codable {
    let supervisorId: Int
    let supervisorName: String
    let confirmedAt: Date
    let notes: String?
    let digitalSignature: String?
    
    private enum CodingKeys: String, CodingKey {
        case supervisorId = "supervisor_id"
        case supervisorName = "supervisor_name"
        case confirmedAt = "confirmed_at"
        case notes
        case digitalSignature = "digital_signature"
    }
}

// MARK: - Payroll Batch
struct PayrollBatch: Codable, Identifiable {
    let id: Int
    let batchNumber: String
    let periodStart: Date
    let periodEnd: Date
    let year: Int
    let periodNumber: Int
    let totalEmployees: Int
    let totalHours: Double
    let totalAmount: Decimal
    let status: PayrollBatchStatus
    let createdBy: Int
    let createdAt: Date
    let approvedBy: Int?
    let approvedAt: Date?
    let sentToZenegyAt: Date?
    let zenegySyncStatus: ZenegySyncStatus?
    let notes: String?
    
    var displayPeriod: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: periodStart)) - \(formatter.string(from: periodEnd))"
    }
    
    var canBeApproved: Bool {
        return status == .readyForApproval
    }
    
    var canBeSentToZenegy: Bool {
        return status == .approved
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case batchNumber = "batch_number"
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case year
        case periodNumber = "period_number"
        case totalEmployees = "total_employees"
        case totalHours = "total_hours"
        case totalAmount = "total_amount"
        case status
        case createdBy = "created_by"
        case createdAt = "created_at"
        case approvedBy = "approved_by"
        case approvedAt = "approved_at"
        case sentToZenegyAt = "sent_to_zenegy_at"
        case zenegySyncStatus = "zenegy_sync_status"
        case notes
    }
}

enum PayrollBatchStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case readyForApproval = "ready_for_approval"
    case approved = "approved"
    case sentToZenegy = "sent_to_zenegy"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .readyForApproval: return "Ready for Approval"
        case .approved: return "Approved"
        case .sentToZenegy: return "Sent to Zenegy"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .draft: return .ksrSecondary
        case .readyForApproval: return .ksrWarning
        case .approved: return .ksrSuccess
        case .sentToZenegy: return .ksrInfo
        case .completed: return .ksrSuccess
        case .failed: return .ksrError
        case .cancelled: return .ksrSecondary
        }
    }
    
    var icon: String {
        switch self {
        case .draft: return "doc.text"
        case .readyForApproval: return "checkmark.circle"
        case .approved: return "checkmark.circle.fill"
        case .sentToZenegy: return "paperplane"
        case .completed: return "checkmark.seal.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Batch Stats
struct BatchStats: Codable {
    let totalBatches: Int
    let draftBatches: Int
    let pendingApprovalBatches: Int
    let approvedBatches: Int
    let completedBatches: Int
    let failedBatches: Int
    let totalAmount: Decimal
    let avgProcessingTime: Double
    
    private enum CodingKeys: String, CodingKey {
        case totalBatches = "total_batches"
        case draftBatches = "draft_batches"
        case pendingApprovalBatches = "pending_approval_batches"
        case approvedBatches = "approved_batches"
        case completedBatches = "completed_batches"
        case failedBatches = "failed_batches"
        case totalAmount = "total_amount"
        case avgProcessingTime = "avg_processing_time"
    }
    
    // Mock data removed - use real API data only
}

// MARK: - Batch Status Filter
enum BatchStatusFilter: CaseIterable {
    case all
    case draft
    case pending
    case approved
    case completed
    case failed
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .draft: return "Draft"
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
    
    func matches(_ status: PayrollBatchStatus) -> Bool {
        switch self {
        case .all: return true
        case .draft: return status == .draft
        case .pending: return status == .readyForApproval
        case .approved: return status == .approved || status == .sentToZenegy
        case .completed: return status == .completed
        case .failed: return status == .failed
        }
    }
}

// MARK: - Zenegy Integration (zgodne z schema.prisma)
enum ZenegySyncStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case syncing = "syncing"
    case sent = "sent"
    case failed = "failed"
    case skipped = "skipped"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .syncing: return "Syncing"
        case .sent: return "Sent"
        case .failed: return "Failed"
        case .skipped: return "Skipped"
        case .completed: return "Completed"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .ksrWarning
        case .syncing: return .ksrInfo
        case .sent: return .ksrSuccess
        case .failed: return .ksrError
        case .skipped: return .ksrSecondary
        case .completed: return .ksrSuccess
        }
    }
    
    var isInProgress: Bool {
        return self == .syncing
    }
}

struct ZenegySyncResult: Codable {
    let success: Bool
    let zenegeBatchId: String?
    let syncedAt: Date
    let errorMessage: String?
    let syncDetails: ZenegySyncDetails?
    
    private enum CodingKeys: String, CodingKey {
        case success
        case zenegeBatchId = "zenegy_batch_id"
        case syncedAt = "synced_at"
        case errorMessage = "error_message"
        case syncDetails = "sync_details"
    }
}

struct ZenegySyncDetails: Codable {
    let employeesSynced: Int
    let totalAmount: Decimal
    let processingTimeMs: Int
    let warnings: [String]?
    
    private enum CodingKeys: String, CodingKey {
        case employeesSynced = "employees_synced"
        case totalAmount = "total_amount"
        case processingTimeMs = "processing_time_ms"
        case warnings
    }
}

// MARK: - Pending Items (UPDATED TO BE CODABLE)
struct PayrollPendingItem: Identifiable, Codable {
    let id: String // Using String for Identifiable protocol, but handling numeric IDs from API
    let title: String
    let subtitle: String
    let priority: PendingItemPriority
    let timeAgo: String
    let requiresAction: Bool
    let icon: String
    let relatedId: Int?
    let type: PendingItemType
    
    // Custom initializer for backward compatibility with existing code
    init(title: String, subtitle: String, priority: PendingItemPriority, timeAgo: String, requiresAction: Bool, icon: String, relatedId: Int?, type: PendingItemType) {
        self.id = UUID().uuidString
        self.title = title
        self.subtitle = subtitle
        self.priority = priority
        self.timeAgo = timeAgo
        self.requiresAction = requiresAction
        self.icon = icon
        self.relatedId = relatedId
        self.type = type
    }
    
    // Custom decoder to handle numeric IDs from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as either String or Int
        if let stringId = try? container.decode(String.self, forKey: .id) {
            self.id = stringId
        } else if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = UUID().uuidString
        }
        
        self.title = try container.decode(String.self, forKey: .title)
        self.subtitle = try container.decode(String.self, forKey: .subtitle)
        self.priority = try container.decode(PendingItemPriority.self, forKey: .priority)
        self.timeAgo = try container.decode(String.self, forKey: .timeAgo)
        self.requiresAction = try container.decode(Bool.self, forKey: .requiresAction)
        self.icon = try container.decode(String.self, forKey: .icon)
        self.relatedId = try container.decodeIfPresent(Int.self, forKey: .relatedId)
        self.type = try container.decode(PendingItemType.self, forKey: .type)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case priority
        case timeAgo = "time_ago"
        case requiresAction = "requires_action"
        case icon
        case relatedId = "related_id"
        case type
    }
}

enum PendingItemPriority: String, CaseIterable, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var color: Color {
        switch self {
        case .high: return .ksrError
        case .medium: return .ksrWarning
        case .low: return .ksrInfo
        }
    }
}

enum PendingItemType: String, CaseIterable, Codable {
    case hoursReview = "hours_review"
    case batchApproval = "batch_approval"
    case batchCreation = "batch_creation"
    case zenegySyncFailed = "zenegy_sync_failed"
    case periodDeadline = "period_deadline"
    
    var icon: String {
        switch self {
        case .hoursReview: return "clock.badge.exclamationmark"
        case .batchApproval: return "checkmark.circle"
        case .batchCreation: return "plus.rectangle.on.folder"
        case .zenegySyncFailed: return "exclamationmark.triangle"
        case .periodDeadline: return "calendar.badge.exclamationmark"
        }
    }
}

// MARK: - Activity (UPDATED TO BE CODABLE)
struct PayrollActivity: Identifiable, Codable {
    let id: String // Using String for Identifiable protocol, but handling numeric IDs from API
    let title: String
    let description: String
    let timestamp: Date
    let type: PayrollActivityType
    let relatedId: Int?
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    // Custom initializer for backward compatibility with existing code
    init(title: String, description: String, timestamp: Date, type: PayrollActivityType, relatedId: Int?) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.type = type
        self.relatedId = relatedId
    }
    
    // Custom decoder to handle numeric IDs from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as either String or Int
        if let stringId = try? container.decode(String.self, forKey: .id) {
            self.id = stringId
        } else if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = UUID().uuidString
        }
        
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.type = try container.decode(PayrollActivityType.self, forKey: .type)
        self.relatedId = try container.decodeIfPresent(Int.self, forKey: .relatedId)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case timestamp
        case type
        case relatedId = "related_id"
    }
}

enum PayrollActivityType: String, CaseIterable, Codable {
    case hoursApproved = "hours_approved"
    case batchCreated = "batch_created"
    case batchApproved = "batch_approved"
    case zenegySyncCompleted = "zenegy_sync_completed"
    case zenegySyncFailed = "zenegy_sync_failed"
    case periodClosed = "period_closed"
    case systemReady = "system_ready"
    
    var icon: String {
        switch self {
        case .hoursApproved: return "checkmark.circle.fill"
        case .batchCreated: return "plus.rectangle.on.folder"
        case .batchApproved: return "checkmark.seal.fill"
        case .zenegySyncCompleted: return "checkmark.icloud.fill"
        case .zenegySyncFailed: return "exclamationmark.icloud.fill"
        case .periodClosed: return "calendar.circle.fill"
        case .systemReady: return "checkmark.shield.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .hoursApproved: return .ksrSuccess
        case .batchCreated: return .ksrInfo
        case .batchApproved: return .ksrSuccess
        case .zenegySyncCompleted: return .ksrSuccess
        case .zenegySyncFailed: return .ksrError
        case .periodClosed: return .ksrPrimary
        case .systemReady: return .ksrSuccess
        }
    }
}

// MARK: - Request/Response Models
struct CreatePayrollBatchRequest: Codable {
    let periodStart: Date
    let periodEnd: Date
    let workEntryIds: [Int]
    let notes: String?
    let batchNumber: String?
    let isDraft: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case workEntryIds = "work_entry_ids"
        case notes
        case batchNumber = "batch_number"
        case isDraft = "is_draft"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Try using ISO8601 format that server expects
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        let startDateString = isoFormatter.string(from: periodStart)
        let endDateString = isoFormatter.string(from: periodEnd)
        
        #if DEBUG
        print("[CreatePayrollBatchRequest] Encoding dates - Start: \(startDateString), End: \(endDateString)")
        print("[CreatePayrollBatchRequest] Work entry IDs: \(workEntryIds)")
        #endif
        
        try container.encode(startDateString, forKey: .periodStart)
        try container.encode(endDateString, forKey: .periodEnd)
        try container.encode(workEntryIds, forKey: .workEntryIds)
        
        // Only include optional fields if they have values
        if let notes = notes, !notes.isEmpty {
            try container.encode(notes, forKey: .notes)
        }
        if let batchNumber = batchNumber, !batchNumber.isEmpty {
            try container.encode(batchNumber, forKey: .batchNumber)
        }
        if let isDraft = isDraft {
            try container.encode(isDraft, forKey: .isDraft)
        }
    }
}

struct BulkWorkEntryApprovalRequest: Codable {
    let workEntryIds: [Int]
    let action: WorkEntryAction
    let notes: String?
    
    private enum CodingKeys: String, CodingKey {
        case workEntryIds = "work_entry_ids"
        case action
        case notes
    }
}

enum WorkEntryAction: String, Codable {
    case approve = "approve"
    case reject = "reject"
    case requestChanges = "request_changes"
}

struct BulkOperationResult: Codable {
    let successful: [Int]
    let failed: [FailedOperation]
    let totalRequested: Int
    
    var successRate: Double {
        guard totalRequested > 0 else { return 0.0 }
        return Double(successful.count) / Double(totalRequested)
    }
    
    var isFullySuccessful: Bool {
        return failed.isEmpty && successful.count == totalRequested
    }
}

struct FailedOperation: Codable {
    let id: Int
    let error: String
}

// MARK: - Extensions for Currency Formatting
extension Decimal {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "DKK"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: self as NSDecimalNumber) ?? "0 kr"
    }
    
    var shortCurrencyFormatted: String {
        let value = (self as NSDecimalNumber).doubleValue
        if value >= 1000000 {
            return String(format: "%.1fM kr", value / 1000000)
        } else if value >= 1000 {
            return String(format: "%.0fK kr", value / 1000)
        } else {
            return currencyFormatted
        }
    }
}

// MARK: - Mock Data Extensions
// Mock data extensions removed - use real API data only

// Mock data extensions removed - use real API data only
