//
//  SyncQueue.swift
//  KSR Cranes App
//
//  Created by Sync Engine on 06/11/2025.
//

import Foundation
import CoreData
import Combine

/// Manages a queue of sync operations with offline support
final class SyncQueue {
    
    // MARK: - Properties
    
    /// Operation queue for sync operations
    private let operationQueue: OperationQueue
    
    /// Pending operations stored for offline execution
    private var pendingOperations: [SyncOperation] = []
    
    /// Lock for thread-safe access
    private let lock = NSLock()
    
    /// Current sync statistics
    @Published private(set) var statistics = SyncStatistics()
    
    /// Active operations
    @Published private(set) var activeOperations: [SyncOperation] = []
    
    /// Network monitor
    private let networkMonitor = NetworkMonitor.shared
    
    /// Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()
    
    /// Persistence key for offline queue
    private let persistenceKey = "com.ksrcranes.syncqueue.pending"
    
    // MARK: - Initialization
    
    init(name: String = "SyncQueue", maxConcurrentOperations: Int = 3) {
        self.operationQueue = OperationQueue()
        self.operationQueue.name = name
        self.operationQueue.maxConcurrentOperationCount = maxConcurrentOperations
        self.operationQueue.qualityOfService = .utility
        
        setupNetworkMonitoring()
        loadPendingOperations()
        
        #if DEBUG
        print("[SyncQueue] ✅ Initialized with max concurrent operations: \(maxConcurrentOperations)")
        #endif
    }
    
    // MARK: - Queue Management
    
    /// Add operation to queue
    func addOperation(_ operation: SyncOperation) {
        lock.lock()
        defer { lock.unlock() }
        
        // Check if network is available
        if networkMonitor.shouldAllowSync {
            // Execute immediately
            executeOperation(operation)
        } else {
            // Store for offline execution
            pendingOperations.append(operation)
            savePendingOperations()
            
            #if DEBUG
            print("[SyncQueue] 📱 Stored operation for offline execution: \(operation.operationType) - \(operation.entityType)")
            #endif
        }
        
        updateStatistics()
    }
    
    /// Add multiple operations
    func addOperations(_ operations: [SyncOperation]) {
        operations.forEach { addOperation($0) }
    }
    
    /// Cancel all operations
    func cancelAllOperations() {
        operationQueue.cancelAllOperations()
        
        lock.lock()
        pendingOperations.removeAll()
        savePendingOperations()
        lock.unlock()
        
        updateStatistics()
        
        #if DEBUG
        print("[SyncQueue] 🛑 Cancelled all operations")
        #endif
    }
    
    /// Cancel operations for specific entity type
    func cancelOperations(for entityType: SyncEntityType) {
        // Cancel active operations
        operationQueue.operations
            .compactMap { $0 as? SyncOperation }
            .filter { $0.entityType == entityType }
            .forEach { $0.cancel() }
        
        // Remove pending operations
        lock.lock()
        pendingOperations.removeAll { $0.entityType == entityType }
        savePendingOperations()
        lock.unlock()
        
        updateStatistics()
    }
    
    /// Get operations for specific entity
    func operations(for entityType: SyncEntityType) -> [SyncOperation] {
        lock.lock()
        defer { lock.unlock() }
        
        let active = operationQueue.operations
            .compactMap { $0 as? SyncOperation }
            .filter { $0.entityType == entityType }
        
        let pending = pendingOperations.filter { $0.entityType == entityType }
        
        return active + pending
    }
    
    /// Pause queue
    func pause() {
        operationQueue.isSuspended = true
        
        #if DEBUG
        print("[SyncQueue] ⏸ Queue paused")
        #endif
    }
    
    /// Resume queue
    func resume() {
        operationQueue.isSuspended = false
        processPendingOperations()
        
        #if DEBUG
        print("[SyncQueue] ▶️ Queue resumed")
        #endif
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        // Monitor network changes
        networkMonitor.$isConnected
            .removeDuplicates()
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.processPendingOperations()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Offline Support
    
    private func processPendingOperations() {
        guard networkMonitor.shouldAllowSync else { return }
        
        lock.lock()
        let operationsToProcess = pendingOperations
        pendingOperations.removeAll()
        savePendingOperations()
        lock.unlock()
        
        if !operationsToProcess.isEmpty {
            #if DEBUG
            print("[SyncQueue] 📤 Processing \(operationsToProcess.count) pending operations")
            #endif
            
            operationsToProcess.forEach { executeOperation($0) }
        }
    }
    
    private func executeOperation(_ operation: SyncOperation) {
        // Track active operations
        operation.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak operation] status in
                guard let self = self, let operation = operation else { return }
                
                self.lock.lock()
                if status.isActive && !self.activeOperations.contains(where: { $0.operationId == operation.operationId }) {
                    self.activeOperations.append(operation)
                } else if status.isFinished {
                    self.activeOperations.removeAll { $0.operationId == operation.operationId }
                }
                self.lock.unlock()
                
                self.updateStatistics()
            }
            .store(in: &cancellables)
        
