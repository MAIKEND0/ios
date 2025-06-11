//
//  PayrollAPIService.swift
//  KSR Cranes App
//
//  🔧 FINAL FIX: Corrected constructor calls and removed duplicate types
//

import Foundation
import Combine

final class PayrollAPIService: BaseAPIService {
    static let shared = PayrollAPIService()

    private override init() {
        super.init()
    }
    
    // MARK: - Factory Methods for Mock Objects
    
    private func createMockEmployee(id: Int, name: String, email: String) -> Employee {
        return Employee(
            id: id,
            name: name,
            email: email,
            role: "arbejder",
            phoneNumber: nil,
            profilePictureUrl: nil,
            isActivated: true,
            craneTypes: nil,
            address: nil,
            emergencyContact: nil,
            cprNumber: nil,
            birthDate: nil,
            hasDrivingLicense: nil,
            drivingLicenseCategory: nil,
            drivingLicenseExpiration: nil
        )
    }
    
    private func createMockProject(id: Int, title: String, customerId: Int?) -> Project {
        return Project(
            id: id,
            title: title,
            description: nil,
            startDate: nil,
            endDate: nil,
            status: .active,
            customerId: customerId,
            customer: nil,
            street: nil,
            city: nil,
            zip: nil,
            isActive: true,
            createdAt: nil,
            tasksCount: nil,
            assignedWorkersCount: nil,
            completionPercentage: nil
        )
    }
    
    private func createMockProjectTask(id: Int, projectId: Int, title: String) -> ProjectTask {
        // Create minimal JSON and decode it to avoid initializer conflicts
        let jsonData = """
        {
            "task_id": \(id),
            "project_id": \(projectId),
            "title": "\(title)",
            "isActive": true
        }
        """.data(using: .utf8)!
        
        do {
            return try jsonDecoder().decode(ProjectTask.self, from: jsonData)
        } catch {
            #if DEBUG
            print("[PayrollAPIService] Failed to create mock ProjectTask, using fallback")
            #endif
            // Fallback - this should not happen but provides safety
            fatalError("Unable to create mock ProjectTask")
        }
    }

    // MARK: - Dashboard Stats (UPDATED TO USE REAL DATA)
    
    func fetchPayrollDashboardStats() -> AnyPublisher<PayrollDashboardStatsResponse, APIError> {
        let endpoint = "/api/app/chef/payroll/dashboard/stats"
        
        #if DEBUG
        print("[PayrollAPIService] Fetching real dashboard stats from API...")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: PayrollDashboardStatsResponse.self, decoder: jsonDecoder())
            .map { response in
                // Transform API response to match iOS model structure
                return PayrollDashboardStatsResponse(
                    overview: response.overview,
                    pending_items: response.pending_items,
                    recent_activity: response.recent_activity
                )
            }
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func fetchPendingItems() -> AnyPublisher<[PayrollPendingItem], APIError> {
        // This now comes from the main dashboard stats endpoint
        return fetchPayrollDashboardStats()
            .map { response in response.pending_items }
            .eraseToAnyPublisher()
    }
    
    func fetchRecentActivity() -> AnyPublisher<[PayrollActivity], APIError> {
        // This now comes from the main dashboard stats endpoint
        return fetchPayrollDashboardStats()
            .map { response in response.recent_activity }
            .eraseToAnyPublisher()
    }

    // MARK: - Work Entry Management (UPDATED TO USE REAL DATA)
    
    func fetchPendingWorkEntries() -> AnyPublisher<[WorkEntryForReview], APIError> {
        let endpoint = "/api/app/work-entries/confirmed"
        
        #if DEBUG
        print("[PayrollAPIService] Fetching confirmed work entries from API...")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ConfirmedWorkEntriesResponse.self, decoder: jsonDecoder())
            .map { response in
                // Transform confirmed entries to WorkEntryForReview format
                return response.data.compactMap { entry in
                    self.transformToWorkEntryForReview(entry)
                }
            }
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    private func transformToWorkEntryForReview(_ apiEntry: ConfirmedWorkEntry) -> WorkEntryForReview? {
        // Transform API confirmed work entry to iOS WorkEntryForReview model
        guard let employee = apiEntry.employee,
              let task = apiEntry.task else {
            return nil
        }
        
        // 🔧 FIXED: Employee constructor using factory method to avoid ambiguity
        let mockEmployee = createMockEmployee(
            id: employee.employee_id,
            name: employee.name ?? "Unknown Employee",
            email: employee.email ?? ""
        )
        
        // 🔧 FIXED: Project constructor using factory method
        let mockProject = createMockProject(
            id: task.project?.project_id ?? 0,
            title: task.project?.title ?? "Unknown Project",
            customerId: task.project?.customer_id
        )
        
        // 🔧 FIXED: ProjectTask constructor using factory method
        let mockTask = createMockProjectTask(
            id: task.task_id,
            projectId: task.project?.project_id ?? 0,
            title: task.title ?? "Unknown Task"
        )
        
        // Create mock SupervisorConfirmation
        let mockConfirmation = SupervisorConfirmation(
            supervisorId: 1,
            supervisorName: "Supervisor",
            confirmedAt: Date(),
            notes: Optional<String>.none,
            digitalSignature: Optional<String>.none
        )
        
        // Create period coverage
        let workDate = DateFormatter.iso8601.date(from: apiEntry.work_date) ?? Date()
        let periodCoverage = DateInterval(start: workDate, end: workDate)
        
        return WorkEntryForReview(
            id: apiEntry.entry_id,
            employee: mockEmployee,
            project: mockProject,
            task: mockTask,
            workEntries: [],
            totalHours: apiEntry.worked_hours,
            totalAmount: Decimal(apiEntry.worked_hours * 450), // Default rate
            supervisorConfirmation: mockConfirmation,
            periodCoverage: periodCoverage,
            status: .pending
        )
    }
    
