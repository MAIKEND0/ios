//
//  WorkerTimesheetReportsViewModel.swift
//  KSR Cranes App
//

import Foundation
import Combine

final class WorkerTimesheetReportsViewModel: ObservableObject {
    @Published var timesheets: [WorkerAPIService.WorkerTimesheet] = []
    @Published var stats: WorkerAPIService.WorkerTimesheetStats?
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var lastLoadTime: Date?
    private let employeeId: String
    
    init() {
        self.employeeId = AuthService.shared.getEmployeeId() ?? ""
        loadData()
    }
    
    func loadData() {
        guard !employeeId.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Unable to get employee ID"
            showAlert = true
            return
        }
        
        guard lastLoadTime == nil || Date().timeIntervalSince(lastLoadTime!) > 5 else {
            #if DEBUG
            print("[WorkerTimesheetReportsViewModel] Skipped data load due to recent refresh")
            #endif
            return
        }
        lastLoadTime = Date()
        
        isLoading = true
        #if DEBUG
        print("[WorkerTimesheetReportsViewModel] Starting data load for employee: \(employeeId)")
        #endif
        
        // Load both timesheets and stats
        Publishers.Zip(
            fetchTimesheets(),
            fetchStats()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            self.isLoading = false
            if case .failure(let error) = completion {
                self.timesheets = []
                self.stats = nil
                self.alertTitle = "Error"
                self.alertMessage = error.localizedDescription
                self.showAlert = true
                #if DEBUG
                print("[WorkerTimesheetReportsViewModel] Failed to load data: \(error.localizedDescription)")
                #endif
            }
        } receiveValue: { [weak self] (timesheets, stats) in
            guard let self = self else { return }
            self.timesheets = timesheets
            self.stats = stats
            #if DEBUG
            print("[WorkerTimesheetReportsViewModel] Loaded \(timesheets.count) timesheets and stats")
            #endif
        }
        .store(in: &cancellables)
        
        // Timeout fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.isLoading ?? false {
                #if DEBUG
                print("[WorkerTimesheetReportsViewModel] Data loading timeout - forcing UI refresh")
                #endif
                self?.isLoading = false
            }
        }
    }
    
    private func fetchTimesheets() -> AnyPublisher<[WorkerAPIService.WorkerTimesheet], WorkerAPIService.APIError> {
        return WorkerAPIService.shared.fetchWorkerTimesheets(employeeId: employeeId)
    }
    
    private func fetchStats() -> AnyPublisher<WorkerAPIService.WorkerTimesheetStats, WorkerAPIService.APIError> {
        return WorkerAPIService.shared.fetchWorkerTimesheetStats(employeeId: employeeId)
    }
    
    // MARK: - Computed Properties
    
    var thisWeekCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let weekOfYear = calendar.component(.weekOfYear, from: now)
        let yearComponent = calendar.component(.year, from: now)
        
        return timesheets.filter { timesheet in
            timesheet.weekNumber == weekOfYear && timesheet.year == yearComponent
        }.count
    }
    
    var thisMonthCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let monthComponent = calendar.component(.month, from: now)
        let yearComponent = calendar.component(.year, from: now)
        
        return timesheets.filter { timesheet in
            timesheet.year == yearComponent &&
            isWeekInMonth(weekNumber: timesheet.weekNumber, month: monthComponent, year: yearComponent)
        }.count
    }
    
    var uniqueTasksCount: Int {
        Set(timesheets.map { $0.task_id }).count
    }
    
    var groupedByTask: [Int: [WorkerAPIService.WorkerTimesheet]] {
        Dictionary(grouping: timesheets) { $0.task_id }
    }
    
    var groupedByMonth: [String: [WorkerAPIService.WorkerTimesheet]] {
        Dictionary(grouping: timesheets) { timesheet in
            let calendar = Calendar.current
            let date = calendar.date(from: DateComponents(
                year: timesheet.year,
                weekOfYear: timesheet.weekNumber
            )) ?? timesheet.created_at
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Helper Methods
    
    private func isWeekInMonth(weekNumber: Int, month: Int, year: Int) -> Bool {
        let calendar = Calendar.current
        guard let weekDate = calendar.date(from: DateComponents(year: year, weekOfYear: weekNumber)) else {
            return false
        }
        let weekMonth = calendar.component(.month, from: weekDate)
        return weekMonth == month
    }
    
    func filterTimesheets(searchText: String, timeFilter: WorkerTimesheetTimeFilter) -> [WorkerAPIService.WorkerTimesheet] {
        var filtered = timesheets
        
        // Apply time filter
        if timeFilter != .all {
            let calendar = Calendar.current
            let now = Date()
            
            filtered = filtered.filter { timesheet in
                switch timeFilter {
                case .thisWeek:
                    let weekOfYear = calendar.component(.weekOfYear, from: now)
                    let yearComponent = calendar.component(.year, from: now)
                    return timesheet.weekNumber == weekOfYear && timesheet.year == yearComponent
                case .thisMonth:
                    let monthComponent = calendar.component(.month, from: now)
                    let yearComponent = calendar.component(.year, from: now)
                    return timesheet.year == yearComponent &&
                           isWeekInMonth(weekNumber: timesheet.weekNumber, month: monthComponent, year: yearComponent)
                case .recent:
                    return timesheet.created_at >= calendar.date(byAdding: .day, value: -30, to: now) ?? now
                case .all:
                    return true
                }
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            filtered = filtered.filter { timesheet in
                let taskTitle = timesheet.Tasks?.title.lowercased() ?? ""
                let weekNumber = String(timesheet.weekNumber)
                let year = String(timesheet.year)
                return taskTitle.contains(lowercasedSearch) ||
                       weekNumber.contains(lowercasedSearch) ||
                       year.contains(lowercasedSearch)
            }
        }
        
        return filtered.sorted { $0.created_at > $1.created_at }
    }
}
