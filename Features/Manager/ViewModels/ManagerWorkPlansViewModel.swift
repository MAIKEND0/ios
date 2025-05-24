//
//  ManagerWorkPlansViewModel.swift
//  KSR Cranes App
//
//  Updated by Maksymilian Marcinowski on 21/05/2025.
//  Added isWeekInFuture on 22/05/2025.
//  Fixed week selection refresh issue with cache on 22/05/2025.
//  Added Hashable conformance for WeekSelection on 22/05/2025.
//  Fixed incorrect week plan display on 22/05/2025.
//  Added employees fetching for creator_name on 22/05/2025.
//  Added clearCache method to refresh work plans on 22/05/2025.
//  Updated to fix compilation errors by ensuring clearCache is present on 22/05/2025.
//  Modified loadData to force reload after clearCache on 22/05/2025.
//  Fixed week to start from Monday instead of Sunday on 22/05/2025.
//  Unified week calculations using WeekUtils on 22/05/2025.
//  Added delete functionality on 23/05/2025.
//

import Foundation
import Combine
import SwiftUI

struct WeekSelection: Equatable, Hashable {
    let weekNumber: Int
    let year: Int
    let startDate: Date
    let endDate: Date
    
    var formattedRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    static func current() -> WeekSelection {
        let today = Date()
        
        // Use WeekUtils for consistent week calculation
        let startOfWeek = WeekUtils.startOfWeek(for: today)
        let endOfWeek = WeekUtils.endOfWeek(for: today)
        let weekNumber = WeekUtils.weekNumber(for: today)
        let year = WeekUtils.year(for: today)
        
        return WeekSelection(
            weekNumber: weekNumber,
            year: year,
            startDate: startOfWeek,
            endDate: endOfWeek
        )
    }
    
    static func == (lhs: WeekSelection, rhs: WeekSelection) -> Bool {
        return lhs.weekNumber == rhs.weekNumber && lhs.year == rhs.year
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(weekNumber)
        hasher.combine(year)
    }
    
    func next() -> WeekSelection {
        let nextWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startDate)!
        let nextWeekEnd = Calendar.current.date(byAdding: .day, value: 6, to: nextWeekStart)!
        
        // Use WeekUtils for consistent week calculation
        let weekNumber = WeekUtils.weekNumber(for: nextWeekStart)
        let year = WeekUtils.year(for: nextWeekStart)
        
        return WeekSelection(
            weekNumber: weekNumber,
            year: year,
            startDate: nextWeekStart,
            endDate: nextWeekEnd
        )
    }
    
    func previous() -> WeekSelection {
        let prevWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: startDate)!
        let prevWeekEnd = Calendar.current.date(byAdding: .day, value: 6, to: prevWeekStart)!
        
        // Use WeekUtils for consistent week calculation
        let weekNumber = WeekUtils.weekNumber(for: prevWeekStart)
        let year = WeekUtils.year(for: prevWeekStart)
        
        return WeekSelection(
            weekNumber: weekNumber,
            year: year,
            startDate: prevWeekStart,
            endDate: prevWeekEnd
        )
    }
}

final class ManagerWorkPlansViewModel: ObservableObject, WeekSelectorViewModel {
    @Published var workPlans: [WorkPlanAPIService.WorkPlan] = []
    @Published var employees: [ManagerAPIService.Worker] = []
    @Published var selectedWeek: WeekSelection
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var searchQuery: String = ""
    @Published var selectedStatus: String = "All"
    @Published var showDeleteConfirmation: Bool = false
    @Published var workPlanToDelete: WorkPlanAPIService.WorkPlan?
    @Published var toast: ToastData? = nil
    
    private let workPlanService = WorkPlanAPIService.shared
    private let managerService = ManagerAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var lastLoadTime: Date?
    private var currentWeekRequest: WeekSelection?
    private var workPlansCache: [WeekSelection: [WorkPlanAPIService.WorkPlan]] = [:]
    private var forceReload: Bool = false // Flaga do wymuszenia ponownego ładowania
    
    var weekRangeText: String {
        return selectedWeek.formattedRange
    }
    
    var selectedMonday: Date {
        return selectedWeek.startDate
    }
    
    var filteredWorkPlans: [WorkPlanAPIService.WorkPlan] {
        let filtered = workPlans.filter { plan in
            let matchesWeek = plan.weekNumber == selectedWeek.weekNumber && plan.year == selectedWeek.year
            let matchesSearch = searchQuery.isEmpty || plan.task_title.lowercased().contains(searchQuery.lowercased())
            let matchesStatus = selectedStatus == "All" || plan.status == selectedStatus
            print("[ManagerWorkPlansViewModel] Filtering plan: \(plan.task_title), week: \(plan.weekNumber)/\(plan.year), matchesWeek: \(matchesWeek), matchesSearch: \(matchesSearch), matchesStatus: \(matchesStatus)")
            return matchesWeek && matchesSearch && matchesStatus
        }
        print("[ManagerWorkPlansViewModel] Filtered \(filtered.count) plans from \(workPlans.count) total for week \(selectedWeek.weekNumber), year \(selectedWeek.year)")
        return filtered
    }
    
