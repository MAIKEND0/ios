//
//  CreateTaskViewModel.swift - CLEAN VERSION
//  KSR Cranes App
//
//  ✅ FIXED: Real API implementation for supervisors (no duplicates)
//

import Foundation
import SwiftUI
import Combine

// Move enum outside class to avoid context issues
enum SupervisorType {
    case `internal`, external
}

class CreateTaskViewModel: ObservableObject {
    // Task Info
    @Published var projectId: Int = 0
    @Published var title = ""
    @Published var description = ""
    @Published var hasDeadline = false
    @Published var deadline = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days default
    
    // Supervisor
    @Published var supervisorType: SupervisorType = .internal
    @Published var selectedSupervisor: Employee?
    @Published var availableSupervisors: [Employee] = []
    @Published var isLoadingSupervisors = false
    
    // External Supervisor
    @Published var externalSupervisorName = ""
    @Published var externalSupervisorEmail = ""
    @Published var externalSupervisorPhone = ""
    
    // Workers
    @Published var selectedWorkers: [AvailableWorker] = []
    @Published var showWorkerPicker = false
    @Published var requiredCraneTypes: [Int]? = nil
    
    // State
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var creationSuccess = false
    
    // Validation Errors
    @Published var titleError: String?
    @Published var supervisorError: String?
    @Published var supervisorNameError: String?
    @Published var supervisorEmailError: String?
    @Published var supervisorPhoneError: String?
    
    internal var cancellables = Set<AnyCancellable>()
    
    var isFormValid: Bool {
        let hasValidTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && titleError == nil
        
        let hasValidSupervisor: Bool
        if supervisorType == .internal {
            hasValidSupervisor = selectedSupervisor != nil
        } else {
            hasValidSupervisor = !externalSupervisorName.isEmpty &&
                                  !externalSupervisorEmail.isEmpty &&
                                  !externalSupervisorPhone.isEmpty &&
                                  supervisorNameError == nil &&
                                  supervisorEmailError == nil &&
                                  supervisorPhoneError == nil
        }
        
        return hasValidTitle && hasValidSupervisor
    }
    
    init() {
        setupValidation()
    }
    
    // MARK: - Validation Setup
    
    private func setupValidation() {
        // Title validation
        $title
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validateTitle(value)
            }
            .store(in: &cancellables)
        
