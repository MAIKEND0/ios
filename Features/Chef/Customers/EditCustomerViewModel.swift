//
//  EditCustomerViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//  Updated with Logo Support
//

import Foundation
import SwiftUI
import Combine

class EditCustomerViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var address = ""
    @Published var cvr = ""
    
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var updateSuccess = false
    @Published var updatedCustomer: Customer?
    
    // Validation errors
    @Published var nameError: String?
    @Published var emailError: String?
    @Published var phoneError: String?
    @Published var cvrError: String?
    
    // Logo related properties
    @Published var currentLogoUrl: String?
    @Published var logoHasChanged = false
    
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
    
    func loadCustomerData(_ customer: Customer) {
        name = customer.name
        email = customer.contact_email ?? ""
        phone = customer.phone ?? ""
        address = customer.address ?? ""
        cvr = customer.cvr_nr ?? ""
        currentLogoUrl = customer.logo_url
        logoHasChanged = false
        
        #if DEBUG
        print("[EditCustomerViewModel] Loaded customer data: \(customer.name)")
        #endif
    }
    
    private func setupValidation() {
        // Real-time validation (same as CreateCustomerViewModel)
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
    
    // MARK: - Validation Methods (same as CreateCustomerViewModel)
    
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
    
    // MARK: - Update Customer Action
    
    func updateCustomer(customerId: Int, completion: @escaping (Bool) -> Void) {
        // Final validation
        guard isFormValid else {
            showError("Validation Error", message: "Please correct the errors in the form.")
            completion(false)
            return
        }
        
        isLoading = true
        updateSuccess = false
        updatedCustomer = nil
        
        let customerData = UpdateCustomerRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            contact_email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.isEmpty ? nil : address.trimmingCharacters(in: .whitespacesAndNewlines),
            cvr: cvr.isEmpty ? nil : cvr.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        #if DEBUG
        print("[EditCustomerViewModel] Updating customer ID: \(customerId)")
        #endif
        
        apiService.updateCustomer(id: customerId, data: customerData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completionResult: Subscribers.Completion<BaseAPIService.APIError>) in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completionResult {
                        self?.handleAPIError(error, context: "updating customer")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] (updatedCustomer: Customer) in
                    self?.updatedCustomer = updatedCustomer
                    self?.updateSuccess = true
                    self?.showSuccess("Customer Updated", message: "The customer has been updated successfully.")
                    completion(true)
                    
                    #if DEBUG
                    print("[EditCustomerViewModel] Customer updated successfully via API")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Logo Management
    
    func updateLogoUrl(_ newLogoUrl: String?) {
        currentLogoUrl = newLogoUrl
        logoHasChanged = true
        
        // Update the updatedCustomer if it exists
        if let customer = updatedCustomer {
            updatedCustomer = Customer(
                customer_id: customer.customer_id,
                name: customer.name,
                contact_email: customer.contact_email,
                phone: customer.phone,
                address: customer.address,
                cvr_nr: customer.cvr_nr,
                created_at: customer.created_at,
                logo_url: newLogoUrl,
                logo_key: nil, // We don't track logo_key in frontend
                logo_uploaded_at: newLogoUrl != nil ? Date() : nil,
                project_count: customer.project_count,
                hiring_request_count: customer.hiring_request_count,
                recent_projects: customer.recent_projects
            )
        }
    }
    
    func hasLogoChanges() -> Bool {
        return logoHasChanged
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
        updateSuccess = false
        updatedCustomer = nil
        nameError = nil
        emailError = nil
        phoneError = nil
        cvrError = nil
        currentLogoUrl = nil
        logoHasChanged = false
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
            if statusCode == 404 {
                title = "Customer Not Found"
                message = "The customer you're trying to update no longer exists."
            } else if statusCode == 409 {
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
        
        showError(title, message: message)
        
        #if DEBUG
        print("[EditCustomerViewModel] API Error in \(context): \(error)")
        #endif
    }
    
    // MARK: - Alert Helpers
    
    private func showError(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        
        #if DEBUG
        print("[EditCustomerViewModel] Error: \(title) - \(message)")
        #endif
    }
    
    private func showSuccess(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        
        #if DEBUG
        print("[EditCustomerViewModel] Success: \(title) - \(message)")
        #endif
    }
}
