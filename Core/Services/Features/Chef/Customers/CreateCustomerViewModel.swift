//
//  CreateCustomerViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//  Updated with Logo Support
//

import Foundation
import SwiftUI
import Combine

// MARK: - CreateCustomerViewModel

class CreateCustomerViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var address = ""
    @Published var cvr = ""
    
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var creationSuccess = false
    @Published var createdCustomer: Customer?
    
    // Validation errors
    @Published var nameError: String?
    @Published var emailError: String?
    @Published var phoneError: String?
    @Published var cvrError: String?
    
    private var apiService: ChefAPIService {
        return ChefAPIService.shared
    }
    private var cancellables = Set<AnyCancellable>()
    
    var isFormValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               nameError == nil &&
               emailError == nil &&
               phoneError == nil &&
               cvrError == nil
    }
    
    init() {
        setupValidation()
    }
    
    private func setupValidation() {
        // Real-time validation
        $name
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validateName(value)
            }
            .store(in: &cancellables)
        
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validateEmail(value)
            }
            .store(in: &cancellables)
        
        $phone
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validatePhone(value)
            }
            .store(in: &cancellables)
        
        $cvr
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validateCVR(value)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    
    private func validateName(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed.count < 2 {
            nameError = "Company name must be at least 2 characters"
        } else if trimmed.count > 255 {
            nameError = "Company name must be less than 255 characters"
        } else {
            nameError = nil
        }
    }
    
    private func validateEmail(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !isValidEmail(trimmed) {
            emailError = "Please enter a valid email address"
        } else {
            emailError = nil
        }
    }
    
    private func validatePhone(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !isValidPhone(trimmed) {
            phoneError = "Please enter a valid phone number"
        } else {
            phoneError = nil
        }
    }
    
    private func validateCVR(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !isValidCVR(trimmed) {
            cvrError = "CVR must be 8 digits"
        } else {
            cvrError = nil
        }
    }
    
    // MARK: - Validation Helpers
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let cleanPhone = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        return cleanPhone.count >= 8 && cleanPhone.count <= 15
    }
    
    private func isValidCVR(_ cvr: String) -> Bool {
        let cleanCVR = cvr.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleanCVR.count == 8 && Int(cleanCVR) != nil
    }
    
    // MARK: - Create Customer Action
    
    func createCustomer(completion: @escaping (Bool) -> Void) {
        // Final validation
        guard isFormValid else {
            showError("Validation Error", "Please correct the errors in the form.")
            completion(false)
            return
        }
        
        isLoading = true
        creationSuccess = false
        createdCustomer = nil
        
        let customerData = CreateCustomerRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            contact_email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.isEmpty ? nil : address.trimmingCharacters(in: .whitespacesAndNewlines),
            cvr: cvr.isEmpty ? nil : cvr.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        #if DEBUG
        print("[CreateCustomerViewModel] Creating customer: \(customerData.name)")
        #endif
        
        apiService.createCustomer(customerData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completionResult: Subscribers.Completion<BaseAPIService.APIError>) in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completionResult {
                        self?.handleAPIError(error, context: "creating customer")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] (newCustomer: Customer) in
                    self?.createdCustomer = newCustomer
                    self?.creationSuccess = true
                    self?.showSuccess("Customer Created", "The customer has been added successfully.")
                    completion(true)
                    
                    #if DEBUG
                    print("[CreateCustomerViewModel] Customer created successfully via API")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Public Alert Methods
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - Reset Method
    
    func reset() {
        name = ""
        email = ""
        phone = ""
        address = ""
        cvr = ""
        isLoading = false
        showAlert = false
        alertTitle = ""
        alertMessage = ""
        creationSuccess = false
        createdCustomer = nil
        nameError = nil
        emailError = nil
        phoneError = nil
        cvrError = nil
    }
    
    // MARK: - Error Handling
    
    private func handleAPIError(_ error: BaseAPIService.APIError, context: String) {
        var title = "Error"
        var message = "An unexpected error occurred."
        
        switch error {
        case .invalidURL:
            title = "Invalid URL"
            message = "The request URL is invalid."
        case .invalidResponse:
            title = "Invalid Response"
            message = "The server response is invalid."
        case .networkError(let networkError):
            title = "Network Error"
            message = "Please check your internet connection and try again. (\(networkError.localizedDescription))"
        case .decodingError(let decodingError):
            title = "Data Error"
            message = "Unable to process the server response. (\(decodingError.localizedDescription))"
        case .serverError(let statusCode, let serverMessage):
            title = "Server Error"
            message = "Server returned error \(statusCode): \(serverMessage)"
            
            // Handle specific server errors
            if statusCode == 409 {
                if serverMessage.contains("name") {
                    title = "Duplicate Customer"
                    message = "A customer with this name already exists."
                } else if serverMessage.contains("CVR") {
                    title = "Duplicate CVR"
                    message = "A customer with this CVR number already exists."
                }
            }
        case .unknown:
            title = "Unknown Error"
            message = "An unexpected error occurred while \(context)."
        }
        
        showError(title, message)
        
        #if DEBUG
        print("[CreateCustomerViewModel] API Error in \(context): \(error)")
        #endif
    }
    
    // MARK: - Alert Helpers
    
    private func showError(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccess(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
