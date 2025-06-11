//
//  LeaveRequestEntity+CoreDataProperties.swift
//  KSR Cranes App
//
//  Created by KSR Cranes on 2025-06-11.
//
//

import Foundation
import CoreData

extension LeaveRequestEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LeaveRequestEntity> {
        return NSFetchRequest<LeaveRequestEntity>(entityName: "LeaveRequestEntity")
    }
    
    // MARK: - Core Properties
    @NSManaged public var localID: String?
    @NSManaged public var serverID: Int32
    @NSManaged public var type: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var totalDays: Int32
    @NSManaged public var halfDay: Bool
    @NSManaged public var status: String?
    @NSManaged public var reason: String?
    @NSManaged public var sickNoteUrl: String?
    @NSManaged public var emergencyLeave: Bool
    
    // MARK: - Approval Properties
    @NSManaged public var approvedBy: Int32
    @NSManaged public var approvedAt: Date?
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
    @NSManaged public var approver: EmployeeEntity?
}

// MARK: - Fetch Request Helpers
extension LeaveRequestEntity {
    
    static func fetchRequestForEmployee(_ employeeID: Int32) -> NSFetchRequest<LeaveRequestEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "employee.serverID == %d", employeeID)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        return request
    }
    
    static func fetchRequestForStatus(_ status: String) -> NSFetchRequest<LeaveRequestEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", status)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return request
    }
    
    static func fetchRequestForDateRange(from startDate: Date, to endDate: Date) -> NSFetchRequest<LeaveRequestEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "(startDate >= %@ AND startDate <= %@) OR (endDate >= %@ AND endDate <= %@)",
                                       startDate as NSDate, endDate as NSDate,
                                       startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        return request
    }
    
    static func fetchRequestForApprover(_ approverID: Int32) -> NSFetchRequest<LeaveRequestEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "approver.serverID == %d AND status == %@", approverID, "PENDING")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return request
    }
    
    static func fetchRequestForPendingSync() -> NSFetchRequest<LeaveRequestEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", "pending")
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: true)]
        return request
    }
    
    static func fetchRequestForUpcoming() -> NSFetchRequest<LeaveRequestEntity> {
        let request = fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        request.predicate = NSPredicate(format: "startDate > %@ AND status == %@", today as NSDate, "APPROVED")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        return request
    }
}

// MARK: - Convenience Methods
extension LeaveRequestEntity {
    
    var isPending: Bool {
        return status == "PENDING"
    }
    
    var isApproved: Bool {
        return status == "APPROVED"
    }
    
    var isRejected: Bool {
        return status == "REJECTED"
    }
    
    var isCancelled: Bool {
        return status == "CANCELLED"
    }
    
    var formattedDateRange: String {
        guard let start = startDate, let end = endDate else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        if start == end {
            return formatter.string(from: start)
        } else {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
    
    var daysUntilStart: Int? {
        guard let start = startDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: start)
        return components.day
    }
    
    var typeDisplayName: String {
        switch type?.lowercased() {
        case "vacation":
            return "Vacation"
        case "sick":
            return emergencyLeave ? "Emergency Sick Leave" : "Sick Leave"
        case "personal":
            return "Personal Day"
        case "parental":
            return "Parental Leave"
        case "compensatory":
            return "Compensatory Time"
        default:
            return type ?? "Unknown"
        }
    }
    
    var statusDisplayName: String {
        switch status?.lowercased() {
        case "pending":
            return "Pending"
        case "approved":
            return "Approved"
        case "rejected":
            return "Rejected"
        case "cancelled":
            return "Cancelled"
        case "expired":
            return "Expired"
        default:
            return status ?? "Unknown"
        }
    }
}