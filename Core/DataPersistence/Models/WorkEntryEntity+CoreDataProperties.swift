//
//  WorkEntryEntity+CoreDataProperties.swift
//  KSR Cranes App
//
//  Created by KSR Cranes on 2025-06-11.
//
//

import Foundation
import CoreData

extension WorkEntryEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkEntryEntity> {
        return NSFetchRequest<WorkEntryEntity>(entityName: "WorkEntryEntity")
    }
    
    // MARK: - Core Properties
    @NSManaged public var localID: String?
    @NSManaged public var serverID: Int32
    @NSManaged public var workDate: Date?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var breakDuration: NSDecimalNumber?
    @NSManaged public var totalHours: NSDecimalNumber?
    @NSManaged public var regularHours: NSDecimalNumber?
    @NSManaged public var overtimeHours: NSDecimalNumber?
    @NSManaged public var notes: String?
    @NSManaged public var status: String?
    
    // MARK: - Approval Properties
    @NSManaged public var approvedBy: Int32
    @NSManaged public var approvedAt: Date?
    @NSManaged public var submittedAt: Date?
    @NSManaged public var rejectionReason: String?
    
    // MARK: - Sync Properties
    @NSManaged public var syncStatus: String?
    @NSManaged public var lastModified: Date?
    @NSManaged public var syncError: String?
    @NSManaged public var syncRetryCount: Int16
    
    // MARK: - Timestamp Properties
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // MARK: - Relationships
    @NSManaged public var employee: EmployeeEntity?
    @NSManaged public var project: ProjectEntity?
    @NSManaged public var task: TaskEntity?
}

// MARK: - Fetch Request Helpers
extension WorkEntryEntity {
    
    static func fetchRequestForEmployee(_ employeeID: Int32) -> NSFetchRequest<WorkEntryEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "employee.serverID == %d", employeeID)
        request.sortDescriptors = [NSSortDescriptor(key: "workDate", ascending: false)]
        return request
    }
    
    static func fetchRequestForDateRange(from startDate: Date, to endDate: Date) -> NSFetchRequest<WorkEntryEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "workDate >= %@ AND workDate <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "workDate", ascending: true)]
        return request
    }
    
    static func fetchRequestForPendingSync() -> NSFetchRequest<WorkEntryEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", "pending")
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: true)]
        return request
    }
    
    static func fetchRequestForProject(_ projectID: Int32) -> NSFetchRequest<WorkEntryEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "project.serverID == %d", projectID)
        request.sortDescriptors = [NSSortDescriptor(key: "workDate", ascending: false)]
        return request
    }
}

// MARK: - Convenience Methods
extension WorkEntryEntity {
    
    var isApproved: Bool {
        return status == "approved"
    }
    
    var isPending: Bool {
        return status == "pending"
    }
    
    var isRejected: Bool {
        return status == "rejected"
    }
    
    var needsModification: Bool {
        return status == "needs_modification"
    }
    
    var formattedWorkDate: String {
        guard let date = workDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var formattedTimeRange: String {
        guard let start = startTime, let end = endTime else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}