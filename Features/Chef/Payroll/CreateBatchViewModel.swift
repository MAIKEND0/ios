//
//  CreateBatchViewModel.swift
//  KSR Cranes App
//
//  ViewModel obsługujący logikę tworzenia nowej partii wypłat
//

import SwiftUI
import Combine
import Foundation

// MARK: - Supporting Enums (if not defined elsewhere)
enum EmployeeRole: String, CaseIterable {
    case arbejder = "arbejder"
    case supervisor = "supervisor"
    case chef = "chef"
}

enum CBVMEmployeeCraneType: String, CaseIterable {
    case mobileCrane = "Mobile Crane"
    case towerCrane = "Tower Crane"
    case crawlerCrane = "Crawler Crane"
}

class CreateBatchViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Step management
    @Published var currentStep: CreateBatchStep = .selectPeriod
    @Published var isLoading = false
    
    // Step 1: Period Selection - 🔧 FIXED: Use PayrollAPIService.PayrollPeriodOption
    @Published var quickPeriodOptions: [PayrollAPIService.PayrollPeriodOption] = []
    @Published var selectedPeriod: PayrollAPIService.PayrollPeriodOption?
    @Published var customStartDate = Date()
    @Published var customEndDate = Date()
    
    // Step 2: Work Entries Review
    @Published var availableWorkEntries: [WorkEntryForReview] = []
    @Published var selectedWorkEntries: Set<Int> = []
    
    // Step 3: Batch Configuration
    @Published var batchNumber = ""
    @Published var batchNotes = ""
    @Published var createAsDraft = true
    
    // Alert and confirmation states
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showCancelConfirmation = false
    @Published var shouldDismissOnSuccess = false
    
    // Use the correct PayrollAPIService from PayrollAPIService.swift
    private var apiService: PayrollAPIService {
        return PayrollAPIService.shared
    }
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var canGoBack: Bool {
        return currentStep != .selectPeriod
    }
    
    var isLastStep: Bool {
        return currentStep == .confirmation
    }
    
    var canProceed: Bool {
        switch currentStep {
        case .selectPeriod:
            return selectedPeriod != nil
        case .reviewHours:
            return !selectedWorkEntries.isEmpty
        case .configureBatch:
            return true // All fields are optional or auto-generated
        case .confirmation:
            return true
        }
    }
    
    var nextButtonTitle: String {
        switch currentStep {
        case .selectPeriod:
            return "Review Hours"
        case .reviewHours:
            return "Configure Batch"
        case .configureBatch:
            return "Review & Create"
        case .confirmation:
            return isLoading ? "Creating..." : "Create Batch"
        }
    }
    
    var hasUnsavedChanges: Bool {
        return selectedPeriod != nil || !selectedWorkEntries.isEmpty || !batchNotes.isEmpty
    }
    
    var isCustomRangeValid: Bool {
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: customStartDate, to: customEndDate).day ?? 0
        
        // Must be exactly 14 days (2 weeks) and not in the future
        return daysDifference == 13 && customEndDate <= Date() && calendar.component(.weekday, from: customStartDate) == 2 // Monday
    }
    
    var totalSelectedHours: Double {
        return availableWorkEntries
            .filter { selectedWorkEntries.contains($0.id) }
            .reduce(0) { $0 + $1.totalHours }
    }
    
    var totalSelectedAmount: Decimal {
        return availableWorkEntries
            .filter { selectedWorkEntries.contains($0.id) }
            .reduce(Decimal(0)) { $0 + $1.totalAmount }
    }
    
    // MARK: - Initialization
    
    init() {
        setupInitialDates()
    }
    
    private func setupInitialDates() {
        let calendar = Calendar.current
        let now = Date()
        
        // KSR 2-week system: Find start of current bi-weekly period
        // Periods run Monday to Sunday, 2 weeks each
        let daysSinceMonday = calendar.component(.weekday, from: now) - 2
        let adjustedDays = daysSinceMonday < 0 ? daysSinceMonday + 7 : daysSinceMonday
        
        // Calculate which 2-week period we're in
        let mondayThisWeek = calendar.date(byAdding: .day, value: -adjustedDays, to: now) ?? now
        let weekOfYear = calendar.component(.weekOfYear, from: mondayThisWeek)
        let isEvenWeek = (weekOfYear % 2) == 0
        
        // Set dates to start of current or previous 2-week period
        if isEvenWeek {
            // Even week - start of current period
            customStartDate = mondayThisWeek
        } else {
            // Odd week - start of previous period (1 week back)
            customStartDate = calendar.date(byAdding: .day, value: -7, to: mondayThisWeek) ?? mondayThisWeek
        }
        
        // End date is always 13 days after start (2 full weeks)
        customEndDate = calendar.date(byAdding: .day, value: 13, to: customStartDate) ?? customStartDate
        
        // Generate initial batch number
        generateBatchNumber()
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        #if DEBUG
        print("[CreateBatchViewModel] Loading initial data...")
        #endif
        
        // Load available periods and work entries
        let periodsPublisher = apiService.fetchAvailablePayrollPeriods()
        let workEntriesPublisher = apiService.fetchAvailableWorkEntriesForBatch()
        
        Publishers.CombineLatest(periodsPublisher, workEntriesPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "loading initial data")
                        // Reset to empty state on API error
                        self?.resetToEmptyState()
                    }
                },
                receiveValue: { [weak self] (periods, workEntries) in
                    self?.quickPeriodOptions = periods
                    self?.availableWorkEntries = workEntries
                    
                    #if DEBUG
                    print("[CreateBatchViewModel] Loaded \(periods.count) periods and \(workEntries.count) work entries")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    private func resetToEmptyState() {
        quickPeriodOptions = []
        availableWorkEntries = []
        
        #if DEBUG
        print("[CreateBatchViewModel] Reset to empty state")
        #endif
    }
    
    private func generateMockWorkEntries() -> [WorkEntryForReview] {
        // For now, return empty array to avoid constructor issues
        // This should be implemented once the correct Employee and ProjectTask constructors are known
        return []
        
        /*
        // Generate 8-12 mock work entries
        let count = Int.random(in: 8...12)
        var entries: [WorkEntryForReview] = []
        
        let employees = [
            ("Lars Hansen", 1), ("Anna Larsen", 2), ("Mikkel Jensen", 3),
            ("Sophie Nielsen", 4), ("Erik Andersen", 5), ("Maria Petersen", 6),
            ("Thomas Christensen", 7), ("Camilla Sørensen", 8)
        ]
        
        let projects = [
            ("Tower Alpha Construction", 101),
            ("Vesterbro Residential", 102),
            ("Nørrebro Office Complex", 103)
        ]
        
        let tasks = [
            ("Crane Operation", 201),
            ("Equipment Setup", 202),
            ("Site Preparation", 203)
        ]
        
        for i in 0..<count {
            let employee = employees[i % employees.count]
            let project = projects[i % projects.count]
            let task = tasks[i % tasks.count]
            
            let hours = Double.random(in: 35.0...50.0)
            let rate = Decimal(Double.random(in: 400.0...550.0))
            let amount = rate * Decimal(hours)
            
            // TODO: Implement mock data generation once Employee and ProjectTask constructors are known
            // Current constructors cause compilation errors due to unknown parameter requirements
            
            // Create mock Employee with all required parameters
            let mockEmployee = Employee(
                id: employee.1,
                name: employee.0,
                email: "\(employee.0.lowercased().replacingOccurrences(of: " ", with: "."))@ksrcranes.dk",
                phoneNumber: "+45 \(String(format: "%08d", Int.random(in: 10000000...99999999)))",
                role: EmployeeRole.arbejder, // Use the correct enum type
                craneTypes: [EmployeeCraneType.mobileCrane], // Use enum array
                address: "Copenhagen, Denmark",
                emergencyContact: "Emergency Contact",
                cprNumber: "123456-7890",
                birthDate: Date(),
                profilePictureUrl: nil as String?, // Explicit type for nil
                hasDrivingLicense: true,
                drivingLicenseCategory: "B",
                drivingLicenseExpiration: Date(),
                isActivated: true
            )
            
            // Create mock Project with correct enum value
            let mockProject = Project(
                id: project.1,
                title: project.0,
                description: "Mock project",
                startDate: Date(),
                endDate: Date(),
                status: .active, // Use .active instead of .aktiv
                customerId: 1,
                street: "Mock Street",
                city: "Copenhagen",
                zip: "1000",
                isActive: true
            )
            
            // Create mock ProjectTask with basic constructor
            let mockTask = ProjectTask(
                id: task.1,
                projectId: project.1,
                title: task.0,
                description: "Mock task",
                deadline: Date(),
                isActive: true
            )
            
            let mockConfirmation = SupervisorConfirmation(
                supervisorId: 999,
                supervisorName: "Supervisor",
                confirmedAt: Date(),
                notes: nil as String?, // Explicit type for nil
                digitalSignature: nil as String? // Explicit type for nil
            )
            
            let entry = WorkEntryForReview(
                id: i + 1,
                employee: mockEmployee,
                project: mockProject,
                task: mockTask,
                workEntries: [],
                totalHours: hours,
                totalAmount: amount,
                supervisorConfirmation: mockConfirmation,
                periodCoverage: DateInterval(start: Date(), end: Date()),
                status: .pending
            )
            
            entries.append(entry)
        }
        
        return entries
        */
    }
    
    // MARK: - Step Navigation
    
    func goToNextStep() {
        guard canProceed else { return }
        
        switch currentStep {
        case .selectPeriod:
            loadWorkEntriesForPeriod()
            currentStep = .reviewHours
        case .reviewHours:
            generateBatchNumber()
            currentStep = .configureBatch
        case .configureBatch:
            currentStep = .confirmation
        case .confirmation:
            break // Handle in createBatch()
        }
        
        #if DEBUG
        print("[CreateBatchViewModel] Advanced to step: \(currentStep)")
        #endif
    }
    
    func goToPreviousStep() {
        guard canGoBack else { return }
        
        switch currentStep {
        case .selectPeriod:
            break
        case .reviewHours:
            currentStep = .selectPeriod
        case .configureBatch:
            currentStep = .reviewHours
        case .confirmation:
            currentStep = .configureBatch
        }
        
        #if DEBUG
        print("[CreateBatchViewModel] Returned to step: \(currentStep)")
        #endif
    }
    
    // MARK: - Period Selection
    
    // 🔧 FIXED: Use PayrollAPIService.PayrollPeriodOption type
    func selectPeriod(_ period: PayrollAPIService.PayrollPeriodOption) {
        selectedPeriod = period
        
        #if DEBUG
        print("[CreateBatchViewModel] Selected period: \(period.title)")
        #endif
    }
    
    func useCustomDateRange() {
        guard isCustomRangeValid else { return }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        // 🔧 FIXED: Create PayrollAPIService.PayrollPeriodOption
        let customPeriod = PayrollAPIService.PayrollPeriodOption(
            id: -1,
            title: "Custom Range",
            startDate: customStartDate,
            endDate: customEndDate,
            availableHours: 0, // Will be calculated when work entries are loaded
            estimatedAmount: Decimal(0)
        )
        
        selectedPeriod = customPeriod
        
        #if DEBUG
        print("[CreateBatchViewModel] Using custom date range: \(formatter.string(from: customStartDate)) - \(formatter.string(from: customEndDate))")
        #endif
    }
    
    private func loadWorkEntriesForPeriod() {
        guard let period = selectedPeriod else { return }
        
        #if DEBUG
        print("[CreateBatchViewModel] Loading work entries for period: \(period.title)")
        #endif
        
        // Filter available work entries by selected period
        // In real app, this would make API call with period parameters
        // For now, just filter mock data by date
        
        // Auto-select all available entries for convenience
        selectedWorkEntries = Set(availableWorkEntries.map { $0.id })
    }
    
    // MARK: - Work Entry Selection
    
    func isWorkEntrySelected(_ entryId: Int) -> Bool {
        return selectedWorkEntries.contains(entryId)
    }
    
    func toggleWorkEntrySelection(_ entryId: Int, isSelected: Bool) {
        if isSelected {
            selectedWorkEntries.insert(entryId)
        } else {
            selectedWorkEntries.remove(entryId)
        }
        
        #if DEBUG
        print("[CreateBatchViewModel] Work entry \(entryId) \(isSelected ? "selected" : "deselected"). Total: \(selectedWorkEntries.count)")
        #endif
    }
    
    func selectAllWorkEntries() {
        selectedWorkEntries = Set(availableWorkEntries.map { $0.id })
        
        #if DEBUG
        print("[CreateBatchViewModel] Selected all \(selectedWorkEntries.count) work entries")
        #endif
    }
    
    func clearAllWorkEntries() {
        selectedWorkEntries.removeAll()
        
        #if DEBUG
        print("[CreateBatchViewModel] Cleared all work entry selections")
        #endif
    }
    
    // MARK: - Batch Configuration
    
    func generateBatchNumber() {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let weekOfYear = calendar.component(.weekOfYear, from: Date())
        
        batchNumber = "\(year)-\(String(format: "%02d", weekOfYear))"
        
        #if DEBUG
        print("[CreateBatchViewModel] Generated batch number: \(batchNumber)")
        #endif
    }
    
    // MARK: - Batch Creation
    
    func createBatch() {
        guard canProceed else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        guard let period = selectedPeriod else {
            showAlert("Error", "No period selected")
            isLoading = false
            return
        }
        
        let request = CreatePayrollBatchRequest(
            periodStart: period.startDate,
            periodEnd: period.endDate,
            workEntryIds: Array(selectedWorkEntries),
            notes: batchNotes.isEmpty ? nil : batchNotes,
            batchNumber: batchNumber.isEmpty ? nil : batchNumber,
            isDraft: createAsDraft
        )
        
        #if DEBUG
        print("[CreateBatchViewModel] Creating batch with \(selectedWorkEntries.count) work entries")
        #endif
        
        apiService.createPayrollBatch(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "creating payroll batch")
                    }
                },
                receiveValue: { [weak self] batch in
                    self?.handleBatchCreationSuccess(batch)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleBatchCreationSuccess(_ batch: PayrollBatch) {
        shouldDismissOnSuccess = true
        showSuccess(
            "Batch Created Successfully",
            "Payroll batch #\(batch.batchNumber) has been created with \(batch.totalEmployees) employees. Total amount: \(batch.totalAmount.currencyFormatted)"
        )
        
        #if DEBUG
        print("[CreateBatchViewModel] Batch created successfully: \(batch.batchNumber)")
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
        print("[CreateBatchViewModel] API Error in \(context): \(error)")
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
    
    // MARK: - Helper Methods
    
    var uniqueEmployeeCount: Int {
        let selectedEntries = availableWorkEntries.filter { selectedWorkEntries.contains($0.id) }
        let uniqueEmployeeIds = Set(selectedEntries.map { $0.employee.id })
        return uniqueEmployeeIds.count
    }
}

// MARK: - Supporting Types

enum CreateBatchStep: Int, CaseIterable {
    case selectPeriod = 0
    case reviewHours = 1
    case configureBatch = 2
    case confirmation = 3
    
    var title: String {
        switch self {
        case .selectPeriod:
            return "Select Period"
        case .reviewHours:
            return "Review Hours"
        case .configureBatch:
            return "Configure Batch"
        case .confirmation:
            return "Confirmation"
        }
    }
    
    var description: String {
        switch self {
        case .selectPeriod:
            return "Choose the payroll period for this batch"
        case .reviewHours:
            return "Review and select work entries to include"
        case .configureBatch:
            return "Configure batch settings and add notes"
        case .confirmation:
            return "Review all details before creating the batch"
        }
    }
}

// 🔧 REMOVED: Duplicate PayrollPeriodOption struct - using PayrollAPIService.PayrollPeriodOption instead
