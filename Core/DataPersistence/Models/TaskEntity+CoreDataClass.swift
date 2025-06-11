//
//  TaskEntity+CoreDataClass.swift
//  KSR Cranes App
//
//  Created by KSR Cranes on 2025-06-11.
//
//

import Foundation
import CoreData

@objc(TaskEntity)
public class TaskEntity: NSManagedObject {
    
    // MARK: - Sync Status
    enum SyncStatus: String {
        case pending = "pending"
        case synced = "synced"
        case error = "error"
        case conflict = "conflict"
    }
    
    // MARK: - Task Status
    enum TaskStatus: String {
        case planned = "planned"
        case inProgress = "in_progress"
        case completed = "completed"
        case cancelled = "cancelled"
        case overdue = "overdue"
    }
    
    // MARK: - Task Priority
    enum TaskPriority: String {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
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
    
    var taskStatusEnum: TaskStatus {
        get {
            return TaskStatus(rawValue: status ?? "") ?? .planned
        }
        set {
            status = newValue.rawValue
        }
    }
    
    var taskPriorityEnum: TaskPriority {
        get {
            return TaskPriority(rawValue: priority ?? "") ?? .medium
        }
        set {
            priority = newValue.rawValue
        }
    }
    
    // MARK: - Validation
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try validateTask()
    }
    
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateTask()
    }
    
    private func validateTask() throws {
        // Validate required fields
        guard let name = name, !name.isEmpty else {
            throw TaskValidationError.missingRequiredField("name")
        }
        
        // Validate status
        let validStatuses = ["planned", "in_progress", "completed", "cancelled", "overdue"]
        if let status = status, !validStatuses.contains(status) {
            throw TaskValidationError.invalidStatus
        }
        
        // Validate priority
        let validPriorities = ["low", "medium", "high", "critical"]
        if let priority = priority, !validPriorities.contains(priority) {
            throw TaskValidationError.invalidPriority
        }
        
        // Validate dates
        if let start = startDate, let deadline = deadline, start > deadline {
            throw TaskValidationError.invalidDateRange
        }
        
        // Validate required operators
        if requiredOperators < 0 || requiredOperators > 50 {
            throw TaskValidationError.invalidOperatorCount
        }
        
        // Validate estimated hours
        if let hours = estimatedHours, hours.doubleValue < 0 || hours.doubleValue > 1000 {
            throw TaskValidationError.invalidHours
        }
    }
    
    // MARK: - Conversion Methods
    func toAPIModel() -> ProjectTaskAPIModel {
        return ProjectTaskAPIModel(
            task_id: Int(serverID),
            project_id: Int(project?.serverID ?? 0),
            name: name ?? "",
            description: descriptionText,
            deadline: deadline,
            is_completed: taskStatusEnum == .completed,
            created_at: createdAt,
            updated_at: lastModified,
            equipment: nil, // Handle equipment separately if needed
            startDate: startDate,
            status: taskStatusEnum,
            priority: taskPriorityEnum,
            estimatedHours: estimatedHours?.doubleValue,
            requiredOperators: Int(requiredOperators),
            clientEquipmentInfo: clientEquipmentInfo
        )
    }
    
    static func fromAPIModel(_ apiModel: ProjectTaskAPIModel, context: NSManagedObjectContext) -> TaskEntity {
        let entity = TaskEntity(context: context)
        entity.updateFromAPIModel(apiModel)
        return entity
    }
    
    func updateFromAPIModel(_ apiModel: ProjectTaskAPIModel) {
        serverID = Int32(apiModel.task_id)
        name = apiModel.name
        descriptionText = apiModel.description
        deadline = apiModel.deadline
        startDate = apiModel.startDate
        status = apiModel.status?.rawValue ?? "planned"
        priority = apiModel.priority?.rawValue ?? "medium"
        requiredOperators = Int32(apiModel.requiredOperators ?? 1)
        clientEquipmentInfo = apiModel.clientEquipmentInfo
        
        if let hours = apiModel.estimatedHours {
            estimatedHours = NSDecimalNumber(value: hours)
        }
        
        lastModified = Date()
        syncStatusEnum = .synced
    }
    
    // MARK: - Conflict Resolution
    func resolveConflict(with serverVersion: ProjectTaskAPIModel, strategy: TaskConflictResolutionStrategy = .serverWins) {
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
    func updateStatus() {
        // Auto-update status based on conditions
        if taskStatusEnum == .planned && startDate != nil && startDate! <= Date() {
            taskStatusEnum = .inProgress
        }
        
        if taskStatusEnum == .inProgress && deadline != nil && deadline! < Date() {
            taskStatusEnum = .overdue
        }
    }
    
    func canAssignOperator() -> Bool {
        return taskStatusEnum == .planned || taskStatusEnum == .inProgress
    }
    
    func calculateProgress() -> Double {
        guard let assignments = taskAssignments as? Set<TaskAssignmentEntity> else { return 0 }
        
        let completedAssignments = assignments.filter { $0.status == "completed" }.count
        let totalAssignments = assignments.count
        
        return totalAssignments > 0 ? Double(completedAssignments) / Double(totalAssignments) : 0
    }
}

// MARK: - Supporting Types
struct ProjectTaskAPIModel {
    let task_id: Int
    let project_id: Int
    let name: String
    let description: String?
    let deadline: Date?
    let is_completed: Bool
    let created_at: Date?
    let updated_at: Date?
    let equipment: String?
    let startDate: Date?
    let status: TaskEntity.TaskStatus?
    let priority: TaskEntity.TaskPriority?
    let estimatedHours: Double?
    let requiredOperators: Int?
    let clientEquipmentInfo: String?
}

enum TaskValidationError: LocalizedError {
    case missingRequiredField(String)
    case invalidStatus
    case invalidPriority
    case invalidDateRange
    case invalidOperatorCount
    case invalidHours
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Required field '\(field)' is missing"
        case .invalidStatus:
            return "Invalid task status"
        case .invalidPriority:
            return "Invalid task priority"
        case .invalidDateRange:
            return "Start date must be before deadline"
        case .invalidOperatorCount:
            return "Required operators must be between 0 and 50"
        case .invalidHours:
            return "Estimated hours must be between 0 and 1000"
        }
    }
}

enum TaskConflictResolutionStrategy {
    case serverWins
    case localWins
    case merge
}