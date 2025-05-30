// ManagerAPIService.swift
import Foundation
import Combine
import UIKit

struct AnyEncodable: Encodable {
    private let value: Encodable
    
    init(_ value: Encodable) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

final class ManagerAPIService: BaseAPIService {
    static let shared = ManagerAPIService()

    private override init() {
        super.init()
    }

    struct SignatureResponse: Codable {
        let signatureId: String
        let signatureUrl: String
    }

    func saveSignature(_ signatureImage: UIImage) -> AnyPublisher<SignatureResponse, APIError> {
        guard let imageData = signatureImage.pngData(),
              let base64String = imageData.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return Fail(error: .decodingError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode signature image"])))
                .eraseToAnyPublisher()
        }

        let body: [String: AnyEncodable] = [
            "signatureBase64": AnyEncodable(base64String)
        ]

        #if DEBUG
        print("[ManagerAPIService] Saving signature with body: \(body)")
        #endif

        return makeRequest(endpoint: "/api/app/signature", method: "POST", body: body)
            .decode(type: SignatureResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func fetchSupervisorTasks(supervisorId: Int) -> AnyPublisher<[Task], APIError> {
        let mondayStr = DateFormatter.isoDate.string(from: Calendar.current.startOfWeek(for: Date()))
        
        let entriesPublisher = fetchPendingWorkEntriesForManager(weekStartDate: mondayStr, isDraft: false)
            .map { entries in
                entries.compactMap { $0.tasks }
            }

        let endpoint = "/api/app/tasks?cacheBust=\(Int(Date().timeIntervalSince1970))"
        let tasksPublisher = makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [Task].self, decoder: jsonDecoder())
            .mapError { error -> APIError in
                if let apiError = error as? APIError {
                    return apiError
                }
                return .decodingError(error)
            }
            .map { tasks in
                #if DEBUG
                let taskDescriptions = tasks.map { "task_id=\($0.task_id), title=\($0.title), supervisor_id=\($0.supervisor_id ?? -1)" }.joined(separator: "; ")
                print("[ManagerAPIService] Raw tasks from API: [\(taskDescriptions)]")
                
                // DODANY DEBUG dla taskAssignments
                print("[ManagerAPIService] ========== TASK ASSIGNMENTS DEBUG ==========")
                for task in tasks {
                    print("[ManagerAPIService] Task: \(task.title) (ID: \(task.task_id))")
                    if let assignments = task.taskAssignments, !assignments.isEmpty {
                        print("  - taskAssignments count: \(assignments.count)")
                        for (index, assignment) in assignments.enumerated() {
                            print("    Assignment \(index + 1):")
                            print("      - employee_id: \(assignment.employee_id)")
                            if let employee = assignment.employees {
                                print("      - worker name: \(employee.name)")
                                print("      - worker employee_id: \(employee.employee_id)")
                            } else {
                                print("      - worker: NO EMPLOYEE DATA")
                            }
                        }
                    } else {
                        print("  - taskAssignments: EMPTY or NIL")
                    }
                }
                print("[ManagerAPIService] ============================================")
                #endif
                return tasks
            }

        return Publishers.Zip(tasksPublisher, entriesPublisher)
            .map { tasks, entryTasks in
                let allTasks = (tasks + entryTasks).reduce(into: [Int: Task]()) { dict, task in
                    dict[task.task_id] = task
                }
                return Array(allTasks.values)
            }
            .eraseToAnyPublisher()
    }

    func fetchPendingWorkEntriesForManager(weekStartDate: String, isDraft: Bool? = nil) -> AnyPublisher<[WorkHourEntry], APIError> {
        var ep = "/api/app/supervisor?selectedMonday=\(weekStartDate)&cacheBust=\(Int(Date().timeIntervalSince1970))"
        if let d = isDraft { ep += "&is_draft=\(d)" }
        return makeRequest(endpoint: ep, method: "GET", body: Optional<String>.none)
            .tryMap { data in
                do {
                    let entries = try self.jsonDecoder().decode([WorkHourEntry].self, from: data)
                    return entries
                } catch {
                    #if DEBUG
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("[ManagerAPIService] Failed to decode WorkHourEntry: \(error)")
                        print("[ManagerAPIService] Raw response: \(responseString.prefix(1000))")
                    }
                    #endif
                    throw error
                }
            }
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func fetchAllPendingWorkEntriesForManager(isDraft: Bool? = nil) -> AnyPublisher<[WorkHourEntry], APIError> {
        var ep = "/api/app/supervisor?allPending=true&cacheBust=\(Int(Date().timeIntervalSince1970))"
        if let d = isDraft { ep += "&is_draft=\(d)" }
        return makeRequest(endpoint: ep, method: "GET", body: Optional<String>.none)
            .tryMap { data in
                do {
                    let entries = try self.jsonDecoder().decode([WorkHourEntry].self, from: data)
                    #if DEBUG
                    print("[ManagerAPIService] Fetched all pending entries: \(entries.count)")
                    #endif
                    return entries
                } catch {
                    #if DEBUG
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("[ManagerAPIService] Failed to decode WorkHourEntry for all pending: \(error)")
                        print("[ManagerAPIService] Raw response: \(responseString.prefix(1000))")
                    }
                    #endif
                    throw error
                }
            }
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func fetchAssignedWorkers(supervisorId: Int) -> AnyPublisher<[Worker], APIError> {
        let endpoint = "/api/app/supervisor/workers?supervisorId=\(supervisorId)&cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [Worker].self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[ManagerAPIService] Fetch workers error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .map { workers in
                #if DEBUG
                print("[ManagerAPIService] Loaded \(workers.count) workers: \(workers.map { $0.name })")
                #endif
                return workers
            }
            .eraseToAnyPublisher()
    }

