# KSR Cranes Sync Engine

A comprehensive synchronization engine for the KSR Cranes app that handles bi-directional sync, offline operations, conflict resolution, and background synchronization.

## Architecture Overview

The sync engine consists of several key components:

### Core Components

1. **SyncEngine** (`SyncEngine.swift`)
   - Main entry point and coordinator
   - Manages sync state and configuration
   - Handles authentication and lifecycle events
   - Provides UI integration points

2. **SyncCoordinator** (`SyncCoordinator.swift`)
   - Coordinates sync operations across entities
   - Manages incremental and full sync workflows
   - Handles sync scheduling and automation

3. **SyncQueue** (`SyncQueue.swift`)
   - Manages operation queue with offline support
   - Handles retry logic and operation prioritization
   - Persists pending operations for offline execution

4. **SyncOperation** (`SyncOperation.swift`)
   - Base class for all sync operations
   - Provides retry logic and progress tracking
   - Handles common sync workflows

5. **NetworkMonitor** (`NetworkMonitor.swift`)
   - Monitors network connectivity and quality
   - Determines sync eligibility based on conditions
   - Supports cellular/WiFi restrictions

6. **ConflictResolver** (`ConflictResolver.swift`)
   - Handles data conflicts during sync
   - Supports multiple resolution strategies
   - Configurable per entity and field

## Features

### Bi-directional Sync
- Downloads server changes to local Core Data
- Uploads local changes to server
- Maintains sync state for each entity

### Offline Support
- Queues operations when offline
- Automatically syncs when network available
- Persists pending operations across app launches

### Conflict Resolution
- Multiple strategies: client wins, server wins, latest wins, merge
- Configurable per entity type and field
- Manual conflict resolution support

### Incremental Sync
- Tracks last sync timestamp
- Only syncs changed data
- Reduces bandwidth and improves performance

### Background Sync
- Continues sync when app enters background
- Respects iOS background task limitations
- Configurable sync intervals

### Network Awareness
- Monitors connection type and quality
- Respects cellular data restrictions
- Waits for suitable network conditions

### Progress Tracking
- Real-time sync progress updates
- Per-entity progress tracking
- UI integration for progress display

### Error Handling
- Comprehensive error types
- Retry logic for transient failures
- Detailed error logging

## Usage

### Basic Setup

```swift
// In AppStateManager after authentication
func initializeSyncEngine() {
    // Configure sync settings
    var config = SyncEngine.Configuration()
    config.autoSyncEnabled = true
    config.syncInterval = 300 // 5 minutes
    config.syncOnCellular = false
    config.backgroundSyncEnabled = true
    
    SyncEngine.shared.configuration = config
    
    // Start sync engine
    SyncEngine.shared.start()
}
```

### Manual Sync

```swift
// Trigger full sync
Task {
    await SyncEngine.shared.syncNow()
}

// Sync specific entity
Task {
    try await SyncEngine.shared.syncEntity(.employee)
}

// Sync specific record
Task {
    try await SyncEngine.shared.syncRecord(
        entityType: .employee,
        recordId: "123"
    )
}
```

### UI Integration

```swift
// Add sync status overlay to any view
struct ContentView: View {
    var body: some View {
        NavigationView {
            // Your content
        }
        .syncStatusOverlay()
    }
}

// Display sync status
struct SettingsView: View {
    var body: some View {
        List {
            Section {
                SyncStatusView()
            }
        }
    }
}

// Trigger sync on data changes
struct EditView: View {
    @State private var data: String = ""
    
    var body: some View {
        TextField("Data", text: $data)
            .syncOnChange(of: data, entityType: .employee)
    }
}
```

### Creating Entity-Specific Sync Operations

```swift
class ProjectSyncOperation: SyncOperation {
    override func performSync() throws {
        switch operationType {
        case .download:
            // Download projects from server
            downloadProjects()
        case .upload:
            // Upload local changes
            uploadLocalChanges()
        case .fullSync:
            // Perform full sync
            performFullSync()
        default:
            break
        }
    }
}
```

## Configuration

### Sync Settings

```swift
struct Configuration {
    var autoSyncEnabled = true           // Enable automatic sync
    var syncOnCellular = false          // Allow sync on cellular
    var syncInterval: TimeInterval = 300 // Sync interval in seconds
    var backgroundSyncEnabled = true     // Enable background sync
    var conflictResolutionStrategy: ConflictResolver.ResolutionStrategy = .latestWins
}
```

### Conflict Resolution Rules

```swift
// Configure entity-specific rules
conflictResolver.setStrategy(.serverWins, for: .project)
conflictResolver.setStrategy(.clientWins, for: .workEntry)
conflictResolver.setStrategy(.merge, for: .employee)

// Configure field-specific rules
conflictResolver.setStrategy(.serverWins, for: "status")
conflictResolver.setStrategy(.clientWins, for: "notes")
```

## Integration with Existing API Services

The sync engine integrates seamlessly with existing API services:

```swift
// Example: Worker sync using ChefWorkersAPIService
class WorkerSyncOperation: SyncOperation {
    private let apiService = ChefWorkersAPIService()
    
    private func downloadWorkers() throws {
        apiService.fetchWorkers(page: 1, limit: 100)
            .sink { response in
                // Process and save to Core Data
                self.processWorkerResponse(response)
            }
    }
}
```

## Best Practices

1. **Entity Sync Order**: Sync parent entities before children (e.g., Projects before Tasks)

2. **Batch Operations**: Process data in batches to avoid memory issues

3. **Progress Updates**: Update progress frequently for better UX

4. **Error Recovery**: Implement proper error handling and recovery

5. **Testing**: Test offline scenarios and conflict resolution

6. **Performance**: Use background contexts for sync operations

## Monitoring and Debugging

### Sync Statistics

```swift
let stats = SyncEngine.shared.getSyncStatistics()
print("Success rate: \(stats.successRate)%")
print("Last sync: \(stats.lastSync)")
print("Failed syncs: \(stats.failedSyncs)")
```

### Debug Logging

All components include comprehensive debug logging:
- Network status changes
- Sync operation lifecycle
- Conflict resolution decisions
- Error details

### Sync History

```swift
// Access sync history
let history = SyncEngine.shared.syncHistory
for entry in history {
    print("\(entry.timestamp): \(entry.success ? "✅" : "❌")")
}
```

## Future Enhancements

- Push notification triggered sync
- Selective sync (sync only specific data)
- Sync analytics and reporting
- Cloud backup integration
- Multi-device sync coordination