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
    struct Task: Codable, Identifiable {
        let id = UUID()
        let task_id: Int
        let title: String
        let description: String?
        let deadline: Date?
        let project: Project?

        struct Project: Codable {
            let project_id: Int
            let title: String
        }

        private enum CodingKeys: String, CodingKey {
            case task_id, title, description, deadline, project = "Projects"
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
        let id: Int
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
