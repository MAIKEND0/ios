//
//  CertificateAPIService.swift
//  KSR Cranes App
//  API service for Danish crane certificates management
//

import Foundation
import Combine

final class CertificateAPIService: BaseAPIService {
    static let shared = CertificateAPIService()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Certificate Types
    
    /// Fetch all available certificate types
    func fetchCertificateTypes() -> AnyPublisher<CertificateTypesResponse, APIError> {
        let endpoint = "/api/app/chef/certificates"
        
        print("[CertificateAPI] 🔍 Fetching certificate types from: \(endpoint)")
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: CertificateTypesResponse.self, decoder: jsonDecoder())
            .mapError { error in
                print("[CertificateAPI] ❌ Failed to fetch certificate types: \(error)")
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Fetch specific certificate type by ID
    func fetchCertificateType(id: Int) -> AnyPublisher<CertificateType, APIError> {
        let endpoint = "/api/app/chef/certificates/\(id)"
        
        print("[CertificateAPI] 🔍 Fetching certificate type \(id) from: \(endpoint)")
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: CertificateType.self, decoder: jsonDecoder())
            .mapError { error in
                print("[CertificateAPI] ❌ Failed to fetch certificate type \(id): \(error)")
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Worker Certificates
    
    /// Fetch certificates for a specific worker
    func fetchWorkerCertificates(workerId: Int) -> AnyPublisher<WorkerCertificatesResponse, APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/certificates"
        
        print("[CertificateAPI] 🔍 Fetching certificates for worker \(workerId) from: \(endpoint)")
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: WorkerCertificatesResponse.self, decoder: jsonDecoder())
            .mapError { error in
                print("[CertificateAPI] ❌ Failed to fetch certificates for worker \(workerId): \(error)")
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Add certificate to worker
    func addCertificateToWorker(workerId: Int, request: CreateWorkerCertificateRequest) -> AnyPublisher<CertificateCreateResponse, APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/certificates"
        
        print("[CertificateAPI] ➕ Adding certificate to worker \(workerId): \(request.skillName)")
        
        return makeRequest(endpoint: endpoint, method: "POST", body: request)
            .decode(type: CertificateCreateResponse.self, decoder: jsonDecoder())
            .mapError { error in
                print("[CertificateAPI] ❌ Failed to add certificate to worker \(workerId): \(error)")
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Update worker certificate
    func updateWorkerCertificate(workerId: Int, certificateId: Int, request: UpdateWorkerCertificateRequest) -> AnyPublisher<CertificateUpdateResponse, APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/certificates/\(certificateId)"
        
        print("[CertificateAPI] 🔄 Updating certificate \(certificateId) for worker \(workerId)")
        
        return makeRequest(endpoint: endpoint, method: "PUT", body: request)
            .decode(type: CertificateUpdateResponse.self, decoder: jsonDecoder())
            .mapError { error in
                print("[CertificateAPI] ❌ Failed to update certificate \(certificateId) for worker \(workerId): \(error)")
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Remove certificate from worker
    func removeCertificateFromWorker(workerId: Int, certificateId: Int) -> AnyPublisher<CertificateDeleteResponse, APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/certificates/\(certificateId)"
        
        print("[CertificateAPI] 🗑️ Removing certificate \(certificateId) from worker \(workerId)")
        
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: CertificateDeleteResponse.self, decoder: jsonDecoder())
            .mapError { error in
                print("[CertificateAPI] ❌ Failed to remove certificate \(certificateId) from worker \(workerId): \(error)")
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Bulk add certificates to worker (for initial worker creation)
    func addMultipleCertificatesToWorker(workerId: Int, certificates: [CreateWorkerCertificateRequest]) -> AnyPublisher<[CertificateCreateResponse], APIError> {
        let publishers = certificates.map { request in
            addCertificateToWorker(workerId: workerId, request: request)
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    /// Get required certificates for a crane category
    func getRequiredCertificatesForCategory(categoryId: Int) -> AnyPublisher<[CertificateType], APIError> {
        let endpoint = "/api/app/chef/crane-categories/\(categoryId)/required-certificates"
        
        print("[CertificateAPI] 🔍 Fetching required certificates for category \(categoryId)")
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: CertificateTypesResponse.self, decoder: jsonDecoder())
            .map { response in
                print("[CertificateAPI] ✅ Successfully fetched \(response.certificateTypes.count) required certificates for category \(categoryId)")
                return response.certificateTypes
            }
            .mapError { error in
                print("[CertificateAPI] ❌ Failed to fetch required certificates for category \(categoryId): \(error)")
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Find available workers with specific certificates
    func findWorkersWithCertificates(certificateIds: [Int], includeExpired: Bool = false) -> AnyPublisher<[WorkerForChef], APIError> {
        var endpoint = "/api/app/chef/workers/with-certificates"
        var queryParams: [String] = []
        
        for certId in certificateIds {
            queryParams.append("certificate_ids=\(certId)")
        }
        if includeExpired {
            queryParams.append("include_expired=true")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        print("[CertificateAPI] 🔍 Finding workers with certificates \(certificateIds)")
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: WorkerSearchResponse.self, decoder: jsonDecoder())
            .map { response in
                print("[CertificateAPI] ✅ Found \(response.workers.count) workers with required certificates")
                return response.workers
            }
            .mapError { error in
                print("[CertificateAPI] ❌ Failed to find workers with certificates: \(error)")
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Certificate Validation
    
    /// Validate worker certificates for task assignment
    func validateWorkerCertificatesForTask(workerId: Int, taskId: Int) -> AnyPublisher<CertificateValidationResponse, APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/validate-certificates"
        
        let request = CertificateValidationRequest(taskId: taskId)
        
        print("[CertificateAPI] 🔍 Validating certificates for worker \(workerId) and task \(taskId)")
        
        return makeRequest(endpoint: endpoint, method: "POST", body: request)
            .decode(type: CertificateValidationResponse.self, decoder: jsonDecoder())
            .mapError { error in
                print("[CertificateAPI] ❌ Certificate validation failed for worker \(workerId): \(error)")
                return (error as? APIError) ?? .decodingError(error)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Certificate Validation Models

struct CertificateValidationRequest: Codable {
    let taskId: Int
    
    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
    }
}

struct CertificateValidationResponse: Codable {
    let isValid: Bool
    let missingCertificates: [CertificateType]
    let expiredCertificates: [WorkerCertificate]
    let expiringSoonCertificates: [WorkerCertificate]
    let validationDetails: String
    
    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case missingCertificates = "missing_certificates"
        case expiredCertificates = "expired_certificates"
        case expiringSoonCertificates = "expiring_soon_certificates"
        case validationDetails = "validation_details"
    }
    
    var canAssignToTask: Bool {
        return isValid && expiredCertificates.isEmpty
    }
    
    var warningsExist: Bool {
        return !expiringSoonCertificates.isEmpty
    }
    
    var validationSummary: String {
        if isValid && !warningsExist {
            return "Worker has all required valid certificates"
        } else if isValid && warningsExist {
            return "Worker qualified but has certificates expiring soon"
        } else {
            return "Worker missing required certificates or has expired certificates"
        }
    }
}