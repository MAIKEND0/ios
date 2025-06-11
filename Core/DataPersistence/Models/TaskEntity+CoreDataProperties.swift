//
//  TaskEntity+CoreDataProperties.swift
//  KSR Cranes App
//
//  Created by KSR Cranes on 2025-06-11.
//
//

import Foundation
import CoreData

extension TaskEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }
    
    // MARK: - Core Properties
    @NSManaged public var localID: String?
    @NSManaged public var serverID: Int32
    @NSManaged public var name: String?
    @NSManaged public var descriptionText: String?
    @NSManaged public var deadline: Date?
    @NSManaged public var startDate: Date?
    @NSManaged public var status: String?
    @NSManaged public var priority: String?
    @NSManaged public var requiredOperators: Int32
    @NSManaged public var estimatedHours: NSDecimalNumber?
    @NSManaged public var clientEquipmentInfo: String?
    @NSManaged public var equipment: String?
    
    // MARK: - Sync Properties
    @NSManaged public var syncStatus: String?
    @NSManaged public var lastModified: Date?
    @NSManaged public var syncError: String?
    @NSManaged public var syncRetryCount: Int16
    
    // MARK: - Timestamp Properties
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // MARK: - Relationships
    @NSManaged public var project: ProjectEntity?
    @NSManaged public var workEntries: NSSet?
    @NSManaged public var assignedOperators: NSSet?
    @NSManaged public var taskAssignments: NSSet?
}

// MARK: - Generated accessors for workEntries
extension TaskEntity {
    
    @objc(addWorkEntriesObject:)
    @NSManaged public func addToWorkEntries(_ value: WorkEntryEntity)
    
    @objc(removeWorkEntriesObject:)
    @NSManaged public func removeFromWorkEntries(_ value: WorkEntryEntity)
    
    @objc(addWorkEntries:)
    @NSManaged public func addToWorkEntries(_ values: NSSet)
    
    @objc(removeWorkEntries:)
    @NSManaged public func removeFromWorkEntries(_ values: NSSet)
}

// MARK: - Generated accessors for assignedOperators
extension TaskEntity {
    
    @objc(addAssignedOperatorsObject:)
    @NSManaged public func addToAssignedOperators(_ value: EmployeeEntity)
    
    @objc(removeAssignedOperatorsObject:)
    @NSManaged public func removeFromAssignedOperators(_ value: EmployeeEntity)
    
    @objc(addAssignedOperators:)
    @NSManaged public func addToAssignedOperators(_ values: NSSet)
    
    @objc(removeAssignedOperators:)
    @NSManaged public func removeFromAssignedOperators(_ values: NSSet)
}

// MARK: - Generated accessors for taskAssignments
extension TaskEntity {
    
    @objc(addTaskAssignmentsObject:)
    @NSManaged public func addToTaskAssignments(_ value: TaskAssignmentEntity)
    
    @objc(removeTaskAssignmentsObject:)
    @NSManaged public func removeFromTaskAssignments(_ value: TaskAssignmentEntity)
    
    @objc(addTaskAssignments:)
    @NSManaged public func addToTaskAssignments(_ values: NSSet)
    
    @objc(removeTaskAssignments:)
    @NSManaged public func removeFromTaskAssignments(_ values: NSSet)
}

// MARK: - Fetch Request Helpers
extension TaskEntity {
    
    static func fetchRequestForProject(_ projectID: Int32) -> NSFetchRequest<TaskEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "project.serverID == %d", projectID)
        request.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false),
                                   NSSortDescriptor(key: "deadline", ascending: true)]
        return request
    }
    
    static func fetchRequestForStatus(_ status: String) -> NSFetchRequest<TaskEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", status)
        request.sortDescriptors = [NSSortDescriptor(key: "deadline", ascending: true)]
        return request
    }
    
    static func fetchRequestForOperator(_ operatorID: Int32) -> NSFetchRequest<TaskEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "ANY assignedOperators.serverID == %d", operatorID)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        return request
    }
    
    static func fetchRequestForPendingSync() -> NSFetchRequest<TaskEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", "pending")
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: true)]
        return request
    }
}

// MARK: - Convenience Methods
extension TaskEntity {
    
    var workEntriesArray: [WorkEntryEntity] {
        let set = workEntries as? Set<WorkEntryEntity> ?? []
        return Array(set)
    }
    
    var assignedOperatorsArray: [EmployeeEntity] {
        let set = assignedOperators as? Set<EmployeeEntity> ?? []
        return Array(set)
    }
    
    var taskAssignmentsArray: [TaskAssignmentEntity] {
        let set = taskAssignments as? Set<TaskAssignmentEntity> ?? []
        return Array(set)
    }
    
    var isCompleted: Bool {
        return status == "completed"
    }
    
    var isActive: Bool {
        return status == "in_progress"
    }
    
    var isOverdue: Bool {
        guard let deadline = deadline else { return false }
        return deadline < Date() && !isCompleted
    }
    
    var formattedDeadline: String {
        guard let date = deadline else { return "No deadline" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var formattedStartDate: String {
        guard let date = startDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var assignedOperatorCount: Int {
        return assignedOperatorsArray.count
    }
    
    var hasEnoughOperators: Bool {
        return assignedOperatorCount >= Int(requiredOperators)
    }
}

// MARK: - TaskAssignmentEntity (Intermediate entity)
@objc(TaskAssignmentEntity)
public class TaskAssignmentEntity: NSManagedObject {
    @NSManaged public var localID: String?
    @NSManaged public var serverID: Int32
    @NSManaged public var workDate: Date?
    @NSManaged public var status: String?
    @NSManaged public var notes: String?
    @NSManaged public var task: TaskEntity?
    @NSManaged public var operatorEmployee: EmployeeEntity?
    @NSManaged public var syncStatus: String?
    @NSManaged public var lastModified: Date?
}