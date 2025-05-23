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
    @Published var toast: ToastData? = nil // NOWE: Toast notification
    var taskId: Int
    var workPlanId: Int
    
    private let managerService = ManagerAPIService.shared
    private let workPlanService = WorkPlanAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Use WeekUtils for consistent week calculation
        self.selectedMonday = WeekUtils.startOfWeek(for: Date())
        self.taskId = 0
        self.workPlanId = 0
        self.description = ""
        self.additionalInfo = ""
        updateWeekRangeText()
    }
    
    func isWeekInFuture() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let selectedWeekStart = Calendar.current.startOfDay(for: selectedMonday)
        return selectedWeekStart >= today
    }
    
    func initializeWithWorkPlan(_ workPlan: WorkPlanAPIService.WorkPlan) {
        print("[EditWorkPlanViewModel] Initializing with work plan: \(workPlan.task_title)")
        print("[EditWorkPlanViewModel] Work plan has \(workPlan.assignments.count) assignments")
        
        self.taskId = workPlan.task_id
        self.workPlanId = workPlan.work_plan_id
        self.description = workPlan.description ?? ""
        self.additionalInfo = workPlan.additional_info ?? ""
        self.attachment = workPlan.attachment_url != nil ? WorkPlanAPIService.Attachment(fileName: "", fileData: "") : nil
        
        // Use WeekUtils for consistent date calculation
        if let weekDate = WeekUtils.date(from: workPlan.weekNumber, year: workPlan.year) {
            self.selectedMonday = WeekUtils.startOfWeek(for: weekDate)
        } else {
            self.selectedMonday = WeekUtils.startOfWeek(for: Date())
        }
        
        // Group assignments by employee_id - THIS IS THE KEY FIX
        let assignmentsByEmployee = Dictionary(grouping: workPlan.assignments, by: { $0.employee_id })
        
        // Create one WorkPlanAssignment per employee with all their days
        let assignmentsValue = assignmentsByEmployee.map { (employeeId, employeeAssignments) in
            print("[EditWorkPlanViewModel] Processing employee \(employeeId) with \(employeeAssignments.count) assignments")
            
            // Initialize daily hours array (7 days, all inactive) - FIX: use default constructor
            var dailyHours = Array(repeating: DailyHours(), count: 7) // ✅ Domyślne 7-15
            
            // Process each assignment for this employee
            for assignment in employeeAssignments {
                // Calculate which day of week this assignment is for
                let dayIndex = Calendar.current.dateComponents([.day], from: selectedMonday, to: assignment.work_date).day ?? 0
                
                print("[EditWorkPlanViewModel] Assignment work_date: \(assignment.work_date), dayIndex: \(dayIndex)")
                
                // Make sure dayIndex is valid (0-6 for Monday-Sunday)
                if dayIndex >= 0 && dayIndex < 7 {
                    // Create proper date for the specific day
                    let dayDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: selectedMonday) ?? selectedMonday
                    
                    let startTime: Date
                    let endTime: Date
                    
                    if let startTimeString = assignment.start_time,
                       let endTimeString = assignment.end_time {
                        // Parse time strings and combine with day date
                        startTime = createTimeForDay(timeString: startTimeString, dayDate: dayDate)
                        endTime = createTimeForDay(timeString: endTimeString, dayDate: dayDate)
                    } else {
                        // Fallback to current time if parsing fails
                        startTime = dayDate
                        endTime = dayDate
                    }
                    
                    dailyHours[dayIndex] = DailyHours(
                        isActive: true,
                        start_time: startTime,
                        end_time: endTime
                    )
                    
                    print("[EditWorkPlanViewModel] Set day \(dayIndex) as active for employee \(employeeId)")
                } else {
                    print("[EditWorkPlanViewModel] ⚠️ Invalid dayIndex \(dayIndex) for employee \(employeeId)")
                }
            }
            
            // Get notes from first assignment (assuming all assignments for same employee have same notes)
            let notes = employeeAssignments.first?.notes ?? ""
            
            let workPlanAssignment = WorkPlanAssignment(
                employee_id: employeeId,
                availableEmployees: [], // Will be filled when employees load
                weekStart: selectedMonday,
                dailyHours: dailyHours,
                notes: notes
            )
            
            print("[EditWorkPlanViewModel] Created WorkPlanAssignment for employee \(employeeId) with \(dailyHours.filter({ $0.isActive }).count) active days")
            
            return workPlanAssignment
        }
        
        self.assignments = assignmentsValue
        print("[EditWorkPlanViewModel] Created \(assignmentsValue.count) WorkPlanAssignments total")
        
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
                    self?.toast = ToastData(
                        type: .error,
                        title: "Loading Failed",
                        message: error.localizedDescription
                    )
                }
            }, receiveValue: { [weak self] workers in
                self?.employees = workers.filter { $0.assignedTasks.contains { $0.task_id == taskId } }
                print("[EditWorkPlanViewModel] Loaded \(workers.count) workers, filtered to \(self?.employees.count ?? 0) for task \(taskId)")
                
                // Update availableEmployees in existing assignments
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
                toast = ToastData(
                    type: .error,
                    title: "Unsupported File",
                    message: "Please select a PDF, image, or document file."
                )
                return
            }
            attachment = WorkPlanAPIService.Attachment(
                fileName: url.lastPathComponent,
                fileData: base64String
            )
            
            // Success toast for file attachment
            toast = ToastData(
                type: .success,
                title: "File Attached ✅",
                message: "File '\(url.lastPathComponent)' has been attached to the work plan.",
                duration: 2.0
            )
        } catch {
            toast = ToastData(
                type: .error,
                title: "File Error",
                message: "Failed to read file: \(error.localizedDescription)"
            )
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
        
        // Toast for copy action
        toast = ToastData(
            type: .info,
            title: "Hours Copied 📋",
            message: "Schedule has been copied to all other employees.",
            duration: 2.0
        )
    }
    
    func saveDraft() {
        savePlan(status: "DRAFT")
    }
    
    func publish() {
        savePlan(status: "PUBLISHED")
    }
    
    private func savePlan(status: String) {
        guard taskId != 0 && workPlanId != 0 else {
            toast = ToastData(
                type: .error,
                title: "Missing Information",
                message: "Task ID or Work Plan ID is missing. Please try again."
            )
            return
        }
        guard !assignments.isEmpty else {
            toast = ToastData(
                type: .warning,
                title: "No Employees Selected",
                message: "Please assign at least one employee to the work plan."
            )
            return
        }
        guard assignments.contains(where: { $0.dailyHours.contains(where: { $0.isActive }) }) else {
            toast = ToastData(
                type: .warning,
                title: "No Schedule Set",
                message: "Please set at least one active schedule for the selected employees."
            )
            return
        }
        
        // Use WeekUtils for consistent week calculation
        let weekNumber = WeekUtils.weekNumber(for: selectedMonday)
        let year = WeekUtils.year(for: selectedMonday)
        
        #if DEBUG
        print("[EditWorkPlanViewModel] Updating work plan for week \(weekNumber), year \(year), selectedMonday: \(selectedMonday)")
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
        workPlanService.updateWorkPlan(workPlanId: workPlanId, plan: request)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.toast = ToastData(
                        type: .error,
                        title: "Update Failed",
                        message: error.localizedDescription
                    )
                }
            }, receiveValue: { [weak self] response in
                // SUCCESS TOAST dla aktualizacji
                if status == "PUBLISHED" {
                    self?.toast = ToastData(
                        type: .success,
                        title: "Work Plan Updated! 🔄",
                        message: "Work plan changes have been published and employees will be notified of the updates.",
                        duration: 5.0
                    )
                } else {
                    // DRAFT TOAST
                    self?.toast = ToastData(
                        type: .info,
                        title: "Draft Updated ✏️",
                        message: "Work plan draft has been saved with your changes.",
                        duration: 3.0
                    )
                }
            })
            .store(in: &cancellables)
    }
    
    // HELPER FUNCTION: Create time for specific day
    private func createTimeForDay(timeString: String, dayDate: Date) -> Date {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // Parse time components
        guard let timeComponents = timeFormatter.date(from: timeString) else {
            return dayDate
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timeComponents)
        let minute = calendar.component(.minute, from: timeComponents)
        
        // Combine with day date
        var components = calendar.dateComponents([.year, .month, .day], from: dayDate)
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        return calendar.date(from: components) ?? dayDate
    }
}
