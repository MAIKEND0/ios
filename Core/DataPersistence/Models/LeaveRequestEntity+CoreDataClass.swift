//
//  LeaveRequestEntity+CoreDataClass.swift
//  KSR Cranes App
//
//  Created by KSR Cranes on 2025-06-11.
//
//

import Foundation
import CoreData

@objc(LeaveRequestEntity)
public class LeaveRequestEntity: NSManagedObject {
    
    // MARK: - Sync Status
    enum SyncStatus: String {
        case pending = "pending"
        case synced = "synced"
        case error = "error"
        case conflict = "conflict"
    }
    
    // MARK: - Leave Type
    enum LeaveType: String {
        case vacation = "VACATION"
        case sick = "SICK"
        case personal = "PERSONAL"
        case parental = "PARENTAL"
        case compensatory = "COMPENSATORY"
        case emergency = "EMERGENCY"
    }
    
    // MARK: - Leave Status
    enum LeaveStatus: String {
        case pending = "PENDING"
        case approved = "APPROVED"
        case rejected = "REJECTED"
        case cancelled = "CANCELLED"
        case expired = "EXPIRED"
    }
    
    // MARK: - Convenience Properties
    var syncStatusEnum: SyncStatus {
        get {
            return SyncStatus(rawValue: syncStatus ?? "") ?? .pending
        }
        set {
            syncStatus = newValue.rawValue
        }
    }
    
    var leaveTypeEnum: LeaveType {
        get {
            return LeaveType(rawValue: type ?? "") ?? .vacation
        }
        set {
            type = newValue.rawValue
        }
    }
    
    var leaveStatusEnum: LeaveStatus {
        get {
            return LeaveStatus(rawValue: status ?? "") ?? .pending
        }
        set {
            status = newValue.rawValue
        }
    }
    
