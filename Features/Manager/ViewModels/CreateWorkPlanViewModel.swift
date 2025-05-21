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
    var taskId: Int = 0
    
    private let managerService = ManagerAPIService.shared
    private let workPlanService = WorkPlanAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let calendar = Calendar.current
        let today = Date()
        self.selectedMonday = calendar.startOfWeek(for: today)
        updateWeekRangeText()
    }
    
    func changeWeek(by offset: Int) {
        if let newMonday = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: selectedMonday) {
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
        }
    }
    
    func updateWeekRangeText() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedMonday)
        let weekNumber = components.weekOfYear ?? 0
        let year = components.yearForWeekOfYear ?? 0
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: selectedMonday)!
        weekRangeText = "Week \(weekNumber), \(year): \(formatter.string(from: selectedMonday)) - \(formatter.string(from: endOfWeek))"
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
        savePlan(status: "DRAFT")
    }
    
    func publish() {
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
        guard assignments.contains(where: { $0.dailyHours.contains(where: { $0.isActive }) }) else {
            showAlert = true
            alertTitle = "Error"
            alertMessage = "At least one active schedule is required"
            return
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedMonday)
        let weekNumber = components.weekOfYear ?? 0
        let year = components.yearForWeekOfYear ?? 0
        
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
                    self?.showAlert = true
                    self?.alertTitle = "Error"
                    self?.alertMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] response in
                self?.showAlert = true
                self?.alertTitle = "Success"
                self?.alertMessage = "Work plan created successfully"
            })
            .store(in: &cancellables)
    }
}
