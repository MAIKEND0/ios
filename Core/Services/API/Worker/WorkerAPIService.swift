//
//  WorkerAPIService.swift
//  KSR Cranes App
//

import Foundation
import Combine

final class WorkerAPIService: BaseAPIService {
    static let shared = WorkerAPIService()

    private override init() {
        super.init()
    }
    // Dodaj te metody i struktury na końcu pliku WorkerAPIService.swift po istniejących metodach

    // MARK: - Timesheet Methods for Workers

    /// Pobiera timesheety dla danego pracownika
    func fetchWorkerTimesheets(employeeId: String) -> AnyPublisher<[WorkerTimesheet], APIError> {
        let endpoint = "/api/app/worker/timesheets?employee_id=\(employeeId)&cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [WorkerTimesheet].self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[WorkerAPIService] Fetch worker timesheets error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .map { timesheets in
                #if DEBUG
                print("[WorkerAPIService] Loaded \(timesheets.count) timesheets for worker \(employeeId)")
                #endif
                return timesheets
            }
            .eraseToAnyPublisher()
    }

    /// Pobiera statystyki timesheetów dla pracownika
    func fetchWorkerTimesheetStats(employeeId: String) -> AnyPublisher<WorkerTimesheetStats, APIError> {
        let endpoint = "/api/app/worker/timesheets/stats?employee_id=\(employeeId)&cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: WorkerTimesheetStats.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Worker Timesheet Models (dodaj te struktury na końcu extension WorkerAPIService)

    struct WorkerTimesheet: Codable, Identifiable {
        let id: Int
        let task_id: Int
        let employee_id: Int
        let weekNumber: Int
        let year: Int
        let timesheetUrl: String
        let created_at: Date
        let updated_at: Date?
        let Tasks: Task?
        
        private enum CodingKeys: String, CodingKey {
            case id, task_id, employee_id, weekNumber, year, timesheetUrl, created_at, updated_at, Tasks
        }
    }

    struct WorkerTimesheetStats: Codable {
        let totalTimesheets: Int
        let thisWeekTimesheets: Int
        let thisMonthTimesheets: Int
        let uniqueTasks: Int
        let oldestTimesheet: OldestNewestTimesheet?
        let newestTimesheet: OldestNewestTimesheet?
        let currentWeekStats: WeekStats?
        let currentMonthStats: MonthStats?
        
        struct OldestNewestTimesheet: Codable {
            let weekNumber: Int
            let year: Int
            let date: String?
        }
        
        struct WeekStats: Codable {
            let entries: Int
            let totalKm: Double
            let totalPauseMinutes: Int
        }
        
        struct MonthStats: Codable {
            let entries: Int
            let totalKm: Double
            let totalPauseMinutes: Int
        }
    }
    // MARK: - Notification Methods

    /// Pobiera powiadomienia dla pracownika z rozszerzonymi parametrami
    func fetchNotifications(params: NotificationQueryParams = NotificationQueryParams()) -> AnyPublisher<NotificationsResponse, APIError> {
        var endpoint = "/api/app/notifications"
        let queryItems = params.toQueryItems()
        if !queryItems.isEmpty {
            let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            endpoint += "?\(queryString)"
        }
        
        // Dodaj cache buster do każdego zapytania
        let separator = endpoint.contains("?") ? "&" : "?"
        endpoint += "\(separator)cacheBust=\(Int(Date().timeIntervalSince1970))"
        
        #if DEBUG
        print("[WorkerAPIService] Fetching notifications from: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .handleEvents(receiveOutput: { data in
                #if DEBUG
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[WorkerAPIService] Notifications response: \(jsonString.prefix(500))")
                }
                #endif
            })
            .decode(type: NotificationsResponse.self, decoder: jsonDecoder())
            .mapError { error in
                #if DEBUG
                print("[WorkerAPIService] Notifications fetch error: \(error)")
                #endif
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }

    /// Pobiera liczbę nieprzeczytanych powiadomień
    func getUnreadNotificationsCount() -> AnyPublisher<UnreadNotificationsCountResponse, APIError> {
        let endpoint = "/api/app/notifications/unread-count?cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: UnreadNotificationsCountResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Oznacza powiadomienie jako przeczytane
    func markNotificationAsRead(id: Int) -> AnyPublisher<MarkAsReadResponse, APIError> {
        let endpoint = "/api/app/notifications/\(id)/read"
        return makeRequest(endpoint: endpoint, method: "PATCH", body: Optional<String>.none)
            .decode(type: MarkAsReadResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Oznacza wiele powiadomień jako przeczytane (bulk operation)
    func markMultipleNotificationsAsRead(ids: [Int]) -> AnyPublisher<BulkMarkAsReadResponse, APIError> {
        let endpoint = "/api/app/notifications/bulk/read"
        let request = BulkMarkAsReadRequest(notificationIds: ids)
        
        return makeRequest(endpoint: endpoint, method: "PATCH", body: request)
            .decode(type: BulkMarkAsReadResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Pobiera statystyki powiadomień
    func getNotificationStats() -> AnyPublisher<NotificationStatsResponse, APIError> {
        let endpoint = "/api/app/notifications/stats?cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: NotificationStatsResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Tworzy nowe powiadomienie (tylko dla adminów/managerów)
    func createNotification(
        targetEmployeeId: Int,
        type: NotificationType,
        title: String,
        message: String,
        workEntryId: Int? = nil,
        taskId: Int? = nil,
        projectId: Int? = nil,
        priority: NotificationPriority = .normal,
        category: NotificationCategory = .system,
        actionRequired: Bool = false,
        actionUrl: String? = nil,
        expiresAt: Date? = nil
    ) -> AnyPublisher<CreateNotificationResponse, APIError> {
        
        let endpoint = "/api/app/notifications"
        let request = CreateNotificationRequest(
            targetEmployeeId: targetEmployeeId,
            notificationType: type,
            title: title,
            message: message,
            workEntryId: workEntryId,
            taskId: taskId,
            projectId: projectId,
            priority: priority,
            category: category,
            actionRequired: actionRequired,
            actionUrl: actionUrl,
            expiresAt: expiresAt
        )
        
        return makeRequest(endpoint: endpoint, method: "POST", body: request)
            .decode(type: CreateNotificationResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Existing Methods

    /// Pobiera zadania przypisane do pracownika
    func fetchTasks() -> AnyPublisher<[Task], APIError> {
        let endpoint = "/api/app/tasks?cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [Task].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Pobiera wpisy godzin pracy dla danego pracownika i tygodnia
    func fetchWorkEntries(
        employeeId: String,
        weekStartDate: String,
        isDraft: Bool? = nil
    ) -> AnyPublisher<[WorkHourEntry], APIError> {
        var ep = "/api/app/work-entries?employee_id=\(employeeId)&selectedMonday=\(weekStartDate)"
        if let d = isDraft { ep += "&is_draft=\(d)" }
        ep += "&cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: ep, method: "GET", body: Optional<String>.none)
            .tryMap { data in
                do {
                    let entries = try self.jsonDecoder().decode([WorkHourEntry].self, from: data)
                    return entries
                } catch {
                    #if DEBUG
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("[WorkerAPIService] Failed to decode WorkHourEntry: \(error)")
                        print("[WorkerAPIService] Raw response: \(responseString.prefix(1000))")
                    }
                    #endif
                    throw error
                }
            }
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Upsert'uje wpisy godzin pracy (tworzy lub aktualizuje)
    func upsertWorkEntries(_ entries: [WorkHourEntry]) -> AnyPublisher<WorkEntryResponse, APIError> {
        #if DEBUG
        for (index, entry) in entries.enumerated() {
            print("[WorkerAPIService] Upsert entry \(index): pause_minutes=\(entry.pause_minutes ?? 0), work_date=\(entry.work_date), km=\(entry.km ?? 0.0)")
        }
        #endif
        let body = ["entries": entries]
        return makeRequest(endpoint: "/api/app/work-entries", method: "POST", body: body)
            .tryMap { data in
                do {
                    let response = try self.jsonDecoder().decode(WorkEntryResponse.self, from: data)
                    return response
                } catch {
                    #if DEBUG
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("[WorkerAPIService] Failed to decode WorkEntryResponse: \(error)")
                        print("[WorkerAPIService] Raw response: \(responseString.prefix(1000))")
                    }
                    #endif
                    throw error
                }
            }
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Pobiera ogłoszenia dla pracownika
    func fetchAnnouncements() -> AnyPublisher<[Announcement], APIError> {
        let endpoint = "/api/app/announcements?cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [Announcement].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Testuje połączenie z API
    func testConnection() -> AnyPublisher<String, APIError> {
        let endpoint = "/api/app/tasks?cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .map { _ in "Connection successful" }
            .eraseToAnyPublisher()
    }

    // MARK: - Notification Utility Methods

    /// Sprawdza czy są nowe powiadomienia od ostatniego sprawdzenia
    func checkForNewNotifications(since lastCheck: Date) -> AnyPublisher<Bool, APIError> {
        let params = NotificationQueryParams(
            limit: 1,
            unreadOnly: true,
            sinceDate: lastCheck
        )
        
        return fetchNotifications(params: params)
            .map { response in
                return !response.notifications.isEmpty
            }
            .eraseToAnyPublisher()
    }

    /// Pobiera tylko pilne nieprzeczytane powiadomienia
    func fetchUrgentNotifications() -> AnyPublisher<[AppNotification], APIError> {
        let params = NotificationQueryParams(
            limit: 20,
            unreadOnly: true,
            priority: .urgent
        )
        
        return fetchNotifications(params: params)
            .map { response in
                return response.notifications
            }
            .eraseToAnyPublisher()
    }

    /// Pobiera powiadomienia według kategorii
    func fetchNotifications(forCategory category: NotificationCategory, limit: Int = 50) -> AnyPublisher<[AppNotification], APIError> {
        let params = NotificationQueryParams(
            limit: limit,
            category: category
        )
        
        return fetchNotifications(params: params)
            .map { response in
                return response.notifications
            }
            .eraseToAnyPublisher()
    }
}

// MARK: – Modele dla iOS‐owych endpointów

extension WorkerAPIService {
    // MARK: - Updated Task Model with all new crane-related fields and flexible decoding
    struct Task: Codable, Identifiable {
        let id = UUID()
        let task_id: Int
        let title: String
        let description: String?
        let deadline: Date?
        let created_at: Date?
        
        // Supervisor information
        let supervisor_id: Int?
        let supervisor_email: String?
        let supervisor_phone: String?
        let supervisor_name: String?
        
        // Crane requirements - new fields
        let required_crane_types: AnyCodable?
        let preferred_crane_model_id: Int?
        let equipment_category_id: Int?
        let equipment_brand_id: Int?
        
        // Crane details - relations
        let crane_category: CraneCategory?
        let crane_brand: CraneBrand?
        let preferred_crane_model: CraneModel?
        
        // Project information
        let project: Project?
        
        // Task assignments (for workers)
        let assignments: [TaskAssignment]?

        struct Project: Codable {
            let project_id: Int
            let title: String
            let description: String?
            let start_date: Date?
            let end_date: Date?
            let street: String?
            let city: String?
            let zip: String?
            let status: String?
            let customer: Customer?
            
            struct Customer: Codable {
                let customer_id: Int
                let name: String
            }
        }
        
        struct CraneCategory: Codable {
            let id: Int
            let name: String
            let code: String
            let description: String?
            let iconUrl: String?
        }
        
        struct CraneBrand: Codable {
            let id: Int
            let name: String
            let code: String
            let logoUrl: String?
            let website: String?
        }
        
        struct CraneModel: Codable {
            let id: Int
            let name: String
            let code: String
            let description: String?
            let maxLoadCapacity: Double?
            let maxHeight: Double?
            let maxRadius: Double?
            let enginePower: Int?
            let specifications: AnyCodable?
            let imageUrl: String?
            let brochureUrl: String?
            let videoUrl: String?
            
            private enum CodingKeys: String, CodingKey {
                case id, name, code, description
                case maxLoadCapacity, maxHeight, maxRadius, enginePower
                case specifications, imageUrl, brochureUrl, videoUrl
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                id = try container.decode(Int.self, forKey: .id)
                name = try container.decode(String.self, forKey: .name)
                code = try container.decode(String.self, forKey: .code)
                description = try container.decodeIfPresent(String.self, forKey: .description)
                
                // Flexible decoding for numeric values that might come as strings
                maxLoadCapacity = Self.decodeFlexibleDouble(from: container, forKey: .maxLoadCapacity)
                maxHeight = Self.decodeFlexibleDouble(from: container, forKey: .maxHeight)
                maxRadius = Self.decodeFlexibleDouble(from: container, forKey: .maxRadius)
                enginePower = Self.decodeFlexibleInt(from: container, forKey: .enginePower)
                
                specifications = try container.decodeIfPresent(AnyCodable.self, forKey: .specifications)
                imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
                brochureUrl = try container.decodeIfPresent(String.self, forKey: .brochureUrl)
                videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
            }
            
            // Helper methods for flexible numeric decoding
            private static func decodeFlexibleDouble<K: CodingKey>(
                from container: KeyedDecodingContainer<K>,
                forKey key: K
            ) -> Double? {
                // Try Double first
                if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: key) {
                    return doubleValue
                }
                
                // Try String and convert to Double
                if let stringValue = try? container.decodeIfPresent(String.self, forKey: key),
                   !stringValue.isEmpty {
                    return Double(stringValue)
                }
                
                // Try Int and convert to Double
                if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
                    return Double(intValue)
                }
                
                return nil
            }
            
            private static func decodeFlexibleInt<K: CodingKey>(
                from container: KeyedDecodingContainer<K>,
                forKey key: K
            ) -> Int? {
                // Try Int first
                if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
                    return intValue
                }
                
                // Try String and convert to Int
                if let stringValue = try? container.decodeIfPresent(String.self, forKey: key),
                   !stringValue.isEmpty {
                    return Int(stringValue)
                }
                
                // Try Double and convert to Int
                if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: key) {
                    return Int(doubleValue)
                }
                
                return nil
            }
        }
        
        struct TaskAssignment: Codable {
            let assignment_id: Int
            let assigned_at: Date?
            let crane_model_id: Int?
            let assigned_crane_model: CraneModel?
        }

        private enum CodingKeys: String, CodingKey {
            case task_id, title, description, deadline, created_at
            case supervisor_id, supervisor_email, supervisor_phone, supervisor_name
            case required_crane_types, preferred_crane_model_id, equipment_category_id, equipment_brand_id
            case crane_category, crane_brand, preferred_crane_model
            case project, assignments
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            task_id = try container.decode(Int.self, forKey: .task_id)
            title = try container.decode(String.self, forKey: .title)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            deadline = try container.decodeIfPresent(Date.self, forKey: .deadline)
            created_at = try container.decodeIfPresent(Date.self, forKey: .created_at)
            
            // Supervisor information
            supervisor_id = try container.decodeIfPresent(Int.self, forKey: .supervisor_id)
            supervisor_email = try container.decodeIfPresent(String.self, forKey: .supervisor_email)
            supervisor_phone = try container.decodeIfPresent(String.self, forKey: .supervisor_phone)
            supervisor_name = try container.decodeIfPresent(String.self, forKey: .supervisor_name)
            
            // Crane requirements
            required_crane_types = try container.decodeIfPresent(AnyCodable.self, forKey: .required_crane_types)
            preferred_crane_model_id = try container.decodeIfPresent(Int.self, forKey: .preferred_crane_model_id)
            equipment_category_id = try container.decodeIfPresent(Int.self, forKey: .equipment_category_id)
            equipment_brand_id = try container.decodeIfPresent(Int.self, forKey: .equipment_brand_id)
            
            // Crane details - with better error handling
            do {
                crane_category = try container.decodeIfPresent(CraneCategory.self, forKey: .crane_category)
            } catch {
                #if DEBUG
                print("⚠️ [Task] Failed to decode crane_category: \(error)")
                #endif
                crane_category = nil
            }
            
            do {
                crane_brand = try container.decodeIfPresent(CraneBrand.self, forKey: .crane_brand)
            } catch {
                #if DEBUG
                print("⚠️ [Task] Failed to decode crane_brand: \(error)")
                #endif
                crane_brand = nil
            }
            
            // Handle preferred_crane_model with extra error handling
            do {
                preferred_crane_model = try container.decodeIfPresent(CraneModel.self, forKey: .preferred_crane_model)
            } catch {
                #if DEBUG
                print("⚠️ [Task] Failed to decode preferred_crane_model: \(error)")
                #endif
                preferred_crane_model = nil
            }
            
            // Project information
            do {
                project = try container.decodeIfPresent(Project.self, forKey: .project)
            } catch {
                #if DEBUG
                print("⚠️ [Task] Failed to decode project: \(error)")
                #endif
                project = nil
            }
            
            // Task assignments - with error handling
            do {
                assignments = try container.decodeIfPresent([TaskAssignment].self, forKey: .assignments)
            } catch {
                #if DEBUG
                print("⚠️ [Task] Failed to decode assignments: \(error)")
                #endif
                assignments = nil
            }
        }
    }

    // Helper for decoding arbitrary JSON values
    struct AnyCodable: Codable {
        let value: Any
        
        init<T>(_ value: T?) {
            self.value = value ?? ()
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if container.decodeNil() {
                value = ()
            } else if let bool = try? container.decode(Bool.self) {
                value = bool
            } else if let int = try? container.decode(Int.self) {
                value = int
            } else if let double = try? container.decode(Double.self) {
                value = double
            } else if let string = try? container.decode(String.self) {
                value = string
            } else if let array = try? container.decode([AnyCodable].self) {
                value = array.map { $0.value }
            } else if let dictionary = try? container.decode([String: AnyCodable].self) {
                value = dictionary.mapValues { $0.value }
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch value {
            case is Void:
                try container.encodeNil()
            case let bool as Bool:
                try container.encode(bool)
            case let int as Int:
                try container.encode(int)
            case let double as Double:
                try container.encode(double)
            case let string as String:
                try container.encode(string)
            case let array as [Any]:
                try container.encode(array.map(AnyCodable.init))
            case let dictionary as [String: Any]:
                try container.encode(dictionary.mapValues(AnyCodable.init))
            default:
                let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
                throw EncodingError.invalidValue(value, context)
            }
        }
    }

    struct WorkHourEntry: Codable, Identifiable {
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
        let km: Double?
        let confirmed_by: Int?
        let confirmed_at: Date?
        let isActive: Bool?
        let rejection_reason: String?
        let timesheetId: String?

        private enum CodingKeys: String, CodingKey {
            case entry_id, employee_id, task_id, work_date,
                 start_time, end_time, pause_minutes,
                 status, confirmation_status, is_draft, description,
                 tasks = "Tasks", km, confirmed_by, confirmed_at,
                 isActive, rejection_reason, timesheetId
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
            if let kmString = try? container.decodeIfPresent(String.self, forKey: .km), !kmString.isEmpty {
                km = Double(kmString)
            } else if let kmInt = try? container.decodeIfPresent(Int.self, forKey: .km) {
                km = Double(kmInt)
            } else {
                km = try container.decodeIfPresent(Double.self, forKey: .km)
            }
            confirmed_by = try container.decodeIfPresent(Int.self, forKey: .confirmed_by)
            confirmed_at = try container.decodeIfPresent(Date.self, forKey: .confirmed_at)
            isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
            rejection_reason = try container.decodeIfPresent(String.self, forKey: .rejection_reason)
            if let timesheetIdString = try? container.decodeIfPresent(String.self, forKey: .timesheetId) {
                timesheetId = timesheetIdString
            } else if let timesheetIdInt = try? container.decodeIfPresent(Int.self, forKey: .timesheetId) {
                timesheetId = String(timesheetIdInt)
            } else {
                timesheetId = nil
            }
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
            km: Double?,
            confirmed_by: Int?,
            confirmed_at: Date?,
            isActive: Bool?,
            rejection_reason: String?,
            timesheetId: String?
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
            self.km = km
            self.confirmed_by = confirmed_by
            self.confirmed_at = confirmed_at
            self.isActive = isActive
            self.rejection_reason = rejection_reason
            self.timesheetId = timesheetId
        }
    }

    struct WorkEntryResponse: Codable {
        let message: String
        let confirmationSent: Bool?
        let confirmationToken: String?
        let confirmationError: String?
        let entries: [WorkHourEntry]?
    }

    struct Announcement: Codable, Identifiable {
        let id: String  // ✅ FIXED: Changed from Int to String to match server response
        let title: String
        let content: String
        let priority: AnnouncementPriority
        let publishedAt: Date
        let expiresAt: Date?
    }

    enum AnnouncementPriority: String, Codable {
        case high
        case normal
        case low
    }
}

// MARK: - Request Models

struct CreateNotificationRequest: Codable {
    let targetEmployeeId: Int
    let notificationType: NotificationType
    let title: String
    let message: String
    let workEntryId: Int?
    let taskId: Int?
    let projectId: Int?
    let priority: NotificationPriority
    let category: NotificationCategory
    let actionRequired: Bool
    let actionUrl: String?
    let expiresAt: Date?
    
    private enum CodingKeys: String, CodingKey {
        case targetEmployeeId = "target_employee_id"
        case notificationType = "notification_type"
        case title
        case message
        case workEntryId = "work_entry_id"
        case taskId = "task_id"
        case projectId = "project_id"
        case priority
        case category
        case actionRequired = "action_required"
        case actionUrl = "action_url"
        case expiresAt = "expires_at"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(targetEmployeeId, forKey: .targetEmployeeId)
        try container.encode(notificationType.rawValue, forKey: .notificationType)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(workEntryId, forKey: .workEntryId)
        try container.encodeIfPresent(taskId, forKey: .taskId)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(priority.rawValue, forKey: .priority)
        try container.encode(category.rawValue, forKey: .category)
        try container.encode(actionRequired, forKey: .actionRequired)
        try container.encodeIfPresent(actionUrl, forKey: .actionUrl)
        
        if let expiresAt = expiresAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(formatter.string(from: expiresAt), forKey: .expiresAt)
        }
    }
}