    init() {
        self.selectedWeek = WeekSelection.current()
        loadData()
        fetchEmployees()
    }
    
    func isWeekInFuture() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedWeekStart = calendar.startOfDay(for: selectedWeek.startDate)
        return selectedWeekStart >= today
    }
    
    func changeWeek(by offset: Int) {
        let newWeek: WeekSelection
        if offset > 0 {
            newWeek = selectedWeek.next()
        } else if offset < 0 {
            newWeek = selectedWeek.previous()
        } else {
            newWeek = WeekSelection.current()
        }
        selectedWeek = newWeek
        searchQuery = "" // Reset wyszukiwania
        selectedStatus = "All" // Reset statusu
        print("[ManagerWorkPlansViewModel] Changed to week \(newWeek.weekNumber), year \(newWeek.year), reset searchQuery and selectedStatus")
        
        // Force reload when changing weeks - clear cache and timeout
        forceReload = true
        lastLoadTime = nil
        workPlansCache.removeValue(forKey: newWeek) // Remove cache for this specific week
        
        loadData()
    }
    
    func selectWeek(number: Int, year: Int) {
        // Use WeekUtils for consistent date calculation
        if let weekDate = WeekUtils.date(from: number, year: year) {
            let startOfWeek = WeekUtils.startOfWeek(for: weekDate)
            let endOfWeek = WeekUtils.endOfWeek(for: weekDate)
            
            let newWeek = WeekSelection(
                weekNumber: number,
                year: year,
                startDate: startOfWeek,
                endDate: endOfWeek
            )
            
            selectedWeek = newWeek
            print("[ManagerWorkPlansViewModel] Selected week \(number), year \(year)")
            
            // Force reload when selecting a specific week
            forceReload = true
            lastLoadTime = nil
            workPlansCache.removeValue(forKey: newWeek)
            
            loadData()
        }
    }
    
    func selectCurrentWeek() {
        selectedWeek = WeekSelection.current()
        print("[ManagerWorkPlansViewModel] Selected current week \(selectedWeek.weekNumber), year \(selectedWeek.year)")
        
        // Force reload when selecting current week
        forceReload = true
        lastLoadTime = nil
        
        loadData()
    }
    
    func fetchEmployees() {
        let supervisorId = Int(AuthService.shared.getEmployeeId() ?? "0") ?? 0
        managerService.fetchAssignedWorkers(supervisorId: supervisorId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("[ManagerWorkPlansViewModel] Failed to fetch employees: \(error)")
                }
            }, receiveValue: { [weak self] workers in
                self?.employees = workers
                print("[ManagerWorkPlansViewModel] Fetched \(workers.count) employees: \(workers.map { $0.name })")
            })
            .store(in: &cancellables)
    }
    
    // Metoda do czyszczenia cache
    func clearCache() {
        workPlansCache.removeAll()
        forceReload = true // Wymuszenie ponownego ładowania po wyczyszczeniu cache
        lastLoadTime = nil // Reset timeout
        print("[ManagerWorkPlansViewModel] Cleared work plans cache and reset timeout")
    }
    
    // Metoda do wymuszenia refresh
    func forceRefresh() {
        clearCache()
        loadData()
    }
    
    func loadData(fetchAll: Bool = false) {
        // Always allow loading when forced or cache cleared
        let shouldSkip = !forceReload &&
                        lastLoadTime != nil &&
                        Date().timeIntervalSince(lastLoadTime!) <= 5
        
        if shouldSkip {
            #if DEBUG
            print("[ManagerWorkPlansViewModel] Skipped data load due to recent refresh (forceReload: \(forceReload))")
            #endif
            return
        }
        
        // Reset flagi forceReload po użyciu
        if forceReload {
            forceReload = false
            print("[ManagerWorkPlansViewModel] Force reload triggered, clearing cache")
        }
        
        let weekToLoad = selectedWeek
        // Skip cache check if force reload or fetchAll
        if !fetchAll && !forceReload, let cachedPlans = workPlansCache[weekToLoad] {
            print("[ManagerWorkPlansViewModel] Loaded \(cachedPlans.count) plans from cache for week \(weekToLoad.weekNumber), year \(weekToLoad.year)")
            self.workPlans = cachedPlans
            self.isLoading = false
            return
        }
        
        lastLoadTime = Date()
        let supervisorId = Int(AuthService.shared.getEmployeeId() ?? "0") ?? 0
        currentWeekRequest = weekToLoad
        
        print("[ManagerWorkPlansViewModel] Loading work plans for supervisorId: \(supervisorId), week: \(weekToLoad.weekNumber), year: \(weekToLoad.year), fetchAll: \(fetchAll)")
        
        // Clear old data immediately to show loading state
        self.workPlans = []
        isLoading = true
        
        workPlanService.fetchWorkPlans(
            supervisorId: supervisorId,
            weekNumber: fetchAll ? nil : weekToLoad.weekNumber,
            year: fetchAll ? nil : weekToLoad.year
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            self.isLoading = false
            if case .failure(let error) = completion {
                self.showAlert = true
                self.alertTitle = "Error"
                self.alertMessage = error.localizedDescription
                print("[ManagerWorkPlansViewModel] Error: \(error.localizedDescription)")
                if case .decodingError(let generalDecodingError) = error {
                    print("[ManagerWorkPlansViewModel] General decoding error: \(generalDecodingError)")
                    if let concreteDecodingError = generalDecodingError as? Swift.DecodingError {
                        print("[ManagerWorkPlansViewModel] Detailed Swift decoding error: \(concreteDecodingError)")
                        switch concreteDecodingError {
                        case .typeMismatch(let type, let context):
                            print("[ManagerWorkPlansViewModel] Type mismatch: \(type), context: \(context.debugDescription), codingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                        case .valueNotFound(let type, let context):
                            print("[ManagerWorkPlansViewModel] Value not found: \(type), context: \(context.debugDescription), codingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                        case .keyNotFound(let key, let context):
                            print("[ManagerWorkPlansViewModel] Key not found: \(key.stringValue), context: \(context.debugDescription), codingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                        case .dataCorrupted(let context):
                            print("[ManagerWorkPlansViewModel] Data corrupted: context: \(context.debugDescription), codingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                        @unknown default:
                            print("[ManagerWorkPlansViewModel] Unknown decoding error")
                        }
                    } else {
                        print("[ManagerWorkPlansViewModel] Wrapped error is not a Swift.DecodingError: \(generalDecodingError)")
                    }
                }
            }
        }, receiveValue: { [weak self] plans in
            guard let self = self else { return }
            if self.currentWeekRequest == weekToLoad || fetchAll {
                print("[ManagerWorkPlansViewModel] Fetched \(plans.count) work plans for week \(weekToLoad.weekNumber), year \(weekToLoad.year): \(plans.map { "\($0.task_title) (\($0.status))" })")
                self.workPlans = plans
                if !fetchAll {
                    self.workPlansCache[weekToLoad] = plans
                }
            } else {
                print("[ManagerWorkPlansViewModel] Ignored outdated response for week \(weekToLoad.weekNumber), year \(weekToLoad.year)")
            }
            self.isLoading = false
        })
        .store(in: &cancellables)
    }
    
    // MARK: - Delete Work Plan
    func deleteWorkPlan(_ workPlan: WorkPlanAPIService.WorkPlan) {
        isLoading = true
        
        workPlanService.deleteWorkPlan(workPlanId: workPlan.work_plan_id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    self.showAlert = true
                    self.alertTitle = "Delete Failed"
                    self.alertMessage = "Failed to delete work plan: \(error.localizedDescription)"
                    print("[ManagerWorkPlansViewModel] Failed to delete work plan: \(error)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if response.success {
                    print("[ManagerWorkPlansViewModel] Successfully deleted work plan: \(workPlan.task_title)")
                    print("[ManagerWorkPlansViewModel] Server message: \(response.message)")
                    
                    // Remove from local array
                    self.workPlans.removeAll { $0.work_plan_id == workPlan.work_plan_id }
                    
                    // Remove from cache
                    self.workPlansCache[self.selectedWeek]?.removeAll { $0.work_plan_id == workPlan.work_plan_id }
                    
                    // Show success toast with server message
                    self.toast = ToastData(
                        type: .success,
                        title: "Work Plan Deleted 🗑️",
                        message: response.message.isEmpty ? "The work plan has been successfully deleted." : response.message,
                        duration: 3.0
                    )
                    
                    // Reload data to ensure consistency
                    self.loadData()
                } else {
                    // Server returned success: false
                    self.showAlert = true
                    self.alertTitle = "Delete Failed"
                    self.alertMessage = response.message.isEmpty ? "Failed to delete work plan" : response.message
                    print("[ManagerWorkPlansViewModel] Delete failed: \(response.message)")
                }
            })
            .store(in: &cancellables)
    }
}
