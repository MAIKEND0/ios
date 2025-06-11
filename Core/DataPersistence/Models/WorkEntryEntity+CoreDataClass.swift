//
//  WorkEntryEntity+CoreDataClass.swift
//  KSR Cranes App
//
//  Created by KSR Cranes on 2025-06-11.
//
//

import Foundation
import CoreData

@objc(WorkEntryEntity)
public class WorkEntryEntity: NSManagedObject {
    
    // MARK: - Sync Status
    enum SyncStatus: String {
        case pending = "pending"
        case synced = "synced"
        case error = "error"
        case conflict = "conflict"
    }
    
    // MARK: - Entry Status
    enum EntryStatus: String {
        case pending = "pending"
        case approved = "approved"
        case rejected = "rejected"
        case needsModification = "needs_modification"
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
    
    var entryStatusEnum: EntryStatus {
        get {
            return EntryStatus(rawValue: status ?? "") ?? .pending
        }
        set {
            status = newValue.rawValue
        }
    }
    
    // MARK: - Validation
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try validateWorkEntry()
    }
    
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateWorkEntry()
    }
    
    private func validateWorkEntry() throws {
        // Validate required fields
        guard workDate != nil else {
            throw WorkEntryValidationError.missingRequiredField("workDate")
        }
        
        guard let hours = totalHours else {
            throw WorkEntryValidationError.missingRequiredField("totalHours")
        }
        
        // Validate hours range
        if hours.doubleValue < 0 || hours.doubleValue > 24 {
            throw WorkEntryValidationError.invalidHours
        }
        
        // Validate status
        let validStatuses = ["pending", "approved", "rejected", "needs_modification"]
        if let status = status, !validStatuses.contains(status) {
            throw WorkEntryValidationError.invalidStatus
        }
    }
    
    // MARK: - Conversion Methods
    func toAPIModel() -> WorkHourEntryAPIModel {
        return WorkHourEntryAPIModel(
            id: localID ?? UUID().uuidString,
            employee_id: Int(employee?.serverID ?? 0),
            employee_name: employee?.name ?? "",
            work_date: workDate ?? Date(),
            start_time: startTime,
            end_time: endTime,
            break_duration: breakDuration?.doubleValue ?? 0,
            total_hours: totalHours?.doubleValue ?? 0,
            regular_hours: regularHours?.doubleValue ?? 0,
            overtime_hours: overtimeHours?.doubleValue ?? 0,
            project_id: Int(project?.serverID ?? 0),
            task_id: Int(task?.serverID ?? 0),
            notes: notes,
            status: entryStatusEnum,
            created_at: createdAt,
            updated_at: lastModified,
            approved_by: Int(approvedBy),
            approved_at: approvedAt,
            submitted_at: submittedAt,
            rejection_reason: rejectionReason
        )
    }
    
    static func fromAPIModel(_ apiModel: WorkHourEntryAPIModel, context: NSManagedObjectContext) -> WorkEntryEntity {
        let entity = WorkEntryEntity(context: context)
        entity.updateFromAPIModel(apiModel)
        return entity
    }
    
    func updateFromAPIModel(_ apiModel: WorkHourEntryAPIModel) {
        localID = apiModel.id
        workDate = apiModel.work_date
        startTime = apiModel.start_time
        endTime = apiModel.end_time
        
        if let breakDur = apiModel.break_duration {
            breakDuration = NSDecimalNumber(value: breakDur)
        }
        
        totalHours = NSDecimalNumber(value: apiModel.total_hours)
        regularHours = NSDecimalNumber(value: apiModel.regular_hours)
        overtimeHours = NSDecimalNumber(value: apiModel.overtime_hours)
        
        notes = apiModel.notes
        status = apiModel.status.rawValue
        approvedBy = Int32(apiModel.approved_by ?? 0)
        approvedAt = apiModel.approved_at
        submittedAt = apiModel.submitted_at
        rejectionReason = apiModel.rejection_reason
        
        lastModified = Date()
        syncStatusEnum = .synced
    }
    
    // MARK: - Conflict Resolution
    func resolveConflict(with serverVersion: WorkHourEntryAPIModel, strategy: WorkEntryConflictResolutionStrategy = .serverWins) {
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
    func calculateTotalHours() {
        guard let start = startTime, let end = endTime else { return }
        
        let interval = end.timeIntervalSince(start)
        let breakDur = breakDuration?.doubleValue ?? 0
        let total = max(0, (interval / 3600) - breakDur)
        
        totalHours = NSDecimalNumber(value: total)
        
        // Calculate regular and overtime
        let regularLimit = 8.0
        if total <= regularLimit {
            regularHours = NSDecimalNumber(value: total)
            overtimeHours = NSDecimalNumber(value: 0)
        } else {
            regularHours = NSDecimalNumber(value: regularLimit)
            overtimeHours = NSDecimalNumber(value: total - regularLimit)
        }
    }
}

// MARK: - Supporting Types
struct WorkHourEntryAPIModel {
    let id: String
    let employee_id: Int
    let employee_name: String
    let work_date: Date
    let start_time: Date?
    let end_time: Date?
    let break_duration: Double?
    let total_hours: Double
    let regular_hours: Double
    let overtime_hours: Double
    let project_id: Int?
    let task_id: Int?
    let notes: String?
    let status: WorkEntryEntity.EntryStatus
    let created_at: Date?
    let updated_at: Date?
    let approved_by: Int?
    let approved_at: Date?
    let submitted_at: Date?
    let rejection_reason: String?
}

enum WorkEntryValidationError: LocalizedError {
    case missingRequiredField(String)
    case invalidHours
    case invalidStatus
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Required field '\(field)' is missing"
        case .invalidHours:
            return "Hours must be between 0 and 24"
        case .invalidStatus:
            return "Invalid status specified"
        }
    }
}

enum WorkEntryConflictResolutionStrategy {
    case serverWins
    case localWins
    case merge
}