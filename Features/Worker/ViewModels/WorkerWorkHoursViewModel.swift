import Foundation
import Combine

/// ViewModel do wyświetlania i analizy godzin pracy pracownika
final class WorkerWorkHoursViewModel: ObservableObject {
    @Published var entries: [APIService.WorkHourEntry] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var weekStart: Date = {
        let now = Date()
        let cal = Calendar.current
        return cal.date(
            from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        )!
    }()

    private var cancellables = Set<AnyCancellable>()

    func loadEntries(isDraft: Bool = false) {
        guard let empId = AuthService.shared.getEmployeeId() else {
            error = "Brak zalogowanego pracownika"
            entries = []
            return
        }

        let weekStartStr = DateFormatter.isoDate.string(from: weekStart)
        isLoading = true
        error = nil

        APIService.shared
            .fetchWorkEntries(
                employeeId: empId,
                weekStartDate: weekStartStr,
                isDraft: isDraft
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.error = err.localizedDescription
                    self?.entries = []
                }
            } receiveValue: { [weak self] fetched in
                self?.entries = fetched
            }
            .store(in: &cancellables)
    }

    func previousWeek() {
        weekStart = Calendar.current.date(
            byAdding: .weekOfYear, value: -1, to: weekStart
        )!
        loadEntries()
    }

    func nextWeek() {
        weekStart = Calendar.current.date(
            byAdding: .weekOfYear, value: 1, to: weekStart
        )!
        loadEntries()
    }
    
    /// Oblicza całkowitą liczbę godzin w bieżącym tygodniu
    var totalWeeklyHours: Double {
        entries.reduce(0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            
            let intervalInSeconds = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            let hoursWorked = max(0, (intervalInSeconds - pauseSeconds) / 3600)
            
            return sum + hoursWorked
        }
    }
    
    /// Oblicza całkowitą liczbę godzin w bieżącym miesiącu
    var totalMonthlyHours: Double {
        // Prosta logika zastępcza - w rzeczywistej aplikacji
        // należałoby pobrać dane z całego miesiąca
        return totalWeeklyHours * 4 // Przybliżenie dla przykładu
    }
    
    /// Oblicza całkowitą liczbę godzin w bieżącym roku
    var totalYearlyHours: Double {
        // Prosta logika zastępcza - w rzeczywistej aplikacji
        // należałoby pobrać dane z całego roku
        return totalWeeklyHours * 52 // Przybliżenie dla przykładu
    }
}
