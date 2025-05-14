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

        // Jeśli token w Keychain lub UserDefaults
        if let token = KeychainService.shared.getToken() {
            self.authToken = token
        }
    }

    // MARK: - Generic Request Method

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
            .flatMap { data, response -> AnyPublisher<Data, APIError> in
                guard let http = response as? HTTPURLResponse else {
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
                        ? "Kod: \(http.statusCode)"
                        : "\(raw.prefix(200))…"
                    return Fail(error: APIError.serverError(http.statusCode, msg))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Work Hours Endpoints

    func saveDraftWorkEntries(_ entries: [WorkHourEntry]) -> AnyPublisher<Bool, APIError> {
        return makeRequest(
            endpoint: "/api/worker/work-entries/draft",
            method: "POST",
            body: ["entries": entries]
        )
        .map { _ in true }
        .eraseToAnyPublisher()
    }

    func submitWorkEntries(_ entries: [WorkHourEntry]) -> AnyPublisher<Bool, APIError> {
        return makeRequest(
            endpoint: "/api/worker/work-entries/bulk",
            method: "POST",
            body: ["entries": entries]
        )
        .map { _ in true }
        .eraseToAnyPublisher()
    }

    func fetchWorkEntries(employeeId: String, weekStartDate: String)
      -> AnyPublisher<[WorkHourEntry], APIError> {
        return makeRequest(
          endpoint: "/api/worker/work-entries?employee_id=\(employeeId)&selectedMonday=\(weekStartDate)",
          method: "GET",
          body: Optional<String>.none
        )
        .decode(type: [WorkHourEntry].self, decoder: createJsonDecoder())
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .eraseToAnyPublisher()
    }

    func fetchDraftWorkEntries(employeeId: String, weekStartDate: String)
      -> AnyPublisher<[WorkHourEntry], APIError> {
        return makeRequest(
          endpoint: "/api/worker/work-entries/draft?employee_id=\(employeeId)&selectedMonday=\(weekStartDate)",
          method: "GET",
          body: Optional<String>.none
        )
        .decode(type: [WorkHourEntry].self, decoder: createJsonDecoder())
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .eraseToAnyPublisher()
    }

    private func createJsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
