//
//  WorkerDashboardViewModel.swift
//  KSR Cranes App
//  Z systemem nawigacji po okresach czasowych
//

import Foundation
import Combine
import SwiftUI  // ✅ DODANY IMPORT dla Color type

final class WorkerDashboardViewModel: ObservableObject {
    // ViewModele podrzędne
    @Published var hoursViewModel = WorkerWorkHoursViewModel()
    @Published var tasksViewModel = WorkerTasksViewModel()
    
    // System nawigacji po okresach czasowych
    @Published var periodManager = TimePeriodManager()
    
    // Ogłoszenia
    @Published var announcements: [WorkerAPIService.Announcement] = []
    @Published var isLoadingAnnouncements = false
    
    // Statystyki dla aktualnie wybranego okresu
    @Published var currentPeriodHours: Double = 0.0
    @Published var currentPeriodKm: Double = 0.0
    @Published var currentPeriodEntries: Int = 0
    
    // Statystyki porównawcze (poprzedni okres)
    @Published var previousPeriodHours: Double = 0.0
    @Published var previousPeriodKm: Double = 0.0
    
    // Łączne statystyki (dla informacji)
    @Published var totalAllTimeHours: Double = 0.0
    @Published var totalAllTimeKm: Double = 0.0
    
    // Flaga do śledzenia, czy dane są załadowane
    @Published var isDataLoaded = false
    
