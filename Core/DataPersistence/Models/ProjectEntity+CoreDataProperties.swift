//
//  ProjectEntity+CoreDataProperties.swift
//  KSR Cranes App
//
//  Created by KSR Cranes on 2025-06-11.
//
//

import Foundation
import CoreData

extension ProjectEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProjectEntity> {
        return NSFetchRequest<ProjectEntity>(entityName: "ProjectEntity")
    }
    
    // MARK: - Core Properties
    @NSManaged public var localID: String?
    @NSManaged public var serverID: Int32
    @NSManaged public var name: String?
    @NSManaged public var descriptionText: String?
    @NSManaged public var customerID: Int32
    @NSManaged public var customerName: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var status: String?
    @NSManaged public var createdBy: Int32
    @NSManaged public var budget: NSDecimalNumber?
    @NSManaged public var clientEquipmentType: String?
    @NSManaged public var operatorRequirements: String?
    
    // MARK: - Sync Properties
    @NSManaged public var syncStatus: String?
    @NSManaged public var lastModified: Date?
    @NSManaged public var syncError: String?
    @NSManaged public var syncRetryCount: Int16
    
    // MARK: - Timestamp Properties
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // MARK: - Relationships
    @NSManaged public var supervisor: EmployeeEntity?
    @NSManaged public var tasks: NSSet?
    @NSManaged public var workEntries: NSSet?
}

// MARK: - Generated accessors for tasks
extension ProjectEntity {
    
    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: TaskEntity)
    
    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: TaskEntity)
    
    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)
    
    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)
}

// MARK: - Generated accessors for workEntries
extension ProjectEntity {
    
    @objc(addWorkEntriesObject:)
    @NSManaged public func addToWorkEntries(_ value: WorkEntryEntity)
    
    @objc(removeWorkEntriesObject:)
    @NSManaged public func removeFromWorkEntries(_ value: WorkEntryEntity)
    
    @objc(addWorkEntries:)
    @NSManaged public func addToWorkEntries(_ values: NSSet)
    
    @objc(removeWorkEntries:)
    @NSManaged public func removeFromWorkEntries(_ values: NSSet)
}

// MARK: - Fetch Request Helpers
extension ProjectEntity {
    
    static func fetchRequestForActive() -> NSFetchRequest<ProjectEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "active")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        return request
    }
    
    static func fetchRequestForSupervisor(_ supervisorID: Int32) -> NSFetchRequest<ProjectEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "supervisor.serverID == %d", supervisorID)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        return request
    }
    
    static func fetchRequestForCustomer(_ customerID: Int32) -> NSFetchRequest<ProjectEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "customerID == %d", customerID)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        return request
    }
    
    static func fetchRequestForDateRange(from startDate: Date, to endDate: Date) -> NSFetchRequest<ProjectEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "(startDate >= %@ AND startDate <= %@) OR (endDate >= %@ AND endDate <= %@)",
                                       startDate as NSDate, endDate as NSDate,
                                       startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        return request
    }
    
    static func fetchRequestForPendingSync() -> NSFetchRequest<ProjectEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", "pending")
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: true)]
        return request
    }
}

// MARK: - Convenience Methods
extension ProjectEntity {
    
    var tasksArray: [TaskEntity] {
        let set = tasks as? Set<TaskEntity> ?? []
        return Array(set)
    }
    
    var workEntriesArray: [WorkEntryEntity] {
        let set = workEntries as? Set<WorkEntryEntity> ?? []
        return Array(set)
    }
    
    var isActive: Bool {
        return status == "active"
    }
    
    var isCompleted: Bool {
        return status == "completed"
    }
    
    var formattedDuration: String {
        guard let start = startDate, let end = endDate else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    var taskCount: Int {
        return tasksArray.count
    }
    
    var completedTaskCount: Int {
        return tasksArray.filter { $0.isCompleted }.count
    }
    
    var activeTaskCount: Int {
        return tasksArray.filter { $0.isActive }.count
    }
    
    var totalWorkHours: Double {
        return workEntriesArray.reduce(0) { total, entry in
            total + (entry.totalHours?.doubleValue ?? 0)
        }
    }
}