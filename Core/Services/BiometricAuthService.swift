import Foundation
import LocalAuthentication

class BiometricAuthService {
    static let shared = BiometricAuthService()
    private let context = LAContext()
    private let keychain = KeychainService.shared
    
    private init() {}
    
    // MARK: - Biometric Availability
    
    /// Check if biometric authentication is available on the device
    func isBiometricAvailable() -> Bool {
        var error: NSError?
        let isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if let error = error {
            print("[BiometricAuth] Biometric not available: \(error.localizedDescription)")
        }
        
        return isAvailable
    }
    
    /// Get the type of biometric available (Face ID or Touch ID)
    var biometricType: String {
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "None"
        case .opticID:
            return "Optic ID"
        @unknown default:
            return "Unknown"
        }
    }
    
    // MARK: - Biometric Settings
    
    /// Check if biometric authentication is enabled for the app
    var isBiometricEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "biometricAuthEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "biometricAuthEnabled")
        }
    }
    
    /// Store credentials for biometric authentication
    func storeCredentialsForBiometric(email: String, password: String) throws {
        guard isBiometricAvailable() else {
            throw BiometricError.notAvailable
        }
        
        // Store encrypted credentials in keychain
        guard keychain.storeString(password, forKey: "biometric_password"),
              keychain.storeString(email, forKey: "biometric_email") else {
            throw BiometricError.unknown(NSError(domain: "BiometricAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to store credentials"]))
        }
        
        // Enable biometric authentication
        isBiometricEnabled = true
        
        print("[BiometricAuth] Credentials stored for biometric authentication")
    }
    
    /// Remove stored credentials
    func removeStoredCredentials() {
        _ = keychain.deleteItem(forKey: "biometric_password")
        _ = keychain.deleteItem(forKey: "biometric_email")
        isBiometricEnabled = false
        
        print("[BiometricAuth] Stored credentials removed")
    }
    
    /// Get stored credentials if available
    func getStoredCredentials() -> (email: String, password: String)? {
        guard let email = keychain.getString(forKey: "biometric_email"),
              let password = keychain.getString(forKey: "biometric_password") else {
            return nil
        }
        
        return (email, password)
    }
    
    // MARK: - Biometric Authentication
    
    /// Authenticate using biometrics
    func authenticateWithBiometric(reason: String? = nil) async throws -> (email: String, password: String) {
        // Check if biometric is enabled
        guard isBiometricEnabled else {
            throw BiometricError.notEnabled
        }
        
        // Check if biometric is available
        guard isBiometricAvailable() else {
            throw BiometricError.notAvailable
        }
        
        // Check if we have stored credentials
        guard let credentials = getStoredCredentials() else {
            throw BiometricError.noStoredCredentials
        }
        
        // Create new context for this authentication
        let authContext = LAContext()
        authContext.localizedCancelTitle = "Cancel"
        
        // Set the reason for authentication
        let authReason = reason ?? "Authenticate to login to KSR Cranes"
        
        do {
            // Perform biometric authentication
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: authReason
            )
            
            if success {
                print("[BiometricAuth] Authentication successful")
                return credentials
            } else {
                throw BiometricError.authenticationFailed
            }
        } catch let error as LAError {
            throw handleLAError(error)
        } catch {
            throw BiometricError.unknown(error)
        }
    }
    
    /// Prompt user to enable biometric authentication after successful login
    func promptToEnableBiometric(email: String, password: String) async -> Bool {
        #if DEBUG
        print("[BiometricAuth] Checking if should prompt for biometric...")
        print("[BiometricAuth] - Is available: \(isBiometricAvailable())")
        print("[BiometricAuth] - Is enabled: \(isBiometricEnabled)")
        #endif
        
        // Check if biometric is available but not enabled
        guard isBiometricAvailable() && !isBiometricEnabled else {
            #if DEBUG
            print("[BiometricAuth] Not prompting - either not available or already enabled")
            #endif
            return false
        }
        
        // For testing, let's comment out the cooldown check
        #if DEBUG
        print("[BiometricAuth] Cooldown check disabled for testing")
        #else
        // Don't prompt if user has already been asked recently
        let lastPromptKey = "lastBiometricPromptDate"
        if let lastPrompt = UserDefaults.standard.object(forKey: lastPromptKey) as? Date,
           Date().timeIntervalSince(lastPrompt) < 7 * 24 * 60 * 60 { // 7 days
            return false
        }
        #endif
        
        // Store the prompt date
        let lastPromptKey = "lastBiometricPromptDate"
        UserDefaults.standard.set(Date(), forKey: lastPromptKey)
        
        #if DEBUG
        print("[BiometricAuth] Will prompt for biometric!")
        #endif
        
        // The UI will handle the actual prompt
        return true
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    /// Reset the biometric prompt date for testing
    func resetPromptDate() {
        UserDefaults.standard.removeObject(forKey: "lastBiometricPromptDate")
        print("[BiometricAuth] Prompt date reset for testing")
    }
    #endif
    
    // MARK: - Error Handling
    
    private func handleLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userFallback
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        default:
            return .unknown(error)
        }
    }
}

// MARK: - Biometric Errors

enum BiometricError: LocalizedError {
    case notAvailable
    case notEnabled
    case notEnrolled
    case noStoredCredentials
    case authenticationFailed
    case userCancelled
    case userFallback
    case lockout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnabled:
            return "Biometric authentication is not enabled"
        case .notEnrolled:
            return "No biometric data is enrolled. Please set up \(BiometricAuthService.shared.biometricType) in Settings"
        case .noStoredCredentials:
            return "No stored credentials found. Please login with your email and password first"
        case .authenticationFailed:
            return "Biometric authentication failed. Please try again"
        case .userCancelled:
            return "Authentication was cancelled"
        case .userFallback:
            return "Please enter your password"
        case .lockout:
            return "Biometric authentication is locked. Please try again later or use your password"
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
}