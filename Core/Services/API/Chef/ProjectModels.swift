//
//  ProjectModels.swift
//  KSR Cranes App
//
//  Data models for project and task management
//

import Foundation
import SwiftUI

// MARK: - API Response Models (DODANE)

struct CreateProjectResponse: Codable {
    let project: Project
    let billingSettings: BillingSettings?
    
    enum CodingKeys: String, CodingKey {
        case project
        case billingSettings = "billing_settings"
    }
}

struct ProjectsListResponse: Codable {
    let projects: [Project]
    let totalCount: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case projects
        case totalCount = "total_count"
        case hasMore = "has_more"
    }
}

// MARK: - Project Models

struct Project: Identifiable, Codable {
    let id: Int
    let title: String
    let description: String?
    let startDate: Date?
    let endDate: Date?
    let status: ProjectStatus
    let customerId: Int?
    let customer: Customer?
    let street: String?
    let city: String?
    let zip: String?
    let isActive: Bool
    let createdAt: Date?
    
    // Computed/included fields
    let tasksCount: Int?
    let assignedWorkersCount: Int?
    let completionPercentage: Double?
    
    enum ProjectStatus: String, Codable, CaseIterable {
        case waiting = "afventer"
        case active = "aktiv"
        case completed = "afsluttet"
        
        var displayName: String {
            switch self {
            case .waiting: return "Waiting"
            case .active: return "Active"
            case .completed: return "Completed"
            }
        }
        
        // ✅ POPRAWKA: Użyj kolorów z Color+Extensions.swift
        var color: Color {
            switch self {
            case .waiting: return .ksrWarning  // było Color.orange
            case .active: return .ksrSuccess   // było Color.green
            case .completed: return .ksrInfo   // było Color.blue
            }
        }
        
