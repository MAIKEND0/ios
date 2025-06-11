//
//  SyncCoordinator.swift
//  KSR Cranes App
//
//  Created by Sync Engine on 06/11/2025.
//

import Foundation
import CoreData
import Combine

/// Coordinates sync operations across all entities
final class SyncCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncProgress: Double = 0.0
    @Published private(set) var syncStatus: String = "Ready"
    @Published private(set) var syncErrors: [SyncError] = []
    
    // MARK: - Properties
    
    /// Sync queue for managing operations
    private let syncQueue: SyncQueue
    
    /// Conflict resolver
    private let conflictResolver: ConflictResolver
    
    /// Network monitor
    private let networkMonitor = NetworkMonitor.shared
    
    /// Core Data stack
    private let coreDataStack = CoreDataStack.shared
    
    /// API services
    private var apiServices: [SyncEntityType: Any] = [:]
    
    /// Sync metadata storage
    private let metadataKey = "com.ksrcranes.sync.metadata"
    
    /// Timer for periodic sync
    private var syncTimer: Timer?
    
    /// Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// Sync interval in seconds (default: 5 minutes)
    var syncInterval: TimeInterval = 300
    
    /// Enable automatic sync
    @Published var isAutoSyncEnabled = true {
        didSet {
            isAutoSyncEnabled ? startAutoSync() : stopAutoSync()
        }
    }
    
    // MARK: - Initialization
    
    init() {
        self.syncQueue = SyncQueue(name: "MainSyncQueue", maxConcurrentOperations: 3)
        self.conflictResolver = ConflictResolver()
        
        setupAPIServices()
        setupConflictResolution()
        loadSyncMetadata()
        observeNetworkChanges()
        
        #if DEBUG
        print("[SyncCoordinator] ✅ Initialized")
        #endif
    }
    
    // MARK: - Setup
    
    private func setupAPIServices() {
        // Register API services for each entity type
        // These would be injected or configured based on user role
        
        #if DEBUG
        print("[SyncCoordinator] 📡 API services configured")
        #endif
    }
    
    private func setupConflictResolution() {
        conflictResolver.configureDefaultRules()
    }
    
    private func observeNetworkChanges() {
        networkMonitor.$isConnected
            .removeDuplicates()
            .sink { [weak self] isConnected in
                if isConnected && self?.isAutoSyncEnabled == true {
                    // Trigger sync when network becomes available
                    Task {
                        await self?.performIncrementalSync()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Perform a full sync of all entities
    @MainActor
    func performFullSync() async {
        guard networkMonitor.shouldAllowSync else {
            updateSyncStatus("No network connection")
            return
        }
        
        guard !isSyncing else {
            updateSyncStatus("Sync already in progress")
            return
        }
        
        isSyncing = true
        syncErrors.removeAll()
        updateSyncStatus("Starting full sync...")
        
        do {
            // Sync each entity type in order
            let entityTypes: [SyncEntityType] = [.employee, .project, .task, .workEntry, .leaveRequest, .notification]
            
            for (index, entityType) in entityTypes.enumerated() {
                updateSyncProgress(Double(index) / Double(entityTypes.count))
                updateSyncStatus("Syncing \(entityType.displayName)...")
                
                try await syncEntity(entityType, fullSync: true)
            }
            
            // Update metadata
            lastSyncDate = Date()
            saveSyncMetadata()
            
            updateSyncProgress(1.0)
            updateSyncStatus("Sync completed successfully")
            
            #if DEBUG
            print("[SyncCoordinator] ✅ Full sync completed")
            #endif
            
        } catch {
            handleSyncError(error)
        }
        
        isSyncing = false
    }
    
    /// Perform incremental sync based on last sync timestamp
    @MainActor
    func performIncrementalSync() async {
        guard networkMonitor.shouldAllowSync else {
            updateSyncStatus("No network connection")
            return
        }
        
        guard !isSyncing else {
            updateSyncStatus("Sync already in progress")
            return
        }
        
        isSyncing = true
        syncErrors.removeAll()
        updateSyncStatus("Checking for updates...")
        
        do {
            let lastSync = lastSyncDate ?? Date.distantPast
            
            // Check for changes since last sync
            let changes = try await checkForChanges(since: lastSync)
            
            if changes.isEmpty {
                updateSyncStatus("No changes to sync")
            } else {
                updateSyncStatus("Syncing \(changes.count) changes...")
                
                for (index, change) in changes.enumerated() {
                    updateSyncProgress(Double(index) / Double(changes.count))
                    try await processChange(change)
                }
            }
            
            // Update metadata
            lastSyncDate = Date()
            saveSyncMetadata()
            
            updateSyncProgress(1.0)
            updateSyncStatus("Sync completed")
            
            #if DEBUG
            print("[SyncCoordinator] ✅ Incremental sync completed")
            #endif
            
        } catch {
            handleSyncError(error)
        }
        
        isSyncing = false
    }
    
    /// Sync specific entity type
    @MainActor
    func syncEntity(_ entityType: SyncEntityType) async throws {
        guard networkMonitor.shouldAllowSync else {
            throw SyncError.noNetwork
        }
        
        updateSyncStatus("Syncing \(entityType.displayName)...")
        try await syncEntity(entityType, fullSync: false)
        updateSyncStatus("Completed syncing \(entityType.displayName)")
    }
    
    /// Start automatic sync
    func startAutoSync() {
        stopAutoSync()
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performIncrementalSync()
            }
        }
        
        #if DEBUG
        print("[SyncCoordinator] ⏱ Auto sync started (interval: \(syncInterval)s)")
        #endif
    }
    
    /// Stop automatic sync
    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        
        #if DEBUG
        print("[SyncCoordinator] ⏹ Auto sync stopped")
        #endif
    }
    
    /// Force sync for specific record
    @MainActor
    func syncRecord(entityType: SyncEntityType, recordId: String) async throws {
        guard networkMonitor.shouldAllowSync else {
            throw SyncError.noNetwork
        }
        
        updateSyncStatus("Syncing \(entityType) record...")
        
        // Create and execute sync operation for specific record
        let context = coreDataStack.backgroundContext()
        let operation = createSyncOperation(for: entityType, recordId: recordId, context: context)
        
        syncQueue.addOperation(operation)
        
        // Wait for completion
        await withCheckedContinuation { continuation in
            operation.completionHandler = { _ in
                continuation.resume()
            }
        }
        
        updateSyncStatus("Record sync completed")
    }
    
    /// Handle authentication failure
    func handleAuthenticationFailure() {
        stopAutoSync()
        syncQueue.cancelAllOperations()
        Task { @MainActor in
            updateSyncStatus("Authentication required")
        }
        
        // Clear sync metadata
        lastSyncDate = nil
        saveSyncMetadata()
    }
    
    // MARK: - Private Methods
    
    private func syncEntity(_ entityType: SyncEntityType, fullSync: Bool) async throws {
        let context = coreDataStack.backgroundContext()
        
        // Download changes from server
        let downloadOp = SyncOperation(operationType: .download, entityType: entityType, context: context)
        
        // Upload local changes
        let uploadOp = SyncOperation(operationType: .upload, entityType: entityType, context: context)
        uploadOp.addDependency(downloadOp)
        
        // Add operations to queue
        syncQueue.addOperations([downloadOp, uploadOp])
        
        // Wait for completion
        await withCheckedContinuation { continuation in
            var completed = 0
            let total = 2
            
            let completionHandler: (Result<Void, Error>) -> Void = { result in
                completed += 1
                if completed == total {
                    continuation.resume()
                }
            }
            
            downloadOp.completionHandler = completionHandler
            uploadOp.completionHandler = completionHandler
        }
    }
    
    private func checkForChanges(since date: Date) async throws -> [SyncChange] {
        // In a real implementation, this would query the server for changes
        // For now, return empty array
        return []
    }
    
    private func processChange(_ change: SyncChange) async throws {
        // Process individual change
        let context = coreDataStack.backgroundContext()
        let operation = createSyncOperation(for: change, context: context)
        
        syncQueue.addOperation(operation)
        
        // Wait for completion
        try await withCheckedThrowingContinuation { continuation in
            operation.completionHandler = { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func createSyncOperation(for entityType: SyncEntityType, recordId: String, context: NSManagedObjectContext) -> SyncOperation {
        // Create appropriate sync operation based on entity type
        return RecordSyncOperation(
            entityType: entityType,
            recordId: recordId,
            context: context
        )
    }
    
    private func createSyncOperation(for change: SyncChange, context: NSManagedObjectContext) -> SyncOperation {
        // Create operation based on change type
        return ChangeSyncOperation(
            change: change,
            context: context
        )
    }
    
    // MARK: - UI Updates
    
    @MainActor
    private func updateSyncStatus(_ status: String) {
        self.syncStatus = status
        
        #if DEBUG
        print("[SyncCoordinator] 📊 Status: \(status)")
        #endif
    }
    
    @MainActor
    private func updateSyncProgress(_ progress: Double) {
        self.syncProgress = progress
    }
    
    private func handleSyncError(_ error: Error) {
        let syncError = error as? SyncError ?? .unknown(error)
        
        Task { @MainActor in
            syncErrors.append(syncError)
            updateSyncStatus("Sync failed: \(syncError.localizedDescription)")
        }
        
        #if DEBUG
        print("[SyncCoordinator] ❌ Sync error: \(error)")
        #endif
    }
    
    // MARK: - Metadata Management
    
    private func loadSyncMetadata() {
        if let data = UserDefaults.standard.data(forKey: metadataKey),
           let metadata = try? JSONDecoder().decode(SyncMetadata.self, from: data) {
            lastSyncDate = metadata.lastSyncDate
        }
    }
    
    private func saveSyncMetadata() {
        let metadata = SyncMetadata(lastSyncDate: lastSyncDate)
        if let data = try? JSONEncoder().encode(metadata) {
            UserDefaults.standard.set(data, forKey: metadataKey)
        }
    }
}

// MARK: - Supporting Types

private struct SyncMetadata: Codable {
    let lastSyncDate: Date?
}

private struct SyncChange {
    let entityType: SyncEntityType
    let recordId: String
    let changeType: ChangeType
    let timestamp: Date
    
    enum ChangeType {
        case created
        case updated
        case deleted
    }
}

// MARK: - Custom Operations

private class DownloadOperation: SyncOperation, @unchecked Sendable {
    let fullSync: Bool
    
    init(entityType: SyncEntityType, context: NSManagedObjectContext, fullSync: Bool) {
        self.fullSync = fullSync
        super.init(operationType: .download, entityType: entityType, context: context)
    }
    
    override func performSync() throws {
        // Implementation would download data from server
        // This is a placeholder
        Thread.sleep(forTimeInterval: 0.5)
        updateProgress(1.0)
    }
}

private class UploadOperation: SyncOperation, @unchecked Sendable {
    override func performSync() throws {
        // Implementation would upload local changes to server
        // This is a placeholder
        Thread.sleep(forTimeInterval: 0.5)
        updateProgress(1.0)
    }
}

private class RecordSyncOperation: SyncOperation, @unchecked Sendable {
    let recordId: String
    
    init(entityType: SyncEntityType, recordId: String, context: NSManagedObjectContext) {
        self.recordId = recordId
        super.init(operationType: .update, entityType: entityType, context: context)
    }
    
    override func performSync() throws {
        // Implementation would sync specific record
        // This is a placeholder
        Thread.sleep(forTimeInterval: 0.3)
        updateProgress(1.0)
    }
}

private class ChangeSyncOperation: SyncOperation, @unchecked Sendable {
    let change: SyncChange
    
    init(change: SyncChange, context: NSManagedObjectContext) {
        self.change = change
        let operationType: SyncOperationType = {
            switch change.changeType {
            case .created: return .upload
            case .updated: return .update
            case .deleted: return .delete
            }
        }()
        super.init(operationType: operationType, entityType: change.entityType, context: context)
    }
    
    override func performSync() throws {
        // Implementation would process the change
        // This is a placeholder
        Thread.sleep(forTimeInterval: 0.2)
        updateProgress(1.0)
    }
}