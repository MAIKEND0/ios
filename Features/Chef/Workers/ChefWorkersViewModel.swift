//
//  ChefWorkersViewModel.swift
//  KSR Cranes App
//  ViewModel for Chef workers management
//

import Foundation
import Combine
import UIKit

class ChefWorkersViewModel: ObservableObject {
    @Published var workers: [WorkerForChef] = []
    @Published var filteredWorkers: [WorkerForChef] = []
    @Published var overallStats: WorkersOverallStats?
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var searchText = ""
    @Published var selectedStatuses: Set<WorkerStatus> = []  // Empty means show all statuses
    @Published var selectedEmploymentTypes: Set<EmploymentType> = []
    @Published var selectedRoles: Set<WorkerRole> = []
    @Published var lastRefreshTime: Date?
    
    // Filters
    @Published var minHourlyRate: Double = 0
    @Published var maxHourlyRate: Double = 1000
    @Published var showOnlyActiveAssignments = false
    
    // Temporary status cache until server implements proper status storage
    private var statusCache: [Int: WorkerStatus] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = ChefWorkersAPIService.shared
    
    init() {
        // Delay binding setup to next run loop to avoid potential initialization issues
        DispatchQueue.main.async { [weak self] in
            self?.setupBindings()
        }
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Filter workers when search text or filters change
        Publishers.CombineLatest4($workers, $searchText, $selectedStatuses, $selectedEmploymentTypes)
            .combineLatest(Publishers.CombineLatest4($selectedRoles, $minHourlyRate, $maxHourlyRate, $showOnlyActiveAssignments))
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .map { [weak self] (firstGroup, secondGroup) in
                let (workers, searchText, statuses, employmentTypes) = firstGroup
                let (roles, minRate, maxRate, activeOnly) = secondGroup
                guard let self = self else { return [] }
                return self.filterWorkers(
                    workers, 
                    searchText: searchText, 
                    statuses: statuses, 
                    employmentTypes: employmentTypes, 
                    roles: roles,
                    minRate: minRate,
                    maxRate: maxRate,
                    activeOnly: activeOnly
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] workers in
                self?.filteredWorkers = workers
            }
            .store(in: &cancellables)
    }
    
