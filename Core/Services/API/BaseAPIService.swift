//
//  BaseAPIService.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 16/05/2025.
//

import Foundation
import Combine

class BaseAPIService {
    let baseURL: String
    let session: URLSession
    var authToken: String?
    
    // ✅ Sesja z długim timeout dla create/update operations
    private lazy var longTimeoutSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0  // 60 sekund zamiast 30
        config.timeoutIntervalForResource = 120.0 // 2 minuty na cały transfer
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        return URLSession(configuration: config)
    }()
    
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

    init() {
        self.baseURL = Configuration.API.baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
        
        refreshTokenFromKeychain()
    }
    
    // MARK: - Token Management
    
    func refreshTokenFromKeychain() {
        if let token = KeychainService.shared.getToken() {
            self.authToken = token
            #if DEBUG
            print("[BaseAPIService] Token załadowany z keychain")
            #endif
        }
    }
    
    // ✅ Method for consistency
    func addAuthToken(to request: URLRequest) -> URLRequest {
        var authenticatedRequest = request
        
        if let token = authToken, !token.isEmpty {
            let tokenValue = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
            authenticatedRequest.setValue(tokenValue, forHTTPHeaderField: "Authorization")
            #if DEBUG
            print("[BaseAPIService] Dodano token do żądania: \(request.url?.absoluteString ?? "")")
            #endif
        } else {
            refreshTokenFromKeychain()
            if let token = authToken, !token.isEmpty {
                let tokenValue = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
                authenticatedRequest.setValue(tokenValue, forHTTPHeaderField: "Authorization")
                #if DEBUG
                print("[BaseAPIService] Dodano odświeżony token do żądania")
                #endif
            } else {
                #if DEBUG
                print("[BaseAPIService] ⚠️ Brak dostępnego tokenu dla żądania: \(request.url?.absoluteString ?? "")")
                #endif
            }
        }
        
        return authenticatedRequest
    }
    
    // ✅ Existing method for compatibility
    func applyAuthToken(to request: inout URLRequest) {
        request = addAuthToken(to: request)
    }

    // MARK: - ✅ performRequest method used by ChefProjectsAPIService
    
    func performRequest<T: Codable>(
        _ request: URLRequest,
        decoder: JSONDecoder = BaseAPIService.createAPIDecoder()
    ) -> AnyPublisher<T, APIError> {
        
        #if DEBUG
        print("[BaseAPIService] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "Unknown URL")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("[BaseAPIService] Request body: \(bodyString)")
        }
        #endif
        
        return URLSession.shared.dataTaskPublisher(for: addAuthToken(to: request))
            .tryMap { [weak self] data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                #if DEBUG
                print("[BaseAPIService] Status: \(httpResponse.statusCode)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[BaseAPIService] Response: \(jsonString)")
                }
                #endif
                
                // Handle different status codes
                switch httpResponse.statusCode {
                case 200...299:
                    // Success - try to decode
                    do {
                        return try decoder.decode(T.self, from: data)
                    } catch {
                        #if DEBUG
                        print("[BaseAPIService] Decoding error: \(error)")
                        if let decodingError = error as? DecodingError {
                            print("[BaseAPIService] Decoding details: \(decodingError)")
                        }
                        #endif
                        throw APIError.decodingError(error)
                    }
                    
                case 401:
                    #if DEBUG
                    print("[BaseAPIService] ⚠️ 401 Unauthorized - token może być wygasły")
                    #endif
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .authTokenExpired, object: nil)
                    }
                    throw APIError.serverError(401, "Authentication expired. Please log in again.")
                    
                case 400...499:
                    // Client error
                    let errorMessage = self?.parseErrorMessage(from: data) ?? "Client error"
                    throw APIError.serverError(httpResponse.statusCode, errorMessage)
                    
                case 500...599:
                    // Server error
                    let errorMessage = self?.parseErrorMessage(from: data) ?? "Server error"
                    throw APIError.serverError(httpResponse.statusCode, errorMessage)
                    
                default:
                    throw APIError.invalidResponse
                }
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if let urlError = error as? URLError {
                    return APIError.networkError(urlError)
                } else {
                    return APIError.unknown
                }
            }
            .eraseToAnyPublisher()
    }
    
    // ✅ Helper method to parse error messages
    private func parseErrorMessage(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? String {
            return error
        } else if let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let msg = message["message"] as? String {
            return msg
        }
        return nil
    }

    // MARK: – ✅ Generic Request (existing functionality)
    
    // ✅ Retry logic dla network timeouts
    func makeRequestWithRetry<T: Encodable>(
        endpoint: String,
        method: String,
        body: T?,
        retryCount: Int = 2
    ) -> AnyPublisher<Data, APIError> {
        
        makeRequest(endpoint: endpoint, method: method, body: body, useLongTimeout: true)
            .catch { error -> AnyPublisher<Data, APIError> in
                guard retryCount > 0 else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                
                // Retry tylko dla network timeouts i connection lost
                switch error {
                case .networkError(let urlError as URLError):
                    if urlError.code == .timedOut || urlError.code == .networkConnectionLost {
                        #if DEBUG
                        print("[BaseAPIService] ⚠️ Network error, retrying... (\(retryCount) attempts left)")
                        print("[BaseAPIService] Error: \(error)")
                        #endif
                        
                        return self.makeRequestWithRetry(
                            endpoint: endpoint,
                            method: method,
                            body: body,
                            retryCount: retryCount - 1
                        )
                        .delay(for: .seconds(2), scheduler: DispatchQueue.global())
                        .eraseToAnyPublisher()
                    }
                default:
                    break
                }
                
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // ✅ Dodano opcjonalny długi timeout
    func makeRequest<T: Encodable>(
        endpoint: String,
        method: String,
        body: T?,
        useLongTimeout: Bool = false
    ) -> AnyPublisher<Data, APIError> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        applyAuthToken(to: &request)
        
        if method != "GET", let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(body)
                #if DEBUG
                if let jsonStr = String(data: request.httpBody!, encoding: .utf8) {
                    print("[BaseAPIService] Request body: \(jsonStr)")
                }
                #endif
            } catch {
                return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
            }
        }
        
        #if DEBUG
        print("[BaseAPIService] \(method) \(url)")
        if useLongTimeout {
            print("[BaseAPIService] Using long timeout (60s)")
        }
        #endif
        
        // ✅ UŻYJ ODPOWIEDNIEJ SESJI NA PODSTAWIE TIMEOUT
        let sessionToUse = useLongTimeout ? longTimeoutSession : session
        
        return sessionToUse.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, resp -> AnyPublisher<Data, APIError> in
                guard let http = resp as? HTTPURLResponse else {
                    return Fail(error: APIError.invalidResponse).eraseToAnyPublisher()
                }
                
                #if DEBUG
                print("[BaseAPIService] Status: \(http.statusCode)")
                if let respStr = String(data: data, encoding: .utf8) {
                    print("[BaseAPIService] Response: \(respStr.prefix(200))")
                }
                #endif
                
                if (200...299).contains(http.statusCode) {
                    return Just(data)
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                } else if http.statusCode == 401 {
                    #if DEBUG
                    print("[BaseAPIService] ⚠️ 401 Unauthorized - token może być wygasły")
                    #endif
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .authTokenExpired, object: nil)
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

    // ✅ Updated JSON decoder
    func jsonDecoder() -> JSONDecoder {
        return BaseAPIService.createAPIDecoder()
    }
    
    // ✅ Static method to create API decoder (prevents conflicts)
    static func createAPIDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        // ✅ CUSTOM DATE DECODING - handles API's date format
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try API format: "2025-06-01T14:53:05.000Z"
            let apiFormatter = DateFormatter()
            apiFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            apiFormatter.timeZone = TimeZone(abbreviation: "UTC")
            
            if let date = apiFormatter.date(from: dateString) {
                return date
            }
            
            // Try without milliseconds: "2025-06-01T14:53:05Z"
            apiFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            if let date = apiFormatter.date(from: dateString) {
                return date
            }
            
            // Try date only: "2025-06-01T00:00:00.000Z"
            apiFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            if let date = apiFormatter.date(from: dateString) {
                return date
            }
            
            // Fallback to ISO8601
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Last fallback - basic ISO8601
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date from: \(dateString)"
            )
        }
        
        return decoder
    }
}

