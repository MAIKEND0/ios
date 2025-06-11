//
//  ProjectBillingViewModel.swift
//  KSR Cranes App
//
//  ViewModel for managing project billing settings - COMPLETE WITH PUT SUPPORT
//

import Foundation
import SwiftUI
import Combine

class ProjectBillingViewModel: ObservableObject {
    @Published var billingSettings: [ChefBillingSettings] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showEditSheet = false
    @Published var showCreateSheet = false
    
    // Current/Active billing settings
    var currentBillingSettings: ChefBillingSettings? {
        let now = Date()
        return billingSettings.first { setting in
            setting.effectiveFrom <= now && (setting.effectiveTo == nil || setting.effectiveTo! >= now)
        }
    }
    
    // Future billing settings
    var futureBillingSettings: [ChefBillingSettings] {
        let now = Date()
        return billingSettings.filter { setting in
            setting.effectiveFrom > now
        }.sorted { $0.effectiveFrom < $1.effectiveFrom }
    }
    
    // Past billing settings
    var pastBillingSettings: [ChefBillingSettings] {
        let now = Date()
        return billingSettings.filter { setting in
            setting.effectiveTo != nil && setting.effectiveTo! < now
        }.sorted { $0.effectiveFrom > $1.effectiveFrom }
    }
    
    private let projectId: Int
    private var cancellables = Set<AnyCancellable>()
    
    init(projectId: Int) {
        self.projectId = projectId
    }
    
    func loadBillingSettings() {
        isLoading = true
        errorMessage = ""
        
        #if DEBUG
        print("[ProjectBillingViewModel] Loading billing settings for project: \(projectId)")
        #endif
        
        ChefProjectsAPIService.shared.fetchProjectBillingSettings(projectId: projectId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        self?.displayError("Failed to load billing settings: \(error.localizedDescription)")
                    case .finished:
                        #if DEBUG
                        print("[ProjectBillingViewModel] Successfully loaded \(self?.billingSettings.count ?? 0) billing settings")
                        #endif
                    }
                },
                receiveValue: { [weak self] settings in
                    self?.billingSettings = settings.sorted { $0.effectiveFrom > $1.effectiveFrom }
                }
            )
            .store(in: &cancellables)
    }
    
    func createBillingSettings(_ request: BillingSettingsRequest) {
        isLoading = true
        
        #if DEBUG
        print("[ProjectBillingViewModel] Creating new billing settings")
        #endif
        
        ChefProjectsAPIService.shared.upsertBillingSettings(projectId: projectId, settings: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        self?.displayError("Failed to create billing settings: \(error.localizedDescription)")
                    case .finished:
                        self?.showCreateSheet = false
                        #if DEBUG
                        print("[ProjectBillingViewModel] Billing settings created successfully")
                        #endif
                    }
                },
                receiveValue: { [weak self] newSettings in
                    // Add new settings to the list
                    self?.billingSettings.append(newSettings)
                    self?.billingSettings.sort { $0.effectiveFrom > $1.effectiveFrom }
                }
            )
            .store(in: &cancellables)
    }
    
    // ✅ UPDATED: Now uses PUT method for proper updates
    func updateBillingSettings(_ settingId: Int, with request: BillingSettingsRequest) {
        isLoading = true
        
        #if DEBUG
        print("[ProjectBillingViewModel] Updating billing settings: \(settingId)")
        #endif
        
        // ✅ NEW: Use dedicated PUT method for updates
        ChefProjectsAPIService.shared.updateBillingSettings(projectId: projectId, settingId: settingId, settings: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        self?.displayError("Failed to update billing settings: \(error.localizedDescription)")
                    case .finished:
                        self?.showEditSheet = false
                        #if DEBUG
                        print("[ProjectBillingViewModel] Billing settings updated successfully")
                        #endif
                    }
                },
                receiveValue: { [weak self] updatedSettings in
                    // Update the settings in the list
                    if let index = self?.billingSettings.firstIndex(where: { $0.settingId == settingId }) {
                        self?.billingSettings[index] = updatedSettings
                        self?.billingSettings.sort { $0.effectiveFrom > $1.effectiveFrom }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteBillingSettings(_ settingId: Int) {
        isLoading = true
        
        #if DEBUG
        print("[ProjectBillingViewModel] Deleting billing settings: \(settingId)")
        #endif
        
        ChefProjectsAPIService.shared.deleteBillingSettings(settingId: settingId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        self?.displayError("Failed to delete billing settings: \(error.localizedDescription)")
                    case .finished:
                        #if DEBUG
                        print("[ProjectBillingViewModel] Billing settings deleted successfully")
                        #endif
                    }
                },
                receiveValue: { [weak self] response in
                    // Remove settings from the list
                    self?.billingSettings.removeAll { $0.settingId == settingId }
                }
            )
            .store(in: &cancellables)
    }
    
    private func displayError(_ message: String) {
        errorMessage = message
        showError = true
        
        #if DEBUG
        print("[ProjectBillingViewModel] Error: \(message)")
        #endif
    }
}
