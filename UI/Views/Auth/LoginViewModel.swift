// Features/Auth/LoginViewModel.swift

import SwiftUI
import Combine

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

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Check current login status without forcing navigation
        if AuthService.shared.isLoggedIn {
            self.isLoggedIn = true
            self.userRole = AuthService.shared.getEmployeeRole() ?? ""
        }
        
        #if DEBUG
        print("[LoginViewModel] 🔧 LoginViewModel initialized")
        print("[LoginViewModel] 🔧 Initial login status: \(isLoggedIn)")
        if !userRole.isEmpty {
            print("[LoginViewModel] 🔧 Initial user role: \(userRole)")
        }
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
                
                // ✅ POPRAWKA: Krótsze opóźnienie i brak dodatkowej notyfikacji
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.isLoggedIn = true
                    
                    // Clear sensitive data
                    self.password = ""
                    
                    #if DEBUG
                    print("[LoginViewModel] ✅ isLoggedIn set to true, AppContainerView should handle navigation")
                    print("[LoginViewModel] 🧹 Password cleared for security")
                    #endif
                    
                    // ✅ USUNIĘTO: Nie wysyłamy dodatkowej notyfikacji
                    // AuthService już wysłał notyfikację w swoim handleEvents
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
}

// ✅ USUNIĘTO: Notification.Name extension - używamy tylko tej z AuthService
// żeby uniknąć konfliktów
