//
//  LeaveModels.swift
//  KSR Cranes App
//
//  Created for Leave Management System
//  Following CLAUDE.md specifications for Danish employment law compliance
//

import Foundation

// MARK: - Leave Request Models

struct LeaveRequest: Codable, Identifiable {
    let id: Int
    let employee_id: Int
    let type: LeaveType
    let start_date: Date
    let end_date: Date
    let total_days: Int
    let half_day: Bool
    let status: LeaveStatus
    let reason: String?
    let sick_note_url: String?
    let created_at: Date
    let updated_at: Date
    let approved_by: Int?
    let approved_at: Date?
    let rejection_reason: String?
    let emergency_leave: Bool
    
    // Related data
    let employee: LeaveEmployee?
    let approver: LeaveEmployee?
    
    // Custom date decoding for server ISO date strings
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Non-date fields
        id = try container.decode(Int.self, forKey: .id)
        employee_id = try container.decode(Int.self, forKey: .employee_id)
        type = try container.decode(LeaveType.self, forKey: .type)
        total_days = try container.decode(Int.self, forKey: .total_days)
        half_day = try container.decode(Bool.self, forKey: .half_day)
        status = try container.decode(LeaveStatus.self, forKey: .status)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        sick_note_url = try container.decodeIfPresent(String.self, forKey: .sick_note_url)
        approved_by = try container.decodeIfPresent(Int.self, forKey: .approved_by)
        rejection_reason = try container.decodeIfPresent(String.self, forKey: .rejection_reason)
        emergency_leave = try container.decode(Bool.self, forKey: .emergency_leave)
        employee = try container.decodeIfPresent(LeaveEmployee.self, forKey: .employee)
        approver = try container.decodeIfPresent(LeaveEmployee.self, forKey: .approver)
        
        // Custom date decoding - handles both ISO strings and Date objects
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // start_date
        if let startDateString = try? container.decode(String.self, forKey: .start_date) {
            guard let decodedDate = isoFormatter.date(from: startDateString) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath + [CodingKeys.start_date],
                        debugDescription: "Cannot decode start_date from: \(startDateString)"
                    )
                )
            }
            start_date = decodedDate
        } else {
            start_date = try container.decode(Date.self, forKey: .start_date)
        }
        
        // end_date
        if let endDateString = try? container.decode(String.self, forKey: .end_date) {
            guard let decodedDate = isoFormatter.date(from: endDateString) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath + [CodingKeys.end_date],
                        debugDescription: "Cannot decode end_date from: \(endDateString)"
                    )
                )
            }
            end_date = decodedDate
        } else {
            end_date = try container.decode(Date.self, forKey: .end_date)
        }
        
        // created_at
        if let createdAtString = try? container.decode(String.self, forKey: .created_at) {
            guard let decodedDate = isoFormatter.date(from: createdAtString) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath + [CodingKeys.created_at],
                        debugDescription: "Cannot decode created_at from: \(createdAtString)"
                    )
                )
            }
            created_at = decodedDate
        } else {
            created_at = try container.decode(Date.self, forKey: .created_at)
        }
        
        // updated_at
        if let updatedAtString = try? container.decode(String.self, forKey: .updated_at) {
            guard let decodedDate = isoFormatter.date(from: updatedAtString) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath + [CodingKeys.updated_at],
                        debugDescription: "Cannot decode updated_at from: \(updatedAtString)"
                    )
                )
            }
            updated_at = decodedDate
        } else {
            updated_at = try container.decode(Date.self, forKey: .updated_at)
        }
        
        // approved_at (optional)
        do {
            if let approvedAtString = try container.decodeIfPresent(String.self, forKey: .approved_at) {
                guard let decodedDate = isoFormatter.date(from: approvedAtString) else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath + [CodingKeys.approved_at],
                            debugDescription: "Cannot decode approved_at from: \(approvedAtString)"
                        )
                    )
                }
                approved_at = decodedDate
            } else {
                approved_at = nil
            }
        } catch {
            // Fallback to Date decoding
            approved_at = try container.decodeIfPresent(Date.self, forKey: .approved_at)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(employee_id, forKey: .employee_id)
        try container.encode(type, forKey: .type)
        try container.encode(total_days, forKey: .total_days)
        try container.encode(half_day, forKey: .half_day)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(reason, forKey: .reason)
        try container.encodeIfPresent(sick_note_url, forKey: .sick_note_url)
        try container.encodeIfPresent(approved_by, forKey: .approved_by)
        try container.encodeIfPresent(rejection_reason, forKey: .rejection_reason)
        try container.encode(emergency_leave, forKey: .emergency_leave)
        try container.encodeIfPresent(employee, forKey: .employee)
        try container.encodeIfPresent(approver, forKey: .approver)
        
        // Encode dates as ISO strings for consistency
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        try container.encode(isoFormatter.string(from: start_date), forKey: .start_date)
        try container.encode(isoFormatter.string(from: end_date), forKey: .end_date)
        try container.encode(isoFormatter.string(from: created_at), forKey: .created_at)
        try container.encode(isoFormatter.string(from: updated_at), forKey: .updated_at)
        
        if let approved_at = approved_at {
            try container.encode(isoFormatter.string(from: approved_at), forKey: .approved_at)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, employee_id, type, start_date, end_date, total_days, half_day, status
        case reason, sick_note_url, created_at, updated_at, approved_by, approved_at
        case rejection_reason, emergency_leave, employee, approver
    }
}

