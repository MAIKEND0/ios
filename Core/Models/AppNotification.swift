//
//  AppNotification.swift
//  KSR Cranes App
//
//  Created by System on 26/05/2025.
//

import Foundation

// ========== GŁÓWNY MODEL POWIADOMIENIA ==========

struct AppNotification: Codable, Identifiable {
    let id: Int
    let employeeId: Int
    let type: NotificationType
    let title: String?  // FIXED: Made optional to handle null values from API
    let message: String
    let isRead: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // Opcjonalne pola z bazy danych
    let workEntryId: Int?  // ✅ POPRAWKA: entry_id → work_entry_id
    let taskId: Int?
    let projectId: Int?
    
    // Dodatkowe pola obliczane lub pobierane z relacji
    let projectTitle: String?
    
    // ✅ NOWE POLA z bazy danych
    let priority: NotificationPriority?
    let category: NotificationCategory?
    let actionRequired: Bool?
    let actionUrl: String?
    let expiresAt: Date?
    let readAt: Date?
    let senderId: Int?
    let targetEmployeeId: Int?
    let targetRole: String?
    let metadata: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "notification_id"
        case employeeId = "employee_id"
        case type = "notification_type"
        case title
        case message
        case isRead = "is_read"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case workEntryId = "work_entry_id"  // ✅ POPRAWKA
        case taskId = "task_id"
        case projectId = "project_id"
        case projectTitle = "project_title"
        case priority
        case category
        case actionRequired = "action_required"
        case actionUrl = "action_url"
        case expiresAt = "expires_at"
        case readAt = "read_at"
        case senderId = "sender_id"
        case targetEmployeeId = "target_employee_id"
        case targetRole = "target_role"
        case metadata
    }
    
    // Manual memberwise initializer for mock data
    init(
        id: Int,
        employeeId: Int,
        type: NotificationType,
        title: String?,
        message: String,
        isRead: Bool,
        createdAt: Date,
        updatedAt: Date,
        workEntryId: Int?,
        taskId: Int?,
        projectId: Int?,
        projectTitle: String?,
        priority: NotificationPriority?,
        category: NotificationCategory?,
        actionRequired: Bool?,
        actionUrl: String?,
        expiresAt: Date?,
        readAt: Date?,
        senderId: Int?,
        targetEmployeeId: Int?,
        targetRole: String?,
        metadata: String?
    ) {
        self.id = id
        self.employeeId = employeeId
        self.type = type
        self.title = title
        self.message = message
        self.isRead = isRead
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.workEntryId = workEntryId
        self.taskId = taskId
        self.projectId = projectId
        self.projectTitle = projectTitle
        self.priority = priority
        self.category = category
        self.actionRequired = actionRequired
        self.actionUrl = actionUrl
        self.expiresAt = expiresAt
        self.readAt = readAt
        self.senderId = senderId
        self.targetEmployeeId = targetEmployeeId
        self.targetRole = targetRole
        self.metadata = metadata
    }
    
    // Custom decoder to handle metadata as both string and dictionary
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        employeeId = try container.decode(Int.self, forKey: .employeeId)
        type = try container.decode(NotificationType.self, forKey: .type)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        isRead = try container.decode(Bool.self, forKey: .isRead)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        workEntryId = try container.decodeIfPresent(Int.self, forKey: .workEntryId)
        taskId = try container.decodeIfPresent(Int.self, forKey: .taskId)
        projectId = try container.decodeIfPresent(Int.self, forKey: .projectId)
        projectTitle = try container.decodeIfPresent(String.self, forKey: .projectTitle)
        priority = try container.decodeIfPresent(NotificationPriority.self, forKey: .priority)
        category = try container.decodeIfPresent(NotificationCategory.self, forKey: .category)
        actionRequired = try container.decodeIfPresent(Bool.self, forKey: .actionRequired)
        actionUrl = try container.decodeIfPresent(String.self, forKey: .actionUrl)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        readAt = try container.decodeIfPresent(Date.self, forKey: .readAt)
        senderId = try container.decodeIfPresent(Int.self, forKey: .senderId)
        targetEmployeeId = try container.decodeIfPresent(Int.self, forKey: .targetEmployeeId)
        targetRole = try container.decodeIfPresent(String.self, forKey: .targetRole)
        
        // Handle metadata as string or skip if it's a dictionary
        if let metadataString = try? container.decodeIfPresent(String.self, forKey: .metadata) {
            metadata = metadataString
        } else {
            // If metadata is not a string (e.g., dictionary), set to nil for now
            metadata = nil
        }
    }
    
    // ========== COMPUTED PROPERTIES ==========
    
    /// Display title with fallback to type name when title is null
    var displayTitle: String {
        return title ?? type.displayName
    }
    
    /// Formatowana data powiadomienia
    var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        // Sprawdź czy to dzisiaj
        if calendar.isDate(createdAt, inSameDayAs: Date()) {
            formatter.timeStyle = .short
            return "Today \(formatter.string(from: createdAt))"
        }
        
        // Sprawdź czy to wczoraj
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()),
           calendar.isDate(createdAt, inSameDayAs: yesterday) {
            formatter.timeStyle = .short
            return "Yesterday \(formatter.string(from: createdAt))"
        }
        
        // Inne daty
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    /// Relative time (np. "2 hours ago")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    /// Ikona powiadomienia w zależności od typu
    var iconName: String {
        switch type {
        case .hoursSubmitted:
            return "clock.badge.checkmark"
        case .hoursConfirmed, .hoursApproved:
            return "checkmark.circle.fill"
        case .hoursRejected:
            return "xmark.circle.fill"
        case .taskAssigned:
            return "briefcase.badge.plus"
        case .projectCreated, .projectAssigned, .projectActivated:
            return "folder.badge.gearshape"
        case .emergencyAlert:
            return "exclamationmark.triangle.fill"
        case .licenseExpiring, .licenseExpired:
            return "doc.badge.exclamationmark"
        case .payrollProcessed, .payrollReady:
            return "banknote.fill"
        case .leaveRequestSubmitted:
            return "calendar.badge.plus"
        case .leaveRequestApproved:
            return "calendar.badge.checkmark"
        case .leaveRequestRejected:
            return "calendar.badge.exclamationmark"
        case .leaveRequestCancelled:
            return "calendar.badge.minus"
        case .leaveBalanceUpdated:
            return "calendar.circle.fill"
        case .leaveStarting, .leaveEnding:
            return "calendar"
        case .generalInfo, .generalAnnouncement:
            return "info.circle.fill"
        default:
            return "bell.fill"
        }
    }
    
    /// Kolor ikony powiadomienia
    var iconColor: String {
        // Sprawdź najpierw priority
        if let priority = priority {
            switch priority {
            case .urgent:
                return "red"
            case .high:
                return "orange"
            case .normal:
                return "blue"
            case .low:
                return "gray"
            }
        }
        
        // Fallback na typ powiadomienia
        switch type {
        case .hoursSubmitted:
            return "blue"
        case .hoursConfirmed, .hoursApproved:
            return "green"
        case .hoursRejected, .emergencyAlert:
            return "red"
        case .taskAssigned:
            return "purple"
        case .projectCreated, .projectAssigned, .projectActivated:
            return "orange"
        case .payrollProcessed, .payrollReady:
            return "green"
        case .licenseExpiring, .licenseExpired:
            return "orange"
        case .leaveRequestSubmitted:
            return "blue"
        case .leaveRequestApproved:
            return "green"
        case .leaveRequestRejected:
            return "red"
        case .leaveRequestCancelled:
            return "gray"
        case .leaveBalanceUpdated:
            return "purple"
        case .leaveStarting, .leaveEnding:
            return "orange"
        default:
            return "blue"
        }
    }
    
    /// Czy powiadomienie wymaga akcji
    var requiresAction: Bool {
        if let actionRequired = actionRequired {
            return actionRequired
        }
        
        // Fallback logic
        switch type {
        case .hoursRejected:
            return true
        case .hoursSubmitted:
            return true
        case .taskAssigned:
            return true
        case .licenseExpiring:
            return true
        case .leaveRequestSubmitted:
            return true
        case .leaveRequestRejected:
            return true
        default:
            return false
        }
    }
    
    /// Krótki opis akcji do wykonania
    var actionText: String? {
        switch type {
        case .hoursRejected:
            return "Correct entry"
        case .hoursSubmitted:
            return "Review & approve"
        case .taskAssigned:
            return "View task"
        case .licenseExpiring:
            return "Renew license"
        case .leaveRequestSubmitted:
            return "Review & approve"
        case .leaveRequestRejected:
            return "Check reason"
        default:
            return nil
        }
    }
    
    /// Dodatkowe informacje o powiadomieniu
    var contextualInfo: String? {
        if let projectTitle = projectTitle {
            return "Project: \(projectTitle)"
        }
        return nil
    }
    
    /// Czy powiadomienie wygasło
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    /// Czy powiadomienie jest pilne
    var isUrgent: Bool {
        return priority == .urgent || type == .emergencyAlert
    }
    
    /// Parse metadata as JSON dictionary if possible
    var metadataDict: [String: Any]? {
        guard let metadata = metadata,
              let data = metadata.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
}

