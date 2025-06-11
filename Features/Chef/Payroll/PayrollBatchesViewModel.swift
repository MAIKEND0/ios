//
//  PayrollBatchesViewModel.swift
//  KSR Cranes App
//
//  ViewModel obsługujący logikę zarządzania partiami wypłat
//

import SwiftUI
import Combine
import Foundation

class PayrollBatchesViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var batches: [PayrollBatch] = []
    @Published var stats: BatchStats = BatchStats(
        totalBatches: 0,
        draftBatches: 0,
        pendingApprovalBatches: 0,
        approvedBatches: 0,
        completedBatches: 0,
        failedBatches: 0,
        totalAmount: Decimal(0),
        avgProcessingTime: 0.0
    )
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedStatusFilter: BatchStatusFilter = .all
    @Published var selectedBatch: PayrollBatch?
    
    // Alert and confirmation states
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showConfirmationAlert = false
    @Published var confirmationMessage = ""
    @Published var confirmationAction: BatchConfirmationAction = .approve
    @Published var showBatchDetails = false
    
    private var apiService: PayrollAPIService {
        return PayrollAPIService.shared
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var pendingAction: (() -> Void)?
    
    // MARK: - Computed Properties
    
    var filteredBatches: [PayrollBatch] {
        var filtered = batches
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { batch in
                batch.batchNumber.localizedCaseInsensitiveContains(searchText) ||
                String(batch.totalEmployees).contains(searchText) ||
                batch.notes?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply status filter
        if selectedStatusFilter != .all {
            filtered = filtered.filter { selectedStatusFilter.matches($0.status) }
        }
        
        // Sort by creation date, newest first
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Initialization
    
    init() {
        setupSearchDebounce()
        loadData() // Load real data on initialization
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        #if DEBUG
        print("[PayrollBatchesViewModel] Loading payroll batches...")
        #endif
        
        // Combine stats and batches loading
        let statsPublisher = apiService.fetchBatchStats()
        let batchesPublisher = apiService.fetchPayrollBatches()
        
        Publishers.CombineLatest(statsPublisher, batchesPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "loading payroll batches")
                        // Reset to empty state if API fails
                        self?.resetToEmptyState()
                    }
                },
                receiveValue: { [weak self] (stats, batches) in
                    self?.stats = stats
                    self?.batches = batches
                    
                    #if DEBUG
                    print("[PayrollBatchesViewModel] Loaded \(batches.count) batches")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshData() {
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
    
    private func resetToEmptyState() {
        stats = BatchStats(
            totalBatches: 0,
            draftBatches: 0,
            pendingApprovalBatches: 0,
            approvedBatches: 0,
            completedBatches: 0,
            failedBatches: 0,
            totalAmount: Decimal(0),
            avgProcessingTime: 0.0
        )
        batches = []
        
        #if DEBUG
        print("[PayrollBatchesViewModel] Reset to empty state")
        #endif
    }
    
    private func generateMockBatches() -> [PayrollBatch] {
        let statuses: [PayrollBatchStatus] = [.draft, .readyForApproval, .approved, .sentToZenegy, .completed, .failed]
        let calendar = Calendar.current
        var batches: [PayrollBatch] = []
        
        for i in 0..<15 {
            let status = statuses[i % statuses.count]
            let createdDate = calendar.date(byAdding: .day, value: -i * 3, to: Date()) ?? Date()
            let periodStart = calendar.date(byAdding: .day, value: -14, to: createdDate) ?? createdDate
            let periodEnd = calendar.date(byAdding: .day, value: -1, to: createdDate) ?? createdDate
            
            let employees = Int.random(in: 8...25)
            let hours = Double.random(in: 300.0...1000.0)
            let amount = Decimal(Double.random(in: 25000.0...75000.0))
            
            var approvedBy: Int? = nil
            var approvedAt: Date? = nil
            var sentToZenegyAt: Date? = nil
            var zenegySyncStatus: ZenegySyncStatus? = nil
            
            // Set up realistic status progression
            if status.rawValue != "draft" {
                if status == .approved || status == .sentToZenegy || status == .completed {
                    approvedBy = 1
                    approvedAt = calendar.date(byAdding: .hour, value: Int.random(in: 1...24), to: createdDate)
                }
                
                if status == .sentToZenegy || status == .completed {
                    sentToZenegyAt = calendar.date(byAdding: .hour, value: Int.random(in: 25...48), to: createdDate)
                    zenegySyncStatus = status == .completed ? .completed : .syncing
                }
                
                if status == .failed {
                    zenegySyncStatus = .failed
                }
            }
            
            let batch = PayrollBatch(
                id: i + 1,
                batchNumber: "2024-\(String(format: "%02d", i + 1))",
                periodStart: periodStart,
                periodEnd: periodEnd,
                year: calendar.component(.year, from: createdDate),
                periodNumber: i + 1,
                totalEmployees: employees,
                totalHours: hours,
                totalAmount: amount,
                status: status,
                createdBy: 1,
                createdAt: createdDate,
                approvedBy: approvedBy,
                approvedAt: approvedAt,
                sentToZenegyAt: sentToZenegyAt,
                zenegySyncStatus: zenegySyncStatus,
                notes: i % 3 == 0 ? "Auto-generated batch from pending hours" : nil
            )
            
            batches.append(batch)
        }
        
        return batches
    }
    
    // MARK: - Search Setup
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { _ in
                #if DEBUG
                print("[PayrollBatchesViewModel] Search filter applied")
                #endif
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Filter Helpers
    
    func getCountForFilter(_ filter: BatchStatusFilter) -> Int {
        if filter == .all {
            return batches.count
        }
        return batches.filter { filter.matches($0.status) }.count
    }
    
    // MARK: - Batch Actions
    
    func selectBatch(_ batch: PayrollBatch) {
        selectedBatch = batch
        #if DEBUG
        print("[PayrollBatchesViewModel] Selected batch: \(batch.batchNumber)")
        #endif
    }
    
    func viewBatchDetails(_ batch: PayrollBatch) {
        selectedBatch = batch
        showBatchDetails = true
        
        #if DEBUG
        print("[PayrollBatchesViewModel] View details for batch: \(batch.batchNumber)")
        #endif
    }
    
    func approveBatch(_ batchId: Int) {
        guard let batch = batches.first(where: { $0.id == batchId }) else { return }
        
        performBatchAction(
            batchId: batchId,
            action: .approve,
            confirmationMessage: "Are you sure you want to approve batch #\(batch.batchNumber)? This will make it ready for Zenegy sync."
        )
    }
    
    func sendBatchToZenegy(_ batchId: Int) {
        guard let batch = batches.first(where: { $0.id == batchId }) else { return }
        
        performBatchAction(
            batchId: batchId,
            action: .sendToZenegy,
            confirmationMessage: "Send batch #\(batch.batchNumber) to Zenegy? This will initiate payroll processing."
        )
    }
    
    func cancelBatch(_ batchId: Int) {
        guard let batch = batches.first(where: { $0.id == batchId }) else { return }
        
        performBatchAction(
            batchId: batchId,
            action: .cancel,
            confirmationMessage: "Cancel batch #\(batch.batchNumber)? This action cannot be undone."
        )
    }
    
    func retrySyncBatch(_ batchId: Int) {
        guard let batch = batches.first(where: { $0.id == batchId }) else { return }
        
        performBatchAction(
            batchId: batchId,
            action: .retrySync,
            confirmationMessage: "Retry Zenegy sync for batch #\(batch.batchNumber)?"
        )
    }
    
    // MARK: - Action Performance
    
    private func performBatchAction(batchId: Int, action: BatchAction, confirmationMessage: String) {
        self.confirmationMessage = confirmationMessage
        self.confirmationAction = BatchConfirmationAction(from: action)
        
        pendingAction = { [weak self] in
            self?.executeBatchAction(batchId: batchId, action: action)
        }
        
        showConfirmationAlert = true
    }
    
    func executeConfirmedAction() {
        pendingAction?()
        pendingAction = nil
    }
    
    private func executeBatchAction(batchId: Int, action: BatchAction) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        #if DEBUG
        print("[PayrollBatchesViewModel] Executing \(action.rawValue) for batch \(batchId)")
        #endif
        
        let publisher: AnyPublisher<PayrollBatch, BaseAPIService.APIError>
        
        switch action {
        case .approve:
            publisher = apiService.approvePayrollBatch(id: batchId)
        case .sendToZenegy:
            publisher = apiService.syncToZenegy(batchId: batchId)
                .map { _ in
                    // Return updated batch after sync
                    var updatedBatch = self.batches.first { $0.id == batchId }!
                    updatedBatch = PayrollBatch(
                        id: updatedBatch.id,
                        batchNumber: updatedBatch.batchNumber,
                        periodStart: updatedBatch.periodStart,
                        periodEnd: updatedBatch.periodEnd,
                        year: updatedBatch.year,
                        periodNumber: updatedBatch.periodNumber,
                        totalEmployees: updatedBatch.totalEmployees,
                        totalHours: updatedBatch.totalHours,
                        totalAmount: updatedBatch.totalAmount,
                        status: .sentToZenegy,
                        createdBy: updatedBatch.createdBy,
                        createdAt: updatedBatch.createdAt,
                        approvedBy: updatedBatch.approvedBy,
                        approvedAt: updatedBatch.approvedAt,
                        sentToZenegyAt: Date(),
                        zenegySyncStatus: .syncing,
                        notes: updatedBatch.notes
                    )
                    return updatedBatch
                }
                .eraseToAnyPublisher()
        case .cancel, .retrySync:
            // Mock implementation for cancel/retry
            publisher = Just(batches.first { $0.id == batchId }!)
                .setFailureType(to: BaseAPIService.APIError.self)
                .delay(for: .milliseconds(1000), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "performing batch action")
                    }
                },
                receiveValue: { [weak self] updatedBatch in
                    self?.handleBatchActionSuccess(updatedBatch: updatedBatch, action: action)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleBatchActionSuccess(updatedBatch: PayrollBatch, action: BatchAction) {
        // Update local batch
        if let index = batches.firstIndex(where: { $0.id == updatedBatch.id }) {
            batches[index] = updatedBatch
        }
        
        let message = action.successMessage(for: updatedBatch.batchNumber)
        showSuccess("Success", message)
        
        #if DEBUG
        print("[PayrollBatchesViewModel] \(action.rawValue) completed for batch \(updatedBatch.batchNumber)")
        #endif
    }
    
    // MARK: - Error Handling
    
    private func handleAPIError(_ error: BaseAPIService.APIError, context: String) {
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
        print("[PayrollBatchesViewModel] API Error in \(context): \(error)")
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
    
    // MARK: - Analytics Helpers
    
    func getTotalValueForStatus(_ status: PayrollBatchStatus) -> Decimal {
        return batches
            .filter { $0.status == status }
            .reduce(Decimal(0)) { $0 + $1.totalAmount }
    }
    
    func getAverageProcessingTime() -> TimeInterval {
        let completedBatches = batches.filter { $0.status == .completed }
        guard !completedBatches.isEmpty else { return 0 }
        
        let totalTime = completedBatches.reduce(TimeInterval(0)) { total, batch in
            guard let approvedAt = batch.approvedAt else { return total }
            return total + batch.createdAt.timeIntervalSince(approvedAt)
        }
        
        return totalTime / Double(completedBatches.count)
    }
    
    func getBatchesInLastDays(_ days: Int) -> [PayrollBatch] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return batches.filter { $0.createdAt >= cutoffDate }
    }
}

// MARK: - API Service Extension

extension PayrollAPIService {
    func fetchBatchStats() -> AnyPublisher<BatchStats, APIError> {
        let endpoint = "/api/app/chef/payroll/batches/stats"
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: BatchStats.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

enum BatchAction: String {
    case approve = "approve"
    case sendToZenegy = "send_to_zenegy"
    case cancel = "cancel"
    case retrySync = "retry_sync"
    
    func successMessage(for batchNumber: String) -> String {
        switch self {
        case .approve:
            return "Batch #\(batchNumber) has been approved and is ready for Zenegy sync."
        case .sendToZenegy:
            return "Batch #\(batchNumber) has been sent to Zenegy for processing."
        case .cancel:
            return "Batch #\(batchNumber) has been cancelled."
        case .retrySync:
            return "Zenegy sync retry initiated for batch #\(batchNumber)."
        }
    }
}

struct BatchConfirmationAction {
    let title: String
    let isDestructive: Bool
    
    init(from action: BatchAction) {
        switch action {
        case .approve:
            title = "Approve"
            isDestructive = false
        case .sendToZenegy:
            title = "Send to Zenegy"
            isDestructive = false
        case .cancel:
            title = "Cancel Batch"
            isDestructive = true
        case .retrySync:
            title = "Retry Sync"
            isDestructive = false
        }
    }
    
    static let approve = BatchConfirmationAction(from: .approve)
}
