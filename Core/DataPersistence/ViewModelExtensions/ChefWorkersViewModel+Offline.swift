import Foundation
import CoreData
import Combine

/// Extension adding offline support to ChefWorkersViewModel
extension ChefWorkersViewModel: OfflineDataProvider {
    typealias DataType = WorkerForChef
    
    /// Access to API service for offline extension
    private var offlineAPIService: ChefWorkersAPIService {
        ChefWorkersAPIService.shared
    }
    
    /// Sync status for workers management
    private static var syncStatusSubject = PassthroughSubject<OfflineSyncStatus, Never>()
    
    var syncStatusPublisher: AnyPublisher<OfflineSyncStatus, Never> {
        Self.syncStatusSubject.eraseToAnyPublisher()
    }
    
    nonisolated var hasPendingChanges: Bool {
        let context = CoreDataStack.shared.mainContext
        
        let request: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", "pending")
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("[ChefWorkersViewModel+Offline] Error checking pending changes: \(error)")
            return false
        }
    }
    
    /// Load data with offline support
    func loadDataOfflineFirst() {
        #if DEBUG
        print("[ChefWorkersViewModel+Offline] Loading data with offline support...")
        #endif
        
        let connectivity = NetworkConnectivity.shared
        Self.syncStatusSubject.send(connectivity.isConnected ? .syncing : .offline)
        
        Task { @MainActor in
            do {
                if connectivity.isConnected {
                    // Load from online with stats
                    let (workers, stats) = try await fetchOnlineData()
                    self.workers = workers
                    self.overallStats = stats
                    
                    // Save for offline
                    Task {
                        try? await self.saveForOffline(workers)
                        if let stats = stats {
                            try? await self.saveStatsForOffline(stats)
                        }
                    }
                } else {
                    // Load from offline (no stats)
                    let workers = try await loadOfflineData()
                    self.workers = workers
                    self.overallStats = nil
                }
                
                self.lastRefreshTime = Date()
                Self.syncStatusSubject.send(.synced)
                
                // Sync pending changes if online
                if connectivity.isConnected && hasPendingChanges {
                    try? await syncPendingChanges()
                }
                
            } catch {
                print("[ChefWorkersViewModel+Offline] Error loading data: \(error)")
                Self.syncStatusSubject.send(.syncFailed(error))
                // Fall back to empty state
                self.workers = []
                self.overallStats = nil
            }
        }
    }
    
    /// Fetch online data
    private func fetchOnlineData() async throws -> ([WorkerForChef], WorkersOverallStats?) {
        // Convert Combine publishers to async/await
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = Publishers.Zip(
                offlineAPIService.fetchWorkers(includeProfileImage: true, includeStats: true, includeCertificates: true),
                offlineAPIService.fetchWorkersStats()
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
                receiveValue: { [weak self] workers, stats in
                    // Save to offline storage
                    Task {
                        try? await self?.saveForOffline(workers)
                        try? await self?.saveStatsForOffline(stats)
                    }
                    continuation.resume(returning: (workers, stats))
                }
            )
        }
    }
    
    /// Load offline data from Core Data
    func loadOfflineData() async throws -> [WorkerForChef] {
        let context = CoreDataStack.shared.mainContext
        
        return try await context.perform {
            // Load workers from EmployeeEntity
            let workersRequest: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
            workersRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            // Only fetch workers (not chefs or managers)
            workersRequest.predicate = NSPredicate(format: "role == %@ OR role == %@", "arbejder", "byggeleder")
            
            let cachedWorkers = try context.fetch(workersRequest)
            let workers = cachedWorkers.map { cached in
                WorkerForChef(
                    id: Int(cached.serverID),
                    name: cached.name ?? "",
                    email: cached.email ?? "",
                    phone: cached.phoneNumber,
                    address: cached.address,
                    hourly_rate: cached.operatorNormalRate?.doubleValue ?? 0,
                    employment_type: EmploymentType(rawValue: "fuld_tid") ?? .fuld_tid, // Default to full-time
                    role: WorkerRole(rawValue: cached.role ?? "arbejder") ?? .arbejder,
                    status: cached.isActivated ? .aktiv : .inaktiv,
                    profile_picture_url: cached.profilePictureUrl,
                    created_at: cached.createdAt ?? Date(),
                    last_active: cached.updatedAt,
                    stats: nil, // Stats not stored in EmployeeEntity
                    certificates: nil // Certificates not stored in EmployeeEntity
                )
            }
            
            return workers
        }
    }
    
    /// Save workers for offline access
    func saveForOffline(_ data: [WorkerForChef]) async throws {
        let context = CoreDataStack.shared.backgroundContext()
        
        try await context.perform {
            // Don't delete all employees - only update workers
            
            // Save/update workers
            for worker in data {
                let request: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
                request.predicate = NSPredicate(format: "serverID == %d", worker.id)
                request.fetchLimit = 1
                
                let employee = (try? context.fetch(request).first) ?? EmployeeEntity(context: context)
                
                employee.serverID = Int32(worker.id)
                employee.name = worker.name
                employee.email = worker.email
                employee.phoneNumber = worker.phone
                employee.address = worker.address
                employee.operatorNormalRate = NSDecimalNumber(value: worker.hourly_rate)
                employee.role = worker.role.rawValue
                employee.isActivated = worker.status == .aktiv
                employee.profilePictureUrl = worker.profile_picture_url
                employee.createdAt = worker.created_at
                employee.updatedAt = worker.last_active ?? Date()
                employee.syncStatus = "synced"
                employee.lastModified = Date()
            }
            
            try context.save()
        }
    }
    
    /// Save stats for offline access - Not implemented as we don't have a stats entity
    private func saveStatsForOffline(_ stats: WorkersOverallStats) async throws {
        // Stats are not persisted offline in the current implementation
        // They would need a separate Core Data entity
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
            // Fetch pending workers
            let pendingWorkers = try await context.perform {
                let request: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
                request.predicate = NSPredicate(format: "syncStatus == %@ AND (role == %@ OR role == %@)", "pending", "arbejder", "byggeleder")
                return try context.fetch(request)
            }
            
            // Sync each pending worker
            for worker in pendingWorkers {
                try await syncWorker(worker)
            }
            
            Self.syncStatusSubject.send(.synced)
            
        } catch {
            print("[ChefWorkersViewModel+Offline] Sync failed: \(error)")
            Self.syncStatusSubject.send(.syncFailed(error))
            throw error
        }
    }
    
    /// Sync individual worker
    private func syncWorker(_ cached: EmployeeEntity) async throws {
        let request = CreateWorkerRequest(
            name: cached.name ?? "",
            email: cached.email ?? "",
            phone: cached.phoneNumber,
            address: cached.address,
            hourly_rate: cached.operatorNormalRate?.doubleValue ?? 0,
            employment_type: "fuld_tid" // Default employment type
        )
        
        // Convert to async/await
        _ = try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            if cached.serverID == 0 {
                // New worker - create
                cancellable = offlineAPIService.createWorker(request)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                Task {
                                    try? await self.updateSyncStatus(for: cached, to: "synced")
                                }
                                continuation.resume(returning: ())
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                            cancellable?.cancel()
                        },
                        receiveValue: { _ in }
                    )
            } else {
                // Existing worker - update
                let updateRequest = UpdateWorkerRequest(
                    name: cached.name,
                    email: cached.email,
                    phone: cached.phoneNumber,
                    address: cached.address,
                    hourly_rate: cached.operatorNormalRate?.doubleValue,
                    employment_type: "fuld_tid",
                    role: cached.role,
                    status: cached.isActivated ? "aktiv" : "inaktiv",
                    notes: nil
                )
                
                cancellable = offlineAPIService.updateWorker(id: Int(cached.serverID), data: updateRequest)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                Task {
                                    try? await self.updateSyncStatus(for: cached, to: "synced")
                                }
                                continuation.resume(returning: ())
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                            cancellable?.cancel()
                        },
                        receiveValue: { _ in }
                    )
            }
        }
    }
    
    /// Update sync status for a cached worker
    private func updateSyncStatus(for worker: EmployeeEntity, to status: String) async throws {
        guard let context = worker.managedObjectContext else { return }
        
        try await context.perform {
            worker.syncStatus = status
            worker.lastModified = Date()
            try context.save()
        }
    }
    
    // MARK: - Optimistic Updates
    
    /// Add worker with optimistic update
    func addWorkerOptimistic(_ request: CreateWorkerRequest) async throws {
        let newWorker = try await performOptimisticUpdate(
            localUpdate: { [weak self] in
                // Create local worker
                let worker = WorkerForChef(
                    id: Int.random(in: 100000...999999), // Temporary ID
                    name: request.name,
                    email: request.email,
                    phone: request.phone,
                    address: request.address,
                    hourly_rate: request.hourly_rate,
                    employment_type: EmploymentType(rawValue: request.employment_type) ?? .fuld_tid,
                    role: .arbejder,
                    status: .aktiv,
                    profile_picture_url: nil,
                    created_at: Date(),
                    last_active: nil,
                    stats: nil,
                    certificates: nil
                )
                
                // Save to Core Data
                try await self?.saveWorkerLocally(worker, syncStatus: "pending")
                
                return worker
            },
            remoteUpdate: { [weak self] in
                // Submit to server
                guard let worker = try await self?.submitWorkerToServer(request) else {
                    throw NSError(domain: "ChefWorkersViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create worker"])
                }
                return worker
            },
            rollback: { [weak self] in
                // Remove from Core Data if server sync fails
                await self?.removeLocalWorker(request.email)
            },
            isConnected: NetworkConnectivity.shared.isConnected
        )
        
        // Update UI
        await MainActor.run { [weak self] in
            self?.workers.append(newWorker)
        }
    }
    
    /// Update worker with optimistic update
    func updateWorkerOptimistic(_ worker: WorkerForChef, request: UpdateWorkerRequest) async throws {
        let updatedWorker = try await performOptimisticUpdate(
            localUpdate: { [weak self] in
                // Create updated worker
                let updated = WorkerForChef(
                    id: worker.id,
                    name: request.name ?? worker.name,
                    email: request.email ?? worker.email,
                    phone: request.phone ?? worker.phone,
                    address: request.address ?? worker.address,
                    hourly_rate: request.hourly_rate ?? worker.hourly_rate,
                    employment_type: worker.employment_type,
                    role: worker.role,
                    status: worker.status,
                    profile_picture_url: worker.profile_picture_url,
                    created_at: worker.created_at,
                    last_active: worker.last_active,
                    stats: worker.stats,
                    certificates: worker.certificates
                )
                
                // Save to Core Data
                try await self?.saveWorkerLocally(updated, syncStatus: "pending")
                
                return updated
            },
            remoteUpdate: { [weak self] in
                // Submit to server
                guard let updatedWorker = try await self?.updateWorkerOnServer(worker.id, request: request) else {
                    throw NSError(domain: "ChefWorkersViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to update worker"])
                }
                return updatedWorker
            },
            rollback: { [weak self] in
                // Restore original worker
                do {
                    try await self?.saveWorkerLocally(worker, syncStatus: "synced")
                } catch {
                    print("[ChefWorkersViewModel+Offline] Error restoring worker: \(error)")
                }
            },
            isConnected: NetworkConnectivity.shared.isConnected
        )
        
        // Update UI
        await MainActor.run { [weak self] in
            self?.updateWorker(updatedWorker)
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveWorkerLocally(_ worker: WorkerForChef, syncStatus: String) async throws {
        let context = CoreDataStack.shared.backgroundContext()
        
        try await context.perform {
            // Find or create employee entity
            let request: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
            request.predicate = NSPredicate(format: "serverID == %d", worker.id)
            request.fetchLimit = 1
            
            let employee = (try? context.fetch(request).first) ?? EmployeeEntity(context: context)
            
            // Update values
            employee.serverID = Int32(worker.id)
            employee.name = worker.name
            employee.email = worker.email
            employee.phoneNumber = worker.phone
            employee.address = worker.address
            employee.operatorNormalRate = NSDecimalNumber(value: worker.hourly_rate)
            employee.role = worker.role.rawValue
            employee.isActivated = worker.status == .aktiv
            employee.profilePictureUrl = worker.profile_picture_url
            employee.createdAt = worker.created_at
            employee.updatedAt = worker.last_active ?? Date()
            employee.syncStatus = syncStatus
            employee.lastModified = Date()
            
            try context.save()
        }
    }
    
    private func submitWorkerToServer(_ request: CreateWorkerRequest) async throws -> WorkerForChef {
        // Convert to async/await
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = offlineAPIService.createWorker(request)
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
                    receiveValue: { worker in
                        continuation.resume(returning: worker)
                    }
                )
        }
    }
    
    private func updateWorkerOnServer(_ id: Int, request: UpdateWorkerRequest) async throws -> WorkerForChef {
        // Convert to async/await
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = offlineAPIService.updateWorker(id: id, data: request)
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
                    receiveValue: { worker in
                        continuation.resume(returning: worker)
                    }
                )
        }
    }
    
    private func removeLocalWorker(_ email: String) async {
        let context = CoreDataStack.shared.backgroundContext()
        
        do {
            try await context.perform {
                let request: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
                request.predicate = NSPredicate(format: "email == %@", email)
                request.fetchLimit = 1
                
                if let employee = try context.fetch(request).first {
                    context.delete(employee)
                    try context.save()
                }
            }
        } catch {
            print("[ChefWorkersViewModel+Offline] Error removing local worker: \(error)")
        }
    }
    
    // MARK: - JSON Serialization Helpers
    
    private func serializeStats(_ stats: WorkerQuickStats?) -> String? {
        guard let stats = stats else { return nil }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(stats)
            return String(data: data, encoding: .utf8)
        } catch {
            print("[ChefWorkersViewModel+Offline] Error serializing stats: \(error)")
            return nil
        }
    }
    
    private func deserializeStats(_ json: String?) -> WorkerQuickStats? {
        guard let json = json, let data = json.data(using: .utf8) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(WorkerQuickStats.self, from: data)
        } catch {
            print("[ChefWorkersViewModel+Offline] Error deserializing stats: \(error)")
            return nil
        }
    }
    
    private func serializeCertificates(_ certificates: [WorkerCertificate]?) -> String? {
        guard let certificates = certificates else { return nil }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(certificates)
            return String(data: data, encoding: .utf8)
        } catch {
            print("[ChefWorkersViewModel+Offline] Error serializing certificates: \(error)")
            return nil
        }
    }
    
    private func deserializeCertificates(_ json: String?) -> [WorkerCertificate]? {
        guard let json = json, let data = json.data(using: .utf8) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode([WorkerCertificate].self, from: data)
        } catch {
            print("[ChefWorkersViewModel+Offline] Error deserializing certificates: \(error)")
            return nil
        }
    }
}