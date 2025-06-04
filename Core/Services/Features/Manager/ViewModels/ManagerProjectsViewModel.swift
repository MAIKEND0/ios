//
//  ManagerProjectsViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 17/05/2025.
//  Fixed to use API data properly on 25/05/2025.
//

import Foundation
import Combine

final class ManagerProjectsViewModel: ObservableObject {
    @Published var projects: [ManagerAPIService.Project] = []
    @Published var filteredProjects: [ManagerAPIService.Project] = []
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
            print("[ManagerProjectsViewModel] Skipped data load due to recent refresh")
            #endif
            return
        }
        lastLoadTime = Date()
        
        isLoading = true
        #if DEBUG
        print("[ManagerProjectsViewModel] Starting data load")
        #endif
        
        fetchProjects()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.isLoading ?? false {
                #if DEBUG
                print("[ManagerProjectsViewModel] Data loading timeout - forcing UI refresh")
                #endif
                self?.isLoading = false
            }
        }
    }
    
    func filterProjects(by status: ManagerProjectsView.ProjectStatusFilter) {
        switch status {
        case .all:
            filteredProjects = projects
        case .active:
            filteredProjects = projects.filter { $0.status == .aktiv }
        case .completed:
            filteredProjects = projects.filter { $0.status == .afsluttet }
        case .pending:
            filteredProjects = projects.filter { $0.status == .afventer }
        }
    }
    
    // UPROSZCZONE: Używamy tylko API endpoint /api/app/projects
    private func fetchProjects() {
        #if DEBUG
        print("[ManagerProjectsViewModel] Fetching projects from API")
        #endif
        
        ManagerAPIService.shared.fetchProjects()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                
                switch completion {
                case .failure(let error):
                    self.projects = []
                    self.filteredProjects = []
                    self.alertTitle = "Error Loading Projects"
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    #if DEBUG
                    print("[ManagerProjectsViewModel] Failed to load projects: \(error.localizedDescription)")
                    #endif
                case .finished:
                    #if DEBUG
                    print("[ManagerProjectsViewModel] Successfully loaded projects")
                    #endif
                }
            } receiveValue: { [weak self] projects in
                guard let self else { return }
                
                #if DEBUG
                print("[ManagerProjectsViewModel] Received \(projects.count) projects from API")
                for project in projects {
                    print("  - Project: \(project.title)")
                    print("    Tasks: \(project.tasks.count)")
                    print("    Workers: \(project.assignedWorkersCount)")
                    print("    Customer: \(project.customer?.name ?? "No customer")")
                }
                #endif
                
                // POPRAWIONE: Używamy danych bezpośrednio z API
                self.projects = projects
                self.filterProjects(by: .all)
                
                #if DEBUG
                print("[ManagerProjectsViewModel] Final projects count: \(self.projects.count)")
                print("[ManagerProjectsViewModel] Projects with tasks > 0: \(self.projects.filter { $0.tasks.count > 0 }.count)")
                print("[ManagerProjectsViewModel] Projects with workers > 0: \(self.projects.filter { $0.assignedWorkersCount > 0 }.count)")
                #endif
            }
            .store(in: &cancellables)
    }
}
