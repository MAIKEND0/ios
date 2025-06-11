//
//  ConflictResolver.swift
//  KSR Cranes App
//
//  Created by Sync Engine on 06/11/2025.
//

import Foundation
import CoreData

/// Handles conflict resolution during sync operations
final class ConflictResolver {
    
    // MARK: - Types
    
    /// Conflict resolution strategy
    enum ResolutionStrategy: String {
        case clientWins      // Local changes override server
        case serverWins      // Server changes override local
        case latestWins      // Most recent change wins
        case merge           // Attempt to merge changes
        case manual          // Require user intervention
        
        static var `default`: ResolutionStrategy {
            return .latestWins
        }
    }
    
    /// Represents a sync conflict
    struct SyncConflict {
        let entityType: SyncEntityType
        let entityId: String
        let localData: [String: Any]
        let serverData: [String: Any]
        let localTimestamp: Date
        let serverTimestamp: Date
        let conflictingFields: Set<String>
        
        var description: String {
            return "\(entityType) \(entityId): \(conflictingFields.count) conflicting fields"
        }
    }
    
    /// Result of conflict resolution
    struct ResolutionResult {
        let resolvedData: [String: Any]
        let strategy: ResolutionStrategy
        let mergedFields: Set<String>
        let discardedChanges: [String: Any]
    }
    
    // MARK: - Properties
    
    /// Default resolution strategy
    var defaultStrategy: ResolutionStrategy = .latestWins
    
    /// Entity-specific resolution strategies
    private var entityStrategies: [SyncEntityType: ResolutionStrategy] = [:]
    
    /// Field-specific resolution strategies
    private var fieldStrategies: [String: ResolutionStrategy] = [:]
    
    // MARK: - Configuration
    
    /// Set resolution strategy for specific entity type
    func setStrategy(_ strategy: ResolutionStrategy, for entityType: SyncEntityType) {
        entityStrategies[entityType] = strategy
    }
    
    /// Set resolution strategy for specific field
    func setStrategy(_ strategy: ResolutionStrategy, for field: String) {
        fieldStrategies[field] = strategy
    }
    
    // MARK: - Conflict Resolution
    
    /// Resolve a sync conflict
    func resolve(_ conflict: SyncConflict) -> ResolutionResult {
        let strategy = determineStrategy(for: conflict)
        
        #if DEBUG
        print("[ConflictResolver] 🔧 Resolving conflict for \(conflict.description) using \(strategy)")
        #endif
        
        switch strategy {
        case .clientWins:
            return resolveClientWins(conflict)
        case .serverWins:
            return resolveServerWins(conflict)
        case .latestWins:
            return resolveLatestWins(conflict)
        case .merge:
            return resolveMerge(conflict)
        case .manual:
            return resolveManual(conflict)
        }
    }
    
    /// Detect conflicts between local and server data
    func detectConflicts(
        entityType: SyncEntityType,
        entityId: String,
        localData: [String: Any],
        serverData: [String: Any],
        localTimestamp: Date,
        serverTimestamp: Date
    ) -> SyncConflict? {
        
        let conflictingFields = findConflictingFields(
            localData: localData,
            serverData: serverData
        )
        
        guard !conflictingFields.isEmpty else {
            return nil
        }
        
        return SyncConflict(
            entityType: entityType,
            entityId: entityId,
            localData: localData,
            serverData: serverData,
            localTimestamp: localTimestamp,
            serverTimestamp: serverTimestamp,
            conflictingFields: conflictingFields
        )
    }
    
    // MARK: - Resolution Strategies
    
    private func resolveClientWins(_ conflict: SyncConflict) -> ResolutionResult {
        return ResolutionResult(
            resolvedData: conflict.localData,
            strategy: .clientWins,
            mergedFields: [],
            discardedChanges: conflict.serverData.filter { conflict.conflictingFields.contains($0.key) }
        )
    }
    
    private func resolveServerWins(_ conflict: SyncConflict) -> ResolutionResult {
        return ResolutionResult(
            resolvedData: conflict.serverData,
            strategy: .serverWins,
            mergedFields: [],
            discardedChanges: conflict.localData.filter { conflict.conflictingFields.contains($0.key) }
        )
    }
    
    private func resolveLatestWins(_ conflict: SyncConflict) -> ResolutionResult {
        let useLocal = conflict.localTimestamp > conflict.serverTimestamp
        
        return ResolutionResult(
            resolvedData: useLocal ? conflict.localData : conflict.serverData,
            strategy: .latestWins,
            mergedFields: [],
            discardedChanges: useLocal
                ? conflict.serverData.filter { conflict.conflictingFields.contains($0.key) }
                : conflict.localData.filter { conflict.conflictingFields.contains($0.key) }
        )
    }
    