        var icon: String {
            switch self {
            case .waiting: return "clock.fill"
            case .active: return "play.circle.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }
    
    // ✅ POPRAWKA: Dodano mapowanie dla "Customers"
    private enum CodingKeys: String, CodingKey {
        case id = "project_id"
        case title
        case description
        case startDate = "start_date"
        case endDate = "end_date"
        case status
        case customerId = "customer_id"
        case customer = "Customers"  // ← KLUCZOWA POPRAWKA: API zwraca "Customers"
        case street
        case city
        case zip
        case isActive
        case createdAt = "created_at"
        case tasksCount = "tasks_count"
        case assignedWorkersCount = "assigned_workers_count"
        case completionPercentage = "completion_percentage"
    }
    
    // Custom initializer for creating projects
    init(
        id: Int,
        title: String,
        description: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        status: ProjectStatus,
        customerId: Int? = nil,
        customer: Customer? = nil,
        street: String? = nil,
        city: String? = nil,
        zip: String? = nil,
        isActive: Bool = true,
        createdAt: Date? = nil,
        tasksCount: Int? = nil,
        assignedWorkersCount: Int? = nil,
        completionPercentage: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.customerId = customerId
        self.customer = customer
        self.street = street
        self.city = city
        self.zip = zip
        self.isActive = isActive
        self.createdAt = createdAt
        self.tasksCount = tasksCount
        self.assignedWorkersCount = assignedWorkersCount
        self.completionPercentage = completionPercentage
    }
}

// MARK: - Task Models (renamed from Task to avoid conflict with Swift's Task)

struct ProjectTask: Identifiable, Codable {
    let id: Int
    let projectId: Int
    let title: String
    let description: String?
    let deadline: Date?
    let supervisorId: Int?
    let supervisorName: String?
    let supervisorEmail: String?
    let supervisorPhone: String?
    let isActive: Bool
    let createdAt: Date?
    
    // Relations
    let assignmentsCount: Int?
    let project: Project?
    let conversation: ConversationInfo?
    
    private enum CodingKeys: String, CodingKey {
        case id = "task_id"
        case projectId = "project_id"
        case title
        case description
        case deadline
        case supervisorId = "supervisor_id"
        case supervisorName = "supervisor_name"
        case supervisorEmail = "supervisor_email"
        case supervisorPhone = "supervisor_phone"
        case isActive
        case createdAt = "created_at"
        case assignmentsCount = "assignments_count"
        case project
        case conversation
    }
}

// MARK: - Task Assignment Models

struct TaskAssignment: Identifiable, Codable {
    let id: Int
    let taskId: Int
    let employeeId: Int
    let assignedAt: Date?
    let craneModelId: Int?
    
    // Relations
    let employee: Employee?
    let craneModel: CraneModel?
    
    private enum CodingKeys: String, CodingKey {
        case id = "assignment_id"
        case taskId = "task_id"
        case employeeId = "employee_id"
        case assignedAt = "assigned_at"
        case craneModelId = "crane_model_id"
        case employee
        case craneModel = "crane_model"
    }
}

// MARK: - Employee Models - ✅ FIXED VERSION

struct Employee: Identifiable, Codable {
    let id: Int
    let name: String
    let email: String
    let role: String
    let phoneNumber: String?
    let profilePictureUrl: String?
    let isActivated: Bool? // ✅ FIXED: Now optional to match API response
    let craneTypes: [EmployeeCraneType]?
    let address: String?
    let emergencyContact: String?
    let cprNumber: String?
    let birthDate: Date?
    let hasDrivingLicense: Bool?
    let drivingLicenseCategory: String?
    let drivingLicenseExpiration: Date?
    
    var employeeId: Int { id } // Alias for compatibility
    
    // ✅ ADDED: Safe computed property for activation status
    var isActiveEmployee: Bool {
        return isActivated ?? true // Default to true if API doesn't provide this field
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "employee_id"
        case name
        case email
        case role
        case phoneNumber = "phone_number"
        case profilePictureUrl
        case isActivated = "is_activated" // This field may not exist in API response
        case craneTypes = "crane_types"
        case address
        case emergencyContact = "emergency_contact"
        case cprNumber = "cpr_number"
        case birthDate = "birth_date"
        case hasDrivingLicense = "has_driving_license"
        case drivingLicenseCategory = "driving_license_category"
        case drivingLicenseExpiration = "driving_license_expiration"
    }
}

struct EmployeeCraneType: Codable {
    let craneTypeId: Int
    let name: String
    let certificationDate: Date?
    
    private enum CodingKeys: String, CodingKey {
        case craneTypeId = "crane_type_id"
        case name
        case certificationDate = "certification_date"
    }
}

// MARK: - Crane Models

struct CraneType: Identifiable, Codable {
    let id: Int
    let categoryId: Int
    let name: String
    let code: String
    let description: String?
    let technicalSpecs: [String: Any]?
    let iconUrl: String?
    let imageUrl: String?
    let displayOrder: Int
    let isActive: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case name
        case code
        case description
        case technicalSpecs = "technical_specs"
        case iconUrl = "icon_url"
        case imageUrl = "image_url"
        case displayOrder = "display_order"
        case isActive
    }
    
    // Custom encoding/decoding for technicalSpecs
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        categoryId = try container.decode(Int.self, forKey: .categoryId)
        name = try container.decode(String.self, forKey: .name)
        code = try container.decode(String.self, forKey: .code)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Handle JSON field
        if let specsData = try container.decodeIfPresent(Data.self, forKey: .technicalSpecs),
           let specs = try? JSONSerialization.jsonObject(with: specsData) as? [String: Any] {
            technicalSpecs = specs
        } else {
            technicalSpecs = nil
        }
        
        iconUrl = try container.decodeIfPresent(String.self, forKey: .iconUrl)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        displayOrder = try container.decode(Int.self, forKey: .displayOrder)
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(name, forKey: .name)
        try container.encode(code, forKey: .code)
        try container.encodeIfPresent(description, forKey: .description)
        
        if let specs = technicalSpecs,
           let specsData = try? JSONSerialization.data(withJSONObject: specs) {
            try container.encode(specsData, forKey: .technicalSpecs)
        }
        
        try container.encodeIfPresent(iconUrl, forKey: .iconUrl)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(displayOrder, forKey: .displayOrder)
        try container.encode(isActive, forKey: .isActive)
    }
}

struct CraneModel: Identifiable, Codable {
    let id: Int
    let brandId: Int
    let typeId: Int
    let name: String
    let code: String
    let description: String?
    let maxLoadCapacity: Decimal?
    let maxHeight: Decimal?
    let maxRadius: Decimal?
    let enginePower: Int?
    let specifications: [String: Any]?
    let imageUrl: String?
    let brochureUrl: String?
    let videoUrl: String?
    let releaseYear: Int?
    let isDiscontinued: Bool
    let isActive: Bool
    