struct LeaveEmployee: Codable {
    let employee_id: Int
    let name: String
    let email: String
    let role: String
    let profilePictureUrl: String?
}

// MARK: - Leave Balance Models

struct LeaveBalance: Codable, Identifiable {
    let id: Int
    let employee_id: Int
    let year: Int
    let vacation_days_total: Int
    let vacation_days_used: Int
    let sick_days_used: Int
    let personal_days_total: Int
    let personal_days_used: Int
    let carry_over_days: Int
    let carry_over_expires: Date?
    
    // Computed properties for UI
    var vacation_days_remaining: Int {
        vacation_days_total + carry_over_days - vacation_days_used
    }
    
    var personal_days_remaining: Int {
        personal_days_total - personal_days_used
    }
}

// MARK: - Public Holidays

struct PublicHoliday: Codable, Identifiable {
    let id: Int
    let date: Date
    let name: String
    let description: String?
    let year: Int
    let is_national: Bool
}

// ✅ WRAPPER MODEL FOR API RESPONSE
struct PublicHolidaysResponse: Codable {
    let holidays: [PublicHoliday]
}

// ✅ WRAPPER FOR LEAVE BALANCE SERVER RESPONSE  
struct LeaveBalanceServerResponse: Codable {
    let balance: LeaveBalance
}

// MARK: - Leave Enums

enum LeaveType: String, Codable, CaseIterable {
    case vacation = "VACATION"          // Ferie
    case sick = "SICK"                  // Sygemeldt
    case personal = "PERSONAL"          // Personlig dag
    case parental = "PARENTAL"          // Forældreorlov
    case compensatory = "COMPENSATORY"  // Afspadsering
    case emergency = "EMERGENCY"        // Nødstilfælde
    
    var displayName: String {
        switch self {
        case .vacation: return "Vacation"
        case .sick: return "Sick Leave"
        case .personal: return "Personal Day"
        case .parental: return "Parental Leave"
        case .compensatory: return "Compensatory Time"
        case .emergency: return "Emergency Leave"
        }
    }
    
    var requiresAdvanceNotice: Bool {
        switch self {
        case .vacation: return true
        case .personal: return true
        case .parental: return true
        case .compensatory: return true
        case .sick, .emergency: return false
        }
    }
    
