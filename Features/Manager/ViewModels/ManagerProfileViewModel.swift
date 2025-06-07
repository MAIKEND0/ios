// Features/Manager/Profile/ManagerProfileViewModel.swift
import SwiftUI
import Combine
import Foundation

class ManagerProfileViewModel: ObservableObject {
    @Published var profileData = ManagerProfileData()
    @Published var managementStats = ManagerStats()
    @Published var profileImage: UIImage? = nil
    @Published var isLoading = false
    @Published var isUploadingImage = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = ManagerAPIService.shared
    private let supervisorApiService = SupervisorProfileAPIService.shared
    private let imageCache = ProfileImageCache.shared
    
    var assignedCustomer: ManagerAPIService.Project.Customer? {
        return profileData.assignedProjects.first?.customer
    }
    
    // MARK: - Main Load Data Method
    
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
        
        #if DEBUG
        print("🔍 [ManagerProfileViewModel] Starting loadData() for manager ID: \(managerIdString)")
        #endif
        
        // 🔥 POPRAWKA: Dodaj loadCurrentProfilePicture do kombinacji
        Publishers.CombineLatest4(
            loadBasicProfileData(),
            loadDashboardStats(managerId: managerIdString),
            loadAssignedProjectsAndWorkers(managerId: managerId),
            loadCurrentProfilePicturePublisher() // 🆕 Dodane!
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("❌ [ManagerProfileViewModel] Load failed: \(error)")
                    self?.showError("Failed to load profile data: \(error.localizedDescription)")
                }
            },
            receiveValue: { [weak self] (basicData, dashboardStats, projectsAndWorkers, profilePictureUrl) in
                guard let self = self else { return }
                
                print("✅ [ManagerProfileViewModel] All data loaded successfully")
                
                self.profileData = basicData
                self.managementStats = dashboardStats
                self.profileData.assignedProjects = projectsAndWorkers.projects
                self.profileData.managedWorkers = projectsAndWorkers.workers
                
                // 🔍 DEBUG: Log workers and their profile URLs
                print("🔍 [ManagerProfileViewModel] Loaded \(projectsAndWorkers.workers.count) workers:")
                for worker in projectsAndWorkers.workers {
                    print("   - Worker: \(worker.name) (ID: \(worker.employee_id))")
                    print("     Profile URL: \(worker.profilePictureUrl ?? "NIL")")
                }
                
                // 🆕 Set profile picture URL from supervisor API
                if let pictureUrl = profilePictureUrl, !pictureUrl.isEmpty {
                    self.profileData.profilePictureUrl = pictureUrl
                    print("✅ [ManagerProfileViewModel] Profile picture URL set: \(pictureUrl)")
                } else {
                    print("⚠️ [ManagerProfileViewModel] No profile picture URL")
                }
                
                // Load profile picture using cache
                self.loadProfileImageWithCache()
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Profile Picture Loading
    
    // 🆕 Publisher version of loadCurrentProfilePicture
    private func loadCurrentProfilePicturePublisher() -> AnyPublisher<String?, Error> {
        guard let managerIdString = AuthService.shared.getEmployeeId() else {
            return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        print("🔍 [ManagerProfileViewModel] Loading current profile picture for manager: \(managerIdString)")
        
        return supervisorApiService.getProfilePicture(supervisorId: managerIdString)
            .map { response -> String? in
                print("✅ [ManagerProfileViewModel] Profile picture response:")
                print("   - Success: \(response.success)")
                print("   - Profile Picture URL: \(response.data.profilePictureUrl ?? "NIL")")
                
                return response.success ? response.data.profilePictureUrl : nil
            }
            .catch { error -> AnyPublisher<String?, Error> in
                print("⚠️ [ManagerProfileViewModel] Profile picture load failed: \(error)")
                return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func loadProfileImageWithCache(forceRefresh: Bool = false) {
        guard let managerIdString = AuthService.shared.getEmployeeId() else {
            print("❌ [ManagerProfileViewModel] No manager ID for cache loading")
            return
        }
        
        let currentUrl = profileData.profilePictureUrl
        
        print("🔍 [ManagerProfileViewModel] Loading profile image with cache:")
        print("   - Manager ID: \(managerIdString)")
        print("   - Current URL: \(currentUrl ?? "NIL")")
        print("   - Force Refresh: \(forceRefresh)")
        
        imageCache.getManagerProfileImage(
            employeeId: managerIdString,
            currentImageUrl: currentUrl,
            forceRefresh: forceRefresh
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] image in
            if let image = image {
                print("✅ [ManagerProfileViewModel] Profile image loaded from cache successfully")
                self?.profileImage = image
            } else {
                print("⚠️ [ManagerProfileViewModel] Profile image cache returned nil")
            }
        }
        .store(in: &cancellables)
    }
    
    func refreshProfileImage() {
        print("[ManagerProfileViewModel] 🔄 Refreshing profile image...")
        loadProfileImageWithCache(forceRefresh: true)
    }
    
    // MARK: - Data Loading Methods
    
    private func loadDashboardStats(managerId: String) -> AnyPublisher<ManagerStats, Error> {
        return apiService.fetchManagerDashboardStats(managerId: managerId)
            .map { response in
                ManagerStats(
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
            .catch { error -> AnyPublisher<ManagerStats, Error> in
                print("[ManagerProfileViewModel] Dashboard stats API failed, using fallback: \(error)")
                return Publishers.CombineLatest3(
                    self.apiService.fetchProjects().replaceError(with: []),
                    self.apiService.fetchAssignedWorkers(supervisorId: Int(managerId) ?? 0).replaceError(with: []),
                    self.apiService.fetchAllPendingWorkEntriesForManager(isDraft: false)
                        .map { entries in entries.filter { $0.confirmation_status == "pending" }.count }
                        .replaceError(with: 0)
                )
                .map { projects, workers, pendingCount in
                    ManagerStats(
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
    
    private func loadBasicProfileData() -> AnyPublisher<ManagerProfileData, Error> {
        guard let managerIdString = AuthService.shared.getEmployeeId() else {
            return Fail(error: APIError.invalidURL as Error).eraseToAnyPublisher()
        }
        
        return apiService.fetchExternalManagerProfile(managerId: managerIdString)
            .map { response in
                ManagerProfileData(
                    employeeId: response.employeeId,
                    name: response.name,
                    email: response.email,
                    role: response.role,
                    assignedSince: response.assignedSince.toDate() ?? Date(),
                    contractType: response.contractType,
                    specializations: response.specializations,
                    certifications: response.certifications.map { cert in
                        ManagerCertification(
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
            .catch { error -> AnyPublisher<ManagerProfileData, Error> in
                print("[ManagerProfileViewModel] API call failed, using fallback data: \(error)")
                let fallbackData = ManagerProfileData(
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
    
    // MARK: - Profile Updates
    
    func updateProfile(_ updatedData: ManagerProfileData) {
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
              let _ = Int(managerIdString) else {
            return Fail(error: APIError.invalidURL as Error).eraseToAnyPublisher()
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
        
        print("📸 [ManagerProfileViewModel] Uploading profile picture via supervisor API for manager: \(managerIdString)")
        
        supervisorApiService.uploadProfilePicture(supervisorId: managerIdString, image: image)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isUploadingImage = false
                    if case .failure(let error) = completion {
                        print("❌ [ManagerProfileViewModel] Upload failed: \(error)")
                        self.showError("Failed to upload profile picture: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    print("✅ [ManagerProfileViewModel] Upload response:")
                    print("   - Success: \(response.success)")
                    print("   - New URL: \(response.data?.profilePictureUrl ?? "NIL")")
                    
                    if response.success, let data = response.data {
                        self.profileData.profilePictureUrl = data.profilePictureUrl
                        
                        self.imageCache.markImageAsUpdated(
                            employeeId: managerIdString,
                            userType: .manager,
                            newImageUrl: data.profilePictureUrl
                        )
                        
                        self.profileImage = image
                        self.showSuccess("Profile picture updated successfully")
                    } else {
                        self.showError(response.message)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadCurrentProfilePicture() {
        guard let managerIdString = AuthService.shared.getEmployeeId() else {
            return
        }
        
        supervisorApiService.getProfilePicture(supervisorId: managerIdString)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("[ManagerProfileViewModel] Failed to load profile picture: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    if response.success {
                        let oldUrl = self.profileData.profilePictureUrl
                        self.profileData.profilePictureUrl = response.data.profilePictureUrl
                        
                        if oldUrl != response.data.profilePictureUrl {
                            self.loadProfileImageWithCache(forceRefresh: true)
                        }
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
        
        print("🗑️ [ManagerProfileViewModel] Deleting profile picture via supervisor API for manager: \(managerIdString)")
        
        supervisorApiService.deleteProfilePicture(supervisorId: managerIdString)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isUploadingImage = false
                    if case .failure(let error) = completion {
                        print("❌ [ManagerProfileViewModel] Delete failed: \(error)")
                        self.showError("Failed to delete profile picture: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    print("✅ [ManagerProfileViewModel] Delete response: \(response.success)")
                    
                    if response.success {
                        self.profileData.profilePictureUrl = nil
                        
                        self.imageCache.removeProfileImage(
                            employeeId: managerIdString,
                            userType: .manager
                        )
                        
                        self.profileImage = nil
                        self.showSuccess("Profile picture removed successfully")
                    } else {
                        self.showError(response.message)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
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

// MARK: - ProfilePictureUploadable conformance
extension ManagerProfileViewModel: ProfilePictureUploadable {
    var profilePictureUrl: String? {
        return profileData.profilePictureUrl
    }
}

// MARK: - Extension dla ProfileImageCache - Manager support
extension ProfileImageCache {
    func getManagerProfileImage(
        employeeId: String,
        currentImageUrl: String?,
        forceRefresh: Bool = false
    ) -> AnyPublisher<UIImage?, Never> {
        return getProfileImage(
            employeeId: employeeId,
            userType: .manager,
            currentImageUrl: currentImageUrl,
            forceRefresh: forceRefresh
        )
    }
}

// MARK: - Data Models (bez "External" prefiksu)

struct ManagerProfileData: Codable {
    var employeeId: String = ""
    var name: String = ""
    var email: String = ""
    var role: String = ""
    var assignedSince: Date = Date()
    var contractType: String = ""
    var assignedProjects: [ManagerAPIService.Project] = []
    var managedWorkers: [ManagerAPIService.Worker] = []
    var specializations: [String] = []
    var certifications: [ManagerCertification] = []
    
    var address: String?
    var phoneNumber: String?
    var emergencyContact: String?
    var profilePictureUrl: String?
    var isActivated: Bool = true
    var createdAt: Date?
    
    var companyName: String? = "KSR Cranes"
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

struct ManagerStats: Codable {
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

struct ManagerCertification: Codable, Identifiable {
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

// MARK: - Convenience Initializers

extension ManagerProfileData {
    init(
        employeeId: String,
        name: String,
        email: String,
        role: String,
        assignedSince: Date,
        contractType: String,
        specializations: [String] = [],
        certifications: [ManagerCertification] = [],
        address: String? = nil,
        phoneNumber: String? = nil,
        emergencyContact: String? = nil,
        profilePictureUrl: String? = nil,
        isActivated: Bool = true,
        createdAt: Date? = nil,
        companyName: String? = "KSR Cranes",
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

extension ManagerStats {
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
