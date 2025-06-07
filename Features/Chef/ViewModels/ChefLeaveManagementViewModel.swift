//
//  ChefLeaveManagementViewModel.swift
//  KSR Cranes App
//
//  Chef Leave Management ViewModels
//  Handles team leave approval, calendar management, and analytics for chef role
//

import Foundation
import Combine
import SwiftUI

extension AnyPublisher where Failure == ChefLeaveAPIService.APIError {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self
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
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
}

// MARK: - Chef Leave Management Dashboard ViewModel

@MainActor
class ChefLeaveManagementViewModel: ObservableObject {
    @Published var pendingRequests: [LeaveRequest] = []
    @Published var allRequests: [LeaveRequest] = []
    @Published var teamBalances: [EmployeeLeaveBalance] = []
    @Published var leaveStatistics: LeaveStatistics?
    @Published var teamCalendar: [TeamLeaveCalendar] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefresh: Date?
    
    // Success alerts
    @Published var successMessage: String?
    @Published var showingSuccessAlert = false
    
    // Modal state management
    @Published var selectedRequestForDetail: LeaveRequest?
    @Published var showingDetailModal = false
    
    // Filtering and display options
    @Published var selectedStatusFilter: LeaveStatus?
    @Published var selectedTypeFilter: LeaveType?
    @Published var selectedEmployeeFilter: Int?
    @Published var dateRangeStart = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var dateRangeEnd = Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date()
    
    private let apiService = ChefLeaveAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadInitialData()
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() {
        isLoading = true
        
        Publishers.Zip4(
            loadPendingRequests(),
            loadTeamBalances(),
            loadLeaveStatistics(),
            loadTeamCalendar()
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
            receiveValue: { _, _, _, _ in
                // Data loaded successfully
            }
        )
        .store(in: &cancellables)
    }
    
    func refreshData() {
        loadInitialData()
    }
    