    var canBeHalfDay: Bool {
        switch self {
        case .vacation, .personal, .compensatory: return true
        case .sick, .parental, .emergency: return false
        }
    }
}

enum LeaveStatus: String, Codable, CaseIterable {
    case pending = "PENDING"      // Afventer godkendelse
    case approved = "APPROVED"    // Godkendt
    case rejected = "REJECTED"    // Afvist
    case cancelled = "CANCELLED"  // Annulleret
    case expired = "EXPIRED"      // Udløbet
    
    var displayName: String {
        switch self {
        case .pending: return "Pending Approval"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        }
    }
    
    var canBeCancelled: Bool {
        switch self {
        case .pending, .approved: return true
        case .rejected, .cancelled, .expired: return false
        }
    }
}

// MARK: - Request/Response Models

struct CreateLeaveRequestRequest: Codable {
    let employee_id: Int  // ✅ ADDED MISSING FIELD
    let type: LeaveType
    let start_date: Date
    let end_date: Date
    let half_day: Bool
    let reason: String?
    let emergency_leave: Bool
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(employee_id, forKey: .employee_id)  // ✅ ENCODE EMPLOYEE_ID
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(half_day, forKey: .half_day)
        try container.encodeIfPresent(reason, forKey: .reason)
        try container.encode(emergency_leave, forKey: .emergency_leave)
        
        // Custom date encoding - dates only (no time)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        try container.encode(dateFormatter.string(from: start_date), forKey: .start_date)
        try container.encode(dateFormatter.string(from: end_date), forKey: .end_date)
    }
    
    private enum CodingKeys: String, CodingKey {
        case employee_id, type, start_date, end_date, half_day, reason, emergency_leave  // ✅ ADDED EMPLOYEE_ID
    }
}

struct UpdateLeaveRequestRequest: Codable {
    let employee_id: Int  // ✅ ADDED FOR CONSISTENCY
    var id: Int?          // ✅ ADDED FOR UPDATE REQUESTS
    let start_date: Date?
    let end_date: Date?
    let half_day: Bool?
    let reason: String?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(employee_id, forKey: .employee_id)  // ✅ ENCODE EMPLOYEE_ID
        try container.encodeIfPresent(id, forKey: .id)           // ✅ ENCODE ID
        try container.encodeIfPresent(half_day, forKey: .half_day)
        try container.encodeIfPresent(reason, forKey: .reason)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        if let start_date = start_date {
            try container.encode(dateFormatter.string(from: start_date), forKey: .start_date)
        }
        if let end_date = end_date {
            try container.encode(dateFormatter.string(from: end_date), forKey: .end_date)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case employee_id, id, start_date, end_date, half_day, reason  // ✅ ADDED ID
    }
}

struct ApproveRejectLeaveRequest: Codable {
    let action: LeaveAction
    let rejection_reason: String?
    
    enum LeaveAction: String, Codable {
        case approve = "approve"
        case reject = "reject"
    }
    
    private enum CodingKeys: String, CodingKey {
        case action, rejection_reason
    }
}

struct CancelLeaveResponse: Codable {
    let success: Bool
    let message: String
    let requires_approval: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case success, message, requires_approval
    }
}

struct LeaveRequestsResponse: Codable {
    let requests: [LeaveRequest]
    let total: Int
    let page: Int
    let limit: Int
    let has_more: Bool
}

// ✅ WRAPPER FOR SERVER RESPONSE
struct LeaveRequestsServerResponse: Codable {
    let leave_requests: [LeaveRequest]
    let leave_balance: LeaveBalance?
}

// ✅ SERVER RESPONSE WRAPPER FOR CREATE LEAVE REQUEST
struct CreateLeaveRequestResponse: Codable {
    let success: Bool
    let leave_request: LeaveRequest
    let confirmation: LeaveConfirmationDetails?
    
    struct LeaveConfirmationDetails: Codable {
        let message: String
        let details: LeaveConfirmationDetailsInner
        
