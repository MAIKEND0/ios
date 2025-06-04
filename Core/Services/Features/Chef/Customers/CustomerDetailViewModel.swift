//
//  CustomerDetailViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//  Updated with Logo Support
//

import Foundation
import SwiftUI
import Combine

class CustomerDetailViewModel: ObservableObject {
    @Published var customerDetail: CustomerDetail?
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    // Logo-related properties
    @Published var currentLogoUrl: String?
    @Published var logoUpdateInProgress = false
    
    private let apiService = ChefAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Load Customer Details
    
    func loadCustomerDetails(customerId: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        #if DEBUG
        print("[CustomerDetailViewModel] Loading details for customer ID: \(customerId)")
        #endif
        
        apiService.fetchCustomer(id: customerId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<BaseAPIService.APIError>) in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "loading customer details")
                    }
                },
                receiveValue: { [weak self] (customerDetail: CustomerDetail) in
                    self?.customerDetail = customerDetail
                    self?.currentLogoUrl = customerDetail.logo_url
                    
                    #if DEBUG
                    print("[CustomerDetailViewModel] Customer details loaded successfully")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Update Customer
    
    func updateCustomer(_ customerId: Int, with data: UpdateCustomerRequest, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        #if DEBUG
        print("[CustomerDetailViewModel] Updating customer ID: \(customerId)")
        #endif
        
        apiService.updateCustomer(id: customerId, data: data)
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
                    // Update local customer detail with new data
                    if let detail = self?.customerDetail {
                        self?.customerDetail = CustomerDetail(
                            customer_id: updatedCustomer.customer_id,
                            name: updatedCustomer.name,
                            contact_email: updatedCustomer.contact_email,
                            phone: updatedCustomer.phone,
                            address: updatedCustomer.address,
                            cvr_nr: updatedCustomer.cvr_nr,
                            created_at: updatedCustomer.created_at,
                            logo_url: updatedCustomer.logo_url,
                            logo_key: updatedCustomer.logo_key,
                            logo_uploaded_at: updatedCustomer.logo_uploaded_at,
                            project_count: detail.project_count,
                            hiring_request_count: detail.hiring_request_count,
                            projects: detail.projects,
                            recent_hiring_requests: detail.recent_hiring_requests
                        )
                        self?.currentLogoUrl = updatedCustomer.logo_url
                    }
                    self?.showSuccess("Customer Updated", message: "\(updatedCustomer.name) has been updated successfully.")
                    completion(true)
                    
                    #if DEBUG
                    print("[CustomerDetailViewModel] Customer updated successfully")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Delete Customer
    
    func deleteCustomer(_ customerId: Int, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        #if DEBUG
        print("[CustomerDetailViewModel] Deleting customer ID: \(customerId)")
        #endif
        
        apiService.deleteCustomer(id: customerId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completionResult: Subscribers.Completion<BaseAPIService.APIError>) in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completionResult {
                        self?.handleAPIError(error, context: "deleting customer")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] (response: DeleteCustomerResponse) in
                    if response.success {
                        let customerName = self?.customerDetail?.name ?? "Customer"
                        self?.showSuccess("Customer Deleted", message: "\(customerName) has been deleted successfully.")
                        completion(true)
                        
                        #if DEBUG
                        print("[CustomerDetailViewModel] Customer deleted successfully")
                        #endif
                    } else {
                        self?.showError("Deletion Failed", message: response.message)
                        completion(false)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Logo Management
    
    func updateCustomerLogo(_ customerId: Int, logoUrl: String?, completion: @escaping (Bool) -> Void) {
        logoUpdateInProgress = true
        
        #if DEBUG
        print("[CustomerDetailViewModel] Updating logo for customer \(customerId)")
        #endif
        
        // In a real implementation, you might have a separate API call for updating just the logo
        // For now, we'll update the local state and refresh the customer details
        currentLogoUrl = logoUrl
        
        // Update the local customer detail object
        if let detail = customerDetail {
            customerDetail = CustomerDetail(
                customer_id: detail.customer_id,
                name: detail.name,
                contact_email: detail.contact_email,
                phone: detail.phone,
                address: detail.address,
                cvr_nr: detail.cvr_nr,
                created_at: detail.created_at,
                logo_url: logoUrl,
                logo_key: nil, // We don't track logo_key in frontend
                logo_uploaded_at: logoUrl != nil ? Date() : nil,
                project_count: detail.project_count,
                hiring_request_count: detail.hiring_request_count,
                projects: detail.projects,
                recent_hiring_requests: detail.recent_hiring_requests
            )
        }
        
        logoUpdateInProgress = false
        completion(true)
        
        #if DEBUG
        print("[CustomerDetailViewModel] Logo updated successfully")
        #endif
    }
    
    func deleteCustomerLogo(_ customerId: Int, completion: @escaping (Bool) -> Void) {
        logoUpdateInProgress = true
        
        #if DEBUG
        print("[CustomerDetailViewModel] Deleting logo for customer \(customerId)")
        #endif
        
        // Update local state to remove logo
        updateCustomerLogo(customerId, logoUrl: nil) { success in
            completion(success)
        }
    }
    
    // MARK: - Local Updates
    
    func updateLocalCustomer(_ customer: Customer) {
        if let detail = customerDetail, detail.customer_id == customer.customer_id {
            customerDetail = CustomerDetail(
                customer_id: customer.customer_id,
                name: customer.name,
                contact_email: customer.contact_email,
                phone: customer.phone,
                address: customer.address,
                cvr_nr: customer.cvr_nr,
                created_at: customer.created_at,
                logo_url: customer.logo_url,
                logo_key: customer.logo_key,
                logo_uploaded_at: customer.logo_uploaded_at,
                project_count: detail.project_count,
                hiring_request_count: detail.hiring_request_count,
                projects: detail.projects,
                recent_hiring_requests: detail.recent_hiring_requests
            )
            currentLogoUrl = customer.logo_url
        }
    }
    
    func updateLocalCustomerLogo(logoUrl: String?) {
        if let detail = customerDetail {
            customerDetail = CustomerDetail(
                customer_id: detail.customer_id,
                name: detail.name,
                contact_email: detail.contact_email,
                phone: detail.phone,
                address: detail.address,
                cvr_nr: detail.cvr_nr,
                created_at: detail.created_at,
                logo_url: logoUrl,
                logo_key: detail.logo_key,
                logo_uploaded_at: logoUrl != nil ? Date() : nil,
                project_count: detail.project_count,
                hiring_request_count: detail.hiring_request_count,
                projects: detail.projects,
                recent_hiring_requests: detail.recent_hiring_requests
            )
            currentLogoUrl = logoUrl
        }
    }
    
    // MARK: - Utility Methods
    
    func refreshCustomerDetails(customerId: Int) {
        loadCustomerDetails(customerId: customerId)
    }
    
    func getRecentProjects(limit: Int = 5) -> [ProjectDetail] {
        return Array(customerDetail?.projects.prefix(limit) ?? [])
    }
    
    func getRecentHiringRequests(limit: Int = 5) -> [HiringRequestSummary] {
        return Array(customerDetail?.recent_hiring_requests.prefix(limit) ?? [])
    }
    
    func hasContactInformation() -> Bool {
        guard let detail = customerDetail else { return false }
        return !(detail.contact_email?.isEmpty ?? true) ||
               !(detail.phone?.isEmpty ?? true) ||
               !(detail.address?.isEmpty ?? true)
    }
    
    func hasLogo() -> Bool {
        return currentLogoUrl != nil && !currentLogoUrl!.isEmpty
    }
    
    func getContactCompleteness() -> Double {
        guard let detail = customerDetail else { return 0.0 }
        
        var completeness = 0.0
        let totalFields = 3.0
        
        if !(detail.contact_email?.isEmpty ?? true) { completeness += 1.0 }
        if !(detail.phone?.isEmpty ?? true) { completeness += 1.0 }
        if !(detail.address?.isEmpty ?? true) { completeness += 1.0 }
        
        return (completeness / totalFields) * 100
    }
    
    func getProfileCompleteness() -> Double {
        guard let detail = customerDetail else { return 0.0 }
        
        var completeness = 1.0 // Name is always present (required)
        let totalFields = 5.0 // name, email, phone, address, logo
        
        if !(detail.contact_email?.isEmpty ?? true) { completeness += 1.0 }
        if !(detail.phone?.isEmpty ?? true) { completeness += 1.0 }
        if !(detail.address?.isEmpty ?? true) { completeness += 1.0 }
        if hasLogo() { completeness += 1.0 }
        
        return (completeness / totalFields) * 100
    }
    
    func canDeleteCustomer() -> Bool {
        guard let detail = customerDetail else { return false }
        return detail.project_count == 0 && detail.hiring_request_count == 0
    }
    
    func getCustomerSummary() -> String {
        guard let detail = customerDetail else { return "Loading..." }
        
        var summary = "\(detail.name)"
        
        if let cvr = detail.cvr_nr, !cvr.isEmpty {
            summary += " (CVR: \(cvr))"
        }
        
        if detail.project_count > 0 || detail.hiring_request_count > 0 {
            var activities: [String] = []
            
            if detail.project_count > 0 {
                activities.append("\(detail.project_count) project\(detail.project_count == 1 ? "" : "s")")
            }
            
            if detail.hiring_request_count > 0 {
                activities.append("\(detail.hiring_request_count) request\(detail.hiring_request_count == 1 ? "" : "s")")
            }
            
            summary += " • " + activities.joined(separator: ", ")
        }
        
        return summary
    }
    
    // MARK: - Public Alert Methods
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
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
                message = "The customer you're looking for no longer exists."
            } else if statusCode == 403 {
                title = "Access Denied"
                message = "You don't have permission to access this customer's information."
            }
        case .unknown:
            title = "Unknown Error"
            message = "An unexpected error occurred while \(context)."
        }
        
        showError(title, message: message)
        
        #if DEBUG
        print("[CustomerDetailViewModel] API Error in \(context): \(error)")
        #endif
    }
    
    // MARK: - Alert Helpers
    
    private func showError(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        
        #if DEBUG
        print("[CustomerDetailViewModel] Error: \(title) - \(message)")
        #endif
    }
    
    private func showSuccess(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        
        #if DEBUG
        print("[CustomerDetailViewModel] Success: \(title) - \(message)")
        #endif
    }
}

