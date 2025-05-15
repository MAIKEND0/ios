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
    
    // Flaga do śledzenia, czy dane są załadowane
    @Published var isDataLoaded = false
    
    // Currently selected task ID (for Log Hours form)
    @Published var selectedTaskId: Int = 0

    private var cancellables = Set<AnyCancellable>()
    private var dataLoadedPublisher = PassthroughSubject<Void, Never>()

    init() {
        // Przy starcie pobieramy ogłoszenia
        setupDataLoadedObserver()
    }
    
    private func setupDataLoadedObserver() {
        // Obserwuj załadowanie danych z obu podrzędnych ViewModeli
        Publishers.CombineLatest(
            tasksViewModel.$isLoading,
            hoursViewModel.$isLoading
        )
        .filter { !$0 && !$1 } // Kontynuuj tylko gdy oba viewModele zakończą ładowanie
        .sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.isDataLoaded = true
            }
        }
        .store(in: &cancellables)
    }

    /// Odświeża wszystkie dane: godziny, zadania i ogłoszenia
    func loadData() {
        isDataLoaded = false
        
        // Logowanie debugowania
        #if DEBUG
        print("[WorkerDashboardViewModel] Rozpoczęcie ładowania danych...")
        #endif
        
        // Ustaw timeout na załadowanie danych
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if !(self?.isDataLoaded ?? true) {
                #if DEBUG
                print("[WorkerDashboardViewModel] Timeout ładowania danych - wymuszenie odświeżenia widoku")
                #endif
                self?.isDataLoaded = true
            }
        }
        
        // Załaduj dane z podrzędnych view modeli
        hoursViewModel.loadEntries()
        tasksViewModel.loadTasks()
        loadAnnouncements()
        
        // Wymuś odświeżenie UI po krótkim opóźnieniu
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.objectWillChange.send()
        }
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
        // If we have a selected task, use it
        if selectedTaskId > 0 {
            return String(selectedTaskId)
        }
        
        // zakładamy, że Task ma pole `task_id: Int`
        guard let id = tasksViewModel.tasks.first?.task_id else {
            return ""
        }
        return String(id)
    }
    
    /// Set the selected task ID
    func setSelectedTaskId(_ taskId: Int) {
        selectedTaskId = taskId
    }
    
    // Sprawdza czy są aktywne zadania
    var hasActiveTasks: Bool {
        return !tasksViewModel.tasks.isEmpty
    }
}
