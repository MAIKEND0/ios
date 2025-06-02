//
//  CustomersViewModel.swift
//  KSR Cranes App
//
//  Updated with Logo Support
//

import SwiftUI
import Combine

class CustomersViewModel: ObservableObject {
    @Published var customers: [Customer] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    // Statistics
    @Published var customerStats = CustomerStats.mockData
    
    // Search and Filter
    @Published var searchResults: [Customer] = []
    @Published var isSearching = false
    
    // Logo management
    @Published var customersWithLogos: Set<Int> = []
    @Published var logoUpdateInProgress: Set<Int> = []
    
    private var cancellables = Set<AnyCancellable>()
    private var apiService: ChefAPIService {
        return ChefAPIService.shared
    }
    
    init() {
        // Initialize with empty state - will load from API
        updateCustomersWithLogos()
    }
    
    // MARK: - Main Actions
    
    func loadCustomers() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        #if DEBUG
        print("[CustomersViewModel] Loading customers from API...")
        #endif
        
        apiService.fetchCustomers(includeLogo: true)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "loading customers")
                    }
                },
                receiveValue: { [weak self] customers in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.customers = customers
                        self?.updateCustomersWithLogos()
                        self?.updateStats()
                    }
                    
                    #if DEBUG
                    print("[CustomersViewModel] Loaded \(customers.count) customers from API")
                    print("[CustomersViewModel] Customers with logos: \(self?.customersWithLogos.count ?? 0)")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func createCustomer(_ customerData: CreateCustomerRequest, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        #if DEBUG
        print("[CustomersViewModel] Creating customer: \(customerData.name)")
        #endif
        
        apiService.createCustomer(customerData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completionResult {
                        self?.handleAPIError(error, context: "creating customer")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] newCustomer in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.customers.insert(newCustomer, at: 0)
                        self?.updateCustomersWithLogos()
                        self?.updateStats()
                    }
                    self?.showSuccess("Customer Created", message: "\(newCustomer.name) has been added successfully.")
                    completion(true)
                    
                    #if DEBUG
                    print("[CustomersViewModel] Customer created successfully via API")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func updateCustomer(_ customer: Customer, with data: UpdateCustomerRequest, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        #if DEBUG
        print("[CustomersViewModel] Updating customer: \(customer.name)")
        #endif
        
        apiService.updateCustomer(id: customer.customer_id, data: data)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completionResult {
                        self?.handleAPIError(error, context: "updating customer")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] updatedCustomer in
                    if let index = self?.customers.firstIndex(where: { $0.customer_id == customer.customer_id }) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self?.customers[index] = updatedCustomer
                            self?.updateCustomersWithLogos()
                        }
                    }
                    self?.showSuccess("Customer Updated", message: "\(updatedCustomer.name) has been updated successfully.")
                    completion(true)
                    
                    #if DEBUG
                    print("[CustomersViewModel] Customer updated successfully via API")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteCustomer(_ customer: Customer, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        #if DEBUG
        print("[CustomersViewModel] Deleting customer: \(customer.name)")
        #endif
        
        apiService.deleteCustomer(id: customer.customer_id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completionResult {
                        self?.handleAPIError(error, context: "deleting customer")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self?.customers.removeAll { $0.customer_id == customer.customer_id }
                            self?.customersWithLogos.remove(customer.customer_id)
                            self?.logoUpdateInProgress.remove(customer.customer_id)
                            self?.updateStats()
                        }
                        self?.showSuccess("Customer Deleted", message: response.message)
                        completion(true)
                        
                        #if DEBUG
                        print("[CustomersViewModel] Customer deleted successfully via API")
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
    
    func updateCustomerLogo(_ customerId: Int, logoUrl: String?) {
        // Update the customer in the local array
        if let index = customers.firstIndex(where: { $0.customer_id == customerId }) {
            let customer = customers[index]
            let updatedCustomer = Customer(
                customer_id: customer.customer_id,
                name: customer.name,
                contact_email: customer.contact_email,
                phone: customer.phone,
                address: customer.address,
                cvr_nr: customer.cvr_nr,
                created_at: customer.created_at,
                logo_url: logoUrl,
                logo_key: customer.logo_key,
                logo_uploaded_at: logoUrl != nil ? Date() : nil,
                project_count: customer.project_count,
                hiring_request_count: customer.hiring_request_count,
                recent_projects: customer.recent_projects
            )
            
            withAnimation(.easeInOut(duration: 0.3)) {
                customers[index] = updatedCustomer
                updateCustomersWithLogos()
            }
            
            #if DEBUG
            print("[CustomersViewModel] Updated customer \(customerId) logo: \(logoUrl != nil ? "added" : "removed")")
            #endif
        }
    }
    
    func setLogoUpdateInProgress(_ customerId: Int, inProgress: Bool) {
        if inProgress {
            logoUpdateInProgress.insert(customerId)
        } else {
            logoUpdateInProgress.remove(customerId)
        }
    }
    
    func isLogoUpdateInProgress(_ customerId: Int) -> Bool {
        return logoUpdateInProgress.contains(customerId)
    }
    
    private func updateCustomersWithLogos() {
        customersWithLogos = Set(
            customers
                .filter { $0.hasLogo }
                .map { $0.customer_id }
        )
    }
    
    // MARK: - Search Functionality
    
    func searchCustomers(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        #if DEBUG
        print("[CustomersViewModel] Searching customers with query: \(query)")
        #endif
        
        apiService.searchCustomers(query: query, limit: 50, offset: 0, includeProjects: false, includeStats: true)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSearching = false
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "searching customers")
                        // Still show local results as fallback
                        self?.searchResults = self?.customers.filter { $0.matches(searchText: query) } ?? []
                    }
                },
                receiveValue: { [weak self] response in
                    self?.searchResults = response.customers.map { $0.toCustomer() }
                    
                    #if DEBUG
                    print("[CustomersViewModel] API search completed. Found \(response.customers.count) results")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Advanced Search
    
    func advancedSearchCustomers(_ searchRequest: AdvancedCustomerSearchRequest) {
        isSearching = true
        
        apiService.advancedSearchCustomers(searchRequest)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSearching = false
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "performing advanced search")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.searchResults = response.customers.map { $0.toCustomer() }
                    
                    #if DEBUG
                    print("[CustomersViewModel] Advanced search completed. Found \(response.customers.count) results")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Statistics
    
    func loadCustomerStats() {
        apiService.fetchCustomerStats(includeMonthlyGrowth: true, topCustomersLimit: 10, recentCustomersLimit: 10)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "loading customer statistics")
                        // Keep existing mock stats as fallback
                    }
                },
                receiveValue: { [weak self] stats in
                    self?.customerStats = stats
                    
                    #if DEBUG
                    print("[CustomersViewModel] Customer stats loaded from API")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateStats() {
        // Update local stats based on current customers data
        let total = customers.count
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let newThisMonth = customers.filter { customer in
            guard let createdAt = customer.created_at else { return false }
            return createdAt > thirtyDaysAgo
        }.count
        
        let totalProjects = customers.compactMap { $0.project_count }.reduce(0, +)
        let customersWithLogosCount = customersWithLogos.count
        
        // Update the published stats with real data including logo stats
        customerStats = CustomerStats(
            total_customers: total,
            new_this_month: newThisMonth,
            new_this_week: getNewThisWeek(),
            new_today: getNewToday(),
            customers_with_projects: getCustomersWithProjects(),
            customers_without_projects: total - getCustomersWithProjects(),
            customers_with_active_projects: customers.filter { ($0.project_count ?? 0) > 0 }.count,
            customers_with_email: customers.filter { $0.contact_email != nil }.count,
            customers_with_phone: customers.filter { $0.phone != nil }.count,
            customers_with_cvr: customers.filter { $0.cvr_nr != nil }.count,
            customers_with_address: customers.filter { $0.address != nil }.count,
            total_projects: totalProjects,
            total_hiring_requests: customers.compactMap { $0.hiring_request_count }.reduce(0, +),
            average_projects_per_customer: total > 0 ? Double(totalProjects) / Double(total) : 0.0,
            top_customers_by_projects: getTopCustomers(),
            recent_customers: getRecentCustomers(),
            monthly_growth: customerStats.monthly_growth // Keep existing monthly growth data
        )
        
        #if DEBUG
        print("[CustomersViewModel] Local stats updated - Total: \(total), New: \(newThisMonth), With Logos: \(customersWithLogosCount)")
        #endif
    }
    
    private func getNewThisWeek() -> Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return customers.filter { customer in
            guard let createdAt = customer.created_at else { return false }
            return createdAt > oneWeekAgo
        }.count
    }
    
    private func getNewToday() -> Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return customers.filter { customer in
            guard let createdAt = customer.created_at else { return false }
            return createdAt >= startOfDay
        }.count
    }
    
    private func getCustomersWithProjects() -> Int {
        return customers.filter { ($0.project_count ?? 0) > 0 }.count
    }
    
    private func getTopCustomers() -> [CustomerStats.TopCustomer] {
        return customers
            .sorted { ($0.project_count ?? 0) > ($1.project_count ?? 0) }
            .prefix(5)
            .map { customer in
                CustomerStats.TopCustomer(
                    customer_id: customer.customer_id,
                    name: customer.name,
                    project_count: customer.project_count ?? 0,
                    hiring_request_count: customer.hiring_request_count ?? 0,
                    latest_project_date: customer.created_at
                )
            }
    }
    
    private func getRecentCustomers() -> [CustomerStats.RecentCustomer] {
        return customers
            .sorted { ($0.created_at ?? Date.distantPast) > ($1.created_at ?? Date.distantPast) }
            .prefix(5)
            .map { customer in
                let daysSince = customer.created_at.map { Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0 } ?? 0
                return CustomerStats.RecentCustomer(
                    customer_id: customer.customer_id,
                    name: customer.name,
                    contact_email: customer.contact_email,
                    created_at: customer.created_at,
                    days_since_created: daysSince
                )
            }
    }
    
    // MARK: - Logo Statistics
    
    func getCustomersWithLogosCount() -> Int {
        return customersWithLogos.count
    }
    
    func getCustomersWithoutLogosCount() -> Int {
        return customers.count - customersWithLogos.count
    }
    
    func getLogoCompletionPercentage() -> Double {
        guard !customers.isEmpty else { return 0.0 }
        return (Double(customersWithLogos.count) / Double(customers.count)) * 100
    }
    
    func getCustomersWithLogos() -> [Customer] {
        return customers.filter { customersWithLogos.contains($0.customer_id) }
    }
    
    func getCustomersWithoutLogos() -> [Customer] {
        return customers.filter { !customersWithLogos.contains($0.customer_id) }
    }
    
    // MARK: - Utility Methods
    
    func refreshData() {
        loadCustomers()
        loadCustomerStats()
    }
    
    func getCustomer(by id: Int) -> Customer? {
        return customers.first { $0.customer_id == id }
    }
    
    func getCustomersWithProjects() -> [Customer] {
        return customers.filter { ($0.project_count ?? 0) > 0 }
    }
    
    func getRecentCustomers(days: Int = 30) -> [Customer] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return customers.filter { customer in
            guard let createdAt = customer.created_at else { return false }
            return createdAt > cutoffDate
        }
    }
    
    func getCustomersNeedingAttention() -> [Customer] {
        // Customers without logos, email, or phone
        return customers.filter { customer in
            !customer.hasLogo ||
            customer.contact_email?.isEmpty ?? true ||
            customer.phone?.isEmpty ?? true
        }
    }
    
    func getProfileCompleteness(for customer: Customer) -> Double {
        var completeness = 1.0 // Name is always present (required)
        let totalFields = 5.0 // name, email, phone, address, logo
        
        if !(customer.contact_email?.isEmpty ?? true) { completeness += 1.0 }
        if !(customer.phone?.isEmpty ?? true) { completeness += 1.0 }
        if !(customer.address?.isEmpty ?? true) { completeness += 1.0 }
        if customer.hasLogo { completeness += 1.0 }
        
        return (completeness / totalFields) * 100
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
        case .unknown:
            title = "Unknown Error"
            message = "An unexpected error occurred while \(context)."
        }
        
        showError(title, message: message)
        
        #if DEBUG
        print("[CustomersViewModel] API Error in \(context): \(error)")
        #endif
    }
    
    // MARK: - Alert Helpers
    
    private func showError(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        
        #if DEBUG
        print("[CustomersViewModel] Error: \(title) - \(message)")
        #endif
    }
    
    private func showSuccess(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        
        #if DEBUG
        print("[CustomersViewModel] Success: \(title) - \(message)")
        #endif
    }
}

