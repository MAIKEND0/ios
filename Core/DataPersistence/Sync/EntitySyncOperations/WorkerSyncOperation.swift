//
//  WorkerSyncOperation.swift
//  KSR Cranes App
//
//  Created by Sync Engine on 06/11/2025.
//

import Foundation
import CoreData
import Combine

/// Sync operation for Worker/Employee entities
@available(iOS 13.0, *)
final class WorkerSyncOperation: SyncOperation, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let apiService: ChefWorkersAPIService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext, operationType: SyncOperationType = .fullSync) {
        self.apiService = ChefWorkersAPIService.shared
        super.init(operationType: operationType, entityType: .employee, context: context)
    }
    
    // MARK: - Sync Implementation
    
    override func performSync() throws {
        switch operationType {
        case .download:
            try downloadWorkers()
        case .upload:
            try uploadLocalChanges()
        case .fullSync:
            try performFullSync()
        case .update:
            try updateWorker()
        case .delete:
            try deleteWorker()
        }
    }
    
    // MARK: - Download Operations
    
    private func downloadWorkers() throws {
        let semaphore = DispatchSemaphore(value: 0)
        var syncError: Error?
        
        // Fetch workers from API
        apiService.fetchWorkers(limit: 100, offset: 0)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        syncError = error
                    }
                    semaphore.signal()
                },
                receiveValue: { [weak self] response in
                    self?.processWorkerResponse(response)
                }
            )
            .store(in: &cancellables)
        
        _ = semaphore.wait(timeout: .now() + 30)
        
        if let error = syncError {
            throw error
        }
        
        // Save context
        try context.save()
        updateProgress(1.0)
    }
    
    private func processWorkerResponse(_ response: [WorkerForChef]) {
        let totalWorkers = response.count
        
        for (index, workerData) in response.enumerated() {
            autoreleasepool {
                processWorker(workerData)
                updateProgress(Double(index + 1) / Double(totalWorkers))
            }
        }
    }
    
    private func processWorker(_ workerData: WorkerForChef) {
        // Fetch or create employee entity
        let fetchRequest: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "serverID == %d", workerData.id)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            let employee = results.first ?? EmployeeEntity(context: context)
            
            // Update employee data
            employee.serverID = Int32(workerData.id)
            employee.name = workerData.name
            employee.email = workerData.email
            employee.phoneNumber = workerData.phone
            employee.address = workerData.address
            employee.role = workerData.role.rawValue
            employee.operatorNormalRate = NSDecimalNumber(value: workerData.hourly_rate)
            employee.isActivated = workerData.isActive
            employee.profilePictureUrl = workerData.profile_picture_url
            employee.createdAt = workerData.created_at
            employee.lastModified = Date()
            employee.syncStatus = "synced"
            
            #if DEBUG
            print("[WorkerSync] ✅ Processed worker: \(workerData.name)")
            #endif
            
        } catch {
            #if DEBUG
            print("[WorkerSync] ❌ Error processing worker \(workerData.id): \(error)")
            #endif
        }
    }
    
    // MARK: - Upload Operations
    
    private func uploadLocalChanges() throws {
        // Fetch employees with pending changes
        let fetchRequest: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "syncStatus == %@ OR syncStatus == %@", "pending", "modified")
        
        let employees = try context.fetch(fetchRequest)
        let totalEmployees = employees.count
        
        guard totalEmployees > 0 else {
            updateProgress(1.0)
            return
        }
        
        for (index, employee) in employees.enumerated() {
            try uploadEmployee(employee)
            updateProgress(Double(index + 1) / Double(totalEmployees))
        }
        
        try context.save()
    }
    
    private func uploadEmployee(_ employee: EmployeeEntity) throws {
        guard employee.syncStatus == "pending" || employee.syncStatus == "modified" else { return }
        
        let semaphore = DispatchSemaphore(value: 0)
        var syncError: Error?
        
        if employee.serverID == 0 {
            // Create new worker
            let request = CreateWorkerRequest(
                name: employee.name ?? "",
                email: employee.email ?? "",
                phone: employee.phoneNumber ?? "",
                address: employee.address ?? "",
                hourly_rate: employee.operatorNormalRate?.doubleValue ?? 0,
                employment_type: employee.role ?? "arbejder"
            )
            
            apiService.createWorker(request)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            syncError = error
                        }
                        semaphore.signal()
                    },
                    receiveValue: { response in
                        employee.serverID = Int32(response.id)
                        employee.syncStatus = "synced"
                    }
                )
                .store(in: &cancellables)
            
        } else {
            // Update existing worker
            let request = UpdateWorkerRequest(
                name: employee.name,
                email: employee.email,
                phone: employee.phoneNumber,
                address: employee.address,
                hourly_rate: employee.operatorNormalRate?.doubleValue,
                employment_type: employee.role,
                role: employee.role,  // Add role parameter
                status: employee.isActivated ? "aktiv" : "inaktiv",
                notes: nil  // Add notes parameter (optional)
            )
            
            apiService.updateWorker(id: Int(employee.serverID), data: request)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            syncError = error
                        }
                        semaphore.signal()
                    },
                    receiveValue: { _ in
                        employee.syncStatus = "synced"
                    }
                )
                .store(in: &cancellables)
        }
        
        _ = semaphore.wait(timeout: .now() + 10)
        
        if let error = syncError {
            employee.syncStatus = "error"
            throw error
        }
    }
    
    // MARK: - Full Sync
    
    private func performFullSync() throws {
        // Download all workers first
        try downloadWorkers()
        
        // Then upload any local changes
        try uploadLocalChanges()
    }
    
    // MARK: - Individual Operations
    
    private func updateWorker() throws {
        // Implementation for updating a specific worker
        // This would be called when syncing a single record
    }
    
    private func deleteWorker() throws {
        // Implementation for deleting a worker
        // Handle both local deletion and server sync
    }
}

// MARK: - Helper Extensions

extension EmployeeEntity {
    /// Check if entity has local modifications
    var hasLocalChanges: Bool {
        return syncStatus == "pending" || syncStatus == "modified"
    }
    
    /// Mark entity as modified for sync
    func markAsModified() {
        if syncStatus != "pending" {
            syncStatus = "modified"
        }
        lastModified = Date()
    }
}