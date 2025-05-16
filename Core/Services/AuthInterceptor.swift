//
//  AuthInterceptor.swift
//  KSR Cranes App
//

import Foundation
import Combine

/// Handles authentication on all API requests
final class AuthInterceptor {
    
    static let shared = AuthInterceptor()
    
    private init() {
        // Listen for authentication failures
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthFailure),
            name: .authenticationFailure,
            object: nil
        )
    }
    
    /// Intercepts and modifies a request to add authentication headers
    func intercept(_ request: inout URLRequest) {
        let role = AuthService.shared.getEmployeeRole()
        var token: String?
        
        // Wybierz odpowiedni serwis na podstawie roli użytkownika
        switch role {
        case "byggeleder":
            token = ManagerAPIService.shared.authToken
        case "arbejder", "chef", "system":
            token = WorkerAPIService.shared.authToken
        default:
            token = nil
        }
        
        // Sprawdź, czy token istnieje w pamięci serwisu
        if let token = token {
            // Upewnij się, że token ma prefiks "Bearer "
            let tokenValue = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
            request.setValue(tokenValue, forHTTPHeaderField: "Authorization")
            
            #if DEBUG
            print("[AuthInterceptor] Added auth token to \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "")")
            #endif
        } else {
            // Spróbuj pobrać token z keychain
            if let keychainToken = KeychainService.shared.getToken() {
                let tokenValue = keychainToken.hasPrefix("Bearer ") ? keychainToken : "Bearer \(keychainToken)"
                request.setValue(tokenValue, forHTTPHeaderField: "Authorization")
                
                // Zaktualizuj token w odpowiednim serwisie
                switch role {
                case "byggeleder":
                    ManagerAPIService.shared.authToken = keychainToken
                case "arbejder", "chef", "system":
                    WorkerAPIService.shared.authToken = keychainToken
                default:
                    break
                }
                
                #if DEBUG
                print("[AuthInterceptor] Added token from keychain to request")
                #endif
            } else {
                #if DEBUG
                print("[AuthInterceptor] ⚠️ No token available for request: \(request.url?.absoluteString ?? "")")
                #endif
            }
        }
    }
    
    /// Handles 401 response by triggering a reauth flow
    func handle401Response(for request: URLRequest) -> AnyPublisher<Data, BaseAPIService.APIError> {
        #if DEBUG
        print("[AuthInterceptor] 🔴 Received 401 error, token might be expired")
        #endif
        
        // Try to refresh token or force re-login
        NotificationCenter.default.post(name: .authenticationFailure, object: nil)
        
        return Fail(error: BaseAPIService.APIError.networkError(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication expired, please log in again"])))
            .eraseToAnyPublisher()
    }
    
    @objc private func handleAuthFailure() {
        #if DEBUG
        print("[AuthInterceptor] 🔄 Handling auth failure, logging out user")
        #endif
        
        // Perform logout on main thread
        DispatchQueue.main.async {
            AuthService.shared.logout()
        }
    }
}
