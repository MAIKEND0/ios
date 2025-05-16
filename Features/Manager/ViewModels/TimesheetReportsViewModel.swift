
//
//  TimesheetReportsViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 18/05/2025.
//

import Foundation
import Combine

final class TimesheetReportsViewModel: ObservableObject {
    @Published var timesheets: [ManagerAPIService.Timesheet] = []
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
            print("[TimesheetReportsViewModel] Skipped data load due to recent refresh")
            #endif
            return
        }
        lastLoadTime = Date()
        
        isLoading = true
        #if DEBUG
        print("[TimesheetReportsViewModel] Starting data load")
        #endif
        
        let supervisorId = Int(AuthService.shared.getEmployeeId() ?? "0") ?? 0
        fetchTimesheets(supervisorId: supervisorId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.isLoading ?? false {
                #if DEBUG
                print("[TimesheetReportsViewModel] Data loading timeout - forcing UI refresh")
                #endif
                self?.isLoading = false
            }
        }
    }
    
    private func fetchTimesheets(supervisorId: Int) {
        ManagerAPIService.shared
            .fetchTimesheets(supervisorId: supervisorId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.timesheets = []
                    self.alertTitle = "Error"
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    #if DEBUG
                    print("[TimesheetReportsViewModel] Failed to load timesheets: \(error.localizedDescription)")
                    #endif
                }
            } receiveValue: { [weak self] timesheets in
                guard let self = self else { return }
                self.timesheets = timesheets
                #if DEBUG
                print("[TimesheetReportsViewModel] Loaded \(timesheets.count) timesheets")
                #endif
            }
            .store(in: &cancellables)
    }
}
