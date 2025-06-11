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
    private let biometricService = BiometricAuthService.shared

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
                #if DEBUG
                print("\n" + String(repeating: "=", count: 60))
                print("🎉 LOGIN SUCCESS - STARTING TOKEN STORAGE")
                print(String(repeating: "=", count: 60))
                print("👤 User: \(auth.name)")
                print("🎭 Role: \(auth.role)")
                print("🆔 Employee ID: \(auth.employeeId)")
                print("🔑 Token received: \(String(auth.token.prefix(20)))...")
                print("📏 Token length: \(auth.token.count) characters")
                print("📅 Timestamp: \(Date())")
                print(String(repeating: "-", count: 40))
                #endif
                
                // Store authentication data with detailed logging
                self?.saveWithDetailedLogging(auth: auth)
                
                // Set appropriate API service token based on role
                switch auth.role {
                case "byggeleder":
                    ManagerAPIService.shared.authToken = auth.token
                    #if DEBUG
                    print("✅ Token set for ManagerAPIService")
                    #endif
                case "arbejder", "chef", "system":
                    WorkerAPIService.shared.authToken = auth.token
                    #if DEBUG
                    print("✅ Token set for WorkerAPIService")
                    #endif
                default:
                    #if DEBUG
                    print("⚠️ Unknown role: \(auth.role) - no API service configured")
                    #endif
                }
                
                // ✅ DODANE: Wyślij notyfikację o udanym logowaniu
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .didLoginUser, object: nil, userInfo: [
                        "employeeId": auth.employeeId,
                        "name": auth.name,
                        "role": auth.role
                    ])
                    
                    #if DEBUG
                    print("📢 Posted login success notification")
                    #endif
                }
                
                #if DEBUG
                // Verify storage after a small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.verifyTokenStorageAfterLogin()
                }
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

    /// Login using biometric authentication
    func loginWithBiometric() async throws -> AuthResponse {
        #if DEBUG
        print("[AuthService] 🔐 Starting biometric login...")
        #endif
        
        // Authenticate with biometric
        let (email, password) = try await biometricService.authenticateWithBiometric()
        
        #if DEBUG
        print("[AuthService] ✅ Biometric authentication successful, proceeding with login...")
        #endif
        
        // Use the retrieved credentials to login
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = login(email: email, password: password)
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { authResponse in
                        continuation.resume(returning: authResponse)
                        cancellable?.cancel()
                    }
                )
        }
    }

    /// Enable biometric authentication after successful login
    func enableBiometric(email: String, password: String) throws {
        try biometricService.storeCredentialsForBiometric(email: email, password: password)
    }

    /// Check if biometric authentication is available and enabled
    var isBiometricAvailable: Bool {
        return biometricService.isBiometricAvailable()
    }

    var isBiometricEnabled: Bool {
        return biometricService.isBiometricEnabled
    }

    var biometricType: String {
        return biometricService.biometricType
    }

    /// Disable biometric authentication
    func disableBiometric() {
        biometricService.removeStoredCredentials()
    }

    /// Check if we should prompt user to enable biometric
    func shouldPromptForBiometric(email: String, password: String) async -> Bool {
        return await biometricService.promptToEnableBiometric(email: email, password: password)
    }

    // MARK: – Enhanced Persistence

    private func saveWithDetailedLogging(auth: AuthResponse) {
        #if DEBUG
        print("\n📦 STARTING DATA STORAGE PROCESS")
        print(String(repeating: "-", count: 35))
        #endif
        
        // Step 1: Store token in keychain
        #if DEBUG
        print("1️⃣ Storing token in keychain...")
        print("   Token to store: \(String(auth.token.prefix(15)))...")
        print("   Token length: \(auth.token.count) characters")
        print("   Storage key: \(Configuration.StorageKeys.authToken)")
        #endif
        
        let storeResult = KeychainService.shared.storeToken(auth.token)
        
        #if DEBUG
        if storeResult {
            print("   ✅ Token stored in keychain successfully")
            
            // Immediate verification
            if let retrievedToken = KeychainService.shared.getToken() {
                if retrievedToken == auth.token {
                    print("   ✅ Immediate verification: Token matches")
                } else {
                    print("   ❌ Immediate verification: Token MISMATCH!")
                    print("      Stored: \(String(auth.token.prefix(20)))...")
                    print("      Retrieved: \(String(retrievedToken.prefix(20)))...")
                }
            } else {
                print("   ❌ Immediate verification: Cannot retrieve token!")
            }
        } else {
            print("   ❌ CRITICAL: Failed to store token in keychain!")
            
            // Try to diagnose the issue
            print("   🔍 Diagnosing keychain issue...")
            let healthCheck = self.performKeychainHealthCheck()
            print("   🏥 Keychain health: \(healthCheck ? "OK" : "FAILED")")
        }
        #endif
        
        // Step 2: Store user data in UserDefaults
        #if DEBUG
        print("2️⃣ Storing user data in UserDefaults...")
        #endif
        
        UserDefaults.standard.set(auth.employeeId, forKey: Configuration.StorageKeys.employeeId)
        UserDefaults.standard.set(auth.name, forKey: Configuration.StorageKeys.employeeName)
        UserDefaults.standard.set(auth.role, forKey: Configuration.StorageKeys.employeeRole)
        
        // Force synchronize
        UserDefaults.standard.synchronize()
        
        #if DEBUG
        print("   ✅ UserDefaults data stored and synchronized")
        print("      Employee ID: \(auth.employeeId)")
        print("      Name: \(auth.name)")
        print("      Role: \(auth.role)")
        
        print(String(repeating: "-", count: 35))
        print("📦 DATA STORAGE PROCESS COMPLETE")
        print(String(repeating: "=", count: 60) + "\n")
        #endif
    }

    // MARK: - Enhanced Token Retrieval

    func getSavedToken() -> String? {
        #if DEBUG
        print("[AuthService] 🔍 Attempting to retrieve saved token...")
        #endif
        
        let token = KeychainService.shared.getToken()
        
        #if DEBUG
        if let tokenValue = token {
            print("[AuthService] ✅ Token retrieved from keychain: \(String(tokenValue.prefix(10)))...")
            print("[AuthService] ✅ Token length: \(tokenValue.count) characters")
        } else {
            print("[AuthService] ⚠️ No token found in keychain")
            // Additional debugging
            print("[AuthService] 🔍 Performing keychain debug check...")
            KeychainService.shared.debugKeychainState()
        }
        #endif
        
        return token
    }

    // MARK: - Enhanced Login Status Check

    var isLoggedIn: Bool {
        #if DEBUG
        print("[AuthService] 🔍 === LOGIN STATUS CHECK ===")
        #endif
        
        // Step 1: Check for token in keychain
        guard let token = getSavedToken(), !token.isEmpty else {
            #if DEBUG
            print("[AuthService] ❌ No token in keychain")
            
            // Additional debugging - check if we have user data but no token
            if let role = getEmployeeRole(), !role.isEmpty {
                print("[AuthService] ⚠️ Have user role (\(role)) but no token - possible keychain issue!")
                
                // Try to get token from memory as fallback
                let memoryToken: String?
                switch role {
                case "byggeleder":
                    memoryToken = ManagerAPIService.shared.authToken
                case "arbejder", "chef", "system":
                    memoryToken = WorkerAPIService.shared.authToken
                default:
                    memoryToken = nil
                }
                
                if let memToken = memoryToken {
                    print("[AuthService] 🔄 Found token in memory, re-storing to keychain...")
                    _ = KeychainService.shared.storeToken(memToken)
                    // Recursive call to re-check
                    return self.isLoggedIn
                }
            }
            
            // Perform keychain health check if no token found
            let healthCheck = self.performKeychainHealthCheck()
            print("[AuthService] 🏥 Keychain health: \(healthCheck ? "OK" : "FAILED")")
            #endif
            return false
        }
        
        // Step 2: Check for user role
        guard let role = getEmployeeRole(), !role.isEmpty else {
            #if DEBUG
            print("[AuthService] ❌ No user role found")
            #endif
            return false
        }
        
        #if DEBUG
        print("[AuthService] ✅ Token and role found")
        print("[AuthService] ✅ Role: \(role)")
        print("[AuthService] ✅ Token: \(String(token.prefix(10)))...")
        #endif
        
        // Step 3: Ensure the appropriate API service has the token
        let tokenWasSet = ensureAPIServiceHasToken(role: role, token: token)
        
        #if DEBUG
        print("[AuthService] ✅ API service token set: \(tokenWasSet)")
        print("[AuthService] 🔍 === LOGIN STATUS: TRUE ===")
        #endif
        
        return true
    }

    /// Ensures the appropriate API service has the auth token
    private func ensureAPIServiceHasToken(role: String, token: String) -> Bool {
        switch role {
        case "byggeleder":
            if ManagerAPIService.shared.authToken == nil {
                ManagerAPIService.shared.authToken = token
                #if DEBUG
                print("[AuthService] 🔄 Restored token to ManagerAPIService")
                #endif
            }
            return ManagerAPIService.shared.authToken != nil
            
        case "arbejder", "chef", "system":
            if WorkerAPIService.shared.authToken == nil {
                WorkerAPIService.shared.authToken = token
                #if DEBUG
                print("[AuthService] 🔄 Restored token to WorkerAPIService")
                #endif
            }
            return WorkerAPIService.shared.authToken != nil
            
        default:
            #if DEBUG
            print("[AuthService] ❌ Unknown role: \(role), cannot set API token")
            #endif
            return false
        }
    }

    func logout() {
        #if DEBUG
        print("[AuthService] 🚪 Starting logout process...")
        #endif
        
        // Clear tokens from both services
        ManagerAPIService.shared.authToken = nil
        WorkerAPIService.shared.authToken = nil
        
        #if DEBUG
        print("[AuthService] ✅ API service tokens cleared")
        #endif
        
        // Delete token from keychain
        let deleteResult = KeychainService.shared.deleteToken()
        
        if deleteResult {
            #if DEBUG
            print("[AuthService] ✅ Token deleted from keychain")
            #endif
        } else {
            #if DEBUG
            print("[AuthService] ⚠️ No token to delete or failed to delete from keychain")
            #endif
        }
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: Configuration.StorageKeys.employeeId)
        UserDefaults.standard.removeObject(forKey: Configuration.StorageKeys.employeeName)
        UserDefaults.standard.removeObject(forKey: Configuration.StorageKeys.employeeRole)
        UserDefaults.standard.synchronize()
        
        #if DEBUG
        print("[AuthService] ✅ UserDefaults cleared")
        #endif
        
        // Post logout notification
        NotificationCenter.default.post(name: .didLogoutUser, object: nil)
        
        #if DEBUG
        print("[AuthService] ✅ Logout completed successfully")
        #endif
    }

    // MARK: – Odczyt danych

    func getEmployeeRole() -> String? {
        let role = UserDefaults.standard.string(forKey: Configuration.StorageKeys.employeeRole)
        #if DEBUG
        if let roleValue = role {
            print("[AuthService] 🔍 Employee role: \(roleValue)")
        } else {
            print("[AuthService] 🔍 No employee role found")
        }
        #endif
        return role
    }
    
    func getEmployeeId() -> String? {
        let id = UserDefaults.standard.string(forKey: Configuration.StorageKeys.employeeId)
        #if DEBUG
        if let idValue = id {
            print("[AuthService] 🔍 Employee ID: \(idValue)")
        } else {
            print("[AuthService] 🔍 No employee ID found")
        }
        #endif
        return id
    }
    
    func getEmployeeName() -> String? {
        let name = UserDefaults.standard.string(forKey: Configuration.StorageKeys.employeeName)
        #if DEBUG
        if let nameValue = name {
            print("[AuthService] 🔍 Employee name: \(nameValue)")
        } else {
            print("[AuthService] 🔍 No employee name found")
        }
        #endif
        return name
    }
    
    // MARK: - Debug & Verification
    
    #if DEBUG
    /// Post-login verification method
    private func verifyTokenStorageAfterLogin() {
        print("\n🔍 POST-LOGIN VERIFICATION")
        print(String(repeating: "-", count: 30))
        
        // Test 1: Keychain retrieval
        print("1️⃣ Testing keychain retrieval...")
        if let keychainToken = KeychainService.shared.getToken() {
            print("   ✅ Token found in keychain: \(String(keychainToken.prefix(15)))...")
        } else {
            print("   ❌ No token in keychain!")
        }
        
        // Test 2: AuthService retrieval
        print("2️⃣ Testing AuthService retrieval...")
        if let authToken = self.getSavedToken() {
            print("   ✅ AuthService can retrieve token: \(String(authToken.prefix(15)))...")
        } else {
            print("   ❌ AuthService cannot retrieve token!")
        }
        
        // Test 3: UserDefaults
        print("3️⃣ Testing UserDefaults...")
        let employeeId = self.getEmployeeId()
        let employeeRole = self.getEmployeeRole()
        print("   Employee ID: \(employeeId ?? "❌ nil")")
        print("   Employee Role: \(employeeRole ?? "❌ nil")")
        
        // Test 4: Overall login status
        print("4️⃣ Testing overall login status...")
        let isLoggedIn = self.isLoggedIn
        print("   Login status: \(isLoggedIn ? "✅ LOGGED IN" : "❌ NOT LOGGED IN")")
        
        // Test 5: API Service tokens
        print("5️⃣ Testing API service tokens...")
        if let role = employeeRole {
            switch role {
            case "byggeleder":
                let hasToken = ManagerAPIService.shared.authToken != nil
                print("   ManagerAPIService token: \(hasToken ? "✅ SET" : "❌ NOT SET")")
            case "arbejder", "chef", "system":
                let hasToken = WorkerAPIService.shared.authToken != nil
                print("   WorkerAPIService token: \(hasToken ? "✅ SET" : "❌ NOT SET")")
            default:
                print("   Unknown role for API service check")
            }
        }
        
        print(String(repeating: "-", count: 30))
        print("🔍 POST-LOGIN VERIFICATION COMPLETE\n")
    }
    
    /// Enhanced keychain health check method
    func performKeychainHealthCheck() -> Bool {
        let testKey = "health_check_\(UUID().uuidString)"
        let testValue = "test_\(Date().timeIntervalSince1970)"
        
        print("[AuthService] 🏥 Starting keychain health check...")
        
        // Test 1: Store
        guard KeychainService.shared.storeString(testValue, forKey: testKey) else {
            print("[AuthService] ❌ Health check: Store operation failed")
            return false
        }
        print("[AuthService] ✅ Health check: Store operation passed")
        
        // Test 2: Retrieve
        guard let retrieved = KeychainService.shared.getString(forKey: testKey),
              retrieved == testValue else {
            print("[AuthService] ❌ Health check: Retrieve operation failed")
            _ = KeychainService.shared.deleteItem(forKey: testKey) // Cleanup
            return false
        }
        print("[AuthService] ✅ Health check: Retrieve operation passed")
        
        // Test 3: Delete
        guard KeychainService.shared.deleteItem(forKey: testKey) else {
            print("[AuthService] ❌ Health check: Delete operation failed")
            return false
        }
        print("[AuthService] ✅ Health check: Delete operation passed")
        
        print("[AuthService] ✅ Keychain health check: ALL TESTS PASSED")
        return true
    }
    
    /// Comprehensive debug method to check authentication state
    func debugAuthenticationState() {
        print("[AuthService] 🔍 === AUTHENTICATION DEBUG STATE ===")
        print("[AuthService] 🔍 App Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        print("[AuthService] 🔍 Base URL: \(baseURL)")
        
        // Check keychain
        print("[AuthService] 🔍 Keychain state:")
        KeychainService.shared.debugKeychainState()
        
        // Check UserDefaults
        print("[AuthService] 🔍 UserDefaults state:")
        print("[AuthService] 🔍   Employee ID: \(getEmployeeId() ?? "nil")")
        print("[AuthService] 🔍   Name: \(getEmployeeName() ?? "nil")")
        print("[AuthService] 🔍   Role: \(getEmployeeRole() ?? "nil")")
        
        // Check API services
        print("[AuthService] 🔍 API Services state:")
        print("[AuthService] 🔍   ManagerAPIService token: \(ManagerAPIService.shared.authToken != nil ? "SET" : "NOT SET")")
        print("[AuthService] 🔍   WorkerAPIService token: \(WorkerAPIService.shared.authToken != nil ? "SET" : "NOT SET")")
        
        // Overall login status
        print("[AuthService] 🔍 Overall login status: \(isLoggedIn)")
        
        print("[AuthService] 🔍 === END AUTHENTICATION DEBUG ===")
    }
    
    /// Force clear all authentication data for debugging
    func debugClearAllAuthData() {
        print("[AuthService] 🧹 === CLEARING ALL AUTH DATA (DEBUG) ===")
        
        // Clear keychain
        KeychainService.shared.clearAllKeychainItems()
        
        // Clear UserDefaults
        let keysToRemove = [
            Configuration.StorageKeys.employeeId,
            Configuration.StorageKeys.employeeName,
            Configuration.StorageKeys.employeeRole
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        
        // Clear API service tokens
        ManagerAPIService.shared.authToken = nil
        WorkerAPIService.shared.authToken = nil
        
        print("[AuthService] 🧹 All authentication data cleared")
        print("[AuthService] 🧹 === CLEAR COMPLETE ===")
    }
    
    /// Manual test method for debugging
    func testTokenStorageManually() {
        print("\n🧪 MANUAL TOKEN STORAGE TEST")
        print(String(repeating: "=", count: 40))
        
        let testAuth = AuthResponse(
            token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.signature",
            employeeId: "TEST123",
            name: "Test User",
            role: "arbejder"
        )
        
        print("📝 Testing with fake auth response...")
        saveWithDetailedLogging(auth: testAuth)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.verifyTokenStorageAfterLogin()
            
            // Cleanup
            print("🧹 Cleaning up test data...")
            _ = KeychainService.shared.deleteToken()
            UserDefaults.standard.removeObject(forKey: Configuration.StorageKeys.employeeId)
            UserDefaults.standard.removeObject(forKey: Configuration.StorageKeys.employeeName)
            UserDefaults.standard.removeObject(forKey: Configuration.StorageKeys.employeeRole)
            print("✅ Test cleanup complete")
        }
    }
    
    /// For debugging: tests the token by making a simple API call
    func testToken() -> AnyPublisher<String, BaseAPIService.APIError> {
        guard let role = getEmployeeRole() else {
            print("[AuthService] ❌ No role found for token test")
            return Fail(error: BaseAPIService.APIError.unknown).eraseToAnyPublisher()
        }
        
        print("[AuthService] 🧪 Testing token for role: \(role)")
        
        switch role {
        case "byggeleder":
            return ManagerAPIService.shared.testConnection()
        case "arbejder", "chef", "system":
            return WorkerAPIService.shared.testConnection()
        default:
            print("[AuthService] ❌ Unknown role for token test: \(role)")
            return Fail(error: BaseAPIService.APIError.unknown).eraseToAnyPublisher()
        }
    }
    #endif
}

// MARK: – Notification.Name

extension Notification.Name {
    static let didLogoutUser = Notification.Name("didLogoutUser")
    static let didLoginUser = Notification.Name("didLoginUser")
}
