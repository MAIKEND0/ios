//
//  WorkerWorkHoursViewModel.swift
//  KSR Cranes App
//

import Foundation
import Combine

final class WorkerWorkHoursViewModel: ObservableObject {
    @Published var entries: [APIService.WorkHourEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var startDate: Date = {
        let now = Date()
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
    }()
    @Published var endDate: Date = {
        let now = Date()
        let cal = Calendar.current
        return cal.date(byAdding: .weekOfYear, value: 1, to: cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!)!
    }()
    @Published var weekStart: Date = {
        let now = Date()
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
    }()

    private var cancellables = Set<AnyCancellable>()
    private var employeeId: String?

    init() {
        setupWorkEntriesUpdateObserver()
    }

    private func setupWorkEntriesUpdateObserver() {
        NotificationCenter.default
            .publisher(for: .workEntriesUpdated)
            .sink { [weak self] _ in
                #if DEBUG
                print("[WorkerWorkHoursViewModel] Otrzymano powiadomienie o aktualizacji wpisów godzin pracy")
                #endif
                if let employeeId = self?.employeeId, let startDate = self?.startDate, let endDate = self?.endDate {
                    self?.loadEntries(employeeId: employeeId, startDate: startDate, endDate: endDate)
                }
            }
            .store(in: &cancellables)
    }

    /// Ładuje godziny pracy dla danego pracownika w zakresie dat od startDate do endDate
    func loadEntries(employeeId: String? = nil, startDate: Date? = nil, endDate: Date? = nil) {
        let calendar = Calendar.current
        let targetEmployeeId = employeeId ?? self.employeeId ?? AuthService.shared.getEmployeeId() ?? ""
        
        // Ustaw zakres dat
        self.employeeId = targetEmployeeId
        if let startDate = startDate, let endDate = endDate {
            self.startDate = startDate
            self.endDate = endDate
        } else {
            // Domyślny zakres: tydzień od weekStart
            self.startDate = weekStart
            self.endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? weekStart
        }

        // Przygotuj zakres dat do zapytania
        var allEntries: [APIService.WorkHourEntry] = []
        var currentDate = self.startDate
        let targetEndDate = self.endDate
        isLoading = true
        errorMessage = nil

        // Pobieraj dane tydzień po tygodniu w zakresie od startDate do endDate
        let group = DispatchGroup()
        while currentDate <= targetEndDate {
            group.enter()
            let mondayStr = DateFormatter.isoDate.string(from: currentDate)
            APIService.shared
                .fetchWorkEntries(
                    employeeId: targetEmployeeId,
                    weekStartDate: mondayStr
                )
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    if case let .failure(err) = completion {
                        self?.errorMessage = err.localizedDescription
                    }
                    group.leave()
                } receiveValue: { entries in
                    allEntries.append(contentsOf: entries)
                }
                .store(in: &cancellables)
            
            // Przejdź do następnego tygodnia
            currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
        }

        group.notify(queue: .main) { [weak self] in
            self?.entries = allEntries
            self?.isLoading = false
            #if DEBUG
            print("[WorkerWorkHoursViewModel] Załadowano \(allEntries.count) wpisów z bazy danych")
            #endif
        }
    }

    func previousWeek() {
        let calendar = Calendar.current
        weekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
        startDate = weekStart
        endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        loadEntries()
    }

    func nextWeek() {
        let calendar = Calendar.current
        weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        startDate = weekStart
        endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        loadEntries()
    }

    // MARK: - Obliczenia statystyk godzin pracy

    /// Suma godzin w bieżącym tygodniu
    var totalWeeklyHours: Double {
        let calendar = Calendar.current
        let currentWeek = calendar.startOfWeek(for: Date())
        return entries.reduce(0) { sum, entry in
            guard let start = entry.start_time,
                  isDate(start, inSameWeekAs: currentWeek, calendar: calendar),
                  let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
    }

    /// Suma godzin w bieżącym miesiącu
    var totalMonthlyHours: Double {
        let calendar = Calendar.current
        let currentMonth = startOfMonth(for: Date(), calendar: calendar)
        return entries.reduce(0) { sum, entry in
            guard let start = entry.start_time,
                  isDate(start, inSameMonthAs: currentMonth, calendar: calendar),
                  let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
    }

    /// Suma godzin w bieżącym roku
    var totalYearlyHours: Double {
        let calendar = Calendar.current
        let currentYear = startOfYear(for: Date(), calendar: calendar)
        return entries.reduce(0) { sum, entry in
            guard let start = entry.start_time,
                  isDate(start, inSameYearAs: currentYear, calendar: calendar),
                  let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
    }

    // MARK: - Pomocnicze metody do pracy z datami

    private func startOfWeek(for date: Date, calendar: Calendar = Calendar.current) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components)!
    }

    private func startOfMonth(for date: Date, calendar: Calendar = Calendar.current) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components)!
    }

    private func startOfYear(for date: Date, calendar: Calendar = Calendar.current) -> Date {
        let components = calendar.dateComponents([.year], from: date)
        return calendar.date(from: components)!
    }

    private func isDate(_ date1: Date, inSameWeekAs date2: Date, calendar: Calendar = Calendar.current) -> Bool {
        let components1 = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date1)
        let components2 = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date2)
        return components1.yearForWeekOfYear == components2.yearForWeekOfYear &&
               components1.weekOfYear == components2.weekOfYear
    }

    private func isDate(_ date1: Date, inSameMonthAs date2: Date, calendar: Calendar = Calendar.current) -> Bool {
        let components1 = calendar.dateComponents([.year, .month], from: date1)
        let components2 = calendar.dateComponents([.year, .month], from: date2)
        return components1.year == components2.year && components1.month == components2.month
    }

    private func isDate(_ date1: Date, inSameYearAs date2: Date, calendar: Calendar = Calendar.current) -> Bool {
        let components1 = calendar.dateComponents([.year], from: date1)
        let components2 = calendar.dateComponents([.year], from: date2)
        return components1.year == components2.year
    }
}