// MARK: - Extensions

extension CustomersViewModel {
    
    // MARK: - Validation Helpers
    
    func validateCustomerData(_ data: CreateCustomerRequest) -> ValidationResult {
        var errors: [String] = []
        
        // Name validation
        if data.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Company name is required")
        } else if data.name.count < 2 {
            errors.append("Company name must be at least 2 characters")
        } else if data.name.count > 255 {
            errors.append("Company name must be less than 255 characters")
        }
        
        // Email validation
        if let email = data.contact_email, !email.isEmpty {
            if !isValidEmail(email) {
                errors.append("Please enter a valid email address")
            }
        }
        
        // Phone validation
        if let phone = data.phone, !phone.isEmpty {
            if !isValidPhone(phone) {
                errors.append("Please enter a valid phone number")
            }
        }
        
        // CVR validation (Danish company registration number)
        if let cvr = data.cvr, !cvr.isEmpty {
            if !isValidCVR(cvr) {
                errors.append("Please enter a valid CVR number (8 digits)")
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
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
    
    // MARK: - Sorting and Filtering Helpers
    
    func sortCustomers(_ customers: [Customer], by option: CustomersListView.CustomerSortOption) -> [Customer] {
        switch option {
        case .name:
            return customers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .dateAdded:
            return customers.sorted {
                ($0.created_at ?? Date.distantPast) > ($1.created_at ?? Date.distantPast)
            }
        case .projectCount:
            return customers.sorted { ($0.project_count ?? 0) > ($1.project_count ?? 0) }
        case .lastActivity:
            return customers.sorted {
                ($0.created_at ?? Date.distantPast) > ($1.created_at ?? Date.distantPast)
            }
        }
    }
    
    func filterCustomers(_ customers: [Customer], by option: CustomersListView.CustomerFilterOption) -> [Customer] {
        switch option {
        case .all:
            return customers
        case .active:
            return customers.filter { ($0.project_count ?? 0) > 0 }
        case .inactive:
            return customers.filter { ($0.project_count ?? 0) == 0 }
        case .recent:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return customers.filter { customer in
                guard let createdAt = customer.created_at else { return false }
                return createdAt > thirtyDaysAgo
            }
        }
    }
    
    // MARK: - Logo-specific Filtering
    
    func filterCustomersByLogo(_ customers: [Customer], hasLogo: Bool?) -> [Customer] {
        guard let hasLogo = hasLogo else { return customers }
        
        if hasLogo {
            return customers.filter { $0.hasLogo }
        } else {
            return customers.filter { !$0.hasLogo }
        }
    }
}