// MARK: - Preview Helper

#if DEBUG
extension CustomerDetailViewModel {
    static func preview(for customer: Customer) -> CustomerDetailViewModel {
        let viewModel = CustomerDetailViewModel()
        
        // Create mock customer detail for preview
        viewModel.customerDetail = CustomerDetail(
            customer_id: customer.customer_id,
            name: customer.name,
            contact_email: customer.contact_email,
            phone: customer.phone,
            address: customer.address,
            cvr_nr: customer.cvr_nr,
            created_at: customer.created_at,
            logo_url: customer.logo_url,
            logo_key: customer.logo_key,
            logo_uploaded_at: customer.logo_uploaded_at,
            project_count: 5,
            hiring_request_count: 3,
            projects: [
                ProjectDetail(
                    project_id: 1,
                    title: "Office Building Construction",
                    status: "aktiv",
                    start_date: Date(),
                    end_date: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
                    created_at: Calendar.current.date(byAdding: .month, value: -2, to: Date())
                )
            ],
            recent_hiring_requests: [
                HiringRequestSummary(
                    id: 1,
                    projectName: "Crane Operator Needed",
                    status: "APPROVED",
                    startDate: Date(),
                    createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
                )
            ]
        )
        
        viewModel.currentLogoUrl = customer.logo_url
        
        return viewModel
    }
}
#endif
