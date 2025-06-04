//
//  ManagerWorkersViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 17/05/2025.
//

import Foundation
import Combine

final class ManagerWorkersViewModel: ObservableObject {
    @Published var workers: [ManagerAPIService.Worker] = []
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var lastLoadTime: Date?
    
    init() {
        loadData()
    }
    
    func loadData() {
        guard lastLoadTime == nil || Date().timeIntervalSince(lastLoadTime!) > 5 else {
            #if DEBUG
            print("[ManagerWorkersViewModel] Skipped data load due to recent refresh")
            #endif
            return
        }
        lastLoadTime = Date()
        
        isLoading = true
        #if DEBUG
        print("[ManagerWorkersViewModel] Starting data load")
        #endif
        
        let supervisorId = Int(AuthService.shared.getEmployeeId() ?? "0") ?? 0
        fetchWorkers(supervisorId: supervisorId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.isLoading ?? false {
                #if DEBUG
                print("[ManagerWorkersViewModel] Data loading timeout - forcing UI refresh")
                #endif
                self?.isLoading = false
            }
        }
    }
    
    private func fetchWorkers(supervisorId: Int) {
        ManagerAPIService.shared
            .fetchAssignedWorkers(supervisorId: supervisorId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (completion: Subscribers.Completion<BaseAPIService.APIError>) in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.workers = []
                    self.alertTitle = "Error"
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    #if DEBUG
                    print("[ManagerWorkersViewModel] Failed to load workers: \(error.localizedDescription)")
                    #endif
                }
            } receiveValue: { [weak self] (workers: [ManagerAPIService.Worker]) in
                guard let self = self else { return }
                self.workers = workers
                #if DEBUG
                print("[ManagerWorkersViewModel] Loaded \(workers.count) workers: \(workers.map { $0.name })")
                #endif
            }
            .store(in: &cancellables)
    }
}
