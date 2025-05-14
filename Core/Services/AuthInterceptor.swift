// Core/Services/AuthInterceptor.swift
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
        // Check if token exists in APIService
        if let token = APIService.shared.authToken {
            // Make sure token has "Bearer " prefix as the backend expects
            let tokenValue = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
            request.setValue(tokenValue, forHTTPHeaderField: "Authorization")
            
            #if DEBUG
            print("[AuthInterceptor] Added auth token to \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "")")
            #endif
        } else {
            // Try to get token from keychain
            if let token = KeychainService.shared.getToken() {
                let tokenValue = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
                request.setValue(tokenValue, forHTTPHeaderField: "Authorization")
                
                // Also update the token in APIService for future requests
                APIService.shared.authToken = token
                
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
    func handle401Response(for request: URLRequest) -> AnyPublisher<Data, APIError> {
        #if DEBUG
        print("[AuthInterceptor] 🔴 Received 401 error, token might be expired")
        #endif
        
        // Try to refresh token or force re-login
        NotificationCenter.default.post(name: .authenticationFailure, object: nil)
        
        return Fail(error: APIError.networkError(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication expired, please log in again"])))
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
