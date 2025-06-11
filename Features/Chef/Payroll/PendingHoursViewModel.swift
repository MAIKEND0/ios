//
//  PendingHoursViewModel.swift
//  KSR Cranes App
//
//  ViewModel obsługujący logikę ekranu Pending Hours
//

import SwiftUI
import Combine
import Foundation

class PendingHoursViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var workEntries: [WorkEntryForReview] = []
    @Published var selectedWorkEntries: Set<Int> = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedFilter: HoursFilter = .all
    
    // Alert and confirmation states
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showConfirmationAlert = false
    @Published var confirmationMessage = ""
    @Published var confirmationAction: ConfirmationAction = .approve
    
    private var apiService: PayrollAPIService {
        return PayrollAPIService.shared
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var pendingAction: (() -> Void)?
    
    // MARK: - Computed Properties
    
    var filteredWorkEntries: [WorkEntryForReview] {
        var filtered = workEntries
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { entry in
                entry.employee.name.localizedCaseInsensitiveContains(searchText) ||
                entry.project.title.localizedCaseInsensitiveContains(searchText) ||
                entry.task.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply time-based filter
        switch selectedFilter {
        case .all:
            break
        case .thisWeek:
            filtered = filtered.filter { isThisWeek(entry: $0) }
        case .lastWeek:
            filtered = filtered.filter { isLastWeek(entry: $0) }
        case .highHours:
            filtered = filtered.filter { $0.totalHours >= 40.0 }
        }
        
        // Sort by total hours descending
        return filtered.sorted { $0.totalHours > $1.totalHours }
    }
    
    var hasSelectedItems: Bool {
        return !selectedWorkEntries.isEmpty
    }
    
    var totalCount: Int {
        return workEntries.count
    }
    
    var thisWeekCount: Int {
        return workEntries.filter { isThisWeek(entry: $0) }.count
    }
    
    var lastWeekCount: Int {
        return workEntries.filter { isLastWeek(entry: $0) }.count
    }
    
    var highHoursCount: Int {
        return workEntries.filter { $0.totalHours >= 40.0 }.count
    }
    
    var totalFilteredHours: Double {
        return filteredWorkEntries.reduce(0) { $0 + $1.totalHours }
    }
    
    var totalFilteredAmount: Decimal {
        return filteredWorkEntries.reduce(Decimal(0)) { $0 + $1.totalAmount }
    }
    
    // MARK: - Initialization
    
    init() {
        setupSearchDebounce()
        loadMockData() // Load mock data initially
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        #if DEBUG
        print("[PendingHoursViewModel] Loading pending work entries...")
        #endif
        
        apiService.fetchPendingWorkEntries()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "loading pending work entries")
                        // Fall back to mock data if API fails
                        self?.loadMockData()
                    }
                },
                receiveValue: { [weak self] entries in
                    self?.workEntries = entries
                    
                    #if DEBUG
                    print("[PendingHoursViewModel] Loaded \(entries.count) pending work entries")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshData() {
        selectedWorkEntries.removeAll()
        loadData()
    }
    
    func refreshAsync() async {
        await withCheckedContinuation { continuation in
            refreshData()
            // Simulate async completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
    
    // MARK: - Mock Data
    
    private func loadMockData() {
        // Generate mock work entries for testing
        let mockEntries = generateMockWorkEntries()
        workEntries = mockEntries
        
        #if DEBUG
        print("[PendingHoursViewModel] Loaded \(mockEntries.count) mock work entries")
        #endif
    }
    
    private func generateMockWorkEntries() -> [WorkEntryForReview] {
        // Simplified mock data generation without complex model construction
        let mockEntries: [WorkEntryForReview] = []
        
        #if DEBUG
        print("[PendingHoursViewModel] Mock data generation temporarily disabled - implement with correct model structure")
        #endif
        
        // TODO: Implement mock data generation once correct Employee/Project/ProjectTask constructors are available
        return mockEntries
    }
    
    // MARK: - Search Setup
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { _ in
                // Search is automatically applied through computed property
                #if DEBUG
                print("[PendingHoursViewModel] Search filter applied")
                #endif
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Filter Helpers
    
    private func isThisWeek(entry: WorkEntryForReview) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.startOfWeek(for: now)
        let endOfWeek = calendar.endOfWeek(for: now)
        
        return entry.periodCoverage.intersects(DateInterval(start: startOfWeek, end: endOfWeek))
    }
    
    private func isLastWeek(entry: WorkEntryForReview) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        guard let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else {
            return false
        }
        let startOfLastWeek = calendar.startOfWeek(for: lastWeek)
        let endOfLastWeek = calendar.endOfWeek(for: lastWeek)
        
        return entry.periodCoverage.intersects(DateInterval(start: startOfLastWeek, end: endOfLastWeek))
    }
    
    // MARK: - Selection Management
    
    func toggleSelection(_ entryId: Int, isSelected: Bool) {
        if isSelected {
            selectedWorkEntries.insert(entryId)
        } else {
            selectedWorkEntries.remove(entryId)
        }
        
        #if DEBUG
        print("[PendingHoursViewModel] Selection changed: \(selectedWorkEntries.count) items selected")
        #endif
    }
    
    func selectAll() {
        selectedWorkEntries = Set(filteredWorkEntries.map { $0.id })
        
        #if DEBUG
        print("[PendingHoursViewModel] Selected all \(selectedWorkEntries.count) filtered items")
        #endif
    }
    
    func clearSelection() {
        selectedWorkEntries.removeAll()
    }
    
    // MARK: - Individual Actions
    
    func approveWorkEntry(_ entryId: Int) {
        performBulkAction(
            entryIds: [entryId],
            action: .approve,
            confirmationMessage: "Are you sure you want to approve this work entry?"
        )
    }
    
    func rejectWorkEntry(_ entryId: Int) {
        performBulkAction(
            entryIds: [entryId],
            action: .reject,
            confirmationMessage: "Are you sure you want to reject this work entry? This action cannot be undone."
        )
    }
    
    func viewWorkEntryDetails(_ entryId: Int) {
        #if DEBUG
        print("[PendingHoursViewModel] View details for work entry: \(entryId)")
        #endif
        
        // TODO: Navigate to detail view
        showAlert("Details", "Work entry details view not implemented yet")
    }
    
    // MARK: - Bulk Actions
    
    func bulkApproveSelected() {
        guard !selectedWorkEntries.isEmpty else { return }
        
        performBulkAction(
            entryIds: Array(selectedWorkEntries),
            action: .approve,
            confirmationMessage: "Are you sure you want to approve \(selectedWorkEntries.count) work entries?"
        )
    }
    
    func bulkRejectSelected() {
        guard !selectedWorkEntries.isEmpty else { return }
        
        performBulkAction(
            entryIds: Array(selectedWorkEntries),
            action: .reject,
            confirmationMessage: "Are you sure you want to reject \(selectedWorkEntries.count) work entries? This action cannot be undone."
        )
    }
    
    func bulkRequestChanges() {
        guard !selectedWorkEntries.isEmpty else { return }
        
        performBulkAction(
            entryIds: Array(selectedWorkEntries),
            action: .requestChanges,
            confirmationMessage: "Request changes for \(selectedWorkEntries.count) work entries? Employees will be notified."
        )
    }
    
    // MARK: - Action Performance
    
    private func performBulkAction(entryIds: [Int], action: WorkEntryAction, confirmationMessage: String) {
        self.confirmationMessage = confirmationMessage
        self.confirmationAction = ConfirmationAction(from: action)
        
        pendingAction = { [weak self] in
            self?.executeBulkAction(entryIds: entryIds, action: action)
        }
        
        showConfirmationAlert = true
    }
    
    func executeConfirmedAction() {
        pendingAction?()
        pendingAction = nil
    }
    
    private func executeBulkAction(entryIds: [Int], action: WorkEntryAction) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        let request = BulkWorkEntryApprovalRequest(
            workEntryIds: entryIds,
            action: action,
            notes: nil
        )
        
        #if DEBUG
        print("[PendingHoursViewModel] Executing bulk \(action.rawValue) for \(entryIds.count) entries")
        #endif
        
        apiService.bulkApproveWorkEntries(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "performing bulk action")
                    }
                },
                receiveValue: { [weak self] result in
                    self?.handleBulkActionResult(result: result, action: action)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleBulkActionResult(result: BulkOperationResult, action: WorkEntryAction) {
        if result.isFullySuccessful {
            let message = "Successfully \(action.pastTense) \(result.successful.count) work entries"
            showSuccess("Success", message)
            
            // Remove processed entries from local state
            workEntries.removeAll { result.successful.contains($0.id) }
            selectedWorkEntries.removeAll()
            
        } else if result.successful.count > 0 {
            let message = "\(action.pastTense.capitalized) \(result.successful.count) of \(result.totalRequested) entries. \(result.failed.count) failed."
            showAlert("Partial Success", message)
            
            // Remove successful entries from local state
            workEntries.removeAll { result.successful.contains($0.id) }
            selectedWorkEntries = selectedWorkEntries.intersection(Set(result.failed.map { $0.id }))
            
        } else {
            showAlert("Action Failed", "Unable to \(action.rawValue) any work entries. Please try again.")
        }
        
        #if DEBUG
        print("[PendingHoursViewModel] Bulk action result: \(result.successRate * 100)% success rate")
        #endif
    }
    
    // MARK: - Error Handling
    
    private func handleAPIError(_ error: PayrollAPIService.APIError, context: String) {
        var title = "Error"
        var message = "An unexpected error occurred."
        
        switch error {
        case .invalidURL:
            title = "Invalid URL"
            message = "The request URL is invalid."
        case .invalidResponse:
            title = "Invalid Response"
            message = "The server response is invalid."
        case .networkError(let networkError):
            title = "Network Error"
            message = "Please check your internet connection and try again. (\(networkError.localizedDescription))"
        case .decodingError(let decodingError):
            title = "Data Error"
            message = "Unable to process the server response. (\(decodingError.localizedDescription))"
        case .serverError(let statusCode, let serverMessage):
            title = "Server Error"
            message = "Server returned error \(statusCode): \(serverMessage)"
        case .unknown:
            title = "Unknown Error"
            message = "An unexpected error occurred while \(context)."
        }
        
        showAlert(title, message)
        
        #if DEBUG
        print("[PendingHoursViewModel] API Error in \(context): \(error)")
        #endif
    }
    
    // MARK: - Alert Management
    
    private func showAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccess(_ title: String, _ message: String) {
        showAlert(title, message)
    }
}

// MARK: - Supporting Types

enum HoursFilter: CaseIterable {
    case all
    case thisWeek
    case lastWeek
    case highHours
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .thisWeek: return "This Week"
        case .lastWeek: return "Last Week"
        case .highHours: return "High Hours"
        }
    }
}

struct ConfirmationAction {
    let title: String
    let isDestructive: Bool
    
    init(from action: WorkEntryAction) {
        switch action {
        case .approve:
            title = "Approve"
            isDestructive = false
        case .reject:
            title = "Reject"
            isDestructive = true
        case .requestChanges:
            title = "Request Changes"
            isDestructive = false
        }
    }
    
    static let approve = ConfirmationAction(from: .approve)
}

// MARK: - Extensions

extension WorkEntryAction {
    var pastTense: String {
        switch self {
        case .approve: return "approved"
        case .reject: return "rejected"
        case .requestChanges: return "requested changes for"
        }
    }
}
