//
//  APIService.swift
//  KSR Cranes App
//

import Foundation
import Combine

final class APIService {
    static let shared = APIService()
    private let baseURL: String
    private let session: URLSession
    var authToken: String?

    private init() {
        self.baseURL = Configuration.API.baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
        if let token = KeychainService.shared.getToken() {
            authToken = token
        }
    }

    // MARK: – Generic Request

    private func makeRequest<T: Encodable>(
        endpoint: String,
        method: String,
        body: T?
    ) -> AnyPublisher<Data, APIError> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if method != "GET", let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(body)
            } catch {
                return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
            }
        }
        #if DEBUG
        print("[APIService] \(method) \(url)")
        #endif
        return session.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, resp -> AnyPublisher<Data, APIError> in
                guard let http = resp as? HTTPURLResponse else {
                    return Fail(error: APIError.invalidResponse).eraseToAnyPublisher()
                }
                #if DEBUG
                print("[APIService] Status: \(http.statusCode)")
                #endif
                if (200...299).contains(http.statusCode) {
                    return Just(data)
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                } else {
                    let raw = String(data: data, encoding: .utf8) ?? ""
                    let msg = raw.isEmpty
                        ? "Code \(http.statusCode)"
                        : "\(raw.prefix(200))…"
                    return Fail(error: APIError.serverError(http.statusCode, msg))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    private func jsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

// MARK: – App‐only endpoints (iOS)

extension APIService {
    /// Pobiera zadania przypisane do pracownika
    func fetchTasks() -> AnyPublisher<[Task], APIError> {
        makeRequest(endpoint: "/api/app/tasks", method: "GET", body: Optional<String>.none)
            .decode(type: [Task].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Pobiera wpisy godzin pracy (draft lub finalne) dla danego tygodnia
    func fetchWorkEntries(
        employeeId: String,
        weekStartDate: String,
        isDraft: Bool? = nil
    ) -> AnyPublisher<[WorkHourEntry], APIError> {
        var ep = "/api/app/work-entries?employee_id=\(employeeId)&selectedMonday=\(weekStartDate)"
        if let d = isDraft {
            ep += "&is_draft=\(d)"
        }
        return makeRequest(endpoint: ep, method: "GET", body: Optional<String>.none)
            .decode(type: [WorkHourEntry].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Upsert (draft lub finalne) wpisów godzin pracy
    func upsertWorkEntries(_ entries: [WorkHourEntry]) -> AnyPublisher<Bool, APIError> {
        let body = ["entries": entries]
        return makeRequest(endpoint: "/api/app/work-entries", method: "POST", body: body)
            .map { _ in true }
            .eraseToAnyPublisher()
    }

    /// **NOWOŚĆ** – pobiera listę ogłoszeń
    func fetchAnnouncements() -> AnyPublisher<[Announcement], APIError> {
        makeRequest(endpoint: "/api/app/announcements", method: "GET", body: Optional<String>.none)
            .decode(type: [Announcement].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: – Modele dla iOS‐owych endpointów

extension APIService {
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
        let is_draft: Bool?
        let tasks: Task?   // JSON pole “Tasks”

        private enum CodingKeys: String, CodingKey {
            case entry_id, employee_id, task_id, work_date,
                 start_time, end_time, pause_minutes,
                 status, is_draft, tasks = "Tasks"
        }
    }
}
