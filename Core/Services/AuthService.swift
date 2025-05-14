//
//  AuthService.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import Foundation
import Combine

// MARK: – DTOs

struct LoginCredentials: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let token: String
    let employeeId: String
    let name: String
    let role: String
}

// MARK: – AuthService

final class AuthService {
    static let shared = AuthService()

    private let baseURL: String
    private let session: URLSession

    private init() {
        self.baseURL = Configuration.API.baseURL

        // Konfiguracja sesji: wyłączamy HTTP/3 (QUIC) i deklarujemy JSON globalnie
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpAdditionalHeaders = [
            "Alt-Svc": "clear",              // wymusza HTTP/2
            "Content-Type": "application/json",
            "Accept":       "application/json"
        ]
        self.session = URLSession(configuration: config)
    }

    /// Logowanie użytkownika
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, APIError> {
        let creds = LoginCredentials(email: email, password: password)
        let urlString = baseURL + "/api/app-login"
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        do {
            req.httpBody = try JSONEncoder().encode(creds)
        } catch {
            return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
        }

        #if DEBUG
        print("[AuthService] → POST \(urlString)\nBody: \(String(data: req.httpBody!, encoding: .utf8)!)")
        #endif

        return session.dataTaskPublisher(for: req)
            .mapError { APIError.networkError($0) }
            .flatMap { data, resp -> AnyPublisher<Data, APIError> in
                guard let http = resp as? HTTPURLResponse else {
                    return Fail(error: APIError.invalidResponse).eraseToAnyPublisher()
                }
                #if DEBUG
                print("[AuthService] ← Status: \(http.statusCode)")
                #endif

                if (200...299).contains(http.statusCode) {
                    return Just(data)
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                } else {
                    let raw = String(data: data, encoding: .utf8) ?? ""
                    let msg = raw.isEmpty ? "Code \(http.statusCode)" : "\(raw.prefix(200))…"
                    return Fail(error: APIError.serverError(http.statusCode, msg))
                        .eraseToAnyPublisher()
                }
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .handleEvents(receiveOutput: { [weak self] auth in
                APIService.shared.authToken = auth.token
                self?.save(auth: auth)
            }, receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    #if DEBUG
                    print("[AuthService] ❌ Login failed:", error.localizedDescription)
                    #endif
                }
            })
            .eraseToAnyPublisher()
    }

    // MARK: – Persistence

    private func save(auth: AuthResponse) {
        _ = KeychainService.shared.storeToken(auth.token)
        UserDefaults.standard.set(auth.employeeId,   forKey: Configuration.StorageKeys.employeeId)
        UserDefaults.standard.set(auth.name,         forKey: Configuration.StorageKeys.employeeName)
        UserDefaults.standard.set(auth.role,         forKey: Configuration.StorageKeys.employeeRole)
    }

    func getSavedToken() -> String? {
        KeychainService.shared.getToken()
    }

    var isLoggedIn: Bool {
        if let token = getSavedToken() {
            APIService.shared.authToken = APIService.shared.authToken ?? token
            return true
        }
        return false
    }

    func logout() {
        APIService.shared.authToken = nil
        _ = KeychainService.shared.deleteToken()
        UserDefaults.standard.removeObject(forKey: Configuration.StorageKeys.employeeId)
        UserDefaults.standard.removeObject(forKey: Configuration.StorageKeys.employeeName)
        UserDefaults.standard.removeObject(forKey: Configuration.StorageKeys.employeeRole)
        NotificationCenter.default.post(name: .didLogoutUser, object: nil)
    }

    // MARK: – Odczyt danych

    func getEmployeeRole() -> String? {
        UserDefaults.standard.string(forKey: Configuration.StorageKeys.employeeRole)
    }
    func getEmployeeId() -> String? {
        UserDefaults.standard.string(forKey: Configuration.StorageKeys.employeeId)
    }
    func getEmployeeName() -> String? {
        UserDefaults.standard.string(forKey: Configuration.StorageKeys.employeeName)
    }
}

// MARK: – Notification.Name

extension Notification.Name {
    static let didLogoutUser = Notification.Name("didLogoutUser")
}
