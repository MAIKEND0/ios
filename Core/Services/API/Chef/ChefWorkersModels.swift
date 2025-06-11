//
//  ChefWorkersModels.swift
//  KSR Cranes App
//  Data models for Chef workers management
//

import Foundation
import SwiftUI

// MARK: - Worker Status Enum

enum WorkerStatus: String, CaseIterable, Codable {
    case aktiv = "aktiv"
    case inaktiv = "inaktiv"
    case sygemeldt = "sygemeldt"
    case ferie = "ferie"
    case opsagt = "opsagt"
    
    var displayName: String {
        switch self {
        case .aktiv: return "Active"
        case .inaktiv: return "Inactive"
        case .sygemeldt: return "Sick Leave"
        case .ferie: return "Vacation"
        case .opsagt: return "Terminated"
        }
    }
    
    var color: Color {
        switch self {
        case .aktiv: return .ksrSuccess
        case .inaktiv: return .ksrSecondary
        case .sygemeldt: return .ksrError
        case .ferie: return .ksrWarning
        case .opsagt: return .ksrDarkGray
        }
    }
    
    var systemImage: String {
        switch self {
        case .aktiv: return "checkmark.circle.fill"
        case .inaktiv: return "pause.circle"
        case .sygemeldt: return "cross.circle.fill"
        case .ferie: return "sun.max.fill"
        case .opsagt: return "xmark.circle.fill"
        }
    }
}

// MARK: - Employment Type Enum

enum EmploymentType: String, CaseIterable, Codable {
    case fuld_tid = "fuld_tid"
    case deltid = "deltid"
    case timebaseret = "timebaseret"
    case freelancer = "freelancer"
    case praktikant = "praktikant"
    
    var displayName: String {
        switch self {
        case .fuld_tid: return "Full-time"
        case .deltid: return "Part-time"
        case .timebaseret: return "Hourly"
        case .freelancer: return "Freelancer"
        case .praktikant: return "Intern"
        }
    }
    
    var shortName: String {
        switch self {
        case .fuld_tid: return "FT"
        case .deltid: return "PT"
        case .timebaseret: return "HR"
        case .freelancer: return "FL"
        case .praktikant: return "IN"
        }
    }
}

// MARK: - Worker Role Enum

enum WorkerRole: String, CaseIterable, Codable {
    case arbejder = "arbejder"
    case byggeleder = "byggeleder"
    
    var displayName: String {
        switch self {
        case .arbejder: return "Worker"
        case .byggeleder: return "Site Manager"
        }
    }
    
    var danishName: String {
        switch self {
        case .arbejder: return "Arbejder"
        case .byggeleder: return "Byggeleder"
        }
    }
    
    var systemImage: String {
        switch self {
        case .arbejder: return "hammer.fill"
        case .byggeleder: return "person.badge.key.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .arbejder: return .ksrPrimary
        case .byggeleder: return .ksrWarning
        }
    }
}

// MARK: - Main Worker Model for Chef View

struct WorkerForChef: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let phone: String?
    let address: String?
    let hourly_rate: Double
    let employment_type: EmploymentType
    let role: WorkerRole
    let status: WorkerStatus
    let profile_picture_url: String?
    let created_at: Date
    let last_active: Date?
    
    // Stats included when requested
    let stats: WorkerQuickStats?
    
    // Certificates included when requested
    let certificates: [WorkerCertificate]?
    
    // Default initializer for manual creation (previews, testing, etc.)
    init(
        id: Int,
        name: String,
        email: String,
        phone: String? = nil,
        address: String? = nil,
        hourly_rate: Double,
        employment_type: EmploymentType,
        role: WorkerRole,
        status: WorkerStatus,
        profile_picture_url: String? = nil,
        created_at: Date,
        last_active: Date? = nil,
        stats: WorkerQuickStats? = nil,
        certificates: [WorkerCertificate]? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.hourly_rate = hourly_rate
        self.employment_type = employment_type
        self.role = role
        self.status = status
        self.profile_picture_url = profile_picture_url
        self.created_at = created_at
        self.last_active = last_active
        self.stats = stats
        self.certificates = certificates
    }
    
    // Custom decoder to handle missing role field
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        hourly_rate = try container.decode(Double.self, forKey: .hourly_rate)
        employment_type = try container.decode(EmploymentType.self, forKey: .employment_type)
        
        // Default role to "arbejder" if not provided by server
        role = try container.decodeIfPresent(WorkerRole.self, forKey: .role) ?? .arbejder
        
        status = try container.decode(WorkerStatus.self, forKey: .status)
        profile_picture_url = try container.decodeIfPresent(String.self, forKey: .profile_picture_url)
        created_at = try container.decode(Date.self, forKey: .created_at)
        last_active = try container.decodeIfPresent(Date.self, forKey: .last_active)
        stats = try container.decodeIfPresent(WorkerQuickStats.self, forKey: .stats)
        certificates = try container.decodeIfPresent([WorkerCertificate].self, forKey: .certificates)
    }
    
    // Computed properties
    var initials: String {
        let components = name.components(separatedBy: " ")
        return components.compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
    
    var isActive: Bool {
        return status == .aktiv
    }
    
    var statusDisplayName: String {
        return status.displayName
    }
    
    var employmentDisplayName: String {
        return employment_type.displayName
    }
    
    var roleDisplayName: String {
        return role.displayName
    }
    
    var roleDanishName: String {
        return role.danishName
    }
    
    // Coding keys to match API
    enum CodingKeys: String, CodingKey {
        case id = "employee_id"
        case name, email, phone, address
        case hourly_rate, employment_type, role, status
        case profile_picture_url, created_at, last_active
        case stats, certificates
    }
}

