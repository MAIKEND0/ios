//
//  SyncEngine.swift
//  KSR Cranes App
//
//  Created by Sync Engine on 06/11/2025.
//

import Foundation
import CoreData
import Combine

/// Main synchronization engine for KSR Cranes app
final class SyncEngine: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SyncEngine()
    
    // MARK: - Published Properties
    
    @Published private(set) var state: SyncState = .idle
    @Published private(set) var isEnabled = true
    @Published private(set) var syncProgress: SyncProgress = SyncProgress()
    @Published private(set) var lastSuccessfulSync: Date?
    @Published private(set) var syncHistory: [SyncHistoryEntry] = []
    
    // MARK: - Properties
    
    /// Sync coordinator
    private let coordinator: SyncCoordinator
    
    /// Network monitor
    private let networkMonitor = NetworkMonitor.shared
    
    /// Auth service
    private let authService = AuthService.shared
    
    /// Core Data stack
    private let coreDataStack = CoreDataStack.shared
    
    /// Background sync task identifier
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    
    /// Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// Settings
    private let settingsKey = "com.ksrcranes.syncengine.settings"
    
    // MARK: - Configuration
    
    struct Configuration {
        var autoSyncEnabled = true
        var syncOnCellular = false
        var syncInterval: TimeInterval = 300 // 5 minutes
        var backgroundSyncEnabled = true
        var conflictResolutionStrategy: ConflictResolver.ResolutionStrategy = .latestWins
    }
    
    @Published var configuration = Configuration() {
        didSet {
            saveConfiguration()
            applyConfiguration()
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        self.coordinator = SyncCoordinator()
        
        loadConfiguration()
        setupObservers()
        applyConfiguration()
        
        #if DEBUG
        print("[SyncEngine] ✅ Initialized")
        #endif
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe authentication state
        NotificationCenter.default.publisher(for: .authTokenExpired)
            .sink { [weak self] _ in
                self?.handleAuthenticationExpired()
            }
            .store(in: &cancellables)
        
        // Observe app lifecycle
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleEnterBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleEnterForeground()
            }
            .store(in: &cancellables)
        
        // Observe network changes
        networkMonitor.$isConnected
            .removeDuplicates()
            .sink { [weak self] isConnected in
                self?.handleNetworkChange(isConnected: isConnected)
            }
            .store(in: &cancellables)
        
        // Observe coordinator state
        coordinator.$isSyncing
            .sink { [weak self] isSyncing in
                self?.updateState(isSyncing ? .syncing : .idle)
            }
            .store(in: &cancellables)
        
        coordinator.$syncProgress
            .sink { [weak self] progress in
                self?.syncProgress.overall = progress
            }
            .store(in: &cancellables)
        
        coordinator.$lastSyncDate
            .sink { [weak self] date in
                self?.lastSuccessfulSync = date
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Start the sync engine
    func start() {
        guard isEnabled else { return }
        
        updateState(.starting)
        
        // Verify authentication
        guard authService.isLoggedIn else {
            updateState(.authenticationRequired)
            return
        }
        
        // Start coordinator
        if configuration.autoSyncEnabled {
            coordinator.startAutoSync()
        }
        
        updateState(.idle)
        
        // Perform initial sync
        Task {
            await syncNow()
        }
        
        #if DEBUG
        print("[SyncEngine] ▶️ Started")
        #endif
    }
    
    /// Stop the sync engine
    func stop() {
        updateState(.stopping)
        
        coordinator.stopAutoSync()
        
        updateState(.stopped)
        
        #if DEBUG
        print("[SyncEngine] ⏹ Stopped")
        #endif
    }
    
    /// Trigger manual sync
    @MainActor
    func syncNow() async {
        guard canSync() else { return }
        
        updateState(.syncing)
        
        if lastSuccessfulSync == nil {
            // First sync - perform full sync
            await coordinator.performFullSync()
        } else {
            // Subsequent sync - incremental
            await coordinator.performIncrementalSync()
        }
        
        recordSyncHistory(success: true)
        
        updateState(.idle)
    }
    
    /// Sync specific entity
    @MainActor
    func syncEntity(_ entityType: SyncEntityType) async throws {
        guard canSync() else {
            throw SyncError.noNetwork
        }
        
        updateState(.syncing)
        defer { updateState(.idle) }
        
        try await coordinator.syncEntity(entityType)
    }
    
    /// Sync specific record
    @MainActor
    func syncRecord(entityType: SyncEntityType, recordId: String) async throws {
        guard canSync() else {
            throw SyncError.noNetwork
        }
        
        try await coordinator.syncRecord(entityType: entityType, recordId: recordId)
    }
    
    /// Reset sync state
    func reset() {
        stop()
        
        // Clear sync metadata
        lastSuccessfulSync = nil
        syncHistory.removeAll()
        
        // Clear coordinator state
        coordinator.handleAuthenticationFailure()
        
        #if DEBUG
        print("[SyncEngine] 🔄 Reset completed")
        #endif
    }
    
    /// Get sync statistics
    func getSyncStatistics() -> SyncEngineStatistics {
        return SyncEngineStatistics(
            lastSync: lastSuccessfulSync,
            totalSyncs: syncHistory.count,
            successfulSyncs: syncHistory.filter { $0.success }.count,
            failedSyncs: syncHistory.filter { !$0.success }.count,
            averageDuration: calculateAverageSyncDuration(),
            dataUsage: calculateDataUsage()
        )
    }
    
    // MARK: - Private Methods
    
    private func canSync() -> Bool {
        // Check if sync is enabled
        guard isEnabled else { return false }
        
        // Check authentication
        guard authService.isLoggedIn else {
            updateState(.authenticationRequired)
            return false
        }
        
        // Check network
        guard networkMonitor.isConnected else {
            updateState(.waitingForNetwork)
            return false
        }
        
        // Check cellular restrictions
        if !configuration.syncOnCellular && networkMonitor.connectionType == .cellular {
            updateState(.waitingForWiFi)
            return false
        }
        
        // Check if already syncing
        guard state != .syncing else { return false }
        
        return true
    }
    
    private func updateState(_ newState: SyncState) {
        Task { @MainActor in
            state = newState
            
            #if DEBUG
            print("[SyncEngine] 📊 State: \(newState)")
            #endif
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleAuthenticationExpired() {
        updateState(.authenticationRequired)
        coordinator.handleAuthenticationFailure()
    }
    
    private func handleEnterBackground() {
        guard configuration.backgroundSyncEnabled else { return }
        
        // Start background task
        backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        // Perform quick sync if needed
        if shouldPerformBackgroundSync() {
            Task {
                await performBackgroundSync()
            }
        }
    }
    
    private func handleEnterForeground() {
        endBackgroundTask()
        
        // Check for sync on foreground
        if configuration.autoSyncEnabled {
            Task {
                await syncNow()
            }
        }
    }
    
    private func handleNetworkChange(isConnected: Bool) {
        if isConnected && state == .waitingForNetwork {
            updateState(.idle)
            
            if configuration.autoSyncEnabled {
                Task {
                    await syncNow()
                }
            }
        } else if !isConnected && state == .syncing {
            updateState(.waitingForNetwork)
        }
    }
    
    // MARK: - Background Sync
    
    private func shouldPerformBackgroundSync() -> Bool {
        guard let lastSync = lastSuccessfulSync else { return true }
        
        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        return timeSinceLastSync > configuration.syncInterval
    }
    
    private func performBackgroundSync() async {
        await coordinator.performIncrementalSync()
        endBackgroundTask()
    }
    
    private func endBackgroundTask() {
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }
    
    // MARK: - Configuration
    
    private func loadConfiguration() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let config = try? JSONDecoder().decode(Configuration.self, from: data) {
            configuration = config
        }
    }
    
    private func saveConfiguration() {
        if let data = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    private func applyConfiguration() {
        coordinator.isAutoSyncEnabled = configuration.autoSyncEnabled
        coordinator.syncInterval = configuration.syncInterval
    }
    
    // MARK: - History Management
    
    private func recordSyncHistory(success: Bool, error: Error? = nil) {
        let entry = SyncHistoryEntry(
            id: UUID(),
            timestamp: Date(),
            success: success,
            duration: 0, // Would be calculated from actual sync time
            error: error?.localizedDescription
        )
        
        syncHistory.insert(entry, at: 0)
        
        // Keep only last 100 entries
        if syncHistory.count > 100 {
            syncHistory = Array(syncHistory.prefix(100))
        }
    }
    
    private func calculateAverageSyncDuration() -> TimeInterval {
        let durations = syncHistory.compactMap { $0.duration }
        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count)
    }
    
    private func calculateDataUsage() -> Int64 {
        // In a real implementation, this would track actual data usage
        return 0
    }
}

// MARK: - Supporting Types

/// Sync engine state
enum SyncState: String {
    case idle = "Idle"
    case starting = "Starting"
    case syncing = "Syncing"
    case stopping = "Stopping"
    case stopped = "Stopped"
    case authenticationRequired = "Authentication Required"
    case waitingForNetwork = "Waiting for Network"
    case waitingForWiFi = "Waiting for Wi-Fi"
    case error = "Error"
    
    var isActive: Bool {
        switch self {
        case .syncing, .starting, .stopping:
            return true
        default:
            return false
        }
    }
}

/// Sync progress tracking
struct SyncProgress {
    var overall: Double = 0.0
    var currentEntity: SyncEntityType?
    var currentOperation: String?
    var itemsProcessed: Int = 0
    var totalItems: Int = 0
    
    var description: String {
        if let entity = currentEntity, let operation = currentOperation {
            return "\(operation) \(entity.displayName) (\(itemsProcessed)/\(totalItems))"
        }
        return "Syncing..."
    }
}

/// Sync history entry
struct SyncHistoryEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let success: Bool
    let duration: TimeInterval
    let error: String?
}

/// Sync statistics for the engine
struct SyncEngineStatistics {
    let lastSync: Date?
    let totalSyncs: Int
    let successfulSyncs: Int
    let failedSyncs: Int
    let averageDuration: TimeInterval
    let dataUsage: Int64
    
    var successRate: Double {
        guard totalSyncs > 0 else { return 0 }
        return Double(successfulSyncs) / Double(totalSyncs)
    }
}

// MARK: - Extensions

extension SyncEngine.Configuration: Codable {
    enum CodingKeys: String, CodingKey {
        case autoSyncEnabled
        case syncOnCellular
        case syncInterval
        case backgroundSyncEnabled
        case conflictResolutionStrategy
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        autoSyncEnabled = try container.decode(Bool.self, forKey: .autoSyncEnabled)
        syncOnCellular = try container.decode(Bool.self, forKey: .syncOnCellular)
        syncInterval = try container.decode(TimeInterval.self, forKey: .syncInterval)
        backgroundSyncEnabled = try container.decode(Bool.self, forKey: .backgroundSyncEnabled)
        
        // Decode conflict resolution strategy
        if let strategyString = try container.decodeIfPresent(String.self, forKey: .conflictResolutionStrategy),
           let strategy = ConflictResolver.ResolutionStrategy(rawValue: strategyString) {
            conflictResolutionStrategy = strategy
        } else {
            conflictResolutionStrategy = .latestWins
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(autoSyncEnabled, forKey: .autoSyncEnabled)
        try container.encode(syncOnCellular, forKey: .syncOnCellular)
        try container.encode(syncInterval, forKey: .syncInterval)
        try container.encode(backgroundSyncEnabled, forKey: .backgroundSyncEnabled)
        try container.encode(conflictResolutionStrategy.rawValue, forKey: .conflictResolutionStrategy)
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

extension SyncEngine {
    /// View modifier for sync status
    struct SyncStatusModifier: ViewModifier {
        @ObservedObject var syncEngine = SyncEngine.shared
        
        func body(content: Content) -> some View {
            content
                .overlay(alignment: .top) {
                    if syncEngine.state.isActive {
                        SyncStatusBanner(state: syncEngine.state, progress: syncEngine.syncProgress)
                            .transition(.move(edge: .top))
                    }
                }
        }
    }
    
    /// Sync status banner view
    struct SyncStatusBanner: View {
        let state: SyncState
        let progress: SyncProgress
        
        var body: some View {
            HStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if progress.overall > 0 {
                        Text(progress.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if progress.overall > 0 {
                    Text("\(Int(progress.overall * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Material.thin)
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

extension View {
    /// Add sync status overlay to any view
    func syncStatusOverlay() -> some View {
        modifier(SyncEngine.SyncStatusModifier())
    }
}