// ========== EQUATABLE IMPLEMENTATION ==========

extension AppNotification: Equatable {
    static func == (lhs: AppNotification, rhs: AppNotification) -> Bool {
        return lhs.id == rhs.id &&
               lhs.employeeId == rhs.employeeId &&
               lhs.type == rhs.type &&
               lhs.title == rhs.title &&
               lhs.message == rhs.message &&
               lhs.isRead == rhs.isRead &&
               lhs.createdAt == rhs.createdAt &&
               lhs.updatedAt == rhs.updatedAt
    }
}

// ========== ENUM PRIORITY ==========

enum NotificationPriority: String, Codable, CaseIterable {
    case urgent = "URGENT"
    case high = "HIGH"
    case normal = "NORMAL"
    case low = "LOW"
    
    var displayName: String {
        switch self {
        case .urgent: return "Urgent"
        case .high: return "High"
        case .normal: return "Normal"
        case .low: return "Low"
        }
    }
}

// ========== ENUM CATEGORY ==========

enum NotificationCategory: String, Codable, CaseIterable {
    case hours = "HOURS"
    case project = "PROJECT"
    case task = "TASK"
    case workplan = "WORKPLAN"
    case leave = "LEAVE"
    case payroll = "PAYROLL"
    case system = "SYSTEM"
    case emergency = "EMERGENCY"
    
