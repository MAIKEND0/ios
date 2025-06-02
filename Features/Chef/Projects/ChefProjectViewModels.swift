//
//  ChefProjectViewModels.swift
//  KSR Cranes App
//
//  ViewModels for Chef project management - UPDATED with real API calls and debug fixes
//

import Foundation
import SwiftUI
import Combine

// MARK: - ChefProjectsViewModel

class ChefProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedStatus: Project.ProjectStatus?
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    var filteredProjects: [Project] {
        projects.filter { project in
            let matchesSearch = searchText.isEmpty ||
                project.title.localizedCaseInsensitiveContains(searchText) ||
                (project.customer?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesStatus = selectedStatus == nil || project.status == selectedStatus
            
            return matchesSearch && matchesStatus
        }
    }
    
    var projectStats: (active: Int, waiting: Int, completed: Int) {
        let active = projects.filter { $0.status == .active }.count
        let waiting = projects.filter { $0.status == .waiting }.count
        let completed = projects.filter { $0.status == .completed }.count
        return (active, waiting, completed)
    }
    
    init() {
        // Setup search debouncing
        setupSearchDebouncing()
    }
    
    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                // Trigger filtered update - no need to reload from API for search
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func loadProjects() {
        isLoading = true
        
        #if DEBUG
        print("[ChefProjectsViewModel] Loading projects from API...")
        #endif
        
        ChefProjectsAPIService.shared.fetchProjects(
            status: selectedStatus,
            search: searchText.isEmpty ? nil : searchText,
            includeCustomer: true,
            includeStats: true
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                case .finished:
                    #if DEBUG
                    print("[ChefProjectsViewModel] Successfully loaded \(self?.projects.count ?? 0) projects")
                    #endif
                }
            },
            receiveValue: { [weak self] response in
                self?.projects = response.projects
                
                #if DEBUG
                // Debug NaN values
                self?.debugNaNValues()
                #endif
            }
        )
        .store(in: &cancellables)
    }
    
    func refreshProjects() {
        loadProjects()
    }
    
    func deleteProject(_ project: Project) {
        #if DEBUG
        print("[ChefProjectsViewModel] Deleting project: \(project.title)")
        #endif
        
        ChefProjectsAPIService.shared.deleteProject(id: project.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.showError("Failed to delete project: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    // Remove project from local array
                    self?.projects.removeAll { $0.id == project.id }
                    
                    #if DEBUG
                    print("[ChefProjectsViewModel] Project deleted successfully: \(response.message)")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func updateProjectStatus(_ project: Project, to status: Project.ProjectStatus) {
        ChefProjectsAPIService.shared.updateProjectStatus(id: project.id, status: status)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.showError("Failed to update project status: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] updatedProject in
                    // Update project in local array
                    if let index = self?.projects.firstIndex(where: { $0.id == updatedProject.id }) {
                        self?.projects[index] = updatedProject
                    }
                    
                    #if DEBUG
                    print("[ChefProjectsViewModel] Project status updated to: \(updatedProject.status.rawValue)")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    #if DEBUG
    func debugNaNValues() {
        projects.forEach { project in
            if let completion = project.completionPercentage {
                if completion.isNaN {
                    print("🚨 [DEBUG] Project '\(project.title)' has NaN completionPercentage")
                }
                if completion.isInfinite {
                    print("🚨 [DEBUG] Project '\(project.title)' has Infinite completionPercentage")
                }
                if completion < 0 || completion > 100 {
                    print("🚨 [DEBUG] Project '\(project.title)' has out-of-range completionPercentage: \(completion)")
                }
            }
        }
    }
    #endif
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
        
        #if DEBUG
        print("[ChefProjectsViewModel] Error: \(message)")
        #endif
    }
}

// MARK: - CreateProjectViewModel

class CreateProjectViewModel: ObservableObject {
    // Customer Selection
    @Published var selectedCustomer: Customer?
    @Published var showCustomerPicker = false
    
    // Project Info
    @Published var title = ""
    @Published var description = ""
    @Published var startDate = Date()
    @Published var endDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days default
    @Published var status: Project.ProjectStatus = .waiting
    
    // Location
    @Published var street = ""
    @Published var city = ""
    @Published var zip = ""
    
    // Billing Settings
    @Published var normalRate = ""
    @Published var weekendRate = ""
    @Published var overtimeRate1 = ""
    @Published var overtimeRate2 = ""
    @Published var weekendOvertimeRate1 = ""
    @Published var weekendOvertimeRate2 = ""
    
    // State
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var creationSuccess = false
    @Published var createdProject: Project?
    
    // Validation Errors
    @Published var customerError: String?
    @Published var titleError: String?
    @Published var dateError: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    var isFormValid: Bool {
        return selectedCustomer != nil &&
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               startDate <= endDate &&
               customerError == nil &&
               titleError == nil &&
               dateError == nil
    }
    
    init() {
        setupValidation()
    }
    
    private func setupValidation() {
        // Title validation
        $title
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validateTitle(value)
            }
            .store(in: &cancellables)
        
        // Date validation
        Publishers.CombineLatest($startDate, $endDate)
            .sink { [weak self] start, end in
                self?.validateDates(start: start, end: end)
            }
            .store(in: &cancellables)
        
        // Customer validation
        $selectedCustomer
            .sink { [weak self] customer in
                self?.customerError = customer == nil ? "Please select a customer" : nil
            }
            .store(in: &cancellables)
    }
    
    private func validateTitle(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed.count < 3 {
            titleError = "Project title must be at least 3 characters"
        } else if trimmed.count > 255 {
            titleError = "Project title must be less than 255 characters"
        } else {
            titleError = nil
        }
    }
    
    private func validateDates(start: Date, end: Date) {
        if start > end {
            dateError = "End date must be after start date"
        } else {
            dateError = nil
        }
    }
    
    // ✅ UPDATED METHOD WITH DEBUG AND FLEXIBLE DECODING
    func createProject(completion: @escaping (Project?) -> Void) {
        guard isFormValid else {
            showError("Validation Error", "Please correct the errors in the form.")
            completion(nil)
            return
        }
        
        // ✅ FLEXIBLE CUSTOMER ID - try both possible property names
        let customerId: Int
        if let customer_id = selectedCustomer?.customer_id {
            customerId = customer_id
        } else if let id = selectedCustomer?.id {
            customerId = id
        } else {
            showError("Customer Required", "Please select a customer for this project.")
            completion(nil)
            return
        }
        
        isLoading = true
        creationSuccess = false
        createdProject = nil
        
        #if DEBUG
        print("[CreateProjectViewModel] Creating project: \(title)")
        print("[CreateProjectViewModel] Customer ID: \(customerId)")
        print("[CreateProjectViewModel] Date range: \(startDate) - \(endDate)")
        #endif
        
        // Prepare billing settings if any rates are provided
        var billingSettings: BillingSettingsRequest? = nil
        if hasAnyBillingRates() {
            billingSettings = BillingSettingsRequest(
                normalRate: Decimal(string: normalRate) ?? 0,
                weekendRate: Decimal(string: weekendRate) ?? 0,
                overtimeRate1: Decimal(string: overtimeRate1) ?? 0,
                overtimeRate2: Decimal(string: overtimeRate2) ?? 0,
                weekendOvertimeRate1: Decimal(string: weekendOvertimeRate1) ?? 0,
                weekendOvertimeRate2: Decimal(string: weekendOvertimeRate2) ?? 0,
                effectiveFrom: startDate,
                effectiveTo: endDate
            )
        }
        
        let request = CreateProjectRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            customerId: customerId,
            startDate: startDate,
            endDate: endDate,
            street: street.isEmpty ? nil : street.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.isEmpty ? nil : city.trimmingCharacters(in: .whitespacesAndNewlines),
            zip: zip.isEmpty ? nil : zip.trimmingCharacters(in: .whitespacesAndNewlines),
            status: status.rawValue,
            billingSettings: billingSettings
        )
        
        // ✅ DEBUG VERSION - Use direct API call to see exact response
        ChefProjectsAPIService.shared.makeRequestWithRetry(
            endpoint: "/api/app/chef/projects",
            method: "POST",
            body: request
        )
        .tryMap { data in
            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 [DEBUG] EXACT API RESPONSE:")
                print(jsonString)
                print("🔍 [DEBUG] Response length: \(data.count) bytes")
            }
            #endif
            
            let decoder = BaseAPIService.createAPIDecoder()
            
            // Strategy 1: Try ChefCreateProjectResponse
            do {
                let response = try decoder.decode(ChefCreateProjectResponse.self, from: data)
                print("✅ [DEBUG] ChefCreateProjectResponse worked!")
                return response.project
            } catch let decodingError {
                print("❌ [DEBUG] ChefCreateProjectResponse failed: \(decodingError)")
                
                // Strategy 2: Try direct Project decoding (maybe API returns just project, not wrapped)
                do {
                    let project = try decoder.decode(Project.self, from: data)
                    print("✅ [DEBUG] Direct Project decoding worked!")
                    return project
                } catch let projectError {
                    print("❌ [DEBUG] Direct Project decoding failed: \(projectError)")
                    
                    // Strategy 3: Try to decode as a different wrapper
                    do {
                        // Maybe the API returns: {"data": {"project": {...}}}
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        print("🔍 [DEBUG] Raw JSON structure: \(json?.keys.sorted() ?? [])")
                        
                        // If we have "project" key directly
                        if let projectData = json?["project"] {
                            let projectJSON = try JSONSerialization.data(withJSONObject: projectData)
                            let project = try decoder.decode(Project.self, from: projectJSON)
                            print("✅ [DEBUG] Project from 'project' key worked!")
                            return project
                        }
                        
                        throw NSError(domain: "DecodingError", code: 0, userInfo: [
                            NSLocalizedDescriptionKey: "Could not decode project from any known format"
                        ])
                    } catch {
                        print("❌ [DEBUG] All decoding strategies failed")
                        throw error
                    }
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                switch completionResult {
                case .failure(let error):
                    #if DEBUG
                    print("❌ [DEBUG] Final error: \(error)")
                    #endif
                    self?.showError("Creation Failed", "Debug: \(error.localizedDescription)")
                    completion(nil)
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] project in
                #if DEBUG
                print("✅ [DEBUG] Project created successfully: \(project.title)")
                #endif
                self?.createdProject = project
                self?.creationSuccess = true
                self?.showSuccess("Project Created", "The project '\(project.title)' has been created successfully.")
                completion(project)
            }
        )
        .store(in: &cancellables)
    }
    
    private func hasAnyBillingRates() -> Bool {
        return !normalRate.isEmpty || !weekendRate.isEmpty ||
               !overtimeRate1.isEmpty || !overtimeRate2.isEmpty ||
               !weekendOvertimeRate1.isEmpty || !weekendOvertimeRate2.isEmpty
    }
    
    // Alert helpers
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    private func showError(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        
        #if DEBUG
        print("[CreateProjectViewModel] Error: \(title) - \(message)")
        #endif
    }
    
    private func showSuccess(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        
        #if DEBUG
        print("[CreateProjectViewModel] Success: \(title) - \(message)")
        #endif
    }
}

// MARK: - ProjectDetailViewModel

class ProjectDetailViewModel: ObservableObject {
    @Published var project: Project?
    @Published var tasks: [ProjectTask] = []
    @Published var projectDetail: ChefProjectDetail?
    @Published var isLoadingTasks = false
    @Published var isLoadingDetail = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadProjectDetail(projectId: Int) {
        isLoadingDetail = true
        
        #if DEBUG
        print("[ProjectDetailViewModel] Loading project detail for ID: \(projectId)")
        #endif
        
        ChefProjectsAPIService.shared.fetchProject(
            id: projectId,
            includeBilling: true,
            includeStats: true
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoadingDetail = false
                switch completion {
                case .failure(let error):
                    self?.showError("Failed to load project details: \(error.localizedDescription)")
                case .finished:
                    #if DEBUG
                    print("[ProjectDetailViewModel] Successfully loaded project detail")
                    #endif
                }
            },
            receiveValue: { [weak self] detail in
                self?.projectDetail = detail
                self?.project = detail.project
            }
        )
        .store(in: &cancellables)
    }
    
    func loadTasks(for projectId: Int) {
        isLoadingTasks = true
        
        #if DEBUG
        print("[ProjectDetailViewModel] Loading tasks for project ID: \(projectId)")
        #endif
        
        ChefProjectsAPIService.shared.fetchTasks(
            projectId: projectId,
            includeProject: false,
            includeAssignments: true
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoadingTasks = false
                switch completion {
                case .failure(let error):
                    self?.showError("Failed to load tasks: \(error.localizedDescription)")
                case .finished:
                    #if DEBUG
                    print("[ProjectDetailViewModel] Successfully loaded \(self?.tasks.count ?? 0) tasks")
                    #endif
                }
            },
            receiveValue: { [weak self] response in
                self?.tasks = response.tasks
            }
        )
        .store(in: &cancellables)
    }
    
    func updateProject(_ project: Project) {
        #if DEBUG
        print("[ProjectDetailViewModel] Updating project: \(project.title)")
        #endif
        
        // Create update request with only changed fields
        let updateData = UpdateProjectRequest(
            title: project.title,
            description: project.description,
            startDate: project.startDate,
            endDate: project.endDate,
            street: project.street,
            city: project.city,
            zip: project.zip,
            isActive: project.isActive
        )
        
        ChefProjectsAPIService.shared.updateProject(id: project.id, data: updateData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.showError("Failed to update project: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] updatedProject in
                    self?.project = updatedProject
                    
                    #if DEBUG
                    print("[ProjectDetailViewModel] Project updated successfully")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteTask(_ task: ProjectTask) {
        #if DEBUG
        print("[ProjectDetailViewModel] Deleting task: \(task.title)")
        #endif
        
        ChefProjectsAPIService.shared.deleteTask(id: task.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.showError("Failed to delete task: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    // Remove task from local array
                    self?.tasks.removeAll { $0.id == task.id }
                    
                    #if DEBUG
                    print("[ProjectDetailViewModel] Task deleted successfully: \(response.message)")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func addTask(_ task: ProjectTask) {
        // Add new task to the beginning of the array
        tasks.insert(task, at: 0)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
        
        #if DEBUG
        print("[ProjectDetailViewModel] Error: \(message)")
        #endif
    }
}

// MARK: - API Error Extension for Projects

extension BaseAPIService.APIError {
    var projectErrorMessage: String {
        switch self {
        case .serverError(let code, let message):
            if code == 409 {
                return "A project with this name already exists for this customer"
            } else if code == 404 {
                return "The requested resource was not found"
            }
            return message
        case .networkError(let error):
            return "Network connection error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Error processing server response: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid request URL"
        case .invalidResponse:
            return "Invalid server response"
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}

// MARK: - Safe Numeric Extensions
extension Double {
    /// Returns a safe value for UI calculations, converting NaN/Infinity to 0
    var safeForUI: Double {
        guard !isNaN && !isInfinite else { return 0.0 }
        return max(0.0, min(100.0, self))
    }
    
    /// Returns a safe percentage (0-100) for UI progress indicators
    var safePercentage: Double {
        guard !isNaN && !isInfinite else { return 0.0 }
        return max(0.0, min(100.0, self))
    }
}