    // Currently selected task ID (for Log Hours form)
    @Published var selectedTaskId: Int = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSubscriptions()
        setupWorkEntriesUpdateObserver()
    }
    
    private func setupSubscriptions() {
        // Obserwuj zmiany w hoursViewModel i aktualizuj statystyki
        hoursViewModel.$entries
            .combineLatest(hoursViewModel.$isLoading)
            .filter { _, isLoading in !isLoading }
            .sink { [weak self] entries, _ in
                DispatchQueue.main.async {
                    #if DEBUG
                    print("[WorkerDashboardViewModel] Entries changed: \(entries.count), updating statistics...")
                    #endif
                    self?.updateStatistics()
                    self?.suggestBestPeriodIfNeeded()
                }
            }
            .store(in: &cancellables)
        
        // Obserwuj zmiany w okresie czasowym
        periodManager.$currentPeriod
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    #if DEBUG
                    print("[WorkerDashboardViewModel] Period changed, updating statistics...")
                    #endif
                    self?.updateStatistics()
                }
            }
            .store(in: &cancellables)
        
        // Obserwuj załadowanie danych z obu ViewModeli
        Publishers.CombineLatest(
            tasksViewModel.$isLoading,
            hoursViewModel.$isLoading
        )
        .filter { !$0 && !$1 }
        .sink { [weak self] _ in
            DispatchQueue.main.async {
                #if DEBUG
                print("[WorkerDashboardViewModel] Both ViewModels finished loading")
                #endif
                self?.isDataLoaded = true
                self?.updateStatistics()
                self?.suggestBestPeriodIfNeeded()
            }
        }
        .store(in: &cancellables)
    }

    private func setupWorkEntriesUpdateObserver() {
        NotificationCenter.default
            .publisher(for: .workEntriesUpdated)
            .sink { [weak self] _ in
                #if DEBUG
                print("[WorkerDashboardViewModel] Otrzymano powiadomienie o aktualizacji wpisów godzin pracy")
                #endif
                self?.refreshHoursData()
            }
            .store(in: &cancellables)
    }
    
    private func updateStatistics() {
        let allEntries = hoursViewModel.entries
        
        // Statystyki dla aktualnego okresu
        let currentStats = periodManager.getStatsForCurrentPeriod(allEntries)
        currentPeriodHours = currentStats.hours
        currentPeriodKm = currentStats.km
        currentPeriodEntries = currentStats.entryCount
        
        // Statystyki dla poprzedniego okresu (do porównania)
        let previousPeriodStats = calculatePreviousPeriodStats(allEntries)
        previousPeriodHours = previousPeriodStats.hours
        previousPeriodKm = previousPeriodStats.km
        
        // Łączne statystyki
        totalAllTimeHours = allEntries.reduce(0.0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
        
        totalAllTimeKm = allEntries.reduce(0.0) { sum, entry in
            return sum + (entry.km ?? 0.0)
        }
        
        #if DEBUG
        print("[WorkerDashboardViewModel] === STATYSTYKI ===")
        print("Aktualny okres (\(periodManager.currentPeriod.displayName)):")
        print("  - Godziny: \(currentPeriodHours)")
        print("  - Kilometry: \(currentPeriodKm)")
        print("  - Wpisy: \(currentPeriodEntries)")
        print("Poprzedni okres:")
        print("  - Godziny: \(previousPeriodHours)")
        print("  - Kilometry: \(previousPeriodKm)")
        print("Łącznie wszystkich czasów:")
        print("  - Godziny: \(totalAllTimeHours)")
        print("  - Kilometry: \(totalAllTimeKm)")
        print("  - Wszystkich wpisów: \(allEntries.count)")
        print("========================")
        #endif
        
        objectWillChange.send()
    }
    
    private func calculatePreviousPeriodStats(_ entries: [WorkerAPIService.WorkHourEntry]) -> (hours: Double, km: Double) {
        let calendar = Calendar.current
        let currentPeriod = periodManager.currentPeriod
        
        // Oblicz poprzedni okres
        let previousReferenceDate: Date
        switch periodManager.selectedType {
        case .week:
            previousReferenceDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentPeriod.referenceDate) ?? currentPeriod.referenceDate
        case .month:
            previousReferenceDate = calendar.date(byAdding: .month, value: -1, to: currentPeriod.referenceDate) ?? currentPeriod.referenceDate
        case .twoWeeks:
            previousReferenceDate = calendar.date(byAdding: .day, value: -14, to: currentPeriod.referenceDate) ?? currentPeriod.referenceDate
        case .custom:
            previousReferenceDate = calendar.date(byAdding: .month, value: -1, to: currentPeriod.referenceDate) ?? currentPeriod.referenceDate
        }
        
        let previousPeriod = TimePeriodManager.createPeriod(type: periodManager.selectedType, referenceDate: previousReferenceDate)
        let previousEntries = entries.filter { previousPeriod.contains($0.work_date) }
        
        let hours = previousEntries.reduce(0.0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
        
        let km = previousEntries.reduce(0.0) { sum, entry in
            return sum + (entry.km ?? 0.0)
        }
        
        return (hours: hours, km: km)
    }
    
    private func suggestBestPeriodIfNeeded() {
        // Jeśli aktualny okres nie ma danych, ale są dane w innych okresach
        if currentPeriodEntries == 0 && !hoursViewModel.entries.isEmpty {
            if let suggestedPeriod = periodManager.findBestPeriodForData(hoursViewModel.entries) {
                #if DEBUG
                print("[WorkerDashboardViewModel] 💡 Sugeruję okres z danymi: \(suggestedPeriod.displayName)")
                #endif
                // Nie zmieniamy automatycznie - pozwalamy użytkownikowi wybrać
                // periodManager.selectPeriod(suggestedPeriod)
            }
        }
    }

    /// Odświeża wszystkie dane: godziny, kilometry, zadania i ogłoszenia
    func loadData() {
        #if DEBUG
        print("\n🔄 [WorkerDashboardViewModel] === ROZPOCZĘCIE ŁADOWANIA DANYCH ===")
        #endif
        
        isDataLoaded = false
        
        loadHoursData()
        tasksViewModel.loadTasks()
        loadAnnouncements()
        
        // Ustaw timeout na załadowanie danych
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            guard let self = self else { return }
            if !self.isDataLoaded {
                #if DEBUG
                print("⚠️ [WorkerDashboardViewModel] Timeout ładowania danych - wymuszenie odświeżenia widoku")
                #endif
                self.isDataLoaded = true
                self.updateStatistics()
            }
        }
    }
    
    private func refreshHoursData() {
        #if DEBUG
        print("[WorkerDashboardViewModel] Odświeżanie danych godzin...")
        #endif
        loadHoursData()
    }

    private func loadHoursData() {
        // Pobieraj dane dla szerszego zakresu - 8 tygodni wstecz i 4 w przód
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .weekOfYear, value: -8, to: today) ?? today
        let endDate = calendar.date(byAdding: .weekOfYear, value: 4, to: today) ?? today
        
        #if DEBUG
        print("[WorkerDashboardViewModel] Ładowanie danych godzin od \(startDate) do \(endDate)")
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
                if case .failure(let error) = completion {
                    #if DEBUG
                    print("[WorkerDashboardViewModel] Błąd ładowania ogłoszeń: \(error)")
                    #endif
                    self.announcements = []
                }
            } receiveValue: { [weak self] anns in
                self?.announcements = anns
            }
            .store(in: &cancellables)
    }

    /// Zwraca ID pierwszego zadania (np. do otworzenia WeeklyWorkEntryForm)
    func getSelectedTaskId() -> String {
        if selectedTaskId > 0 {
            return String(selectedTaskId)
        }
        
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
    
    /// Całkowita liczba godzin dla wybranego zadania w bieżącym zakresie dat
    var totalHoursForSelectedTask: Double {
        hoursViewModel.totalHoursForSelectedTask
    }
    
    /// Całkowita liczba kilometrów dla wybranego zadania w bieżącym zakresie dat
    var totalKmForSelectedTask: Double {
        hoursViewModel.totalKmForSelectedTask
    }
    
    // MARK: - Trend Analysis
    
    var hoursPercentageChange: Double {
        guard previousPeriodHours > 0 else { return currentPeriodHours > 0 ? 100 : 0 }
        return ((currentPeriodHours - previousPeriodHours) / previousPeriodHours) * 100
    }
    
    var kmPercentageChange: Double {
        guard previousPeriodKm > 0 else { return currentPeriodKm > 0 ? 100 : 0 }
        return ((currentPeriodKm - previousPeriodKm) / previousPeriodKm) * 100
    }
    
    var hoursGrowthTrend: TrendDirection {
        let change = hoursPercentageChange
        if abs(change) < 5 { return .stable }
        return change > 0 ? .up : .down
    }
    
    var kmGrowthTrend: TrendDirection {
        let change = kmPercentageChange
        if abs(change) < 5 { return .stable }
        return change > 0 ? .up : .down
    }
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .ksrSuccess
            case .down: return .ksrError
            case .stable: return .ksrSecondary
            }
        }
    }
    
    // MARK: - Quick Actions
    
    func goToPreviousPeriod() {
        periodManager.navigateToPrevious()
    }
    
    func goToNextPeriod() {
        periodManager.navigateToNext()
    }
    
    func goToCurrentPeriod() {
        periodManager.navigateToToday()
    }
    
    func changePeriodType(to type: TimePeriodType) {
        periodManager.changePeriodType(to: type)
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    func debugCurrentState() {
        print("\n🐛 === WorkerDashboardViewModel Debug State ===")
        print("Total entries: \(hoursViewModel.entries.count)")
        print("Current period: \(periodManager.currentPeriod.displayName)")
        print("Period type: \(periodManager.selectedType.rawValue)")
        print("Current period stats:")
        print("  - Hours: \(currentPeriodHours)")
        print("  - Km: \(currentPeriodKm)")
        print("  - Entries: \(currentPeriodEntries)")
        print("All time totals:")
        print("  - Hours: \(totalAllTimeHours)")
        print("  - Km: \(totalAllTimeKm)")
        print("Tasks count: \(tasksViewModel.tasks.count)")
        
        // Show period entry details
        let periodEntries = periodManager.getEntriesForCurrentPeriod(hoursViewModel.entries)
        print("Entries in current period: \(periodEntries.count)")
        for (index, entry) in periodEntries.prefix(3).enumerated() {
            print("  Entry \(index): \(entry.work_date) - \(entry.start_time?.description ?? "nil") to \(entry.end_time?.description ?? "nil"), km: \(entry.km ?? 0)")
        }
        
        // Suggest better period if available
        if let suggestion = periodManager.findBestPeriodForData(hoursViewModel.entries) {
            print("💡 Suggested period with data: \(suggestion.displayName)")
        }
        
        print("🐛 === End Debug State ===\n")
    }
    
    func testAPIConnection() {
        guard let employeeId = AuthService.shared.getEmployeeId() else {
            print("❌ Cannot test API - no employee_id")
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let weekStartString = formatter.string(from: startOfWeek)
        
        print("🧪 Testing API for employee_id: \(employeeId), week: \(weekStartString)")
        
        WorkerAPIService.shared
            .fetchWorkEntries(employeeId: employeeId, weekStartDate: weekStartString)
            .sink { completion in
                switch completion {
                case .finished:
                    print("✅ API test completed successfully")
                case .failure(let error):
                    print("❌ API test failed: \(error)")
                }
            } receiveValue: { entries in
                print("📊 API returned \(entries.count) entries for this week")
                for (index, entry) in entries.prefix(3).enumerated() {
                    print("  Entry \(index): \(entry.work_date) - \(entry.start_time?.description ?? "nil") to \(entry.end_time?.description ?? "nil")")
                }
            }
            .store(in: &cancellables)
    }
    #endif
}

// MARK: - Backward Compatibility Properties
extension WorkerDashboardViewModel {
    // Te properties dla kompatybilności z istniejącym kodem
    var totalWeeklyHours: Double { currentPeriodHours }
    var totalMonthlyHours: Double { currentPeriodHours }
    var totalWeeklyKm: Double { currentPeriodKm }
    var totalMonthlyKm: Double { currentPeriodKm }
    var totalYearlyHours: Double { totalAllTimeHours }
    var totalYearlyKm: Double { totalAllTimeKm }
}