    var displayName: String {
        switch self {
        case .hours: return "Hours"
        case .project: return "Project"
        case .task: return "Task"
        case .workplan: return "Work Plan"
        case .leave: return "Leave"
        case .payroll: return "Payroll"
        case .system: return "System"
        case .emergency: return "Emergency"
        }
    }
}

// ========== ENUM TYPU POWIADOMIENIA - SYNCED WITH DB ==========

enum NotificationType: String, Codable, CaseIterable {
    // 🕐 Hours & Timesheet Flow
    case hoursSubmitted = "HOURS_SUBMITTED"
    case hoursApproved = "HOURS_APPROVED"                           // Backward compatibility
    case hoursConfirmed = "HOURS_CONFIRMED"                         // New standard
    case hoursRejected = "HOURS_REJECTED"
    case hoursConfirmedForPayroll = "HOURS_CONFIRMED_FOR_PAYROLL"
    case timesheetGenerated = "TIMESHEET_GENERATED"
    case payrollProcessed = "PAYROLL_PROCESSED"
    case hoursReminder = "HOURS_REMINDER"
    case hoursOverdue = "HOURS_OVERDUE"
    
    // 🏗️ Project Management
    case projectCreated = "PROJECT_CREATED"
    case projectAssigned = "PROJECT_ASSIGNED"
    case projectActivated = "PROJECT_ACTIVATED"
    case projectCompleted = "PROJECT_COMPLETED"
    case projectCancelled = "PROJECT_CANCELLED"
    case projectStatusChanged = "PROJECT_STATUS_CHANGED"
    case projectDeadlineApproaching = "PROJECT_DEADLINE_APPROACHING"
    
