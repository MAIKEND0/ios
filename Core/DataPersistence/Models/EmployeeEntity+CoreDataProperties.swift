//
//  EmployeeEntity+CoreDataProperties.swift
//  KSR Cranes App
//
//  Created by KSR Cranes on 2025-06-11.
//
//

import Foundation
import CoreData

extension EmployeeEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EmployeeEntity> {
        return NSFetchRequest<EmployeeEntity>(entityName: "EmployeeEntity")
    }
    
    // MARK: - Core Properties
    @NSManaged public var localID: String?
    @NSManaged public var serverID: Int32
    @NSManaged public var name: String?
    @NSManaged public var email: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var address: String?
    @NSManaged public var role: String?
    @NSManaged public var isActivated: Bool
    @NSManaged public var profilePictureUrl: String?
    
    // MARK: - Rate Properties
    @NSManaged public var operatorNormalRate: NSDecimalNumber?
    @NSManaged public var operatorOvertimeRate1: NSDecimalNumber?
    @NSManaged public var operatorOvertimeRate2: NSDecimalNumber?
    @NSManaged public var operatorWeekendRate: NSDecimalNumber?
    
    // MARK: - Sync Properties
    @NSManaged public var syncStatus: String?
    @NSManaged public var lastModified: Date?
    @NSManaged public var syncError: String?
    @NSManaged public var syncRetryCount: Int16
    
    // MARK: - Timestamp Properties
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // MARK: - Relationships
    @NSManaged public var workEntries: NSSet?
    @NSManaged public var taskAssignments: NSSet?
    @NSManaged public var leaveRequests: NSSet?
    @NSManaged public var managedProjects: NSSet?
}

// MARK: - Generated accessors for workEntries
extension EmployeeEntity {
    
    @objc(addWorkEntriesObject:)
    @NSManaged public func addToWorkEntries(_ value: WorkEntryEntity)
    
    @objc(removeWorkEntriesObject:)
    @NSManaged public func removeFromWorkEntries(_ value: WorkEntryEntity)
    
    @objc(addWorkEntries:)
    @NSManaged public func addToWorkEntries(_ values: NSSet)
    
    @objc(removeWorkEntries:)
    @NSManaged public func removeFromWorkEntries(_ values: NSSet)
}

// MARK: - Generated accessors for taskAssignments
extension EmployeeEntity {
    
    @objc(addTaskAssignmentsObject:)
    @NSManaged public func addToTaskAssignments(_ value: TaskEntity)
    
    @objc(removeTaskAssignmentsObject:)
    @NSManaged public func removeFromTaskAssignments(_ value: TaskEntity)
    
    @objc(addTaskAssignments:)
    @NSManaged public func addToTaskAssignments(_ values: NSSet)
    
    @objc(removeTaskAssignments:)
    @NSManaged public func removeFromTaskAssignments(_ values: NSSet)
}

// MARK: - Generated accessors for leaveRequests
extension EmployeeEntity {
    
    @objc(addLeaveRequestsObject:)
    @NSManaged public func addToLeaveRequests(_ value: LeaveRequestEntity)
    
    @objc(removeLeaveRequestsObject:)
    @NSManaged public func removeFromLeaveRequests(_ value: LeaveRequestEntity)
    
    @objc(addLeaveRequests:)
    @NSManaged public func addToLeaveRequests(_ values: NSSet)
    
    @objc(removeLeaveRequests:)
    @NSManaged public func removeFromLeaveRequests(_ values: NSSet)
}

// MARK: - Generated accessors for managedProjects
extension EmployeeEntity {
    
    @objc(addManagedProjectsObject:)
    @NSManaged public func addToManagedProjects(_ value: ProjectEntity)
    
    @objc(removeManagedProjectsObject:)
    @NSManaged public func removeFromManagedProjects(_ value: ProjectEntity)
    
    @objc(addManagedProjects:)
    @NSManaged public func addToManagedProjects(_ values: NSSet)
    
    @objc(removeManagedProjects:)
    @NSManaged public func removeFromManagedProjects(_ values: NSSet)
}

// MARK: - Convenience Methods
extension EmployeeEntity {
    
    var workEntriesArray: [WorkEntryEntity] {
        let set = workEntries as? Set<WorkEntryEntity> ?? []
        return Array(set)
    }
    
    var taskAssignmentsArray: [TaskEntity] {
        let set = taskAssignments as? Set<TaskEntity> ?? []
        return Array(set)
    }
    
    var leaveRequestsArray: [LeaveRequestEntity] {
        let set = leaveRequests as? Set<LeaveRequestEntity> ?? []
        return Array(set)
    }
    
    var managedProjectsArray: [ProjectEntity] {
        let set = managedProjects as? Set<ProjectEntity> ?? []
        return Array(set)
    }
}