        struct LeaveConfirmationDetailsInner: Codable {
            let type: String
            let dates: String
            let work_days: Int
            let half_day: Bool
            let status: String
            let next_steps: String
        }
    }
}

struct ApproveRejectLeaveResponse: Codable {
    let message: String
    let request: LeaveRequest
    let balance_updated: LeaveBalance?
}

// MARK: - Statistics and Calendar Models

struct LeaveStatistics: Codable {
    let total_requests: Int
    let pending_requests: Int
    let approved_requests: Int
    let rejected_requests: Int
    let team_on_leave_today: Int
    let team_on_leave_this_week: Int
    let most_common_leave_type: LeaveType?
    let average_response_time_hours: Double?
}

struct TeamLeaveCalendar: Codable {
    let date: Date
    let employees_on_leave: [EmployeeLeaveDay]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Custom date decoding from string
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        guard let decodedDate = dateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath + [CodingKeys.date],
                    debugDescription: "Cannot decode date from: \(dateString)"
                )
            )
        }
        
        self.date = decodedDate
        self.employees_on_leave = try container.decode([EmployeeLeaveDay].self, forKey: .employees_on_leave)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        try container.encode(dateFormatter.string(from: date), forKey: .date)
        try container.encode(employees_on_leave, forKey: .employees_on_leave)
    }
    
    private enum CodingKeys: String, CodingKey {
        case date, employees_on_leave
    }
}

struct EmployeeLeaveDay: Codable {
    let employee_id: Int
    let employee_name: String
    let leave_type: LeaveType
    let is_half_day: Bool
    let profile_picture_url: String?
}

// MARK: - Query Parameters

struct LeaveQueryParams {
    let employee_id: Int?
    let status: LeaveStatus?
    let type: LeaveType?
    let start_date: Date?
    let end_date: Date?
    let page: Int
    let limit: Int
    let include_employee: Bool
    let include_approver: Bool
    
    init(
        employee_id: Int? = nil,
        status: LeaveStatus? = nil,
        type: LeaveType? = nil,
        start_date: Date? = nil,
        end_date: Date? = nil,
        page: Int = 1,
        limit: Int = 50,
        include_employee: Bool = true,
        include_approver: Bool = true
    ) {
        self.employee_id = employee_id
        self.status = status
        self.type = type
        self.start_date = start_date
        self.end_date = end_date
        self.page = page
        self.limit = limit
        self.include_employee = include_employee
        self.include_approver = include_approver
    }
    
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        if let employee_id = employee_id {
            items.append(URLQueryItem(name: "employee_id", value: String(employee_id)))
        }
        if let status = status {
            items.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        if let type = type {
            items.append(URLQueryItem(name: "type", value: type.rawValue))
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let start_date = start_date {
            items.append(URLQueryItem(name: "start_date", value: dateFormatter.string(from: start_date)))
        }
        if let end_date = end_date {
            items.append(URLQueryItem(name: "end_date", value: dateFormatter.string(from: end_date)))
        }
        
        items.append(URLQueryItem(name: "page", value: String(page)))
        items.append(URLQueryItem(name: "limit", value: String(limit)))
        items.append(URLQueryItem(name: "include_employee", value: String(include_employee)))
        items.append(URLQueryItem(name: "include_approver", value: String(include_approver)))
        
        return items
    }
}

// MARK: - Document Upload Models

struct SickNoteUploadRequest: Codable {
    let file_name: String
    let file_type: String
    let file_size: Int
}

struct SickNoteUploadResponse: Codable {
    let upload_url: String
    let file_key: String
    let expires_at: Date
}

struct DocumentUploadConfirmation: Codable {
    let file_key: String
    let file_name: String
}

// MARK: - Error Models

struct LeaveValidationError: Codable {
    let field: String
    let message: String
    let code: String
}

struct LeaveErrorResponse: Codable {
    let error: String
    let message: String
    let validation_errors: [LeaveValidationError]?
}