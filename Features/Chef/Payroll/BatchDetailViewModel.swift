//
//  BatchDetailViewModel.swift
//  KSR Cranes App
//
//  ViewModel obsługujący logikę szczegółów partii wypłat
//

import SwiftUI
import Combine
import Foundation

class BatchDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var topEmployees: [PayrollModels.BatchEmployeeBreakdown] = []
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    // Financial breakdown
    @Published var regularHours: Double = 0
    @Published var overtimeHours: Double = 0
    @Published var weekendHours: Double = 0
    @Published var regularHoursAmount: Decimal = 0
    @Published var overtimeAmount: Decimal = 0
    @Published var weekendAmount: Decimal = 0
    @Published var averageRegularRate: Decimal = 0
    @Published var averageOvertimeRate: Decimal = 0
    @Published var averageWeekendRate: Decimal = 0
    
    // Zenegy sync details
    @Published var syncedEmployees: Int = 0
    @Published var processingTime: Int = 0
    @Published var warningsCount: Int = 0
    @Published var hasSyncDetails: Bool = false
    @Published var hasWarnings: Bool = false
    
    private var allEmployees: [PayrollModels.BatchEmployeeBreakdown] = []
    private var currentBatch: PayrollBatch?
    
    // Use the correct PayrollAPIService from PayrollAPIService.swift
    private var apiService: PayrollAPIService {
        return PayrollAPIService.shared
    }
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasMoreEmployees: Bool {
        return allEmployees.count > topEmployees.count
    }
    
    var remainingEmployeesCount: Int {
        return allEmployees.count - topEmployees.count
    }
    
    // MARK: - Data Loading
    
    func loadBatchDetails(_ batch: PayrollBatch) {
        currentBatch = batch
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        #if DEBUG
        print("[BatchDetailViewModel] Loading details for batch: \(batch.batchNumber)")
        #endif
        
        // Load detailed batch information
        apiService.fetchBatchDetails(batchId: batch.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "loading batch details")
                        // Fall back to mock data
                        self?.loadMockData(for: batch)
                    }
                },
                receiveValue: { [weak self] details in
                    self?.processBatchDetails(details)
                    
                    #if DEBUG
                    print("[BatchDetailViewModel] Loaded details for \(details.employees.count) employees")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadMockData(for batch: PayrollBatch) {
        // Generate mock employee breakdown
        allEmployees = generateMockEmployeeBreakdown(for: batch)
        topEmployees = Array(allEmployees.prefix(5))
        
        // Generate mock financial breakdown
        calculateFinancialBreakdown(for: batch)
        
        // Generate mock Zenegy details if applicable
        loadMockZenegyDetails(for: batch)
        
        #if DEBUG
        print("[BatchDetailViewModel] Loaded mock data for batch: \(batch.batchNumber)")
        #endif
    }
    
    private func generateMockEmployeeBreakdown(for batch: PayrollBatch) -> [PayrollModels.BatchEmployeeBreakdown] {
        let employeeNames = [
            "Lars Hansen", "Anna Larsen", "Mikkel Jensen", "Sophie Nielsen",
            "Erik Andersen", "Maria Petersen", "Thomas Christensen", "Camilla Sørensen",
            "Niels Madsen", "Katrine Olsen", "Peter Rasmussen", "Line Poulsen",
            "Jonas Sommer", "Maja Lund", "Christian Berg"
        ]
        
        var employees: [PayrollModels.BatchEmployeeBreakdown] = []
        let totalEmployees = min(batch.totalEmployees, employeeNames.count)
        
        for i in 0..<totalEmployees {
            let name = employeeNames[i]
            let hours = Double.random(in: 35.0...55.0)
            let rate = Decimal(Double.random(in: 400.0...600.0))
            let amount = rate * Decimal(hours)
            
            let employee = PayrollModels.BatchEmployeeBreakdown(
                employeeId: i + 1,
                name: name,
                totalHours: hours,
                totalAmount: amount
            )
            
            employees.append(employee)
        }
        
        // Sort by total amount descending
        return employees.sorted { $0.totalAmount > $1.totalAmount }
    }
    
    private func calculateFinancialBreakdown(for batch: PayrollBatch) {
        // Mock calculation - in real app this would come from detailed work entries
        regularHours = batch.totalHours * 0.75 // 75% regular hours
        overtimeHours = batch.totalHours * 0.20 // 20% overtime
        weekendHours = batch.totalHours * 0.05 // 5% weekend
        
        averageRegularRate = Decimal(450.0)
        averageOvertimeRate = Decimal(675.0) // 1.5x regular
        averageWeekendRate = Decimal(600.0)
        
        regularHoursAmount = averageRegularRate * Decimal(regularHours)
        overtimeAmount = averageOvertimeRate * Decimal(overtimeHours)
        weekendAmount = averageWeekendRate * Decimal(weekendHours)
        
        #if DEBUG
        print("[BatchDetailViewModel] Financial breakdown calculated")
        print("- Regular: \(regularHours) hrs @ \(averageRegularRate) = \(regularHoursAmount)")
        print("- Overtime: \(overtimeHours) hrs @ \(averageOvertimeRate) = \(overtimeAmount)")
        print("- Weekend: \(weekendHours) hrs @ \(averageWeekendRate) = \(weekendAmount)")
        #endif
    }
    
    private func loadMockZenegyDetails(for batch: PayrollBatch) {
        guard batch.zenegySyncStatus != nil else { return }
        
        hasSyncDetails = true
        syncedEmployees = batch.totalEmployees
        processingTime = Int.random(in: 1500...4500)
        warningsCount = Int.random(in: 0...3)
        hasWarnings = warningsCount > 0
        
        #if DEBUG
        print("[BatchDetailViewModel] Zenegy details loaded - \(syncedEmployees) employees, \(processingTime)ms")
        #endif
    }
    
    // 🔧 FIXED: Use PayrollAPIService.BatchDetailResponse type
    private func processBatchDetails(_ details: PayrollAPIService.BatchDetailResponse) {
        allEmployees = details.employees
        topEmployees = Array(details.employees.prefix(5))
        
        // Process financial breakdown
        regularHours = details.financialBreakdown.regularHours
        overtimeHours = details.financialBreakdown.overtimeHours
        weekendHours = details.financialBreakdown.weekendHours
        regularHoursAmount = details.financialBreakdown.regularAmount
        overtimeAmount = details.financialBreakdown.overtimeAmount
        weekendAmount = details.financialBreakdown.weekendAmount
        averageRegularRate = details.financialBreakdown.averageRegularRate
        averageOvertimeRate = details.financialBreakdown.averageOvertimeRate
        averageWeekendRate = details.financialBreakdown.averageWeekendRate
        
        // Process Zenegy details if available
        if let zenegyDetails = details.zenegyDetails {
            hasSyncDetails = true
            syncedEmployees = zenegyDetails.employeesSynced
            processingTime = zenegyDetails.processingTimeMs
            warningsCount = zenegyDetails.warnings?.count ?? 0
            hasWarnings = warningsCount > 0
        }
    }
    
    // MARK: - Employee Management
    
    func showAllEmployees(_ batch: PayrollBatch) {
        #if DEBUG
        print("[BatchDetailViewModel] Show all \(allEmployees.count) employees for batch: \(batch.batchNumber)")
        #endif
        
        // TODO: Navigate to full employee list view
        showAlert("Employee List", "Full employee breakdown view not implemented yet")
    }
    
    // MARK: - Batch Actions
    
    func approveBatch(_ batch: PayrollBatch) {
        guard batch.canBeApproved else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        #if DEBUG
        print("[BatchDetailViewModel] Approving batch: \(batch.batchNumber)")
        #endif
        
        apiService.approvePayrollBatch(id: batch.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "approving batch")
                    }
                },
                receiveValue: { [weak self] updatedBatch in
                    self?.currentBatch = updatedBatch
                    self?.showSuccess("Success", "Batch #\(updatedBatch.batchNumber) has been approved")
                    
                    #if DEBUG
                    print("[BatchDetailViewModel] Batch approved successfully")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func sendToZenegy(_ batch: PayrollBatch) {
        guard batch.canBeSentToZenegy else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        #if DEBUG
        print("[BatchDetailViewModel] Sending batch to Zenegy: \(batch.batchNumber)")
        #endif
        
        apiService.syncToZenegy(batchId: batch.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "sending to Zenegy")
                    }
                },
                receiveValue: { [weak self] syncResult in
                    if syncResult.success {
                        self?.showSuccess("Success", "Batch #\(batch.batchNumber) has been sent to Zenegy")
                        
                        // Update sync details
                        if let details = syncResult.syncDetails {
                            self?.processSyncResult(details)
                        }
                    } else {
                        self?.showAlert("Sync Failed", syncResult.errorMessage ?? "Unknown error occurred")
                    }
                    
                    #if DEBUG
                    print("[BatchDetailViewModel] Zenegy sync result: \(syncResult.success)")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func retrySyncToZenegy(_ batch: PayrollBatch) {
        #if DEBUG
        print("[BatchDetailViewModel] Retrying Zenegy sync for batch: \(batch.batchNumber)")
        #endif
        
        // Same as sendToZenegy but for retry
        sendToZenegy(batch)
    }
    
    func cancelBatch(_ batch: PayrollBatch) {
        #if DEBUG
        print("[BatchDetailViewModel] Cancelling batch: \(batch.batchNumber)")
        #endif
        
        // TODO: Implement batch cancellation
        showAlert("Cancel Batch", "Batch cancellation not implemented yet")
    }
    
    // MARK: - Export and Sharing
    
    func exportBatchPDF(_ batch: PayrollBatch) {
        #if DEBUG
        print("[BatchDetailViewModel] Exporting PDF for batch: \(batch.batchNumber)")
        #endif
        
        // TODO: Implement PDF export
        showAlert("Export PDF", "PDF export functionality not implemented yet")
    }
    
    func shareBatchSummary(_ batch: PayrollBatch) {
        #if DEBUG
        print("[BatchDetailViewModel] Sharing summary for batch: \(batch.batchNumber)")
        #endif
        
        // TODO: Implement share functionality
        showAlert("Share Summary", "Share functionality not implemented yet")
    }
    
    func editBatch(_ batch: PayrollBatch) {
        #if DEBUG
        print("[BatchDetailViewModel] Editing batch: \(batch.batchNumber)")
        #endif
        
        // TODO: Navigate to edit batch view
        showAlert("Edit Batch", "Batch editing not implemented yet")
    }
    
    func viewBatchReports(_ batch: PayrollBatch) {
        #if DEBUG
        print("[BatchDetailViewModel] Viewing reports for batch: \(batch.batchNumber)")
        #endif
        
        // TODO: Navigate to reports view
        showAlert("Batch Reports", "Batch reports view not implemented yet")
    }
    
    // MARK: - Helper Methods
    
    private func processSyncResult(_ syncDetails: ZenegySyncDetails) {
        hasSyncDetails = true
        syncedEmployees = syncDetails.employeesSynced
        processingTime = syncDetails.processingTimeMs
        warningsCount = syncDetails.warnings?.count ?? 0
        hasWarnings = warningsCount > 0
        
        #if DEBUG
        print("[BatchDetailViewModel] Sync details updated: \(syncedEmployees) employees, \(processingTime)ms")
        #endif
    }
    
    // MARK: - Error Handling
    
    // 🔧 FIXED: Use BaseAPIService.APIError type
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
        print("[BatchDetailViewModel] API Error in \(context): \(error)")
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