    // MARK: - Validation
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try validateLeaveRequest()
    }
    
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateLeaveRequest()
    }
    
    private func validateLeaveRequest() throws {
        // Validate required fields
        guard startDate != nil else {
            throw LeaveRequestValidationError.missingRequiredField("startDate")
        }
        
        guard endDate != nil else {
            throw LeaveRequestValidationError.missingRequiredField("endDate")
        }
        
        // Validate date range
        if let start = startDate, let end = endDate, start > end {
            throw LeaveRequestValidationError.invalidDateRange
        }
        
        // Validate type
        let validTypes = ["VACATION", "SICK", "PERSONAL", "PARENTAL", "COMPENSATORY", "EMERGENCY"]
        if let type = type, !validTypes.contains(type) {
            throw LeaveRequestValidationError.invalidLeaveType
        }
        
        // Validate status
        let validStatuses = ["PENDING", "APPROVED", "REJECTED", "CANCELLED", "EXPIRED"]
        if let status = status, !validStatuses.contains(status) {
            throw LeaveRequestValidationError.invalidStatus
        }
        
        // Validate total days
        if totalDays < 0 {
            throw LeaveRequestValidationError.invalidDays
        }
    }
    
    // MARK: - Conversion Methods
    func toAPIModel() -> LeaveRequestAPIModel {
        return LeaveRequestAPIModel(
            id: Int(serverID),
            employee_id: Int(employee?.serverID ?? 0),
            type: leaveTypeEnum,
            start_date: startDate ?? Date(),
            end_date: endDate ?? Date(),
            total_days: Int(totalDays),
            half_day: halfDay,
            status: leaveStatusEnum,
            reason: reason,
            sick_note_url: sickNoteUrl,
            created_at: createdAt,
            updated_at: lastModified,
            approved_by: approvedBy != 0 ? Int(approvedBy) : nil,
            approved_at: approvedAt,
            rejection_reason: rejectionReason,
            emergency_leave: emergencyLeave,
            employee: nil, // Handle separately if needed
            approver: nil  // Handle separately if needed
        )
    }
    
    static func fromAPIModel(_ apiModel: LeaveRequestAPIModel, context: NSManagedObjectContext) -> LeaveRequestEntity {
        let entity = LeaveRequestEntity(context: context)
        entity.updateFromAPIModel(apiModel)
        return entity
    }
    
    func updateFromAPIModel(_ apiModel: LeaveRequestAPIModel) {
        serverID = Int32(apiModel.id)
        type = apiModel.type.rawValue
        startDate = apiModel.start_date
        endDate = apiModel.end_date
        totalDays = Int32(apiModel.total_days)
        halfDay = apiModel.half_day
        status = apiModel.status.rawValue
        reason = apiModel.reason
        sickNoteUrl = apiModel.sick_note_url
        approvedBy = Int32(apiModel.approved_by ?? 0)
        approvedAt = apiModel.approved_at
        rejectionReason = apiModel.rejection_reason
        emergencyLeave = apiModel.emergency_leave
        
        lastModified = Date()
        syncStatusEnum = .synced
    }
    
    // MARK: - Conflict Resolution
    func resolveConflict(with serverVersion: LeaveRequestAPIModel, strategy: LeaveRequestConflictResolutionStrategy = .serverWins) {
        switch strategy {
        case .serverWins:
            updateFromAPIModel(serverVersion)
        case .localWins:
            // Keep local changes, mark for sync
            syncStatusEnum = .pending
        case .merge:
            // Merge logic - keep newer changes based on lastModified
            if let serverUpdated = serverVersion.updated_at,
               let localUpdated = lastModified,
               serverUpdated > localUpdated {
                updateFromAPIModel(serverVersion)
            } else {
                syncStatusEnum = .pending
            }
        }
    }
    
    // MARK: - Helper Methods
    func calculateWorkDays() -> Int {
        guard let start = startDate, let end = endDate else { return 0 }
        
        let calendar = Calendar.current
        var workDays = 0
        var currentDate = start
        
        while currentDate <= end {
            let weekday = calendar.component(.weekday, from: currentDate)
            // Monday = 2, Friday = 6
            if weekday >= 2 && weekday <= 6 {
                workDays += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return halfDay ? max(1, workDays / 2) : workDays
    }
    
    func canEdit() -> Bool {
        return leaveStatusEnum == .pending
    }
    
    func canCancel() -> Bool {
        return leaveStatusEnum == .pending || leaveStatusEnum == .approved
    }
    
    func isUpcoming() -> Bool {
        guard let start = startDate else { return false }
        return start > Date()
    }
    
    func isOngoing() -> Bool {
        guard let start = startDate, let end = endDate else { return false }
        let now = Date()
        return start <= now && end >= now
    }
}

// MARK: - Supporting Types
struct LeaveRequestAPIModel {
    let id: Int
    let employee_id: Int
    let type: LeaveRequestEntity.LeaveType
    let start_date: Date
    let end_date: Date
    let total_days: Int
    let half_day: Bool
    let status: LeaveRequestEntity.LeaveStatus
    let reason: String?
    let sick_note_url: String?
    let created_at: Date?
    let updated_at: Date?
    let approved_by: Int?
    let approved_at: Date?
    let rejection_reason: String?
    let emergency_leave: Bool
    let employee: EmployeeAPIModel?
    let approver: EmployeeAPIModel?
}

enum LeaveRequestValidationError: LocalizedError {
    case missingRequiredField(String)
    case invalidDateRange
    case invalidLeaveType
    case invalidStatus
    case invalidDays
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Required field '\(field)' is missing"
        case .invalidDateRange:
            return "Start date must be before end date"
        case .invalidLeaveType:
            return "Invalid leave type"
        case .invalidStatus:
            return "Invalid leave status"
        case .invalidDays:
            return "Total days cannot be negative"
        }
    }
}

enum LeaveRequestConflictResolutionStrategy {
    case serverWins
    case localWins
    case merge
}