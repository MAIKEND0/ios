import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers

class EditWorkPlanViewModel: ObservableObject, WeekSelectorViewModel, WorkPlanViewModel {
    @Published var employees: [ManagerAPIService.Worker] = []
    @Published var assignments: [WorkPlanAssignment] = []
    @Published var selectedMonday: Date
    @Published var description: String
    @Published var additionalInfo: String
    @Published var attachment: WorkPlanAPIService.Attachment?
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var weekRangeText: String = ""
    var taskId: Int
    var workPlanId: Int
    
    private let managerService = ManagerAPIService.shared
    private let workPlanService = WorkPlanAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.selectedMonday = Calendar.current.startOfWeek(for: Date())
        self.taskId = 0
        self.workPlanId = 0
        self.description = ""
        self.additionalInfo = ""
        updateWeekRangeText()
    }
    
    func isWeekInFuture() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedWeekStart = calendar.startOfDay(for: selectedMonday)
        return selectedWeekStart >= today
    }
    
    func initializeWithWorkPlan(_ workPlan: WorkPlanAPIService.WorkPlan) {
        self.taskId = workPlan.task_id
        self.workPlanId = workPlan.work_plan_id
        self.description = workPlan.description ?? ""
        self.additionalInfo = workPlan.additional_info ?? ""
        self.attachment = workPlan.attachment_url != nil ? WorkPlanAPIService.Attachment(fileName: "", fileData: "") : nil
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekOfYear = workPlan.weekNumber
        components.yearForWeekOfYear = workPlan.year
        self.selectedMonday = calendar.date(from: components) ?? Date()
        
        let assignmentsValue = workPlan.assignments.map { assignment in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let startTime = assignment.start_time != nil ? dateFormatter.date(from: assignment.start_time!) : Date()
            let endTime = assignment.end_time != nil ? dateFormatter.date(from: assignment.end_time!) : Date()
            let dayIndex = Calendar.current.dateComponents([.day], from: selectedMonday, to: assignment.work_date).day!
            
            var dailyHours = Array(repeating: DailyHours(isActive: false, start_time: Date(), end_time: Date()), count: 7)
            if dayIndex >= 0 && dayIndex < 7 {
                dailyHours[dayIndex] = DailyHours(
                    isActive: true,
                    start_time: startTime ?? Date(),
                    end_time: endTime ?? Date()
                )
            }
            
            return WorkPlanAssignment(
                employee_id: assignment.employee_id,
                availableEmployees: [],
                weekStart: selectedMonday,
                dailyHours: dailyHours,
                notes: assignment.notes ?? ""
            )
        }
        self.assignments = assignmentsValue
        
        updateWeekRangeText()
        loadEmployees(for: workPlan.task_id)
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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: selectedMonday)!
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
        savePlan(status: "DRAFT")
    }
    
    func publish() {
        savePlan(status: "PUBLISHED")
    }
    
    private func savePlan(status: String) {
        guard taskId != 0 && workPlanId != 0 else {
            showAlert = true
            alertTitle = "Error"
            alertMessage = "Task ID or Work Plan ID is missing"
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
        
        let request = WorkPlanAPIService.WorkPlanRequest(
            task_id: taskId,
            weekNumber: Calendar.current.component(.weekOfYear, from: selectedMonday),
            year: Calendar.current.component(.year, from: selectedMonday),
            status: status,
            description: description.isEmpty ? nil : description,
            additional_info: additionalInfo.isEmpty ? nil : additionalInfo,
            attachment: attachment,
            assignments: assignments.flatMap { $0.toRequestAssignments() }
        )
        
        isLoading = true
        workPlanService.updateWorkPlan(workPlanId: workPlanId, plan: request)
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
                self?.alertMessage = response.message
            })
            .store(in: &cancellables)
    }
}
