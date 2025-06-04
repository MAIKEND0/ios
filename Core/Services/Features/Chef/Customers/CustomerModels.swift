//
//  CustomerModels.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//  Updated with Logo Support
//

import Foundation

// MARK: - Customer Models

struct Customer: Codable, Identifiable {
    let customer_id: Int
    let name: String
    let contact_email: String?
    let phone: String?
    let address: String?
    let cvr_nr: String?
    let created_at: Date?
    
    // Logo fields
    let logo_url: String?
    let logo_key: String?
    let logo_uploaded_at: Date?
    
    // Additional fields from API
    let project_count: Int?
    let hiring_request_count: Int?
    let recent_projects: [ProjectSummary]?
    
    var id: Int { customer_id }
    
    // Computed properties for display
    var displayName: String {
        return name.isEmpty ? "Unnamed Customer" : name
    }
    
    var hasLogo: Bool {
        return logo_url != nil && !logo_url!.isEmpty
    }
    
    var hasContactInfo: Bool {
        return !(contact_email?.isEmpty ?? true) || !(phone?.isEmpty ?? true)
    }
    
    var formattedCVR: String? {
        guard let cvr = cvr_nr, !cvr.isEmpty else { return nil }
        return "CVR: \(cvr)"
    }
    
    var createdAtFormatted: String {
        guard let created_at = created_at else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: created_at)
    }
    
    var projectCountText: String {
        guard let count = project_count else { return "0 projects" }
        return count == 1 ? "1 project" : "\(count) projects"
    }
    
    var logoDisplayUrl: String? {
        return hasLogo ? logo_url : nil
    }
    
    // For search functionality
    func matches(searchText: String) -> Bool {
        let search = searchText.lowercased()
        return name.lowercased().contains(search) ||
               contact_email?.lowercased().contains(search) == true ||
               phone?.contains(search) == true ||
               cvr_nr?.contains(search) == true ||
               address?.lowercased().contains(search) == true
    }
}

struct CustomerDetail: Codable, Identifiable {
    let customer_id: Int
    let name: String
    let contact_email: String?
    let phone: String?
    let address: String?
    let cvr_nr: String?
    let created_at: Date?
    
    // Logo fields
    let logo_url: String?
    let logo_key: String?
    let logo_uploaded_at: Date?
    
    let project_count: Int
    let hiring_request_count: Int
    let projects: [ProjectDetail]
    let recent_hiring_requests: [HiringRequestSummary]
    
    var id: Int { customer_id }
    
    var hasLogo: Bool {
        return logo_url != nil && !logo_url!.isEmpty
    }
    
    // Convert to basic Customer model
    func toCustomer() -> Customer {
        return Customer(
            customer_id: customer_id,
            name: name,
            contact_email: contact_email,
            phone: phone,
            address: address,
            cvr_nr: cvr_nr,
            created_at: created_at,
            logo_url: logo_url,
            logo_key: logo_key,
            logo_uploaded_at: logo_uploaded_at,
            project_count: project_count,
            hiring_request_count: hiring_request_count,
            recent_projects: projects.prefix(3).map { $0.toProjectSummary() }
        )
    }
}

struct ProjectSummary: Codable, Identifiable {
    let project_id: Int
    let title: String
    let status: String?
    let created_at: Date?
    
    var id: Int { project_id }
}

struct ProjectDetail: Codable, Identifiable {
    let project_id: Int
    let title: String
    let status: String?
    let start_date: Date?
    let end_date: Date?
    let created_at: Date?
    
    var id: Int { project_id }
    
    func toProjectSummary() -> ProjectSummary {
        return ProjectSummary(
            project_id: project_id,
            title: title,
            status: status,
            created_at: created_at
        )
    }
}

struct HiringRequestSummary: Codable, Identifiable {
    let id: Int
    let projectName: String
    let status: String
    let startDate: Date
    let createdAt: Date
}

// MARK: - Request Models

struct CreateCustomerRequest: Codable {
    let name: String
    let contact_email: String?
    let phone: String?
    let address: String?
    let cvr: String? // Frontend uses 'cvr', backend expects 'cvr_nr'
    
    private enum CodingKeys: String, CodingKey {
        case name, contact_email, phone, address, cvr
    }
}

struct UpdateCustomerRequest: Codable {
    let name: String
    let contact_email: String?
    let phone: String?
    let address: String?
    let cvr: String?
    
    private enum CodingKeys: String, CodingKey {
        case name, contact_email, phone, address, cvr
    }
}

