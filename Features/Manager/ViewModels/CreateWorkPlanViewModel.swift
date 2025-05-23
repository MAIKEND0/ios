import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers

class CreateWorkPlanViewModel: ObservableObject, WeekSelectorViewModel, WorkPlanViewModel {
    @Published var employees: [ManagerAPIService.Worker] = []
    @Published var assignments: [WorkPlanAssignment] = []
    @Published var selectedMonday: Date
    @Published var description: String = ""
    @Published var additionalInfo: String = ""
    @Published var attachment: WorkPlanAPIService.Attachment?
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var weekRangeText: String = ""
    @Published var toast: ToastData? = nil // NOWE: Toast notification
    var taskId: Int = 0
    
    private let managerService = ManagerAPIService.shared
    private let workPlanService = WorkPlanAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let today = Date()
        // Use WeekUtils for consistent week calculation
        let currentWeekStart = WeekUtils.startOfWeek(for: today)
        // Start with current week (not next week) - user can create plans for current week if there are future days
        self.selectedMonday = currentWeekStart
        updateWeekRangeText()
    }
    
    func isWeekInFuture() -> Bool {
        // POPRAWKA: Sprawdź czy w wybranym tygodniu są jeszcze jakieś dni w przyszłości
        let today = Calendar.current.startOfDay(for: Date())
        let weekEndDate = WeekUtils.endOfWeek(for: selectedMonday)
        let weekEndDateStartOfDay = Calendar.current.startOfDay(for: weekEndDate)
        
        // Tydzień jest "dostępny" jeśli jego ostatni dzień (niedziela) jest dzisiaj lub w przyszłości
        let isAvailable = weekEndDateStartOfDay >= today
        
        #if DEBUG
        print("[CreateWorkPlanViewModel] isWeekInFuture check:")
        print("  - Today: \(today)")
        print("  - Selected Monday: \(selectedMonday)")
        print("  - Week end (Sunday): \(weekEndDate)")
        print("  - Is available: \(isAvailable)")
        #endif
        
        return isAvailable
    }
    
    // Sprawdź czy tydzień ma choć jeden dzień w przyszłości (dla bardziej dokładnej walidacji)
    func weekHasFutureDays() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Sprawdź każdy dzień w tygodniu
        for dayOffset in 0..<7 {
            if let dayDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: selectedMonday) {
                let dayStartOfDay = Calendar.current.startOfDay(for: dayDate)
                if dayStartOfDay >= today {
                    return true // Znaleziono przynajmniej jeden dzień dzisiaj lub w przyszłości
                }
            }
        }
        return false
    }
    
    func changeWeek(by offset: Int) {
        if let newMonday = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: selectedMonday) {
            // POPRAWKA: Sprawdź czy nowy tydzień ma jakieś dni w przyszłości
            let today = Calendar.current.startOfDay(for: Date())
            let newWeekEndDate = WeekUtils.endOfWeek(for: newMonday)
            let newWeekEndDateStartOfDay = Calendar.current.startOfDay(for: newWeekEndDate)
            
            // Pozwól na wybór tygodnia jeśli jego ostatni dzień (niedziela) jest dzisiaj lub w przyszłości
            if newWeekEndDateStartOfDay >= today {
                selectedMonday = newMonday
                updateWeekRangeText()
                assignments = assignments.map {
                    WorkPlanAssignment(
                        employee_id: $0.employee_id,
                        availableEmployees: $0.availableEmployees,
                        weekStart: selectedMonday,
                        dailyHours: $0.dailyHours,
                        notes: $0.notes
                    )
                }
                print("[CreateWorkPlanViewModel] Changed to week with Monday: \(selectedMonday)")
            } else {
                showAlert = true
                alertTitle = "Invalid Week"
                alertMessage = "Cannot select a week that has completely passed. All days in that week are in the past."
                print("[CreateWorkPlanViewModel] Rejected week selection - all days are in the past")
            }
        }
    }
    
    func updateWeekRangeText() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let endOfWeek = WeekUtils.endOfWeek(for: selectedMonday)
        weekRangeText = "\(formatter.string(from: selectedMonday)) - \(formatter.string(from: endOfWeek))"
    }
    
    func loadEmployees(for taskId: Int) {
        isLoading = true
        managerService.fetchAssignedWorkers(supervisorId: 0)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.showAlert = true
                    self?.alertTitle = "Error"
                    self?.alertMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] workers in
                self?.employees = workers.filter { $0.assignedTasks.contains { $0.task_id == taskId } }
                self?.assignments = self?.assignments.map { assignment in
                    var updated = assignment
                    updated.availableEmployees = self?.employees ?? []
                    return updated
                } ?? []
                self?.isLoading = false
            })
            .store(in: &cancellables)
    }
    
    func setAttachment(from url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let base64String = data.base64EncodedString()
            let fileExtension = url.pathExtension.lowercased()
            guard ["pdf", "png", "jpeg", "jpg", "txt", "doc", "docx"].contains(fileExtension) else {
                showAlert = true
                alertTitle = "Error"
                alertMessage = "Unsupported file type"
                return
            }
            attachment = WorkPlanAPIService.Attachment(
                fileName: url.lastPathComponent,
                fileData: base64String
            )
        } catch {
            showAlert = true
            alertTitle = "Error"
            alertMessage = "Failed to read file: \(error.localizedDescription)"
        }
    }
    
    func copyHoursToOtherEmployees(from sourceAssignment: WorkPlanAssignment) {
        assignments = assignments.map { assignment in
            guard assignment.employee_id != sourceAssignment.employee_id else { return assignment }
            return WorkPlanAssignment(
                employee_id: assignment.employee_id,
                availableEmployees: assignment.availableEmployees,
                weekStart: assignment.weekStart,
                dailyHours: sourceAssignment.dailyHours,
                notes: assignment.notes
            )
        }
    }
    
    func saveDraft() {
        if !weekHasFutureDays() {
            showAlert = true
            alertTitle = "Invalid Week"
            alertMessage = "Cannot create a work plan for a week that has completely passed. Please select a week with future days."
            return
        }
        savePlan(status: "DRAFT")
    }
    
    func publish() {
        if !weekHasFutureDays() {
            showAlert = true
            alertTitle = "Invalid Week"
            alertMessage = "Cannot publish a work plan for a week that has completely passed. Please select a week with future days."
            return
        }
        savePlan(status: "PUBLISHED")
    }
    
    private func savePlan(status: String) {
        guard taskId != 0 else {
            showAlert = true
            alertTitle = "Error"
            alertMessage = "Task ID is missing"
            return
        }
        guard !assignments.isEmpty else {
            showAlert = true
            alertTitle = "Error"
            alertMessage = "At least one employee must be assigned"
            return
        }
        
        // Sprawdź czy są jakieś aktywne assignmenty na dni które nie są w przeszłości
        let today = Calendar.current.startOfDay(for: Date())
        let hasFutureActiveAssignments = assignments.contains { assignment in
            assignment.dailyHours.enumerated().contains { index, hours in
                guard hours.isActive else { return false }
                if let dayDate = Calendar.current.date(byAdding: .day, value: index, to: assignment.weekStart) {
                    let dayStartOfDay = Calendar.current.startOfDay(for: dayDate)
                    return dayStartOfDay >= today
                }
                return false
            }
        }
        
        guard hasFutureActiveAssignments else {
            showAlert = true
            alertTitle = "Error"
            alertMessage = "At least one active schedule is required for a day that is not in the past"
            return
        }
        
        // Use WeekUtils for consistent week calculation
        let weekNumber = WeekUtils.weekNumber(for: selectedMonday)
        let year = WeekUtils.year(for: selectedMonday)
        
        #if DEBUG
        print("[CreateWorkPlanViewModel] Creating work plan for week \(weekNumber), year \(year), selectedMonday: \(selectedMonday)")
        #endif
        
        let request = WorkPlanAPIService.WorkPlanRequest(
            task_id: taskId,
            weekNumber: weekNumber,
            year: year,
            status: status,
            description: description.isEmpty ? nil : description,
            additional_info: additionalInfo.isEmpty ? nil : additionalInfo,
            attachment: attachment,
            assignments: assignments.flatMap { $0.toRequestAssignments() }
        )
        
        isLoading = true
        workPlanService.createWorkPlan(plan: request)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.toast = ToastData(
                        type: .error,
                        title: "Failed to \(status == "DRAFT" ? "Save Draft" : "Publish")",
                        message: error.localizedDescription
                    )
                }
            }, receiveValue: { [weak self] response in
                // SUCCESS TOAST dla publikacji
                if status == "PUBLISHED" {
                    self?.toast = ToastData(
                        type: .success,
                        title: "Work Plan Published! 🎉",
                        message: "Work plan has been published and sent to employees for the selected week. They will receive notifications about their schedules.",
                        duration: 5.0
                    )
                } else {
                    // DRAFT TOAST
                    self?.toast = ToastData(
                        type: .info,
                        title: "Draft Saved ✏️",
                        message: "Work plan saved as draft. You can continue editing and publish when ready.",
                        duration: 3.0
                    )
                }
            })
            .store(in: &cancellables)
    }
}
