import Foundation
import CoreData
import Combine

// MARK: - Worker Leave Request ViewModel Offline Extension

extension WorkerLeaveRequestViewModel: OfflineDataProvider {
    typealias DataType = LeaveRequest
    
    /// Sync status for leave management
    nonisolated private static let syncStatusSubject = PassthroughSubject<OfflineSyncStatus, Never>()
    
    nonisolated var syncStatusPublisher: AnyPublisher<OfflineSyncStatus, Never> {
        Self.syncStatusSubject.eraseToAnyPublisher()
    }
    
    nonisolated var hasPendingChanges: Bool {
        let context = CoreDataStack.shared.mainContext
        
        let request: NSFetchRequest<LeaveRequestEntity> = LeaveRequestEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", "pending")
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("[WorkerLeaveRequestViewModel+Offline] Error checking pending changes: \(error)")
            return false
        }
    }
    
    /// Load initial data with offline support
    func loadInitialDataOfflineFirst() {
        #if DEBUG
        print("[WorkerLeaveRequestViewModel+Offline] Loading data with offline support...")
        #endif
        
        let connectivity = NetworkConnectivity.shared
        Self.syncStatusSubject.send(connectivity.isConnected ? .syncing : .offline)
        
        isLoading = true
        
        Task { @MainActor in
            do {
                // Load all data types with offline fallback
                async let requestsTask: Void = loadLeaveRequestsOfflineFirst()
                async let balanceTask: Void = loadLeaveBalanceOfflineFirst()
                async let holidaysTask: Void = loadPublicHolidaysOfflineFirst()
                
                _ = try await (requestsTask, balanceTask, holidaysTask)
                
                lastRefresh = Date()
                Self.syncStatusSubject.send(.synced)
                
                // Sync pending changes if online
                if connectivity.isConnected && hasPendingChanges {
                    try? await syncPendingChanges()
                }
                
            } catch {
                print("[WorkerLeaveRequestViewModel+Offline] Error loading data: \(error)")
                Self.syncStatusSubject.send(.syncFailed(error))
                self.errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    /// Load leave requests with offline fallback
    private func loadLeaveRequestsOfflineFirst() async throws {
        let requests = try await loadDataOfflineFirst(
            onlineLoader: { [weak self] in
                guard let self = self else { throw NSError(domain: "WorkerLeave", code: -1) }
                return try await self.fetchOnlineLeaveRequests()
            },
            offlineLoader: { [weak self] in
                guard let self = self else { throw NSError(domain: "WorkerLeave", code: -1) }
                return try await self.loadOfflineData()
            },
            isConnected: NetworkConnectivity.shared.isConnected
        )
        
        await MainActor.run { [weak self] in
            self?.leaveRequests = requests
        }
    }
    
    /// Load leave balance with offline fallback
    private func loadLeaveBalanceOfflineFirst() async throws {
        do {
            if NetworkConnectivity.shared.isConnected {
                // Try online first
                let balance = try await fetchOnlineLeaveBalance()
                await MainActor.run { [weak self] in
                    self?.leaveBalance = balance
                }
            } else {
                // Use offline fallback
                if let balance = try await loadOfflineLeaveBalance() {
                    await MainActor.run { [weak self] in
                        self?.leaveBalance = balance
                    }
                }
            }
        } catch {
            // If online fails, try offline
            if let balance = try await loadOfflineLeaveBalance() {
                await MainActor.run { [weak self] in
                    self?.leaveBalance = balance
                }
            } else {
                throw error
            }
        }
    }
    
    /// Load public holidays with offline fallback
    private func loadPublicHolidaysOfflineFirst() async throws {
        let holidays = try await loadDataOfflineFirst(
            onlineLoader: { [weak self] in
                guard let self = self else { throw NSError(domain: "WorkerLeave", code: -1) }
                return try await self.fetchOnlinePublicHolidays()
            },
            offlineLoader: { [weak self] in
                guard let self = self else { throw NSError(domain: "WorkerLeave", code: -1) }
                return try await self.loadOfflinePublicHolidays()
            },
            isConnected: NetworkConnectivity.shared.isConnected
        )
        
        await MainActor.run { [weak self] in
            self?.publicHolidays = holidays
        }
    }
    
    /// Fetch online leave requests
    private func fetchOnlineLeaveRequests() async throws -> [LeaveRequest] {
        let params = LeaveQueryParams(
            status: selectedStatusFilter,
            type: selectedTypeFilter,
            page: 1,
            limit: 100
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = WorkerLeaveAPIService.shared.fetchLeaveRequests(params: params)
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
                    receiveValue: { [weak self] response in
                        // Save to offline storage
                        Task {
                            try? await self?.saveForOffline(response.requests)
                        }
                        continuation.resume(returning: response.requests)
                    }
                )
        }
    }
    
    /// Fetch online leave balance
    private func fetchOnlineLeaveBalance() async throws -> LeaveBalance {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = WorkerLeaveAPIService.shared.fetchLeaveBalance()
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
                    receiveValue: { [weak self] (balance: LeaveBalance) in
                        // Save to offline storage
                        Task {
                            try? await self?.saveLeaveBalanceForOffline(balance)
                        }
                        continuation.resume(returning: balance)
                    }
                )
        }
    }
    
    /// Fetch online public holidays
    private func fetchOnlinePublicHolidays() async throws -> [PublicHoliday] {
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = WorkerLeaveAPIService.shared.fetchPublicHolidays(year: currentYear)
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
                    receiveValue: { [weak self] (holidays: [PublicHoliday]) in
                        // Save to offline storage
                        Task {
                            try? await self?.savePublicHolidaysForOffline(holidays)
                        }
                        continuation.resume(returning: holidays)
                    }
                )
        }
    }
    
    /// Load offline leave requests from Core Data
    @MainActor
    func loadOfflineData() async throws -> [LeaveRequest] {
        let context = CoreDataStack.shared.mainContext
        
        let request: NSFetchRequest<LeaveRequestEntity> = LeaveRequestEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        // Apply filters if set
        var predicates: [NSPredicate] = []
        
        if let statusFilter = self.selectedStatusFilter {
            predicates.append(NSPredicate(format: "status == %@", statusFilter.rawValue))
        }
        
        if let typeFilter = self.selectedTypeFilter {
            predicates.append(NSPredicate(format: "type == %@", typeFilter.rawValue))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        let cachedRequests = try context.fetch(request)
        
        // Convert to API model
        return cachedRequests.compactMap { cached in
            convertToLeaveRequest(from: cached)
        }
    }
    
    /// Convert LeaveRequestEntity to LeaveRequest model
    private func convertToLeaveRequest(from entity: LeaveRequestEntity) -> LeaveRequest? {
        // Create a dictionary representation
        let dict: [String: Any] = [
            "id": Int(entity.serverID),
            "employee_id": Int(entity.employee?.serverID ?? 0),
            "type": entity.type ?? "VACATION",
            "start_date": ISO8601DateFormatter().string(from: entity.startDate ?? Date()),
            "end_date": ISO8601DateFormatter().string(from: entity.endDate ?? Date()),
            "total_days": Int(entity.totalDays),
            "half_day": entity.halfDay,
            "status": entity.status ?? "PENDING",
            "reason": entity.reason as Any,
            "sick_note_url": entity.sickNoteUrl as Any,
            "created_at": ISO8601DateFormatter().string(from: entity.createdAt ?? Date()),
            "updated_at": ISO8601DateFormatter().string(from: entity.updatedAt ?? Date()),
            "approved_by": entity.approvedBy != 0 ? Int(entity.approvedBy) as Any : NSNull(),
            "approved_at": entity.approvedAt != nil ? ISO8601DateFormatter().string(from: entity.approvedAt!) as Any : NSNull(),
            "rejection_reason": entity.rejectionReason as Any,
            "emergency_leave": entity.emergencyLeave
        ]
        
        // Convert to JSON and decode
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(LeaveRequest.self, from: jsonData)
        } catch {
            print("[WorkerLeaveViewModel+Offline] Error converting LeaveRequestEntity: \(error)")
            return nil
        }
    }
    
    /// Load offline leave balance
    private func loadOfflineLeaveBalance() async throws -> LeaveBalance? {
        // TODO: Implement when LeaveBalanceEntity is created in Core Data
        return nil
    }
    
    /// Load offline public holidays
    private func loadOfflinePublicHolidays() async throws -> [PublicHoliday] {
        // TODO: Implement when PublicHolidayEntity is created in Core Data
        return []
    }
    
    /// Save leave requests for offline access
    func saveForOffline(_ data: [LeaveRequest]) async throws {
        let context = CoreDataStack.shared.backgroundContext()
        
        try await context.perform {
            // Clear existing requests
            let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LeaveRequestEntity")
            let batchDelete = NSBatchDeleteRequest(fetchRequest: deleteRequest)
            try context.execute(batchDelete)
            
            // Save new requests
            for request in data {
                let cached = LeaveRequestEntity(context: context)
                cached.serverID = Int32(request.id)
                // Note: employeeId should be set via relationship, not directly
                cached.type = request.type.rawValue
                cached.startDate = request.start_date
                cached.endDate = request.end_date
                cached.totalDays = Int32(request.total_days)
                cached.halfDay = request.half_day
                cached.status = request.status.rawValue
                cached.reason = request.reason
                cached.sickNoteUrl = request.sick_note_url
                cached.createdAt = request.created_at
                cached.updatedAt = request.updated_at
                cached.approvedBy = Int32(request.approved_by ?? 0)
                cached.approvedAt = request.approved_at
                cached.rejectionReason = request.rejection_reason
                cached.emergencyLeave = request.emergency_leave
                cached.syncStatus = "synced"
                cached.lastModified = Date()
            }
            
            try context.save()
        }
    }
    
    /// Save leave balance for offline access
    private func saveLeaveBalanceForOffline(_ balance: LeaveBalance) async throws {
        // TODO: Implement when LeaveBalanceEntity is created in Core Data
    }
    
    /// Save public holidays for offline access
    private func savePublicHolidaysForOffline(_ holidays: [PublicHoliday]) async throws {
        // TODO: Implement when PublicHolidayEntity is created in Core Data
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
            // Fetch pending leave requests
            let pendingRequests = try await context.perform {
                let request: NSFetchRequest<LeaveRequestEntity> = LeaveRequestEntity.fetchRequest()
                request.predicate = NSPredicate(format: "syncStatus == %@", "pending")
                return try context.fetch(request)
            }
            
            // Sync each pending request
            for request in pendingRequests {
                try await syncLeaveRequest(request)
            }
            
            Self.syncStatusSubject.send(.synced)
            
        } catch {
            print("[WorkerLeaveRequestViewModel+Offline] Sync failed: \(error)")
            Self.syncStatusSubject.send(.syncFailed(error))
            throw error
        }
    }
    
    /// Sync individual leave request
    private func syncLeaveRequest(_ cached: LeaveRequestEntity) async throws {
        guard let employeeIdString = AuthService.shared.getEmployeeId(),
              let employeeId = Int(employeeIdString) else { return }
        
        let request = CreateLeaveRequestRequest(
            employee_id: employeeId,
            type: LeaveType(rawValue: cached.type ?? "") ?? .vacation,
            start_date: cached.startDate ?? Date(),
            end_date: cached.endDate ?? Date(),
            half_day: cached.halfDay,
            reason: cached.reason,
            emergency_leave: cached.emergencyLeave
        )
        
        // Submit to server
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var cancellable: AnyCancellable?
            
            cancellable = WorkerLeaveAPIService.shared.createLeaveRequest(request)
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
    
    /// Update sync status for cached request
    private func updateSyncStatus(for request: LeaveRequestEntity, to status: String) async throws {
        guard let context = request.managedObjectContext else { return }
        
        try await context.perform {
            request.syncStatus = status
            request.lastModified = Date()
            try context.save()
        }
    }
}

