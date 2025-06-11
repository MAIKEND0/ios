//
//  WorkerLeaveViewModel.swift
//  KSR Cranes App
//
//  Worker Leave Management ViewModels
//  Handles leave requests, balance tracking, and document uploads for workers
//

import Foundation
import Combine
import SwiftUI

// MARK: - Worker Leave Request ViewModel

@MainActor
class WorkerLeaveRequestViewModel: ObservableObject {
    @Published var leaveRequests: [LeaveRequest] = []
    @Published var leaveBalance: LeaveBalance?
    @Published var publicHolidays: [PublicHoliday] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefresh: Date?
    
    // Filtering
    @Published var selectedStatusFilter: LeaveStatus?
    @Published var selectedTypeFilter: LeaveType?
    @Published var isShowingFilters = false
    
    private let apiService = WorkerLeaveAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadInitialData()
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() {
        isLoading = true
        
        Publishers.Zip3(
            loadLeaveRequests(),
            loadLeaveBalance(),
            loadPublicHolidays()
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                } else {
                    self?.lastRefresh = Date()
                }
            },
            receiveValue: { _, _, _ in
                // Data loaded successfully
            }
        )
        .store(in: &cancellables)
    }
    
    func refreshData() {
        loadInitialData()
    }
    
    private func loadLeaveRequests() -> AnyPublisher<Void, BaseAPIService.APIError> {
        let params = LeaveQueryParams(
            status: selectedStatusFilter,
            type: selectedTypeFilter,
            page: 1,
            limit: 100
        )
        
        return apiService.fetchLeaveRequests(params: params)
            .receive(on: DispatchQueue.main)  // ✅ ENSURE MAIN THREAD
            .map { [weak self] response in
                self?.leaveRequests = response.requests
            }
            .eraseToAnyPublisher()
    }
    
    private func loadLeaveBalance() -> AnyPublisher<Void, BaseAPIService.APIError> {
        return apiService.fetchLeaveBalance()
            .receive(on: DispatchQueue.main)  // ✅ ENSURE MAIN THREAD
            .map { [weak self] balance in
                self?.leaveBalance = balance
            }
            .eraseToAnyPublisher()
    }
    
    private func loadPublicHolidays() -> AnyPublisher<Void, BaseAPIService.APIError> {
        let currentYear = Calendar.current.component(.year, from: Date())
        return apiService.fetchPublicHolidays(year: currentYear)
            .receive(on: DispatchQueue.main)  // ✅ ENSURE MAIN THREAD
            .map { [weak self] holidays in
                self?.publicHolidays = holidays
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Actions
    
    func applyFilters() {
        loadLeaveRequests()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    func clearFilters() {
        selectedStatusFilter = nil
        selectedTypeFilter = nil
        applyFilters()
    }
    
    func cancelLeaveRequest(_ request: LeaveRequest) {
        isLoading = true
        errorMessage = nil
        
        apiService.cancelLeaveRequest(id: request.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    // Show success message based on response
                    if response.requires_approval == true {
                        self?.errorMessage = response.message // Actually a success message
                    } else {
                        // Refresh data to show updated status
                        self?.loadInitialData()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func editLeaveRequest(_ request: LeaveRequest, updates: UpdateLeaveRequestRequest) {
        isLoading = true
        errorMessage = nil
        
        apiService.updateLeaveRequest(id: request.id, updates: updates)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    // Refresh data to show updated request
                    self?.loadInitialData()
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var pendingRequests: [LeaveRequest] {
        leaveRequests.filter { $0.status == .pending }
    }
    
    var approvedRequests: [LeaveRequest] {
        leaveRequests.filter { $0.status == .approved }
    }
    
    var rejectedRequests: [LeaveRequest] {
        leaveRequests.filter { $0.status == .rejected }
    }
    
    var hasVacationDaysRemaining: Bool {
        guard let balance = leaveBalance else { return false }
        return balance.vacation_days_remaining > 0
    }
    
    var hasPersonalDaysRemaining: Bool {
        guard let balance = leaveBalance else { return false }
        return balance.personal_days_remaining > 0
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: BaseAPIService.APIError) {
        errorMessage = error.localizedDescription
        
        #if DEBUG
        print("[WorkerLeaveRequestViewModel] Error: \(error)")
        #endif
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Create Leave Request ViewModel

@MainActor
class CreateLeaveRequestViewModel: ObservableObject {
    @Published var selectedLeaveType: LeaveType = .vacation
    @Published var startDate = Date()
    @Published var endDate = Date()
    @Published var isHalfDay = false
    @Published var reason = ""
    @Published var isEmergencyLeave = false
    
    @Published var isLoading = false
    @Published var validationErrors: [String] = []
    @Published var workDaysCount: Int?
    @Published var isValidRequest = false
    @Published var showingSuccessAlert = false
    @Published var showingErrorAlert = false
    @Published var createdRequest: LeaveRequest?
    @Published var successMessage: String?
    @Published var submitSuccessDetails: String?
    @Published var errorMessage: String?
    
    // Leave balance tracking
    @Published var leaveBalance: LeaveBalance?
    @Published var isLoadingBalance = false
    
    // Existing leave requests for overlap checking
    @Published var existingLeaveRequests: [LeaveRequest] = []
    
    private let apiService = WorkerLeaveAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupValidation()
        loadLeaveBalance()
        loadExistingRequests()
    }
    
    // MARK: - Data Loading
    
    private func loadLeaveBalance() {
        isLoadingBalance = true
        
        apiService.fetchLeaveBalance()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingBalance = false
                    if case .failure(let error) = completion {
                        print("[CreateLeaveRequestViewModel] Failed to load leave balance: \(error)")
                    }
                },
                receiveValue: { [weak self] balance in
                    self?.leaveBalance = balance
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadExistingRequests() {
        // Load approved and pending requests to check for overlaps
        let params = LeaveQueryParams(
            status: nil, // Get all statuses
            type: nil,
            page: 1,
            limit: 100
        )
        
        apiService.fetchLeaveRequests(params: params)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("[CreateLeaveRequestViewModel] Failed to load existing requests: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    // Only keep approved and pending requests for overlap checking
                    self?.existingLeaveRequests = response.requests.filter { 
                        $0.status == .approved || $0.status == .pending 
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    
    private func setupValidation() {
        // Validate dates and calculate work days
        Publishers.CombineLatest4(
            $selectedLeaveType,
            $startDate,
            $endDate,
            $isHalfDay
        )
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] type, start, end, halfDay in
            self?.validateRequest(type: type, start: start, end: end, halfDay: halfDay)
        }
        .store(in: &cancellables)
    }
    
    private func validateRequest(type: LeaveType, start: Date, end: Date, halfDay: Bool) {
        validationErrors.removeAll()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Basic date validation
        if end < start {
            validationErrors.append("End date must be after start date")
            isValidRequest = false
            workDaysCount = nil
            return
        }
        
        // Leave type specific validation
        switch type {
        case .sick:
            // Sick leave restrictions
            let maxPastDays = 3
            let maxFutureDays = isEmergencyLeave ? 0 : 3
            
            let earliestAllowed = calendar.date(byAdding: .day, value: -maxPastDays, to: today) ?? today
            let latestAllowed = calendar.date(byAdding: .day, value: maxFutureDays, to: today) ?? today
            
            if start < earliestAllowed {
                validationErrors.append("Sick leave cannot be reported more than \(maxPastDays) days in the past")
            }
            
            if start > latestAllowed {
                if isEmergencyLeave {
                    validationErrors.append("Emergency sick leave can only be used for today or previous days")
                } else {
                    validationErrors.append("Regular sick leave cannot be scheduled more than \(maxFutureDays) days in advance")
                }
            }
            
        case .vacation:
            // Vacation advance notice (14 days)
            let requiredAdvanceDays = 14
            let minAdvanceDate = calendar.date(byAdding: .day, value: requiredAdvanceDays, to: today) ?? today
            
            if start < minAdvanceDate {
                validationErrors.append("Vacation requests must be submitted at least \(requiredAdvanceDays) days in advance")
            }
            
            // Check if start date is in the past
            if start < today {
                validationErrors.append("Vacation cannot be scheduled in the past")
            }
            
        case .personal:
            // Personal days advance notice (24 hours unless emergency)
            let _ = calendar.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
            
            if start < Date() && !isEmergencyLeave {
                validationErrors.append("Personal days require at least 24 hours advance notice unless marked as emergency")
            }
            
        case .parental, .compensatory:
            // Standard advance notice for these types
            if start < today {
                validationErrors.append("\(type.displayName) cannot be scheduled in the past")
            }
            
        case .emergency:
            // Emergency leave can be for immediate use
            break
        }
        
        // Weekend validation - ensure we're only counting work days
        let workDays = calculateWorkDaysLocal(from: start, to: end)
        workDaysCount = halfDay ? max(1, Int(ceil(Double(workDays) / 2))) : workDays
        
        if workDays == 0 {
            validationErrors.append("Selected dates contain no work days (weekends and holidays are excluded)")
        }
        
        // Check if half day is allowed for this type
        if halfDay && !type.canBeHalfDay {
            validationErrors.append("Half day option is not available for \(type.displayName)")
        }
        
        // Maximum duration validation
        if workDays > 20 && type == .vacation {
            validationErrors.append("Vacation requests cannot exceed 20 work days (4 weeks). Please split into multiple requests.")
        }
        
        // Check vacation balance if applicable
        if type == .vacation, let balance = leaveBalance {
            let requestedDays = halfDay ? 1 : workDays
            let availableDays = balance.vacation_days_remaining
            
            if requestedDays > availableDays {
                validationErrors.append("Insufficient vacation days. You have \(availableDays) days available but are requesting \(requestedDays) days.")
            }
        }
        
        // Check for overlapping leave requests
        for existingRequest in existingLeaveRequests {
            let existingStart = calendar.startOfDay(for: existingRequest.start_date)
            let existingEnd = calendar.startOfDay(for: existingRequest.end_date)
            let newStart = calendar.startOfDay(for: start)
            let newEnd = calendar.startOfDay(for: end)
            
            // Check if dates overlap
            if (newStart <= existingEnd && newEnd >= existingStart) {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.locale = Locale(identifier: "en_US")
                
                let conflictStart = formatter.string(from: existingRequest.start_date)
                let conflictEnd = formatter.string(from: existingRequest.end_date)
                let statusText = existingRequest.status == .approved ? "approved" : "pending"
                
                validationErrors.append("You already have a \(statusText) \(existingRequest.type.displayName) request from \(conflictStart) to \(conflictEnd). Please choose different dates.")
                break // Only show first conflict
            }
        }
        
        // Set validation result
        isValidRequest = validationErrors.isEmpty
        
        if !isValidRequest {
            workDaysCount = nil
        }
    }
    
    // Helper method to calculate work days locally
    private func calculateWorkDaysLocal(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        var workDays = 0
        var currentDate = startDate
        
        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            
            // Count only Monday (2) to Friday (6) in weekday format
            if weekday >= 2 && weekday <= 6 {
                // TODO: Exclude public holidays when available
                workDays += 1
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return workDays
    }
    
    private func validateWithAPI(type: LeaveType, start: Date, end: Date, halfDay: Bool) {
        // ✅ REPLACED API CALLS WITH LOCAL VALIDATION
        let isValidLocal = apiService.validateLeaveRequestLocal(
            type: type,
            startDate: start,
            endDate: end,
            halfDay: halfDay
        )
        
        let workDays = apiService.calculateWorkDaysLocal(
            from: start,
            to: end,
            holidays: [] // TODO: Use publicHolidays when available
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.isValidRequest = isValidLocal
            self?.workDaysCount = workDays
            
            if !isValidLocal {
                self?.validationErrors.append("Request is not valid (basic validation failed)")
            }
        }
    }
    
    // MARK: - Actions
    
    func submitRequest(completion: @escaping (Bool) -> Void) {
        guard isValidRequest else {
            completion(false)
            return
        }
        
        isLoading = true
        
        // ✅ GET EMPLOYEE_ID FROM AUTH SERVICE AND CONVERT TO INT
        guard let employeeIdString = AuthService.shared.getEmployeeId(),
              let employeeId = Int(employeeIdString) else {
            validationErrors.append("Unable to identify user")
            completion(false)
            return
        }
        
        let request = CreateLeaveRequestRequest(
            employee_id: employeeId,  // ✅ INCLUDE EMPLOYEE_ID
            type: selectedLeaveType,
            start_date: startDate,
            end_date: endDate,
            half_day: isHalfDay,
            reason: reason.isEmpty ? nil : reason,
            emergency_leave: isEmergencyLeave
        )
        
        apiService.createLeaveRequest(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    if case .failure(let error) = result {
                        // ✅ ENHANCED ERROR HANDLING FOR SPECIFIC DATABASE CONSTRAINTS
                        let errorMessage = self?.parseServerError(error) ?? "Creation error: \(error.localizedDescription)"
                        self?.validationErrors.append(errorMessage)
                        completion(false)
                    }
                },
                receiveValue: { [weak self] response in
                    // Handle API response using proper struct
                    if response.success {
                        // Parse enhanced response
                        if let confirmation = response.confirmation {
                            self?.successMessage = confirmation.message
                            
                            let details = confirmation.details
                            self?.submitSuccessDetails = """
                            Dates: \(details.dates)
                            Work days: \(details.work_days)
                            Status: \(details.status)
                            Next steps: \(details.next_steps)
                            """
                        } else {
                            // Fallback for simple response
                            self?.successMessage = "Your leave request has been submitted successfully"
                            self?.submitSuccessDetails = "Your manager will review and respond to your request"
                        }
                        
                        self?.showingSuccessAlert = true
                        self?.resetForm()
                        completion(true)
                        
                    } else {
                        // Handle failure case
                        self?.errorMessage = "Failed to submit leave request. Please try again."
                        self?.showingErrorAlert = true
                        completion(false)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func resetForm() {
        selectedLeaveType = .vacation
        startDate = Date()
        endDate = Date()
        isHalfDay = false
        reason = ""
        isEmergencyLeave = false
        validationErrors.removeAll()
        workDaysCount = nil
        isValidRequest = false
        successMessage = nil
        submitSuccessDetails = nil
        createdRequest = nil
    }
    
    // MARK: - Convenience Methods
    
    func setDateRange(start: Date, end: Date) {
        startDate = start
        endDate = end
    }
    
    func setQuickVacation(days: Int) {
        let calendar = Calendar.current
        startDate = calendar.date(byAdding: .day, value: 14, to: Date()) ?? Date() // 2 weeks from now
        endDate = calendar.date(byAdding: .day, value: days - 1, to: startDate) ?? startDate
        selectedLeaveType = .vacation
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return formatter.string(from: startDate)
        } else {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
    
    var estimatedWorkDays: String {
        if let workDays = workDaysCount {
            return isHalfDay ? "0.5 work days" : "\(workDays) work days"
        }
        return "Calculating..."
    }
    
    var availableVacationDays: Int {
        leaveBalance?.vacation_days_remaining ?? 0
    }
    
    var availablePersonalDays: Int {
        leaveBalance?.personal_days_remaining ?? 0
    }
    
    // ✅ ENHANCED ERROR PARSING FOR BETTER USER FEEDBACK
    private func parseServerError(_ error: BaseAPIService.APIError) -> String? {
        switch error {
        case .serverError(let code, let message):
            if code == 500 {
                // Parse specific database constraint errors
                if message.contains("Approved leave requests must have approved_by and approved_at values") {
                    return "System error: Emergency leave approval process failed. Please contact your manager."
                }
                if message.contains("ConnectorError") || message.contains("prisma") {
                    return "Database error occurred. Please try again or contact support."
                }
                return "Server error occurred. Please try again later."
            }
            if code == 400 {
                // Parse specific 400 errors
                if message.contains("Insufficient vacation days") {
                    // Extract the available and requested days from error message
                    if let availableRange = message.range(of: "Available: "),
                       let requestedRange = message.range(of: "Requested: ") {
                        let availableStr = message[availableRange.upperBound...]
                            .prefix(while: { $0.isNumber })
                        let requestedStr = message[requestedRange.upperBound...]
                            .prefix(while: { $0.isNumber })
                        return "Insufficient vacation days. You have \(availableStr) days available but requested \(requestedStr) days."
                    }
                    return message // Return original message if parsing fails
                }
                if message.contains("Overlapping leave request") {
                    return message // Already user-friendly
                }
                if message.contains("advance notice") {
                    return message // Already user-friendly
                }
                // Try to parse JSON error response
                if let data = message.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = json["error"] as? String {
                    return errorMsg
                }
                return "Invalid request. Please check your leave dates and details."
            }
            if code == 409 {
                // Conflict errors - parse the JSON response
                if let data = message.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = json["error"] as? String {
                    return errorMsg
                }
                return "A conflicting leave request already exists for these dates."
            }
            return "Server returned error \(code). Please try again."
            
        case .decodingError:
            return "Response format error. Please try again."
            
        case .networkError:
            return "Network connection error. Please check your internet connection."
            
        case .invalidURL:
            return "System configuration error. Please contact support."
            
        case .invalidResponse:
            return "Invalid server response. Please try again."
            
        case .unknown:
            return "Unknown error occurred. Please try again."
        }
    }
}

// MARK: - Leave Document Upload ViewModel

@MainActor
class LeaveDocumentUploadViewModel: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadError: String?
    @Published var uploadedDocuments: [DocumentUploadConfirmation] = []
    
    private let apiService = WorkerLeaveAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func uploadSickNote(
        for leaveRequestId: Int,
        fileData: Data,
        fileName: String,
        fileType: String
    ) {
        isUploading = true
        uploadProgress = 0.0
        uploadError = nil
        
        apiService.uploadSickNote(
            for: leaveRequestId,
            fileName: fileName,
            fileData: fileData,
            fileType: fileType
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isUploading = false
                self?.uploadProgress = 1.0
                
                if case .failure(let error) = completion {
                    self?.uploadError = error.localizedDescription
                }
            },
            receiveValue: { [weak self] confirmation in
                self?.uploadedDocuments.append(confirmation)
            }
        )
        .store(in: &cancellables)
    }
    
    func removeDocument(from leaveRequestId: Int, fileKey: String) {
        apiService.removeDocument(from: leaveRequestId, fileKey: fileKey)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.uploadError = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.uploadedDocuments.removeAll { $0.file_key == fileKey }
                }
            )
            .store(in: &cancellables)
    }
    
    func clearError() {
        uploadError = nil
    }
}