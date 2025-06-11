//
//  EmployeeEntity+CoreDataClass.swift
//  KSR Cranes App
//
//  Created by KSR Cranes on 2025-06-11.
//
//

import Foundation
import CoreData

@objc(EmployeeEntity)
public class EmployeeEntity: NSManagedObject {
    
    // MARK: - Sync Status
    enum SyncStatus: String {
        case pending = "pending"
        case synced = "synced"
        case error = "error"
        case conflict = "conflict"
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
    
    // MARK: - Validation
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try validateEmployee()
    }
    
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateEmployee()
    }
    
    private func validateEmployee() throws {
        // Validate required fields
        guard let name = name, !name.isEmpty else {
            throw EmployeeValidationError.missingRequiredField("name")
        }
        
        guard let email = email, !email.isEmpty else {
            throw EmployeeValidationError.missingRequiredField("email")
        }
        
        // Validate email format
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        guard emailPred.evaluate(with: email) else {
            throw EmployeeValidationError.invalidEmail
        }
        
        // Validate role
        let validRoles = ["arbejder", "byggeleder", "chef", "system"]
        if let role = role, !validRoles.contains(role) {
            throw EmployeeValidationError.invalidRole
        }
    }
    
    // MARK: - Conversion Methods
    func toAPIModel() -> EmployeeAPIModel {
        return EmployeeAPIModel(
            employee_id: Int(serverID),
            name: name ?? "",
            email: email ?? "",
            phone_number: phoneNumber,
            address: address,
            role: role ?? "arbejder",
            is_activated: isActivated,
            profilePictureUrl: profilePictureUrl,
            operator_normal_rate: operatorNormalRate?.doubleValue,
            operator_overtime_rate1: operatorOvertimeRate1?.doubleValue,
            operator_overtime_rate2: operatorOvertimeRate2?.doubleValue,
            operator_weekend_rate: operatorWeekendRate?.doubleValue,
            created_at: createdAt,
            updated_at: lastModified
        )
    }
    
    static func fromAPIModel(_ apiModel: EmployeeAPIModel, context: NSManagedObjectContext) -> EmployeeEntity {
        let entity = EmployeeEntity(context: context)
        entity.updateFromAPIModel(apiModel)
        return entity
    }
    
    func updateFromAPIModel(_ apiModel: EmployeeAPIModel) {
        serverID = Int32(apiModel.employee_id)
        name = apiModel.name
        email = apiModel.email
        phoneNumber = apiModel.phone_number
        address = apiModel.address
        role = apiModel.role
        isActivated = apiModel.is_activated
        profilePictureUrl = apiModel.profilePictureUrl
        
        if let normalRate = apiModel.operator_normal_rate {
            operatorNormalRate = NSDecimalNumber(value: normalRate)
        }
        if let overtimeRate1 = apiModel.operator_overtime_rate1 {
            operatorOvertimeRate1 = NSDecimalNumber(value: overtimeRate1)
        }
        if let overtimeRate2 = apiModel.operator_overtime_rate2 {
            operatorOvertimeRate2 = NSDecimalNumber(value: overtimeRate2)
        }
        if let weekendRate = apiModel.operator_weekend_rate {
            operatorWeekendRate = NSDecimalNumber(value: weekendRate)
        }
        
        lastModified = Date()
        syncStatusEnum = .synced
    }
    
    // MARK: - Conflict Resolution
    func resolveConflict(with serverVersion: EmployeeAPIModel, strategy: EmployeeConflictResolutionStrategy = .serverWins) {
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
}

// MARK: - Supporting Types
struct EmployeeAPIModel {
    let employee_id: Int
    let name: String
    let email: String
    let phone_number: String?
    let address: String?
    let role: String
    let is_activated: Bool
    let profilePictureUrl: String?
    let operator_normal_rate: Double?
    let operator_overtime_rate1: Double?
    let operator_overtime_rate2: Double?
    let operator_weekend_rate: Double?
    let created_at: Date?
    let updated_at: Date?
}

enum EmployeeValidationError: LocalizedError {
    case missingRequiredField(String)
    case invalidEmail
    case invalidRole
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Required field '\(field)' is missing"
        case .invalidEmail:
            return "Invalid email format"
        case .invalidRole:
            return "Invalid role specified"
        }
    }
}

enum EmployeeConflictResolutionStrategy {
    case serverWins
    case localWins
    case merge
}