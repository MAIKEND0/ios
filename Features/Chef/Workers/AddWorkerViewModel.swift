//
//  AddWorkerViewModel.swift
//  KSR Cranes App
//  ViewModel for adding new workers
//

import Foundation
import Combine

class AddWorkerViewModel: ObservableObject {
    // Basic Information
    @Published var name = ""
    @Published var email = ""
    
    // Employment Details
    @Published var hourlyRate = ""
    @Published var employmentType: EmploymentType = .fuld_tid
    @Published var role: WorkerRole = .arbejder
    @Published var status: WorkerStatus = .aktiv
    @Published var hireDate = Date()
    
    // Contact Information
    @Published var phone = ""
    @Published var address = ""
    
    // Additional Information
    @Published var notes = ""
    
    // Certificate Information
    @Published var selectedCertificates: [CertificateSelectionState] = []
    @Published var showingCertificateSelection = false
    
    // UI State
    @Published var isCreating = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var workerCreated = false
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = ChefWorkersAPIService.shared
    private let certificateAPIService = CertificateAPIService.shared
    
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
    
    // Certificate-related computed properties
    var selectedCertificatesCount: Int {
        return selectedCertificates.count
    }
    
    var certifiedCertificatesCount: Int {
        return selectedCertificates.filter { $0.isCertified }.count
    }
    
    var certificatesSummary: String {
        let total = selectedCertificatesCount
        let certified = certifiedCertificatesCount
        
        if total == 0 {
            return "No certificates selected"
        } else if certified == 0 {
            return "\(total) certificate\(total == 1 ? "" : "s") selected (none certified)"
        } else {
            return "\(total) certificate\(total == 1 ? "" : "s") selected (\(certified) certified)"
        }
    }
    
    // MARK: - Methods
    