// MARK: - ✅ Notification extension for auth failures

extension Notification.Name {
    static let authTokenExpired = Notification.Name("AuthTokenExpired")
}

// MARK: - ✅ Debug helper for testing decoding

#if DEBUG
extension BaseAPIService {
    static func testProjectDecoding() {
        let sampleJSON = """
        {
          "project": {
            "project_id": 7,
            "title": "Stejlepladsen",
            "description": "Two Cranes",
            "start_date": "2025-06-01T00:00:00.000Z",
            "end_date": "2025-07-15T00:00:00.000Z",
            "status": "aktiv",
            "customer_id": 4,
            "street": "Sejlklubvej 6, 2450 København",
            "city": "København",
            "zip": "2450",
            "isActive": true,
            "created_at": "2025-06-01T14:53:05.000Z",
            "Customers": {
              "customer_id": 4,
              "name": "Heidelberg Materials",
              "contact_email": "test@heidelberg.com",
              "phone": null,
              "address": null,
              "cvr_nr": null,
              "created_at": "2025-05-31T13:31:23.000Z",
              "logo_url": null,
              "logo_uploaded_at": null
            }
          }
        }
        """.data(using: .utf8)!
        
        do {
            let response = try createAPIDecoder().decode(CreateProjectResponse.self, from: sampleJSON)
            print("✅ [BaseAPIService] Decoding test successful!")
            print("✅ Project: \(response.project.title)")
            print("✅ Status: \(response.project.status.displayName)")
            print("✅ Customer: \(response.project.customer?.name ?? "No customer")")
            print("✅ API Status Raw Value: \(response.project.status.rawValue)")
        } catch {
            print("❌ [BaseAPIService] Decoding test failed: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Key '\(key.stringValue)' not found in \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("❌ Value of type \(type) not found in \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch for \(type) in \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error: \(error)")
                }
            }
        }
    }
    
    // ✅ Helper method for testing decoding
    static func decodeProjectResponse<T: Codable>(_ data: Data, as type: T.Type) throws -> T {
        return try createAPIDecoder().decode(type, from: data)
    }
}
#endif
