// Features/Auth/LoginViewModel.swift

import SwiftUI
import Combine
import LocalAuthentication

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var userRole: String = ""
    
    // Biometric properties
    @Published var showBiometricButton: Bool = false
    @Published var showBiometricPrompt: Bool = false
    @Published var biometricType: String = "Face ID"
    @Published var isHandlingBiometric: Bool = false  // New flag to prevent navigation
    
    private var storedEmail: String = ""
    private var storedPassword: String = ""

    private var cancellables = Set<AnyCancellable>()

    private let viewModelId = UUID().uuidString.prefix(8)
    
    init() {
        #if DEBUG
        print("[LoginViewModel] 🔧 LoginViewModel initialized with ID: \(viewModelId)")
        #endif
        
        // Check current login status without forcing navigation
        if AuthService.shared.isLoggedIn {
            self.isLoggedIn = true
            self.userRole = AuthService.shared.getEmployeeRole() ?? ""
        }
        
        // Check if biometric is available and enabled
        checkBiometricStatus()
        
        // Reset any hanging biometric state
        self.isHandlingBiometric = false
        self.showBiometricPrompt = false
        
        #if DEBUG
        print("[LoginViewModel] 🔧 Initial login status: \(isLoggedIn)")
        if !userRole.isEmpty {
            print("[LoginViewModel] 🔧 Initial user role: \(userRole)")
        }
        print("[LoginViewModel] 🔧 Biometric available: \(AuthService.shared.isBiometricAvailable)")
        print("[LoginViewModel] 🔧 Biometric enabled: \(showBiometricButton)")
        print("[LoginViewModel] 🔧 Biometric type: \(biometricType)")
        #endif
    }

    func login() {
        // Basic validation
        guard !email.isEmpty else {
            showError("Please enter your email")
            return
        }
        
        guard !password.isEmpty else {
            showError("Please enter your password")
            return
        }
        
        guard email.contains("@") else {
            showError("Please enter a valid email address")
            return
        }

        #if DEBUG
        print("[LoginViewModel] 🚀 Starting login process...")
        print("[LoginViewModel] 📧 Email: \(email)")
        #endif

        isLoading = true
        errorMessage = ""

        AuthService.shared.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                switch completion {
                case .failure(let error):
                    #if DEBUG
                    print("[LoginViewModel] ❌ Login failed with error: \(error.localizedDescription)")
                    #endif
                    self.handleLoginError(error)
                case .finished:
                    #if DEBUG
                    print("[LoginViewModel] ✅ Login completed successfully")
                    #endif
                    break
                }
            } receiveValue: { [weak self] authResponse in
                guard let self = self else { return }
                
                #if DEBUG
                print("[LoginViewModel] 🎉 Login successful!")
                print("[LoginViewModel] 👤 User: \(authResponse.name)")
                print("[LoginViewModel] 🎭 Role: \(authResponse.role)")
                print("[LoginViewModel] 🆔 Employee ID: \(authResponse.employeeId)")
                #endif
                
                // Set user data
                self.userRole = authResponse.role
                
                // Store credentials for biometric prompt if needed
                self.storedEmail = self.email
                self.storedPassword = self.password
                
                // Check if we should prompt for biometric
                #if DEBUG
                print("[LoginViewModel] 📱 About to start biometric check Task...")
                print("[LoginViewModel] 📱 Stored email: \(self.storedEmail)")
                print("[LoginViewModel] 📱 Stored password: \(!self.storedPassword.isEmpty)")
                #endif
                
                Task { @MainActor in
                    #if DEBUG
                    print("[LoginViewModel] 📱 Inside Task - checking biometric status...")
                    #endif
                    
                    let shouldShowPrompt = await self.checkBiometricPrompt()
                    
                    #if DEBUG
                    print("[LoginViewModel] 📱 Should show biometric prompt: \(shouldShowPrompt)")
                    #endif
                    
                    self.password = ""  // Clear password for security
                    
                    if shouldShowPrompt {
                        // Show biometric prompt, navigation will happen after user responds
                        #if DEBUG
                        print("[LoginViewModel] 📱 Setting showBiometricPrompt = true")
                        #endif
                        self.isHandlingBiometric = true
                        
                        // Small delay to ensure UI is ready for alert
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            #if DEBUG
                            print("[LoginViewModel] 📱 Now setting showBiometricPrompt = true")
                            print("[LoginViewModel] 📱 Current showBiometricPrompt value: \(self.showBiometricPrompt)")
                            #endif
                            self.showBiometricPrompt = true
                            #if DEBUG
                            print("[LoginViewModel] 📱 After setting, showBiometricPrompt = \(self.showBiometricPrompt)")
                            #endif
                        }
                        
                        // DO NOT navigate yet - wait for user response
                        // The navigation will happen in enableBiometric() or dismissBiometricPrompt()
                        
                        // Safety timeout - if biometric prompt doesn't show or gets stuck
                        let timeoutId = UUID().uuidString.prefix(8)
                        #if DEBUG
                        print("[LoginViewModel] ⏱️ Setting up biometric timeout with ID: \(timeoutId)")
                        #endif
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                            #if DEBUG
                            print("[LoginViewModel] ⏱️ Timeout \(timeoutId) fired - checking if should proceed")
                            print("[LoginViewModel] ⏱️ isHandlingBiometric: \(self.isHandlingBiometric)")
                            print("[LoginViewModel] ⏱️ showBiometricPrompt: \(self.showBiometricPrompt)")
                            #endif
                            
                            if self.isHandlingBiometric {
                                #if DEBUG
                                print("[LoginViewModel] ⏱️ Biometric timeout \(timeoutId) - proceeding with navigation")
                                #endif
                                self.isHandlingBiometric = false
                                self.showBiometricPrompt = false
                                
                                // Post notification to trigger navigation - AppContainerView will set isLoggedIn
                                NotificationCenter.default.post(name: Notification.Name("BiometricPromptCompleted"), object: nil)
                            } else {
                                #if DEBUG
                                print("[LoginViewModel] ⏱️ Timeout \(timeoutId) - already handled, ignoring")
                                #endif
                            }
                        }
                    } else {
                        // No biometric prompt, proceed with navigation immediately
                        #if DEBUG
                        print("[LoginViewModel] 🚀 No biometric prompt, proceeding with navigation")
                        #endif
                        
                        // Post notification to trigger navigation - AppContainerView will set isLoggedIn
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            NotificationCenter.default.post(name: Notification.Name("BiometricPromptCompleted"), object: nil)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func handleLoginError(_ error: BaseAPIService.APIError) {
        let errorMessage: String
        
        switch error {
        case .serverError(let code, let message):
            if code == 401 {
                errorMessage = "Invalid email or password"
            } else if code == 403 {
                errorMessage = "Account access denied"
            } else if code >= 500 {
                errorMessage = "Server error. Please try again later."
            } else {
                errorMessage = message.isEmpty ? "Login failed" : message
            }
        case .networkError(_):
            errorMessage = "Network error. Please check your connection."
        case .decodingError(_):
            errorMessage = "Unexpected response from server"
        case .invalidURL:
            errorMessage = "Configuration error. Please contact support."
        case .invalidResponse:
            errorMessage = "Invalid server response"
        case .unknown:
            errorMessage = "Unknown error occurred"
        }
        
        #if DEBUG
        print("[LoginViewModel] ❌ Showing error to user: \(errorMessage)")
        #endif
        
        showError(errorMessage)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        
        #if DEBUG
        print("[LoginViewModel] ⚠️ Error displayed: \(message)")
        #endif
        
        // Auto-clear error after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.errorMessage == message {
                self.errorMessage = ""
                #if DEBUG
                print("[LoginViewModel] 🧹 Auto-cleared error message")
                #endif
            }
        }
    }

    func forgotPassword() {
        #if DEBUG
        print("[LoginViewModel] 🔑 Forgot password requested")
        #endif
        
        showAlert = true
        alertTitle = "Reset Password"
        alertMessage = "Please contact the administrator at support@ksrcranes.dk to reset your password."
    }
    
    // MARK: - Biometric Methods
    
    func checkBiometricStatus() {
        // Show biometric button if:
        // 1. Biometric hardware is available
        // 2. Biometric is enabled 
        // 3. We have stored credentials
        let hasStoredCredentials = BiometricAuthService.shared.getStoredCredentials() != nil
        showBiometricButton = AuthService.shared.isBiometricAvailable && AuthService.shared.isBiometricEnabled && hasStoredCredentials
        biometricType = AuthService.shared.biometricType
        
        #if DEBUG
        print("[LoginViewModel] 🔍 Biometric check:")
        print("  - Available: \(AuthService.shared.isBiometricAvailable)")
        print("  - Enabled: \(AuthService.shared.isBiometricEnabled)")
        print("  - Has credentials: \(hasStoredCredentials)")
        print("  - Show button: \(showBiometricButton)")
        #endif
    }
    
    func loginWithBiometric() {
        #if DEBUG
        print("[LoginViewModel] 🔐 Starting biometric login...")
        #endif
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let authResponse = try await AuthService.shared.loginWithBiometric()
                
                await MainActor.run {
                    // Set user data
                    self.userRole = authResponse.role
                    self.isLoading = false
                    
                    #if DEBUG
                    print("[LoginViewModel] 🎉 Biometric login successful!")
                    print("[LoginViewModel] 👤 User: \(authResponse.name)")
                    print("[LoginViewModel] 🎭 Role: \(authResponse.role)")
                    #endif
                    
                    // Navigate to main app
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        // Post notification to trigger navigation - AppContainerView will set isLoggedIn
                        NotificationCenter.default.post(name: Notification.Name("BiometricPromptCompleted"), object: nil)
                    }
                }
            } catch let error as BiometricError {
                await MainActor.run {
                    self.isLoading = false
                    self.handleBiometricError(error)
                }
            } catch let error as BaseAPIService.APIError {
                await MainActor.run {
                    self.isLoading = false
                    self.handleLoginError(error)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.showError("An unexpected error occurred")
                }
            }
        }
    }
    
    private func handleBiometricError(_ error: BiometricError) {
        #if DEBUG
        print("[LoginViewModel] ❌ Biometric error: \(error.localizedDescription)")
        #endif
        
        switch error {
        case .userCancelled:
            // User cancelled, no need to show error
            return
        case .notEnrolled:
            showAlert = true
            alertTitle = "Setup Required"
            alertMessage = error.localizedDescription
        default:
            showError(error.localizedDescription)
        }
    }
    
    private func checkBiometricPrompt() async -> Bool {
        #if DEBUG
        print("[LoginViewModel] 🔐 Checking if should show biometric prompt...")
        print("[LoginViewModel] 📧 Stored email: \(!storedEmail.isEmpty)")
        print("[LoginViewModel] 🔑 Stored password: \(!storedPassword.isEmpty)")
        #endif
        
        guard !storedEmail.isEmpty && !storedPassword.isEmpty else { 
            #if DEBUG
            print("[LoginViewModel] ❌ No stored credentials, skipping biometric prompt")
            #endif
            return false
        }
        
        let shouldPrompt = await AuthService.shared.shouldPromptForBiometric(
            email: storedEmail,
            password: storedPassword
        )
        
        #if DEBUG
        print("[LoginViewModel] 🤔 Should prompt for biometric: \(shouldPrompt)")
        #endif
        
        if shouldPrompt {
            await MainActor.run {
                #if DEBUG
                print("[LoginViewModel] 📱 Showing biometric prompt!")
                #endif
                self.showBiometricPrompt = true
            }
        }
        
        return shouldPrompt
    }
    
    func enableBiometric() {
        #if DEBUG
        print("[LoginViewModel] 🔐 Enabling biometric authentication...")
        #endif
        
        do {
            try AuthService.shared.enableBiometric(email: storedEmail, password: storedPassword)
            
            // Clear stored credentials
            storedEmail = ""
            storedPassword = ""
            
            // Update UI
            checkBiometricStatus()
            
            #if DEBUG
            print("[LoginViewModel] ✅ Biometric authentication enabled")
            #endif
            
            // Navigate immediately
            self.isHandlingBiometric = false
            
            // Post notification to trigger navigation - AppContainerView will set isLoggedIn
            NotificationCenter.default.post(name: Notification.Name("BiometricPromptCompleted"), object: nil)
            
        } catch {
            #if DEBUG
            print("[LoginViewModel] ❌ Failed to enable biometric: \(error)")
            #endif
            
            showAlert = true
            alertTitle = "Setup Failed"
            alertMessage = "Failed to enable \(biometricType). Please try again later."
            
            // Still navigate to app even if biometric setup failed
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isHandlingBiometric = false
                
                // Post notification to trigger navigation - AppContainerView will set isLoggedIn
                NotificationCenter.default.post(name: Notification.Name("BiometricPromptCompleted"), object: nil)
            }
        }
    }
    
    func dismissBiometricPrompt() {
        showBiometricPrompt = false
        // Clear stored credentials for security
        storedEmail = ""
        storedPassword = ""
        
        // Navigate immediately after dismissing prompt
        self.isHandlingBiometric = false
        
        #if DEBUG
        print("[LoginViewModel] ✅ Navigating to app after dismissing biometric prompt")
        #endif
        
        // Post notification to trigger navigation - AppContainerView will set isLoggedIn
        NotificationCenter.default.post(name: Notification.Name("BiometricPromptCompleted"), object: nil)
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = ""
        
        #if DEBUG
        print("[LoginViewModel] 🧹 Error message cleared manually")
        #endif
    }
    
    func logout() {
        // This method can be called from other parts of the app
        #if DEBUG
        print("[LoginViewModel] 🚪 Logout called from LoginViewModel")
        #endif
        
        AuthService.shared.logout()
        isLoggedIn = false
        userRole = ""
        email = ""
        password = ""
        errorMessage = ""
        
        #if DEBUG
        print("[LoginViewModel] ✅ LoginViewModel state reset")
        #endif
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    func testLogin() {
        // For testing purposes
        email = "admin@ksrcranes.dk"
        password = "password123"
        
        print("[LoginViewModel] 🧪 Test credentials set")
        print("[LoginViewModel] 📧 Email: \(email)")
        print("[LoginViewModel] 🔐 Password: [HIDDEN]")
    }
    
    func debugState() {
        print("[LoginViewModel] 🔍 === LOGIN VIEW MODEL STATE ===")
        print("[LoginViewModel] 🔍 Email: \(email)")
        print("[LoginViewModel] 🔍 Password: \(password.isEmpty ? "EMPTY" : "SET (\(password.count) chars)")")
        print("[LoginViewModel] 🔍 Is Loading: \(isLoading)")
        print("[LoginViewModel] 🔍 Is Logged In: \(isLoggedIn)")
        print("[LoginViewModel] 🔍 User Role: \(userRole.isEmpty ? "NONE" : userRole)")
        print("[LoginViewModel] 🔍 Error Message: \(errorMessage.isEmpty ? "NONE" : errorMessage)")
        print("[LoginViewModel] 🔍 Show Alert: \(showAlert)")
        print("[LoginViewModel] 🔍 === END STATE ===")
    }
    
    func simulateSuccessfulLogin() {
        print("[LoginViewModel] 🎭 Simulating successful login...")
        
        userRole = "arbejder"
        isLoggedIn = true
        password = ""
        errorMessage = ""
        
        print("[LoginViewModel] ✅ Simulation complete - state should trigger navigation")
    }
    
    func simulateLoginError() {
        print("[LoginViewModel] 🎭 Simulating login error...")
        
        isLoading = false
        showError("Simulated login error for testing")
        
        print("[LoginViewModel] ❌ Error simulation complete")
    }
    #endif
    
    deinit {
        #if DEBUG
        print("[LoginViewModel] 💀 LoginViewModel deinitialized with ID: \(viewModelId)")
        #endif
    }
}

// ✅ USUNIĘTO: Notification.Name extension - używamy tylko tej z AuthService
// żeby uniknąć konfliktów