    // Relations
    let brandName: String?
    let typeName: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case brandId = "brand_id"
        case typeId = "type_id"
        case name
        case code
        case description
        case maxLoadCapacity = "max_load_capacity"
        case maxHeight = "max_height"
        case maxRadius = "max_radius"
        case enginePower = "engine_power"
        case specifications
        case imageUrl = "image_url"
        case brochureUrl = "brochure_url"
        case videoUrl = "video_url"
        case releaseYear = "release_year"
        case isDiscontinued = "is_discontinued"
        case isActive
        case brandName = "brand_name"
        case typeName = "type_name"
    }
    
    // Custom encoding/decoding for specifications JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        brandId = try container.decode(Int.self, forKey: .brandId)
        typeId = try container.decode(Int.self, forKey: .typeId)
        name = try container.decode(String.self, forKey: .name)
        code = try container.decode(String.self, forKey: .code)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        maxLoadCapacity = try container.decodeIfPresent(Decimal.self, forKey: .maxLoadCapacity)
        maxHeight = try container.decodeIfPresent(Decimal.self, forKey: .maxHeight)
        maxRadius = try container.decodeIfPresent(Decimal.self, forKey: .maxRadius)
        enginePower = try container.decodeIfPresent(Int.self, forKey: .enginePower)
        
        // Handle JSON field
        if let specsData = try container.decodeIfPresent(Data.self, forKey: .specifications),
           let specs = try? JSONSerialization.jsonObject(with: specsData) as? [String: Any] {
            specifications = specs
        } else {
            specifications = nil
        }
        
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        brochureUrl = try container.decodeIfPresent(String.self, forKey: .brochureUrl)
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        releaseYear = try container.decodeIfPresent(Int.self, forKey: .releaseYear)
        isDiscontinued = try container.decode(Bool.self, forKey: .isDiscontinued)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        brandName = try container.decodeIfPresent(String.self, forKey: .brandName)
        typeName = try container.decodeIfPresent(String.self, forKey: .typeName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(brandId, forKey: .brandId)
        try container.encode(typeId, forKey: .typeId)
        try container.encode(name, forKey: .name)
        try container.encode(code, forKey: .code)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(maxLoadCapacity, forKey: .maxLoadCapacity)
        try container.encodeIfPresent(maxHeight, forKey: .maxHeight)
        try container.encodeIfPresent(maxRadius, forKey: .maxRadius)
        try container.encodeIfPresent(enginePower, forKey: .enginePower)
        
        if let specs = specifications,
           let specsData = try? JSONSerialization.data(withJSONObject: specs) {
            try container.encode(specsData, forKey: .specifications)
        }
        
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(brochureUrl, forKey: .brochureUrl)
        try container.encodeIfPresent(videoUrl, forKey: .videoUrl)
        try container.encodeIfPresent(releaseYear, forKey: .releaseYear)
        try container.encode(isDiscontinued, forKey: .isDiscontinued)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(brandName, forKey: .brandName)
        try container.encodeIfPresent(typeName, forKey: .typeName)
    }
}

