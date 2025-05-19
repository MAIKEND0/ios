//
//  WorkerDashboardViewModel.swift
//  KSR Cranes App
//

import Foundation
import Combine

/// ViewModel dla ekranu Dashboard pracownika:
/// – przechowuje statystyki godzin i kilometrów (hoursViewModel)
/// – przechowuje listę zadań (tasksViewModel)
/// – zarządza ogłoszeniami (announcements)
final class WorkerDashboardViewModel: ObservableObject {
    // ViewModele podrzędne
    @Published var hoursViewModel = WorkerWorkHoursViewModel()
    @Published var tasksViewModel = WorkerTasksViewModel()
    
    // Ogłoszenia
    @Published var announcements: [WorkerAPIService.Announcement] = []
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
        setupWorkEntriesUpdateObserver()
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

    private func setupWorkEntriesUpdateObserver() {
        // Nasłuchuj powiadomienia o aktualizacji wpisów godzin pracy
        NotificationCenter.default
            .publisher(for: .workEntriesUpdated)
            .sink { [weak self] _ in
                #if DEBUG
                print("[WorkerDashboardViewModel] Otrzymano powiadomienie o aktualizacji wpisów godzin pracy")
                #endif
                self?.loadHoursData()
            }
            .store(in: &cancellables)
    }

    /// Odświeża wszystkie dane: godziny, kilometry, zadania i ogłoszenia
    func loadData() {
        isDataLoaded = false
        
        // Logowanie debugowania
        #if DEBUG
        print("[WorkerDashboardViewModel] Rozpoczęcie ładowania danych...")
        #endif
        
        // Resetuj wpisy godzin przed ponownym ładowaniem
        hoursViewModel.resetEntries()
        
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
        loadHoursData()
        tasksViewModel.loadTasks()
        loadAnnouncements()
        
        // Wymuś odświeżenie UI po krótkim opóźnieniu
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.objectWillChange.send()
        }
    }

    private func loadHoursData() {
        // Pobieraj dane dla 4 tygodni wstecz i 4 tygodni w przyszłość
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .weekOfYear, value: -4, to: today) ?? today
        let endDate = calendar.date(byAdding: .weekOfYear, value: 4, to: today) ?? today
        #if DEBUG
        print("[WorkerDashboardViewModel] Ładowanie danych godzin i kilometrów od \(startDate) do \(endDate)")
        #endif
        hoursViewModel.loadEntries(startDate: startDate, endDate: endDate, isForDashboard: true)
    }

    /// Pobiera ogłoszenia z backendu przez WorkerAPIService
    private func loadAnnouncements() {
        isLoadingAnnouncements = true
        WorkerAPIService.shared
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
        // Jeśli wybrano zadanie, użyj go
        if selectedTaskId > 0 {
            return String(selectedTaskId)
        }
        
        // Zakładamy, że Task ma pole `task_id: Int`
        guard let id = tasksViewModel.tasks.first?.task_id else {
            return ""
        }
        return String(id)
    }
    
    /// Ustawia ID wybranego zadania
    func setSelectedTaskId(_ taskId: Int) {
        selectedTaskId = taskId
    }
    
    // Sprawdza, czy są aktywne zadania
    var hasActiveTasks: Bool {
        return !tasksViewModel.tasks.isEmpty
    }
    
    // MARK: - Statystyki godzin i kilometrów
    
    /// Całkowita liczba godzin w bieżącym tygodniu
    var totalWeeklyHours: Double {
        hoursViewModel.totalWeeklyHours
    }
    
    /// Całkowita liczba kilometrów w bieżącym tygodniu
    var totalWeeklyKm: Double {
        hoursViewModel.totalWeeklyKm
    }
    
    /// Całkowita liczba godzin w bieżącym miesiącu
    var totalMonthlyHours: Double {
        hoursViewModel.totalMonthlyHours
    }
    
    /// Całkowita liczba kilometrów w bieżącym miesiącu
    var totalMonthlyKm: Double {
        hoursViewModel.totalMonthlyKm
    }
    
    /// Całkowita liczba godzin w bieżącym roku
    var totalYearlyHours: Double {
        hoursViewModel.totalYearlyHours
    }
    
    /// Całkowita liczba kilometrów w bieżącym roku
    var totalYearlyKm: Double {
        hoursViewModel.totalYearlyKm
    }
    
    /// Całkowita liczba godzin dla wybranego zadania w bieżącym zakresie dat
    var totalHoursForSelectedTask: Double {
        hoursViewModel.totalHoursForSelectedTask
    }
    
    /// Całkowita liczba kilometrów dla wybranego zadania w bieżącym zakresie dat
    var totalKmForSelectedTask: Double {
        hoursViewModel.totalKmForSelectedTask
    }
}