    // ⚒️ Task Management
    case taskCreated = "TASK_CREATED"
    case taskAssigned = "TASK_ASSIGNED"
    case taskReassigned = "TASK_REASSIGNED"
    case taskUnassigned = "TASK_UNASSIGNED"
    case taskCompleted = "TASK_COMPLETED"
    case taskStatusChanged = "TASK_STATUS_CHANGED"
    case taskDeadlineApproaching = "TASK_DEADLINE_APPROACHING"
    case taskOverdue = "TASK_OVERDUE"
    
    // 📋 Work Plan Management
    case workplanCreated = "WORKPLAN_CREATED"
    case workplanUpdated = "WORKPLAN_UPDATED"
    case workplanAssigned = "WORKPLAN_ASSIGNED"
    case workplanCancelled = "WORKPLAN_CANCELLED"
    
    // 🏖️ Leave Management
    case leaveRequestSubmitted = "LEAVE_REQUEST_SUBMITTED"
    case leaveRequestApproved = "LEAVE_REQUEST_APPROVED"
    case leaveRequestRejected = "LEAVE_REQUEST_REJECTED"
    case leaveRequestCancelled = "LEAVE_REQUEST_CANCELLED"
    case leaveBalanceUpdated = "LEAVE_BALANCE_UPDATED"
    case leaveRequestReminder = "LEAVE_REQUEST_REMINDER"
    case leaveStarting = "LEAVE_STARTING"
    case leaveEnding = "LEAVE_ENDING"
    
    // 👤 Employee Management
    case employeeActivated = "EMPLOYEE_ACTIVATED"
    case employeeDeactivated = "EMPLOYEE_DEACTIVATED"
    case employeeRoleChanged = "EMPLOYEE_ROLE_CHANGED"
    case licenseExpiring = "LICENSE_EXPIRING"
    case licenseExpired = "LICENSE_EXPIRED"
    case certificationRequired = "CERTIFICATION_REQUIRED"
    
    // 💰 Payroll & Billing
    case payrollReady = "PAYROLL_READY"
    case invoiceGenerated = "INVOICE_GENERATED"
    case paymentReceived = "PAYMENT_RECEIVED"
    
    // 🔧 System & Emergency
    case systemMaintenance = "SYSTEM_MAINTENANCE"
    case emergencyAlert = "EMERGENCY_ALERT"
    case generalAnnouncement = "GENERAL_ANNOUNCEMENT"
    case generalInfo = "GENERAL_INFO"
    
    var displayName: String {
        switch self {
        // Hours Flow
        case .hoursSubmitted:
            return "Hours Submitted"
        case .hoursApproved, .hoursConfirmed:
            return "Hours Confirmed"
        case .hoursRejected:
            return "Hours Rejected"
        case .hoursConfirmedForPayroll:
            return "Ready for Payroll"
        case .timesheetGenerated:
            return "Timesheet Generated"
        case .payrollProcessed:
            return "Payroll Processed"
        case .hoursReminder:
            return "Hours Reminder"
        case .hoursOverdue:
            return "Hours Overdue"
            
        // Project Flow
        case .projectCreated:
            return "Project Created"
        case .projectAssigned:
            return "Project Assigned"
        case .projectActivated:
            return "Project Activated"
        case .projectCompleted:
            return "Project Completed"
        case .projectCancelled:
            return "Project Cancelled"
        case .projectStatusChanged:
            return "Project Updated"
        case .projectDeadlineApproaching:
            return "Project Deadline Soon"
            
        // Task Flow
        case .taskCreated:
            return "Task Created"
        case .taskAssigned:
            return "Task Assigned"
        case .taskReassigned:
            return "Task Reassigned"
        case .taskUnassigned:
            return "Task Unassigned"
        case .taskCompleted:
            return "Task Completed"
        case .taskStatusChanged:
            return "Task Updated"
        case .taskDeadlineApproaching:
            return "Task Deadline Soon"
        case .taskOverdue:
            return "Task Overdue"
            
        // Work Plan Flow
        case .workplanCreated:
            return "Work Plan Created"
        case .workplanUpdated:
            return "Work Plan Updated"
        case .workplanAssigned:
            return "Work Plan Assigned"
        case .workplanCancelled:
            return "Work Plan Cancelled"
            
        // Leave Flow
        case .leaveRequestSubmitted:
            return "Leave Request Submitted"
        case .leaveRequestApproved:
            return "Leave Request Approved"
        case .leaveRequestRejected:
            return "Leave Request Rejected"
        case .leaveRequestCancelled:
            return "Leave Request Cancelled"
        case .leaveBalanceUpdated:
            return "Leave Balance Updated"
        case .leaveRequestReminder:
            return "Leave Request Reminder"
        case .leaveStarting:
            return "Leave Starting"
        case .leaveEnding:
            return "Leave Ending"
            
        // Employee Flow
        case .employeeActivated:
            return "Employee Activated"
        case .employeeDeactivated:
            return "Employee Deactivated"
        case .employeeRoleChanged:
            return "Role Changed"
        case .licenseExpiring:
            return "License Expiring"
        case .licenseExpired:
            return "License Expired"
        case .certificationRequired:
            return "Certification Required"
            
        // Payroll Flow
        case .payrollReady:
            return "Payroll Ready"
        case .invoiceGenerated:
            return "Invoice Generated"
        case .paymentReceived:
            return "Payment Received"
            
        // System Flow
        case .systemMaintenance:
            return "System Maintenance"
        case .emergencyAlert:
            return "Emergency Alert"
        case .generalAnnouncement:
            return "Announcement"
        case .generalInfo:
            return "Information"
        }
    }
}

