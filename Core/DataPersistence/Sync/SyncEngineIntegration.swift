//
//  SyncEngineIntegration.swift
//  KSR Cranes App
//
//  Created by Sync Engine on 06/11/2025.
//

import Foundation
import SwiftUI
import Combine

/// Extension to integrate SyncEngine with AppStateManager
extension AppStateManager {
    
    /// Initialize sync engine after successful authentication
    func initializeSyncEngine() {
        guard AuthService.shared.isLoggedIn else { return }
        
        // Configure sync engine based on user preferences
        configureSyncEngine()
        
        // Start sync engine
        SyncEngine.shared.start()
        
        #if DEBUG
        print("[AppStateManager] 🔄 Sync engine initialized")
        #endif
    }
    
    /// Configure sync engine settings
    private func configureSyncEngine() {
        var config = SyncEngine.Configuration()
        
        // Load user preferences
        config.autoSyncEnabled = UserDefaults.standard.bool(forKey: "autoSyncEnabled") 
        config.syncOnCellular = UserDefaults.standard.bool(forKey: "syncOnCellular")
        config.backgroundSyncEnabled = true
        config.syncInterval = 300 // 5 minutes
        
        // Apply role-specific settings
        let userRole = AuthService.shared.getEmployeeRole() ?? ""
        switch userRole.lowercased() {
        case "chef":
            config.conflictResolutionStrategy = .serverWins
        case "byggeleder":
            config.conflictResolutionStrategy = .merge
        case "arbejder":
            config.conflictResolutionStrategy = .clientWins
        default:
            config.conflictResolutionStrategy = .latestWins
        }
        
        SyncEngine.shared.configuration = config
    }
    
    /// Stop sync engine on logout
    func stopSyncEngine() {
        SyncEngine.shared.stop()
    }
}

/// View for displaying sync status and controls
struct SyncStatusView: View {
    @ObservedObject private var syncEngine = SyncEngine.shared
    @State private var showingSyncDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync Status")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(syncEngine.state.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { showingSyncDetails.toggle() }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            
            // Last Sync Info
            if let lastSync = syncEngine.lastSuccessfulSync {
                Label {
                    Text("Last synced \(lastSync, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            // Sync Progress
            if syncEngine.state == .syncing {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: syncEngine.syncProgress.overall)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    if let entity = syncEngine.syncProgress.currentEntity {
                        Text("Syncing \(entity.displayName)...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Manual Sync Button
            if syncEngine.state == .idle || syncEngine.state == .error {
                Button(action: performManualSync) {
                    Label("Sync Now", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!NetworkMonitor.shared.isConnected)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingSyncDetails) {
            SyncDetailsView()
        }
    }
    
    private var statusColor: Color {
        switch syncEngine.state {
        case .idle: return .green
        case .syncing: return .blue
        case .error: return .red
        case .authenticationRequired: return .orange
        case .waitingForNetwork, .waitingForWiFi: return .yellow
        default: return .gray
        }
    }
    
    private func performManualSync() {
        Task {
            await syncEngine.syncNow()
        }
    }
}

/// Detailed sync information view
struct SyncDetailsView: View {
    @ObservedObject private var syncEngine = SyncEngine.shared
    @Environment(\.dismiss) private var dismiss
    
    private var statistics: SyncEngineStatistics {
        syncEngine.getSyncStatistics()
    }
    
    var body: some View {
        NavigationView {
            List {
                // Configuration Section
                Section("Settings") {
                    Toggle("Auto Sync", isOn: $syncEngine.configuration.autoSyncEnabled)
                    
                    Toggle("Sync on Cellular", isOn: $syncEngine.configuration.syncOnCellular)
                    
                    Toggle("Background Sync", isOn: $syncEngine.configuration.backgroundSyncEnabled)
                }
                
                // Statistics Section
                Section("Statistics") {
                    LabeledContent("Total Syncs", value: "\(statistics.totalSyncs)")
                    
                    LabeledContent("Success Rate", value: "\(Int(statistics.successRate * 100))%")
                    
                    if let lastSync = statistics.lastSync {
                        LabeledContent("Last Sync", value: lastSync, format: .dateTime)
                    }
                    
                    LabeledContent("Average Duration", value: "\(Int(statistics.averageDuration))s")
                }
                
                // History Section
                if !syncEngine.syncHistory.isEmpty {
                    Section("Recent Activity") {
                        ForEach(syncEngine.syncHistory.prefix(10)) { entry in
                            HStack {
                                Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(entry.success ? .green : .red)
                                
                                VStack(alignment: .leading) {
                                    Text(entry.timestamp, style: .relative)
                                        .font(.caption)
                                    
                                    if let error = entry.error {
                                        Text(error)
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sync Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// View modifier to trigger sync on data changes
struct SyncOnChangeModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let entityType: SyncEntityType
    
    func body(content: Content) -> some View {
        content
            .onChange(of: value) {
                // Trigger sync for specific entity type
                Task {
                    try? await SyncEngine.shared.syncEntity(entityType)
                }
            }
    }
}

extension View {
    /// Trigger sync when value changes
    func syncOnChange<Value: Equatable>(of value: Value, entityType: SyncEntityType) -> some View {
        modifier(SyncOnChangeModifier(value: value, entityType: entityType))
    }
}

/// Example usage in a view
struct ExampleSyncIntegration: View {
    @StateObject private var viewModel = ChefWorkersViewModel()
    @ObservedObject private var syncEngine = SyncEngine.shared
    
    var body: some View {
        NavigationView {
            List {
                // Sync status at top
                Section {
                    SyncStatusView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                
                // Worker list
                Section("Workers") {
                    ForEach(viewModel.workers) { worker in
                        WorkerRow(worker: worker)
                    }
                }
            }
            .navigationTitle("Workers")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: syncWorkers) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(syncEngine.state == .syncing ? 360 : 0))
                            .animation(
                                syncEngine.state == .syncing
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                value: syncEngine.state
                            )
                    }
                    .disabled(syncEngine.state == .syncing)
                }
            }
        }
        .syncStatusOverlay() // Add sync status overlay
        .onAppear {
            // Sync workers when view appears
            Task {
                try? await syncEngine.syncEntity(.employee)
            }
        }
    }
    
    private func syncWorkers() {
        Task {
            try? await syncEngine.syncEntity(.employee)
        }
    }
}

struct WorkerRow: View {
    let worker: WorkerForChef
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(worker.name)
                    .font(.headline)
                Text(worker.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if worker.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}