    private func filterWorkers(
        _ workers: [WorkerForChef],
        searchText: String,
        statuses: Set<WorkerStatus>,
        employmentTypes: Set<EmploymentType>,
        roles: Set<WorkerRole>,
        minRate: Double,
        maxRate: Double,
        activeOnly: Bool
    ) -> [WorkerForChef] {
        return workers.filter { worker in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                worker.name.localizedCaseInsensitiveContains(searchText) ||
                worker.email.localizedCaseInsensitiveContains(searchText) ||
                (worker.phone?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            // Status filter - if empty, show all statuses
            let matchesStatus = statuses.isEmpty || statuses.contains(worker.status)
            
            // Employment type filter
            let matchesEmploymentType = employmentTypes.isEmpty || employmentTypes.contains(worker.employment_type)
            
            // Role filter
            let matchesRole = roles.isEmpty || roles.contains(worker.role)
            
            // Rate filter
            let matchesRate = worker.hourly_rate >= minRate && worker.hourly_rate <= maxRate
            
            // Active assignments filter
            let matchesActiveAssignments = !activeOnly || (worker.stats?.active_tasks ?? 0) > 0
            
            return matchesSearch && matchesStatus && matchesEmploymentType && matchesRole && matchesRate && matchesActiveAssignments
        }.sorted { $0.name < $1.name }
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        guard !isLoading else { return }
        
        #if DEBUG
        print("[ChefWorkersViewModel] Loading workers data...")
        #endif
        
        isLoading = true
        
        Publishers.Zip(
            apiService.fetchWorkers(includeProfileImage: true, includeStats: true, includeCertificates: true),
            apiService.fetchWorkersStats()
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleAPIError(error, context: "loading workers data")
                }
            },
            receiveValue: { [weak self] workers, stats in
                #if DEBUG
                print("[ChefWorkersViewModel] ✅ Loaded \(workers.count) workers")
                #endif
                
                // Apply cached statuses to workers
                var updatedWorkers = workers
                if let self = self {
                    for (index, worker) in updatedWorkers.enumerated() {
                        if let cachedStatus = self.statusCache[worker.id] {
                            // Create new worker with cached status
                            updatedWorkers[index] = WorkerForChef(
                                id: worker.id,
                                name: worker.name,
                                email: worker.email,
                                phone: worker.phone,
                                address: worker.address,
                                hourly_rate: worker.hourly_rate,
                                employment_type: worker.employment_type,
                                role: worker.role,
                                status: cachedStatus,  // Use cached status
                                profile_picture_url: worker.profile_picture_url,
                                created_at: worker.created_at,
                                last_active: worker.last_active,
                                stats: worker.stats,
                                certificates: worker.certificates
                            )
                        }
                    }
                }
                
                self?.workers = updatedWorkers
                self?.overallStats = stats
                self?.lastRefreshTime = Date()
            }
        )
        .store(in: &cancellables)
    }
    
    func refreshData() {
        lastRefreshTime = nil
        loadData()
    }
    
    // MARK: - Search
    
    func searchWorkers(query: String) {
        searchText = query
        
        // If query is not empty and has more than 2 characters, perform API search
        if !query.isEmpty && query.count > 2 {
            apiService.searchWorkers(query: query)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            #if DEBUG
                            print("[ChefWorkersViewModel] Search error: \(error)")
                            #endif
                        }
                    },
                    receiveValue: { [weak self] response in
                        // Update with search results if they're more specific
                        if response.workers.count < self?.workers.count ?? 0 {
                            self?.workers = response.workers
                        }
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Filters
    
    func toggleStatusFilter(_ status: WorkerStatus) {
        if selectedStatuses.contains(status) {
            selectedStatuses.remove(status)
        } else {
            selectedStatuses.insert(status)
        }
    }
    
    func toggleEmploymentTypeFilter(_ type: EmploymentType) {
        if selectedEmploymentTypes.contains(type) {
            selectedEmploymentTypes.remove(type)
        } else {
            selectedEmploymentTypes.insert(type)
        }
    }
    
    func toggleRoleFilter(_ role: WorkerRole) {
        if selectedRoles.contains(role) {
            selectedRoles.remove(role)
        } else {
            selectedRoles.insert(role)
        }
    }
    
    func clearAllFilters() {
        selectedStatuses = []  // Empty means show all statuses
        selectedEmploymentTypes = []
        selectedRoles = []
        minHourlyRate = 0
        maxHourlyRate = 1000
        showOnlyActiveAssignments = false
        searchText = ""
    }
    
    // MARK: - CRUD Operations
    
    func addWorker(_ worker: WorkerForChef) {
        // Insert the new worker at the beginning of the list
        workers.insert(worker, at: 0)
        
        #if DEBUG
        print("[ChefWorkersViewModel] ✅ Added worker: \(worker.name)")
        #endif
        
        // Refresh stats
        refreshStats()
    }
    
    func updateWorker(_ updatedWorker: WorkerForChef) {
        if let index = workers.firstIndex(where: { $0.id == updatedWorker.id }) {
            workers[index] = updatedWorker
            
            #if DEBUG
            print("[ChefWorkersViewModel] ✅ Updated worker: \(updatedWorker.name)")
            #endif
        }
    }
    
    func deleteWorker(_ worker: WorkerForChef) {
        // Show confirmation alert
        showConfirmationAlert(
            title: "Delete Worker",
            message: "Are you sure you want to delete \(worker.name)? This action cannot be undone.",
            confirmAction: {
                self.performDeleteWorker(worker)
            }
        )
    }
    
    private func performDeleteWorker(_ worker: WorkerForChef) {
        apiService.deleteWorker(id: worker.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "deleting worker")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        self?.workers.removeAll { $0.id == worker.id }
                        self?.showSuccess("Worker deleted successfully")
                        self?.refreshStats()
                        
                        #if DEBUG
                        print("[ChefWorkersViewModel] ✅ Deleted worker: \(worker.name)")
                        #endif
                    } else {
                        self?.showError("Failed to delete worker: \(response.message)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func updateWorkerStatus(_ worker: WorkerForChef, newStatus: WorkerStatus) {
        apiService.updateWorkerStatus(workerId: worker.id, status: newStatus)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "updating worker status")
                    }
                },
                receiveValue: { [weak self] updatedWorker in
                    // Cache the new status
                    self?.statusCache[updatedWorker.id] = updatedWorker.status
                    
                    self?.updateWorker(updatedWorker)
                    self?.showSuccess("Worker status updated successfully")
                    
                    #if DEBUG
                    print("[ChefWorkersViewModel] ✅ Updated status for: \(updatedWorker.name) to \(updatedWorker.status.rawValue)")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Helpers
    
    private func refreshStats() {
        apiService.fetchWorkersStats()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        #if DEBUG
                        print("[ChefWorkersViewModel] Failed to refresh stats: \(error)")
                        #endif
                    }
                },
                receiveValue: { [weak self] stats in
                    self?.overallStats = stats
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleAPIError(_ error: ChefWorkersAPIService.APIError, context: String) {
        #if DEBUG
        print("[ChefWorkersViewModel] ❌ API Error (\(context)): \(error)")
        #endif
        
        let message: String
        switch error {
        case .networkError:
            message = "Network error. Please check your connection and try again."
        case .serverError(let code, let serverMessage):
            message = "Server error (\(code)): \(serverMessage)"
        case .decodingError:
            message = "Error processing server response. Please try again."
        default:
            message = "An unexpected error occurred. Please try again."
        }
        
        showError(message)
    }
    
    private func showError(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccess(_ message: String) {
        alertTitle = "Success"
        alertMessage = message
        showAlert = true
    }
    
    private func showConfirmationAlert(title: String, message: String, confirmAction: @escaping () -> Void) {
        // For now, just execute the action. In a real app, you'd want to show a proper confirmation dialog
        confirmAction()
    }
    
}

// MARK: - Extensions

extension ChefWorkersViewModel {
    var hasActiveFilters: Bool {
        return !selectedStatuses.isEmpty ||  // Not empty means filters are active
               !selectedEmploymentTypes.isEmpty ||
               !selectedRoles.isEmpty ||
               minHourlyRate > 0 ||
               maxHourlyRate < 1000 ||
               showOnlyActiveAssignments ||
               !searchText.isEmpty
    }
    
    var activeFiltersCount: Int {
        var count = 0
        if !selectedStatuses.isEmpty { count += 1 }  // Count when filters are active
        if !selectedEmploymentTypes.isEmpty { count += 1 }
        if !selectedRoles.isEmpty { count += 1 }
        if minHourlyRate > 0 || maxHourlyRate < 1000 { count += 1 }
        if showOnlyActiveAssignments { count += 1 }
        if !searchText.isEmpty { count += 1 }
        return count
    }
    
    func getWorkerById(_ id: Int) -> WorkerForChef? {
        return workers.first { $0.id == id }
    }
    
    func getTopPerformers(limit: Int = 5) -> [WorkerForChef] {
        return workers
            .filter { $0.stats != nil }
            .sorted { (first, second) in
                guard let firstStats = first.stats, let secondStats = second.stats else {
                    return false
                }
                return (firstStats.approval_rate ?? 0) > (secondStats.approval_rate ?? 0)
            }
            .prefix(limit)
            .map { $0 }
    }
    
    func getTotalHoursThisWeek() -> Double {
        return workers.compactMap { $0.stats?.hours_this_week }.reduce(0, +)
    }
    
    func getTotalHoursThisMonth() -> Double {
        return workers.compactMap { $0.stats?.hours_this_month }.reduce(0, +)
    }
}