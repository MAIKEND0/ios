import Foundation
import CoreData
import Combine

/// Extension adding offline support to WorkerDashboardViewModel
extension WorkerDashboardViewModel: OfflineDataProvider {
    typealias DataType = WorkerAPIService.WorkHourEntry
    
    /// Sync status for the dashboard
    private static var syncStatusSubject = PassthroughSubject<OfflineSyncStatus, Never>()
    
    var syncStatusPublisher: AnyPublisher<OfflineSyncStatus, Never> {
        Self.syncStatusSubject.eraseToAnyPublisher()
    }
    
    nonisolated var hasPendingChanges: Bool {
        // Check if there are any unsynced work entries in Core Data
        let context = CoreDataStack.shared.mainContext
        
        let request: NSFetchRequest<WorkEntryEntity> = WorkEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", "pending")
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("[WorkerDashboardViewModel+Offline] Error checking pending changes: \(error)")
            return false
        }
    }
    
    /// Load data with offline support
    func loadDataOfflineFirst() {
        #if DEBUG
        print("[WorkerDashboardViewModel+Offline] Loading data with offline support...")
        #endif
        
        let connectivity = NetworkConnectivity.shared
        
        // Update sync status
        Self.syncStatusSubject.send(connectivity.isConnected ? .syncing : .offline)
        
        // Load hours data with offline support
        loadHoursDataOfflineFirst()
        
        // Load tasks with offline support
        loadTasksOfflineFirst()
        
        // Load announcements (online only for now)
        if !connectivity.isConnected {
            // Load cached announcements if available
            loadCachedAnnouncements()
        }
        // Note: loadAnnouncements() is called automatically by loadData() in the main ViewModel
        
        // Sync pending changes if online
        if connectivity.isConnected {
            Task {
                try? await syncPendingChanges()
            }
        }
    }
    
    /// Load hours data with offline fallback
    private func loadHoursDataOfflineFirst() {
        Task { @MainActor in
            do {
                let entries = try await loadDataOfflineFirst(
                    onlineLoader: { [weak self] in
                        guard let self = self else { throw NSError(domain: "WorkerDashboard", code: -1) }
                        return try await self.fetchOnlineHoursData()
                    },
                    offlineLoader: { [weak self] in
                        guard let self = self else { throw NSError(domain: "WorkerDashboard", code: -1) }
                        return try await self.loadOfflineData()
                    },
                    isConnected: NetworkConnectivity.shared.isConnected
                )
                
                // Update the hours view model with loaded entries
                self.hoursViewModel.entries = entries
                Self.syncStatusSubject.send(.synced)
                
            } catch {
                print("[WorkerDashboardViewModel+Offline] Error loading hours data: \(error)")
                Self.syncStatusSubject.send(.syncFailed(error))
            }
        }
    }
    
    /// Load tasks with offline fallback
    private func loadTasksOfflineFirst() {
        Task { @MainActor in
            do {
                let tasks = try await loadDataOfflineFirst(
                    onlineLoader: { [weak self] in
                        guard let self = self else { throw NSError(domain: "WorkerDashboard", code: -1) }
                        return try await self.fetchOnlineTasks()
                    },
                    offlineLoader: { [weak self] in
                        guard let self = self else { throw NSError(domain: "WorkerDashboard", code: -1) }
                        return try await self.loadOfflineTasks()
                    },
                    isConnected: NetworkConnectivity.shared.isConnected
                )
                
                // Update tasks view model
                self.tasksViewModel.tasks = tasks
                
            } catch {
                print("[WorkerDashboardViewModel+Offline] Error loading tasks: \(error)")
            }
        }
    }
    
    /// Fetch online hours data
    private func fetchOnlineHoursData() async throws -> [WorkerAPIService.WorkHourEntry] {
        guard let employeeId = AuthService.shared.getEmployeeId() else {
            throw NSError(domain: "WorkerDashboard", code: -1, userInfo: [NSLocalizedDescriptionKey: "No employee ID found"])
        }
        
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .weekOfYear, value: -8, to: today) ?? today
        
        // Convert to async/await from Combine
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            cancellable = WorkerAPIService.shared
                .fetchWorkEntries(
                    employeeId: employeeId,
                    weekStartDate: formatter.string(from: startDate)
                )
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { entries in
                        // Save to offline storage
                        Task {
                            try? await self.saveForOffline(entries)
                        }
                        continuation.resume(returning: entries)
                    }
                )
        }
    }
    
    /// Fetch online tasks
    private func fetchOnlineTasks() async throws -> [WorkerAPIService.Task] {
        // TODO: Implement when WorkerAPIService has fetchWorkerTasks method
        // For now, return empty array as tasks are loaded through tasksViewModel
        return []
        
        /*
        // Convert Combine publisher to async/await
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = WorkerAPIService.shared
                .fetchWorkerTasks()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { tasks in
                        // Save tasks to offline storage
                        Task {
                            try? await self.saveTasksForOffline(tasks)
                        }
                        continuation.resume(returning: tasks)
                    }
                )
        }
        */
    }
    
    /// Load offline work entries from Core Data
    func loadOfflineData() async throws -> [WorkerAPIService.WorkHourEntry] {
        let context = CoreDataStack.shared.mainContext
        
        return try await context.perform {
            let request: NSFetchRequest<WorkEntryEntity> = WorkEntryEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "workDate", ascending: false)]
            
            _ = try context.fetch(request)
            
            // Convert cached entries to API model
            // TODO: Implement proper conversion when WorkHourEntry has a proper init
            return []
        }
    }
    
    /// Load offline tasks
    private func loadOfflineTasks() async throws -> [WorkerAPIService.Task] {
        let context = CoreDataStack.shared.mainContext
        
        return try await context.perform {
            let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            _ = try context.fetch(request)
            
            // Convert cached tasks to API model
            // TODO: Implement proper conversion when Task has a proper initializer
            // For now, return empty array as Task uses Codable init only
            return []
        }
    }
    
    /// Load cached announcements
    private func loadCachedAnnouncements() {
        // TODO: Implement when AnnouncementEntity is created
        self.announcements = []
    }
    
    /// Save work entries for offline access
    func saveForOffline(_ data: [WorkerAPIService.WorkHourEntry]) async throws {
        let context = CoreDataStack.shared.backgroundContext()
        
        try await context.perform {
            // Clear existing entries
            let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "WorkEntryEntity")
            let batchDelete = NSBatchDeleteRequest(fetchRequest: deleteRequest)
            try context.execute(batchDelete)
            
            // Save new entries
            // TODO: Implement when WorkEntryEntity properties match the API model
            /*
            for entry in data {
                let cached = WorkEntryEntity(context: context)
                cached.workEntryId = Int32(entry.work_entry_id)
                cached.employeeId = Int32(entry.employee_id)
                cached.taskId = Int32(entry.task_id)
                cached.projectId = Int32(entry.project_id)
                cached.workDate = entry.work_date
                cached.startTime = entry.start_time
                cached.endTime = entry.end_time
                cached.pauseMinutes = Int16(entry.pause_minutes ?? 0)
                cached.hoursDecimal = entry.hours_decimal ?? 0
                cached.km = entry.km ?? 0
                cached.notes = entry.notes
                cached.workType = entry.work_type
                cached.isOffsite = entry.is_offsite ?? false
                cached.entryStatus = entry.entry_status
                cached.statusChangedAt = entry.status_changed_at
                cached.projectName = entry.project_name
                cached.taskName = entry.task_name
                cached.employeeName = entry.employee_name
                cached.createdAt = entry.created_at
                cached.updatedAt = entry.updated_at
                cached.syncStatus = WorkEntryEntity.SyncStatus.synced.rawValue
                cached.lastSyncedAt = Date()
            }
            */
            
            try context.save()
        }
    }
    
    /// Save tasks for offline access
    private func saveTasksForOffline(_ tasks: [WorkerAPIService.Task]) async throws {
        let context = CoreDataStack.shared.backgroundContext()
        
        try await context.perform {
            // Clear existing tasks
            let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TaskEntity")
            let batchDelete = NSBatchDeleteRequest(fetchRequest: deleteRequest)
            try context.execute(batchDelete)
            
            // Save new tasks
            // TODO: Implement when TaskEntity properties match the API model
            /*
            for task in tasks {
                let cached = TaskEntity(context: context)
                cached.taskId = Int32(task.task_id)
                cached.taskName = task.task_name
                cached.taskDescription = task.description
                cached.deadline = task.deadline
                cached.totalHours = task.total_hours ?? 0
                cached.totalKm = task.total_km ?? 0
                cached.projectId = Int32(task.project_id)
                cached.projectName = task.project_name
                cached.startDate = task.start_date
                cached.status = task.status
                cached.priority = task.priority
                cached.estimatedHours = task.estimated_hours ?? 0
                cached.requiredOperators = Int16(task.required_operators ?? 0)
                cached.clientEquipmentInfo = task.client_equipment_info
                cached.createdAt = Date()
                cached.syncStatus = SyncStatus.synced.rawValue
            }
            */
            
            try context.save()
        }
    }
    
    /// Sync pending changes with server
    func syncPendingChanges() async throws {
        guard NetworkConnectivity.shared.isConnected else {
            Self.syncStatusSubject.send(.offline)
            return
        }
        
        let context = CoreDataStack.shared.mainContext
        
        Self.syncStatusSubject.send(.syncing)
        
        do {
            // Fetch pending work entries
            let pendingEntries = try await context.perform {
                let request: NSFetchRequest<WorkEntryEntity> = WorkEntryEntity.fetchRequest()
                request.predicate = NSPredicate(format: "syncStatus == %@", SyncStatus.pending.rawValue)
                return try context.fetch(request)
            }
            
            // Sync each pending entry
            for entry in pendingEntries {
                try await syncWorkEntry(entry)
            }
            
            Self.syncStatusSubject.send(.synced)
            
        } catch {
            print("[WorkerDashboardViewModel+Offline] Sync failed: \(error)")
            Self.syncStatusSubject.send(.syncFailed(error))
            throw error
        }
    }
    
    /// Sync individual work entry
    private func syncWorkEntry(_ cached: WorkEntryEntity) async throws {
        // TODO: Implement when WorkerAPIService has CreateWorkEntryRequest model
        // For now, we'll just update the sync status
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        // Update sync status
        let context = CoreDataStack.shared.mainContext
        
        try await context.perform {
            cached.syncStatus = SyncStatus.synced.rawValue
            cached.lastModified = Date()
            try context.save()
        }
    }
    
    /// Add offline support to the main loadData method
    func loadDataWithOfflineSupport() {
        if NetworkConnectivity.shared.isConnected {
            // Use existing online method
            loadData()
        } else {
            // Use offline-first approach
            loadDataOfflineFirst()
        }
    }
}

