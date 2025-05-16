//
//  WeeklyWorkEntryViewModel.swift
//  KSR Cranes App
//

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

/// ViewModel for handling weekly work entry forms
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
    private var copiedEntry: EditableWorkEntry?

    // MARK: - Initializer Parameters
    private let employeeId: String
    private let taskId: String
    private(set) var selectedMonday: Date

    // MARK: - Combine Subscriptions
    private var cancellables = Set<AnyCancellable>()
    private let calendar = Calendar.current

    /// Initializes the ViewModel with employee ID, task ID, and the Monday of the selected week
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

    /// Copies data from the specified entry
    func copyEntry(from index: Int) {
        guard index < weekData.count else { return }
        guard weekData[index].startTime != nil, weekData[index].endTime != nil else {
            #if DEBUG
            print("[WeeklyWorkEntryViewModel] Cannot copy empty entry at index \(index)")
            #endif
            return
        }
        
        copiedEntry = weekData[index]
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Copied entry from index \(index): startTime=\(String(describing: copiedEntry?.startTime)), endTime=\(String(describing: copiedEntry?.endTime)), pauseMinutes=\(copiedEntry?.pauseMinutes ?? 0), notes=\(copiedEntry?.notes ?? "")")
        #endif
    }
    
    /// Pastes data to the specified entry
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
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Pasted entry to index \(index): startTime=\(String(describing: sourceEntry.startTime)), endTime=\(String(describing: sourceEntry.endTime)), pauseMinutes=\(sourceEntry.pauseMinutes), notes=\(sourceEntry.notes)")
        #endif
    }
    
    /// Clears data for the specified day
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
        weekData[index].isDraft = true
        weekData[index].status = "draft"
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Cleared entry at index \(index)")
        #endif
    }
    
    /// Clears all draft entries
    func clearAllDrafts() {
        for i in 0..<weekData.count {
            if !weekData[i].isFutureDate && weekData[i].isDraft {
                weekData[i].startTime = nil
                weekData[i].endTime = nil
                weekData[i].pauseMinutes = 0
                weekData[i].notes = ""
                weekData[i].status = "draft"
            }
        }
        anyDrafts = false
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Cleared all draft entries")
        #endif
    }

    /// Loads data from the API:
    /// 1) fetchWorkEntries(isDraft: true) for the specific taskId
    /// 2) If empty array → fetchWorkEntries(isDraft: false) for the specific taskId
    /// 3) If still empty or error → keep generated empty week data
    func loadWeekDataFromAPI() {
        isLoading = true
        let mondayStr = DateFormatter.isoDate.string(from: selectedMonday)
        let previousMonday = calendar.date(byAdding: .day, value: -7, to: selectedMonday)!
        let previousMondayStr = DateFormatter.isoDate.string(from: previousMonday)

        if APIService.shared.authToken == nil {
            APIService.shared.refreshTokenFromKeychain()
        }

        Publishers.Zip(
            APIService.shared.fetchWorkEntries(employeeId: employeeId, weekStartDate: previousMondayStr, isDraft: true),
            APIService.shared.fetchWorkEntries(employeeId: employeeId, weekStartDate: mondayStr, isDraft: true)
        )
        .map { (previousDrafts, currentDrafts) -> [EditableWorkEntry] in
            let allDrafts = (previousDrafts + currentDrafts).filter { $0.task_id == Int(self.taskId) ?? 0 }
            return allDrafts.map { apiEntry in
                return EditableWorkEntry(from: apiEntry)
            }
        }
        .flatMap { draftModels -> AnyPublisher<[EditableWorkEntry], APIService.APIError> in
            if !draftModels.isEmpty {
                return Just(draftModels)
                    .setFailureType(to: APIService.APIError.self)
                    .eraseToAnyPublisher()
            } else {
                return Publishers.Zip(
                    APIService.shared.fetchWorkEntries(employeeId: self.employeeId, weekStartDate: previousMondayStr, isDraft: false),
                    APIService.shared.fetchWorkEntries(employeeId: self.employeeId, weekStartDate: mondayStr, isDraft: false)
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
                    result[index] = apiEntry
                } else {
                    result.append(apiEntry)
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
                print("[WeeklyWorkEntryViewModel] Entry \(index): id=\(entry.id), date=\(entry.date), startTime=\(String(describing: entry.startTime)), endTime=\(String(describing: entry.endTime)), pauseMinutes=\(entry.pauseMinutes), status=\(entry.status)")
            }
            #endif
        }
        .store(in: &cancellables)
    }
    
    /// Saves the current entries as a draft
    func saveDraft() {
        isLoading = true
        
        if APIService.shared.authToken == nil {
            APIService.shared.refreshTokenFromKeychain()
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
            print("[WeeklyWorkEntryViewModel] weekData entry \(index): date=\(entry.date), pauseMinutes=\(entry.pauseMinutes), id=\(entry.id)")
        }
        #endif
        
        let apiEntries = prepareEntriesForAPI(asDraft: true)
        
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
        
        APIService.shared.upsertWorkEntries(apiEntries)
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
    
    /// Prepares data for submission (status: submitted) and sends an email to the supervisor
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
        
        APIService.shared.upsertWorkEntries(apiEntries)
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
    
    /// Converts current EditableWorkEntry data to WorkHourEntry model for API
    private func prepareEntriesForAPI(asDraft: Bool = true) -> [APIService.WorkHourEntry] {
        var localCalendar = Calendar.current
        localCalendar.timeZone = TimeZone.current // Ustaw kalendarz na lokalną strefę czasową (CEST)
        
        let validEntries = weekData.filter { entry in
            return (entry.startTime != nil && entry.endTime != nil) && !entry.isFutureDate
        }
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Valid entries for API: \(validEntries.count)")
        for (index, entry) in validEntries.enumerated() {
            print("[WeeklyWorkEntryViewModel] Valid entry \(index): date=\(entry.date), pauseMinutes=\(entry.pauseMinutes), id=\(entry.id)")
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
            print("[WeeklyWorkEntryViewModel] Grouped entries for date \(date): \(entries.count) entries, pauseMinutes: \(entries.map { $0.pauseMinutes })")
        }
        #endif
        
        return groupedEntries.map { (localWorkDate, entries) -> APIService.WorkHourEntry in
            let firstEntry = entries.first!
            var earliestStartTime = firstEntry.startTime!
            var latestEndTime = firstEntry.endTime!
            let totalPauseMinutes = firstEntry.pauseMinutes // Zmieniono z 'var' na 'let'
            var combinedDescription = firstEntry.notes
            var existingEntryId: Int = 0
            
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
                if !entry.notes.isEmpty {
                    combinedDescription += (combinedDescription.isEmpty ? "" : "; ") + entry.notes
                }
            }
            
            #if DEBUG
            print("[WeeklyWorkEntryViewModel] Prepared entry for date \(localWorkDate): pauseMinutes=\(totalPauseMinutes), startTime=\(earliestStartTime), endTime=\(latestEndTime)")
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
            
            return APIService.WorkHourEntry(
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
                tasks: nil
            )
        }
    }
    
    /// Generates an empty array of 7 entries, starting from the selected Monday
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
        }
    }
    
    func updateEndTime(at index: Int, to newTime: Date) {
        guard index < weekData.count else { return }
        if !weekData[index].isFutureDate {
            weekData[index].endTime = newTime
        }
    }
    
    func updateDescription(at index: Int, to newDescription: String) {
        guard index < weekData.count else { return }
        if !weekData[index].isFutureDate {
            weekData[index].notes = newDescription
        }
    }
    
    func updatePauseMinutes(at index: Int, to minutes: Int) {
        guard index < weekData.count else { return }
        if !weekData[index].isFutureDate {
            weekData[index].pauseMinutes = minutes
        }
    }
}
