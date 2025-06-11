//
//  SyncOperation.swift
//  KSR Cranes App
//
//  Created by Sync Engine on 06/11/2025.
//

import Foundation
import CoreData
import Combine

/// Base class for sync operations
class SyncOperation: Operation, @unchecked Sendable {
    
    // MARK: - Properties
    
    /// Unique identifier for this operation
    let operationId = UUID()
    
    /// Type of sync operation
    let operationType: SyncOperationType
    
    /// Entity type being synced
    let entityType: SyncEntityType
    
    /// Timestamp when operation was created
    let createdAt = Date()
    
    /// Number of retry attempts
    private(set) var retryCount = 0
    
    /// Maximum retry attempts
    let maxRetries: Int = 3
    
    /// Current sync status
    @Published private(set) var status: SyncOperationStatus = .pending
    
    /// Error if operation failed
    private(set) var error: Error?
    
    /// Core Data context for this operation
    let context: NSManagedObjectContext
    
    /// Progress tracking
    @Published private(set) var progress: Double = 0.0
    
    /// Completion handler
    var completionHandler: ((Result<Void, Error>) -> Void)?
    
    // MARK: - Initialization
    
    init(operationType: SyncOperationType,
         entityType: SyncEntityType,
         context: NSManagedObjectContext) {
        self.operationType = operationType
        self.entityType = entityType
        self.context = context
        super.init()
        
        self.qualityOfService = .utility
        self.queuePriority = operationType.priority
    }
    
    // MARK: - Operation Lifecycle
    
    override func main() {
        guard !isCancelled else {
            status = .cancelled
            completionHandler?(.failure(SyncError.cancelled))
            return
        }
        
        status = .syncing
        
        #if DEBUG
        print("[SyncOperation] 🔄 Starting \(operationType) for \(entityType)")
        #endif
        
        do {
            try performSync()
            
            if !isCancelled {
                status = .completed
                completionHandler?(.success(()))
                
                #if DEBUG
                print("[SyncOperation] ✅ Completed \(operationType) for \(entityType)")
                #endif
            }
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Sync Implementation (Override in subclasses)
    
    /// Perform the actual sync operation
    /// Subclasses must override this method
    func performSync() throws {
        fatalError("Subclasses must implement performSync()")
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        self.error = error
        
        #if DEBUG
        print("[SyncOperation] ❌ Error in \(operationType) for \(entityType): \(error)")
        #endif
        
        // Check if we should retry
        if shouldRetry(for: error) && retryCount < maxRetries {
            retryCount += 1
            status = .retrying
            
            #if DEBUG
            print("[SyncOperation] 🔁 Retrying \(operationType) for \(entityType) (attempt \(retryCount))")
            #endif
            
            // Wait before retry with exponential backoff
            let delay = pow(2.0, Double(retryCount))
            Thread.sleep(forTimeInterval: delay)
            
            // Retry the operation
            if !isCancelled {
                main()
            }
        } else {
            status = .failed
            completionHandler?(.failure(error))
        }
    }
    
    /// Determine if operation should be retried for given error
    private func shouldRetry(for error: Error) -> Bool {
        // Network errors are retryable
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .timedOut,
                 .cannotConnectToHost:
                return true
            default:
                return false
            }
        }
        
        // API errors
        if let apiError = error as? BaseAPIService.APIError {
            switch apiError {
            case .networkError:
                return true
            case .serverError(let code, _):
                // Retry on 5xx errors and rate limiting
                return code >= 500 || code == 429
            default:
                return false
            }
        }
        
        return false
    }
    
    // MARK: - Progress Tracking
    
    /// Update operation progress
    func updateProgress(_ value: Double) {
        progress = min(max(value, 0.0), 1.0)
    }
    
    // MARK: - Cancellation
    
    override func cancel() {
        super.cancel()
        status = .cancelled
        
        #if DEBUG
        print("[SyncOperation] 🛑 Cancelled \(operationType) for \(entityType)")
        #endif
    }
}

// MARK: - Sync Operation Types

enum SyncOperationType: String, CaseIterable {
    case upload = "upload"
    case download = "download"
    case update = "update"
    case delete = "delete"
    case fullSync = "fullSync"
    
    var priority: Operation.QueuePriority {
        switch self {
        case .delete: return .veryHigh
        case .update: return .high
        case .upload: return .normal
        case .download: return .low
        case .fullSync: return .veryLow
        }
    }
}

// MARK: - Sync Entity Types

enum SyncEntityType: String, CaseIterable {
    case employee = "Employee"
    case project = "Project"
    case task = "Task"
    case workEntry = "WorkEntry"
    case leaveRequest = "LeaveRequest"
    case notification = "Notification"
    case all = "All"
    
    var displayName: String {
        switch self {
        case .employee: return "Employees"
        case .project: return "Projects"
        case .task: return "Tasks"
        case .workEntry: return "Work Entries"
        case .leaveRequest: return "Leave Requests"
        case .notification: return "Notifications"
        case .all: return "All Data"
        }
    }
}

// MARK: - Sync Status

enum SyncOperationStatus: String {
    case pending = "pending"
    case syncing = "syncing"
    case retrying = "retrying"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var isActive: Bool {
        switch self {
        case .syncing, .retrying:
            return true
        default:
            return false
        }
    }
    
    var isFinished: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        default:
            return false
        }
    }
}

// MARK: - Sync Errors

enum SyncError: LocalizedError {
    case noNetwork
    case authenticationRequired
    case serverUnavailable
    case dataConflict(String)
    case invalidData(String)
    case quotaExceeded
    case cancelled
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noNetwork:
            return "No network connection available"
        case .authenticationRequired:
            return "Authentication required. Please log in again."
        case .serverUnavailable:
            return "Server is currently unavailable"
        case .dataConflict(let details):
            return "Data conflict: \(details)"
        case .invalidData(let details):
            return "Invalid data: \(details)"
        case .quotaExceeded:
            return "Sync quota exceeded. Please try again later."
        case .cancelled:
            return "Sync operation was cancelled"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noNetwork:
            return "Check your internet connection and try again"
        case .authenticationRequired:
            return "Please log in to continue syncing"
        case .serverUnavailable:
            return "Please try again in a few minutes"
        case .dataConflict:
            return "Conflicts will be resolved automatically"
        case .invalidData:
            return "Please contact support if this persists"
        case .quotaExceeded:
            return "Wait for quota reset or upgrade your plan"
        case .cancelled:
            return "Restart sync when ready"
        case .unknown:
            return "Please try again or contact support"
        }
    }
}