    func createWorker(onSuccess: @escaping (WorkerForChef) -> Void) {
        guard isFormValid else {
            showError("Please fill in all required fields correctly.")
            return
        }
        
        guard !isCreating else { return }
        
        #if DEBUG
        print("[AddWorkerViewModel] Creating worker: \(name)")
        #endif
        
        isCreating = true
        
        let workerRequest = CreateWorkerRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.isEmpty ? nil : address.trimmingCharacters(in: .whitespacesAndNewlines),
            hourly_rate: hourlyRateValue,
            employment_type: employmentType.rawValue,
            role: role.rawValue,
            status: status.rawValue,
            hire_date: hireDate,
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        apiService.createWorker(workerRequest)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.isCreating = false
                        self?.handleAPIError(error)
                    }
                },
                receiveValue: { [weak self] worker in
                    guard let self = self else { return }
                    
                    #if DEBUG
                    print("[AddWorkerViewModel] ✅ Worker created successfully: \(worker.name)")
                    #endif
                    
                    // If certificates are selected, add them to the worker
                    if !self.selectedCertificates.isEmpty {
                        self.addCertificatesToWorker(workerId: worker.id) { success in
                            self.isCreating = false
                            if success {
                                self.workerCreated = true
                                self.showSuccess("Worker and certificates created successfully!")
                                onSuccess(worker)
                            } else {
                                self.showError("Worker created but some certificates failed to add. You can add them later from the worker details.")
                                onSuccess(worker)
                            }
                        }
                    } else {
                        // No certificates to add
                        self.isCreating = false
                        self.workerCreated = true
                        self.showSuccess("Worker created successfully!")
                        onSuccess(worker)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func clearForm() {
        name = ""
        email = ""
        hourlyRate = ""
        employmentType = .fuld_tid
        status = .aktiv
        hireDate = Date()
        phone = ""
        address = ""
        notes = ""
        selectedCertificates = []
        workerCreated = false
    }
    
    // MARK: - Certificate Methods
    
    private func addCertificatesToWorker(workerId: Int, completion: @escaping (Bool) -> Void) {
        guard !selectedCertificates.isEmpty else {
            completion(true)
            return
        }
        
        #if DEBUG
        print("[AddWorkerViewModel] Adding \(selectedCertificates.count) certificates to worker \(workerId)")
        #endif
        
        let certificateRequests = selectedCertificates.map { state in
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
        
        certificateAPIService.addMultipleCertificatesToWorker(workerId: workerId, certificates: certificateRequests)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .finished:
                        #if DEBUG
                        print("[AddWorkerViewModel] ✅ All certificates added successfully")
                        #endif
                        completion(true)
                    case .failure(let error):
                        #if DEBUG
                        print("[AddWorkerViewModel] ❌ Failed to add certificates: \(error)")
                        #endif
                        completion(false)
                    }
                },
                receiveValue: { responses in
                    let successCount = responses.filter { $0.success }.count
                    #if DEBUG
                    print("[AddWorkerViewModel] 📊 Certificate results: \(successCount)/\(responses.count) successful")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func addCertificate(_ certificate: CertificateSelectionState) {
        if let index = selectedCertificates.firstIndex(where: { $0.certificateType.id == certificate.certificateType.id }) {
            selectedCertificates[index] = certificate
        } else {
            selectedCertificates.append(certificate)
        }
        
        #if DEBUG
        print("[AddWorkerViewModel] Certificate updated: \(certificate.certificateType.displayName)")
        #endif
    }
    
    func removeCertificate(withId certificateId: Int) {
        selectedCertificates.removeAll { $0.certificateType.id == certificateId }
        
        #if DEBUG
        print("[AddWorkerViewModel] Certificate removed: ID \(certificateId)")
        #endif
    }
    
    func clearCertificates() {
        selectedCertificates.removeAll()
        
        #if DEBUG
        print("[AddWorkerViewModel] All certificates cleared")
        #endif
    }
    
    func prefillForm(from template: WorkerForChef) {
        // Don't copy name and email (these should be unique)
        hourlyRate = String(Int(template.hourly_rate))
        employmentType = template.employment_type
        status = .aktiv // Always start new workers as active
        hireDate = Date()
        // Don't copy contact info
    }
    
    // MARK: - Validation
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        // Basic validation for Danish phone numbers
        let cleanPhone = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "+", with: "")
        
        return cleanPhone.count >= 8 && cleanPhone.allSatisfy { $0.isNumber }
    }
    
    // MARK: - Error Handling
    
    private func handleAPIError(_ error: ChefWorkersAPIService.APIError) {
        #if DEBUG
        print("[AddWorkerViewModel] ❌ API Error: \(error)")
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
    
    func suggestEmail() {
        // Auto-suggest email based on name
        guard !name.isEmpty && email.isEmpty else { return }
        
        let nameParts = name.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if nameParts.count >= 2 {
            let firstName = nameParts[0]
            let lastName = nameParts[1]
            email = "\(firstName).\(lastName)@ksrcranes.dk"
        } else if nameParts.count == 1 {
            email = "\(nameParts[0])@ksrcranes.dk"
        }
    }
}

// MARK: - Mock Data for Development

#if DEBUG
extension AddWorkerViewModel {
    func loadTestData() {
        name = "Test Worker"
        email = "test.worker@ksrcranes.dk"
        hourlyRate = "350"
        employmentType = .fuld_tid
        status = .aktiv
        phone = "+45 12 34 56 78"
        address = "Test Address 123, 2100 København"
        notes = "Test worker for development"
    }
    
    func createMockWorker(onSuccess: @escaping (WorkerForChef) -> Void) {
        // Simulate API call with mock data
        isCreating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let mockWorker = WorkerForChef(
                id: Int.random(in: 1000...9999),
                name: self.name,
                email: self.email,
                phone: self.phone.isEmpty ? nil : self.phone,
                address: self.address.isEmpty ? nil : self.address,
                hourly_rate: self.hourlyRateValue,
                employment_type: self.employmentType,
                role: self.role,
                status: self.status,
                profile_picture_url: nil,
                created_at: Date(),
                last_active: Date(),
                stats: WorkerQuickStats(
                    hours_this_week: 0,
                    hours_this_month: 0,
                    active_tasks: 0,
                    completed_tasks: 0,
                    total_tasks: 0,
                    approval_rate: 1.0,
                    last_timesheet_date: nil
                )
            )
            
            self.isCreating = false
            self.workerCreated = true
            self.showSuccess("Mock worker created successfully!")
            onSuccess(mockWorker)
        }
    }
}
#endif