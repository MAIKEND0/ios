//
//  EditWorkerViewModel.swift
//  KSR Cranes App
//  ViewModel for editing existing workers
//

import Foundation
import Combine

class EditWorkerViewModel: ObservableObject {
    // Original worker data
    let originalWorker: WorkerForChef
    
    // Editable fields
    @Published var name: String
    @Published var email: String
    @Published var hourlyRate: String
    @Published var employmentType: EmploymentType
    @Published var role: WorkerRole
    @Published var status: WorkerStatus
    @Published var phone: String
    @Published var address: String
    @Published var notes: String
    
    // Certificate Management
    @Published var certificates: [WorkerCertificate] = []
    @Published var availableCertificateTypes: [CertificateType] = []
    @Published var isLoadingCertificates = false
    @Published var showCertificateSelection = false
    @Published var selectedCertificateStates: [CertificateSelectionState] = []
    
    // UI State
    @Published var isUpdating = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var workerUpdated = false
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = ChefWorkersAPIService.shared
    private let certificateService = CertificateAPIService.shared
    
    init(worker: WorkerForChef) {
        self.originalWorker = worker
        
        // Initialize fields with current values
        self.name = worker.name
        self.email = worker.email
        self.hourlyRate = String(Int(worker.hourly_rate))
        self.employmentType = worker.employment_type
        self.role = worker.role
        self.status = worker.status
        self.phone = worker.phone ?? ""
        self.address = worker.address ?? ""
        self.notes = "" // Notes field is not exposed in WorkerForChef model
        self.certificates = worker.certificates ?? []
        
        // Load certificate data
        loadCertificateTypes()
        loadWorkerCertificates()
    }
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               isValidEmail(email) &&
               !hourlyRate.isEmpty &&
               Double(hourlyRate) != nil &&
               Double(hourlyRate)! > 0
    }
    
    var hourlyRateValue: Double {
        return Double(hourlyRate) ?? 0.0
    }
    
    var hasChanges: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return trimmedName != originalWorker.name ||
               trimmedEmail != originalWorker.email.lowercased() ||
               hourlyRateValue != originalWorker.hourly_rate ||
               employmentType != originalWorker.employment_type ||
               role != originalWorker.role ||
               status != originalWorker.status ||
               (trimmedPhone.isEmpty ? nil : trimmedPhone) != originalWorker.phone ||
               (trimmedAddress.isEmpty ? nil : trimmedAddress) != originalWorker.address
    }
    
    var changedFieldsCount: Int {
        var count = 0
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName != originalWorker.name { count += 1 }
        if trimmedEmail != originalWorker.email.lowercased() { count += 1 }
        if hourlyRateValue != originalWorker.hourly_rate { count += 1 }
        if employmentType != originalWorker.employment_type { count += 1 }
        if role != originalWorker.role { count += 1 }
        if status != originalWorker.status { count += 1 }
        if (trimmedPhone.isEmpty ? nil : trimmedPhone) != originalWorker.phone { count += 1 }
        if (trimmedAddress.isEmpty ? nil : trimmedAddress) != originalWorker.address { count += 1 }
        
        return count
    }
    
    // MARK: - Methods
    
    func updateWorker(onSuccess: @escaping (WorkerForChef) -> Void) {
        guard isFormValid && hasChanges else {
            if !hasChanges {
                showError("No changes to save.")
            } else {
                showError("Please fill in all required fields correctly.")
            }
            return
        }
        
        guard !isUpdating else { return }
        
        #if DEBUG
        print("[EditWorkerViewModel] Updating worker: \(originalWorker.name)")
        #endif
        
        isUpdating = true
        
        // Build update request with only changed fields
        var updateData: [String: Any] = [:]
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName != originalWorker.name {
            updateData["name"] = trimmedName
        }
        if trimmedEmail != originalWorker.email.lowercased() {
            updateData["email"] = trimmedEmail
        }
        if hourlyRateValue != originalWorker.hourly_rate {
            updateData["hourly_rate"] = hourlyRateValue
        }
        if employmentType != originalWorker.employment_type {
            updateData["employment_type"] = employmentType.rawValue
        }
        if role != originalWorker.role {
            updateData["role"] = role.rawValue
        }
        if status != originalWorker.status {
            updateData["status"] = status.rawValue
        }
        if (trimmedPhone.isEmpty ? nil : trimmedPhone) != originalWorker.phone {
            updateData["phone"] = trimmedPhone.isEmpty ? nil : trimmedPhone
        }
        if (trimmedAddress.isEmpty ? nil : trimmedAddress) != originalWorker.address {
            updateData["address"] = trimmedAddress.isEmpty ? nil : trimmedAddress
        }
        if !trimmedNotes.isEmpty {
            updateData["notes"] = trimmedNotes
        }
        
        let updateRequest = UpdateWorkerRequest(
            name: updateData["name"] as? String,
            email: updateData["email"] as? String,
            phone: updateData["phone"] as? String,
            address: updateData["address"] as? String,
            hourly_rate: updateData["hourly_rate"] as? Double,
            employment_type: updateData["employment_type"] as? String,
            role: updateData["role"] as? String,
            status: updateData["status"] as? String,
            notes: updateData["notes"] as? String
        )
        
        apiService.updateWorker(id: originalWorker.id, data: updateRequest)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isUpdating = false
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error)
                    }
                },
                receiveValue: { [weak self] worker in
                    #if DEBUG
                    print("[EditWorkerViewModel] ✅ Worker updated successfully: \(worker.name)")
                    #endif
                    
                    self?.workerUpdated = true
                    self?.showSuccess("Worker updated successfully!")
                    onSuccess(worker)
                }
            )
            .store(in: &cancellables)
    }
    
    func resetForm() {
        name = originalWorker.name
        email = originalWorker.email
        hourlyRate = String(Int(originalWorker.hourly_rate))
        employmentType = originalWorker.employment_type
        role = originalWorker.role
        status = originalWorker.status
        phone = originalWorker.phone ?? ""
        address = originalWorker.address ?? ""
        notes = ""
    }
    
    // MARK: - Validation
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    // MARK: - Error Handling
    
    private func handleAPIError(_ error: ChefWorkersAPIService.APIError) {
        #if DEBUG
        print("[EditWorkerViewModel] ❌ API Error: \(error)")
        #endif
        
        let message: String
        switch error {
        case .networkError:
            message = "Network error. Please check your connection and try again."
        case .serverError(let code, let serverMessage):
            if code == 409 {
                message = "A worker with this email already exists."
            } else if code == 400 {
                message = "Invalid data provided. Please check your inputs."
            } else {
                message = "Server error (\(code)): \(serverMessage)"
            }
        case .decodingError:
            message = "Error processing server response. Please try again."
        default:
            message = "An unexpected error occurred. Please try again."
        }
        
        showError(message)
    }
    
    private func showError(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccess(_ message: String) {
        alertTitle = "Success"
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - Form Helpers
    
    func formatPhoneNumber() {
        // Auto-format Danish phone numbers
        let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        if cleaned.hasPrefix("45") && !cleaned.hasPrefix("+45") {
            phone = "+\(cleaned)"
        } else if cleaned.count == 8 && !cleaned.hasPrefix("+") {
            phone = "+45 \(cleaned)"
        }
    }
    
    func validateHourlyRate() {
        // Ensure hourly rate is a valid number
        if let rate = Double(hourlyRate) {
            if rate < 0 {
                hourlyRate = "0"
            } else if rate > 2000 {
                hourlyRate = "2000"
            }
        }
    }
    
    // MARK: - Certificate Management
    
    func loadCertificateTypes() {
        certificateService.fetchCertificateTypes()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("[EditWorkerViewModel] ❌ Failed to load certificate types: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.availableCertificateTypes = response.certificateTypes
                    self?.prepareCertificateSelection()
                }
            )
            .store(in: &cancellables)
    }
    
    func loadWorkerCertificates() {
        isLoadingCertificates = true
        
        certificateService.fetchWorkerCertificates(workerId: originalWorker.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingCertificates = false
                    if case .failure(let error) = completion {
                        print("[EditWorkerViewModel] ❌ Failed to load worker certificates: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.certificates = response.certificates
                    self?.prepareCertificateSelection()
                }
            )
            .store(in: &cancellables)
    }
    
    func prepareCertificateSelection() {
        selectedCertificateStates = availableCertificateTypes.map { certType in
            var state = CertificateSelectionState(certificateType: certType)
            
            // Check if worker already has this certificate
            if let existingCert = certificates.first(where: { $0.certificateTypeId == certType.id }) {
                state.isSelected = true
                state.isCertified = existingCert.isCertified
                state.certificationExpires = existingCert.certificationExpires
                state.yearsExperience = existingCert.yearsExperience
                state.skillLevel = .expert // Use expert instead of certified for existing certificates
                state.certificationNumber = existingCert.certificationNumber ?? ""
                state.notes = existingCert.notes ?? ""
            }
            
            return state
        }
    }
    
    func addCertificate(_ certificateState: CertificateSelectionState) {
        guard certificateState.isSelected else { return }
        
        print("[EditWorkerViewModel] 📊 Creating certificate with years experience: \(certificateState.yearsExperience)")
        
        let request = CreateWorkerCertificateRequest(
            employeeId: originalWorker.id,
            certificateTypeId: certificateState.certificateType.id,
            skillName: certificateState.certificateType.nameEn,
            skillLevel: certificateState.skillLevel.rawValue,
            isCertified: certificateState.isCertified,
            certificationNumber: certificateState.certificationNumber.isEmpty ? nil : certificateState.certificationNumber,
            certificationExpires: certificateState.certificationExpires,
            yearsExperience: certificateState.yearsExperience,
            craneTypeSpecialization: nil,
            notes: certificateState.notes.isEmpty ? nil : certificateState.notes
        )
        
        print("[EditWorkerViewModel] 📊 Request years experience: \(request.yearsExperience)")
        
        certificateService.addCertificateToWorker(workerId: originalWorker.id, request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        print("[EditWorkerViewModel] ✅ Certificate added successfully")
                        self?.loadWorkerCertificates()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func updateCertificate(_ certificate: WorkerCertificate, with state: CertificateSelectionState) {
        let request = UpdateWorkerCertificateRequest(
            skillLevel: state.skillLevel.rawValue,
            isCertified: state.isCertified,
            certificationNumber: state.certificationNumber.isEmpty ? nil : state.certificationNumber,
            certificationExpires: state.certificationExpires,
            yearsExperience: state.yearsExperience,
            craneTypeSpecialization: nil,
            notes: state.notes.isEmpty ? nil : state.notes
        )
        
        certificateService.updateWorkerCertificate(
            workerId: originalWorker.id,
            certificateId: certificate.id,
            request: request
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleAPIError(error)
                }
            },
            receiveValue: { [weak self] response in
                if response.success {
                    print("[EditWorkerViewModel] ✅ Certificate updated successfully")
                    self?.loadWorkerCertificates()
                }
            }
        )
        .store(in: &cancellables)
    }
    
    func removeCertificate(_ certificate: WorkerCertificate) {
        certificateService.removeCertificateFromWorker(
            workerId: originalWorker.id,
            certificateId: certificate.id
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleAPIError(error)
                }
            },
            receiveValue: { [weak self] response in
                if response.success {
                    print("[EditWorkerViewModel] ✅ Certificate removed successfully")
                    self?.loadWorkerCertificates()
                }
            }
        )
        .store(in: &cancellables)
    }
}

// MARK: - Mock Data for Development

#if DEBUG
extension EditWorkerViewModel {
    func updateMockWorker(onSuccess: @escaping (WorkerForChef) -> Void) {
        // Simulate API call with mock data
        isUpdating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Create updated worker with changed fields
            let updatedWorker = WorkerForChef(
                id: self.originalWorker.id,
                name: self.name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: self.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                phone: self.phone.isEmpty ? nil : self.phone.trimmingCharacters(in: .whitespacesAndNewlines),
                address: self.address.isEmpty ? nil : self.address.trimmingCharacters(in: .whitespacesAndNewlines),
                hourly_rate: self.hourlyRateValue,
                employment_type: self.employmentType,
                role: self.role,
                status: self.status,
                profile_picture_url: self.originalWorker.profile_picture_url,
                created_at: self.originalWorker.created_at,
                last_active: Date(),
                stats: self.originalWorker.stats
            )
            
            self.isUpdating = false
            self.workerUpdated = true
            self.showSuccess("Mock worker updated successfully!")
            onSuccess(updatedWorker)
        }
    }
}
#endif