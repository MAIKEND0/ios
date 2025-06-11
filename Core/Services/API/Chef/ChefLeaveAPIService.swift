//
//  ChefLeaveAPIService.swift
//  KSR Cranes App
//
//  Chef Leave Management API Service  
//  Handles leave approval, team management, and analytics for chef/manager roles
//

import Foundation
import Combine

final class ChefLeaveAPIService: BaseAPIService {
    static let shared = ChefLeaveAPIService()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Leave Requests Management
    
    /// Fetches all team leave requests with filtering options
    func fetchTeamLeaveRequests(
        params: LeaveQueryParams = LeaveQueryParams()
    ) -> AnyPublisher<LeaveRequestsResponse, APIError> {
        var endpoint = "/api/app/chef/leave/requests"
        let queryItems = params.toQueryItems()
        
        if !queryItems.isEmpty {
            let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            endpoint += "?\(queryString)"
        }
        
        // Add cache buster
        let separator = endpoint.contains("?") ? "&" : "?"
        endpoint += "\(separator)cacheBust=\(Int(Date().timeIntervalSince1970))"
        
        #if DEBUG
        print("[ChefLeaveAPIService] Fetching team leave requests: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .tryMap { data in
                // Handle server response format that may not have 'total' field
                struct ServerResponse: Codable {
                    let requests: [LeaveRequest]
                    let total: Int?
                    let page: Int?
                    let limit: Int?
                    let has_more: Bool?
                }
                
                let serverResponse = try JSONDecoder().decode(ServerResponse.self, from: data)
                
                #if DEBUG
                print("[ChefLeaveAPIService] Decoded \(serverResponse.requests.count) leave requests")
                let requestsWithoutEmployeeData = serverResponse.requests.filter { $0.employee == nil }
                if !requestsWithoutEmployeeData.isEmpty {
                    print("[ChefLeaveAPIService] WARNING: \(requestsWithoutEmployeeData.count) requests missing employee data:")
                    for request in requestsWithoutEmployeeData {
                        print("  - Request #\(request.id) for employee_id \(request.employee_id)")
                    }
                }
                #endif
                
                return LeaveRequestsResponse(
                    requests: serverResponse.requests,
                    total: serverResponse.total ?? serverResponse.requests.count,
                    page: serverResponse.page ?? 1,
                    limit: serverResponse.limit ?? serverResponse.requests.count,
                    has_more: serverResponse.has_more ?? false
                )
            }
            .mapError { error in
                #if DEBUG
                print("[ChefLeaveAPIService] Fetch team leave requests error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Fetches pending leave requests that need approval
    func fetchPendingApprovals() -> AnyPublisher<LeaveRequestsResponse, APIError> {
        let params = LeaveQueryParams(
            status: .pending,
            page: 1,
            limit: 100,
            include_employee: true,
            include_approver: true
        )
        
        return fetchTeamLeaveRequests(params: params)
    }
    
    /// Approves or rejects a leave request
    func approveOrRejectLeaveRequest(
        id: Int,
        action: ApproveRejectLeaveRequest.LeaveAction,
        rejectionReason: String? = nil
    ) -> AnyPublisher<ApproveRejectLeaveResponse, APIError> {
        let endpoint = "/api/app/chef/leave/requests"
        
        // Get current user's employee ID as approver
        guard let approverIdString = AuthService.shared.getEmployeeId(),
              let approverId = Int(approverIdString) else {
            return Fail(error: APIError.serverError(400, "Unable to identify approver"))
                .eraseToAnyPublisher()
        }
        
        let request = ChefApproveRejectLeaveRequest(
            id: id,
            action: action,
            approver_id: approverId,
            rejection_reason: rejectionReason
        )
        
        #if DEBUG
        print("[ChefLeaveAPIService] \(action.rawValue.capitalized) leave request \(id)")
        #endif
        
        return makeRequestWithRetry(endpoint: endpoint, method: "PUT", body: request)
            .decode(type: ApproveRejectLeaveResponse.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[ChefLeaveAPIService] Approve/reject leave request error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Bulk approve multiple leave requests
    func bulkApproveLeaveRequests(ids: [Int]) -> AnyPublisher<BulkLeaveActionResponse, APIError> {
        let endpoint = "/api/app/chef/leave/requests/bulk-approve"
        let request = BulkLeaveActionRequest(request_ids: ids)
        
        #if DEBUG
        print("[ChefLeaveAPIService] Bulk approving \(ids.count) leave requests")
        #endif
        
        return makeRequestWithRetry(endpoint: endpoint, method: "POST", body: request)
            .decode(type: BulkLeaveActionResponse.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[ChefLeaveAPIService] Bulk approve error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Team Calendar & Availability
    
    /// Fetches team leave calendar for a date range
    func fetchTeamLeaveCalendar(
        startDate: Date,
        endDate: Date
    ) -> AnyPublisher<[TeamLeaveCalendar], APIError> {
        let dateFormatter = DateFormatter.iso8601DateOnly
        let params = [
            "start_date": dateFormatter.string(from: startDate),
            "end_date": dateFormatter.string(from: endDate)
        ]
        
        let queryString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let endpoint = "/api/app/chef/leave/calendar?\(queryString)&cacheBust=\(Int(Date().timeIntervalSince1970))"
        
        #if DEBUG
        print("[ChefLeaveAPIService] Fetching team calendar: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [TeamLeaveCalendar].self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[ChefLeaveAPIService] Fetch team calendar error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Checks team availability for a specific date range
    func checkTeamAvailability(
        startDate: Date,
        endDate: Date,
        requiredEmployees: Int? = nil
    ) -> AnyPublisher<TeamAvailabilityResponse, APIError> {
        let dateFormatter = DateFormatter.iso8601DateOnly
        var params = [
            "start_date": dateFormatter.string(from: startDate),
            "end_date": dateFormatter.string(from: endDate)
        ]
        
        if let requiredEmployees = requiredEmployees {
            params["required_employees"] = String(requiredEmployees)
        }
        
        let queryString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let endpoint = "/api/app/chef/leave/availability?\(queryString)"
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: TeamAvailabilityResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Leave Balance Management
    
    /// Fetches leave balances for all team members
    func fetchTeamLeaveBalances(year: Int? = nil) -> AnyPublisher<[EmployeeLeaveBalance], APIError> {
        var endpoint = "/api/app/chef/leave/balance"
        
        if let year = year {
            endpoint += "?year=\(year)"
        }
        
        // Add cache buster
        let separator = endpoint.contains("?") ? "&" : "?"
        endpoint += "\(separator)cacheBust=\(Int(Date().timeIntervalSince1970))"
        
        #if DEBUG
        print("[ChefLeaveAPIService] Fetching team leave balances: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .tryMap { data in
                // Server returns {balances: [...], summary: {...}, year: 2025}
                struct ServerBalanceResponse: Codable {
                    let balances: [EmployeeLeaveBalance]
                    let year: Int
                    
                    private enum CodingKeys: String, CodingKey {
                        case balances, year
                    }
                }
                
                let serverResponse = try JSONDecoder().decode(ServerBalanceResponse.self, from: data)
                return serverResponse.balances
            }
            .mapError { error in
                #if DEBUG
                print("[ChefLeaveAPIService] Fetch team balances error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Adjusts leave balance for an employee (admin function)
    func adjustEmployeeLeaveBalance(
        employeeId: Int,
        adjustment: LeaveBalanceAdjustment
    ) -> AnyPublisher<EmployeeLeaveBalance, APIError> {
        let endpoint = "/api/app/chef/leave/balance/\(employeeId)"
        
        #if DEBUG
        print("[ChefLeaveAPIService] Adjusting leave balance for employee \(employeeId)")
        #endif
        
        return makeRequestWithRetry(endpoint: endpoint, method: "PUT", body: adjustment)
            .decode(type: EmployeeLeaveBalance.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[ChefLeaveAPIService] Adjust balance error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Statistics & Analytics
    
    /// Fetches leave statistics for the team
    func fetchLeaveStatistics(
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> AnyPublisher<LeaveStatistics, APIError> {
        var endpoint = "/api/app/chef/leave/statistics"
        var params: [String] = []
        
        let dateFormatter = DateFormatter.iso8601DateOnly
        
        if let startDate = startDate {
            params.append("start_date=\(dateFormatter.string(from: startDate))")
        }
        if let endDate = endDate {
            params.append("end_date=\(dateFormatter.string(from: endDate))")
        }
        
        if !params.isEmpty {
            endpoint += "?" + params.joined(separator: "&")
        }
        
        // Add cache buster
        let separator = endpoint.contains("?") ? "&" : "?"
        endpoint += "\(separator)cacheBust=\(Int(Date().timeIntervalSince1970))"
        
        #if DEBUG
        print("[ChefLeaveAPIService] Fetching leave statistics: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: LeaveStatistics.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[ChefLeaveAPIService] Fetch statistics error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Export & Reporting
    
    /// Exports leave data for payroll/HR integration
    func exportLeaveData(
        startDate: Date,
        endDate: Date,
        format: LeaveExportFormat = .csv,
        includeBalances: Bool = true
    ) -> AnyPublisher<ExportResponse, APIError> {
        let dateFormatter = DateFormatter.iso8601DateOnly
        let params = [
            "start_date": dateFormatter.string(from: startDate),
            "end_date": dateFormatter.string(from: endDate),
            "format": format.rawValue,
            "include_balances": String(includeBalances)
        ]
        
        let queryString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let endpoint = "/api/app/chef/leave/export?\(queryString)"
        
        #if DEBUG
        print("[ChefLeaveAPIService] Exporting leave data: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none, useLongTimeout: true)
            .decode(type: ExportResponse.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[ChefLeaveAPIService] Export error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Emergency Override Functions
    
    /// Creates a leave request on behalf of an employee (emergency situations)
    func createLeaveRequestForEmployee(
        employeeId: Int,
        request: CreateLeaveRequestRequest,
        reason: String
    ) -> AnyPublisher<CreateLeaveRequestResponse, APIError> {
        let endpoint = "/api/app/chef/leave/requests/create-for-employee"
        let overrideRequest = CreateLeaveRequestForEmployeeRequest(
            employee_id: employeeId,
            leave_request: request,
            override_reason: reason
        )
        
        #if DEBUG
        print("[ChefLeaveAPIService] Creating leave request for employee \(employeeId)")
        #endif
        
        return makeRequestWithRetry(endpoint: endpoint, method: "POST", body: overrideRequest)
            .decode(type: CreateLeaveRequestResponse.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[ChefLeaveAPIService] Create request for employee error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Cancels any leave request (admin override)
    func adminCancelLeaveRequest(
        id: Int,
        reason: String
    ) -> AnyPublisher<ApproveRejectLeaveResponse, APIError> {
        let endpoint = "/api/app/chef/leave/requests/\(id)/admin-cancel"
        let request = AdminCancelRequest(reason: reason)
        
        #if DEBUG
        print("[ChefLeaveAPIService] Admin cancelling leave request \(id)")
        #endif
        
        return makeRequestWithRetry(endpoint: endpoint, method: "DELETE", body: request)
            .decode(type: ApproveRejectLeaveResponse.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[ChefLeaveAPIService] Admin cancel error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Recalculate all leave balances based on approved requests
    func recalculateAllLeaveBalances() -> AnyPublisher<RecalculateBalancesResponse, APIError> {
        let endpoint = "/api/app/chef/leave/balance/recalculate"
        let request = RecalculateBalancesRequest(confirm: "RECALCULATE_BALANCES")
        
        #if DEBUG
        print("[ChefLeaveAPIService] Recalculating all leave balances")
        #endif
        
        return makeRequestWithRetry(endpoint: endpoint, method: "POST", body: request)
            .decode(type: RecalculateBalancesResponse.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[ChefLeaveAPIService] Recalculate balances error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Models

struct RecalculateBalancesRequest: Codable {
    let confirm: String
}

struct RecalculateBalancesResponse: Codable {
    let success: Bool
    let message: String
    let updated_balances: Int
    let missing_balances_created: Int
    let verification: [BalanceVerification]
}

struct BalanceVerification: Codable, Identifiable {
    let id: Int
    let employee_id: Int
    let year: Int
    let vacation_days_total: Int
    let vacation_days_used: Int
    let personal_days_total: Int
    let personal_days_used: Int
    let sick_days_used: Int
    let carry_over_days: Int
    let Employees: EmployeeName?
    
    struct EmployeeName: Codable {
        let name: String
    }
}

struct EmployeeLeaveBalance: Codable, Identifiable {
    let id: Int
    let employee_id: Int
    let year: Int
    let vacation_days_total: Int?
    let vacation_days_used: Int?
    let sick_days_used: Int?
    let personal_days_total: Int?
    let personal_days_used: Int?
    let carry_over_days: Int?
    let carry_over_expires: String?
    let vacation_days_remaining: Int?
    let personal_days_remaining: Int?
    let carry_over_expiring_soon: Bool?
    let vacation_utilization_percent: Int?
    let personal_utilization_percent: Int?
    let needs_attention: Bool?
    let Employees: EmployeeInfo?
    
    // Computed properties for convenience
    var employee_name: String {
        return Employees?.name ?? "Employee #\(employee_id)"
    }
    
    var employee_email: String {
        return Employees?.email ?? ""
    }
    
    var role: String {
        return Employees?.role ?? ""
    }
    
    var profile_picture_url: String? {
        return nil // Not included in this response
    }
    
    // Convert to LeaveBalance for compatibility - mutable
    var balance: LeaveBalance {
        get {
            return LeaveBalance(
                id: id,
                employee_id: employee_id,
                year: year,
                vacation_days_total: vacation_days_total ?? 25,
                vacation_days_used: vacation_days_used ?? 0,
                sick_days_used: sick_days_used ?? 0,
                personal_days_total: personal_days_total ?? 5,
                personal_days_used: personal_days_used ?? 0,
                carry_over_days: carry_over_days ?? 0,
                carry_over_expires: carry_over_expires != nil ? ISO8601DateFormatter().date(from: carry_over_expires!) : nil
            )
        }
        set {
            // Note: Setting balance will create a new instance
            // This is for compatibility but the individual fields are immutable
        }
    }
    
    // Create a new instance with updated balance
    func withUpdatedBalance(_ newBalance: LeaveBalance) -> EmployeeLeaveBalance {
        return EmployeeLeaveBalance(
            id: newBalance.id,
            employee_id: newBalance.employee_id,
            year: newBalance.year,
            vacation_days_total: newBalance.vacation_days_total,
            vacation_days_used: newBalance.vacation_days_used,
            sick_days_used: newBalance.sick_days_used,
            personal_days_total: newBalance.personal_days_total,
            personal_days_used: newBalance.personal_days_used,
            carry_over_days: newBalance.carry_over_days,
            carry_over_expires: newBalance.carry_over_expires?.description,
            vacation_days_remaining: nil,
            personal_days_remaining: nil,
            carry_over_expiring_soon: nil,
            vacation_utilization_percent: nil,
            personal_utilization_percent: nil,
            needs_attention: nil,
            Employees: self.Employees
        )
    }
}

struct EmployeeInfo: Codable {
    let employee_id: Int
    let name: String
    let email: String
    let role: String
    let created_at: String?
}

struct TeamAvailabilityResponse: Codable {
    let available_employees: Int
    let total_employees: Int
    let availability_percentage: Double
    let employees_on_leave: [EmployeeLeaveDay]
    let sufficient_staffing: Bool
}

struct BulkLeaveActionRequest: Codable {
    let request_ids: [Int]
}

struct BulkLeaveActionResponse: Codable {
    let successful: [Int]
    let failed: [BulkActionFailure]
    let total_processed: Int
    let message: String
}

struct BulkActionFailure: Codable {
    let request_id: Int
    let error: String
}

struct LeaveBalanceAdjustment: Codable {
    let vacation_days_adjustment: Int?
    let personal_days_adjustment: Int?
    let carry_over_adjustment: Int?
    let reason: String
    let effective_date: Date?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(vacation_days_adjustment, forKey: .vacation_days_adjustment)
        try container.encodeIfPresent(personal_days_adjustment, forKey: .personal_days_adjustment)
        try container.encodeIfPresent(carry_over_adjustment, forKey: .carry_over_adjustment)
        try container.encode(reason, forKey: .reason)
        
        if let effective_date = effective_date {
            let dateFormatter = DateFormatter.iso8601DateOnly
            try container.encode(dateFormatter.string(from: effective_date), forKey: .effective_date)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case vacation_days_adjustment, personal_days_adjustment, carry_over_adjustment, reason, effective_date
    }
}

struct CreateLeaveRequestForEmployeeRequest: Codable {
    let employee_id: Int
    let leave_request: CreateLeaveRequestRequest
    let override_reason: String
}

struct AdminCancelRequest: Codable {
    let reason: String
}

enum LeaveExportFormat: String, Codable, CaseIterable {
    case csv = "csv"
    case json = "json"
    case xlsx = "xlsx"
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .xlsx: return "Excel"
        }
    }
}

struct ExportResponse: Codable {
    let download_url: String
    let file_name: String
    let file_size: Int
    let expires_at: Date
    let format: String
}

struct ChefApproveRejectLeaveRequest: Codable {
    let id: Int
    let action: ApproveRejectLeaveRequest.LeaveAction
    let approver_id: Int
    let rejection_reason: String?
}