//
//  WorkerLeaveAPIService.swift
//  KSR Cranes App
//
//  Worker Leave Management API Service
//  Handles leave requests, balance checking, and document uploads for workers
//

import Foundation
import Combine

final class WorkerLeaveAPIService: BaseAPIService {
    static let shared = WorkerLeaveAPIService()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Leave Requests Management
    
    /// Fetches worker's leave requests with filtering options
    func fetchLeaveRequests(
        params: LeaveQueryParams = LeaveQueryParams()
    ) -> AnyPublisher<LeaveRequestsResponse, APIError> {
        var endpoint = "/api/app/worker/leave"
        var queryItems = params.toQueryItems()
        
        // ✅ ADD MISSING EMPLOYEE_ID PARAMETER
        if let employeeIdString = AuthService.shared.getEmployeeId() {
            queryItems.append(URLQueryItem(name: "employee_id", value: employeeIdString))
        }
        
        if !queryItems.isEmpty {
            let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            endpoint += "?\(queryString)"
        }
        
        // Add cache buster
        let separator = endpoint.contains("?") ? "&" : "?"
        endpoint += "\(separator)cacheBust=\(Int(Date().timeIntervalSince1970))"
        
        #if DEBUG
        print("[WorkerLeaveAPIService] Fetching leave requests: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: LeaveRequestsServerResponse.self, decoder: jsonDecoder())
            .map { serverResponse in
                // ✅ CONVERT SERVER RESPONSE TO CLIENT RESPONSE
                LeaveRequestsResponse(
                    requests: serverResponse.leave_requests,
                    total: serverResponse.leave_requests.count,
                    page: 1,
                    limit: 100,
                    has_more: false
                )
            }
            .mapError { error in
                #if DEBUG
                print("[WorkerLeaveAPIService] Fetch leave requests error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Creates a new leave request
    func createLeaveRequest(
        _ request: CreateLeaveRequestRequest
    ) -> AnyPublisher<CreateLeaveRequestResponse, APIError> {
        let endpoint = "/api/app/worker/leave"
        
        #if DEBUG
        print("[WorkerLeaveAPIService] Creating leave request: \(request.type.displayName) from \(request.start_date) to \(request.end_date)")
        #endif
        
        return makeRequestWithRetry(endpoint: endpoint, method: "POST", body: request)
            .decode(type: CreateLeaveRequestResponse.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[WorkerLeaveAPIService] Create leave request error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Updates an existing leave request (only if pending)
    func updateLeaveRequest(
        id: Int,
        updates: UpdateLeaveRequestRequest
    ) -> AnyPublisher<CreateLeaveRequestResponse, APIError> {
        let endpoint = "/api/app/worker/leave"
        
        // Create update request with ID
        var updateBody = updates
        updateBody.id = id
        
        #if DEBUG
        print("[WorkerLeaveAPIService] Updating leave request \(id)")
        #endif
        
        return makeRequestWithRetry(endpoint: endpoint, method: "PUT", body: updateBody)
            .decode(type: CreateLeaveRequestResponse.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[WorkerLeaveAPIService] Update leave request error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Cancels a leave request
    func cancelLeaveRequest(id: Int) -> AnyPublisher<CancelLeaveResponse, APIError> {
        guard let employeeIdString = AuthService.shared.getEmployeeId() else {
            return Fail(error: APIError.unknown)
                .eraseToAnyPublisher()
        }
        
        let endpoint = "/api/app/worker/leave?id=\(id)&employee_id=\(employeeIdString)"
        
        #if DEBUG
        print("[WorkerLeaveAPIService] Cancelling leave request \(id)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: CancelLeaveResponse.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[WorkerLeaveAPIService] Cancel leave request error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Leave Balance
    
    /// Fetches current leave balance for the worker
    func fetchLeaveBalance(year: Int? = nil) -> AnyPublisher<LeaveBalance, APIError> {
        var endpoint = "/api/app/worker/leave/balance"
        var queryItems: [URLQueryItem] = []
        
        // ✅ ADD MISSING EMPLOYEE_ID PARAMETER
        if let employeeIdString = AuthService.shared.getEmployeeId() {
            queryItems.append(URLQueryItem(name: "employee_id", value: employeeIdString))
        }
        
        if let year = year {
            queryItems.append(URLQueryItem(name: "year", value: String(year)))
        }
        
        // Add cache buster
        queryItems.append(URLQueryItem(name: "cacheBust", value: String(Int(Date().timeIntervalSince1970))))
        
        if !queryItems.isEmpty {
            let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            endpoint += "?\(queryString)"
        }
        
        #if DEBUG
        print("[WorkerLeaveAPIService] Fetching leave balance: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: LeaveBalanceServerResponse.self, decoder: jsonDecoder())
            .map { $0.balance }  // ✅ EXTRACT BALANCE FROM WRAPPER
            .mapError { error in
                #if DEBUG
                print("[WorkerLeaveAPIService] Fetch leave balance error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Public Holidays
    
    /// Fetches public holidays for a given year
    func fetchPublicHolidays(year: Int? = nil) -> AnyPublisher<[PublicHoliday], APIError> {
        var endpoint = "/api/app/worker/leave/holidays"
        var queryItems: [URLQueryItem] = []
        
        if let year = year {
            queryItems.append(URLQueryItem(name: "year", value: String(year)))
        }
        
        // Add cache buster
        queryItems.append(URLQueryItem(name: "cacheBust", value: String(Int(Date().timeIntervalSince1970))))
        
        if !queryItems.isEmpty {
            let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            endpoint += "?\(queryString)"
        }
        
        #if DEBUG
        print("[WorkerLeaveAPIService] Fetching public holidays: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: PublicHolidaysResponse.self, decoder: jsonDecoder())
            .map { $0.holidays }  // ✅ EXTRACT HOLIDAYS ARRAY FROM WRAPPER
            .mapError { error in
                #if DEBUG
                print("[WorkerLeaveAPIService] Fetch public holidays error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Document Management
    
    /// Uploads sick note document for a leave request
    func uploadSickNote(
        for leaveRequestId: Int,
        fileName: String,
        fileData: Data,
        fileType: String
    ) -> AnyPublisher<DocumentUploadConfirmation, APIError> {
        let endpoint = "/api/app/worker/leave/\(leaveRequestId)/documents"
        
        // First, get upload URL
        let uploadRequest = SickNoteUploadRequest(
            file_name: fileName,
            file_type: fileType,
            file_size: fileData.count
        )
        
        #if DEBUG
        print("[WorkerLeaveAPIService] Uploading sick note for request \(leaveRequestId): \(fileName)")
        #endif
        
        return makeRequestWithRetry(endpoint: endpoint, method: "POST", body: uploadRequest)
            .decode(type: SickNoteUploadResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .flatMap { uploadResponse -> AnyPublisher<DocumentUploadConfirmation, APIError> in
                // Upload file to S3 using presigned URL
                return self.uploadFileToS3(
                    uploadURL: uploadResponse.upload_url,
                    fileData: fileData,
                    fileType: fileType
                )
                .flatMap { _ -> AnyPublisher<DocumentUploadConfirmation, APIError> in
                    // Confirm upload completion
                    let confirmationRequest = DocumentUploadConfirmation(
                        file_key: uploadResponse.file_key,
                        file_name: fileName
                    )
                    
                    let confirmEndpoint = "/api/app/worker/leave/\(leaveRequestId)/documents/confirm"
                    return self.makeRequest(endpoint: confirmEndpoint, method: "PATCH", body: confirmationRequest)
                        .decode(type: DocumentUploadConfirmation.self, decoder: self.jsonDecoder())
                        .mapError { ($0 as? APIError) ?? .decodingError($0) }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            }
            .mapError { error in
                #if DEBUG
                print("[WorkerLeaveAPIService] Upload sick note error: \(error)")
                #endif
                return error
            }
            .eraseToAnyPublisher()
    }
    
    /// Removes uploaded document from a leave request
    func removeDocument(
        from leaveRequestId: Int,
        fileKey: String
    ) -> AnyPublisher<DocumentUploadConfirmation, APIError> {
        let endpoint = "/api/app/worker/leave/\(leaveRequestId)/documents/\(fileKey)"
        
        #if DEBUG
        print("[WorkerLeaveAPIService] Removing document \(fileKey) from request \(leaveRequestId)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: DocumentUploadConfirmation.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[WorkerLeaveAPIService] Remove document error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Utility Methods
    
    /// ✅ REMOVED: validateLeaveRequest() - endpoint doesn't exist on server (404)
    /// Validates leave request locally using business rules
    func validateLeaveRequestLocal(
        type: LeaveType,
        startDate: Date,
        endDate: Date,
        halfDay: Bool = false
    ) -> Bool {
        // Basic validation rules
        guard startDate <= endDate else { return false }
        
        // Check advance notice requirements
        if type.requiresAdvanceNotice {
            let minimumNoticeHours: TimeInterval = type == .vacation ? 336 : 24 // 14 days vs 1 day
            guard startDate.timeIntervalSinceNow > minimumNoticeHours else { return false }
        }
        
        // Check half-day compatibility
        if halfDay && !type.canBeHalfDay {
            return false
        }
        
        return true
    }
    
    /// ✅ REMOVED: calculateWorkDays() - endpoint doesn't exist on server (404)
    /// Calculates work days locally (excluding weekends, holidays need to be fetched separately)
    func calculateWorkDaysLocal(
        from startDate: Date,
        to endDate: Date,
        holidays: [PublicHoliday] = []
    ) -> Int {
        let calendar = Calendar.current
        var workDays = 0
        var currentDate = startDate
        
        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            let isWeekend = weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7
            
            let isHoliday = holidays.contains { holiday in
                calendar.isDate(holiday.date, inSameDayAs: currentDate)
            }
            
            if !isWeekend && !isHoliday {
                workDays += 1
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return workDays
    }
    
    // MARK: - Private Helper Methods
    
    private func uploadFileToS3(
        uploadURL: String,
        fileData: Data,
        fileType: String
    ) -> AnyPublisher<Data, APIError> {
        guard let url = URL(string: uploadURL) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(fileType, forHTTPHeaderField: "Content-Type")
        request.httpBody = fileData
        
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .mapError { APIError.networkError($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Models

struct WorkDaysCalculationResponse: Codable {
    let work_days: Int
    let total_days: Int
    let weekend_days: Int
    let holiday_days: Int
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let iso8601DateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}