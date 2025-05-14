// Features/Worker/WorkerTasksViewModel.swift

import Foundation
import Combine

final class WorkerTasksViewModel: ObservableObject {
    @Published var tasks: [APIService.Task] = []
    @Published var isLoading = false
    @Published var error: String?

    private var cancellables = Set<AnyCancellable>()

    func loadTasks() {
        guard let employeeId = AuthService.shared.getEmployeeId() else {
            error = "Brak zalogowanego pracownika"
            tasks = []
            return
        }

        isLoading = true
        error = nil

        APIService.shared.fetchTasks()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let err) = completion {
                    self.error = err.localizedDescription
                    self.tasks = []
                }
            } receiveValue: { [weak self] tasks in
                self?.tasks = tasks
            }
            .store(in: &cancellables)
    }
}