// MARK: - Create Leave Request ViewModel Offline Extension

extension CreateLeaveRequestViewModel {
    
    /// Submit request with offline support
    func submitRequestOfflineFirst(completion: @escaping (Bool) -> Void) {
        guard isValidRequest else {
            completion(false)
            return
        }
        
        isLoading = true
        
        Task { @MainActor in
            do {
                let connectivity = NetworkConnectivity.shared
                
                if connectivity.isConnected {
                    // Try online submission first
                    submitRequest(completion: completion)
                } else {
                    // Save locally for later sync
                    try await saveRequestLocally()
                    
                    // Show offline success message
                    self.successMessage = "Your leave request has been saved and will be submitted when you're back online"
                    self.submitSuccessDetails = "The request will be automatically synced when connection is restored"
                    self.showingSuccessAlert = true
                    self.resetForm()
                    
                    completion(true)
                }
            } catch {
                self.errorMessage = "Failed to save leave request: \(error.localizedDescription)"
                self.showingErrorAlert = true
                completion(false)
            }
            
            isLoading = false
        }
    }
    
    /// Save leave request locally for offline sync
    private func saveRequestLocally() async throws {
        let context = CoreDataStack.shared.backgroundContext()
        
        guard let employeeIdString = AuthService.shared.getEmployeeId(),
              let _ = Int(employeeIdString) else {
            throw NSError(domain: "LeaveRequest", code: -1, userInfo: [NSLocalizedDescriptionKey: "Employee ID not found"])
        }
        
        try await context.perform {
            let cached = LeaveRequestEntity(context: context)
            cached.serverID = Int32.random(in: 100000...999999) // Temporary ID
            // Note: employeeId should be set via relationship, not directly
            cached.type = self.selectedLeaveType.rawValue
            cached.startDate = self.startDate
            cached.endDate = self.endDate
            cached.totalDays = Int32(self.workDaysCount ?? 0)
            cached.halfDay = self.isHalfDay
            cached.status = LeaveStatus.pending.rawValue
            cached.reason = self.reason.isEmpty ? nil : self.reason
            cached.emergencyLeave = self.isEmergencyLeave
            cached.createdAt = Date()
            cached.updatedAt = Date()
            cached.syncStatus = "pending"
            
            try context.save()
        }
    }
}