struct AdvancedCustomerSearchRequest: Codable {
    let query: String?
    let filters: SearchFilters?
    let sort: SortOptions?
    let limit: Int
    let offset: Int
    let include_projects: Bool
    let include_stats: Bool
    
    struct SearchFilters: Codable {
        let has_email: Bool?
        let has_phone: Bool?
        let has_cvr: Bool?
        let has_address: Bool?
        let has_projects: Bool?
        let created_after: Date?
        let created_before: Date?
        let project_status: [String]?
    }
    
    struct SortOptions: Codable {
        let field: String // name, created_at, project_count
        let direction: String // asc, desc
    }
}

// MARK: - Logo Response Models

struct LogoConfirmRequest: Codable {
    let logo_key: String
    let logo_url: String
}

struct LogoUploadResponse: Codable {
    let success: Bool
    let message: String
    let data: LogoUploadData
    
    struct LogoUploadData: Codable {
        let logo_url: String
        let logo_uploaded_at: Date
    }
}

struct PresignedUrlResponse: Codable {
    let success: Bool
    let data: PresignedUrlData
    
    struct PresignedUrlData: Codable {
        let upload_url: String
        let logo_key: String
        let logo_url: String
        let expires_in: Int
    }
}

// MARK: - Response Models

struct DeleteCustomerResponse: Codable {
    let success: Bool
    let message: String
}

struct CustomerSearchResponse: Codable {
    let customers: [CustomerSearchResult]
    let total: Int
    let query: String
    let has_more: Bool
    let pagination: PaginationInfo
    
    struct PaginationInfo: Codable {
        let limit: Int
        let offset: Int
        let total_pages: Int
        let current_page: Int
    }
}

struct CustomerSearchResult: Codable, Identifiable {
    let customer_id: Int
    let name: String
    let contact_email: String?
    let phone: String?
    let address: String?
    let cvr_nr: String?
    let created_at: Date?
    
    // Logo fields
    let logo_url: String?
    let logo_key: String?
    let logo_uploaded_at: Date?
    
    let project_count: Int?
    let hiring_request_count: Int?
    let recent_projects: [ProjectSummary]?
    let match_fields: [String]?
    
    var id: Int { customer_id }
    
    var hasLogo: Bool {
        return logo_url != nil && !logo_url!.isEmpty
    }
    
    // Convert to basic Customer model
    func toCustomer() -> Customer {
        return Customer(
            customer_id: customer_id,
            name: name,
            contact_email: contact_email,
            phone: phone,
            address: address,
            cvr_nr: cvr_nr,
            created_at: created_at,
            logo_url: logo_url,
            logo_key: logo_key,
            logo_uploaded_at: logo_uploaded_at,
            project_count: project_count,
            hiring_request_count: hiring_request_count,
            recent_projects: recent_projects
        )
    }
}

// MARK: - Enhanced Customer Statistics

struct CustomerStats: Codable {
    let total_customers: Int
    let new_this_month: Int
    let new_this_week: Int
    let new_today: Int
    let customers_with_projects: Int
    let customers_without_projects: Int
    let customers_with_active_projects: Int
    let customers_with_email: Int
    let customers_with_phone: Int
    let customers_with_cvr: Int
    let customers_with_address: Int
    let total_projects: Int
    let total_hiring_requests: Int
    let average_projects_per_customer: Double
    let top_customers_by_projects: [TopCustomer]
    let recent_customers: [RecentCustomer]
    let monthly_growth: [MonthlyGrowth]?
    
    struct TopCustomer: Codable, Identifiable {
        let customer_id: Int
        let name: String
        let project_count: Int
        let hiring_request_count: Int
        let latest_project_date: Date?
        
        var id: Int { customer_id }
    }
    
    struct RecentCustomer: Codable, Identifiable {
        let customer_id: Int
        let name: String
        let contact_email: String?
        let created_at: Date?
        let days_since_created: Int
        
        var id: Int { customer_id }
    }
    
    struct MonthlyGrowth: Codable {
        let month: String
        let year: Int
        let customer_count: Int
        let cumulative_count: Int
    }
    
    // Computed properties for easier display
    var completionRate: Double {
        guard customers_with_projects > 0 else { return 0.0 }
        return Double(customers_with_active_projects) / Double(customers_with_projects) * 100
    }
    