    private func resolveMerge(_ conflict: SyncConflict) -> ResolutionResult {
        var mergedData = conflict.serverData
        var mergedFields = Set<String>()
        var discardedChanges: [String: Any] = [:]
        
        // Merge non-conflicting local changes
        for (key, localValue) in conflict.localData {
            if !conflict.conflictingFields.contains(key) {
                mergedData[key] = localValue
                mergedFields.insert(key)
            } else {
                // For conflicting fields, use field-specific strategy or latest wins
                if let fieldStrategy = fieldStrategies[key] {
                    switch fieldStrategy {
                    case .clientWins:
                        mergedData[key] = localValue
                        discardedChanges[key] = conflict.serverData[key] ?? NSNull()
                    case .serverWins:
                        discardedChanges[key] = localValue
                    case .latestWins:
                        if conflict.localTimestamp > conflict.serverTimestamp {
                            mergedData[key] = localValue
                            discardedChanges[key] = conflict.serverData[key] ?? NSNull()
                        } else {
                            discardedChanges[key] = localValue
                        }
                    default:
                        // Use server value for other strategies in merge
                        discardedChanges[key] = localValue
                    }
                } else if conflict.localTimestamp > conflict.serverTimestamp {
                    mergedData[key] = localValue
                    mergedFields.insert(key)
                    discardedChanges[key] = conflict.serverData[key] ?? NSNull()
                } else {
                    discardedChanges[key] = localValue
                }
            }
        }
        
        return ResolutionResult(
            resolvedData: mergedData,
            strategy: .merge,
            mergedFields: mergedFields,
            discardedChanges: discardedChanges
        )
    }
    
    private func resolveManual(_ conflict: SyncConflict) -> ResolutionResult {
        // For manual resolution, we default to server wins but mark for user review
        // In a real implementation, this would queue the conflict for user resolution
        
        #if DEBUG
        print("[ConflictResolver] ⚠️ Manual resolution required for \(conflict.description)")
        #endif
        
        // Store conflict for user resolution
        storeConflictForManualResolution(conflict)
        
        // Default to server wins for now
        return resolveServerWins(conflict)
    }
    
    // MARK: - Helper Methods
    
    private func determineStrategy(for conflict: SyncConflict) -> ResolutionStrategy {
        // Check entity-specific strategy
        if let entityStrategy = entityStrategies[conflict.entityType] {
            return entityStrategy
        }
        
        // Check if any conflicting fields have specific strategies
        for field in conflict.conflictingFields {
            if let fieldStrategy = fieldStrategies[field] {
                return fieldStrategy
            }
        }
        
        // Use default strategy
        return defaultStrategy
    }
    
    private func findConflictingFields(
        localData: [String: Any],
        serverData: [String: Any]
    ) -> Set<String> {
        var conflicts = Set<String>()
        
        // Check all keys that exist in both
        let allKeys = Set(localData.keys).union(Set(serverData.keys))
        
        for key in allKeys {
            let localValue = localData[key]
            let serverValue = serverData[key]
            
            // Skip sync metadata fields
            if isSyncMetadataField(key) {
                continue
            }
            
            // Compare values
            if !areValuesEqual(localValue, serverValue) {
                conflicts.insert(key)
            }
        }
        
        return conflicts
    }
    
    private func areValuesEqual(_ value1: Any?, _ value2: Any?) -> Bool {
        // Handle nil cases
        if value1 == nil && value2 == nil {
            return true
        }
        if value1 == nil || value2 == nil {
            return false
        }
        
        // Compare based on type
        switch (value1, value2) {
        case let (v1 as String, v2 as String):
            return v1 == v2
        case let (v1 as Int, v2 as Int):
            return v1 == v2
        case let (v1 as Double, v2 as Double):
            return v1 == v2
        case let (v1 as Bool, v2 as Bool):
            return v1 == v2
        case let (v1 as Date, v2 as Date):
            return v1 == v2
        case let (v1 as Data, v2 as Data):
            return v1 == v2
        case let (v1 as [String: Any], v2 as [String: Any]):
            return NSDictionary(dictionary: v1).isEqual(to: v2)
        case let (v1 as [Any], v2 as [Any]):
            return NSArray(array: v1).isEqual(to: v2)
        default:
            // For other types, use string comparison
            return "\(value1!)" == "\(value2!)"
        }
    }
    
    private func isSyncMetadataField(_ field: String) -> Bool {
        let metadataFields = [
            "syncVersion",
            "syncTimestamp",
            "lastSyncedAt",
            "syncId",
            "_etag",
            "_version"
        ]
        return metadataFields.contains(field)
    }
    
    private func storeConflictForManualResolution(_ conflict: SyncConflict) {
        // In a real implementation, this would store the conflict
        // in a persistent store for later user resolution
        
        // For now, we just log it
        #if DEBUG
        print("[ConflictResolver] 📝 Storing conflict for manual resolution:")
        print("  - Entity: \(conflict.entityType) (\(conflict.entityId))")
        print("  - Conflicting fields: \(conflict.conflictingFields)")
        print("  - Local timestamp: \(conflict.localTimestamp)")
        print("  - Server timestamp: \(conflict.serverTimestamp)")
        #endif
    }
}

// MARK: - Entity-Specific Resolution Rules

extension ConflictResolver {
    /// Configure default resolution rules for KSR Cranes entities
    func configureDefaultRules() {
        // Work entries should preserve local changes (user's recorded time)
        setStrategy(.clientWins, for: .workEntry)
        
        // Projects and tasks should use server as source of truth
        setStrategy(.serverWins, for: .project)
        setStrategy(.serverWins, for: .task)
        
        // Leave requests use latest wins
        setStrategy(.latestWins, for: .leaveRequest)
        
        // Employee data merges changes
        setStrategy(.merge, for: .employee)
        
        // Field-specific rules
        setStrategy(.serverWins, for: "status")      // Status changes from server
        setStrategy(.clientWins, for: "notes")       // User notes preserved
        setStrategy(.latestWins, for: "updatedAt")   // Timestamp uses latest
    }
}