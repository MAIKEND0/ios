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
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, BaseAPIService.APIError> {
        let creds = LoginCredentials(email: email, password: password)
        let urlString = baseURL + "/api/app-login"
        guard let url = URL(string: urlString) else {
            return Fail(error: BaseAPIService.APIError.invalidURL).eraseToAnyPublisher()
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        do {
            req.httpBody = try JSONEncoder().encode(creds)
        } catch {
            return Fail(error: BaseAPIService.APIError.decodingError(error)).eraseToAnyPublisher()
        }

        #if DEBUG
        print("[AuthService] → POST \(urlString)")
        print("[AuthService] → Login attempt for: \(email)")
        #endif

        return session.dataTaskPublisher(for: req)
            .mapError { BaseAPIService.APIError.networkError($0) }
            .flatMap { data, resp -> AnyPublisher<Data, BaseAPIService.APIError> in
                guard let http = resp as? HTTPURLResponse else {
                    return Fail(error: BaseAPIService.APIError.invalidResponse).eraseToAnyPublisher()
                }
                #if DEBUG
                print("[AuthService] ← Status: \(http.statusCode)")
                if let respStr = String(data: data, encoding: .utf8) {
                    print("[AuthService] ← Response: \(respStr)")
                }
                #endif

                if (200...299).contains(http.statusCode) {
                    return Just(data)
                        .setFailureType(to: BaseAPIService.APIError.self)
                        .eraseToAnyPublisher()
                } else {
                    let raw = String(data: data, encoding: .utf8) ?? ""
                    let msg = raw.isEmpty ? "Code \(http.statusCode)" : "\(raw.prefix(200))…"
                    return Fail(error: BaseAPIService.APIError.serverError(http.statusCode, msg))
                        .eraseToAnyPublisher()
                }
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .mapError { ($0 as? BaseAPIService.APIError) ?? .decodingError($0) }
            .handleEvents(receiveOutput: { [weak self] auth in
                // Store token as-is, without adding Bearer prefix
                // The appropriate APIService will add the Bearer prefix when needed
                switch auth.role {
                case "byggeleder":
                    ManagerAPIService.shared.authToken = auth.token
                case "arbejder", "chef", "system":
                    WorkerAPIService.shared.authToken = auth.token
                default:
                    #if DEBUG
                    print("[AuthService] ⚠️ Unknown role: \(auth.role)")
                    #endif
                }
                self?.save(auth: auth)
                
                #if DEBUG
                print("[AuthService] ✅ Login successful for: \(email)")
                print("[AuthService] ✅ Token received: \(String(auth.token.prefix(15)))...")
                #endif
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
        // Store token as-is in keychain
        let storeResult = KeychainService.shared.storeToken(auth.token)
        
        #if DEBUG
        if storeResult {
            print("[AuthService] ✅ Token stored in keychain")
        } else {
            print("[AuthService] ❌ Failed to store token in keychain")
        }
        #endif
        
        UserDefaults.standard.set(auth.employeeId, forKey: Configuration.StorageKeys.employeeId)
        UserDefaults.standard.set(auth.name, forKey: Configuration.StorageKeys.employeeName)
        UserDefaults.standard.set(auth.role, forKey: Configuration.StorageKeys.employeeRole)
    }

    func getSavedToken() -> String? {
        let token = KeychainService.shared.getToken()
        
        #if DEBUG
        if let tokenValue = token {
            print("[AuthService] ✅ Token retrieved from keychain: \(String(tokenValue.prefix(10)))...")
        } else {
            print("[AuthService] ⚠️ No token found in keychain")
        }
        #endif
        
        return token
    }

    var isLoggedIn: Bool {
        if let token = getSavedToken() {
            let role = getEmployeeRole()
            switch role {
            case "byggeleder":
                ManagerAPIService.shared.authToken = ManagerAPIService.shared.authToken ?? token
            case "arbejder", "chef", "system":
                WorkerAPIService.shared.authToken = WorkerAPIService.shared.authToken ?? token
            default:
                #if DEBUG
                print("[AuthService] ⚠️ Unknown role, cannot set token")
                #endif
                return false
            }
            return true
        }
        return false
    }

    func logout() {
        #if DEBUG
        print("[AuthService] Logging out user")
        #endif
        
        // Clear tokens from both services
        ManagerAPIService.shared.authToken = nil
        WorkerAPIService.shared.authToken = nil
        
        let deleteResult = KeychainService.shared.deleteToken()
        
        #if DEBUG
        if deleteResult {
            print("[AuthService] ✅ Token deleted from keychain")
        } else {
            print("[AuthService] ⚠️ No token to delete or failed to delete")
        }
        #endif
        
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
    
    // MARK: - Debug
    
    #if DEBUG
    /// For debugging: tests the token by making a simple API call
    func testToken() -> AnyPublisher<String, BaseAPIService.APIError> {
        let role = getEmployeeRole()
        switch role {
        case "byggeleder":
            return ManagerAPIService.shared.testConnection()
        case "arbejder", "chef", "system":
            return WorkerAPIService.shared.testConnection()
        default:
            #if DEBUG
            print("[AuthService] ⚠️ Unknown role, cannot test token")
            #endif
            return Fail(error: BaseAPIService.APIError.unknown).eraseToAnyPublisher()
        }
    }
    #endif
}

// MARK: – Notification.Name

extension Notification.Name {
    static let didLogoutUser = Notification.Name("didLogoutUser")
}
