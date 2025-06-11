//
//  ChefProjectsAPIService.swift
//  KSR Cranes App
//
//  API Service for Chef project and task management - COMPLETE VERSION WITH PUT
//

import Foundation
import Combine
import UIKit

// MARK: - ChefProjectsAPIService

final class ChefProjectsAPIService: BaseAPIService {
    static let shared = ChefProjectsAPIService()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Projects Management
    
    /// Fetch all projects with optional filters
    func fetchProjects(
        status: Project.ProjectStatus? = nil,
        customerId: Int? = nil,
        search: String? = nil,
        limit: Int = 50,
        offset: Int = 0,
        includeCustomer: Bool = true,
        includeStats: Bool = true
    ) -> AnyPublisher<ChefProjectsResponse, APIError> {
        var endpoint = "/api/app/chef/projects"
        var queryParams: [String] = []
        
        if let status = status {
            queryParams.append("status=\(status.rawValue)")
        }
        
        if let customerId = customerId {
            queryParams.append("customer_id=\(customerId)")
        }
        
        if let search = search, !search.isEmpty {
            queryParams.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        
        queryParams.append("limit=\(limit)")
        queryParams.append("offset=\(offset)")
        
        if includeCustomer {
            queryParams.append("include_customer=true")
        }
        
        if includeStats {
            queryParams.append("include_stats=true")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        #if DEBUG
        print("[ChefProjectsAPIService] Fetching projects: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ChefProjectsResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Create a new project with billing settings (WITH RETRY LOGIC)
    func createProject(_ request: CreateProjectRequest) -> AnyPublisher<ChefCreateProjectResponse, APIError> {
        let endpoint = "/api/app/chef/projects"
        
        #if DEBUG
        print("[ChefProjectsAPIService] Creating project with retry logic: \(request.title)")
        print("[ChefProjectsAPIService] Customer ID: \(request.customerId)")
        #endif
        
        // ✅ UŻYWA makeRequestWithRetry zamiast makeRequest
        return makeRequestWithRetry(endpoint: endpoint, method: "POST", body: request)
            .decode(type: ChefCreateProjectResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Get detailed project information
    func fetchProject(id: Int, includeBilling: Bool = true, includeStats: Bool = true) -> AnyPublisher<ChefProjectDetail, APIError> {
        var endpoint = "/api/app/chef/projects/\(id)"
        var queryParams: [String] = []
        
        queryParams.append("include_customer=true")
        
        if includeBilling {
            queryParams.append("include_billing=true")
        }
        
        if includeStats {
            queryParams.append("include_stats=true")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ChefProjectDetail.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Update project information
    func updateProject(id: Int, data: UpdateProjectRequest) -> AnyPublisher<Project, APIError> {
        let endpoint = "/api/app/chef/projects/\(id)"
        
        #if DEBUG
        print("[ChefProjectsAPIService] Updating project ID: \(id)")
        #endif
        
        // ✅ UŻYWA makeRequestWithRetry dla update operations
        return makeRequestWithRetry(endpoint: endpoint, method: "PUT", body: data)
            .decode(type: Project.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Delete a project
    func deleteProject(id: Int) -> AnyPublisher<DeleteProjectResponse, APIError> {
        let endpoint = "/api/app/chef/projects/\(id)"
        
        #if DEBUG
        print("[ChefProjectsAPIService] Deleting project ID: \(id)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: DeleteProjectResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Update project status
    func updateProjectStatus(id: Int, status: Project.ProjectStatus, notes: String? = nil) -> AnyPublisher<Project, APIError> {
        let endpoint = "/api/app/chef/projects/\(id)/status"
        let request = UpdateProjectStatusRequest(status: status.rawValue, notes: notes)
        
        #if DEBUG
        print("[ChefProjectsAPIService] Updating project \(id) status to: \(status.rawValue)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "PATCH", body: request)
            .decode(type: Project.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Billing Settings Management
    
    /// Get all billing settings for a project
    func fetchProjectBillingSettings(projectId: Int) -> AnyPublisher<[ChefBillingSettings], APIError> {
        let endpoint = "/api/app/chef/projects/\(projectId)/billing-settings"
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [ChefBillingSettings].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Create new billing settings for a project (POST)
    func upsertBillingSettings(projectId: Int, settings: BillingSettingsRequest) -> AnyPublisher<ChefBillingSettings, APIError> {
        let endpoint = "/api/app/chef/projects/\(projectId)/billing-settings"
        
        #if DEBUG
        print("[ChefProjectsAPIService] Creating billing settings for project: \(projectId)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "POST", body: settings)
            .decode(type: ChefBillingSettings.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// ✅ NEW: Update existing billing settings (PUT)
    func updateBillingSettings(projectId: Int, settingId: Int, settings: BillingSettingsRequest) -> AnyPublisher<ChefBillingSettings, APIError> {
        let endpoint = "/api/app/chef/projects/\(projectId)/billing-settings?setting_id=\(settingId)"
        
        #if DEBUG
        print("[ChefProjectsAPIService] Updating billing settings \(settingId) for project: \(projectId)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "PUT", body: settings)
            .decode(type: ChefBillingSettings.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Delete billing settings
    func deleteBillingSettings(settingId: Int) -> AnyPublisher<DeleteResponse, APIError> {
        let endpoint = "/api/app/chef/billing-settings/\(settingId)"
        
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: DeleteResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Tasks Management
    
    /// Fetch tasks with filters
    func fetchTasks(
        projectId: Int? = nil,
        supervisorId: Int? = nil,
        isActive: Bool? = nil,
        search: String? = nil,
        includeProject: Bool = true,
        includeAssignments: Bool = true,
        limit: Int = 50,
        offset: Int = 0
    ) -> AnyPublisher<ChefTasksResponse, APIError> {
        var endpoint = "/api/app/chef/tasks"
        var queryParams: [String] = []
        
        if let projectId = projectId {
            queryParams.append("project_id=\(projectId)")
        }
        
        if let supervisorId = supervisorId {
            queryParams.append("supervisor_id=\(supervisorId)")
        }
        
        if let isActive = isActive {
            queryParams.append("is_active=\(isActive)")
        }
        
        if let search = search, !search.isEmpty {
            queryParams.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        
        queryParams.append("limit=\(limit)")
        queryParams.append("offset=\(offset)")
        
        if includeProject {
            queryParams.append("include_project=true")
        }
        
        if includeAssignments {
            queryParams.append("include_assignments=true")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        #if DEBUG
        print("[ChefProjectsAPIService] Fetching tasks: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ChefTasksResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Create a new task for a project
    func createTask(projectId: Int, task: CreateTaskRequest) -> AnyPublisher<ProjectTask, APIError> {
        let endpoint = "/api/app/chef/projects/\(projectId)/tasks"
        
        #if DEBUG
        print("[ChefProjectsAPIService] Creating task for project \(projectId): \(task.title)")
        #endif
        
        // ✅ UŻYWA makeRequestWithRetry dla create operations
        return makeRequestWithRetry(endpoint: endpoint, method: "POST", body: task)
            .decode(type: ProjectTask.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Get detailed task information
    func fetchTaskDetail(taskId: Int) -> AnyPublisher<ChefTaskDetail, APIError> {
        let endpoint = "/api/app/chef/tasks/\(taskId)?include_project=true&include_assignments=true&include_workers=true&include_conversation=true"
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ChefTaskDetail.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Update task information
    func updateTask(id: Int, data: UpdateTaskRequest) -> AnyPublisher<ProjectTask, APIError> {
        let endpoint = "/api/app/chef/tasks/\(id)"
        
        #if DEBUG
        print("[ChefProjectsAPIService] Updating task ID: \(id)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "PATCH", body: data)
            .decode(type: ProjectTask.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Delete a task
    func deleteTask(id: Int) -> AnyPublisher<DeleteTaskResponse, APIError> {
        let endpoint = "/api/app/chef/tasks/\(id)"
        
        #if DEBUG
        print("[ChefProjectsAPIService] Deleting task ID: \(id)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: DeleteTaskResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Toggle task active status
    func toggleTaskStatus(id: Int, isActive: Bool) -> AnyPublisher<ProjectTask, APIError> {
        let endpoint = "/api/app/chef/tasks/\(id)/status"
        let request = UpdateTaskStatusRequest(isActive: isActive)
        
        return makeRequest(endpoint: endpoint, method: "PATCH", body: request)
            .decode(type: ProjectTask.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Task Assignments (✅ FIXED METHODS)
    
    /// Get available workers for task assignment
    func fetchAvailableWorkers(
        taskId: Int,
        date: Date? = nil,
        requiredCraneTypes: [Int]? = nil,
        includeAvailability: Bool = true
    ) -> AnyPublisher<AvailableWorkersResponse, APIError> {
        var endpoint = "/api/app/chef/tasks/\(taskId)/available-workers"
        var queryParams: [String] = []
        
        if let date = date {
            queryParams.append("date=\(DateFormatter.isoDate.string(from: date))")
        }
        
        if let craneTypes = requiredCraneTypes, !craneTypes.isEmpty {
            queryParams.append("crane_types=\(craneTypes.map(String.init).joined(separator: ","))")
        }
        
        if includeAvailability {
            queryParams.append("include_availability=true")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        #if DEBUG
        print("[ChefProjectsAPIService] Fetching available workers for task \(taskId)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: AvailableWorkersResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// ✅ FIXED: Assign workers to a task using correct endpoint
    func assignWorkersToTask(taskId: Int, assignments: [CreateTaskAssignmentRequest]) -> AnyPublisher<[TaskAssignment], APIError> {
        let endpoint = "/api/app/chef/task-assignments"  // ✅ FIXED: Correct endpoint
        let request = TaskAssignmentBulkRequest(task_id: taskId, assignments: assignments)  // ✅ FIXED: Correct request model
        
        #if DEBUG
        print("[ChefProjectsAPIService] Assigning \(assignments.count) workers to task \(taskId)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "POST", body: request)
            .decode(type: TaskAssignmentBulkResponse.self, decoder: jsonDecoder())  // ✅ FIXED: Decode bulk response
            .map { response in
                response.created_assignments  // ✅ FIXED: Extract assignments from response
            }
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// ✅ DISABLED: Update worker assignment (API doesn't support this)
    func updateTaskAssignment(assignmentId: Int, data: UpdateTaskAssignmentRequest) -> AnyPublisher<TaskAssignment, APIError> {
        #if DEBUG
        print("[ChefProjectsAPIService] ⚠️ Assignment update not supported by API. Assignment ID: \(assignmentId)")
        #endif
        
        // ✅ FIXED: API doesn't support assignment updates
        return Fail(error: APIError.serverError(501, "Assignment update not supported. Remove worker and assign again to change crane."))
            .eraseToAnyPublisher()
    }
    
    /// ✅ FIXED: Remove worker from task using correct endpoint
    func removeTaskAssignment(assignmentId: Int) -> AnyPublisher<DeleteAssignmentResponse, APIError> {
        let endpoint = "/api/app/chef/task-assignments?assignment_id=\(assignmentId)"  // ✅ FIXED: Correct endpoint
        
        #if DEBUG
        print("[ChefProjectsAPIService] Removing assignment ID: \(assignmentId)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: DeleteAssignmentResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Bulk update assignments for a task
    func bulkUpdateTaskAssignments(taskId: Int, updates: BulkAssignmentUpdateRequest) -> AnyPublisher<[TaskAssignment], APIError> {
        let endpoint = "/api/app/chef/tasks/\(taskId)/assignments/bulk-update"
        
        return makeRequest(endpoint: endpoint, method: "PUT", body: updates)
            .decode(type: [TaskAssignment].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Project Statistics & Analytics
    
    /// Get comprehensive project statistics
    func fetchProjectStatistics(projectId: Int, includeFinancial: Bool = false) -> AnyPublisher<ProjectStatistics, APIError> {
        var endpoint = "/api/app/chef/projects/\(projectId)/statistics"
        
        if includeFinancial {
            endpoint += "?include_financial=true"
        }
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ProjectStatistics.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Get project timeline with milestones
    func fetchProjectTimeline(projectId: Int) -> AnyPublisher<ProjectTimeline, APIError> {
        let endpoint = "/api/app/chef/projects/\(projectId)/timeline"
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ProjectTimeline.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Get worker allocation summary for a project
    func fetchProjectWorkerAllocation(projectId: Int) -> AnyPublisher<WorkerAllocationSummary, APIError> {
        let endpoint = "/api/app/chef/projects/\(projectId)/worker-allocation"
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: WorkerAllocationSummary.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Supervisors Management
    
    /// Get available supervisors (internal employees with appropriate roles)
    func fetchAvailableSupervisors(includeExternal: Bool = false) -> AnyPublisher<[Supervisor], APIError> {
        var endpoint = "/api/app/chef/supervisors"
        
        if includeExternal {
            endpoint += "?include_external=true"
        }
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [Supervisor].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Project Documents & Attachments
    
    /// Upload document/attachment to project
    func uploadProjectDocument(projectId: Int, document: Data, fileName: String, mimeType: String) -> AnyPublisher<ProjectDocument, APIError> {
        let endpoint = "/api/app/chef/projects/\(projectId)/documents"
        
        return uploadFile(
            endpoint: endpoint,
            method: "POST",
            fieldName: "document",
            fileName: fileName,
            fileData: document,
            mimeType: mimeType,
            additionalFields: Optional<String>.none
        )
        .decode(type: ProjectDocument.self, decoder: jsonDecoder())
        .mapError { ($0 as? APIError) ?? .decodingError($0) }
        .eraseToAnyPublisher()
    }
    
    /// Get project documents
    func fetchProjectDocuments(projectId: Int) -> AnyPublisher<[ProjectDocument], APIError> {
        let endpoint = "/api/app/chef/projects/\(projectId)/documents"
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [ProjectDocument].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Delete project document
    func deleteProjectDocument(documentId: Int) -> AnyPublisher<DeleteResponse, APIError> {
        let endpoint = "/api/app/chef/documents/\(documentId)"
        
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: DeleteResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Crane Equipment Management
    
    /// Get available crane models for assignment
    func fetchAvailableCraneModels(
        typeId: Int? = nil,
        brandId: Int? = nil,
        search: String? = nil
    ) -> AnyPublisher<[CraneModel], APIError> {
        var endpoint = "/api/app/chef/crane-models"
        var queryParams: [String] = []
        
        if let typeId = typeId {
            queryParams.append("type_id=\(typeId)")
        }
        
        if let brandId = brandId {
            queryParams.append("brand_id=\(brandId)")
        }
        
        if let search = search, !search.isEmpty {
            queryParams.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [CraneModel].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Bulk Operations
    
    /// Bulk create projects
    func bulkCreateProjects(_ projects: [CreateProjectRequest]) -> AnyPublisher<BulkCreateProjectsResponse, APIError> {
        let endpoint = "/api/app/chef/projects/bulk"
        let request = BulkCreateProjectsRequest(projects: projects)
        
        #if DEBUG
        print("[ChefProjectsAPIService] Bulk creating \(projects.count) projects")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "POST", body: request)
            .decode(type: BulkCreateProjectsResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Bulk update project statuses
    func bulkUpdateProjectStatuses(_ updates: [ProjectStatusUpdate]) -> AnyPublisher<BulkUpdateResponse, APIError> {
        let endpoint = "/api/app/chef/projects/bulk-status"
        let request = BulkProjectStatusUpdateRequest(updates: updates)
        
        return makeRequest(endpoint: endpoint, method: "PATCH", body: request)
            .decode(type: BulkUpdateResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Additional Request/Response Models

struct ChefProjectsResponse: Codable {
    let projects: [Project]
    let totalCount: Int
    let hasMore: Bool
    
    private enum CodingKeys: String, CodingKey {
        case projects
        case totalCount = "total_count"
        case hasMore = "has_more"
    }
}

struct ChefCreateProjectResponse: Codable {
    let project: Project
    let billingSettings: ChefBillingSettings?
    
    private enum CodingKeys: String, CodingKey {
        case project
        case billingSettings = "billing_settings"
    }
}

struct ChefProjectDetail: Codable {
    let project: Project
    let customer: Customer
    let billingSettings: [ChefBillingSettings]?
    let statistics: ProjectStatistics?
    let tasks: [ProjectTask]?
    
    private enum CodingKeys: String, CodingKey {
        case project
        case customer
        case billingSettings = "billing_settings"
        case statistics
        case tasks
    }
}

struct UpdateProjectRequest: Codable {
    let title: String?
    let description: String?
    let startDate: Date?
    let endDate: Date?
    let street: String?
    let city: String?
    let zip: String?
    let isActive: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case startDate = "start_date"
        case endDate = "end_date"
        case street
        case city
        case zip
        case isActive = "is_active"
    }
}

struct UpdateProjectStatusRequest: Codable {
    let status: String
    let notes: String?
}

struct DeleteProjectResponse: Codable {
    let success: Bool
    let message: String
    let affectedResources: AffectedResources?
    
    struct AffectedResources: Codable {
        let tasks: Int
        let assignments: Int
        let workEntries: Int
        
        private enum CodingKeys: String, CodingKey {
            case tasks
            case assignments
            case workEntries = "work_entries"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case affectedResources = "affected_resources"
    }
}

// ✅ FIXED: ChefBillingSettings with custom decoder for string-to-decimal conversion
struct ChefBillingSettings: Codable, Identifiable {
    let settingId: Int
    let projectId: Int
    let normalRate: Decimal
    let weekendRate: Decimal
    let overtimeRate1: Decimal
    let overtimeRate2: Decimal
    let weekendOvertimeRate1: Decimal
    let weekendOvertimeRate2: Decimal
    let effectiveFrom: Date
    let effectiveTo: Date?
    
    var id: Int { settingId }
    
    private enum CodingKeys: String, CodingKey {
        case settingId = "setting_id"
        case projectId = "project_id"
        case normalRate = "normal_rate"
        case weekendRate = "weekend_rate"
        case overtimeRate1 = "overtime_rate1"
        case overtimeRate2 = "overtime_rate2"
        case weekendOvertimeRate1 = "weekend_overtime_rate1"
        case weekendOvertimeRate2 = "weekend_overtime_rate2"
        case effectiveFrom = "effective_from"
        case effectiveTo = "effective_to"
    }
    
    // ✅ CUSTOM DECODER: Handles string rates from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        #if DEBUG
        print("🔄 [ChefBillingSettings] Decoding billing settings...")
        #endif
        
        settingId = try container.decode(Int.self, forKey: .settingId)
        projectId = try container.decode(Int.self, forKey: .projectId)
        effectiveFrom = try container.decode(Date.self, forKey: .effectiveFrom)
        effectiveTo = try container.decodeIfPresent(Date.self, forKey: .effectiveTo)
        
        // ✅ CONVERT STRINGS TO DECIMALS
        normalRate = try Self.decodeRate(container, forKey: .normalRate)
        weekendRate = try Self.decodeRate(container, forKey: .weekendRate)
        overtimeRate1 = try Self.decodeRate(container, forKey: .overtimeRate1)
        overtimeRate2 = try Self.decodeRate(container, forKey: .overtimeRate2)
        weekendOvertimeRate1 = try Self.decodeRate(container, forKey: .weekendOvertimeRate1)
        weekendOvertimeRate2 = try Self.decodeRate(container, forKey: .weekendOvertimeRate2)
        
        #if DEBUG
        print("✅ [ChefBillingSettings] Successfully decoded setting \(settingId)")
        print("   - Normal rate: \(normalRate)")
        print("   - Weekend rate: \(weekendRate)")
        #endif
    }
    
    // ✅ HELPER: Decode rate from string or number
    private static func decodeRate<K: CodingKey>(_ container: KeyedDecodingContainer<K>, forKey key: K) throws -> Decimal {
        // Try string first (API sends strings)
        if let string = try? container.decode(String.self, forKey: key) {
            if let decimal = Decimal(string: string) {
                #if DEBUG
                print("   - \(key.stringValue): '\(string)' -> \(decimal)")
                #endif
                return decimal
            } else if string.isEmpty {
                #if DEBUG
                print("   - \(key.stringValue): empty string -> 0")
                #endif
                return 0
            }
        }
        
        // Try number types
        if let decimal = try? container.decode(Decimal.self, forKey: key) {
            #if DEBUG
            print("   - \(key.stringValue): \(decimal) (as Decimal)")
            #endif
            return decimal
        }
        
        if let double = try? container.decode(Double.self, forKey: key) {
            let decimal = Decimal(double)
            #if DEBUG
            print("   - \(key.stringValue): \(double) (as Double) -> \(decimal)")
            #endif
            return decimal
        }
        
        // Default to 0 if all fails
        #if DEBUG
        print("   - \(key.stringValue): failed to decode, defaulting to 0")
        #endif
        return 0
    }
    
    // ✅ STANDARD ENCODER: Always encode as numbers
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(settingId, forKey: .settingId)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(normalRate, forKey: .normalRate)
        try container.encode(weekendRate, forKey: .weekendRate)
        try container.encode(overtimeRate1, forKey: .overtimeRate1)
        try container.encode(overtimeRate2, forKey: .overtimeRate2)
        try container.encode(weekendOvertimeRate1, forKey: .weekendOvertimeRate1)
        try container.encode(weekendOvertimeRate2, forKey: .weekendOvertimeRate2)
        try container.encode(effectiveFrom, forKey: .effectiveFrom)
        try container.encodeIfPresent(effectiveTo, forKey: .effectiveTo)
    }
}

struct ChefTasksResponse: Codable {
    let tasks: [ProjectTask]
    let totalCount: Int
    let hasMore: Bool
    
    private enum CodingKeys: String, CodingKey {
        case tasks
        case totalCount = "total_count"
        case hasMore = "has_more"
    }
}

struct ChefTaskDetail: Codable {
    let task: ProjectTask
    let project: Project
    let assignments: [TaskAssignmentDetail]
    let conversation: ConversationInfo?
}

struct TaskAssignmentDetail: Codable {
    let assignment: TaskAssignment
    let employee: Employee
    let craneModel: CraneModel?
    let availability: WorkerAvailability?
    
    private enum CodingKeys: String, CodingKey {
        case assignment
        case employee
        case craneModel = "crane_model"
        case availability
    }
}

struct UpdateTaskRequest: Codable {
    let title: String?
    let description: String?
    let deadline: Date?
    let supervisorId: Int?
    let supervisorName: String?
    let supervisorEmail: String?
    let supervisorPhone: String?
    let isActive: Bool?
    
    // Management Calendar Fields
    let startDate: Date?
    let status: String?  // Use raw value
    let priority: String?  // Use raw value
    let estimatedHours: Double?
    let requiredOperators: Int?
    let clientEquipmentInfo: String?
    
    // Equipment Fields
    let requiredCraneTypes: [Int]?
    let preferredCraneModelId: Int?
    let equipmentCategoryId: Int?
    let equipmentBrandId: Int?
    
    // Certificate Fields
    let requiredCertificates: [Int]?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case deadline
        case supervisorId = "supervisor_id"
        case supervisorName = "supervisor_name"
        case supervisorEmail = "supervisor_email"
        case supervisorPhone = "supervisor_phone"
        case isActive = "is_active"
        
        // Management Calendar Fields
        case startDate = "start_date"
        case status
        case priority
        case estimatedHours = "estimated_hours"
        case requiredOperators = "required_operators"
        case clientEquipmentInfo = "client_equipment_info"
        
        // Equipment Fields
        case requiredCraneTypes = "required_crane_types"
        case preferredCraneModelId = "preferred_crane_model_id"
        case equipmentCategoryId = "equipment_category_id"
        case equipmentBrandId = "equipment_brand_id"
        
        // Certificate Fields
        case requiredCertificates = "required_certificates"
    }
}

struct UpdateTaskStatusRequest: Codable {
    let isActive: Bool
    
    private enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
    }
}

struct DeleteTaskResponse: Codable {
    let success: Bool
    let message: String
    let reassignedWorkers: Int?
    
    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case reassignedWorkers = "reassigned_workers"
    }
}

struct AvailableWorkersResponse: Codable {
    let workers: [AvailableWorker]
    let totalAvailable: Int
    let totalWithConflicts: Int
    
    private enum CodingKeys: String, CodingKey {
        case workers
        case totalAvailable = "total_available"
        case totalWithConflicts = "total_with_conflicts"
    }
}

struct AvailableWorker: Codable, Identifiable {
    let employee: Employee
    let availability: WorkerAvailability
    let craneTypes: [CraneType]
    let certificates: [TaskWorkerCertificate]?
    let hasRequiredCertificates: Bool?
    let certificateValidation: CertificateValidation?
    
    var id: Int { employee.id }
    
    private enum CodingKeys: String, CodingKey {
        case employee
        case availability
        case craneTypes = "crane_types"
        case certificates
        case hasRequiredCertificates = "has_required_certificates"
        case certificateValidation = "certificate_validation"
    }
}

struct TaskWorkerCertificate: Codable {
    let skillId: Int
    let certificateTypeId: Int?
    let certificateType: CertificateTypeInfo?
    let skillName: String?
    let skillLevel: String?
    let isCertified: Bool
    let certificationExpires: Date?
    let yearsExperience: Int?
    let isExpired: Bool?
    let daysUntilExpiry: Int?
    let urgency: String?
    
    private enum CodingKeys: String, CodingKey {
        case skillId = "skill_id"
        case certificateTypeId = "certificate_type_id"
        case certificateType = "certificate_type"
        case skillName = "skill_name"
        case skillLevel = "skill_level"
        case isCertified = "is_certified"
        case certificationExpires = "certification_expires"
        case yearsExperience = "years_experience"
        case isExpired = "is_expired"
        case daysUntilExpiry = "days_until_expiry"
        case urgency
    }
}

struct CertificateTypeInfo: Codable {
    let code: String
    let nameEn: String
    let nameDa: String
    
    private enum CodingKeys: String, CodingKey {
        case code
        case nameEn = "name_en"
        case nameDa = "name_da"
    }
}

struct CertificateValidation: Codable {
    let requiredCount: Int
    let validCount: Int
    let missingCertificates: [Int]
    let expiredCertificates: [Int]
    
    private enum CodingKeys: String, CodingKey {
        case requiredCount = "required_count"
        case validCount = "valid_count"
        case missingCertificates = "missing_certificates"
        case expiredCertificates = "expired_certificates"
    }
}

struct WorkerAvailability: Codable {
    let isAvailable: Bool
    let conflictingTasks: [TaskConflict]?
    let workHoursThisWeek: Double
    let workHoursThisMonth: Double
    let maxWeeklyHours: Double
    let nextAvailableDate: Date?
    
    private enum CodingKeys: String, CodingKey {
        case isAvailable = "is_available"
        case conflictingTasks = "conflicting_tasks"
        case workHoursThisWeek = "work_hours_this_week"
        case workHoursThisMonth = "work_hours_this_month"
        case maxWeeklyHours = "max_weekly_hours"
        case nextAvailableDate = "next_available_date"
    }
}

struct TaskConflict: Codable {
    let taskId: Int
    let taskTitle: String
    let projectTitle: String
    let conflictDates: [Date]
    
    private enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case taskTitle = "task_title"
        case projectTitle = "project_title"
        case conflictDates = "conflict_dates"
    }
}

struct CreateTaskAssignmentRequest: Codable {
    let employeeId: Int
    let craneModelId: Int?
    let skipCertificateValidation: Bool?
    let skipCraneTypeValidation: Bool?
    let workDate: Date?
    let status: String?
    let notes: String?
    
    private enum CodingKeys: String, CodingKey {
        case employeeId = "employee_id"
        case craneModelId = "crane_model_id"
        case skipCertificateValidation = "skip_certificate_validation"
        case skipCraneTypeValidation = "skip_crane_type_validation"
        case workDate = "work_date"
        case status
        case notes
    }
}

// ✅ NEW: Fixed bulk assignment models
struct TaskAssignmentBulkRequest: Codable {
    let task_id: Int
    let assignments: [CreateTaskAssignmentRequest]
}

struct TaskAssignmentBulkResponse: Codable {
    let success: Bool
    let message: String
    let created_assignments: [TaskAssignment]
    let errors: [String]
}

struct BulkTaskAssignmentRequest: Codable {
    let assignments: [CreateTaskAssignmentRequest]
}

struct UpdateTaskAssignmentRequest: Codable {
    let craneModelId: Int?
    
    private enum CodingKeys: String, CodingKey {
        case craneModelId = "crane_model_id"
    }
}

struct BulkAssignmentUpdateRequest: Codable {
    let addAssignments: [CreateTaskAssignmentRequest]?
    let removeAssignmentIds: [Int]?
    let updateAssignments: [AssignmentUpdate]?
    
    struct AssignmentUpdate: Codable {
        let assignmentId: Int
        let craneModelId: Int?
        
        private enum CodingKeys: String, CodingKey {
            case assignmentId = "assignment_id"
            case craneModelId = "crane_model_id"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case addAssignments = "add_assignments"
        case removeAssignmentIds = "remove_assignment_ids"
        case updateAssignments = "update_assignments"
    }
}

struct DeleteAssignmentResponse: Codable {
    let success: Bool
    let message: String
    let employeeName: String?
    
    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case employeeName = "employee_name"
    }
}

struct ProjectStatistics: Codable {
    let projectId: Int
    let totalTasks: Int
    let completedTasks: Int
    let activeTasks: Int
    let totalWorkers: Int
    let activeWorkers: Int
    let totalHoursWorked: Double
    let totalHoursPlanned: Double
    let estimatedCompletion: Double
    let budgetUtilization: Double?
    let tasksByStatus: [String: Int]
    let upcomingDeadlines: [UpcomingDeadline]
    let workerUtilization: Double
    let averageTaskCompletionTime: Double?
    let delayedTasks: Int
    
    struct UpcomingDeadline: Codable {
        let task: ProjectTask
        let daysUntilDeadline: Int
        let isOverdue: Bool
        
        private enum CodingKeys: String, CodingKey {
            case task
            case daysUntilDeadline = "days_until_deadline"
            case isOverdue = "is_overdue"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case totalTasks = "total_tasks"
        case completedTasks = "completed_tasks"
        case activeTasks = "active_tasks"
        case totalWorkers = "total_workers"
        case activeWorkers = "active_workers"
        case totalHoursWorked = "total_hours_worked"
        case totalHoursPlanned = "total_hours_planned"
        case estimatedCompletion = "estimated_completion"
        case budgetUtilization = "budget_utilization"
        case tasksByStatus = "tasks_by_status"
        case upcomingDeadlines = "upcoming_deadlines"
        case workerUtilization = "worker_utilization"
        case averageTaskCompletionTime = "average_task_completion_time"
        case delayedTasks = "delayed_tasks"
    }
}

struct ProjectTimeline: Codable {
    let projectId: Int
    let milestones: [Milestone]
    let criticalPath: [ProjectTask]
    let estimatedEndDate: Date
    let currentProgress: Double
    
    struct Milestone: Codable {
        let id: Int
        let title: String
        let date: Date
        let isCompleted: Bool
        let completedDate: Date?
        let associatedTasks: [Int]
        
        private enum CodingKeys: String, CodingKey {
            case id
            case title
            case date
            case isCompleted = "is_completed"
            case completedDate = "completed_date"
            case associatedTasks = "associated_tasks"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case milestones
        case criticalPath = "critical_path"
        case estimatedEndDate = "estimated_end_date"
        case currentProgress = "current_progress"
    }
}

struct WorkerAllocationSummary: Codable {
    let projectId: Int
    let totalAllocatedWorkers: Int
    let workersByRole: [String: Int]
    let workersByCraneType: [String: Int]
    let utilizationByWorker: [WorkerUtilization]
    let peakDemandDates: [PeakDemand]
    
    struct WorkerUtilization: Codable {
        let employee: Employee
        let allocatedHours: Double
        let workedHours: Double
        let utilizationPercentage: Double
        
        private enum CodingKeys: String, CodingKey {
            case employee
            case allocatedHours = "allocated_hours"
            case workedHours = "worked_hours"
            case utilizationPercentage = "utilization_percentage"
        }
    }
    
    struct PeakDemand: Codable {
        let date: Date
        let requiredWorkers: Int
        let assignedWorkers: Int
        let shortage: Int
        
        private enum CodingKeys: String, CodingKey {
            case date
            case requiredWorkers = "required_workers"
            case assignedWorkers = "assigned_workers"
            case shortage
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case totalAllocatedWorkers = "total_allocated_workers"
        case workersByRole = "workers_by_role"
        case workersByCraneType = "workers_by_crane_type"
        case utilizationByWorker = "utilization_by_worker"
        case peakDemandDates = "peak_demand_dates"
    }
}

struct Supervisor: Codable {
    let employee: Employee?
    let externalSupervisor: ExternalSupervisor?
    let activeTasksCount: Int
    let isAvailable: Bool
    
    struct ExternalSupervisor: Codable {
        let id: Int
        let name: String
        let email: String
        let phone: String
        let company: String?
    }
    
    private enum CodingKeys: String, CodingKey {
        case employee
        case externalSupervisor = "external_supervisor"
        case activeTasksCount = "active_tasks_count"
        case isAvailable = "is_available"
    }
}

struct ProjectDocument: Codable {
    let id: Int
    let projectId: Int
    let fileName: String
    let fileUrl: String
    let fileSize: Int
    let mimeType: String
    let uploadedBy: String
    let uploadedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case fileName = "file_name"
        case fileUrl = "file_url"
        case fileSize = "file_size"
        case mimeType = "mime_type"
        case uploadedBy = "uploaded_by"
        case uploadedAt = "uploaded_at"
    }
}

struct BulkCreateProjectsRequest: Codable {
    let projects: [CreateProjectRequest]
}

struct BulkCreateProjectsResponse: Codable {
    let created: [Project]
    let failed: [FailedProject]?
    
    struct FailedProject: Codable {
        let index: Int
        let error: String
    }
}

struct ProjectStatusUpdate: Codable {
    let projectId: Int
    let status: String
    let notes: String?
    
    private enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case status
        case notes
    }
}

struct BulkProjectStatusUpdateRequest: Codable {
    let updates: [ProjectStatusUpdate]
}

struct BulkUpdateResponse: Codable {
    let updated: Int
    let failed: Int
    let errors: [String]?
}

struct DeleteResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Error Extension

extension ChefProjectsAPIService {
    enum ProjectError: LocalizedError {
        case projectNotFound
        case taskNotFound
        case workerNotAvailable
        case invalidDateRange
        case duplicateAssignment
        case insufficientPermissions
        
        var errorDescription: String? {
            switch self {
            case .projectNotFound:
                return "Project not found"
            case .taskNotFound:
                return "Task not found"
            case .workerNotAvailable:
                return "Worker is not available for this assignment"
            case .invalidDateRange:
                return "Invalid date range specified"
            case .duplicateAssignment:
                return "Worker is already assigned to this task"
            case .insufficientPermissions:
                return "You don't have permission to perform this action"
            }
        }
    }
}
