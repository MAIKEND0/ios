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
    
    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case networkError(Error)
        case decodingError(Error)
        case serverError(Int, String)
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:           return "Niepoprawny adres URL"
            case .invalidResponse:      return "Niepoprawna odpowiedź serwera"
            case .networkError(let e):  return "Błąd sieci: \(e.localizedDescription)"
            case .decodingError(let e): return "Błąd dekodowania: \(e.localizedDescription)"
            case .serverError(let c, let m): return "Błąd serwera (\(c)): \(m)"
            case .unknown:              return "Nieznany błąd"
            }
        }
    }

    private init() {
        self.baseURL = Configuration.API.baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
        
        // Załaduj token z keychain przy inicjalizacji
        refreshTokenFromKeychain()
    }
    
    // MARK: - Token Management
    
    func refreshTokenFromKeychain() {
        if let token = KeychainService.shared.getToken() {
            self.authToken = token
            #if DEBUG
            print("[APIService] Token załadowany z keychain")
            #endif
        }
    }
    
    private func applyAuthToken(to request: inout URLRequest) {
        if let token = authToken, !token.isEmpty {
            let tokenValue = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
            request.setValue(tokenValue, forHTTPHeaderField: "Authorization")
            #if DEBUG
            print("[APIService] Dodano token do żądania: \(request.url?.absoluteString ?? "")")
            #endif
        } else {
            refreshTokenFromKeychain()
            if let token = authToken, !token.isEmpty {
                let tokenValue = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
                request.setValue(tokenValue, forHTTPHeaderField: "Authorization")
                #if DEBUG
                print("[APIService] Dodano odświeżony token do żądania")
                #endif
            } else {
                #if DEBUG
                print("[APIService] ⚠️ Brak dostępnego tokenu dla żądania: \(request.url?.absoluteString ?? "")")
                #endif
            }
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
        applyAuthToken(to: &request)
        
        if method != "GET", let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(body)
                #if DEBUG
                if let jsonStr = String(data: request.httpBody!, encoding: .utf8) {
                    print("[APIService] Request body: \(jsonStr)")
                }
                #endif
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
                if let respStr = String(data: data, encoding: .utf8) {
                    print("[APIService] Response: \(respStr.prefix(200))")
                }
                #endif
                
                if (200...299).contains(http.statusCode) {
                    return Just(data)
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                } else if http.statusCode == 401 {
                    #if DEBUG
                    print("[APIService] ⚠️ 401 Unauthorized - token może być wygasły")
                    #endif
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .authenticationFailure, object: nil)
                    }
                    return Fail(error: APIError.serverError(401, "Authentication expired. Please log in again."))
                        .eraseToAnyPublisher()
                } else {
                    let raw = String(data: data, encoding: .utf8) ?? ""
                    let msg = raw.isEmpty ? "Code \(http.statusCode)" : "\(raw.prefix(200))…"
                    return Fail(error: APIError.serverError(http.statusCode, msg))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    private func jsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        // Custom ISO8601 with fractional seconds:
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Nie można rozkodować daty: \(dateString)"
            )
        }
        return decoder
    }
}

// MARK: – App‐only endpoints (iOS)

extension APIService {
    func fetchTasks() -> AnyPublisher<[Task], APIError> {
        makeRequest(endpoint: "/api/app/tasks", method: "GET", body: Optional<String>.none)
            .decode(type: [Task].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func fetchWorkEntries(
        employeeId: String,
        weekStartDate: String,
        isDraft: Bool? = nil
    ) -> AnyPublisher<[WorkHourEntry], APIError> {
        var ep = "/api/app/work-entries?employee_id=\(employeeId)&selectedMonday=\(weekStartDate)"
        if let d = isDraft { ep += "&is_draft=\(d)" }
        return makeRequest(endpoint: ep, method: "GET", body: Optional<String>.none)
            .decode(type: [WorkHourEntry].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func upsertWorkEntries(_ entries: [WorkHourEntry]) -> AnyPublisher<Bool, APIError> {
        let body = ["entries": entries]
        return makeRequest(endpoint: "/api/app/work-entries", method: "POST", body: body)
            .map { _ in true }
            .eraseToAnyPublisher()
    }

    func fetchAnnouncements() -> AnyPublisher<[Announcement], APIError> {
        makeRequest(endpoint: "/api/app/announcements", method: "GET", body: Optional<String>.none)
            .decode(type: [Announcement].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func testConnection() -> AnyPublisher<String, APIError> {
        makeRequest(endpoint: "/api/app/tasks", method: "GET", body: Optional<String>.none)
            .map { _ in "Connection successful" }
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
        let tasks: Task?

        private enum CodingKeys: String, CodingKey {
            case entry_id, employee_id, task_id, work_date,
                 start_time, end_time, pause_minutes,
                 status, is_draft, tasks = "Tasks"
        }
    }
}

// MARK: - Authentication Notification

extension Notification.Name {
    static let authenticationFailure = Notification.Name("authenticationFailure")
}