        operationQueue.addOperation(operation)
    }
    
    // MARK: - Persistence
    
    private func savePendingOperations() {
        // Create operation metadata for persistence
        let metadata = pendingOperations.map { operation in
            OperationMetadata(
                id: operation.operationId,
                type: operation.operationType,
                entityType: operation.entityType,
                createdAt: operation.createdAt
            )
        }
        
        do {
            let data = try JSONEncoder().encode(metadata)
            UserDefaults.standard.set(data, forKey: persistenceKey)
            
            #if DEBUG
            print("[SyncQueue] 💾 Saved \(metadata.count) pending operations")
            #endif
        } catch {
            #if DEBUG
            print("[SyncQueue] ❌ Failed to save pending operations: \(error)")
            #endif
        }
    }
    
    private func loadPendingOperations() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
        
        do {
            let metadata = try JSONDecoder().decode([OperationMetadata].self, from: data)
            
            // Note: In a real implementation, you would recreate the actual operations
            // based on the metadata. For now, we just log them.
            
            #if DEBUG
            print("[SyncQueue] 📂 Found \(metadata.count) pending operations from previous session")
            #endif
            
            // Clear the persisted data as we can't recreate the operations without more context
            UserDefaults.standard.removeObject(forKey: persistenceKey)
        } catch {
            #if DEBUG
            print("[SyncQueue] ❌ Failed to load pending operations: \(error)")
            #endif
        }
    }
    
    // MARK: - Statistics
    
    private func updateStatistics() {
        lock.lock()
        defer { lock.unlock() }
        
        statistics.totalOperations = operationQueue.operations.count + pendingOperations.count
        statistics.activeOperations = activeOperations.count
        statistics.pendingOperations = pendingOperations.count
        statistics.completedOperations = statistics.completedOperations // Keep existing count
        statistics.failedOperations = statistics.failedOperations // Keep existing count
        
        // Update operation counts by type
        let allOperations = operationQueue.operations.compactMap { $0 as? SyncOperation } + pendingOperations
        
        statistics.uploadCount = allOperations.filter { $0.operationType == .upload }.count
        statistics.downloadCount = allOperations.filter { $0.operationType == .download }.count
        statistics.updateCount = allOperations.filter { $0.operationType == .update }.count
        statistics.deleteCount = allOperations.filter { $0.operationType == .delete }.count
    }
    
    /// Wait for all operations to complete
    func waitUntilAllOperationsAreFinished() {
        operationQueue.waitUntilAllOperationsAreFinished()
    }
}

// MARK: - Supporting Types

/// Metadata for persisting operations
private struct OperationMetadata: Codable {
    let id: UUID
    let type: SyncOperationType
    let entityType: SyncEntityType
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case entityType
        case createdAt
    }
    
    init(id: UUID, type: SyncOperationType, entityType: SyncEntityType, createdAt: Date) {
        self.id = id
        self.type = type
        self.entityType = entityType
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        
        // Decode type as string and convert to enum
        let typeString = try container.decode(String.self, forKey: .type)
        guard let decodedType = SyncOperationType(rawValue: typeString) else {
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid SyncOperationType value: \(typeString)")
        }
        type = decodedType
        
        // Decode entityType as string and convert to enum
        let entityTypeString = try container.decode(String.self, forKey: .entityType)
        guard let decodedEntityType = SyncEntityType(rawValue: entityTypeString) else {
            throw DecodingError.dataCorruptedError(forKey: .entityType, in: container, debugDescription: "Invalid SyncEntityType value: \(entityTypeString)")
        }
        entityType = decodedEntityType
        
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(entityType.rawValue, forKey: .entityType)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

/// Sync queue statistics
struct SyncStatistics {
    var totalOperations: Int = 0
    var activeOperations: Int = 0
    var pendingOperations: Int = 0
    var completedOperations: Int = 0
    var failedOperations: Int = 0
    
    var uploadCount: Int = 0
    var downloadCount: Int = 0
    var updateCount: Int = 0
    var deleteCount: Int = 0
    
    var successRate: Double {
        let total = completedOperations + failedOperations
        guard total > 0 else { return 0 }
        return Double(completedOperations) / Double(total)
    }
}

// MARK: - Queue Priority

extension SyncQueue {
    /// Prioritize operations for specific entity type
    func prioritize(entityType: SyncEntityType) {
        operationQueue.operations
            .compactMap { $0 as? SyncOperation }
            .filter { $0.entityType == entityType }
            .forEach { $0.queuePriority = .veryHigh }
    }
    
    /// Set quality of service for queue
    func setQualityOfService(_ qos: QualityOfService) {
        operationQueue.qualityOfService = qos
    }
}