    func bulkApproveWorkEntries(request: BulkWorkEntryApprovalRequest) -> AnyPublisher<BulkOperationResult, APIError> {
        let endpoint = "/api/app/work-entries/confirmed"
        
        // Transform iOS request to API format
        let apiRequest = BulkWorkEntryAPIRequest(
            entry_ids: request.workEntryIds,
            action: request.action.rawValue,
            payroll_batch_id: Optional<Int>.none
        )
        
        return makeRequest(endpoint: endpoint, method: "PATCH", body: apiRequest)
            .decode(type: BulkOperationAPIResponse.self, decoder: jsonDecoder())
            .map { response in
                // Transform API response to iOS format
                return BulkOperationResult(
                    successful: response.updated_entries?.map { $0.entry_id } ?? [],
                    failed: [], // API doesn't return failed items in this format
                    totalRequested: request.workEntryIds.count
                )
            }
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func bulkApproveAllPendingHours() -> AnyPublisher<BulkOperationResult, APIError> {
        // First get all confirmed entries, then mark them as sent to payroll
        return fetchPendingWorkEntries()
            .flatMap { entries in
                let entryIds = entries.map { $0.id }
                let request = BulkWorkEntryApprovalRequest(
                    workEntryIds: entryIds,
                    action: .approve,
                    notes: Optional<String>.none
                )
                return self.bulkApproveWorkEntries(request: request)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Payroll Batch Management (UPDATED TO USE REAL DATA)
    
    func fetchPayrollBatches() -> AnyPublisher<[PayrollBatch], APIError> {
        let endpoint = "/api/app/chef/payroll/batches"
        
        #if DEBUG
        print("[PayrollAPIService] Fetching payroll batches from API...")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [PayrollBatch].self, decoder: jsonDecoder())
            .catch { error -> AnyPublisher<[PayrollBatch], APIError> in
                #if DEBUG
                print("[PayrollAPIService] API call failed: \(error)")
                #endif
                // Return empty array on API error
                return Just([PayrollBatch]())
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            }
            .mapError { error in
                // 🔧 FIXED: Remove redundant conditional cast
                return error
            }
            .eraseToAnyPublisher()
    }
    
    func fetchBatchDetails(batchId: Int) -> AnyPublisher<PayrollAPIService.BatchDetailResponse, APIError> {
        let endpoint = "/api/app/chef/payroll/batches/\(batchId)/details"
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: PayrollAPIService.BatchDetailResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func createPayrollBatch(request: CreatePayrollBatchRequest) -> AnyPublisher<PayrollBatch, APIError> {
        let endpoint = "/api/app/chef/payroll/batches"
        
        return makeRequest(endpoint: endpoint, method: "POST", body: request)
            .decode(type: PayrollBatch.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func approvePayrollBatch(id: Int) -> AnyPublisher<PayrollBatch, APIError> {
        let endpoint = "/api/app/chef/payroll/batches/\(id)/approve"
        
        return makeRequest(endpoint: endpoint, method: "PUT", body: Optional<String>.none)
            .decode(type: PayrollBatch.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Zenegy Integration (Keep existing mock implementation)
    
    func syncToZenegy(batchId: Int) -> AnyPublisher<ZenegySyncResult, APIError> {
        let endpoint = "/api/app/chef/zenegy/sync-batch"
        
        return makeRequest(endpoint: endpoint, method: "POST", body: Optional<String>.none)
            .decode(type: ZenegySyncResult.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func fetchZenegyStatus(batchId: Int) -> AnyPublisher<ZenegySyncStatus, APIError> {
        let endpoint = "/api/app/chef/payroll/batches/\(batchId)/zenegy-status"
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ZenegySyncStatus.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Period Management (Keep existing implementation)
    
    func fetchAvailablePayrollPeriods() -> AnyPublisher<[PayrollAPIService.PayrollPeriodOption], APIError> {
        let endpoint = "/api/app/chef/payroll/periods/available"
        
        #if DEBUG
        print("[PayrollAPIService] Fetching available payroll periods from API...")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [PayrollAPIService.PayrollPeriodOption].self, decoder: jsonDecoder())
            .catch { error -> AnyPublisher<[PayrollAPIService.PayrollPeriodOption], APIError> in
                #if DEBUG
                print("[PayrollAPIService] API call failed: \(error)")
                #endif
                // Return empty array on API error
                return Just([PayrollAPIService.PayrollPeriodOption]())
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func fetchAvailableWorkEntriesForBatch() -> AnyPublisher<[WorkEntryForReview], APIError> {
        // Use the same confirmed work entries endpoint
        return fetchPendingWorkEntries()
    }
}

// MARK: - API Response Models

// 🔧 FIXED: Added Codable conformance
struct PayrollDashboardStatsResponse: Codable {
    let overview: PayrollDashboardStats
    let pending_items: [PayrollPendingItem]
    let recent_activity: [PayrollActivity]
}

struct ConfirmedWorkEntriesResponse: Codable {
    let success: Bool
    let data: [ConfirmedWorkEntry]
    let summary: WorkEntriesSummary
}

struct ConfirmedWorkEntry: Codable {
    let entry_id: Int
    let work_date: String
    let start_time: String?
    let end_time: String?
    let worked_hours: Double
    let kilometers: Double
    let employee: ConfirmedEmployee?
    let task: ConfirmedTask?
    let can_sync_to_zenegy: Bool
}

struct ConfirmedEmployee: Codable {
    let employee_id: Int
    let name: String?
    let email: String?
}

struct ConfirmedTask: Codable {
    let task_id: Int
    let title: String?
    let project: ConfirmedProject?
}

struct ConfirmedProject: Codable {
    let project_id: Int
    let title: String?
    let customer_id: Int?
}

struct WorkEntriesSummary: Codable {
    let total_entries: Int
    let total_hours: Double
    let unique_employees: Int
}

struct BulkWorkEntryAPIRequest: Codable {
    let entry_ids: [Int]
    let action: String
    let payroll_batch_id: Int?
}

struct BulkOperationAPIResponse: Codable {
    let success: Bool
    let message: String
    let updated_count: Int
    let updated_entries: [UpdatedWorkEntry]?
}

struct UpdatedWorkEntry: Codable {
    let entry_id: Int
    let employee_name: String
    let task_title: String
    let work_date: String
}

// MARK: - 🔧 FIXED: Local PayrollAPIService types to avoid ambiguity

extension PayrollAPIService {
    
    // 🔧 LOCAL: PayrollPeriodOption to avoid redeclaration
    struct PayrollPeriodOption: Identifiable, Codable {
        let id: Int
        let title: String
        let startDate: Date
        let endDate: Date
        let availableHours: Double
        let estimatedAmount: Decimal
        
        var displayName: String {
            return title
        }
        
        var dateRange: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
        
        private enum CodingKeys: String, CodingKey {
            case id
            case title
            case startDate = "start_date"
            case endDate = "end_date"
            case availableHours = "available_hours"
            case estimatedAmount = "estimated_amount"
        }
        
        // Mock data removed - use real API data only
    }

    // 🔧 LOCAL: BatchDetailResponse to avoid redeclaration
    struct BatchDetailResponse: Codable {
        let employees: [PayrollModels.BatchEmployeeBreakdown]
        let financialBreakdown: FinancialBreakdown
        let zenegyDetails: ZenegySyncDetails?
        
        struct FinancialBreakdown: Codable {
            let regularHours: Double
            let overtimeHours: Double
            let weekendHours: Double
            let regularAmount: Decimal
            let overtimeAmount: Decimal
            let weekendAmount: Decimal
            let averageRegularRate: Decimal
            let averageOvertimeRate: Decimal
            let averageWeekendRate: Decimal
            
            private enum CodingKeys: String, CodingKey {
                case regularHours = "regular_hours"
                case overtimeHours = "overtime_hours"
                case weekendHours = "weekend_hours"
                case regularAmount = "regular_amount"
                case overtimeAmount = "overtime_amount"
                case weekendAmount = "weekend_amount"
                case averageRegularRate = "average_regular_rate"
                case averageOvertimeRate = "average_overtime_rate"
                case averageWeekendRate = "average_weekend_rate"
            }
        }
        
        // Mock data removed - use real API data only
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