// ========== MOCK DATA DLA PREVIEW - COMPLETE EXAMPLES ==========

extension AppNotification {
    static let mockRejected = AppNotification(
        id: 1,
        employeeId: 123,
        type: .hoursRejected,
        title: "Hours Entry Rejected",
        message: "Your entry for May 25, 2025 has been rejected. Please check the work entry details and resubmit.",
        isRead: false,
        createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
        updatedAt: Date().addingTimeInterval(-3600),
        workEntryId: 456, // ✅ POPRAWKA
        taskId: 789,
        projectId: 10,
        projectTitle: "Crane Installation Project",
        priority: .high,
        category: .hours,
        actionRequired: true,
        actionUrl: nil,
        expiresAt: nil,
        readAt: nil,
        senderId: nil,
        targetEmployeeId: nil,
        targetRole: nil,
        metadata: nil
    )
    
    static let mockConfirmed = AppNotification(
        id: 2,
        employeeId: 123,
        type: .hoursConfirmed,
        title: nil,  // FIXED: Example of null title from API
        message: "Your entry for May 24, 2025 has been confirmed and processed for payroll.",
        isRead: true,
        createdAt: Date().addingTimeInterval(-86400), // 1 day ago
        updatedAt: Date().addingTimeInterval(-86400),
        workEntryId: 455, // ✅ POPRAWKA
        taskId: 789,
        projectId: 10,
        projectTitle: "Crane Installation Project",
        priority: .normal,
        category: .hours,
        actionRequired: false,
        actionUrl: nil,
        expiresAt: nil,
        readAt: Date().addingTimeInterval(-86400),
        senderId: nil,
        targetEmployeeId: nil,
        targetRole: nil,
        metadata: nil
    )
    
    static let mockEmergencyAlert = AppNotification(
        id: 7,
        employeeId: 123,
        type: .emergencyAlert,
        title: "Emergency Alert",
        message: "Safety alert: Strong winds expected at Site A. All crane operations suspended until further notice.",
        isRead: false,
        createdAt: Date().addingTimeInterval(-300), // 5 minutes ago
        updatedAt: Date().addingTimeInterval(-300),
        workEntryId: nil,
        taskId: nil,
        projectId: 10,
        projectTitle: "Crane Installation Project",
        priority: .urgent,
        category: .emergency,
        actionRequired: true,
        actionUrl: nil,
        expiresAt: Date().addingTimeInterval(3600), // Expires in 1 hour
        readAt: nil,
        senderId: nil,
        targetEmployeeId: nil,
        targetRole: nil,
        metadata: nil
    )
    
    static let mockData: [AppNotification] = [
        mockEmergencyAlert,
        mockRejected,
        mockConfirmed,
        // Dodaj więcej przykładów...
    ]
}
