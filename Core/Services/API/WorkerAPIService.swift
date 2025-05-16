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

    /// Pobiera zadania przypisane do pracownika
    /// - Returns: Publisher z tablicą zadań lub błędem
    func fetchTasks() -> AnyPublisher<[Task], APIError> {
        makeRequest(endpoint: "/api/app/tasks", method: "GET", body: Optional<String>.none)
            .decode(type: [Task].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Pobiera wpisy godzin pracy dla danego pracownika i tygodnia
    /// - Parameters:
    ///   - employeeId: ID pracownika
    ///   - weekStartDate: Data początku tygodnia (poniedziałek) w formacie YYYY-MM-DD
    ///   - isDraft: Optional - filtrowanie po stanie draft/nondraft
    /// - Returns: Publisher z tablicą wpisów lub błędem
    func fetchWorkEntries(
        employeeId: String,
        weekStartDate: String,
        isDraft: Bool? = nil
    ) -> AnyPublisher<[WorkHourEntry], APIError> {
        var ep = "/api/app/work-entries?employee_id=\(employeeId)&selectedMonday=\(weekStartDate)"
        if let d = isDraft { ep += "&is_draft=\(d)" }
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
    /// - Parameter entries: Tablica wpisów do zapisania
    /// - Returns: Publisher z odpowiedzią lub błędem
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
    /// - Returns: Publisher z tablicą ogłoszeń lub błędem
    func fetchAnnouncements() -> AnyPublisher<[Announcement], APIError> {
        makeRequest(endpoint: "/api/app/announcements", method: "GET", body: Optional<String>.none)
            .decode(type: [Announcement].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Testuje połączenie z API
    /// - Returns: Publisher z potwierdzeniem lub błędem
    func testConnection() -> AnyPublisher<String, APIError> {
        makeRequest(endpoint: "/api/app/tasks", method: "GET", body: Optional<String>.none)
            .map { _ in "Connection successful" }
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
            // Obsługa tasks jako null lub pusty obiekt
            if container.contains(.tasks), try container.decodeNil(forKey: .tasks) == false {
                tasks = try container.decodeIfPresent(Task.self, forKey: .tasks)
            } else {
                tasks = nil
            }
            // Obsługa km jako String, Int lub Double
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
            timesheetId = try container.decodeIfPresent(String.self, forKey: .timesheetId)
        }

        // Inicjalizacja ręczna dla tworzenia wpisów
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