    // POPRAWIONE: Usunięto parametr supervisorId - API pobiera go z JWT tokenu
    func fetchProjects() -> AnyPublisher<[Project], APIError> {
        let endpoint = "/api/app/projects?cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .handleEvents(receiveOutput: { data in
                #if DEBUG
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[ManagerAPIService] Raw JSON Response for projects:")
                    print(jsonString.prefix(2000))
                }
                #endif
            })
            .decode(type: [Project].self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[ManagerAPIService] ❌ Dekodowanie projektów nie powiodło się: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .map { projects in
                #if DEBUG
                print("[ManagerAPIService] ✅ Pomyślnie zdekodowano \(projects.count) projektów")
                for (index, project) in projects.enumerated() {
                    print("  Projekt \(index + 1):")
                    print("    - ID: \(project.project_id)")
                    print("    - Tytuł: \(project.title)")
                    print("    - Zadania: \(project.tasks.count)")
                    print("    - Pracownicy: \(project.assignedWorkersCount)")
                    print("    - Klient: \(project.customer?.name ?? "Brak")")
                    print("    - Status: \(project.status?.rawValue ?? "Brak")")
                }
                #endif
                return projects
            }
            .eraseToAnyPublisher()
    }

    func fetchTimesheets(supervisorId: Int) -> AnyPublisher<[Timesheet], APIError> {
        let endpoint = "/api/app/timesheets?supervisorId=\(supervisorId)&cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [Timesheet].self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[ManagerAPIService] Fetch timesheets error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .map { timesheets in
                #if DEBUG
                print("[ManagerAPIService] Loaded \(timesheets.count) timesheets")
                #endif
                return timesheets
            }
            .eraseToAnyPublisher()
    }

    // POPRAWIONE: Dodano parametry status i isDraft dla obsługi odrzuconych wpisów
    func updateWorkEntryStatus(
        entry: WorkHourEntry,
        confirmationStatus: String,
        rejectionReason: String? = nil,
        status: String? = nil,
        isDraft: Bool? = nil
    ) -> AnyPublisher<WorkEntryResponse, APIError> {
        
        let updateRequest = UpdateWorkEntryRequest(
            entry_id: entry.entry_id,
            confirmation_status: confirmationStatus,
            work_date: entry.work_date,
            task_id: entry.task_id,
            employee_id: entry.employee_id,
            rejection_reason: rejectionReason,
            km: entry.km,
            status: status,
            is_draft: isDraft
        )
        
        let body: [String: AnyEncodable] = [
            "entries": AnyEncodable([updateRequest]),
            "rejectionReason": AnyEncodable(rejectionReason ?? "")
        ]
        
        #if DEBUG
        if let jsonData = try? JSONEncoder().encode(body), let jsonString = String(data: jsonData, encoding: .utf8) {
            print("[ManagerAPIService] Update request body: \(jsonString)")
        }
        #endif
        
        return makeRequest(endpoint: "/api/app/timesheet", method: "POST", body: body)
            .decode(type: WorkEntryResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func approveEntriesWithoutPDF(entries: [UpdateWorkEntryRequest]) -> AnyPublisher<WorkEntryResponse, APIError> {
        let body: [String: AnyEncodable] = [
            "entries": AnyEncodable(entries),
            "rejectionReason": AnyEncodable("")
        ]
        
        #if DEBUG
        if let jsonData = try? JSONEncoder().encode(body), let jsonString = String(data: jsonData, encoding: .utf8) {
            print("[ManagerAPIService] Approve entries request body: \(jsonString)")
        }
        #endif
        
        return makeRequest(endpoint: "/api/app/timesheet", method: "POST", body: body)
            .decode(type: WorkEntryResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // NOWA METODA: Grupowe odrzucanie wpisów z całego tygodnia
    func rejectWeekEntries(entries: [UpdateWorkEntryRequest], rejectionReason: String) -> AnyPublisher<WorkEntryResponse, APIError> {
        let body: [String: AnyEncodable] = [
            "entries": AnyEncodable(entries),
            "rejectionReason": AnyEncodable(rejectionReason)
        ]
        
        #if DEBUG
        print("[ManagerAPIService] 🔄 Rejecting \(entries.count) entries as a group")
        print("[ManagerAPIService] Rejection reason: \(rejectionReason)")
        if let jsonData = try? JSONEncoder().encode(body), let jsonString = String(data: jsonData, encoding: .utf8) {
            print("[ManagerAPIService] Reject week request body: \(jsonString)")
        }
        #endif
        
        return makeRequest(endpoint: "/api/app/timesheet", method: "POST", body: body)
            .decode(type: WorkEntryResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func uploadPDF(pdfData: Data, employeeId: Int, taskId: Int, weekNumber: Int, year: Int, entryIds: [Int]) -> AnyPublisher<TimesheetUploadResponse, APIError> {
        guard let url = URL(string: baseURL + "/api/app/upload-timesheet") else {
            return Fail(outputType: TimesheetUploadResponse.self, failure: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        applyAuthToken(to: &request)
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"pdf\"; filename=\"timesheet.pdf\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(pdfData)
        body.append("\r\n".data(using: .utf8)!)
        
        let addField = { (name: String, value: String) in
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append(value.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        addField("employeeId", "\(employeeId)")
        addField("taskId", "\(taskId)")
        addField("weekNumber", "\(weekNumber)")
        addField("year", "\(year)")
        
        if let entriesData = try? JSONEncoder().encode(entryIds),
           let entriesString = String(data: entriesData, encoding: .utf8) {
            addField("entries", entriesString)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        #if DEBUG
        print("[ManagerAPIService] Uploading PDF to S3, size: \(pdfData.count) bytes")
        #endif
        
        return session.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<TimesheetUploadResponse, APIError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(outputType: TimesheetUploadResponse.self, failure: APIError.invalidResponse)
                        .eraseToAnyPublisher()
                }
                
                #if DEBUG
                print("[ManagerAPIService] Upload status: \(httpResponse.statusCode)")
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("[ManagerAPIService] Response: \(responseStr)")
                }
                #endif
                
                if (200...299).contains(httpResponse.statusCode) {
                    return Just(data)
                        .decode(type: TimesheetUploadResponse.self, decoder: self.jsonDecoder())
                        .mapError { APIError.decodingError($0) }
                        .eraseToAnyPublisher()
                } else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    return Fail(outputType: TimesheetUploadResponse.self, failure: APIError.serverError(httpResponse.statusCode, errorMessage))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func testConnection() -> AnyPublisher<String, APIError> {
        let endpoint = "/api/app/tasks?cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .map { _ in "Connection successful" }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Manager Profile API Methods
    
    func fetchManagerDashboardStats(managerId: String) -> AnyPublisher<ManagerDashboardStatsResponse, APIError> {
        let endpoint = "/api/app/manager/dashboard/\(managerId)?cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ManagerDashboardStatsResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func fetchExternalManagerProfile(managerId: String) -> AnyPublisher<ExternalManagerProfileResponse, APIError> {
        let endpoint = "/api/app/manager/profile/\(managerId)?cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ExternalManagerProfileResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func updateExternalManagerContact(managerId: String, contactData: ManagerContactUpdateRequest) -> AnyPublisher<UpdateResponse, APIError> {
        let body: [String: AnyEncodable] = [
            "email": AnyEncodable(contactData.email),
            "phoneNumber": AnyEncodable(contactData.phoneNumber),
            "address": AnyEncodable(contactData.address),
            "emergencyContact": AnyEncodable(contactData.emergencyContact)
        ]
        
        let endpoint = "/api/app/manager/profile/\(managerId)"
        return makeRequest(endpoint: endpoint, method: "PATCH", body: body)
            .decode(type: UpdateResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func fetchManagerPerformanceMetrics(managerId: String) -> AnyPublisher<ManagerPerformanceResponse, APIError> {
        let endpoint = "/api/app/manager/performance/\(managerId)?cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ManagerPerformanceResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func submitWorkerFeedback(managerId: String, feedback: WorkerFeedbackRequest) -> AnyPublisher<UpdateResponse, APIError> {
        let body: [String: AnyEncodable] = [
            "workerId": AnyEncodable(feedback.workerId),
            "rating": AnyEncodable(feedback.rating),
            "comments": AnyEncodable(feedback.comments),
            "categories": AnyEncodable(feedback.categories)
        ]
        
        let endpoint = "/api/app/manager/feedback/\(managerId)"
        return makeRequest(endpoint: endpoint, method: "POST", body: body)
            .decode(type: UpdateResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - API Request Models

struct ManagerContactUpdateRequest: Codable {
    let email: String
    let phoneNumber: String?
    let address: String?
    let emergencyContact: String?
}

struct WorkerFeedbackRequest: Codable {
    let workerId: Int
    let rating: Double
    let comments: String
    let categories: [String]
}

// MARK: - API Response Models

struct ManagerDashboardStatsResponse: Codable {
    let assignedProjects: Int
    let activeProjects: Int
    let totalWorkers: Int
    let pendingApprovals: Int
    let projectsCompleted: Int
    let totalTasks: Int
    let averageProjectDuration: Double
    let approvalResponseTime: Double
    let projectSuccessRate: Double
    let workerSatisfactionScore: Double
    let hoursThisWeek: Int
    let tasksCompleted: Int
    let efficiencyRate: Int
    let workPlansCreated: Int
}

struct ExternalManagerProfileResponse: Codable {
    let employeeId: String
    let name: String
    let email: String
    let role: String
    let assignedSince: String
    let contractType: String
    let companyName: String?
    let contractEndDate: String?
    let hourlyRate: String?
    let specializations: [String]
    let certifications: [CertificationResponse]
    let address: String?
    let phoneNumber: String?
    let emergencyContact: String?
    let profilePictureUrl: String?
    let isActivated: Bool
    let createdAt: String?
    let maxProjectsAllowed: Int
    let preferredProjectTypes: [String]
}

struct CertificationResponse: Codable {
    let name: String
    let issuingOrganization: String
    let issueDate: String
    let expiryDate: String?
    let certificateNumber: String?
}

struct ManagerPerformanceResponse: Codable {
    let approvalResponseTime: Double
    let projectSuccessRate: Double
    let workerSatisfactionScore: Double
    let totalProjectsManaged: Int
    let averageProjectDuration: Double
    let onTimeCompletionRate: Double
    let qualityStandardsMet: Double
    let clientSatisfactionScore: Double
}

struct UpdateResponse: Codable {
    let success: Bool
    let message: String
    let data: [String: String]?
}

// MARK: - Extensions

extension String {
    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: self) {
            return date
        }
        
        let isoFormatter = ISO8601DateFormatter()
        return isoFormatter.date(from: self)
    }
    
    func toDecimal() -> Decimal? {
        return Decimal(string: self)
    }
}

// MARK: - Existing Model Extensions

extension ManagerAPIService {
    struct Task: Codable, Identifiable, Equatable {
        let id = UUID()
        let task_id: Int
        let title: String
        let description: String?
        let deadline: String?
        let project: Project?
        let supervisor_id: Int?
        let taskAssignments: [TaskAssignment]? // DODANE jako opcjonalne

        // DODANA struktura TaskAssignment
        struct TaskAssignment: Codable, Equatable {
            let employee_id: Int
            let employees: AssignedEmployee?
            
            struct AssignedEmployee: Codable, Equatable {
                let employee_id: Int
                let name: String
            }
            
            private enum CodingKeys: String, CodingKey {
                case employee_id, employees = "Employees"
            }
        }

        var deadlineDate: Date? {
            guard let deadline = deadline else { return nil }
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return isoFormatter.date(from: deadline)
        }

        private enum CodingKeys: String, CodingKey {
            case task_id, title, description, deadline, supervisor_id
            case project = "Projects"
            case taskAssignments = "TaskAssignments" // DODANE
        }

        // DODANY inicjalizator z domyślnymi wartościami
        init(task_id: Int, title: String, description: String?, deadline: String?, project: Project?, supervisor_id: Int?, taskAssignments: [TaskAssignment]? = nil) {
            self.task_id = task_id
            self.title = title
            self.description = description
            self.deadline = deadline
            self.project = project
            self.supervisor_id = supervisor_id
            self.taskAssignments = taskAssignments
        }

        static func == (lhs: Task, rhs: Task) -> Bool {
            return lhs.task_id == rhs.task_id &&
                   lhs.title == rhs.title &&
                   lhs.description == rhs.description &&
                   lhs.deadline == rhs.deadline &&
                   lhs.project == rhs.project &&
                   lhs.supervisor_id == rhs.supervisor_id
        }
    }

    struct WorkHourEntry: Codable, Identifiable, Equatable {
        let id = UUID()
        let entry_id: Int
        let employee_id: Int
        let task_id: Int
        let work_date: Date
        let start_time: Date?
        let end_time: Date?
        let pause_minutes: Int?
        let status: String?
        let confirmation_status: String?
        let is_draft: Bool?
        let description: String?
        let tasks: Task?
        let employees: Employee?
        let rejection_reason: String?
        let km: Double?

        struct Employee: Codable, Equatable {
            let name: String
        }

        private enum CodingKeys: String, CodingKey {
            case entry_id, employee_id, task_id, work_date,
                 start_time, end_time, pause_minutes,
                 status, confirmation_status, is_draft, description,
                 tasks = "Tasks", employees = "Employees", rejection_reason, km
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            entry_id = try container.decode(Int.self, forKey: .entry_id)
            employee_id = try container.decode(Int.self, forKey: .employee_id)
            task_id = try container.decode(Int.self, forKey: .task_id)
            work_date = try container.decode(Date.self, forKey: .work_date)
            start_time = try container.decodeIfPresent(Date.self, forKey: .start_time)
            end_time = try container.decodeIfPresent(Date.self, forKey: .end_time)
            pause_minutes = try container.decodeIfPresent(Int.self, forKey: .pause_minutes)
            status = try container.decodeIfPresent(String.self, forKey: .status)
            confirmation_status = try container.decodeIfPresent(String.self, forKey: .confirmation_status)
            is_draft = try container.decodeIfPresent(Bool.self, forKey: .is_draft)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            if container.contains(.tasks), try container.decodeNil(forKey: .tasks) == false {
                tasks = try container.decodeIfPresent(Task.self, forKey: .tasks)
            } else {
                tasks = nil
            }
            employees = try container.decodeIfPresent(Employee.self, forKey: .employees)
            rejection_reason = try container.decodeIfPresent(String.self, forKey: .rejection_reason)
            if let kmString = try? container.decodeIfPresent(String.self, forKey: .km), !kmString.isEmpty {
                km = Double(kmString)
            } else if let kmInt = try? container.decodeIfPresent(Int.self, forKey: .km) {
                km = Double(kmInt)
            } else {
                km = try container.decodeIfPresent(Double.self, forKey: .km)
            }
            
            #if DEBUG
            print("[ManagerAPIService] Decoded WorkHourEntry: entry_id=\(entry_id), task_id=\(task_id), tasks=\(String(describing: tasks?.title)), project=\(String(describing: tasks?.project?.title)), customer=\(String(describing: tasks?.project?.customer?.name))")
            #endif
        }

        init(
            entry_id: Int,
            employee_id: Int,
            task_id: Int,
            work_date: Date,
            start_time: Date?,
            end_time: Date?,
            pause_minutes: Int?,
            status: String?,
            confirmation_status: String?,
            is_draft: Bool?,
            description: String?,
            tasks: Task?,
            employees: Employee?,
            rejection_reason: String?,
            km: Double?
        ) {
            self.entry_id = entry_id
            self.employee_id = employee_id
            self.task_id = task_id
            self.work_date = work_date
            self.start_time = start_time
            self.end_time = end_time
            self.pause_minutes = pause_minutes
            self.status = status
            self.confirmation_status = confirmation_status
            self.is_draft = is_draft
            self.description = description
            self.tasks = tasks
            self.employees = employees
            self.rejection_reason = rejection_reason
            self.km = km
        }

        static func == (lhs: WorkHourEntry, rhs: WorkHourEntry) -> Bool {
            return lhs.entry_id == rhs.entry_id &&
                   lhs.employee_id == rhs.employee_id &&
                   lhs.task_id == rhs.task_id &&
                   lhs.work_date == rhs.work_date &&
                   lhs.start_time == rhs.start_time &&
                   lhs.end_time == rhs.end_time &&
                   lhs.pause_minutes == rhs.pause_minutes &&
                   lhs.status == rhs.status &&
                   lhs.confirmation_status == rhs.confirmation_status &&
                   lhs.is_draft == rhs.is_draft &&
                   lhs.description == rhs.description &&
                   lhs.tasks == rhs.tasks &&
                   lhs.employees == rhs.employees &&
                   lhs.rejection_reason == rhs.rejection_reason &&
                   lhs.km == rhs.km
        }
    }
    
    struct Worker: Codable, Identifiable {
        let id = UUID()
        let employee_id: Int
        let name: String
        let email: String?
        let phone_number: String?
        let assignedTasks: [Task]
        
        private enum CodingKeys: String, CodingKey {
            case employee_id, name, email, phone_number, assignedTasks
        }
    }
    
    enum ProjectStatus: String, Codable {
        case aktiv
        case afsluttet
        case afventer
    }
    
    // POPRAWIONY model Project z obsługą Customer z więcej pól
    struct Project: Codable, Identifiable, Equatable {
        let id: UUID
        let project_id: Int
        let title: String
        let description: String?
        let start_date: Date?
        let end_date: Date?
        let street: String?
        let city: String?
        let zip: String?
        let status: ProjectStatus?
        var tasks: [Task]
        var assignedWorkersCount: Int
        let customer: Customer?

        // POPRAWIONA struktura Customer z dodatkowymi polami
        struct Customer: Codable, Equatable {
            let customer_id: Int
            let name: String
            let contact_email: String?
            let phone: String?

            private enum CodingKeys: String, CodingKey {
                case customer_id, name, contact_email, phone
            }
            
            // DODANY inicjalizator dla backward compatibility
            init(customer_id: Int, name: String, contact_email: String? = nil, phone: String? = nil) {
                self.customer_id = customer_id
                self.name = name
                self.contact_email = contact_email
                self.phone = phone
            }
        }

        private enum CodingKeys: String, CodingKey {
            case project_id, title, description, start_date, end_date, street, city, zip, status
            case customer, tasks, assignedWorkersCount
        }
        
        var fullAddress: String? {
            let components = [street, city, zip].compactMap { $0 }
            return components.isEmpty ? nil : components.joined(separator: ", ")
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = UUID()
            self.project_id = try container.decode(Int.self, forKey: .project_id)
            self.title = try container.decode(String.self, forKey: .title)
            self.description = try container.decodeIfPresent(String.self, forKey: .description)
            self.start_date = try container.decodeIfPresent(Date.self, forKey: .start_date)
            self.end_date = try container.decodeIfPresent(Date.self, forKey: .end_date)
            self.street = try container.decodeIfPresent(String.self, forKey: .street)
            self.city = try container.decodeIfPresent(String.self, forKey: .city)
            self.zip = try container.decodeIfPresent(String.self, forKey: .zip)
            self.status = try container.decodeIfPresent(ProjectStatus.self, forKey: .status)
            self.customer = try container.decodeIfPresent(Customer.self, forKey: .customer)
            self.tasks = try container.decodeIfPresent([Task].self, forKey: .tasks) ?? []
            self.assignedWorkersCount = try container.decodeIfPresent(Int.self, forKey: .assignedWorkersCount) ?? 0
            
            #if DEBUG
            print("[ManagerAPIService] Decoded project: \(project_id)")
            print("  - Title: \(title)")
            print("  - Tasks count: \(tasks.count)")
            print("  - Workers count: \(assignedWorkersCount)")
            print("  - Customer: \(String(describing: customer?.name))")
            #endif
        }
        
        // DODANY inicjalizator dla backward compatibility
        init(id: UUID, project_id: Int, title: String, description: String?, start_date: Date?, end_date: Date?, street: String?, city: String?, zip: String?, status: ProjectStatus?, tasks: [Task], assignedWorkersCount: Int, customer: Customer?) {
            self.id = id
            self.project_id = project_id
            self.title = title
            self.description = description
            self.start_date = start_date
            self.end_date = end_date
            self.street = street
            self.city = city
            self.zip = zip
            self.status = status
            self.tasks = tasks
            self.assignedWorkersCount = assignedWorkersCount
            self.customer = customer
        }
        
        static func == (lhs: Project, rhs: Project) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.project_id == rhs.project_id &&
                   lhs.title == rhs.title &&
                   lhs.description == rhs.description &&
                   lhs.start_date == rhs.start_date &&
                   lhs.end_date == rhs.end_date &&
                   lhs.street == rhs.street &&
                   lhs.city == rhs.city &&
                   lhs.zip == rhs.zip &&
                   lhs.status == rhs.status &&
                   lhs.tasks == rhs.tasks &&
                   lhs.assignedWorkersCount == rhs.assignedWorkersCount &&
                   lhs.customer == rhs.customer
        }
    }
    
    struct WorkEntryResponse: Codable {
        let message: String
        let jobId: String?
        let confirmationSent: Bool?
        let confirmationToken: String?
        let confirmationError: String?
        let entries: [WorkHourEntry]?
    }
    
    struct TimesheetUploadResponse: Codable {
        let success: Bool
        let timesheetUrl: String
        let message: String
    }

    struct Timesheet: Codable, Identifiable {
        let id: Int
        let task_id: Int
        let employee_id: Int?
        let weekNumber: Int
        let year: Int
        let timesheetUrl: String
        let created_at: Date
        let updated_at: Date?
        let Tasks: Task?
        let Employees: WorkHourEntry.Employee?

        private enum CodingKeys: String, CodingKey {
            case id, task_id, employee_id, weekNumber, year, timesheetUrl, created_at, updated_at, Tasks, Employees
        }
    }

    // POPRAWIONY UpdateWorkEntryRequest z nowymi polami dla obsługi odrzuconych wpisów
    struct UpdateWorkEntryRequest: Codable {
        let entry_id: Int
        let confirmation_status: String
        let work_date: Date
        let task_id: Int
        let employee_id: Int
        let rejection_reason: String?
        let km: Double?
        let status: String?      // DODANE - dla odrzuconych wpisów: "pending"
        let is_draft: Bool?      // DODANE - dla odrzuconych wpisów: true

        private enum CodingKeys: String, CodingKey {
            case entry_id, confirmation_status, work_date, task_id, employee_id,
                 rejection_reason, km, status, is_draft
        }

        init(entry_id: Int, confirmation_status: String, work_date: Date, task_id: Int,
             employee_id: Int, rejection_reason: String?, km: Double?,
             status: String? = nil, is_draft: Bool? = nil) {
            self.entry_id = entry_id
            self.confirmation_status = confirmation_status
            self.work_date = work_date
            self.task_id = task_id
            self.employee_id = employee_id
            self.rejection_reason = rejection_reason
            self.km = km
            self.status = status
            self.is_draft = is_draft
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(entry_id, forKey: .entry_id)
            try container.encode(confirmation_status, forKey: .confirmation_status)
            try container.encode(task_id, forKey: .task_id)
            try container.encode(employee_id, forKey: .employee_id)
            try container.encodeIfPresent(rejection_reason, forKey: .rejection_reason)
            try container.encodeIfPresent(km, forKey: .km)
            try container.encodeIfPresent(status, forKey: .status)              // DODANE
            try container.encodeIfPresent(is_draft, forKey: .is_draft)          // DODANE
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            try container.encode(formatter.string(from: work_date), forKey: .work_date)
        }
    }
}
