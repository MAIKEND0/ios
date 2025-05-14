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
    @Published var userRole: String = ""   // <— dodaj to

    private var cancellables = Set<AnyCancellable>()

    init() {
        if AuthService.shared.isLoggedIn {
            self.isLoggedIn = true
            // Pobierz rolę z tokenu/keychain przy starcie
            self.userRole = AuthService.shared.getEmployeeRole() ?? ""
        }
    }

    func login() {
        // … walidacja email/password …

        isLoading = true
        errorMessage = ""

        AuthService.shared.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                // … obsługa błędów …
            } receiveValue: { [weak self] authResponse in
                guard let self = self else { return }
                // Zapisz rolę zalogowanego użytkownika:
                self.userRole = authResponse.role
                self.isLoggedIn = true
            }
            .store(in: &cancellables)
    }

    func forgotPassword() {
        showAlert = true
        alertTitle = "Reset Password"
        alertMessage = "Please contact the administrator at support@ksrcranes.dk to reset your password."
    }
}
