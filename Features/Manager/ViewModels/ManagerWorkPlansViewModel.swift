//
//  ManagerWorkPlansViewModel.swift
//  KSR Cranes App
//
//  Updated by Maksymilian Marcinowski on 21/05/2025.
//  Added isWeekInFuture on 22/05/2025.
//

import Foundation
import Combine
import SwiftUI

struct WeekSelection: Equatable {
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
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.startOfWeek(for: today)
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        
        return WeekSelection(
            weekNumber: calendar.component(.weekOfYear, from: today),
            year: calendar.component(.year, from: today),
            startDate: startOfWeek,
            endDate: endOfWeek
        )
    }
    
    static func == (lhs: WeekSelection, rhs: WeekSelection) -> Bool {
        return lhs.weekNumber == rhs.weekNumber && lhs.year == rhs.year
    }
    
    func next() -> WeekSelection {
        let calendar = Calendar.current
        let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: startDate)!
        let nextWeekEnd = calendar.date(byAdding: .day, value: 6, to: nextWeekStart)!
        
        return WeekSelection(
            weekNumber: calendar.component(.weekOfYear, from: nextWeekStart),
            year: calendar.component(.year, from: nextWeekStart),
            startDate: nextWeekStart,
            endDate: nextWeekEnd
        )
    }
    
    func previous() -> WeekSelection {
        let calendar = Calendar.current
        let prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: startDate)!
        let prevWeekEnd = calendar.date(byAdding: .day, value: 6, to: prevWeekStart)!
        
        return WeekSelection(
            weekNumber: calendar.component(.weekOfYear, from: prevWeekStart),
            year: calendar.component(.year, from: prevWeekStart),
            startDate: prevWeekStart,
            endDate: prevWeekEnd
        )
    }
}

final class ManagerWorkPlansViewModel: ObservableObject, WeekSelectorViewModel {
    @Published var workPlans: [WorkPlanAPIService.WorkPlan] = []
    @Published var selectedWeek: WeekSelection
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var searchQuery: String = ""
    @Published var selectedStatus: String = "All"
    
    private let workPlanService = WorkPlanAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var lastLoadTime: Date?
    
    var weekRangeText: String {
        return selectedWeek.formattedRange
    }
    
    var selectedMonday: Date {
        return selectedWeek.startDate
    }
    
    var filteredWorkPlans: [WorkPlanAPIService.WorkPlan] {
        workPlans.filter { plan in
            let matchesSearch = searchQuery.isEmpty || plan.task_title.lowercased().contains(searchQuery.lowercased())
            let matchesStatus = selectedStatus == "All" || plan.status == selectedStatus
            return matchesSearch && matchesStatus
        }
    }
    
    init() {
        self.selectedWeek = WeekSelection.current()
        loadData()
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
        loadData()
    }
    
    func selectWeek(number: Int, year: Int) {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekOfYear = number
        components.yearForWeekOfYear = year
        
        if let date = calendar.date(from: components) {
            let startOfWeek = calendar.startOfWeek(for: date)
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            
            selectedWeek = WeekSelection(
                weekNumber: number,
                year: year,
                startDate: startOfWeek,
                endDate: endOfWeek
            )
            loadData()
        }
    }
    
    func selectCurrentWeek() {
        selectedWeek = WeekSelection.current()
        loadData()
    }
    
    func loadData(fetchAll: Bool = false) {
        guard lastLoadTime == nil || Date().timeIntervalSince(lastLoadTime!) > 5 else {
            #if DEBUG
            print("[ManagerWorkPlansViewModel] Skipped data load due to recent refresh")
            #endif
            return
        }
        lastLoadTime = Date()
        
        let supervisorId = Int(AuthService.shared.getEmployeeId() ?? "0") ?? 0
        print("[ManagerWorkPlansViewModel] Loading work plans for supervisorId: \(supervisorId), week: \(selectedWeek.weekNumber), year: \(selectedWeek.year), fetchAll: \(fetchAll)")
        
        isLoading = true
        workPlanService.fetchWorkPlans(
            supervisorId: supervisorId,
            weekNumber: fetchAll ? nil : selectedWeek.weekNumber,
            year: fetchAll ? nil : selectedWeek.year
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
            print("[ManagerWorkPlansViewModel] Fetched \(plans.count) work plans: \(plans.map { "\($0.task_title) (\($0.status))" })")
            self?.workPlans = plans
            self?.isLoading = false
        })
        .store(in: &cancellables)
    }
}
