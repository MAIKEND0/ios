//WeeklyWorkEntryViewModel.swift

import Foundation
import Combine
import SwiftUI

// Extension for EditableWorkEntry to add properties for UI handling
extension EditableWorkEntry {
    /// Stores break minutes as Double for slider handling
    var pauseMinutesDouble: Double {
        get { Double(pauseMinutes) }
        set { pauseMinutes = Int(newValue) }
    }
    
    /// Formats total hours as a string (e.g., "8h 30m")
    var formattedTotalHours: String {
        if startTime == nil || endTime == nil {
            return "0h 0m"
        }
        
        let totalHoursValue = totalHours
        let hours = Int(totalHoursValue)
        let minutes = Int((totalHoursValue - Double(hours)) * 60)
        
        return "\(hours)h \(minutes)m"
    }
    
    /// Checks if the entry is for a future date (after today)
    var isFutureDate: Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())
    }
}

/// Struktura dla skopiowanego wpisu
struct CopiedEntry {
    let startTime: Date?
    let endTime: Date?
    let pauseMinutes: Int
    let notes: String
    let km: Double? // Obsługa km
}

/// ViewModel dla formularza tygodniowych wpisów pracy
final class WeeklyWorkEntryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var weekData: [EditableWorkEntry] = []
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isConfirmingSubmission = false
    @Published var anyDrafts = true
    
    // Przechowuje skopiowany wpis
    private var copiedEntry: CopiedEntry?
    // Przechowuje km dla wpisów, aby zachować wartości po reloadzie z API
    private var kmCache: [Int: Double?] = [:]

    // MARK: - Initializer Parameters
    private let employeeId: String
    private let taskId: String
    private(set) var selectedMonday: Date

    // MARK: - Combine Subscriptions
    private var cancellables = Set<AnyCancellable>()
    private let calendar = Calendar.current

    /// Inicjalizuje ViewModel z ID pracownika, ID zadania i poniedziałkiem wybranego tygodnia
    init(employeeId: String, taskId: String, selectedMonday: Date) {
        self.employeeId = employeeId
        self.taskId = taskId
        // Normalizuj selectedMonday do lokalnej strefy czasowej
        var localCalendar = Calendar.current
        localCalendar.timeZone = TimeZone.current
        self.selectedMonday = localCalendar.startOfDay(for: selectedMonday)
        self.weekData = generateEmptyWeekData()
        loadWeekDataFromAPI()
    }

    /// Kopiuje dane z określonego wpisu
    func copyEntry(from index: Int) {
        guard index < weekData.count else { return }
        guard weekData[index].startTime != nil, weekData[index].endTime != nil else {
            #if DEBUG
            print("[WeeklyWorkEntryViewModel] Cannot copy empty entry at index \(index)")
            #endif
            return
        }
        
        copiedEntry = CopiedEntry(
            startTime: weekData[index].startTime,
            endTime: weekData[index].endTime,
            pauseMinutes: weekData[index].pauseMinutes,
            notes: weekData[index].notes,
            km: weekData[index].km // Kopiowanie km
        )
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Copied entry from index \(index): startTime=\(String(describing: copiedEntry?.startTime)), endTime=\(String(describing: copiedEntry?.endTime)), pauseMinutes=\(copiedEntry?.pauseMinutes ?? 0), notes=\(copiedEntry?.notes ?? ""), km=\(String(describing: copiedEntry?.km))")
        #endif
    }
    
    /// Wkleja dane do określonego wpisu
    func pasteEntry(to index: Int) {
        guard index < weekData.count else { return }
        guard !weekData[index].isFutureDate else {
            #if DEBUG
            print("[WeeklyWorkEntryViewModel] Cannot paste to future date at index \(index)")
            #endif
            return
        }
        guard let sourceEntry = copiedEntry else {
            #if DEBUG
            print("[WeeklyWorkEntryViewModel] No copied entry available to paste")
            #endif
            return
        }
        
        weekData[index].startTime = sourceEntry.startTime
        weekData[index].endTime = sourceEntry.endTime
        weekData[index].pauseMinutes = sourceEntry.pauseMinutes
        weekData[index].notes = sourceEntry.notes
        weekData[index].km = sourceEntry.km // Wklejanie km
        
        // Zapisz km w cache
        kmCache[weekData[index].id] = sourceEntry.km
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Pasted entry to index \(index): startTime=\(String(describing: sourceEntry.startTime)), endTime=\(String(describing: sourceEntry.endTime)), pauseMinutes=\(sourceEntry.pauseMinutes), notes=\(sourceEntry.notes), km=\(String(describing: sourceEntry.km))")
        #endif
    }
    
    /// Czyści dane dla określonego dnia
    func clearDay(at index: Int) {
        guard index < weekData.count else { return }
        guard !weekData[index].isFutureDate else {
            #if DEBUG
            print("[WeeklyWorkEntryViewModel] Cannot clear future date at index \(index)")
            #endif
            return
        }
        guard weekData[index].status != "submitted" && weekData[index].status != "confirmed" else {
            #if DEBUG
            print("[WeeklyWorkEntryViewModel] Cannot clear submitted or confirmed entry at index \(index)")
            #endif
            return
        }
        
        weekData[index].startTime = nil
        weekData[index].endTime = nil
        weekData[index].pauseMinutes = 0
        weekData[index].notes = ""
        weekData[index].km = nil // Czyszczenie km
        weekData[index].isDraft = true
        weekData[index].status = "draft"
        
        // Usuń km z cache
        kmCache.removeValue(forKey: weekData[index].id)
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Cleared entry at index \(index)")
        #endif
    }
    
    /// Czyści wszystkie szkice wpisów
    func clearAllDrafts() {
        for i in 0..<weekData.count {
            if !weekData[i].isFutureDate && weekData[i].isDraft {
                weekData[i].startTime = nil
                weekData[i].endTime = nil
                weekData[i].pauseMinutes = 0
                weekData[i].notes = ""
                weekData[i].km = nil // Czyszczenie km
                weekData[i].status = "draft"
                // Usuń km z cache
                kmCache.removeValue(forKey: weekData[i].id)
            }
        }
        anyDrafts = false
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Cleared all draft entries")
        #endif
    }

    /// Ładuje dane z API:
    /// 1) fetchWorkEntries(isDraft: true) dla określonego taskId
    /// 2) Jeśli tablica pusta → fetchWorkEntries(isDraft: false) dla określonego taskId
    /// 3) Jeśli nadal pusta lub błąd → zachowaj wygenerowane puste dane tygodnia
    func loadWeekDataFromAPI() {
        isLoading = true
        let mondayStr = DateFormatter.isoDate.string(from: selectedMonday)
        let previousMonday = calendar.date(byAdding: .day, value: -7, to: selectedMonday)!
        let previousMondayStr = DateFormatter.isoDate.string(from: previousMonday)

        if WorkerAPIService.shared.authToken == nil {
            WorkerAPIService.shared.refreshTokenFromKeychain()
        }

        Publishers.Zip(
            WorkerAPIService.shared.fetchWorkEntries(employeeId: employeeId, weekStartDate: previousMondayStr, isDraft: true),
            WorkerAPIService.shared.fetchWorkEntries(employeeId: employeeId, weekStartDate: mondayStr, isDraft: true)
        )
        .map { (previousDrafts, currentDrafts) -> [EditableWorkEntry] in
            let allDrafts = (previousDrafts + currentDrafts).filter { $0.task_id == Int(self.taskId) ?? 0 }
            return allDrafts.map { apiEntry in
                return EditableWorkEntry(from: apiEntry)
            }
        }
        .flatMap { draftModels -> AnyPublisher<[EditableWorkEntry], WorkerAPIService.APIError> in
            if !draftModels.isEmpty {
                return Just(draftModels)
                    .setFailureType(to: WorkerAPIService.APIError.self)
                    .eraseToAnyPublisher()
            } else {
                return Publishers.Zip(
                    WorkerAPIService.shared.fetchWorkEntries(employeeId: self.employeeId, weekStartDate: previousMondayStr, isDraft: false),
                    WorkerAPIService.shared.fetchWorkEntries(employeeId: self.employeeId, weekStartDate: mondayStr, isDraft: false)
                )
                .map { (previousNonDrafts, currentNonDrafts) -> [EditableWorkEntry] in
                    let allNonDrafts = (previousNonDrafts + currentNonDrafts).filter { $0.task_id == Int(self.taskId) ?? 0 }
                    return allNonDrafts.map { apiEntry in
                        return EditableWorkEntry(from: apiEntry)
                    }
                }
                .eraseToAnyPublisher()
            }
        }
        .map { entries in
            var result = self.generateEmptyWeekData()
            let calendar = Calendar.current
            for apiEntry in entries {
                if let index = result.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: apiEntry.date) }) {
                    // Przywróć km z cache, jeśli dostępne
                    var updatedEntry = apiEntry
                    if let cachedKm = self.kmCache[apiEntry.id] {
                        updatedEntry.km = cachedKm
                    }
                    result[index] = updatedEntry
                } else {
                    // Przywróć km z cache dla nowych wpisów
                    var updatedEntry = apiEntry
                    if let cachedKm = self.kmCache[apiEntry.id] {
                        updatedEntry.km = cachedKm
                    }
                    result.append(updatedEntry)
                }
            }
            return result
        }
        .catch { error -> AnyPublisher<[EditableWorkEntry], Never> in
            #if DEBUG
            print("[WeeklyWorkEntryViewModel] Error loading data: \(error.localizedDescription)")
            #endif
            
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertTitle = "Error"
                self.alertMessage = error.localizedDescription
            }
            return Just(self.weekData)
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] entries in
            guard let self = self else { return }
            self.weekData = entries
            self.anyDrafts = !entries.filter { $0.isDraft == true }.isEmpty
            self.isLoading = false
            #if DEBUG
            print("[WeeklyWorkEntryViewModel] Loaded \(entries.count) entries into weekData for taskId: \(self.taskId)")
            for (index, entry) in entries.enumerated() {
                print("[WeeklyWorkEntryViewModel] Entry \(index): id=\(entry.id), date=\(entry.date), startTime=\(String(describing: entry.startTime)), endTime=\(String(describing: entry.endTime)), pauseMinutes=\(entry.pauseMinutes), km=\(String(describing: entry.km)), status=\(entry.status)")
            }
            #endif
        }
        .store(in: &cancellables)
    }
    
    /// Zapisuje bieżące wpisy jako szkic
    func saveDraft() {
        isLoading = true
        
        if WorkerAPIService.shared.authToken == nil {
            WorkerAPIService.shared.refreshTokenFromKeychain()
        }
        
        let futureDates = weekData.filter { entry in
            return entry.isFutureDate && (entry.startTime != nil || entry.endTime != nil)
        }
        
        if !futureDates.isEmpty {
            DispatchQueue.main.async {
                self.alertTitle = "Error"
                self.alertMessage = "Cannot save hours for future dates."
                self.showAlert = true
                self.isLoading = false
            }
            return
        }
        
        let validEntries = weekData.filter { entry in
            return (entry.startTime != nil && entry.endTime != nil) && !entry.isFutureDate
        }
        let groupedByDate = Dictionary(grouping: validEntries, by: { calendar.startOfDay(for: $0.date) })
        let hasMergedEntries = groupedByDate.values.contains { $0.count > 1 }
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] weekData before prepareEntriesForAPI: \(weekData.count) entries")
        for (index, entry) in weekData.enumerated() {
            print("[WeeklyWorkEntryViewModel] weekData entry \(index): date=\(entry.date), pauseMinutes=\(entry.pauseMinutes), km=\(String(describing: entry.km)), id=\(entry.id)")
        }
        #endif
        
        let apiEntries = prepareEntriesForAPI(asDraft: true)
        
        // Zapisz km w cache przed zapisem
        for entry in validEntries {
            kmCache[entry.id] = entry.km
        }
        
        if apiEntries.isEmpty {
            DispatchQueue.main.async {
                self.alertTitle = "Success"
                self.alertMessage = "Draft saved"
                self.showAlert = true
                self.isLoading = false
            }
            return
        }
        
        for entry in apiEntries {
            if let start = entry.start_time, let end = entry.end_time,
               end.compare(start) == .orderedAscending {
                DispatchQueue.main.async {
                    self.alertTitle = "Error"
                    self.alertMessage = "End time cannot be earlier than start time."
                    self.showAlert = true
                    self.isLoading = false
                }
                return
            }
        }
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Sending \(apiEntries.count) entries as draft for taskId: \(taskId)")
        #endif
        
        WorkerAPIService.shared.upsertWorkEntries(apiEntries)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                switch completion {
                case .finished:
                    self.loadWeekDataFromAPI()
                case .failure(let error):
                    self.alertTitle = "Error"
                    if case .serverError(401, _) = error {
                        self.alertMessage = "Session expired. Please log in again."
                    } else if case .serverError(409, _) = error {
                        self.alertMessage = "Data conflict. An entry with these parameters already exists."
                    } else if case .serverError(207, let message) = error {
                        self.alertMessage = "Some entries failed to save: \(message)"
                    } else {
                        self.alertMessage = error.localizedDescription
                    }
                    self.showAlert = true
                    #if DEBUG
                    print("[WeeklyWorkEntryViewModel] Saving failed: \(error.localizedDescription)")
                    #endif
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.alertTitle = "Success"
                var message = response.message.isEmpty ? "Draft saved" : response.message
                if hasMergedEntries {
                    message += "\nNote: Multiple entries for the same day were merged."
                }
                self.alertMessage = message
                self.showAlert = true
                self.anyDrafts = true
                #if DEBUG
                print("[WeeklyWorkEntryViewModel] Save successful: \(response.message)")
                print("[WeeklyWorkEntryViewModel] Posting workEntriesUpdated notification for taskId: \(self.taskId)")
                #endif
                // Wysyłaj powiadomienie o aktualizacji wpisów
                NotificationCenter.default.post(name: .workEntriesUpdated, object: nil)
                self.loadWeekDataFromAPI()
            }
            .store(in: &cancellables)
    }
    
    /// Przygotowuje dane do przesłania (status: submitted) i wysyła e-mail do supervisora
    func submitEntries() {
        isLoading = true
        
        let futureDates = weekData.filter { entry in
            return entry.isFutureDate && (entry.startTime != nil || entry.endTime != nil)
        }
        
        if !futureDates.isEmpty {
            DispatchQueue.main.async {
                self.alertTitle = "Error"
                self.alertMessage = "Cannot save hours for future dates."
                self.showAlert = true
                self.isLoading = false
            }
            return
        }
        
        isConfirmingSubmission = true
        
        for i in 0..<weekData.count where !weekData[i].isFutureDate {
            weekData[i].isDraft = false
            weekData[i].status = "submitted"
        }
        
        let apiEntries = prepareEntriesForAPI(asDraft: false)
        
        if apiEntries.isEmpty {
            DispatchQueue.main.async {
                self.alertTitle = "Error"
                self.alertMessage = "No hours to submit. Please enter work hours."
                self.showAlert = true
                self.isLoading = false
                self.isConfirmingSubmission = false
            }
            return
        }
        
        for entry in apiEntries {
            if let start = entry.start_time, let end = entry.end_time,
               end.compare(start) == .orderedAscending {
                DispatchQueue.main.async {
                    self.alertTitle = "Error"
                    self.alertMessage = "End time cannot be earlier than start time."
                    self.showAlert = true
                    self.isLoading = false
                    self.isConfirmingSubmission = false
                }
                return
            }
        }
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Sending \(apiEntries.count) entries for submission for taskId: \(taskId)")
        #endif
        
        WorkerAPIService.shared.upsertWorkEntries(apiEntries)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                self.isConfirmingSubmission = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.alertTitle = "Error"
                    if case .serverError(401, _) = error {
                        self.alertMessage = "Session expired. Please log in again."
                    } else if case .serverError(409, _) = error {
                        self.alertMessage = "Data conflict. An entry with these parameters already exists."
                    } else {
                        self.alertMessage = "Failed to submit hours: \(error.localizedDescription)"
                    }
                    self.showAlert = true
                    #if DEBUG
                    print("[WeeklyWorkEntryViewModel] Submission failed: \(error.localizedDescription)")
                    #endif
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.alertTitle = "Success"
                var message = response.message.isEmpty ? "Your hours have been submitted for approval." : response.message
                if let confirmationSent = response.confirmationSent, confirmationSent {
                    message += "\nA confirmation email has been sent to the supervisor."
                    if let token = response.confirmationToken {
                        message += "\nToken: \(token)"
                    }
                } else if let confirmationError = response.confirmationError {
                    message += "\nFailed to send confirmation email: \(confirmationError)"
                }
                self.alertMessage = message
                self.showAlert = true
                self.anyDrafts = false
                #if DEBUG
                print("[WeeklyWorkEntryViewModel] Submission successful. Message: \(response.message)")
                print("[WeeklyWorkEntryViewModel] Confirmation sent: \(response.confirmationSent ?? false)")
                if let token = response.confirmationToken {
                    print("[WeeklyWorkEntryViewModel] Confirmation token: \(token)")
                }
                print("[WeeklyWorkEntryViewModel] Posting workEntriesUpdated notification for taskId: \(self.taskId)")
                #endif
                // Wysyłaj powiadomienie o aktualizacji wpisów
                NotificationCenter.default.post(name: .workEntriesUpdated, object: nil)
                self.loadWeekDataFromAPI()
            }
            .store(in: &cancellables)
    }
    
    /// Konwertuje bieżące dane EditableWorkEntry na model WorkHourEntry dla API
    private func prepareEntriesForAPI(asDraft: Bool = true) -> [WorkerAPIService.WorkHourEntry] {
        var localCalendar = Calendar.current
        localCalendar.timeZone = TimeZone.current // Ustaw kalendarz na lokalną strefę czasową (CEST)
        
        let validEntries = weekData.filter { entry in
            return (entry.startTime != nil && entry.endTime != nil) && !entry.isFutureDate
        }
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Valid entries for API: \(validEntries.count)")
        for (index, entry) in validEntries.enumerated() {
            print("[WeeklyWorkEntryViewModel] Valid entry \(index): date=\(entry.date), pauseMinutes=\(entry.pauseMinutes), km=\(String(describing: entry.km)), id=\(entry.id)")
        }
        #endif
        
        var groupedEntries: [Date: [EditableWorkEntry]] = [:]
        for entry in validEntries {
            // Normalizuj entry.date w lokalnej strefie czasowej
            let localStartOfDay = localCalendar.startOfDay(for: entry.date)
            if groupedEntries[localStartOfDay] == nil {
                groupedEntries[localStartOfDay] = []
            }
            groupedEntries[localStartOfDay]?.append(entry)
        }
        
        #if DEBUG
        for (date, entries) in groupedEntries {
            print("[WeeklyWorkEntryViewModel] Grouped entries for date \(date): \(entries.count) entries, pauseMinutes: \(entries.map { $0.pauseMinutes }), km: \(entries.map { String(describing: $0.km) })")
        }
        #endif
        
        return groupedEntries.map { (localWorkDate, entries) -> WorkerAPIService.WorkHourEntry in
            let firstEntry = entries.first!
            var earliestStartTime = firstEntry.startTime!
            var latestEndTime = firstEntry.endTime!
            let totalPauseMinutes = entries.reduce(0) { $0 + $1.pauseMinutes }
            let combinedDescription = entries.map { $0.notes }.filter { !$0.isEmpty }.joined(separator: "; ")
            var existingEntryId: Int = 0
            let totalKm: Double? = entries.first?.km // Bierz km z pierwszego wpisu, bez sumowania
            
            for entry in entries {
                if entry.id != 0 && entry.id != Int(localWorkDate.timeIntervalSince1970) {
                    existingEntryId = entry.id
                    break
                }
            }
            
            for entry in entries {
                if let startTime = entry.startTime, startTime < earliestStartTime {
                    earliestStartTime = startTime
                }
                if let endTime = entry.endTime, endTime > latestEndTime {
                    latestEndTime = endTime
                }
            }
            
            #if DEBUG
            print("[WeeklyWorkEntryViewModel] Prepared entry for date \(localWorkDate): pauseMinutes=\(totalPauseMinutes), startTime=\(earliestStartTime), endTime=\(latestEndTime), km=\(String(describing: totalKm))")
            #endif
            
            // Formatuj localWorkDate jako ciąg yyyy-MM-dd
            let dateComponents = localCalendar.dateComponents([.year, .month, .day], from: localWorkDate)
            guard let year = dateComponents.year, let month = dateComponents.month, let day = dateComponents.day else {
                fatalError("Nie udało się uzyskać komponentów daty")
            }
            let formattedDate = String(format: "%04d-%02d-%02d", year, month, day)
            
            // Parsuj sformatowaną datę z powrotem do Date w UTC
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            guard let utcWorkDate = formatter.date(from: formattedDate) else {
                fatalError("Nie udało się sparsować daty: \(formattedDate)")
            }
            
            return WorkerAPIService.WorkHourEntry(
                entry_id: existingEntryId != 0 ? existingEntryId : 0,
                employee_id: Int(employeeId) ?? 0,
                task_id: Int(taskId) ?? 0,
                work_date: utcWorkDate,
                start_time: earliestStartTime,
                end_time: latestEndTime,
                pause_minutes: totalPauseMinutes,
                status: asDraft ? "pending" : "submitted",
                confirmation_status: "pending",
                is_draft: asDraft,
                description: combinedDescription.isEmpty ? nil : combinedDescription,
                tasks: nil,
                km: totalKm,
                confirmed_by: nil,
                confirmed_at: nil,
                isActive: nil,
                rejection_reason: nil,
                timesheetId: nil
            )
        }
    }
    
    /// Generuje pustą tablicę 7 wpisów, zaczynając od wybranego poniedziałku
    private func generateEmptyWeekData() -> [EditableWorkEntry] {
        var arr: [EditableWorkEntry] = []
        var localCalendar = Calendar.current
        localCalendar.timeZone = TimeZone.current // Ustaw kalendarz na lokalną strefę czasową (CEST)
        
        for offset in 0..<7 {
            if let date = localCalendar.date(byAdding: .day, value: offset, to: selectedMonday) {
                let normalizedDate = localCalendar.startOfDay(for: date)
                arr.append(.init(date: normalizedDate))
            }
        }
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Generated \(arr.count) empty days for the week")
        for (index, entry) in arr.enumerated() {
            print("[WeeklyWorkEntryViewModel] Empty entry \(index): date=\(entry.date)")
        }
        #endif
        
        return arr
    }
    
    // MARK: - Update Methods for UI Bindings
    
    func updateStartTime(at index: Int, to newTime: Date) {
        guard index < weekData.count else { return }
        if !weekData[index].isFutureDate {
            weekData[index].startTime = newTime
            // Zapisz km w cache, jeśli istnieje
            if let km = weekData[index].km {
                kmCache[weekData[index].id] = km
            }
        }
    }
    
    func updateEndTime(at index: Int, to newTime: Date) {
        guard index < weekData.count else { return }
        if !weekData[index].isFutureDate {
            weekData[index].endTime = newTime
            // Zapisz km w cache, jeśli istnieje
            if let km = weekData[index].km {
                kmCache[weekData[index].id] = km
            }
        }
    }
    
    func updateDescription(at index: Int, to newDescription: String) {
        guard index < weekData.count else { return }
        if !weekData[index].isFutureDate {
            weekData[index].notes = newDescription
            // Zapisz km w cache, jeśli istnieje
            if let km = weekData[index].km {
                kmCache[weekData[index].id] = km
            }
        }
    }
    
    func updatePauseMinutes(at index: Int, to minutes: Int) {
        guard index < weekData.count else { return }
        if !weekData[index].isFutureDate {
            weekData[index].pauseMinutes = minutes
            // Zapisz km w cache, jeśli istnieje
            if let km = weekData[index].km {
                kmCache[weekData[index].id] = km
            }
        }
    }
    
    func updateKm(at index: Int, to km: Double?) {
        guard index < weekData.count else { return }
        if !weekData[index].isFutureDate {
            weekData[index].km = km
            // Zapisz km w cache
            kmCache[weekData[index].id] = km
        }
    }
}
