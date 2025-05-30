// Features/Worker/Profile/WorkerProfileViewModel.swift
import SwiftUI
import Combine
import Foundation

class WorkerProfileViewModel: ObservableObject {
    @Published var basicData = WorkerBasicData(employeeId: 0, name: "", email: "", role: "arbejder")
    @Published var stats = WorkerStats(currentWeekHours: 0, currentMonthHours: 0, pendingEntries: 0, approvedEntries: 0, rejectedEntries: 0, approvalRate: 0)
    @Published var currentTasks: [WorkerAPIService.Task] = []
    @Published var recentWorkEntries: [WorkerAPIService.WorkHourEntry] = []
    @Published var isLoading = false
    @Published var isUploadingImage = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let profileAPIService = WorkerProfileAPIService.shared
    private let workerAPIService = WorkerAPIService.shared
    
    func loadData() {
        isLoading = true
        
        guard let employeeIdString = AuthService.shared.getEmployeeId() else {
            showError("Unable to get employee ID")
            isLoading = false
            return
        }
        
        // Użyj istniejących API endpoints
        Publishers.CombineLatest3(
            loadBasicData(employeeId: employeeIdString),
            loadTasks(),
            loadWorkEntries(employeeId: employeeIdString)
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.showError("Failed to load profile data: \(error.localizedDescription)")
                }
            },
            receiveValue: { [weak self] (basic, tasks, workEntries) in
                guard let self = self else { return }
                self.basicData = basic
                self.currentTasks = tasks
                self.recentWorkEntries = workEntries
                
                // Oblicz statystyki z work entries
                self.stats = self.profileAPIService.calculateWorkerStats(workEntries: workEntries)
                
                // Load profile picture separately (non-blocking)
                self.loadCurrentProfilePicture()
            }
        )
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
        
        // Użyj prostego formattera zamiast extension
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
        
        profileAPIService.uploadWorkerProfilePicture(employeeId: employeeIdString, image: image)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isUploadingImage = false
                    if case .failure(let error) = completion {
                        self.showError("Failed to upload profile picture: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    if response.success, let data = response.data {
                        self.basicData.profilePictureUrl = data.profilePictureUrl
                        self.showSuccess("Profile picture updated successfully")
                    } else {
                        self.showError(response.message)
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
                        #if DEBUG
                        print("[WorkerProfileViewModel] Failed to load profile picture: \(error)")
                        #endif
                        // Don't show error to user for this, it's not critical
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    if response.success {
                        self.basicData.profilePictureUrl = response.data.profilePictureUrl
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
        
        profileAPIService.deleteWorkerProfilePicture(employeeId: employeeIdString)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isUploadingImage = false
                    if case .failure(let error) = completion {
                        self.showError("Failed to delete profile picture: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    if response.success {
                        self.basicData.profilePictureUrl = nil
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
