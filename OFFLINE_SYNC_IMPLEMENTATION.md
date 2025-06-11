# KSR Cranes App - Offline Support & Sync Implementation

## 🎯 **Overview**

This document describes the comprehensive offline support and synchronization system implemented for the KSR Cranes app. The implementation enables users to work seamlessly without internet connectivity and automatically synchronizes data when connection is restored.

## 📁 **Architecture Overview**

```
┌──────────────────────────────────────┐
│          UI Layer (SwiftUI)          │
│  • Sync status indicators            │
│  • Offline mode banners              │
└──────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────┐
│        ViewModels + Extensions       │
│  • Offline-first data loading        │
│  • Optimistic updates                │
└──────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────┐
│          Sync Engine                 │
│  • Bi-directional sync               │
│  • Conflict resolution               │
│  • Operation queue                   │
└──────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────┐
│         Core Data Stack              │
│  • Local persistence                 │
│  • Migration support                 │
│  • Background contexts               │
└──────────────────────────────────────┘
```

## 🏗️ **Components Implemented**

### **1. Core Data Infrastructure**

#### **CoreDataStack** (`Core/DataPersistence/CoreDataStack.swift`)
- Singleton pattern for app-wide access
- Main and background context management
- Automatic lightweight migration support
- Comprehensive error handling and logging

#### **Core Data Entities**
- `EmployeeEntity` - Employee/Worker data
- `WorkEntryEntity` - Time tracking entries
- `TaskEntity` - Task assignments
- `ProjectEntity` - Project information
- `LeaveRequestEntity` - Leave/vacation requests

Each entity includes:
- Sync status tracking (pending, synced, error, conflict)
- Local and server IDs for offline/online mapping
- Timestamps for conflict detection
- Conversion methods to/from API models

### **2. Synchronization Engine**

#### **SyncEngine** (`Core/DataPersistence/Sync/SyncEngine.swift`)
Main synchronization orchestrator with:
- Configurable sync intervals
- Background sync support
- Authentication error handling
- Progress tracking and notifications

#### **NetworkMonitor** (`Core/DataPersistence/Sync/NetworkMonitor.swift`)
- Real-time network status monitoring
- Connection quality assessment
- Automatic sync triggering on connectivity changes

#### **SyncQueue** (`Core/DataPersistence/Sync/SyncQueue.swift`)
- Stores operations for offline execution
- Priority-based processing
- Automatic retry with exponential backoff

#### **ConflictResolver** (`Core/DataPersistence/Sync/ConflictResolver.swift`)
- Multiple resolution strategies (client wins, server wins, merge)
- Field-level conflict detection
- User notification for manual resolution when needed

### **3. ViewModel Extensions**

#### **Offline Data Providers**
- `WorkerDashboardViewModel+Offline.swift`
- `ChefWorkersViewModel+Offline.swift`
- `WorkerLeaveViewModel+Offline.swift`

Features:
- Offline-first data loading with automatic fallback
- Optimistic updates with rollback on failure
- Sync status publishing for UI updates
- Pending changes tracking

### **4. UI Components**

#### **Sync Status Indicators**
- `SyncStatusBadge` - Colored badge with sync state
- `OfflineIndicatorView` - Offline mode banner
- `SyncProgressView` - Progress during sync operations
- `PendingChangesIndicator` - Count of unsynced items
- `NetworkStatusBar` - Real-time connectivity display

## 💾 **Data Flow**

### **Online → Offline**
```
1. User performs action (e.g., submit work hours)
2. ViewModel saves to Core Data (immediate)
3. ViewModel attempts API call
4. If successful → Update sync status to "synced"
5. If failed → Keep in Core Data with "pending" status
6. Add to sync queue for later retry
```

### **Offline → Online**
```
1. Network becomes available
2. NetworkMonitor triggers sync
3. SyncQueue processes pending operations
4. ConflictResolver handles any conflicts
5. Update Core Data with server response
6. Update UI with sync status
```

## 🔄 **Conflict Resolution**

### **Automatic Resolution Strategies**

1. **Server Wins** (Default for critical data)
   - Server data overwrites local changes
   - Used for: Employee rates, project assignments

2. **Client Wins** (For user-generated content)
   - Local changes override server data
   - Used for: Draft work entries, personal notes

3. **Latest Wins** (Timestamp-based)
   - Most recent change is kept
   - Used for: Profile updates, general edits

4. **Merge** (Field-level merging)
   - Combines non-conflicting changes
   - Used for: Complex entities with multiple fields

### **Manual Resolution**
When automatic resolution isn't possible:
1. User is notified of conflict
2. Both versions are presented
3. User selects which version to keep
4. Resolution is logged for audit

## 🚀 **Implementation Guide**

### **1. Enable Offline Support in Existing Views**

```swift
// In your view
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    @State private var showOfflineBanner = false
    
    var body: some View {
        NavigationView {
            Content()
                .onAppear {
                    viewModel.loadDataOfflineFirst()
                }
                .offlineBanner(isOffline: showOfflineBanner)
                .networkStatus(.floating)
                .syncStatusOverlay()
        }
        .onReceive(NetworkMonitor.shared.$isConnected) { connected in
            showOfflineBanner = !connected
        }
    }
}
```

### **2. Add Offline Support to ViewModels**

```swift
// Extend existing ViewModel
extension MyViewModel: OfflineDataProvider {
    func loadDataOfflineFirst() {
        Task {
            do {
                // Try online first
                let data = try await apiService.fetchData()
                self.data = data
                saveToCache(data)
            } catch {
                // Fall back to offline
                self.data = loadFromCache()
                syncStatus = .offline
            }
        }
    }
}
```

