import Foundation
import Combine
import SwiftUI

@MainActor
class EditTaskViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var taskTitle: String = ""
    @Published var description: String = ""
    @Published var deadline: Date = Date()
    @Published var hasDeadline: Bool = false
    
    // Management Calendar Fields
    @Published var startDate: Date = Date()
    @Published var hasStartDate: Bool = false
    @Published var status: ProjectTaskStatus = .planned
    @Published var priority: TaskPriority = .medium
    @Published var estimatedHours: Double = 8.0
    @Published var hasEstimatedHours: Bool = false
    @Published var requiredOperators: Int = 1
    @Published var hasRequiredOperators: Bool = false
    @Published var clientEquipmentInfo: String = ""
    
    // Equipment Fields - Using IDs instead of structs
    @Published var selectedCraneTypeIds: Set<Int> = []
    @Published var selectedCategory: CraneCategory?
    @Published var selectedBrand: CraneBrand?
    @Published var selectedModel: CraneModel?
    @Published var preferredCraneModelId: Int?
    
    // Certificate Fields - Using IDs
    @Published var selectedCertificateIds: Set<Int> = []
    
    // Other Fields
    @Published var supervisorId: Int?
    @Published var selectedProjectId: Int?
    
    // UI State
    @Published var isLoading = false
    @Published var error: String?
    @Published var showingSuccessAlert = false
    @Published var hasChanges = false
    @Published var showCertificateSelector = false
    @Published var showHierarchicalEquipmentSelector = false
    @Published var showAlert = false
    @Published var isLoadingCertificates = false
    @Published var isLoadingSupervisors = false
    @Published var availableCertificates: [CertificateType] = []
    @Published var availableSupervisors: [Employee] = []
    @Published var supervisorError: String?
    @Published var certificateError: String?
    @Published var equipmentValidationResult: EquipmentValidationResult?
    @Published var isSaving = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var updateSuccess = false
    
    // Validation Errors
    @Published var titleError: String?
    @Published var descriptionError: String?
    @Published var deadlineError: String?
    @Published var startDateError: String?
    @Published var estimatedHoursError: String?
    @Published var requiredOperatorsError: String?
    @Published var clientEquipmentInfoError: String?
    @Published var equipmentError: String?
    
    // MARK: - Private Properties
    private let apiService = ChefProjectsAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Original values for change detection
    private var originalTask: ProjectTask?
    private var originalCraneTypeIds: Set<Int> = []
    private var originalCertificateIds: Set<Int> = []
    
    let task: ProjectTask
    var onDismiss: (() -> Void)?
    var onTaskUpdated: ((ProjectTask) -> Void)?
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        !taskTitle.isEmpty &&
        !description.isEmpty &&
        titleError == nil &&
        descriptionError == nil &&
        deadlineError == nil &&
        startDateError == nil &&
        estimatedHoursError == nil &&
        requiredOperatorsError == nil &&
        clientEquipmentInfoError == nil
    }
    
    // Computed property for certificate binding
    var selectedCertificatesBinding: Binding<[CertificateType]> {
        Binding(
            get: {
                self.availableCertificates.filter { cert in
                    self.selectedCertificateIds.contains(cert.id)
                }
            },
            set: { newCertificates in
                self.selectedCertificateIds = Set(newCertificates.map { $0.id })
            }
        )
    }
    
    // MARK: - Init
    init(task: ProjectTask) {
        self.task = task
        self.originalTask = task
        
        setupInitialValues()
        setupValidation()
        setupChangeTracking()
        
        // Load data
        loadSupervisors()
        loadCertificates()
    }
    
    // MARK: - Setup Methods
    private func setupInitialValues() {
        // Basic fields
        taskTitle = task.title
        description = task.description ?? ""
        
        // Deadline
        if let deadline = task.deadline {
            self.deadline = deadline
            hasDeadline = true
        }
        
        // Management Calendar fields
        if let startDate = task.startDate {
            self.startDate = startDate
            hasStartDate = true
        }
        
        status = task.status ?? .planned
        priority = task.priority ?? .medium
        
        if let estimatedHours = task.estimatedHours {
            self.estimatedHours = estimatedHours
            hasEstimatedHours = true
        }
        
        if let requiredOperators = task.requiredOperators {
            self.requiredOperators = requiredOperators
            hasRequiredOperators = true
        }
        
        clientEquipmentInfo = task.clientEquipmentInfo ?? ""
        
        // Equipment fields - Already stored as IDs
        if let craneTypeIds = task.requiredCraneTypes {
            selectedCraneTypeIds = Set(craneTypeIds)
            originalCraneTypeIds = selectedCraneTypeIds
        }
        
        preferredCraneModelId = task.preferredCraneModelId
        
        // Certificates - Already stored as IDs
        if let certificateIds = task.requiredCertificates {
            selectedCertificateIds = Set(certificateIds)
            originalCertificateIds = selectedCertificateIds
        }
        
        // Supervisor fields
        supervisorId = task.supervisorId
        selectedProjectId = task.projectId
    }
    
    private func setupValidation() {
        // Title validation
        $taskTitle
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validateTitle(value)
            }
            .store(in: &cancellables)
        
        // Description validation
        $description
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validateDescription(value)
            }
            .store(in: &cancellables)
        
        // Start date validation
        Publishers.CombineLatest($startDate, $hasStartDate)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] date, hasDate in
                if hasDate {
                    self?.validateStartDate(date)
                } else {
                    self?.startDateError = nil
                }
            }
            .store(in: &cancellables)
        
        // Deadline validation
        Publishers.CombineLatest3($deadline, $hasDeadline, $startDate)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] deadline, hasDeadline, startDate in
                if hasDeadline {
                    self?.validateDeadline(deadline, startDate: startDate)
                } else {
                    self?.deadlineError = nil
                }
            }
            .store(in: &cancellables)
        
        // Estimated hours validation
        Publishers.CombineLatest($estimatedHours, $hasEstimatedHours)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] hours, hasHours in
                if hasHours {
                    self?.validateEstimatedHours(hours)
                } else {
                    self?.estimatedHoursError = nil
                }
            }
            .store(in: &cancellables)
        
        // Required operators validation
        Publishers.CombineLatest($requiredOperators, $hasRequiredOperators)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] operators, hasOperators in
                if hasOperators {
                    self?.validateRequiredOperators(operators)
                } else {
                    self?.requiredOperatorsError = nil
                }
            }
            .store(in: &cancellables)
        
        // Client equipment info validation
        $clientEquipmentInfo
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validateClientEquipmentInfo(value)
            }
            .store(in: &cancellables)
        
    }
    
    private func setupChangeTracking() {
        // Track all field changes
        Publishers.CombineLatest(
            Publishers.CombineLatest4($taskTitle, $description, $hasDeadline, $deadline),
            Publishers.CombineLatest4($hasStartDate, $startDate, $status, $priority)
        )
        .sink { [weak self] _ in
            self?.checkForChanges()
        }
        .store(in: &cancellables)
        
        Publishers.CombineLatest(
            Publishers.CombineLatest4($hasEstimatedHours, $estimatedHours, $hasRequiredOperators, $requiredOperators),
            Publishers.CombineLatest3($clientEquipmentInfo, $selectedCraneTypeIds, $selectedCertificateIds)
        )
        .sink { [weak self] _ in
            self?.checkForChanges()
        }
        .store(in: &cancellables)
        
        $supervisorId
            .sink { [weak self] _ in
                self?.checkForChanges()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Change Detection
    private func checkForChanges() {
        guard let original = originalTask else {
            hasChanges = false
            return
        }
        
        var changed = false
        
        // Basic fields
        if taskTitle != original.title { changed = true }
        if description != (original.description ?? "") { changed = true }
        
        // Deadline
        if hasDeadline != (original.deadline != nil) { changed = true }
        if hasDeadline, let originalDeadline = original.deadline {
            if !Calendar.current.isDate(deadline, inSameDayAs: originalDeadline) {
                changed = true
            }
        }
        
        // Management Calendar fields
        if hasStartDate != (original.startDate != nil) { changed = true }
        if hasStartDate, let originalStartDate = original.startDate {
            if !Calendar.current.isDate(startDate, inSameDayAs: originalStartDate) {
                changed = true
            }
        }
        
        if status != (original.status ?? .planned) { changed = true }
        if priority != (original.priority ?? .medium) { changed = true }
        
        if hasEstimatedHours != (original.estimatedHours != nil) { changed = true }
        if hasEstimatedHours, let originalHours = original.estimatedHours {
            if abs(estimatedHours - originalHours) > 0.01 { changed = true }
        }
        
        if hasRequiredOperators != (original.requiredOperators != nil) { changed = true }
        if hasRequiredOperators, let originalOperators = original.requiredOperators {
            if requiredOperators != originalOperators { changed = true }
        }
        
        if clientEquipmentInfo != (original.clientEquipmentInfo ?? "") { changed = true }
        
        // Equipment
        if selectedCraneTypeIds != originalCraneTypeIds { changed = true }
        
        // Certificates
        if selectedCertificateIds != originalCertificateIds { changed = true }
        
        // Supervisor
        if supervisorId != original.supervisorId { changed = true }
        
        hasChanges = changed
    }
    
    // MARK: - Validation Methods
    private func validateTitle(_ value: String) {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            titleError = "Title is required"
        } else if value.count > 200 {
            titleError = "Title must be less than 200 characters"
        } else {
            titleError = nil
        }
    }
    
    private func validateDescription(_ value: String) {
        if value.count > 2000 {
            descriptionError = "Description must be less than 2000 characters"
        } else {
            descriptionError = nil
        }
    }
    
    private func validateStartDate(_ value: Date) {
        let now = Date()
        
        if value < now.addingTimeInterval(-365 * 24 * 60 * 60) {
            startDateError = "Start date cannot be more than 1 year in the past"
        } else if value > now.addingTimeInterval(2 * 365 * 24 * 60 * 60) {
            startDateError = "Start date cannot be more than 2 years in the future"
        } else if hasDeadline && value > deadline {
            startDateError = "Start date must be before the deadline"
        } else {
            startDateError = nil
        }
    }
    
    private func validateDeadline(_ value: Date, startDate: Date) {
        if hasStartDate && value < startDate {
            deadlineError = "Deadline must be after the start date"
        } else {
            deadlineError = nil
        }
    }
    
    private func validateEstimatedHours(_ value: Double) {
        if value <= 0 {
            estimatedHoursError = "Estimated hours must be greater than 0"
        } else if value > 1000 {
            estimatedHoursError = "Estimated hours cannot exceed 1000"
        } else {
            estimatedHoursError = nil
        }
    }
    
    private func validateRequiredOperators(_ value: Int) {
        if value <= 0 {
            requiredOperatorsError = "Required operators must be at least 1"
        } else if value > 50 {
            requiredOperatorsError = "Required operators cannot exceed 50"
        } else {
            requiredOperatorsError = nil
        }
    }
    
    private func validateClientEquipmentInfo(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 1000 {
            clientEquipmentInfoError = "Client equipment information must be less than 1000 characters"
        } else {
            clientEquipmentInfoError = nil
        }
    }
    
    
    // MARK: - Save Method
    func saveTask() {
        guard isFormValid && hasChanges else { return }
        
        isLoading = true
        error = nil
        
        // Build UpdateTaskRequest with all fields including management calendar
        let updateRequest = UpdateTaskRequest(
            title: taskTitle,
            description: description.isEmpty ? nil : description,
            deadline: hasDeadline ? deadline : nil,
            supervisorId: supervisorId,
            supervisorName: nil,
            supervisorEmail: nil,
            supervisorPhone: nil,
            isActive: true,
            // Management Calendar Fields
            startDate: hasStartDate ? startDate : nil,
            status: status.rawValue,
            priority: priority.rawValue,
            estimatedHours: hasEstimatedHours ? estimatedHours : nil,
            requiredOperators: hasRequiredOperators ? requiredOperators : nil,
            clientEquipmentInfo: clientEquipmentInfo.isEmpty ? nil : clientEquipmentInfo,
            // Equipment Fields
            requiredCraneTypes: selectedCraneTypeIds.isEmpty ? nil : Array(selectedCraneTypeIds),
            preferredCraneModelId: preferredCraneModelId,
            equipmentCategoryId: nil,  // Not used in UI currently
            equipmentBrandId: nil,     // Not used in UI currently
            // Certificate Fields
            requiredCertificates: selectedCertificateIds.isEmpty ? nil : Array(selectedCertificateIds)
        )
        
        // Make API call with correct method signature
        apiService.updateTask(id: task.id, data: updateRequest)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.error = error.localizedDescription
                        print("Error updating task: \(error)")
                    }
                },
                receiveValue: { [weak self] updatedTask in
                    guard let self = self else { return }
                    
                    print("Task updated successfully")
                    self.showingSuccessAlert = true
                    
                    // Update original values
                    self.originalTask = updatedTask
                    self.originalCraneTypeIds = self.selectedCraneTypeIds
                    self.originalCertificateIds = self.selectedCertificateIds
                    self.hasChanges = false
                    
                    // Call the onTaskUpdated callback to update the parent view
                    self.onTaskUpdated?(updatedTask)
                    
                    // Dismiss the view after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.onDismiss?()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    func toggleCertificate(_ certificate: CertificateType) {
        if selectedCertificateIds.contains(certificate.id) {
            selectedCertificateIds.remove(certificate.id)
        } else {
            selectedCertificateIds.insert(certificate.id)
        }
    }
    
    func loadSupervisors() {
        // TODO: Implement supervisor loading from API
        isLoadingSupervisors = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoadingSupervisors = false
            // For now, just use empty array
            self?.availableSupervisors = []
        }
    }
    
    func loadCertificates() {
        // TODO: Implement certificate loading from API
        isLoadingCertificates = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoadingCertificates = false
            // For now, just use empty array
            self?.availableCertificates = []
        }
    }
}