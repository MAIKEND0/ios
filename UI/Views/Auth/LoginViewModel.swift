//
//  LoginViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

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
        // Check if user is already logged in
        if AuthService.shared.isLoggedIn {
            self.isLoggedIn = true
            self.userRole = AuthService.shared.getEmployeeRole() ?? ""
        }
    }
    
    func login() {
        // Validate input
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        AuthService.shared.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    switch error {
                    case .serverError(let code, _) where code == 401:
                        self.errorMessage = "Invalid email or password"
                    case .networkError(_):
                        self.errorMessage = "No internet connection"
                    default:
                        self.errorMessage = "Login failed: \(error.localizedDescription)"
                    }
                }
            } receiveValue: { [weak self] authResponse in
                guard let self = self else { return }
                
                // Store the user role
                self.userRole = authResponse.role
                
                // Login success
                self.isLoggedIn = true
            }
            .store(in: &cancellables)
    }
    
    func forgotPassword() {
        // In a real app, this would trigger a password reset flow
        showAlert = true
        alertTitle = "Reset Password"
        alertMessage = "Please contact the administrator at support@ksrcranes.dk to reset your password."
    }
}
