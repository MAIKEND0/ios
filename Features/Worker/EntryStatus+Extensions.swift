//
//  EntryStatus+Extensions.swift
//  KSR Cranes App
//
//  Extensions for existing EntryStatus enum from WorkHourEntry.swift
//

import Foundation
import SwiftUI

// MARK: - EntryStatus Extensions
extension EntryStatus: CaseIterable {
    /// All cases for iteration
    static var allCases: [EntryStatus] {
        return [.draft, .pending, .submitted, .confirmed, .rejected]
    }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .draft:
            return "Draft"
        case .pending:
            return "Pending"
        case .submitted:
            return "Submitted"
        case .confirmed:
            return "Confirmed"
        case .rejected:
            return "Rejected"
        }
    }
    
    /// Description of what this status means
    var description: String {
        switch self {
        case .draft:
            return "Entry is saved but not yet submitted"
        case .pending:
            return "Entry is waiting for review"
        case .submitted:
            return "Entry has been submitted for approval"
        case .confirmed:
            return "Entry has been approved by supervisor"
        case .rejected:
            return "Entry was rejected and needs corrections"
        }
    }
    
    /// Associated color for this status (using existing KSR colors)
    var color: Color {
        switch self {
        case .draft:
            return .ksrWarning
        case .pending:
            return .ksrInfo
        case .submitted:
            return .ksrPrimary
        case .confirmed:
            return .ksrSuccess
        case .rejected:
            return .ksrError
        }
    }
    
    /// System icon for this status
    var icon: String {
        switch self {
        case .draft:
            return "pencil.circle"
        case .pending:
            return "clock"
        case .submitted:
            return "paperplane"
        case .confirmed:
            return "checkmark.circle"
        case .rejected:
            return "xmark.circle"
        }
    }
    
    /// Priority order for sorting (higher number = more important)
    var priority: Int {
        switch self {
        case .rejected:
            return 5
        case .draft:
            return 4
        case .pending:
            return 3
        case .submitted:
            return 2
        case .confirmed:
            return 1
        }
    }
    
    /// Whether this status allows editing
    var isEditable: Bool {
        switch self {
        case .draft, .rejected:
            return true
        case .pending, .submitted, .confirmed:
            return false
        }
    }
    
    /// Whether this status is considered "active" (needs attention)
    var isActive: Bool {
        switch self {
        case .draft, .pending, .submitted, .rejected:
            return true
        case .confirmed:
            return false
        }
    }
    
    /// Whether this status is final (no more changes expected)
    var isFinal: Bool {
        switch self {
        case .confirmed:
            return true
        case .draft, .pending, .submitted, .rejected:
            return false
        }
    }
}

// MARK: - Helper Functions for WorkerAPIService.WorkHourEntry

/// Determines the effective status for a work entry based on various fields
/// - Parameter entry: The work entry to analyze
/// - Returns: The effective EntryStatus
func effectiveStatus(for entry: WorkerAPIService.WorkHourEntry) -> EntryStatus {
    // First check confirmation_status if it exists and is not "pending"
    if let confirmationStatus = entry.confirmation_status, confirmationStatus != "pending" {
        switch confirmationStatus {
        case "confirmed":
            return .confirmed
        case "rejected":
            return .rejected
        default:
            break // Unknown status, continue with other logic
        }
    }
    
    // If confirmation_status is "pending" or nil, check is_draft
    if entry.is_draft == true {
        return .draft
    }
    
    // Then use status to distinguish between pending/submitted
    if let status = entry.status {
        switch status {
        case "submitted":
            return .submitted
        case "pending":
            return .pending
        default:
            break
        }
    }
    
    // Default to pending
    return .pending
}

/// Determines the effective status for a WorkHourEntry model
/// - Parameter entry: The work hour entry to analyze
/// - Returns: The effective EntryStatus
func effectiveStatus(for entry: WorkHourEntry) -> EntryStatus {
    // If it's marked as draft, return draft
    if entry.isDraft {
        return .draft
    }
    
    // Otherwise return the status from the model
    return entry.status
}

/// Filters WorkerAPIService entries by status
/// - Parameters:
///   - entries: Array of work entries
///   - status: Status to filter by
/// - Returns: Filtered array
func filterEntries(_ entries: [WorkerAPIService.WorkHourEntry], by status: EntryStatus) -> [WorkerAPIService.WorkHourEntry] {
    return entries.filter { effectiveStatus(for: $0) == status }
}

/// Filters WorkHourEntry models by status
/// - Parameters:
///   - entries: Array of work entries
///   - status: Status to filter by
/// - Returns: Filtered array
func filterEntries(_ entries: [WorkHourEntry], by status: EntryStatus) -> [WorkHourEntry] {
    return entries.filter { effectiveStatus(for: $0) == status }
}