// MARK: - Worker Quick Stats

struct WorkerQuickStats: Codable {
    let hours_this_week: Double?
    let hours_this_month: Double?
    let active_tasks: Int?
    let completed_tasks: Int?
    let total_tasks: Int?
    let approval_rate: Double?
    let last_timesheet_date: Date?
    
    var hoursThisWeekFormatted: String {
        return String(format: "%.1f", hours_this_week ?? 0)
    }
    
    var approvalRatePercentage: Int {
        return Int((approval_rate ?? 0) * 100)
    }
    
    var activeTasksFormatted: String {
        return "\(active_tasks ?? 0)"
    }
    
    var completedTasksFormatted: String {
        return "\(completed_tasks ?? 0)"
    }
    
    var taskCompletionRate: Double {
        guard let total = total_tasks, total > 0,
              let completed = completed_tasks else { return 0 }
        return Double(completed) / Double(total)
    }
}

// MARK: - Detailed Worker Model

struct WorkerDetailForChef: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let phone: String?
    let address: String?
    let hourly_rate: Double
    let employment_type: EmploymentType
    let role: WorkerRole
    let status: WorkerStatus
    let profile_picture_url: String?
    let created_at: Date
    let last_active: Date?
    let hire_date: Date?
    let notes: String?
    
    // Detailed stats
    let detailed_stats: WorkerDetailedStats?
    
    // Current assignments
    let current_assignments: [WorkerAssignment]
    
    // Recent activity
    let recent_activity: [WorkerActivity]
    
    // Rates history
    let rates_history: [WorkerRateHistory]
    
    enum CodingKeys: String, CodingKey {
        case id = "employee_id"
        case name, email, phone, address
        case hourly_rate, employment_type, role, status
        case profile_picture_url, created_at, last_active
        case hire_date, notes
        case detailed_stats, current_assignments
        case recent_activity, rates_history
    }
}

// MARK: - Worker Detailed Stats

struct WorkerDetailedStats: Codable {
    let total_hours: Double
    let hours_this_week: Double
    let hours_this_month: Double
    let hours_this_year: Double
    let active_projects: Int
    let completed_projects: Int
    let total_tasks: Int
    let completed_tasks: Int
    let approval_rate: Double
    let average_rating: Double
    let total_earnings: Double
    let last_timesheet_date: Date?
    let efficiency_score: Double
}

// MARK: - Worker Assignment

struct WorkerAssignment: Codable, Identifiable {
    let id: Int
    let project_id: Int
    let project_title: String
    let customer_name: String
    let role: String
    let start_date: Date
    let end_date: Date?
    let status: String
    let hourly_rate: Double
    
    var isActive: Bool {
        return status == "aktiv"
    }
    
    var durationText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        if let endDate = end_date {
            return "\(formatter.string(from: start_date)) - \(formatter.string(from: endDate))"
        } else {
            return "Since \(formatter.string(from: start_date))"
        }
    }
}

// MARK: - Worker Activity

struct WorkerActivity: Codable, Identifiable {
    let id: Int
    let type: String
    let description: String
    let timestamp: Date
    let project_title: String?
    let metadata: [String: String]?
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var activityIcon: String {
        switch type {
        case "timesheet_submitted": return "clock.fill"
        case "task_completed": return "checkmark.circle.fill"
        case "project_assigned": return "folder.badge.plus"
        case "rate_updated": return "dollarsign.circle.fill"
        case "status_changed": return "person.circle.fill"
        default: return "info.circle.fill"
        }
    }
}

// MARK: - Worker Rate Models

struct WorkerRate: Codable, Identifiable {
    let id: Int
    let worker_id: Int
    let rate_type: String
    let rate_amount: Double
    let effective_date: Date
    let end_date: Date?
    let is_active: Bool
    let created_at: Date
    
    var rateTypeDisplayName: String {
        switch rate_type {
        case "hourly": return "Hourly Rate"
        case "overtime": return "Overtime Rate"
        case "weekend": return "Weekend Rate"
        case "holiday": return "Holiday Rate"
        default: return rate_type.capitalized
        }
    }
    
    var formattedAmount: String {
        return String(format: "%.0f DKK", rate_amount)
    }
}

