import Foundation
import CoreData
import Combine

/// Protocol defining offline data access methods for ViewModels
protocol OfflineDataProvider {
    associatedtype DataType
    
    /// Load data from Core Data when offline
    func loadOfflineData() async throws -> [DataType]
    
    /// Save data to Core Data for offline access
    func saveForOffline(_ data: [DataType]) async throws
    
    /// Sync local changes with server
    func syncPendingChanges() async throws
    
    /// Check if there are unsynced local changes
    var hasPendingChanges: Bool { get }
    
    /// Publisher for sync status updates
    var syncStatusPublisher: AnyPublisher<OfflineSyncStatus, Never> { get }
}

/// Sync status for offline data
enum OfflineSyncStatus: Equatable {
    case idle
    case syncing
    case synced
    case syncFailed(Error)
    case offline
    
    static func == (lhs: OfflineSyncStatus, rhs: OfflineSyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.synced, .synced), (.offline, .offline):
            return true
        case (.syncFailed(_), .syncFailed(_)):
            return true
        default:
            return false
        }
    }
    
    var isLoading: Bool {
        if case .syncing = self { return true }
        return false
    }
    
    var hasError: Bool {
        if case .syncFailed(_) = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .syncFailed(let error) = self {
            return error.localizedDescription
        }
        return nil
    }
}

/// Base implementation helpers for offline support
extension OfflineDataProvider {
    
    /// Helper to perform offline-first data loading
    func loadDataOfflineFirst<T>(
        onlineLoader: @escaping () async throws -> T,
        offlineLoader: @escaping () async throws -> T,
        isConnected: Bool
    ) async throws -> T {
        if isConnected {
            do {
                let data = try await onlineLoader()
                // Save to offline storage after successful online load
                return data
            } catch {
                // Fall back to offline data on network error
                print("[OfflineDataProvider] Online load failed, falling back to offline: \(error)")
                return try await offlineLoader()
            }
        } else {
            // Load from offline storage when not connected
            return try await offlineLoader()
        }
    }
    
    /// Helper to handle optimistic updates
    func performOptimisticUpdate<T>(
        localUpdate: @escaping () async throws -> T,
        remoteUpdate: @escaping () async throws -> T,
        rollback: @escaping () async -> Void,
        isConnected: Bool
    ) async throws -> T {
        // First, perform local update
        let localResult = try await localUpdate()
        
        if isConnected {
            do {
                // Try to sync with server
                let remoteResult = try await remoteUpdate()
                return remoteResult
            } catch {
                // Rollback on sync failure
                await rollback()
                throw error
            }
        }
        
        // If offline, just return local result and mark for sync
        return localResult
    }
}

/// Network connectivity observer
class NetworkConnectivity: ObservableObject {
    static let shared = NetworkConnectivity()
    
    @Published var isConnected: Bool = true
    
    private init() {
        // Monitor network connectivity
        startMonitoring()
    }
    
    private func startMonitoring() {
        // This would use Network framework in production
        // For now, we'll simulate connectivity
    }
}

/// Core Data context provider for offline operations
protocol CoreDataContextProvider {
    var viewContext: NSManagedObjectContext { get }
    var backgroundContext: NSManagedObjectContext { get }
}

/// Extension to handle common offline operations
extension NSManagedObjectContext {
    
    /// Save context with proper error handling
    func saveIfNeeded() async throws {
        guard hasChanges else { return }
        
        try await perform { [weak self] in
            do {
                try self?.save()
            } catch {
                print("[CoreData] Save failed: \(error)")
                throw error
            }
        }
    }
    
    /// Perform batch delete with error handling
    func performBatchDelete<T: NSManagedObject>(
        _ request: NSFetchRequest<T>
    ) async throws {
        let batchDelete = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
        batchDelete.resultType = .resultTypeObjectIDs
        
        try await perform { [weak self] in
            guard let self = self else { return }
            
            let result = try self.execute(batchDelete) as? NSBatchDeleteResult
            guard let objectIDs = result?.result as? [NSManagedObjectID] else { return }
            
            let changes = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: changes,
                into: [self]
            )
        }
    }
}