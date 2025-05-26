// ManagerProfileViewModel.swift
import SwiftUI
import Combine
import Foundation

class ManagerProfileViewModel: ObservableObject {
    @Published var profileData = ExternalManagerProfileData()
    @Published var managementStats = ExternalManagerStats()
    @Published var isLoading = false
    @Published var isUploadingImage = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = ManagerAPIService.shared
    private let profileApiService = SupervisorProfileAPIService.shared
    
    // DODANE: Computed property dla klienta supervisora
    var assignedCustomer: ManagerAPIService.Project.Customer? {
        // Supervisor ma zadania tylko od jednego klienta
        return profileData.assignedProjects.first?.customer
    }
    
    func loadData() {
        isLoading = true
        
        guard let managerIdString = AuthService.shared.getEmployeeId() else {
            showError("Unable to get manager ID")
            isLoading = false
            return
        }
        
        guard let managerId = Int(managerIdString) else {
            showError("Invalid manager ID format")
            isLoading = false
            return
        }
        
        Publishers.CombineLatest3(
            loadBasicProfileData(),
            loadDashboardStats(managerId: managerIdString),
            loadAssignedProjectsAndWorkers(managerId: managerId)
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.showError("Failed to load profile data: \(error.localizedDescription)")
                }
            },
            receiveValue: { [weak self] (basicData, dashboardStats, projectsAndWorkers) in
                self?.profileData = basicData
                self?.managementStats = dashboardStats
                self?.profileData.assignedProjects = projectsAndWorkers.projects
                self?.profileData.managedWorkers = projectsAndWorkers.workers
                
                // Load profile picture separately (non-blocking)
                self?.loadCurrentProfilePicture()
            }
        )
        .store(in: &cancellables)
    }
    
    private func loadDashboardStats(managerId: String) -> AnyPublisher<ExternalManagerStats, Error> {
        return apiService.fetchManagerDashboardStats(managerId: managerId)
            .map { response in
                ExternalManagerStats(
                    assignedProjects: response.assignedProjects,
                    activeProjects: response.activeProjects,
                    totalWorkers: response.totalWorkers,
                    pendingApprovals: response.pendingApprovals,
                    projectsCompleted: response.projectsCompleted,
                    totalTasks: response.totalTasks,
                    averageProjectDuration: response.averageProjectDuration,
                    approvalResponseTime: response.approvalResponseTime,
                    projectSuccessRate: response.projectSuccessRate,
                    workerSatisfactionScore: response.workerSatisfactionScore,
                    hoursThisWeek: response.hoursThisWeek,
                    tasksCompleted: response.tasksCompleted,
                    efficiencyRate: response.efficiencyRate,
                    workPlansCreated: response.workPlansCreated
                )
            }
            .catch { error -> AnyPublisher<ExternalManagerStats, Error> in
                #if DEBUG
                print("[ManagerProfileViewModel] Dashboard stats API failed, using fallback: \(error)")
                #endif
                return Publishers.CombineLatest3(
                    self.apiService.fetchProjects()
                        .replaceError(with: []),
                    self.apiService.fetchAssignedWorkers(supervisorId: Int(managerId) ?? 0)
                        .replaceError(with: []),
                    self.apiService.fetchAllPendingWorkEntriesForManager(isDraft: false)
                        .map { entries in entries.filter { $0.confirmation_status == "pending" }.count }
                        .replaceError(with: 0)
                )
                .map { projects, workers, pendingCount in
                    ExternalManagerStats(
                        assignedProjects: projects.count,
                        activeProjects: projects.filter { $0.status == .aktiv }.count,
                        totalWorkers: workers.count,
                        pendingApprovals: pendingCount,
                        projectsCompleted: projects.filter { $0.status == .afsluttet }.count,
                        totalTasks: projects.reduce(0) { $0 + $1.tasks.count },
                        averageProjectDuration: self.calculateAverageProjectDuration(projects)
                    )
                }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func loadAssignedProjectsAndWorkers(managerId: Int) -> AnyPublisher<(projects: [ManagerAPIService.Project], workers: [ManagerAPIService.Worker]), Error> {
        return Publishers.CombineLatest(
            apiService.fetchProjects(),
            apiService.fetchAssignedWorkers(supervisorId: managerId)
        )
        .map { projects, workers in
            (projects: projects, workers: workers)
        }
        .mapError { $0 as Error }
        .eraseToAnyPublisher()
    }
    
    private func loadBasicProfileData() -> AnyPublisher<ExternalManagerProfileData, Error> {
        guard let managerIdString = AuthService.shared.getEmployeeId() else {
            return Fail(error: APIError.invalidURL as Error)
                .eraseToAnyPublisher()
        }
        
        return apiService.fetchExternalManagerProfile(managerId: managerIdString)
            .map { response in
                ExternalManagerProfileData(
                    employeeId: response.employeeId,
                    name: response.name,
                    email: response.email,
                    role: response.role,
                    assignedSince: response.assignedSince.toDate() ?? Date(),
                    contractType: response.contractType,
                    specializations: response.specializations,
                    certifications: response.certifications.map { cert in
                        ExternalCertification(
                            name: cert.name,
                            issuingOrganization: cert.issuingOrganization,
                            issueDate: cert.issueDate.toDate() ?? Date(),
                            expiryDate: cert.expiryDate?.toDate(),
                            certificateNumber: cert.certificateNumber
                        )
                    },
                    address: response.address,
                    phoneNumber: response.phoneNumber,
                    emergencyContact: response.emergencyContact,
                    profilePictureUrl: response.profilePictureUrl,
                    isActivated: response.isActivated,
                    createdAt: response.createdAt?.toDate(),
                    companyName: response.companyName,
                    contractEndDate: response.contractEndDate?.toDate(),
                    hourlyRate: response.hourlyRate?.toDecimal(),
                    maxProjectsAllowed: response.maxProjectsAllowed,
                    preferredProjectTypes: response.preferredProjectTypes
                )
            }
            .catch { error -> AnyPublisher<ExternalManagerProfileData, Error> in
                #if DEBUG
                print("[ManagerProfileViewModel] API call failed, using fallback data: \(error)")
                #endif
                let fallbackData = ExternalManagerProfileData(
                    employeeId: managerIdString,
                    name: AuthService.shared.getEmployeeName() ?? "",
                    email: "supervisor@ksrcranes.dk",
                    role: "Supervisor",
                    assignedSince: Date(),
                    contractType: "Internal"
                )
                return Just(fallbackData)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func calculateAverageProjectDuration(_ projects: [ManagerAPIService.Project]) -> Double {
        let completedProjects = projects.compactMap { project -> Double? in
            guard let start = project.start_date,
                  let end = project.end_date else { return nil }
            return end.timeIntervalSince(start) / (24 * 60 * 60)
        }
        
        return completedProjects.isEmpty ? 0 : completedProjects.reduce(0, +) / Double(completedProjects.count)
    }
    
    func updateProfile(_ updatedData: ExternalManagerProfileData) {
        isLoading = true
        
        guard let managerIdString = AuthService.shared.getEmployeeId() else {
            showError("Unable to get manager ID")
            isLoading = false
            return
        }
        
        let contactData = ManagerContactUpdateRequest(
            email: updatedData.email,
            phoneNumber: updatedData.phoneNumber,
            address: updatedData.address,
            emergencyContact: updatedData.emergencyContact
        )
        
        apiService.updateExternalManagerContact(managerId: managerIdString, contactData: contactData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.showError("Failed to update profile: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        self?.profileData = updatedData
                        self?.showSuccess("Profile updated successfully")
                    } else {
                        self?.showError(response.message)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadProjectDetails(projectId: Int) -> AnyPublisher<ManagerAPIService.Project?, Error> {
        guard let managerIdString = AuthService.shared.getEmployeeId(),
              let managerId = Int(managerIdString) else {
            return Fail(error: APIError.invalidURL as Error)
                .eraseToAnyPublisher()
        }
        
        return apiService.fetchProjects()
            .map { projects in
                projects.first { $0.project_id == projectId }
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func submitWorkerFeedback(workerId: Int, rating: Double, comments: String, categories: [String]) {
        guard let managerIdString = AuthService.shared.getEmployeeId() else {
            showError("Unable to get manager ID")
            return
        }
        
        let feedback = WorkerFeedbackRequest(
            workerId: workerId,
            rating: rating,
            comments: comments,
            categories: categories
        )
        
        apiService.submitWorkerFeedback(managerId: managerIdString, feedback: feedback)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.showError("Failed to submit feedback: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        self?.showSuccess("Feedback submitted successfully")
                    } else {
                        self?.showError(response.message)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Profile Picture Methods
    
    func uploadProfilePicture(_ image: UIImage) {
        guard let managerIdString = AuthService.shared.getEmployeeId() else {
            showError("Unable to get manager ID")
            return
        }
        
        isUploadingImage = true
        
        profileApiService.uploadProfilePicture(supervisorId: managerIdString, image: image)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isUploadingImage = false
                    if case .failure(let error) = completion {
                        self?.showError("Failed to upload profile picture: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success, let data = response.data {
                        self?.profileData.profilePictureUrl = data.profilePictureUrl
                        self?.showSuccess("Profile picture updated successfully")
                    } else {
                        self?.showError(response.message)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadCurrentProfilePicture() {
        guard let managerIdString = AuthService.shared.getEmployeeId() else {
            return
        }
        
        profileApiService.getProfilePicture(supervisorId: managerIdString)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        #if DEBUG
                        print("[ManagerProfileViewModel] Failed to load profile picture: \(error)")
                        #endif
                        // Don't show error to user for this, it's not critical
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        self?.profileData.profilePictureUrl = response.data.profilePictureUrl
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteProfilePicture() {
        guard let managerIdString = AuthService.shared.getEmployeeId() else {
            showError("Unable to get manager ID")
            return
        }
        
        isUploadingImage = true
        
        profileApiService.deleteProfilePicture(supervisorId: managerIdString)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isUploadingImage = false
                    if case .failure(let error) = completion {
                        self?.showError("Failed to delete profile picture: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        self?.profileData.profilePictureUrl = nil
                        self?.showSuccess("Profile picture removed successfully")
                    } else {
                        self?.showError(response.message)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func showError(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccess(_ message: String) {
        alertTitle = "Success"
        alertMessage = message
        showAlert = true
    }
}

// Reszta struktur danych pozostaje bez zmian
struct ExternalManagerProfileData: Codable {
    var employeeId: String = ""
    var name: String = ""
    var email: String = ""
    var role: String = ""
    var assignedSince: Date = Date()
    var contractType: String = ""
    var assignedProjects: [ManagerAPIService.Project] = []
    var managedWorkers: [ManagerAPIService.Worker] = []
    var specializations: [String] = []
    var certifications: [ExternalCertification] = []
    
    var address: String?
    var phoneNumber: String?
    var emergencyContact: String?
    var profilePictureUrl: String?
    var isActivated: Bool = true
    var createdAt: Date?
    
    var companyName: String? = "KSR Cranes (External)"
    var contractEndDate: Date?
    var hourlyRate: Decimal?
    var maxProjectsAllowed: Int = 10
    var preferredProjectTypes: [String] = []
    
    var hasDrivingLicense: Bool = false
    var drivingLicenseExpiration: Date?
    var drivingLicenseCategory: String?
    var cprNumber: String?
    var birthDate: Date?
    var languages: [EmployeeLanguage] = []
    var craneTypes: [CraneTypeCertification] = []
    var operatorNormalRate: Decimal?
    var operatorOvertimeRate1: Decimal?
    var operatorWeekendRate: Decimal?
}

struct ExternalManagerStats: Codable {
    var assignedProjects: Int = 0
    var activeProjects: Int = 0
    var totalWorkers: Int = 0
    var pendingApprovals: Int = 0
    var projectsCompleted: Int = 0
    var totalTasks: Int = 0
    var averageProjectDuration: Double = 0
    
    var approvalResponseTime: Double = 24.0
    var projectSuccessRate: Double = 95.0
    var workerSatisfactionScore: Double = 4.5
    
    var teamMembers: Int = 0
    var hoursThisWeek: Int = 0
    var tasksCompleted: Int = 0
    var efficiencyRate: Int = 85
    var workPlansCreated: Int = 0
}

struct ExternalCertification: Codable, Identifiable {
    var id = UUID()
    let name: String
    let issuingOrganization: String
    let issueDate: Date
    let expiryDate: Date?
    let certificateNumber: String?
    
    var isValid: Bool {
        guard let expiry = expiryDate else { return true }
        return expiry > Date()
    }
    
    var statusColor: Color {
        guard let expiry = expiryDate else { return .ksrSuccess }
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
        
        if daysUntilExpiry < 0 { return .ksrError }
        if daysUntilExpiry < 30 { return .ksrWarning }
        return .ksrSuccess
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, issuingOrganization, issueDate, expiryDate, certificateNumber
    }
    
    init(name: String, issuingOrganization: String, issueDate: Date, expiryDate: Date?, certificateNumber: String?) {
        self.id = UUID()
        self.name = name
        self.issuingOrganization = issuingOrganization
        self.issueDate = issueDate
        self.expiryDate = expiryDate
        self.certificateNumber = certificateNumber
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.issuingOrganization = try container.decode(String.self, forKey: .issuingOrganization)
        self.issueDate = try container.decode(Date.self, forKey: .issueDate)
        self.expiryDate = try container.decodeIfPresent(Date.self, forKey: .expiryDate)
        self.certificateNumber = try container.decodeIfPresent(String.self, forKey: .certificateNumber)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(issuingOrganization, forKey: .issuingOrganization)
        try container.encode(issueDate, forKey: .issueDate)
        try container.encodeIfPresent(expiryDate, forKey: .expiryDate)
        try container.encodeIfPresent(certificateNumber, forKey: .certificateNumber)
    }
}

struct EmployeeLanguage: Codable {
    let language: String
    let proficiency: String
}

struct CraneTypeCertification: Codable {
    let craneTypeId: Int
    let name: String
    let certificationDate: Date?
}

extension ExternalManagerProfileData {
    init(
        employeeId: String,
        name: String,
        email: String,
        role: String,
        assignedSince: Date,
        contractType: String,
        specializations: [String] = [],
        certifications: [ExternalCertification] = [],
        address: String? = nil,
        phoneNumber: String? = nil,
        emergencyContact: String? = nil,
        profilePictureUrl: String? = nil,
        isActivated: Bool = true,
        createdAt: Date? = nil,
        companyName: String? = "KSR Cranes (External)",
        contractEndDate: Date? = nil,
        hourlyRate: Decimal? = nil,
        maxProjectsAllowed: Int = 10,
        preferredProjectTypes: [String] = []
    ) {
        self.employeeId = employeeId
        self.name = name
        self.email = email
        self.role = role
        self.assignedSince = assignedSince
        self.contractType = contractType
        self.specializations = specializations
        self.certifications = certifications
        self.address = address
        self.phoneNumber = phoneNumber
        self.emergencyContact = emergencyContact
        self.profilePictureUrl = profilePictureUrl
        self.isActivated = isActivated
        self.createdAt = createdAt
        self.companyName = companyName
        self.contractEndDate = contractEndDate
        self.hourlyRate = hourlyRate
        self.maxProjectsAllowed = maxProjectsAllowed
        self.preferredProjectTypes = preferredProjectTypes
        
        self.assignedProjects = []
        self.managedWorkers = []
        self.hasDrivingLicense = false
        self.drivingLicenseExpiration = nil
        self.drivingLicenseCategory = nil
        self.cprNumber = nil
        self.birthDate = nil
        self.languages = []
        self.craneTypes = []
        self.operatorNormalRate = nil
        self.operatorOvertimeRate1 = nil
        self.operatorWeekendRate = nil
    }
}

extension ExternalManagerStats {
    init(
        assignedProjects: Int,
        activeProjects: Int,
        totalWorkers: Int,
        pendingApprovals: Int,
        projectsCompleted: Int,
        totalTasks: Int,
        averageProjectDuration: Double,
        approvalResponseTime: Double = 24.0,
        projectSuccessRate: Double = 95.0,
        workerSatisfactionScore: Double = 4.5,
        hoursThisWeek: Int = 0,
        tasksCompleted: Int = 0,
        efficiencyRate: Int = 85,
        workPlansCreated: Int = 0
    ) {
        self.assignedProjects = assignedProjects
        self.activeProjects = activeProjects
        self.totalWorkers = totalWorkers
        self.pendingApprovals = pendingApprovals
        self.projectsCompleted = projectsCompleted
        self.totalTasks = totalTasks
        self.averageProjectDuration = averageProjectDuration
        self.approvalResponseTime = approvalResponseTime
        self.projectSuccessRate = projectSuccessRate
        self.workerSatisfactionScore = workerSatisfactionScore
        
        self.teamMembers = totalWorkers
        self.hoursThisWeek = hoursThisWeek
        self.tasksCompleted = tasksCompleted
        self.efficiencyRate = efficiencyRate
        self.workPlansCreated = workPlansCreated
    }
}
