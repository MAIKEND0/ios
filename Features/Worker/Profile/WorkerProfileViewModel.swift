// Features/Worker/Profile/WorkerProfileViewModel.swift
import SwiftUI
import Combine
import Foundation

class WorkerProfileViewModel: ObservableObject {
    @Published var basicData = WorkerBasicData(employeeId: 0, name: "", email: "", role: "arbejder")
    @Published var stats = WorkerStats(currentWeekHours: 0, currentMonthHours: 0, pendingEntries: 0, approvedEntries: 0, rejectedEntries: 0, approvalRate: 0)
    @Published var currentTasks: [WorkerAPIService.Task] = []
    @Published var recentWorkEntries: [WorkerAPIService.WorkHourEntry] = []
    @Published var profileImage: UIImage? = nil
    @Published var isLoading = false
    @Published var isUploadingImage = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let profileAPIService = WorkerProfileAPIService.shared
    private let workerAPIService = WorkerAPIService.shared
    private let imageCache = ProfileImageCache.shared
    
    func loadData() {
        isLoading = true
        
        guard let employeeIdString = AuthService.shared.getEmployeeId() else {
            showError("Unable to get employee ID")
            isLoading = false
            return
        }
        
        #if DEBUG
        print("🔍 [WorkerProfileViewModel] Starting loadData() for worker ID: \(employeeIdString)")
        #endif
        
        // 🔥 POPRAWKA: Dodaj loadCurrentProfilePicturePublisher do kombinacji
        Publishers.CombineLatest4(
            loadBasicData(employeeId: employeeIdString),
            loadTasks(),
            loadWorkEntries(employeeId: employeeIdString),
            loadCurrentProfilePicturePublisher() // 🆕 Dodane!
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    print("❌ [WorkerProfileViewModel] Load failed: \(error)")
                    self.showError("Failed to load profile data: \(error.localizedDescription)")
                }
            },
            receiveValue: { [weak self] (basic, tasks, workEntries, profilePictureUrl) in
                guard let self = self else { return }
                
                print("✅ [WorkerProfileViewModel] All data loaded successfully")
                
                self.basicData = basic
                self.currentTasks = tasks
                self.recentWorkEntries = workEntries
                
                // 🆕 Set profile picture URL from API
                if let pictureUrl = profilePictureUrl, !pictureUrl.isEmpty {
                    self.basicData.profilePictureUrl = pictureUrl
                    print("✅ [WorkerProfileViewModel] Profile picture URL set: \(pictureUrl)")
                } else {
                    print("⚠️ [WorkerProfileViewModel] No profile picture URL")
                }
                
                // Oblicz statystyki z work entries
                self.stats = self.profileAPIService.calculateWorkerStats(workEntries: workEntries)
                
                // Load profile picture using cache
                self.loadProfileImageWithCache()
            }
        )
        .store(in: &cancellables)
    }
    
    // 🆕 Publisher version of loadCurrentProfilePicture
    private func loadCurrentProfilePicturePublisher() -> AnyPublisher<String?, Error> {
        guard let employeeIdString = AuthService.shared.getEmployeeId() else {
            return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        print("🔍 [WorkerProfileViewModel] Loading current profile picture for worker: \(employeeIdString)")
        
        return profileAPIService.getWorkerProfilePicture(employeeId: employeeIdString)
            .map { response -> String? in
                print("✅ [WorkerProfileViewModel] Profile picture response:")
                print("   - Success: \(response.success)")
                print("   - Profile Picture URL: \(response.data.profilePictureUrl ?? "NIL")")
                
                return response.success ? response.data.profilePictureUrl : nil
            }
            .catch { error -> AnyPublisher<String?, Error> in
                print("⚠️ [WorkerProfileViewModel] Profile picture load failed: \(error)")
                return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func loadProfileImageWithCache(forceRefresh: Bool = false) {
        guard let employeeIdString = AuthService.shared.getEmployeeId() else {
            print("❌ [WorkerProfileViewModel] No employee ID for cache loading")
            return
        }
        
        let currentUrl = basicData.profilePictureUrl
        
        print("🔍 [WorkerProfileViewModel] Loading profile image with cache:")
        print("   - Worker ID: \(employeeIdString)")
        print("   - Current URL: \(currentUrl ?? "NIL")")
        print("   - Force Refresh: \(forceRefresh)")
        
        imageCache.getWorkerProfileImage(
            employeeId: employeeIdString,
            currentImageUrl: currentUrl,
            forceRefresh: forceRefresh
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] image in
            if let image = image {
                print("✅ [WorkerProfileViewModel] Profile image loaded from cache successfully")
                self?.profileImage = image
            } else {
                print("⚠️ [WorkerProfileViewModel] Profile image cache returned nil")
            }
        }
        .store(in: &cancellables)
    }
    
    private func loadBasicData(employeeId: String) -> AnyPublisher<WorkerBasicData, Error> {
        return profileAPIService.fetchWorkerBasicData(employeeId: employeeId)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    private func loadTasks() -> AnyPublisher<[WorkerAPIService.Task], Error> {
        return workerAPIService.fetchTasks()
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    private func loadWorkEntries(employeeId: String) -> AnyPublisher<[WorkerAPIService.WorkHourEntry], Error> {
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let weekStartDate = formatter.string(from: thirtyDaysAgo)
        
        return workerAPIService.fetchWorkEntries(employeeId: employeeId, weekStartDate: weekStartDate)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Profile Update Methods
    
    func updateProfile(_ updatedData: WorkerBasicData) {
        isLoading = true
        
        guard let employeeIdString = AuthService.shared.getEmployeeId() else {
            showError("Unable to get employee ID")
            isLoading = false
            return
        }
        
        let contactData = WorkerContactUpdate(
            address: updatedData.address,
            phoneNumber: updatedData.phoneNumber,
            emergencyContact: updatedData.emergencyContact
        )
        
        profileAPIService.updateWorkerContactInfo(employeeId: employeeIdString, contactData: contactData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.showError("Failed to update profile: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    if response.success {
                        self.basicData = updatedData
                        self.showSuccess("Profile updated successfully")
                    } else {
                        self.showError(response.message)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Profile Picture Methods
    
    func uploadProfilePicture(_ image: UIImage) {
        guard let employeeIdString = AuthService.shared.getEmployeeId() else {
            showError("Unable to get employee ID")
            return
        }
        
        isUploadingImage = true
        
        print("📸 [WorkerProfileViewModel] Uploading profile picture for worker: \(employeeIdString)")
        
        // Natychmiastowy feedback - pokaż zdjęcie od razu
        profileImage = image
        
        profileAPIService.uploadWorkerProfilePicture(employeeId: employeeIdString, image: image)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isUploadingImage = false
                    if case .failure(let error) = completion {
                        print("❌ [WorkerProfileViewModel] Upload failed: \(error)")
                        self.showError("Failed to upload profile picture: \(error.localizedDescription)")
                        // W przypadku błędu, przywróć poprzednie zdjęcie
                        self.loadProfileImageWithCache(forceRefresh: true)
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    print("✅ [WorkerProfileViewModel] Upload response:")
                    print("   - Success: \(response.success)")
                    print("   - New URL: \(response.data?.profilePictureUrl ?? "NIL")")
                    
                    if response.success, let data = response.data {
                        // Zaktualizuj URL w basicData
                        self.basicData.profilePictureUrl = data.profilePictureUrl
                        
                        // Dodaj do cache bezpośrednio
                        if let newUrl = data.profilePictureUrl {
                            self.imageCache.cacheImageDirectly(
                                image,
                                employeeId: employeeIdString,
                                userType: .worker,
                                imageUrl: newUrl
                            )
                        }
                        
                        // Oznacz w cache jako zaktualizowane
                        self.imageCache.markImageAsUpdated(
                            employeeId: employeeIdString,
                            userType: .worker,
                            newImageUrl: data.profilePictureUrl
                        )
                        
                        self.showSuccess("Profile picture updated successfully")
                    } else {
                        self.showError(response.message)
                        // Przywróć poprzednie zdjęcie z cache
                        self.loadProfileImageWithCache(forceRefresh: true)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadCurrentProfilePicture() {
        guard let employeeIdString = AuthService.shared.getEmployeeId() else {
            return
        }
        
        profileAPIService.getWorkerProfilePicture(employeeId: employeeIdString)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("[WorkerProfileViewModel] Failed to load profile picture: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    if response.success {
                        let oldUrl = self.basicData.profilePictureUrl
                        self.basicData.profilePictureUrl = response.data.profilePictureUrl
                        
                        // Jeśli URL się zmienił, załaduj nowe zdjęcie z cache
                        if oldUrl != response.data.profilePictureUrl {
                            print("[WorkerProfileViewModel] 🔄 Profile picture URL changed: \(oldUrl ?? "nil") -> \(response.data.profilePictureUrl ?? "nil")")
                            self.loadProfileImageWithCache(forceRefresh: true)
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteProfilePicture() {
        guard let employeeIdString = AuthService.shared.getEmployeeId() else {
            showError("Unable to get employee ID")
            return
        }
        
        isUploadingImage = true
        
        print("🗑️ [WorkerProfileViewModel] Deleting profile picture for worker: \(employeeIdString)")
        
        profileAPIService.deleteWorkerProfilePicture(employeeId: employeeIdString)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isUploadingImage = false
                    if case .failure(let error) = completion {
                        print("❌ [WorkerProfileViewModel] Delete failed: \(error)")
                        self.showError("Failed to delete profile picture: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    print("✅ [WorkerProfileViewModel] Delete response: \(response.success)")
                    
                    if response.success {
                        self.basicData.profilePictureUrl = nil
                        
                        // Usuń z cache
                        self.imageCache.removeProfileImage(
                            employeeId: employeeIdString,
                            userType: .worker
                        )
                        
                        // Usuń zdjęcie z UI
                        self.profileImage = nil
                        
                        self.showSuccess("Profile picture removed successfully")
                    } else {
                        self.showError(response.message)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshProfileImage() {
        guard let employeeIdString = AuthService.shared.getEmployeeId() else {
            return
        }
        
        print("[WorkerProfileViewModel] 🔄 Refreshing profile image for worker \(employeeIdString)")
        
        // Najpierw sprawdź aktualny URL z serwera
        loadCurrentProfilePicture()
        
        // Następnie wymuś odświeżenie cache
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadProfileImageWithCache(forceRefresh: true)
        }
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
    
    // MARK: - Computed Properties
    
    var currentWeekHours: String {
        return String(format: "%.1f hours", stats.currentWeekHours)
    }
    
    var currentMonthHours: String {
        return String(format: "%.1f hours", stats.currentMonthHours)
    }
    
    var approvalRateFormatted: String {
        return "\(stats.efficiencyPercentage)%"
    }
    
    var recentTasksForDisplay: [WorkerAPIService.Task] {
        return Array(currentTasks.prefix(5))
    }
    
    var recentWorkEntriesForDisplay: [WorkerAPIService.WorkHourEntry] {
        return Array(recentWorkEntries.prefix(10))
    }
}

// MARK: - ProfilePictureUploadable conformance
extension WorkerProfileViewModel: ProfilePictureUploadable {
    var profilePictureUrl: String? {
        return basicData.profilePictureUrl
    }
}