struct WorkerRateHistory: Codable, Identifiable {
    let id: Int
    let old_rate: Double
    let new_rate: Double
    let change_date: Date
    let reason: String?
    let changed_by: String
    
    var changeAmount: Double {
        return new_rate - old_rate
    }
    
    var changePercentage: Double {
        guard old_rate > 0 else { return 0 }
        return (changeAmount / old_rate) * 100
    }
    
    var formattedChange: String {
        let sign = changeAmount >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", changeAmount)) DKK"
    }
}

// MARK: - Request Models

struct CreateWorkerRequest: Codable {
    let name: String
    let email: String
    let phone: String?
    let address: String?
    let hourly_rate: Double
    let employment_type: String
    let role: String
    let status: String
    let hire_date: Date?
    let notes: String?
    
    init(
        name: String,
        email: String,
        phone: String? = nil,
        address: String? = nil,
        hourly_rate: Double,
        employment_type: String,
        role: String = "arbejder",
        status: String = "aktiv",
        hire_date: Date? = nil,
        notes: String? = nil
    ) {
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.hourly_rate = hourly_rate
        self.employment_type = employment_type
        self.role = role
        self.status = status
        self.hire_date = hire_date
        self.notes = notes
    }
}

struct UpdateWorkerRequest: Codable {
    let name: String?
    let email: String?
    let phone: String?
    let address: String?
    let hourly_rate: Double?
    let employment_type: String?
    let role: String?
    let status: String?
    let notes: String?
}

struct UpdateWorkerStatusRequest: Codable {
    let status: String
}

struct UpdateWorkerRateRequest: Codable {
    let rate_type: String
    let rate_amount: Double
    let effective_date: Date
    let reason: String?
}

// MARK: - Response Models

struct DeleteWorkerResponse: Codable {
    let success: Bool
    let message: String
    let worker_id: Int?
}

struct WorkerProfileImageUploadResponse: Codable {
    let success: Bool
    let message: String
    let profile_picture_url: String?
}

struct WorkerSearchResponse: Codable {
    let workers: [WorkerForChef]
    let total_count: Int
    let page: Int
    let limit: Int
    let has_more: Bool
}

// MARK: - Search Request Models

struct AdvancedWorkerSearchRequest: Codable {
    let query: String?
    let status: [String]?
    let employment_type: [String]?
    let role: [String]?
    let min_hourly_rate: Double?
    let max_hourly_rate: Double?
    let hired_after: Date?
    let hired_before: Date?
    let has_active_assignments: Bool?
    let limit: Int
    let offset: Int
    
    init(
        query: String? = nil,
        status: [String]? = nil,
        employment_type: [String]? = nil,
        role: [String]? = nil,
        min_hourly_rate: Double? = nil,
        max_hourly_rate: Double? = nil,
        hired_after: Date? = nil,
        hired_before: Date? = nil,
        has_active_assignments: Bool? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) {
        self.query = query
        self.status = status
        self.employment_type = employment_type
        self.role = role
        self.min_hourly_rate = min_hourly_rate
        self.max_hourly_rate = max_hourly_rate
        self.hired_after = hired_after
        self.hired_before = hired_before
        self.has_active_assignments = has_active_assignments
        self.limit = limit
        self.offset = offset
    }
}

// MARK: - Stats Models

struct WorkerStatsForChef: Codable {
    let worker_id: Int
    let period_start: Date
    let period_end: Date
    let total_hours: Double
    let billable_hours: Double
    let overtime_hours: Double
    let projects_worked: Int
    let tasks_completed: Int
    let average_daily_hours: Double
    let efficiency_rating: Double
    let total_earnings: Double
}

struct WorkersOverallStats: Codable {
    let total_workers: Int
    let active_workers: Int
    let inactive_workers: Int
    let total_hours_this_month: Double
    let total_earnings_this_month: Double
    let average_hourly_rate: Double
    let top_performers: [TopPerformerStat]
    let employment_type_breakdown: [EmploymentTypeBreakdown]
    let status_breakdown: [StatusBreakdown]
    let recent_hires: [RecentHire]
}

struct TopPerformerStat: Codable, Identifiable {
    let id: Int
    let name: String
    let hours_this_month: Double
    let efficiency_rating: Double
    let projects_completed: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "worker_id"
        case name, hours_this_month, efficiency_rating, projects_completed
    }
}

struct EmploymentTypeBreakdown: Codable {
    let employment_type: String
    let count: Int
    let percentage: Double
    
    var displayName: String {
        return EmploymentType(rawValue: employment_type)?.displayName ?? employment_type
    }
}

struct StatusBreakdown: Codable {
    let status: String
    let count: Int
    let percentage: Double
    
    var displayName: String {
        return WorkerStatus(rawValue: status)?.displayName ?? status
    }
}

struct RecentHire: Codable, Identifiable {
    let id: Int
    let name: String
    let hire_date: Date
    let employment_type: String
    let days_since_hire: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "worker_id"
        case name, hire_date, employment_type, days_since_hire
    }
}