/// Groups WorkerAPIService entries by their effective status
/// - Parameter entries: Array of work entries
/// - Returns: Dictionary grouped by status
func groupEntriesByStatus(_ entries: [WorkerAPIService.WorkHourEntry]) -> [EntryStatus: [WorkerAPIService.WorkHourEntry]] {
    return Dictionary(grouping: entries) { effectiveStatus(for: $0) }
}

/// Groups WorkHourEntry models by their effective status
/// - Parameter entries: Array of work entries
/// - Returns: Dictionary grouped by status
func groupEntriesByStatus(_ entries: [WorkHourEntry]) -> [EntryStatus: [WorkHourEntry]] {
    return Dictionary(grouping: entries) { effectiveStatus(for: $0) }
}

/// Gets status statistics for WorkerAPIService entries
/// - Parameter entries: Array of work entries
/// - Returns: Dictionary with count for each status
func getStatusStatistics(for entries: [WorkerAPIService.WorkHourEntry]) -> [EntryStatus: Int] {
    let grouped = groupEntriesByStatus(entries)
    var stats: [EntryStatus: Int] = [:]
    
    for status in EntryStatus.allCases {
        stats[status] = grouped[status]?.count ?? 0
    }
    
    return stats
}

/// Gets status statistics for WorkHourEntry models
/// - Parameter entries: Array of work entries
/// - Returns: Dictionary with count for each status
func getStatusStatistics(for entries: [WorkHourEntry]) -> [EntryStatus: Int] {
    let grouped = groupEntriesByStatus(entries)
    var stats: [EntryStatus: Int] = [:]
    
    for status in EntryStatus.allCases {
        stats[status] = grouped[status]?.count ?? 0
    }
    
    return stats
}

/// Gets the most critical status from WorkerAPIService entries
/// - Parameter entries: Array of work entries
/// - Returns: The status with highest priority, or nil if empty
func getMostCriticalStatus(from entries: [WorkerAPIService.WorkHourEntry]) -> EntryStatus? {
    let statuses = entries.map { effectiveStatus(for: $0) }
    return statuses.max { $0.priority < $1.priority }
}

/// Gets the most critical status from WorkHourEntry models
/// - Parameter entries: Array of work entries
/// - Returns: The status with highest priority, or nil if empty
func getMostCriticalStatus(from entries: [WorkHourEntry]) -> EntryStatus? {
    let statuses = entries.map { effectiveStatus(for: $0) }
    return statuses.max { $0.priority < $1.priority }
}

// MARK: - Array Extensions

extension Array where Element == WorkerAPIService.WorkHourEntry {
    /// Convenience method to get status statistics
    var statusStatistics: [EntryStatus: Int] {
        return getStatusStatistics(for: self)
    }
    
    /// Convenience method to filter by status
    func filtered(by status: EntryStatus) -> [WorkerAPIService.WorkHourEntry] {
        return filterEntries(self, by: status)
    }
    
    /// Convenience method to group by status
    var groupedByStatus: [EntryStatus: [WorkerAPIService.WorkHourEntry]] {
        return groupEntriesByStatus(self)
    }
    
    /// Gets the most critical status from this array
    var mostCriticalStatus: EntryStatus? {
        return getMostCriticalStatus(from: self)
    }
    
    /// Gets count of entries needing attention (draft, rejected, pending)
    var entriesNeedingAttentionCount: Int {
        return filter { effectiveStatus(for: $0).isActive }.count
    }
    
    /// Gets count of finalized entries (confirmed)
    var finalizedEntriesCount: Int {
        return filter { effectiveStatus(for: $0).isFinal }.count
    }
}

extension Array where Element == WorkHourEntry {
    /// Convenience method to get status statistics
    var statusStatistics: [EntryStatus: Int] {
        return getStatusStatistics(for: self)
    }
    
    /// Convenience method to filter by status
    func filtered(by status: EntryStatus) -> [WorkHourEntry] {
        return filterEntries(self, by: status)
    }
    
    /// Convenience method to group by status
    var groupedByStatus: [EntryStatus: [WorkHourEntry]] {
        return groupEntriesByStatus(self)
    }
    
    /// Gets the most critical status from this array
    var mostCriticalStatus: EntryStatus? {
        return getMostCriticalStatus(from: self)
    }
    
    /// Gets count of entries needing attention (draft, rejected, pending)
    var entriesNeedingAttentionCount: Int {
        return filter { effectiveStatus(for: $0).isActive }.count
    }
    
    /// Gets count of finalized entries (confirmed)
    var finalizedEntriesCount: Int {
        return filter { effectiveStatus(for: $0).isFinal }.count
    }
}