### **3. Handle Offline Operations**

```swift
// Submit data with offline support
func submitData(_ data: MyData) {
    Task {
        // Save locally first
        let localEntity = saveToCore​Data(data)
        
        if NetworkMonitor.shared.isConnected {
            do {
                let response = try await apiService.submit(data)
                updateCoreData(localEntity, with: response)
            } catch {
                // Queue for later sync
                SyncQueue.shared.addOperation(.upload(data))
            }
        } else {
            // Queue immediately when offline
            SyncQueue.shared.addOperation(.upload(data))
            showOfflineMessage()
        }
    }
}
```

## 🔧 **Configuration**

### **Sync Settings**

```swift
// In AppDelegate or App.swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions...) {
    // Configure sync engine
    SyncEngine.shared.configure(
        syncInterval: 300, // 5 minutes
        backgroundSyncEnabled: true,
        conflictResolution: .automatic,
        maxRetries: 3,
        enableDebugLogging: true
    )
    
    // Start monitoring
    NetworkMonitor.shared.startMonitoring()
}
```

### **Background Sync**

```swift
// Enable background fetch
func application(_ application: UIApplication, performFetchWithCompletionHandler...) {
    Task {
        let result = await SyncEngine.shared.performBackgroundSync()
        completionHandler(result)
    }
}
```

## 📊 **Migration from Online-Only**

### **Step 1: Update Xcode Project**
1. Add Core Data model file (KSRCranes.xcdatamodeld)
2. Enable Core Data capability in project settings
3. Add Background Modes capability (Background fetch)

### **Step 2: Data Migration**
```swift
// One-time migration of existing data
func migrateExistingData() async {
    // Fetch all current data from API
    let workers = try? await apiService.fetchAllWorkers()
    let projects = try? await apiService.fetchAllProjects()
    
    // Save to Core Data
    await CoreDataManager.shared.performBackgroundTask { context in
        workers?.forEach { worker in
            let entity = EmployeeEntity.fromAPIModel(worker, context: context)
            entity.syncStatus = .synced
        }
        
        projects?.forEach { project in
            let entity = ProjectEntity.fromAPIModel(project, context: context)
            entity.syncStatus = .synced
        }
        
        try? context.save()
    }
}
```

### **Step 3: Update ViewModels**
1. Import new extensions
2. Replace `loadData()` with `loadDataOfflineFirst()`
3. Add sync status handling
4. Update save methods to use offline-first approach

### **Step 4: Update UI**
1. Add sync status indicators to navigation bars
2. Add offline banners to main views
3. Show pending changes count where appropriate
4. Add pull-to-refresh with sync trigger

## 🧪 **Testing Offline Functionality**

### **Simulator Testing**
1. Run app in simulator
2. Turn off Mac's WiFi or use Network Link Conditioner
3. Verify offline indicators appear
4. Perform operations (should work offline)
5. Turn WiFi back on
6. Verify automatic sync occurs

### **Device Testing**
1. Install app on device
2. Enable Airplane Mode
3. Test all major workflows
4. Disable Airplane Mode
5. Monitor sync progress

### **Conflict Testing**
1. Make changes on two devices while offline
2. Bring both online
3. Verify conflict resolution works correctly
4. Check audit logs for conflict records

## 📈 **Performance Considerations**

### **Optimization Tips**
1. **Batch Operations**: Group multiple changes before syncing
2. **Incremental Sync**: Only sync changed data using timestamps
3. **Compression**: Compress large payloads before sync
4. **Priority Queue**: Sync critical data first
5. **Background Processing**: Use background contexts for heavy operations

### **Storage Management**
```swift
// Implement cache cleanup
func cleanupOldData() {
    let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
    
    // Delete old synced entries
    let request: NSFetchRequest<WorkEntryEntity> = WorkEntryEntity.fetchRequest()
    request.predicate = NSPredicate(
        format: "syncStatus == %@ AND lastModified < %@", 
        SyncStatus.synced.rawValue,
        thirtyDaysAgo as NSDate
    )
    
    // Execute batch delete
    let batchDelete = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
    try? context.execute(batchDelete)
}
```

## 🔒 **Security Considerations**

1. **Encryption**: Core Data files are encrypted by iOS
2. **Authentication**: Tokens stored in Keychain, not Core Data
3. **Sensitive Data**: Consider additional encryption for sensitive fields
4. **Data Purge**: Implement secure data wipe on logout

## 🎯 **Success Metrics**

Monitor these metrics to ensure offline sync is working well:
- Sync success rate (target: >95%)
- Average sync duration (target: <5 seconds)
- Conflict rate (target: <1%)
- Offline usage percentage
- Data consistency checks

## 📚 **Troubleshooting**

### **Common Issues**

1. **Sync Not Starting**
   - Check network permissions
   - Verify background fetch is enabled
   - Check authentication status

2. **Duplicate Data**
   - Verify unique constraints in Core Data
   - Check ID mapping logic
   - Review conflict resolution settings

3. **Slow Performance**
   - Reduce fetch batch sizes
   - Implement pagination
   - Use background contexts
   - Add appropriate indexes

## 🚀 **Next Steps**

1. Implement remaining entity sync operations
2. Add comprehensive unit tests
3. Performance testing with large datasets
4. User acceptance testing
5. Production rollout with monitoring

This offline sync implementation provides a robust foundation for the KSR Cranes app to work seamlessly in any network condition, ensuring productivity is never interrupted.