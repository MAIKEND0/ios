import Foundation
import Combine

final class WorkerWorkHoursViewModel: ObservableObject {
    @Published var entries: [APIService.WorkHourEntry] = []
    @Published var tasks: [APIService.Task] = []
    @Published var selectedTaskId: Int = 0 // 0 indicates no task selected
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

    private var cancellables = Set<AnyCancellable>()
    private var employeeId: String?

    init() {
        self.employeeId = AuthService.shared.getEmployeeId() ?? ""
        setupWorkEntriesUpdateObserver()
        loadTasks() // Fetch tasks on initialization
    }

    private func setupWorkEntriesUpdateObserver() {
        NotificationCenter.default
            .publisher(for: .workEntriesUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                #if DEBUG
                print("[WorkerWorkHoursViewModel] Received notification of work entries update")
                #endif
                if let employeeId = self?.employeeId, let startDate = self?.startDate, let endDate = self?.endDate {
                    self?.loadEntries(employeeId: employeeId, startDate: startDate, endDate: endDate, isForDashboard: true)
                }
            }
            .store(in: &cancellables)
    }

    /// Loads tasks for the employee
    func loadTasks() {
        isLoading = true
        errorMessage = nil
        
        APIService.shared.fetchTasks()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    #if DEBUG
                    print("[WorkerWorkHoursViewModel] Failed to load tasks: \(error.localizedDescription)")
                    #endif
                }
            } receiveValue: { [weak self] tasks in
                self?.tasks = tasks
                if !tasks.isEmpty && self?.selectedTaskId == 0 {
                    self?.selectedTaskId = tasks.first?.task_id ?? 0
                    self?.loadEntries()
                }
                #if DEBUG
                print("[WorkerWorkHoursViewModel] Loaded \(tasks.count) tasks")
                #endif
            }
            .store(in: &cancellables)
    }

    /// Loads work hours for the given employee within the date range
    func loadEntries(employeeId: String? = nil, startDate: Date? = nil, endDate: Date? = nil, isForDashboard: Bool = false) {
        let calendar = Calendar.current
        let targetEmployeeId = employeeId ?? self.employeeId ?? AuthService.shared.getEmployeeId() ?? ""
        
        self.employeeId = targetEmployeeId
        if let startDate = startDate, let endDate = endDate {
            self.startDate = startDate
            self.endDate = endDate
        } else {
            self.startDate = calendar.startOfWeek(for: Date())
            self.endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: self.startDate)!
        }

        var allEntries: [APIService.WorkHourEntry] = []
        var currentDate = self.startDate
        let targetEndDate = self.endDate
        isLoading = true
        errorMessage = nil

        let group = DispatchGroup()
        while currentDate < targetEndDate {
            group.enter()
            let mondayStr = DateFormatter.isoDate.string(from: currentDate)
            #if DEBUG
            print("[WorkerWorkHoursViewModel] Fetching entries for week starting \(mondayStr) with employeeId \(targetEmployeeId)")
            #endif
            APIService.shared
                .fetchWorkEntries(
                    employeeId: targetEmployeeId,
                    weekStartDate: mondayStr,
                    isDraft: nil
                )
                .sink { [weak self] completion in
                    if case let .failure(err) = completion {
                        DispatchQueue.main.async {
                            self?.errorMessage = err.localizedDescription
                            #if DEBUG
                            print("[WorkerWorkHoursViewModel] Error fetching entries for week starting \(mondayStr): \(err.localizedDescription)")
                            #endif
                        }
                    }
                    group.leave()
                } receiveValue: { entries in
                    #if DEBUG
                    print("[WorkerWorkHoursViewModel] Received \(entries.count) entries for week starting \(mondayStr): \(entries)")
                    #endif
                    allEntries.append(contentsOf: entries)
                }
                .store(in: &cancellables)
            
            // Move to the next week
            currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            // Zachowaj istniejące wpisy, aktualizując tylko te, które są w allEntries
            var updatedEntries = self.entries
            let calendar = Calendar.current
            for entry in allEntries {
                if let index = updatedEntries.firstIndex(where: { $0.entry_id == entry.entry_id }) {
                    updatedEntries[index] = entry
                } else {
                    updatedEntries.append(entry)
                }
            }
            // Zachowaj wszystkie wpisy, usuwając tylko te, które są w zakresie dat i nie znajdują się w allEntries
            updatedEntries = updatedEntries.filter { entry in
                let entryWeek = calendar.startOfWeek(for: entry.work_date)
                return allEntries.contains(where: { $0.entry_id == entry.entry_id }) ||
                       entryWeek < self.startDate || entryWeek >= self.endDate
            }
            self.entries = updatedEntries.sorted { $0.work_date < $1.work_date }
            self.isLoading = false
            #if DEBUG
            print("[WorkerWorkHoursViewModel] Loaded \(allEntries.count) new entries, total entries: \(self.entries.count)")
            #endif
        }
    }

    /// Resets entries to an empty array
    func resetEntries() {
        entries = []
        #if DEBUG
        print("[WorkerWorkHoursViewModel] Entries reset to empty array")
        #endif
    }

    // MARK: - Obliczenia statystyk godzin pracy

    /// Total hours in the current week
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

    /// Total hours in the current month
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

    /// Total hours in the current year
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

    /// Total hours for the selected task within the current date range
    var totalHoursForSelectedTask: Double {
        entries.reduce(0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
    }

    // MARK: - Helper Methods for Date Handling

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