    func updateDateRange(for displayedMonth: Date) {
        let calendar = Calendar.current
        // Set range to show the displayed month plus surrounding months
        dateRangeStart = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        dateRangeEnd = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        
        // Reload calendar data with new range
        loadTeamCalendar()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("[ChefLeaveManagementViewModel] Calendar update error: \(error)")
                    }
                },
                receiveValue: { _ in
                    print("[ChefLeaveManagementViewModel] Calendar updated for month: \(displayedMonth)")
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadPendingRequests() -> AnyPublisher<Void, BaseAPIService.APIError> {
        return apiService.fetchPendingApprovals()
            .receive(on: DispatchQueue.main)
            .map { [weak self] response in
                self?.pendingRequests = response.requests
            }
            .eraseToAnyPublisher()
    }
    
    private func loadAllRequests() -> AnyPublisher<Void, BaseAPIService.APIError> {
        let params = LeaveQueryParams(
            status: selectedStatusFilter,
            type: selectedTypeFilter,
            start_date: dateRangeStart,
            end_date: dateRangeEnd,
            page: 1,
            limit: 200,
            include_employee: true,
            include_approver: true
        )
        
        return apiService.fetchTeamLeaveRequests(params: params)
            .receive(on: DispatchQueue.main)
            .map { [weak self] response in
                self?.allRequests = response.requests
            }
            .eraseToAnyPublisher()
    }
    
    private func loadTeamBalances() -> AnyPublisher<Void, BaseAPIService.APIError> {
        let currentYear = Calendar.current.component(.year, from: Date())
        return apiService.fetchTeamLeaveBalances(year: currentYear)
            .receive(on: DispatchQueue.main)
            .map { [weak self] balances in
                self?.teamBalances = balances
            }
            .eraseToAnyPublisher()
    }
    
    private func loadLeaveStatistics() -> AnyPublisher<Void, BaseAPIService.APIError> {
        return apiService.fetchLeaveStatistics(
            startDate: dateRangeStart,
            endDate: dateRangeEnd
        )
        .receive(on: DispatchQueue.main)
        .map { [weak self] statistics in
            self?.leaveStatistics = statistics
        }
        .eraseToAnyPublisher()
    }
    
    private func loadTeamCalendar() -> AnyPublisher<Void, BaseAPIService.APIError> {
        return apiService.fetchTeamLeaveCalendar(
            startDate: dateRangeStart,
            endDate: dateRangeEnd
        )
        .receive(on: DispatchQueue.main)
        .map { [weak self] calendar in
            self?.teamCalendar = calendar
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Leave Request Actions
    
    func approveLeaveRequest(_ request: LeaveRequest, completion: @escaping (Bool) -> Void = { _ in }) {
        isLoading = true
        
        apiService.approveOrRejectLeaveRequest(
            id: request.id,
            action: .approve
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.handleError(error)
                    completion(false)
                }
            },
            receiveValue: { [weak self] response in
                // Update local data
                self?.updateRequestInLists(response.request)
                
                // Update balance if provided
                if let updatedBalance = response.balance_updated {
                    self?.updateEmployeeBalance(updatedBalance)
                }
                
                completion(true)
            }
        )
        .store(in: &cancellables)
    }
    
    func rejectLeaveRequest(_ request: LeaveRequest, reason: String, completion: @escaping (Bool) -> Void = { _ in }) {
        isLoading = true
        
        apiService.approveOrRejectLeaveRequest(
            id: request.id,
            action: .reject,
            rejectionReason: reason
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.handleError(error)
                    completion(false)
                }
            },
            receiveValue: { [weak self] response in
                // Update local data
                self?.updateRequestInLists(response.request)
                completion(true)
            }
        )
        .store(in: &cancellables)
    }
    
    func bulkApproveRequests(_ requests: [LeaveRequest], completion: @escaping (Int, Int) -> Void = { _, _ in }) {
        let requestIds = requests.map { $0.id }
        
        isLoading = true
        apiService.bulkApproveLeaveRequests(ids: requestIds)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    self?.isLoading = false
                    if case .failure(let error) = completionResult {
                        self?.handleError(error)
                        completion(0, requestIds.count)
                    }
                },
                receiveValue: { [weak self] response in
                    // Refresh data to get updated statuses
                    if let strongSelf = self {
                        strongSelf.loadPendingRequests()
                            .sink(receiveCompletion: { _ in }, receiveValue: { })
                            .store(in: &strongSelf.cancellables)
                    }
                    
                    completion(response.successful.count, response.total_processed)
                }
            )
            .store(in: &cancellables)
    }
    
    func recalculateAllBalances() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let response = try await apiService.recalculateAllLeaveBalances()
                .async()
            
            await MainActor.run {
                isLoading = false
                
                // Show success message
                successMessage = """
                ✅ Leave balances recalculated successfully!
                
                Updated: \(response.updated_balances) balances
                Created: \(response.missing_balances_created) missing records
                
                All workers now have correct vacation/sick/personal day counts.
                """
                showingSuccessAlert = true
                
                // Refresh data to show updated balances
                loadInitialData()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                if let apiError = error as? ChefLeaveAPIService.APIError {
                    handleError(apiError)
                } else {
                    handleError(.serverError(500, error.localizedDescription))
                }
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Filtering and Search
    
    func applyFilters() {
        loadAllRequests()
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
        selectedEmployeeFilter = nil
        applyFilters()
    }
    
    // MARK: - Team Availability
    
    func checkTeamAvailability(for dateRange: ClosedRange<Date>) -> AnyPublisher<TeamAvailabilityResponse, BaseAPIService.APIError> {
        return apiService.checkTeamAvailability(
            startDate: dateRange.lowerBound,
            endDate: dateRange.upperBound
        )
    }
    
    // MARK: - Data Export
    
    func exportLeaveData(format: ExportFormat = .csv, completion: @escaping (String?) -> Void) {
        isLoading = true
        
        apiService.exportLeaveData(
            startDate: dateRangeStart,
            endDate: dateRangeEnd,
            format: format
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.handleError(error)
                    completion(nil)
                }
            },
            receiveValue: { response in
                completion(response.download_url)
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    private func updateRequestInLists(_ updatedRequest: LeaveRequest) {
        // Update in pending requests
        if let index = pendingRequests.firstIndex(where: { $0.id == updatedRequest.id }) {
            if updatedRequest.status == .pending {
                pendingRequests[index] = updatedRequest
            } else {
                pendingRequests.remove(at: index)
            }
        }
        
        // Update in all requests
        if let index = allRequests.firstIndex(where: { $0.id == updatedRequest.id }) {
            allRequests[index] = updatedRequest
        }
    }
    
    private func updateEmployeeBalance(_ updatedBalance: LeaveBalance) {
        if let index = teamBalances.firstIndex(where: { $0.employee_id == updatedBalance.employee_id }) {
            teamBalances[index] = teamBalances[index].withUpdatedBalance(updatedBalance)
        }
    }
    
    // MARK: - Computed Properties
    
    var urgentPendingRequests: [LeaveRequest] {
        let twoDaysFromNow = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        return pendingRequests.filter { $0.start_date <= twoDaysFromNow }
    }
    
    var employeesOnLeaveToday: [EmployeeLeaveDay] {
        let today = Calendar.current.startOfDay(for: Date())
        return teamCalendar
            .first { Calendar.current.isDate($0.date, inSameDayAs: today) }?
            .employees_on_leave ?? []
    }
    
    var employeesWithLowVacationBalance: [EmployeeLeaveBalance] {
        return teamBalances.filter { $0.balance.vacation_days_remaining <= 5 }
    }
    
    // MARK: - Helper Methods
    
    func getEmployeeLeaveBalance(employeeId: Int) -> LeaveBalance? {
        return teamBalances.first(where: { $0.employee_id == employeeId })?.balance
    }
    
    func fetchEmployeeLeaveHistory(employeeId: Int, completion: @escaping ([LeaveRequest]) -> Void) {
        let params = LeaveQueryParams(
            employee_id: employeeId,
            page: 1,
            limit: 10,
            include_employee: true,
            include_approver: true
        )
        
        apiService.fetchTeamLeaveRequests(params: params)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completionResult in
                    if case .failure(let error) = completionResult {
                        print("[ChefLeaveManagementViewModel] Error fetching employee history: \(error)")
                        completion([])
                    }
                },
                receiveValue: { response in
                    completion(response.requests)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Modal Management
    
    func showLeaveRequestDetail(_ request: LeaveRequest) {
        print("DEBUG: ViewModel.showLeaveRequestDetail called for request ID: \(request.id)")
        selectedRequestForDetail = request
        showingDetailModal = true
        print("DEBUG: ViewModel selectedRequestForDetail set to: \(selectedRequestForDetail?.id ?? -1)")
        print("DEBUG: ViewModel showingDetailModal set to: \(showingDetailModal)")
    }
    
    func hideLeaveRequestDetail() {
        print("DEBUG: ViewModel.hideLeaveRequestDetail called")
        selectedRequestForDetail = nil
        showingDetailModal = false
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: BaseAPIService.APIError) {
        errorMessage = error.localizedDescription
        
        #if DEBUG
        print("[ChefLeaveManagementViewModel] Error: \(error)")
        #endif
    }
}

// MARK: - Leave Approval Detail ViewModel

@MainActor
class LeaveApprovalDetailViewModel: ObservableObject {
    @Published var leaveRequest: LeaveRequest
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var rejectionReason = ""
    @Published var showingRejectionDialog = false
    @Published var showingConfirmationDialog = false
    @Published var pendingAction: ApprovalAction?
    
    enum ApprovalAction {
        case approve
        case reject
    }
    
    private let apiService = ChefLeaveAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(leaveRequest: LeaveRequest) {
        self.leaveRequest = leaveRequest
    }
    
    // MARK: - Actions
    
    func approveRequest(completion: @escaping (Bool) -> Void) {
        performAction(.approve, completion: completion)
    }
    
    func rejectRequest(reason: String, completion: @escaping (Bool) -> Void) {
        rejectionReason = reason
        performAction(.reject, completion: completion)
    }
    
    private func performAction(_ action: ApprovalAction, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        let apiAction: ApproveRejectLeaveRequest.LeaveAction = action == .approve ? .approve : .reject
        
        apiService.approveOrRejectLeaveRequest(
            id: leaveRequest.id,
            action: apiAction,
            rejectionReason: action == .reject ? rejectionReason : nil
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.handleError(error)
                    completion(false)
                }
            },
            receiveValue: { [weak self] response in
                self?.leaveRequest = response.request
                completion(true)
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Team Impact Analysis
    
    func analyzeTeamImpact() -> AnyPublisher<TeamAvailabilityResponse, BaseAPIService.APIError> {
        return apiService.checkTeamAvailability(
            startDate: leaveRequest.start_date,
            endDate: leaveRequest.end_date
        )
    }
    
    // MARK: - Computed Properties
    
    var isUrgent: Bool {
        let twoDaysFromNow = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        return leaveRequest.start_date <= twoDaysFromNow
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if Calendar.current.isDate(leaveRequest.start_date, inSameDayAs: leaveRequest.end_date) {
            return formatter.string(from: leaveRequest.start_date)
        } else {
            return "\(formatter.string(from: leaveRequest.start_date)) - \(formatter.string(from: leaveRequest.end_date))"
        }
    }
    
    var daysUntilStart: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: leaveRequest.start_date).day ?? 0
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: BaseAPIService.APIError) {
        errorMessage = error.localizedDescription
        
        #if DEBUG
        print("[LeaveApprovalDetailViewModel] Error: \(error)")
        #endif
    }
}

// MARK: - Team Leave Calendar ViewModel

@MainActor
class TeamLeaveCalendarViewModel: ObservableObject {
    @Published var calendarData: [TeamLeaveCalendar] = []
    @Published var selectedDate = Date()
    @Published var displayedMonth = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = ChefLeaveAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadCalendarData()
        setupMonthChangeObserver()
    }
    
    private func setupMonthChangeObserver() {
        $displayedMonth
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadCalendarData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadCalendarData() {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: displayedMonth)?.end ?? displayedMonth
        
        isLoading = true
        
        apiService.fetchTeamLeaveCalendar(
            startDate: startOfMonth,
            endDate: endOfMonth
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            },
            receiveValue: { [weak self] calendar in
                self?.calendarData = calendar
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Calendar Navigation
    
    func goToNextMonth() {
        displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }
    
    func goToPreviousMonth() {
        displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }
    
    func goToToday() {
        displayedMonth = Date()
        selectedDate = Date()
    }
    
    // MARK: - Data Access
    
    func employeesOnLeave(for date: Date) -> [EmployeeLeaveDay] {
        return calendarData
            .first { Calendar.current.isDate($0.date, inSameDayAs: date) }?
            .employees_on_leave ?? []
    }
    
    func hasLeaveOnDate(_ date: Date) -> Bool {
        return !employeesOnLeave(for: date).isEmpty
    }
    
    func leaveCountForDate(_ date: Date) -> Int {
        return employeesOnLeave(for: date).count
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: BaseAPIService.APIError) {
        errorMessage = error.localizedDescription
        
        #if DEBUG
        print("[TeamLeaveCalendarViewModel] Error: \(error)")
        #endif
    }
    
}