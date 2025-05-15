import Foundation
import Combine

/// ViewModel dla ekranu Dashboard pracownika:
/// – przechowuje statystyki godzin (hoursViewModel)
/// – przechowuje listę zadań (tasksViewModel)
/// – zarządza ogłoszeniami (announcements)
final class WorkerDashboardViewModel: ObservableObject {
    // ViewModele podrzędne
    @Published var hoursViewModel = WorkerWorkHoursViewModel()
    @Published var tasksViewModel = WorkerTasksViewModel()
    
    // Ogłoszenia
    @Published var announcements: [Announcement] = []
    @Published var isLoadingAnnouncements = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Przy starcie pobieramy ogłoszenia
        loadAnnouncements()
    }

    /// Odświeża wszystkie dane: godziny, zadania i ogłoszenia
    func loadData() {
        hoursViewModel.loadEntries()
        tasksViewModel.loadTasks()
        loadAnnouncements()
    }

    /// Pobiera ogłoszenia z backendu przez APIService
    private func loadAnnouncements() {
        isLoadingAnnouncements = true
        APIService.shared
            .fetchAnnouncements()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoadingAnnouncements = false
                if case .failure = completion {
                    self.announcements = []
                }
            } receiveValue: { [weak self] anns in
                self?.announcements = anns
            }
            .store(in: &cancellables)
    }

    /// Zwraca ID pierwszego zadania (np. do otworzenia WeeklyWorkEntryForm)
    func getSelectedTaskId() -> String {
        // zakładamy, że Task ma pole `task_id: Int`
        guard let id = tasksViewModel.tasks.first?.task_id else {
            return ""
        }
        return String(id)
    }
}