// MARK: - Request Models

struct CreateProjectRequest: Codable {
    let title: String
    let description: String?
    let customerId: Int
    let startDate: Date?
    let endDate: Date?
    let street: String?
    let city: String?
    let zip: String?
    let status: String
    let billingSettings: BillingSettingsRequest?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case customerId = "customer_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case street
        case city
        case zip
        case status
        case billingSettings = "billing_settings"
    }
}

struct BillingSettingsRequest: Codable {
    let normalRate: Decimal
    let weekendRate: Decimal
    let overtimeRate1: Decimal
    let overtimeRate2: Decimal
    let weekendOvertimeRate1: Decimal
    let weekendOvertimeRate2: Decimal
    let effectiveFrom: Date
    let effectiveTo: Date?
    
    private enum CodingKeys: String, CodingKey {
        case normalRate = "normal_rate"
        case weekendRate = "weekend_rate"
        case overtimeRate1 = "overtime_rate1"
        case overtimeRate2 = "overtime_rate2"
        case weekendOvertimeRate1 = "weekend_overtime_rate1"
        case weekendOvertimeRate2 = "weekend_overtime_rate2"
        case effectiveFrom = "effective_from"
        case effectiveTo = "effective_to"
    }
}

struct CreateTaskRequest: Codable {
    let title: String
    let description: String?
    let deadline: Date?
    let supervisorId: Int?
    let supervisorName: String?
    let supervisorEmail: String?
    let supervisorPhone: String?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case deadline
        case supervisorId = "supervisor_id"
        case supervisorName = "supervisor_name"
        case supervisorEmail = "supervisor_email"
        case supervisorPhone = "supervisor_phone"
    }
}

// MARK: - Supporting Models

struct ConversationInfo: Codable {
    let conversationId: Int
    let participantsCount: Int
    let messagesCount: Int
    let lastMessageAt: Date?
    
    private enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case participantsCount = "participants_count"
        case messagesCount = "messages_count"
        case lastMessageAt = "last_message_at"
    }
}

// ✅ DODANY: Billing Settings Response Model
struct BillingSettings: Codable {
    let settingId: Int
    let projectId: Int
    let normalRate: Decimal
    let weekendRate: Decimal
    let overtimeRate1: Decimal
    let overtimeRate2: Decimal
    let weekendOvertimeRate1: Decimal
    let weekendOvertimeRate2: Decimal
    let effectiveFrom: Date
    let effectiveTo: Date?
    
    enum CodingKeys: String, CodingKey {
        case settingId = "setting_id"
        case projectId = "project_id"
        case normalRate = "normal_rate"
        case weekendRate = "weekend_rate"
        case overtimeRate1 = "overtime_rate1"
        case overtimeRate2 = "overtime_rate2"
        case weekendOvertimeRate1 = "weekend_overtime_rate1"
        case weekendOvertimeRate2 = "weekend_overtime_rate2"
        case effectiveFrom = "effective_from"
        case effectiveTo = "effective_to"
    }
}

// ✅ DODANY: Custom JSON Decoder for API
extension JSONDecoder {
    static var ksrApiDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        
        // Custom date decoding strategy for API format: "2025-06-01T14:53:05.000Z"
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try API format with milliseconds first
            let apiFormatter = DateFormatter()
            apiFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            apiFormatter.timeZone = TimeZone(abbreviation: "UTC")
            
            if let date = apiFormatter.date(from: dateString) {
                return date
            }
            
            // Try without milliseconds
            apiFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            if let date = apiFormatter.date(from: dateString) {
                return date
            }
            
            // Fallback to ISO8601
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date from: \(dateString)"
            )
        }
        
        return decoder
    }
}

// MARK: - Compatibility Note
// Using ProjectTask everywhere instead of Task to avoid conflicts with Swift.Task
// Customer, AvailableWorker, WorkerAvailability, TaskConflict types are defined in other files