    var contactInfoCompleteness: Double {
        guard total_customers > 0 else { return 0.0 }
        let customersWithFullContact = customers_with_email + customers_with_phone
        return Double(customersWithFullContact) / Double(total_customers * 2) * 100
    }
    
    var growthThisMonth: Int {
        return new_this_month
    }
    
    var growthThisWeek: Int {
        return new_this_week
    }
    
    // Mock data for development - remove when API is ready
    static let mockData = CustomerStats(
        total_customers: 25,
        new_this_month: 5,
        new_this_week: 2,
        new_today: 1,
        customers_with_projects: 18,
        customers_without_projects: 7,
        customers_with_active_projects: 12,
        customers_with_email: 20,
        customers_with_phone: 22,
        customers_with_cvr: 15,
        customers_with_address: 18,
        total_projects: 45,
        total_hiring_requests: 78,
        average_projects_per_customer: 1.8,
        top_customers_by_projects: [
            TopCustomer(customer_id: 1, name: "Copenhagen Construction Group", project_count: 8, hiring_request_count: 15, latest_project_date: Date()),
            TopCustomer(customer_id: 2, name: "Nordic Building Solutions", project_count: 6, hiring_request_count: 12, latest_project_date: Date()),
            TopCustomer(customer_id: 3, name: "Øresund Development", project_count: 5, hiring_request_count: 10, latest_project_date: Date())
        ],
        recent_customers: [
            RecentCustomer(customer_id: 20, name: "New Company A/S", contact_email: "info@newcompany.dk", created_at: Date(), days_since_created: 2),
            RecentCustomer(customer_id: 21, name: "Fresh Construction", contact_email: "contact@fresh.dk", created_at: Calendar.current.date(byAdding: .day, value: -5, to: Date()), days_since_created: 5)
        ],
        monthly_growth: []
    )
}

// MARK: - Mock Data for Development

extension Customer {
    static let mockData: [Customer] = [
        Customer(
            customer_id: 1,
            name: "Copenhagen Construction Group",
            contact_email: "contact@copenhagen-construction.dk",
            phone: "+45 33 12 34 56",
            address: "Vesterbrogade 123, 1620 København V",
            cvr_nr: "12345678",
            created_at: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
            logo_url: nil,
            logo_key: nil,
            logo_uploaded_at: nil,
            project_count: 8,
            hiring_request_count: 15,
            recent_projects: []
        ),
        Customer(
            customer_id: 2,
            name: "Nordic Building Solutions",
            contact_email: "info@nordic-building.dk",
            phone: "+45 70 20 30 40",
            address: "Nørrebrogade 45, 2200 København N",
            cvr_nr: "87654321",
            created_at: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
            logo_url: "https://example.com/logos/nordic-building.jpg",
            logo_key: "customer-logos/customer-2/logo-123456.jpg",
            logo_uploaded_at: Date(),
            project_count: 6,
            hiring_request_count: 12,
            recent_projects: []
        ),
        Customer(
            customer_id: 3,
            name: "Øresund Development",
            contact_email: "projects@oresund-dev.dk",
            phone: "+45 32 45 67 89",
            address: "Amager Boulevard 78, 2300 København S",
            cvr_nr: "11223344",
            created_at: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
            logo_url: nil,
            logo_key: nil,
            logo_uploaded_at: nil,
            project_count: 5,
            hiring_request_count: 10,
            recent_projects: []
        ),
        Customer(
            customer_id: 4,
            name: "Danish Infrastructure Partners",
            contact_email: "contact@dip.dk",
            phone: "+45 45 67 89 01",
            address: "Frederiksberg Allé 12, 1820 Frederiksberg",
            cvr_nr: "55667788",
            created_at: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            logo_url: "https://example.com/logos/dip-logo.png",
            logo_key: "customer-logos/customer-4/logo-789012.png",
            logo_uploaded_at: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
            project_count: 3,
            hiring_request_count: 8,
            recent_projects: []
        ),
        Customer(
            customer_id: 5,
            name: "Malmö Construction AB",
            contact_email: "info@malmo-construction.se",
            phone: "+46 40 123 456",
            address: "Storgatan 25, 211 34 Malmö, Sweden",
            cvr_nr: "99887766",
            created_at: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            logo_url: nil,
            logo_key: nil,
            logo_uploaded_at: nil,
            project_count: 2,
            hiring_request_count: 5,
            recent_projects: []
        )
    ]
}

// MARK: - Helper Types

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    
    var errorMessage: String {
        return errors.joined(separator: "\n")
    }
}
