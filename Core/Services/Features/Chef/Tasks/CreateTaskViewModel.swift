//
//  CreateTaskViewModel.swift - ENHANCED VERSION WITH BETTER EQUIPMENT DEBUG
//  KSR Cranes App
//
//  ✅ ENHANCED: Complete implementation with hierarchical equipment selection and detailed debug info
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
    
    // ✅ ENHANCED: Use hierarchical equipment selection with better debug
    @Published var selectedEquipment = SelectedEquipment(categoryId: nil, typeIds: [], brandId: nil, modelId: nil)
    @Published var showHierarchicalEquipmentSelector = false
    @Published var isLoadingEquipment = false
    @Published var equipmentValidationResult: EquipmentValidationResult?
    
    // Legacy properties for backward compatibility
    var requiredCraneTypes: [Int]? {
        get { selectedEquipment.typeIds.isEmpty ? nil : selectedEquipment.typeIds }
        set {
            if let types = newValue {
                selectedEquipment.typeIds = types
            } else {
                selectedEquipment.typeIds = []
            }
        }
    }
    
    var preferredCraneModel: CraneModel? {
        get {
            // Would need to fetch from API based on selectedEquipment.modelId
            return nil
        }
        set {
            selectedEquipment.modelId = newValue?.id
        }
    }
    
    // ✅ ENHANCED: Equipment selection text method with detailed info
    func getSelectedEquipmentText() -> String {
        var components: [String] = []
        
        if let categoryId = selectedEquipment.categoryId {
            components.append("Category ID: \(categoryId)")
        }
        
        if selectedEquipment.typeIds.count == 1 {
            components.append("1 crane type (ID: \(selectedEquipment.typeIds[0]))")
        } else if selectedEquipment.typeIds.count > 1 {
            components.append("\(selectedEquipment.typeIds.count) crane types (IDs: \(selectedEquipment.typeIds.map(String.init).joined(separator: ", ")))")
        }
        
        if let brandId = selectedEquipment.brandId {
            components.append("Brand ID: \(brandId)")
        }
        
        if let modelId = selectedEquipment.modelId {
            components.append("Model ID: \(modelId)")
        }
        
        if components.isEmpty {
            return "No equipment selected"
        }
        
        return components.joined(separator: " • ")
    }
    
    /// Show hierarchical equipment selector
    func showEquipmentSelector() {
        showHierarchicalEquipmentSelector = true
    }
    
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
    @Published var equipmentError: String?
    
    internal var cancellables = Set<AnyCancellable>()
    
    // ✅ ENHANCED: Form validation with detailed equipment validation
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
        
        // ✅ ENHANCED: More detailed equipment validation
        let hasValidEquipment = selectedEquipment.hasSelection && equipmentError == nil
        
        #if DEBUG
        if !hasValidTitle || !hasValidSupervisor || !hasValidEquipment {
            print("[CreateTaskViewModel] 🚨 Form validation failed:")
            print("   - Valid title: \(hasValidTitle) (title: '\(title)', error: \(titleError ?? "none"))")
            print("   - Valid supervisor: \(hasValidSupervisor) (type: \(supervisorType), selected: \(selectedSupervisor?.name ?? "none"))")
            print("   - Valid equipment: \(hasValidEquipment) (equipment: \(selectedEquipment), error: \(equipmentError ?? "none"))")
        }
        #endif
        
        return hasValidTitle && hasValidSupervisor && hasValidEquipment
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
        
        // ✅ ENHANCED: Equipment validation with detailed logging
        $selectedEquipment
            .sink { [weak self] equipment in
                #if DEBUG
                print("[CreateTaskViewModel] 🔧 Equipment selection changed: \(equipment)")
                #endif
                self?.validateEquipment(equipment)
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
    
    // ✅ ENHANCED: Equipment validation with detailed logging
    private func validateEquipment(_ equipment: SelectedEquipment) {
        #if DEBUG
        print("[CreateTaskViewModel] 🔧 Validating equipment selection:")
        print("   - Category ID: \(equipment.categoryId?.description ?? "none")")
        print("   - Type IDs: \(equipment.typeIds)")
        print("   - Brand ID: \(equipment.brandId?.description ?? "none")")
        print("   - Model ID: \(equipment.modelId?.description ?? "none")")
        print("   - Has selection: \(equipment.hasSelection)")
        print("   - Is complete: \(equipment.isComplete)")
        #endif
        
        if !equipment.hasSelection {
            equipmentError = "Please select at least one crane type"
            #if DEBUG
            print("[CreateTaskViewModel] ❌ Equipment validation failed: No selection")
            #endif
        } else {
            equipmentError = nil
            #if DEBUG
            print("[CreateTaskViewModel] ✅ Equipment validation passed")
            #endif
            
            // ✅ ENHANCED: Validate equipment selection with API if complete
            if equipment.isComplete {
                validateEquipmentWithAPI(equipment)
            }
        }
    }
    
    private func validateEquipmentWithAPI(_ equipment: SelectedEquipment) {
        #if DEBUG
        print("[CreateTaskViewModel] 🔍 Validating equipment with API...")
        #endif
        
        EquipmentAPIService.shared.validateEquipmentSelection(
            categoryId: equipment.categoryId,
            typeId: equipment.typeIds.first, // For now, validate first type
            brandId: equipment.brandId,
            modelId: equipment.modelId
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    #if DEBUG
                    print("[CreateTaskViewModel] ❌ Equipment API validation failed: \(error)")
                    #endif
                }
            },
            receiveValue: { [weak self] result in
                #if DEBUG
                print("[CreateTaskViewModel] 📋 Equipment validation result: \(result)")
                print("   - Is completely valid: \(result.isCompletelyValid)")
                if !result.validationErrors.isEmpty {
                    print("   - Validation errors: \(result.validationErrors)")
                }
                #endif
                
                self?.equipmentValidationResult = result
                
                if !result.isCompletelyValid {
                    self?.equipmentError = result.validationErrors.first
                } else {
                    self?.equipmentError = nil
                }
            }
        )
        .store(in: &cancellables)
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
    
    // MARK: - ✅ ENHANCED: Equipment Selection Methods with Better Logging
    
    /// Check if equipment selection is compatible with worker
    func isWorkerCompatible(_ worker: AvailableWorker) -> Bool {
        guard !selectedEquipment.typeIds.isEmpty else {
            #if DEBUG
            print("[CreateTaskViewModel] 🤝 Worker \(worker.employee.name) is compatible (no equipment requirements)")
            #endif
            return true
        }
        
        // ✅ FIXED: Remove optional chaining on non-optional id property
        let workerTypeIds = Set(worker.craneTypes.map { $0.id })
        let requiredTypeIds = Set(selectedEquipment.typeIds)
        
        // Worker must have skills for at least one required type
        let isCompatible = !workerTypeIds.intersection(requiredTypeIds).isEmpty
        
        #if DEBUG
        print("[CreateTaskViewModel] 🤝 Worker \(worker.employee.name) compatibility check:")
        print("   - Worker crane types: \(workerTypeIds)")
        print("   - Required crane types: \(requiredTypeIds)")
        print("   - Is compatible: \(isCompatible)")
        #endif
        
        return isCompatible
    }
    
    /// Get compatible workers based on equipment requirements
    func getCompatibleWorkers() -> [AvailableWorker] {
        let compatible = selectedWorkers.filter { isWorkerCompatible($0) }
        
        #if DEBUG
        print("[CreateTaskViewModel] 👥 Compatible workers: \(compatible.count) of \(selectedWorkers.count)")
        compatible.forEach { worker in
            print("   - \(worker.employee.name)")
        }
        #endif
        
        return compatible
    }
    
    /// Get incompatible workers
    func getIncompatibleWorkers() -> [AvailableWorker] {
        let incompatible = selectedWorkers.filter { !isWorkerCompatible($0) }
        
        #if DEBUG
        if !incompatible.isEmpty {
            print("[CreateTaskViewModel] ⚠️ Incompatible workers: \(incompatible.count)")
            incompatible.forEach { worker in
                print("   - \(worker.employee.name)")
            }
        }
        #endif
        
        return incompatible
    }
    
    // MARK: - Supervisor API Methods
    
    func loadAvailableSupervisors() {
        isLoadingSupervisors = true
        supervisorError = nil
        
        #if DEBUG
        print("[CreateTaskViewModel] 🔄 Loading supervisors from proper API endpoint...")
        #endif
        
        loadSupervisorsFromProperEndpoint()
    }
    
    private func loadSupervisorsFromProperEndpoint() {
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
                    
                    self?.handleSupervisorAPIFailure(error: error)
                    
                case .finished:
                    #if DEBUG
                    print("✅ [CreateTaskViewModel] Supervisors loaded successfully from proper endpoint")
                    #endif
                }
            },
            receiveValue: { [weak self] (supervisorResponses: [SupervisorResponse]) in
                #if DEBUG
                print("✅ [CreateTaskViewModel] Received \(supervisorResponses.count) supervisors (byggeleder/chef)")
                supervisorResponses.forEach { supervisor in
                    print("   - ID: \(supervisor.employeeId), Name: \(supervisor.name), Role: \(supervisor.role)")
                }
                #endif
                
                self?.availableSupervisors = supervisorResponses.compactMap { response in
                    let employeeDict: [String: Any] = [
                        "employee_id": response.employeeId,
                        "name": response.name,
                        "email": response.email,
                        "role": response.role,
                        "phone_number": response.phoneNumber as Any,
                        "profilePictureUrl": response.profilePictureUrl as Any,
                        "is_activated": true,
                        "crane_types": [] as [[String: Any]],
                        "address": response.address as Any,
                        "emergency_contact": NSNull(),
                        "cpr_number": NSNull(),
                        "birth_date": NSNull(),
                        "has_driving_license": response.hasDrivingLicense as Any,
                        "driving_license_category": response.drivingLicenseCategory as Any,
                        "driving_license_expiration": response.drivingLicenseExpiration as Any
                    ]
                    
                    do {
                        let data = try JSONSerialization.data(withJSONObject: employeeDict)
                        return try JSONDecoder().decode(Employee.self, from: data)
                    } catch {
                        #if DEBUG
                        print("❌ Failed to convert supervisor to employee: \(error)")
                        #endif
                        return nil
                    }
                }
            }
        )
        .store(in: &cancellables)
    }
    
    private func handleSupervisorAPIFailure(error: Error) {
        #if DEBUG
        print("⚠️ [CreateTaskViewModel] API failed, using fallback data. Error: \(error.localizedDescription)")
        #endif
        
        supervisorError = "Failed to load supervisors from server. Using limited data."
        
        let fallbackEmployeeDict: [String: Any] = [
            "employee_id": 8,
            "name": "Admin (Fallback)",
            "email": "admin@ksrcranes.dk",
            "role": "chef",
            "phone_number": "+45 12 34 56 78",
            "profilePictureUrl": NSNull(),
            "is_activated": true,
            "crane_types": [] as [[String: Any]],
            "address": NSNull(),
            "emergency_contact": NSNull(),
            "cpr_number": NSNull(),
            "birth_date": NSNull(),
            "has_driving_license": NSNull(),
            "driving_license_category": NSNull(),
            "driving_license_expiration": NSNull()
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: fallbackEmployeeDict)
            let fallbackEmployee = try JSONDecoder().decode(Employee.self, from: data)
            self.availableSupervisors = [fallbackEmployee]
        } catch {
            #if DEBUG
            print("❌ Failed to create fallback supervisor: \(error)")
            #endif
            self.availableSupervisors = []
        }
        
        selectedSupervisor = nil
    }
    
    // MARK: - Worker Management (updated with equipment compatibility)
    
    func removeWorker(_ worker: AvailableWorker) {
        selectedWorkers.removeAll { $0.employee.employeeId == worker.employee.employeeId }
        
        #if DEBUG
        print("[CreateTaskViewModel] 🗑️ Removed worker: \(worker.employee.name)")
        print("[CreateTaskViewModel] Remaining workers: \(selectedWorkers.count)")
        #endif
    }
    
    func addWorker(_ worker: AvailableWorker) {
        if !selectedWorkers.contains(where: { $0.employee.employeeId == worker.employee.employeeId }) {
            selectedWorkers.append(worker)
            
            #if DEBUG
            print("[CreateTaskViewModel] ➕ Added worker: \(worker.employee.name)")
            print("[CreateTaskViewModel] Total workers: \(selectedWorkers.count)")
            print("[CreateTaskViewModel] Compatible: \(isWorkerCompatible(worker))")
            #endif
        }
    }
    
    // MARK: - ✅ ENHANCED: Worker Validation with Equipment Compatibility
    
    func validateSelectedWorkers() -> WorkerAssignmentValidation {
        let validation = ChefProjectsAPIService.shared.validateWorkerAssignments(
            workers: selectedWorkers,
            requiredCraneTypes: selectedEquipment.typeIds.isEmpty ? nil : selectedEquipment.typeIds,
            taskDate: hasDeadline ? deadline : nil
        )
        
        #if DEBUG
        print("[CreateTaskViewModel] 📋 Worker validation results:")
        print("   - Valid workers: \(validation.validWorkers.count)")
        print("   - Unavailable workers: \(validation.unavailableWorkers.count)")
        print("   - Workers with missing skills: \(validation.workersWithMissingSkills.count)")
        print("   - Workers with conflicts: \(validation.workersWithConflicts.count)")
        print("   - Has issues: \(validation.hasIssues)")
        print("   - Can proceed: \(validation.canProceed)")
        if validation.hasIssues {
            print("   - Issues summary: \(validation.issuesSummary)")
        }
        #endif
        
        return validation
    }
    
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
    
    // MARK: - ✅ ENHANCED: Task Creation with Comprehensive Equipment Debug
    
    func createTask(completion: @escaping (ProjectTask?) -> Void) {
        guard isFormValid else {
            showError("Validation Error", "Please correct the errors in the form.")
            completion(nil)
            return
        }
        
        // Additional validation for supervisor
        if supervisorType == .internal {
            guard let supervisor = selectedSupervisor else {
                showError("Supervisor Required", "Please select a supervisor before creating the task.")
                completion(nil)
                return
            }
            
            let validSupervisorRoles = ["byggeleder", "chef"]
            if supervisor.id <= 0 || !validSupervisorRoles.contains(supervisor.role) {
                showError("Invalid Supervisor", "Please select a valid supervisor (byggeleder or chef) from the list.")
                completion(nil)
                return
            }
        }
        
        // ✅ ENHANCED: Detailed equipment validation logging
        guard selectedEquipment.hasSelection else {
            showError("Equipment Required", "Please select equipment requirements for this task.")
            completion(nil)
            return
        }
        
        isLoading = true
        creationSuccess = false
        
        #if DEBUG
        print("[CreateTaskViewModel] 🚀 Starting task creation process...")
        print("[CreateTaskViewModel] Project ID: \(projectId)")
        print("[CreateTaskViewModel] Title: '\(title)')")
        print("[CreateTaskViewModel] 🔧 DETAILED EQUIPMENT INFO:")
        print("   - Category ID: \(selectedEquipment.categoryId?.description ?? "none")")
        print("   - Type IDs: \(selectedEquipment.typeIds) (count: \(selectedEquipment.typeIds.count))")
        print("   - Brand ID: \(selectedEquipment.brandId?.description ?? "none")")
        print("   - Model ID: \(selectedEquipment.modelId?.description ?? "none")")
        print("   - Has selection: \(selectedEquipment.hasSelection)")
        print("   - Is complete: \(selectedEquipment.isComplete)")
        print("[CreateTaskViewModel] Supervisor: \(supervisorType)")
        if let supervisor = selectedSupervisor {
            print("[CreateTaskViewModel] Supervisor ID: \(supervisor.id) (Name: \(supervisor.name))")
        }
        print("[CreateTaskViewModel] Workers: \(selectedWorkers.count)")
        #endif
        
        // Validate worker assignments with equipment requirements
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
        
        // ✅ FIXED: Create worker assignments with enhanced crane selection
        let workerAssignments = createWorkerAssignments()
        
        #if DEBUG
        print("[CreateTaskViewModel] 📋 Enhanced task request prepared")
        print("[CreateTaskViewModel] 👥 Worker assignments: \(workerAssignments.count)")
        #endif
        
        // Execute creation with enhanced API
        createTaskWithAPI(workerAssignments: workerAssignments, completion: completion)
    }
    
    // ✅ FIXED: Enhanced worker assignment creation with proper crane selection
    private func createWorkerAssignments() -> [CreateTaskAssignmentRequest] {
        return selectedWorkers.compactMap { worker in
            let craneModel = selectOptimalCraneModel(for: worker)
            
            #if DEBUG
            print("[CreateTaskViewModel] 👷 Worker assignment for \(worker.employee.name):")
            print("   - Employee ID: \(worker.employee.employeeId)")
            print("   - Selected crane model ID: \(craneModel?.id != nil ? String(craneModel!.id) : "none")")
            print("   - Worker crane types: \(worker.craneTypes.map { $0.name })")
            #endif
            
            return CreateTaskAssignmentRequest(
                employeeId: worker.employee.employeeId,
                craneModelId: craneModel?.id
            )
        }
    }
    
    private func createTaskWithAPI(
        workerAssignments: [CreateTaskAssignmentRequest],
        completion: @escaping (ProjectTask?) -> Void
    ) {
        // ✅ ENHANCED: Create task request with detailed equipment logging
        let taskRequest = CreateTaskRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            deadline: hasDeadline ? deadline : nil,
            supervisorId: supervisorType == .internal ? selectedSupervisor?.employeeId : nil,
            supervisorName: supervisorType == .external ? externalSupervisorName : selectedSupervisor?.name,
            supervisorEmail: supervisorType == .external ? externalSupervisorEmail : selectedSupervisor?.email,
            supervisorPhone: supervisorType == .external ? externalSupervisorPhone : selectedSupervisor?.phoneNumber,
            // ✅ CRITICAL: Transfer equipment data from selectedEquipment
            requiredCraneTypes: selectedEquipment.typeIds.isEmpty ? nil : selectedEquipment.typeIds,
            preferredCraneModelId: selectedEquipment.modelId,
            equipmentCategoryId: selectedEquipment.categoryId,
            equipmentBrandId: selectedEquipment.brandId
        )
        
        #if DEBUG
        print("[CreateTaskViewModel] 🏗️ FINAL EQUIPMENT DATA BEING SENT TO API:")
        print("   - required_crane_types: \(taskRequest.requiredCraneTypes?.description ?? "nil")")
        print("   - preferred_crane_model_id: \(taskRequest.preferredCraneModelId?.description ?? "nil")")
        print("   - equipment_category_id: \(taskRequest.equipmentCategoryId?.description ?? "nil")")
        print("   - equipment_brand_id: \(taskRequest.equipmentBrandId?.description ?? "nil")")
        print("[CreateTaskViewModel] 📤 About to call createTaskWithWorkers API...")
        #endif
        
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
                    print("[CreateTaskViewModel] 🔧 CREATED TASK EQUIPMENT VERIFICATION:")
                    print("   - required_crane_types: \(result.task.requiredCraneTypes?.description ?? "nil")")
                    print("   - preferred_crane_model_id: \(result.task.preferredCraneModelId?.description ?? "nil")")
                    print("   - equipment_category_id: \(result.task.equipmentCategoryId?.description ?? "nil")")
                    print("   - equipment_brand_id: \(result.task.equipmentBrandId?.description ?? "nil")")
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
    
    /// ✅ FIXED: Smart crane selection with equipment requirements
    private func selectOptimalCraneModel(for worker: AvailableWorker) -> CraneModel? {
        // 1. Prioritize preferred crane model if worker has skills
        if let _ = selectedEquipment.modelId {
            // ✅ FIXED: Remove optional chaining on non-optional id property
            let workerTypeIds = worker.craneTypes.map { $0.id }
            let hasRequiredSkill = selectedEquipment.typeIds.contains { requiredTypeId in
                workerTypeIds.contains(requiredTypeId)
            }
            
            if hasRequiredSkill {
                // Would need to fetch model details from API
                // For now, return nil and let API handle it
                return nil
            }
        }
        
        // 2. Use required crane types to find compatible model
        if !selectedEquipment.typeIds.isEmpty {
            // ✅ FIXED: Remove optional chaining on non-optional id property
            let workerTypeIds = Set(worker.craneTypes.map { $0.id })
            let requiredTypeIds = Set(selectedEquipment.typeIds)
            
            if !workerTypeIds.intersection(requiredTypeIds).isEmpty {
                // Would need to fetch available models for this type
                // For now, return nil and let API handle it
                return nil
            }
        }
        
        return nil
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

// MARK: - ✅ Enhanced Models for Equipment Requirements

/// Enhanced task request with equipment requirements
struct EnhancedCreateTaskRequest: Codable {
    let title: String
    let description: String?
    let deadline: Date?
    let supervisorId: Int?
    let supervisorName: String?
    let supervisorEmail: String?
    let supervisorPhone: String?
    let requiredCraneTypes: [Int]
    let preferredCraneModelId: Int?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case deadline
        case supervisorId = "supervisor_id"
        case supervisorName = "supervisor_name"
        case supervisorEmail = "supervisor_email"
        case supervisorPhone = "supervisor_phone"
        case requiredCraneTypes = "required_crane_types"
        case preferredCraneModelId = "preferred_crane_model_id"
    }
}

/// Dedicated model for supervisor API response
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