        // External supervisor validation
        $externalSupervisorName
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                guard self?.supervisorType == .external else { return }
                self?.validateSupervisorName(value)
            }
            .store(in: &cancellables)
        
        $externalSupervisorEmail
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                guard self?.supervisorType == .external else { return }
                self?.validateSupervisorEmail(value)
            }
            .store(in: &cancellables)
        
        $externalSupervisorPhone
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                guard self?.supervisorType == .external else { return }
                self?.validateSupervisorPhone(value)
            }
            .store(in: &cancellables)
        
        // Supervisor type validation
        $supervisorType
            .sink { [weak self] type in
                if type == .internal && self?.selectedSupervisor == nil {
                    self?.supervisorError = "Please select a supervisor"
                } else {
                    self?.supervisorError = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    
    private func validateTitle(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed.count < 3 {
            titleError = "Task title must be at least 3 characters"
        } else if trimmed.count > 255 {
            titleError = "Task title must be less than 255 characters"
        } else {
            titleError = nil
        }
    }
    
    private func validateSupervisorName(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed.count < 2 {
            supervisorNameError = "Name must be at least 2 characters"
        } else {
            supervisorNameError = nil
        }
    }
    
    private func validateSupervisorEmail(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !isValidEmail(trimmed) {
            supervisorEmailError = "Please enter a valid email"
        } else {
            supervisorEmailError = nil
        }
    }
    
    private func validateSupervisorPhone(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed.count < 8 {
            supervisorPhoneError = "Please enter a valid phone number"
        } else {
            supervisorPhoneError = nil
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - API Methods
    
    /// ✅ FIXED: Load supervisors from proper API endpoint
    func loadAvailableSupervisors() {
        isLoadingSupervisors = true
        supervisorError = nil
        
        #if DEBUG
        print("[CreateTaskViewModel] 🔄 Loading supervisors from proper API endpoint...")
        #endif
        
        // ✅ FIXED: Use the correct endpoint that you just created
        loadSupervisorsFromProperEndpoint()
    }
    
    /// Load supervisors from the correct API endpoint
    private func loadSupervisorsFromProperEndpoint() {
        // Use the actual endpoint you created: /api/app/chef/employees/supervisors
        let endpoint = "/api/app/chef/employees/supervisors?include_external=false"
        
        #if DEBUG
        print("[CreateTaskViewModel] 📞 API Call: \(endpoint)")
        #endif
        
        ChefProjectsAPIService.shared.makeRequest(
            endpoint: endpoint,
            method: "GET",
            body: Optional<String>.none
        )
        .decode(type: [SupervisorResponse].self, decoder: ChefProjectsAPIService.shared.jsonDecoder())
        .mapError { ($0 as? ChefProjectsAPIService.APIError) ?? .decodingError($0) }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoadingSupervisors = false
                
                switch completion {
                case .failure(let error):
                    #if DEBUG
                    print("❌ [CreateTaskViewModel] Failed to load supervisors: \(error)")
                    #endif
                    
                    // Fallback to temporary data if API fails
                    self?.handleSupervisorAPIFailure(error: error)
                    
                case .finished:
                    #if DEBUG
                    print("✅ [CreateTaskViewModel] Supervisors loaded successfully from proper endpoint")
                    #endif
                }
            },
            receiveValue: { [weak self] supervisorResponses in
                #if DEBUG
                print("✅ [CreateTaskViewModel] Received \(supervisorResponses.count) supervisors (byggeleder/chef)")
                supervisorResponses.forEach { supervisor in
                    print("   - ID: \(supervisor.employeeId), Name: \(supervisor.name), Role: \(supervisor.role)")
                }
                #endif
                
                // ✅ FIXED: Convert SupervisorResponse to Employee objects
                self?.availableSupervisors = supervisorResponses.map { response in
                    Employee(
                        id: response.employeeId,
                        name: response.name,
                        email: response.email,
                        role: response.role,
                        phoneNumber: response.phoneNumber,
                        profilePictureUrl: response.profilePictureUrl,
                        isActivated: nil, // ✅ FIXED: Set to nil since API doesn't provide this
                        craneTypes: nil,
                        address: response.address,
                        emergencyContact: nil,
                        cprNumber: nil,
                        birthDate: nil,
                        hasDrivingLicense: response.hasDrivingLicense,
                        drivingLicenseCategory: response.drivingLicenseCategory,
                        drivingLicenseExpiration: response.drivingLicenseExpiration
                    )
                }
            }
        )
        .store(in: &cancellables)
    }
    
    /// Fallback method when real API fails
    private func handleSupervisorAPIFailure(error: Error) {
        #if DEBUG
        print("⚠️ [CreateTaskViewModel] API failed, using fallback data. Error: \(error.localizedDescription)")
        #endif
        
        // Show error to user but continue with fallback
        self.supervisorError = "Failed to load supervisors from server. Using limited data."
        
        // ✅ FIXED: Use Admin's ID (8) as fallback since we know it exists from logs
        self.availableSupervisors = [
            Employee(
                id: 8, // Admin's ID from logs - known to exist
                name: "Admin (Fallback)",
                email: "admin@ksrcranes.dk",
                role: "chef", // Use chef role since Admin is chef
                phoneNumber: "+45 12 34 56 78",
                profilePictureUrl: nil,
                isActivated: nil, // ✅ FIXED: Set to nil for fallback
                craneTypes: nil,
                address: nil,
                emergencyContact: nil,
                cprNumber: nil,
                birthDate: nil,
                hasDrivingLicense: nil,
                drivingLicenseCategory: nil,
                drivingLicenseExpiration: nil
            )
        ]
        
        // Reset selection
        self.selectedSupervisor = nil
    }
    
    // MARK: - Worker Management
    
    func removeWorker(_ worker: AvailableWorker) {
        selectedWorkers.removeAll { $0.employee.employeeId == worker.employee.employeeId }
        
        #if DEBUG
        print("[CreateTaskViewModel] Removed worker: \(worker.employee.name)")
        print("[CreateTaskViewModel] Remaining workers: \(selectedWorkers.count)")
        #endif
    }
    
    func addWorker(_ worker: AvailableWorker) {
        // Check if worker is already selected
        if !selectedWorkers.contains(where: { $0.employee.employeeId == worker.employee.employeeId }) {
            selectedWorkers.append(worker)
            
            #if DEBUG
            print("[CreateTaskViewModel] Added worker: \(worker.employee.name)")
            print("[CreateTaskViewModel] Total workers: \(selectedWorkers.count)")
            #endif
        }
    }
    
    // MARK: - Worker Validation Methods
    
    /// Validate workers before task creation
    func validateSelectedWorkers() -> WorkerAssignmentValidation {
        return ChefProjectsAPIService.shared.validateWorkerAssignments(
            workers: selectedWorkers,
            requiredCraneTypes: requiredCraneTypes,
            taskDate: hasDeadline ? deadline : nil
        )
    }
    
    /// Show validation warnings to user
    func showWorkerValidationWarnings() {
        let validation = validateSelectedWorkers()
        
        guard validation.hasIssues else { return }
        
        let message = """
        Some selected workers have issues: \(validation.issuesSummary).
        
        \(validation.validWorkers.count) workers can be assigned successfully.
        
        Do you want to proceed?
        """
        
        self.showWarning("Worker Assignment Issues", message)
    }
    
    // MARK: - Task Creation
    
    /// ✅ PRODUCTION READY: Create task with real API integration
    func createTask(completion: @escaping (ProjectTask?) -> Void) {
        guard isFormValid else {
            showError("Validation Error", "Please correct the errors in the form.")
            completion(nil)
            return
        }
        
        // ✅ ADDITIONAL VALIDATION: Check if supervisor exists
        if supervisorType == .internal {
            guard let supervisor = selectedSupervisor else {
                showError("Supervisor Required", "Please select a supervisor before creating the task.")
                completion(nil)
                return
            }
            
            // ✅ Check if supervisor ID is valid and has supervisor role (byggeleder or chef)
            let validSupervisorRoles = ["byggeleder", "chef"]
            if supervisor.id <= 0 || !validSupervisorRoles.contains(supervisor.role) {
                showError("Invalid Supervisor", "Please select a valid supervisor (byggeleder or chef) from the list.")
                completion(nil)
                return
            }
        }
        
        isLoading = true
        creationSuccess = false
        
        #if DEBUG
        print("[CreateTaskViewModel] 🚀 Starting task creation process...")
        print("[CreateTaskViewModel] Project ID: \(projectId)")
        print("[CreateTaskViewModel] Title: '\(title)'")
        print("[CreateTaskViewModel] Supervisor: \(supervisorType)")
        if let supervisor = selectedSupervisor {
            print("[CreateTaskViewModel] Supervisor ID: \(supervisor.id) (Name: \(supervisor.name))")
        }
        print("[CreateTaskViewModel] Workers: \(selectedWorkers.count)")
        #endif
        
        // Step 1: Validate worker assignments
        let validation = validateSelectedWorkers()
        if validation.hasIssues {
            #if DEBUG
            print("[CreateTaskViewModel] ⚠️ Worker validation issues: \(validation.issuesSummary)")
            #endif
            
            if !validation.canProceed {
                showError("Worker Assignment Error", validation.issuesSummary)
                isLoading = false
                completion(nil)
                return
            }
        }
        
        // Step 2: Create task request
        let taskRequest = CreateTaskRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            deadline: hasDeadline ? deadline : nil,
            supervisorId: supervisorType == .internal ? selectedSupervisor?.employeeId : nil,
            supervisorName: supervisorType == .external ? externalSupervisorName : selectedSupervisor?.name,
            supervisorEmail: supervisorType == .external ? externalSupervisorEmail : selectedSupervisor?.email,
            supervisorPhone: supervisorType == .external ? externalSupervisorPhone : selectedSupervisor?.phoneNumber
        )
        
        // Step 3: Create worker assignments with smart crane selection
        let workerAssignments = selectedWorkers.compactMap { worker in
            CreateTaskAssignmentRequest(
                employeeId: worker.employee.employeeId,
                craneModelId: selectOptimalCraneModel(for: worker)?.id
            )
        }
        
        #if DEBUG
        print("[CreateTaskViewModel] 📋 Task request prepared")
        print("[CreateTaskViewModel] 👥 Worker assignments: \(workerAssignments.count)")
        #endif
        
        // Step 4: Execute creation with enhanced API
        createTaskWithAPI(taskRequest: taskRequest, workerAssignments: workerAssignments, completion: completion)
    }
    
    private func createTaskWithAPI(
        taskRequest: CreateTaskRequest,
        workerAssignments: [CreateTaskAssignmentRequest],
        completion: @escaping (ProjectTask?) -> Void
    ) {
        // Use the enhanced API method that creates task and assigns workers atomically
        ChefProjectsAPIService.shared.createTaskWithWorkers(
            projectId: projectId,
            task: taskRequest,
            workerAssignments: workerAssignments
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                
                switch completionResult {
                case .failure(let error):
                    #if DEBUG
                    print("❌ [CreateTaskViewModel] Task creation failed: \(error)")
                    #endif
                    
                    let userFriendlyMessage = self?.getUserFriendlyErrorMessage(error) ?? error.localizedDescription
                    self?.showError("Creation Failed", userFriendlyMessage)
                    completion(nil)
                    
                case .finished:
                    #if DEBUG
                    print("[CreateTaskViewModel] ✅ Task creation flow completed")
                    #endif
                }
            },
            receiveValue: { [weak self] result in
                #if DEBUG
                print("✅ [CreateTaskViewModel] Task creation result received")
                print("[CreateTaskViewModel] Task: '\(result.task.title)' (ID: \(result.task.id))")
                print("[CreateTaskViewModel] Assignments: \(result.assignments.count)")
                print("[CreateTaskViewModel] Errors: \(result.assignmentErrors.count)")
                #endif
                
                self?.creationSuccess = true
                self?.handleTaskCreationResult(result, completion: completion)
            }
        )
        .store(in: &cancellables)
    }
    
    private func handleTaskCreationResult(
        _ result: TaskCreationResult,
        completion: @escaping (ProjectTask?) -> Void
    ) {
        if result.isFullySuccessful {
            showSuccess("Task Created Successfully", result.successMessage)
        } else if result.hasPartialFailure {
            showWarning("Task Created with Issues", result.successMessage)
        } else {
            showWarning("Task Created", "Task was created but workers could not be assigned. You can assign them later.")
        }
        
        completion(result.task)
    }
    
    // MARK: - Helper Methods
    
    private func selectOptimalCraneModel(for worker: AvailableWorker) -> CraneType? {
        // Smart selection: prioritize required crane types, then worker's primary skill
        if let required = requiredCraneTypes, !required.isEmpty {
            return worker.craneTypes.first { required.contains($0.id) }
        }
        
        // If no specific requirements, use worker's first (presumably primary) crane type
        return worker.craneTypes.first
    }
    
    private func getUserFriendlyErrorMessage(_ error: Error) -> String {
        if let apiError = error as? ChefProjectsAPIService.APIError {
            switch apiError {
            case .serverError(let code, let message):
                switch code {
                case 400:
                    return "Invalid task data. Please check all fields and try again."
                case 401:
                    return "Authentication expired. Please log in again."
                case 403:
                    return "You don't have permission to create tasks for this project."
                case 404:
                    return "Project not found. Please refresh and try again."
                case 409:
                    return "A task with this name already exists in the project."
                case 422:
                    return "Some workers are not available for assignment. Please review your selection."
                case 500:
                    if message.contains("Foreign key constraint") {
                        return "Selected supervisor is no longer available. Please choose a different supervisor."
                    }
                    return "Server error occurred. Please try again."
                default:
                    return message
                }
            case .networkError:
                return "Network connection error. Please check your internet connection and try again."
            case .decodingError:
                return "Unexpected response from server. Please try again."
            default:
                return "An unexpected error occurred. Please try again."
            }
        }
        
        return error.localizedDescription
    }
    
    // MARK: - Alert Methods
    
    func showError(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        
        #if DEBUG
        print("🚨 [CreateTaskViewModel] Error: \(title) - \(message)")
        #endif
    }
    
    func showSuccess(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        
        #if DEBUG
        print("✅ [CreateTaskViewModel] Success: \(title) - \(message)")
        #endif
    }
    
    func showWarning(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        
        #if DEBUG
        print("⚠️ [CreateTaskViewModel] Warning: \(title) - \(message)")
        #endif
    }
}

// MARK: - SupervisorResponse Model

/// ✅ ADDED: Dedicated model for supervisor API response
struct SupervisorResponse: Codable {
    let employeeId: Int
    let name: String
    let email: String
    let role: String
    let phoneNumber: String?
    let profilePictureUrl: String?
    let address: String?
    let hasDrivingLicense: Bool?
    let drivingLicenseCategory: String?
    let drivingLicenseExpiration: Date?
    
    private enum CodingKeys: String, CodingKey {
        case employeeId = "employee_id"
        case name
        case email
        case role
        case phoneNumber = "phone_number"
        case profilePictureUrl
        case address
        case hasDrivingLicense = "has_driving_license"
        case drivingLicenseCategory = "driving_license_category"
        case drivingLicenseExpiration = "driving_license_expiration"
    }
}
