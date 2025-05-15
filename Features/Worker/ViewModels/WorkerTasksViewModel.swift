// Features/Worker/WorkerTasksViewModel.swift

import Foundation
import Combine

final class WorkerTasksViewModel: ObservableObject {
    @Published var tasks: [APIService.Task] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastLoadTime: Date?

    private var cancellables = Set<AnyCancellable>()

    func loadTasks() {
        // Check if user is logged in - but don't store the employeeId variable since we don't use it
        if AuthService.shared.getEmployeeId() == nil {
            error = "Brak zalogowanego pracownika"
            tasks = []
            return
        }

        // Debug logging
        #if DEBUG
        print("[WorkerTasksViewModel] Rozpoczęcie ładowania zadań...")
        #endif
        
        isLoading = true
        error = nil

        APIService.shared.fetchTasks()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                self.lastLoadTime = Date()
                
                if case .failure(let err) = completion {
                    self.error = err.localizedDescription
                    // Don't clear tasks on error to maintain UI state
                    #if DEBUG
                    print("[WorkerTasksViewModel] Błąd ładowania zadań: \(err.localizedDescription)")
                    #endif
                }
            } receiveValue: { [weak self] tasks in
                #if DEBUG
                print("[WorkerTasksViewModel] Załadowano \(tasks.count) zadań")
                #endif
                self?.tasks = tasks
                
                // Force UI update by sending objectWillChange
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
    
    // Check if tasks need to be reloaded (e.g. if > 5 minutes since last load)
    func shouldReloadTasks() -> Bool {
        guard let lastLoad = lastLoadTime else {
            return true
        }
        
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        return lastLoad < fiveMinutesAgo
    }
}