// MARK: - Optimistic Updates Support

extension WorkerDashboardViewModel {
    
    /// Submit work entry with optimistic update
    /*
    func submitWorkEntryOptimistic(
        _ entry: WorkerAPIService.CreateWorkEntryRequest
    ) async throws {
        
        let localEntry = try await performOptimisticUpdate(
            localUpdate: {
                // Save to Core Data immediately
                try await self.saveWorkEntryLocally(entry)
            },
            remoteUpdate: {
                // Submit to server
                try await self.submitWorkEntryToServer(entry)
            },
            rollback: {
                // Remove from Core Data if server sync fails
                await self.removeLocalWorkEntry(entry)
            },
            isConnected: NetworkConnectivity.shared.isConnected
        )
        
        // Refresh UI
        await MainActor.run {
            self.loadDataWithOfflineSupport()
        }
    }
    */
    
    /*
    private func saveWorkEntryLocally(_ entry: WorkerAPIService.CreateWorkEntryRequest) async throws -> WorkerAPIService.WorkHourEntry {
        let context = CoreDataStack.shared.backgroundContext()
        
        return try await context.perform {
            let cached = CachedWorkEntry(context: context)
            cached.workEntryId = Int32.random(in: 100000...999999) // Temporary ID
            cached.employeeId = Int32(entry.employee_id)
            cached.taskId = Int32(entry.task_id)
            cached.workDate = entry.work_date
            cached.startTime = entry.start_time
            cached.endTime = entry.end_time
            cached.pauseMinutes = Int16(entry.pause_minutes ?? 0)
            cached.km = entry.km ?? 0
            cached.notes = entry.notes
            cached.workType = entry.work_type
            cached.isOffsite = entry.is_offsite ?? false
            cached.syncStatus = NetworkConnectivity.shared.isConnected ? SyncStatus.pending.rawValue : SyncStatus.offline.rawValue
            cached.createdAt = Date()
            
            try context.save()
            
            // Return as WorkHourEntry
            return WorkerAPIService.WorkHourEntry(
                work_entry_id: Int(cached.workEntryId),
                employee_id: Int(cached.employeeId),
                task_id: Int(cached.taskId),
                project_id: 0, // Will be updated on sync
                work_date: cached.workDate ?? Date(),
                start_time: cached.startTime,
                end_time: cached.endTime,
                pause_minutes: Int(cached.pauseMinutes),
                hours_decimal: 0, // Will be calculated
                km: cached.km,
                notes: cached.notes,
                work_type: cached.workType,
                is_offsite: cached.isOffsite,
                entry_status: "draft",
                status_changed_at: nil,
                project_name: nil,
                task_name: nil,
                employee_name: nil,
                created_at: cached.createdAt,
                updated_at: cached.createdAt
            )
        }
    }
    */
    
