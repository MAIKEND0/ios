import Foundation
import Combine

/// ViewModel dla ekranu Dashboard pracownika:
/// – trzyma podgląd godzin (hoursViewModel)
/// – trzyma listę zadań (tasksViewModel)
/// – pobiera i przechowuje ogłoszenia (announcements)
final class WorkerDashboardViewModel: ObservableObject {
    /// tygodniowe statystyki godzin
    @Published var hoursViewModel = WorkerWorkHoursViewModel()
    /// lista zadań przypisanych do pracownika
    @Published var tasksViewModel = WorkerTasksViewModel()
    /// ogłoszenia
    @Published var announcements: [Announcement] = []
    /// flaga ładowania ogłoszeń
    @Published var isLoadingAnnouncements = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // od razu przy starcie pobieramy ogłoszenia
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
        let id = tasksViewModel.tasks.first?.task_id
        return id.map(String.init) ?? ""
    }
}
