//
//  ProjectEntity+CoreDataClass.swift
//  KSR Cranes App
//
//  Created by KSR Cranes on 2025-06-11.
//
//

import Foundation
import CoreData

@objc(ProjectEntity)
public class ProjectEntity: NSManagedObject {
    
    // MARK: - Sync Status
    enum SyncStatus: String {
        case pending = "pending"
        case synced = "synced"
        case error = "error"
        case conflict = "conflict"
    }
    
    // MARK: - Project Status
    enum ProjectStatus: String {
        case active = "active"
        case completed = "completed"
        case onHold = "on_hold"
        case cancelled = "cancelled"
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
    
    var projectStatusEnum: ProjectStatus {
        get {
            return ProjectStatus(rawValue: status ?? "") ?? .active
        }
        set {
            status = newValue.rawValue
        }
    }
    
    // MARK: - Validation
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try validateProject()
    }
    
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateProject()
    }
    
    private func validateProject() throws {
        // Validate required fields
        guard let name = name, !name.isEmpty else {
            throw ProjectValidationError.missingRequiredField("name")
        }
        
        guard let customerName = customerName, !customerName.isEmpty else {
            throw ProjectValidationError.missingRequiredField("customerName")
        }
        
        // Validate status
        let validStatuses = ["active", "completed", "on_hold", "cancelled"]
        if let status = status, !validStatuses.contains(status) {
            throw ProjectValidationError.invalidStatus
        }
        
        // Validate dates
        if let start = startDate, let end = endDate, start > end {
            throw ProjectValidationError.invalidDateRange
        }
        
        // Validate budget
        if let budget = budget, budget.doubleValue < 0 {
            throw ProjectValidationError.invalidBudget
        }
    }
    
    // MARK: - Conversion Methods
    func toAPIModel() -> ProjectAPIModel {
        return ProjectAPIModel(
            project_id: Int(serverID),
            name: name ?? "",
            description: descriptionText,
            customer_id: Int(customerID),
            customer_name: customerName ?? "",
            start_date: startDate,
            end_date: endDate,
            status: projectStatusEnum.rawValue,
            is_active: projectStatusEnum == .active,
            created_by: Int(createdBy),
            created_at: createdAt,
            updated_at: lastModified,
            supervisor_id: supervisor?.serverID != nil ? Int(supervisor!.serverID) : nil,
            supervisor_name: supervisor?.name,
            budget: budget?.doubleValue,
            client_equipment_type: clientEquipmentType,
            operator_requirements: operatorRequirements
        )
    }
    
    static func fromAPIModel(_ apiModel: ProjectAPIModel, context: NSManagedObjectContext) -> ProjectEntity {
        let entity = ProjectEntity(context: context)
        entity.updateFromAPIModel(apiModel)
        return entity
    }
    
    func updateFromAPIModel(_ apiModel: ProjectAPIModel) {
        serverID = Int32(apiModel.project_id)
        name = apiModel.name
        descriptionText = apiModel.description
        customerID = Int32(apiModel.customer_id)
        customerName = apiModel.customer_name
        startDate = apiModel.start_date
        endDate = apiModel.end_date
        status = apiModel.status ?? "active"
        createdBy = Int32(apiModel.created_by)
        clientEquipmentType = apiModel.client_equipment_type
        operatorRequirements = apiModel.operator_requirements
        
        if let budgetValue = apiModel.budget {
            budget = NSDecimalNumber(value: budgetValue)
        }
        
        lastModified = Date()
        syncStatusEnum = .synced
    }
    
    // MARK: - Conflict Resolution
    func resolveConflict(with serverVersion: ProjectAPIModel, strategy: ProjectConflictResolutionStrategy = .serverWins) {
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
    func calculateProgress() -> Double {
        guard let tasks = tasks as? Set<TaskEntity> else { return 0 }
        
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        
        return totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
    }
    
    func calculateBudgetUtilization() -> Double {
        guard let budget = budget, budget.doubleValue > 0 else { return 0 }
        
        // Calculate total spent from work entries
        let totalSpent = calculateTotalSpent()
        
        return (totalSpent / budget.doubleValue) * 100
    }
    
    private func calculateTotalSpent() -> Double {
        guard let workEntries = workEntries as? Set<WorkEntryEntity> else { return 0 }
        
        var total = 0.0
        for entry in workEntries {
            if let employee = entry.employee,
               let hours = entry.totalHours {
                let rate = employee.operatorNormalRate?.doubleValue ?? 0
                total += hours.doubleValue * rate
            }
        }
        
        return total
    }
    
    func isOverdue() -> Bool {
        guard let endDate = endDate else { return false }
        return endDate < Date() && projectStatusEnum != .completed
    }
    
    func daysRemaining() -> Int? {
        guard let endDate = endDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return components.day
    }
}

// MARK: - Supporting Types
struct ProjectAPIModel {
    let project_id: Int
    let name: String
    let description: String?
    let customer_id: Int
    let customer_name: String
    let start_date: Date?
    let end_date: Date?
    let status: String?
    let is_active: Bool
    let created_by: Int
    let created_at: Date?
    let updated_at: Date?
    let supervisor_id: Int?
    let supervisor_name: String?
    let budget: Double?
    let client_equipment_type: String?
    let operator_requirements: String?
}

enum ProjectValidationError: LocalizedError {
    case missingRequiredField(String)
    case invalidStatus
    case invalidDateRange
    case invalidBudget
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Required field '\(field)' is missing"
        case .invalidStatus:
            return "Invalid project status"
        case .invalidDateRange:
            return "Start date must be before end date"
        case .invalidBudget:
            return "Budget cannot be negative"
        }
    }
}

enum ProjectConflictResolutionStrategy {
    case serverWins
    case localWins
    case merge
}