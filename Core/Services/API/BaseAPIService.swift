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
    
    func applyAuthToken(to request: inout URLRequest) {
        if let token = authToken, !token.isEmpty {
            let tokenValue = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
            request.setValue(tokenValue, forHTTPHeaderField: "Authorization")
            #if DEBUG
            print("[BaseAPIService] Dodano token do żądania: \(request.url?.absoluteString ?? "")")
            #endif
        } else {
            refreshTokenFromKeychain()
            if let token = authToken, !token.isEmpty {
                let tokenValue = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
                request.setValue(tokenValue, forHTTPHeaderField: "Authorization")
                #if DEBUG
                print("[BaseAPIService] Dodano odświeżony token do żądania")
                #endif
            } else {
                #if DEBUG
                print("[BaseAPIService] ⚠️ Brak dostępnego tokenu dla żądania: \(request.url?.absoluteString ?? "")")
                #endif
            }
        }
    }

    // MARK: – Generic Request

    func makeRequest<T: Encodable>(
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
        #endif
        
        return session.dataTaskPublisher(for: request)
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

    func jsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
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
