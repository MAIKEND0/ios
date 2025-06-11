//
//  CertificateSelectionViewModel.swift
//  KSR Cranes App
//  ViewModel for certificate selection during worker creation/editing
//

import Foundation
import Combine

@MainActor
final class CertificateSelectionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var certificateTypes: [CertificateType] = []
    @Published var selectionStates: [CertificateSelectionState] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // MARK: - Private Properties
    
    private let certificateAPIService = CertificateAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        print("[CertificateSelectionVM] 🎯 Initializing CertificateSelectionViewModel")
    }
    
    deinit {
        print("[CertificateSelectionVM] 🔄 Deinitializing CertificateSelectionViewModel")
    }
    
    // MARK: - Public Methods
    
    func loadCertificateTypes() async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
            showError = false
        }
        
        print("[CertificateSelectionVM] 🔍 Loading certificate types...")
        
        certificateAPIService.fetchCertificateTypes()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    switch completion {
                    case .finished:
                        print("[CertificateSelectionVM] ✅ Successfully loaded certificate types")
                    case .failure(let error):
                        print("[CertificateSelectionVM] ❌ Failed to load certificate types: \(error)")
                        self.handleError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    self.certificateTypes = response.certificateTypes
                    self.initializeSelectionStates()
                    
                    print("[CertificateSelectionVM] 📋 Loaded \(response.certificateTypes.count) certificate types")
                }
            )
            .store(in: &cancellables)
    }
    
    func updateExistingSelections(_ existingCertificates: [CertificateSelectionState]) {
        print("[CertificateSelectionVM] 🔄 Updating existing certificate selections")
        
        // Reset all selection states
        initializeSelectionStates()
        
        // Apply existing selections
        for existingCert in existingCertificates {
            if let index = selectionStates.firstIndex(where: { $0.certificateType.id == existingCert.certificateType.id }) {
                selectionStates[index] = existingCert
                print("[CertificateSelectionVM] ✅ Applied existing selection for: \(existingCert.certificateType.displayName)")
            }
        }
    }
    
    func getSelectedCertificates() -> [CertificateSelectionState] {
        let selected = selectionStates.filter { $0.isSelected }
        print("[CertificateSelectionVM] 📤 Returning \(selected.count) selected certificates")
        return selected
    }
    
    func getCreateCertificateRequests(for workerId: Int) -> [CreateWorkerCertificateRequest] {
        let selectedCertificates = getSelectedCertificates()
        
        let requests = selectedCertificates.map { state in
            CreateWorkerCertificateRequest(
                employeeId: workerId,
                certificateTypeId: state.certificateType.id,
                skillName: state.certificateType.displayName,
                skillLevel: state.skillLevel.rawValue,
                isCertified: state.isCertified,
                certificationNumber: state.certificationNumber.isEmpty ? nil : state.certificationNumber,
                certificationExpires: state.certificationExpires,
                yearsExperience: state.yearsExperience,
                craneTypeSpecialization: nil,
                notes: state.notes.isEmpty ? nil : state.notes
            )
        }
        
        print("[CertificateSelectionVM] 📝 Generated \(requests.count) certificate requests for worker \(workerId)")
        return requests
    }
    
    // MARK: - Private Methods
    
    private func initializeSelectionStates() {
        selectionStates = certificateTypes.map { certificateType in
            CertificateSelectionState(certificateType: certificateType)
        }
        
        print("[CertificateSelectionVM] 🎯 Initialized \(selectionStates.count) selection states")
    }
    
    private func handleError(_ error: CertificateAPIService.APIError) {
        switch error {
        case .networkError(let error):
            errorMessage = "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            errorMessage = "Failed to process certificate data: \(error.localizedDescription)"
        case .invalidURL:
            errorMessage = "Invalid request URL"
        case .invalidResponse:
            errorMessage = "Invalid server response"
        case .serverError(let statusCode, let message):
            switch statusCode {
            case 401:
                errorMessage = "Authentication required"
            case 403:
                errorMessage = "Access denied"
            case 404:
                errorMessage = "Certificate service not available"
            default:
                errorMessage = "Server error (\(statusCode)): \(message)"
            }
        case .unknown:
            errorMessage = "Unexpected error occurred"
        }
        
        showError = true
        print("[CertificateSelectionVM] ⚠️ Error handled: \(errorMessage)")
    }
    
    // MARK: - Validation Methods
    
    func validateSelections() -> (isValid: Bool, errors: [String]) {
        let selectedCertificates = getSelectedCertificates()
        var errors: [String] = []
        
        for cert in selectedCertificates {
            // Validate certified certificates have required fields
            if cert.isCertified {
                if cert.certificationNumber.isEmpty {
                    errors.append("\(cert.certificateType.displayName): Certification number is required")
                }
                
                if let expiryDate = cert.certificationExpires, expiryDate < Date() {
                    errors.append("\(cert.certificateType.displayName): Certificate has expired")
                }
            }
            
            // Validate years of experience is reasonable
            if cert.yearsExperience < 0 || cert.yearsExperience > 50 {
                errors.append("\(cert.certificateType.displayName): Years of experience must be between 0 and 50")
            }
        }
        
        let isValid = errors.isEmpty
        print("[CertificateSelectionVM] 🔍 Validation result: \(isValid ? "✅ Valid" : "❌ Invalid") - \(errors.count) errors")
        
        return (isValid, errors)
    }
    
    // MARK: - Statistics Methods
    
    func getCertificateStatistics() -> CertificateSelectionStatistics {
        let selectedCount = selectionStates.filter { $0.isSelected }.count
        let certifiedCount = selectionStates.filter { $0.isSelected && $0.isCertified }.count
        let totalAvailableCount = certificateTypes.count
        
        let avgExperience = selectionStates
            .filter { $0.isSelected }
            .map { Double($0.yearsExperience) }
            .reduce(0, +) / Double(max(selectedCount, 1))
        
        return CertificateSelectionStatistics(
            totalAvailable: totalAvailableCount,
            selected: selectedCount,
            certified: certifiedCount,
            averageExperience: avgExperience
        )
    }
}

// MARK: - Certificate Selection Statistics

struct CertificateSelectionStatistics {
    let totalAvailable: Int
    let selected: Int
    let certified: Int
    let averageExperience: Double
    
    var selectionPercentage: Double {
        guard totalAvailable > 0 else { return 0 }
        return Double(selected) / Double(totalAvailable) * 100
    }
    
    var certificationPercentage: Double {
        guard selected > 0 else { return 0 }
        return Double(certified) / Double(selected) * 100
    }
    
    var summary: String {
        return "\(selected) of \(totalAvailable) certificates selected (\(certified) certified)"
    }
}