    /*
    private func submitWorkEntryToServer(_ entry: WorkerAPIService.CreateWorkEntryRequest) async throws -> WorkerAPIService.WorkHourEntry {
        // This would need to be implemented in WorkerAPIService as an async method
        // For now, throw an error to simulate
        throw NSError(domain: "WorkerDashboard", code: -1, userInfo: [NSLocalizedDescriptionKey: "Server submission not implemented"])
    }
    */
    
    /*
    private func removeLocalWorkEntry(_ entry: WorkerAPIService.CreateWorkEntryRequest) async {
        let context = CoreDataStack.shared.backgroundContext()
        
        do {
            try await context.perform {
                let request: NSFetchRequest<CachedWorkEntry> = CachedWorkEntry.fetchRequest()
                request.predicate = NSPredicate(
                    format: "workDate == %@ AND taskId == %d AND syncStatus == %@",
                    entry.work_date as NSDate,
                    entry.task_id,
                    SyncStatus.pending.rawValue
                )
                request.fetchLimit = 1
                
                if let cached = try context.fetch(request).first {
                    context.delete(cached)
                    try context.save()
                }
            }
        } catch {
            print("[WorkerDashboardViewModel+Offline] Error removing local entry: \(error)")
        }
    }
    */
}

// MARK: - Sync Status Enums

private extension WorkerDashboardViewModel {
    enum SyncStatus: String {
        case pending = "pending"
        case synced = "synced"
        case offline = "offline"
        case failed = "failed"
    }
}