//
//  CertificateModels.swift
//  KSR Cranes App
//  Danish crane operator certificate models
//

import Foundation
import SwiftUI

// MARK: - Certificate Type Model

struct CertificateType: Codable, Identifiable, Hashable {
    let id: Int
    let code: String
    let nameDa: String
    let nameEn: String
    let description: String?
    let equipmentTypes: String?
    let capacityRange: String?
    let requiresMedical: Bool
    let minAge: Int
    let isActive: Bool
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "certificate_type_id"
        case code
        case nameDa = "name_da"
        case nameEn = "name_en"
        case description
        case equipmentTypes = "equipment_types"
        case capacityRange = "capacity_range"
        case requiresMedical = "requires_medical"
        case minAge = "min_age"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Display properties
    var displayName: String {
        return nameEn
    }
    
    var displayNameDanish: String {
        return nameDa
    }
    
    var shortCode: String {
        return code
    }
    
    var icon: String {
        switch code {
        case "CLASS_A": return "building.2.crop.circle"
        case "CLASS_B": return "truck.pickup.side"
        case "CLASS_C": return "gear.circle"
        case "CLASS_D": return "truck.box"
        case "CLASS_E": return "truck.box.fill"
        case "CLASS_G": return "hammer.circle"
        case "TELESCOPIC": return "arrow.up.and.down.and.arrow.left.and.right"
        case "CRANE_BASIS": return "graduationcap.circle"
        case "RIGGER": return "link.circle"
        default: return "checkmark.seal"
        }
    }
    
    var color: Color {
        switch code {
        case "CLASS_A", "CLASS_B": return .ksrPrimary
        case "CLASS_C", "CLASS_D", "CLASS_E": return .ksrSuccess
        case "CLASS_G": return .ksrWarning
        case "TELESCOPIC": return .ksrSecondary
        case "CRANE_BASIS": return .ksrInfo
        case "RIGGER": return .orange
        default: return .gray
        }
    }
}

// MARK: - Worker Certificate Model

struct WorkerCertificate: Codable, Identifiable {
    let id: Int
    let employeeId: Int?
    let certificateTypeId: Int?
    let certificateType: CertificateType?
    let skillName: String
    let skillLevel: String // Changed to String to handle different skill level formats
    let isCertified: Bool
    let certificationNumber: String?
    let certificationExpires: Date?
    let yearsExperience: Int
    let craneTypeSpecialization: String?
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "skill_id"
        case employeeId = "employee_id"
        case certificateTypeId = "certificate_type_id"
        case certificateType = "CertificateTypes"
        case skillName = "skill_name"
        case skillLevel = "skill_level"
        case isCertified = "is_certified"
        case certificationNumber = "certification_number"
        case certificationExpires = "certification_expires"
        case yearsExperience = "years_experience"
        case craneTypeSpecialization = "crane_type_specialization"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Status computed properties
    var isExpiringSoon: Bool {
        guard let expiryDate = certificationExpires else { return false }
        return expiryDate.timeIntervalSinceNow < 30 * 24 * 3600 // 30 days
    }
    
    var isExpired: Bool {
        guard let expiryDate = certificationExpires else { return false }
        return expiryDate < Date()
    }
    
    var isValid: Bool {
        return isCertified && !isExpired
    }
    
    var statusColor: Color {
        if !isCertified { return .gray }
        if isExpired { return .red }
        if isExpiringSoon { return .orange }
        return .green
    }
    
    var statusText: String {
        if !isCertified { return "Not Certified" }
        if isExpired { return "Expired" }
        if isExpiringSoon { return "Expiring Soon" }
        return "Valid"
    }
    
    var expiryDateFormatted: String {
        guard let expiryDate = certificationExpires else { return "No expiry" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: expiryDate)
    }
    
    var displayName: String {
        return certificateType?.displayName ?? skillName
    }
    
    var icon: String {
        return certificateType?.icon ?? "checkmark.seal"
    }
    
    var color: Color {
        return certificateType?.color ?? .gray
    }
}

// MARK: - Skill Level Enum

enum CertificateSkillLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .gray
        case .intermediate: return .blue
        case .advanced: return .green
        case .expert: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .beginner: return "1.circle"
        case .intermediate: return "2.circle"
        case .advanced: return "3.circle"
        case .expert: return "star.circle"
        }
    }
}

// MARK: - Certificate Selection State

struct CertificateSelectionState: Identifiable {
    let id = UUID()
    let certificateType: CertificateType
    var isSelected: Bool
    var isCertified: Bool
    var certificationExpires: Date?
    var yearsExperience: Int
    var skillLevel: CertificateSkillLevel
    var certificationNumber: String
    var notes: String
    
    init(certificateType: CertificateType) {
        self.certificateType = certificateType
        self.isSelected = false
        self.isCertified = true // Default to certified when adding a certificate
        self.certificationExpires = nil
        self.yearsExperience = 0
        self.skillLevel = .expert
        self.certificationNumber = ""
        self.notes = ""
    }
}

// MARK: - Request Models

struct CreateWorkerCertificateRequest: Codable {
    let employeeId: Int
    let certificateTypeId: Int
    let skillName: String
    let skillLevel: String
    let isCertified: Bool
    let certificationNumber: String?
    let certificationExpires: Date?
    let yearsExperience: Int
    let craneTypeSpecialization: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case employeeId = "employee_id"
        case certificateTypeId = "certificate_type_id"
        case skillName = "skill_name"
        case skillLevel = "skill_level"
        case isCertified = "is_certified"
        case certificationNumber = "certification_number"
        case certificationExpires = "certification_expires"
        case yearsExperience = "years_experience"
        case craneTypeSpecialization = "crane_type_specialization"
        case notes
    }
}

struct UpdateWorkerCertificateRequest: Codable {
    let skillLevel: String?
    let isCertified: Bool?
    let certificationNumber: String?
    let certificationExpires: Date?
    let yearsExperience: Int?
    let craneTypeSpecialization: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case skillLevel = "skill_level"
        case isCertified = "is_certified"
        case certificationNumber = "certification_number"
        case certificationExpires = "certification_expires"
        case yearsExperience = "years_experience"
        case craneTypeSpecialization = "crane_type_specialization"
        case notes
    }
}

// MARK: - Response Models

struct CertificateTypesResponse: Codable {
    let certificateTypes: [CertificateType]
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case certificateTypes = "certificate_types"
        case totalCount = "total_count"
    }
}

struct WorkerCertificatesResponse: Codable {
    let certificates: [WorkerCertificate]
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case certificates
        case totalCount = "total_count"
    }
}

struct CertificateCreateResponse: Codable {
    let success: Bool
    let message: String
    let certificate: WorkerCertificate?
}

struct CertificateUpdateResponse: Codable {
    let success: Bool
    let message: String
    let certificate: WorkerCertificate?
}

struct CertificateDeleteResponse: Codable {
    let success: Bool
    let message: String
    let certificateId: Int?
    
    enum CodingKeys: String, CodingKey {
        case success, message
        case certificateId = "certificate_id"
    }
}

