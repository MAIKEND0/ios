
//
//  ManagerProjectsViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 17/05/2025.
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
        
        let supervisorId = Int(AuthService.shared.getEmployeeId() ?? "0") ?? 0
        fetchProjects(supervisorId: supervisorId)
        
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
    
    private func fetchProjects(supervisorId: Int) {
        let mondayStr = DateFormatter.isoDate.string(from: Calendar.current.startOfWeek(for: Date()))
        
        // Pobierz wpisy godzin pracy i zadania
        Publishers.Zip(
            ManagerAPIService.shared.fetchPendingWorkEntriesForManager(weekStartDate: mondayStr, isDraft: false),
            ManagerAPIService.shared.fetchSupervisorTasks(supervisorId: supervisorId)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self else { return }
            self.isLoading = false
            if case .failure(let error) = completion {
                self.projects = []
                self.filteredProjects = []
                self.alertTitle = "Error"
                self.alertMessage = error.localizedDescription
                self.showAlert = true
                #if DEBUG
                print("[ManagerProjectsViewModel] Failed to load projects: \(error.localizedDescription)")
                #endif
            }
        } receiveValue: { [weak self] (entries, tasks) in
            guard let self else { return }
            // Grupowanie projektów na podstawie zadań
            var projectsDict: [Int: ManagerAPIService.Project] = [:]
            for task in tasks {
                guard let project = task.project else { continue }
                let projectId = project.project_id
                if var existingProject = projectsDict[projectId] {
                    var updatedTasks = existingProject.tasks
                    updatedTasks.append(task)
                    existingProject.tasks = updatedTasks
                    projectsDict[projectId] = existingProject
                } else {
                    let workerIds = entries
                        .filter { $0.task_id == task.task_id }
                        .map { $0.employee_id }
                    projectsDict[projectId] = ManagerAPIService.Project(
                        id: UUID(),
                        project_id: projectId,
                        title: project.title,
                        description: nil,
                        start_date: nil,
                        end_date: nil,
                        street: nil,
                        city: nil,
                        zip: nil,
                        status: nil,
                        tasks: [task],
                        assignedWorkersCount: Set(workerIds).count,
                        customer: nil // Added customer parameter
                    )
                }
            }
            
            // Pobierz pełne dane projektów
            ManagerAPIService.shared.fetchProjects(supervisorId: supervisorId)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    guard let self else { return }
                    if case .failure(let error) = completion {
                        #if DEBUG
                        print("[ManagerProjectsViewModel] Failed to load full project data: \(error.localizedDescription)")
                        #endif
                    }
                } receiveValue: { [weak self] fullProjects in
                    guard let self else { return }
                    self.projects = fullProjects.map { fullProject in
                        var project = fullProject
                        if let existing = projectsDict[fullProject.project_id] {
                            project.tasks = existing.tasks
                            project.assignedWorkersCount = existing.assignedWorkersCount
                        }
                        return project
                    }
                    self.filterProjects(by: .all)
                    #if DEBUG
                    print("[ManagerProjectsViewModel] Loaded \(self.projects.count) projects: \(self.projects.map { $0.title })")
                    #endif
                }
                .store(in: &self.cancellables)
        }
        .store(in: &cancellables)
    }
}
