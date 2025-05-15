//
//  WeeklyWorkEntryViewModel.swift
//  KSR Cranes App
//

import Foundation
import Combine

// Rozszerzenie dla EditableWorkEntry, aby dodać właściwość dla przechowywania przerwy w minutach
extension EditableWorkEntry {
    /// Przechowuje minuty przerwy jako double dla obsługi suwaka
    var pauseMinutesDouble: Double {
        get { Double(pauseMinutes) }
        set { pauseMinutes = Int(newValue) }
    }
    
    /// Oblicza łączną liczbę godzin jako string (np. "8h 30m")
    var formattedTotalHours: String {
        if startTime == nil || endTime == nil {
            return "0h 0m"
        }
        
        let totalHoursValue = totalHours
        let hours = Int(totalHoursValue)
        let minutes = Int((totalHoursValue - Double(hours)) * 60)
        
        return "\(hours)h \(minutes)m"
    }
    
    /// Sprawdza, czy wpis dotyczy przyszłej daty (po dzisiejszym dniu)
    var isFutureDate: Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())
    }
}

/// Dostosowany ViewModel do obsługi tygodniowych wpisów godzin pracy.
final class WeeklyWorkEntryViewModel: ObservableObject {
    // MARK: – Publikowane właściwości
    @Published var weekData: [EditableWorkEntry] = []
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isConfirmingSubmission = false
    @Published var anyDrafts = true

    // MARK: – Parametry inicjalizatora
    private let employeeId: String
    private let taskId: String
    private(set) var selectedMonday: Date

    // MARK: – Subskrypcje Combine
    private var cancellables = Set<AnyCancellable>()

    /// Tworzymy ViewModel z danymi: identyfikator pracownika, zadania oraz tydzień (poniedziałek)
    init(employeeId: String, taskId: String, selectedMonday: Date) {
        self.employeeId = employeeId
        self.taskId = taskId
        self.selectedMonday = selectedMonday

        // Create empty week data first to ensure we have 7 days
        self.weekData = generateEmptyWeekData()
        
        // Automatically load data from API
        loadWeekDataFromAPI()
    }

    /// Ładuje dane z API:
    /// 1) fetchWorkEntries(isDraft: true)
    /// 2) jeśli pusta tablica → fetchWorkEntries(isDraft: false)
    /// 3) jeśli dalej pusto lub błąd → generateEmptyWeekData()
    func loadWeekDataFromAPI() {
        isLoading = true
        let mondayStr = DateFormatter.isoDate.string(from: selectedMonday)

        // Upewnij się, że token jest odświeżony przed zapytaniem
        if APIService.shared.authToken == nil {
            APIService.shared.refreshTokenFromKeychain()
        }

        APIService.shared
            .fetchWorkEntries(employeeId: employeeId, weekStartDate: mondayStr, isDraft: true)
            .flatMap { drafts -> AnyPublisher<[EditableWorkEntry], APIService.APIError> in
                let draftModels = drafts.map(EditableWorkEntry.init)
                
                // Update anyDrafts flag
                self.anyDrafts = !draftModels.isEmpty
                
                if !draftModels.isEmpty {
                    // Jeśli są drafty, zwracamy je od razu
                    return Just(draftModels)
                        .setFailureType(to: APIService.APIError.self)
                        .eraseToAnyPublisher()
                } else {
                    // W przeciwnym razie pobieramy wpisy zatwierdzone
                    return APIService.shared
                        .fetchWorkEntries(employeeId: self.employeeId, weekStartDate: mondayStr, isDraft: false)
                        .map { $0.map(EditableWorkEntry.init) }
                        .eraseToAnyPublisher()
                }
            }
            .map { entries in
                // If there are no entries from API, use our existing empty data
                if entries.isEmpty {
                    return self.weekData
                }
                
                // Since API may not return all 7 days, ensure we have data for each day
                var result = self.generateEmptyWeekData()
                let calendar = Calendar.current
                for apiEntry in entries {
                    if let index = result.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: apiEntry.date) }) {
                        result[index] = apiEntry
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
                    self.alertTitle = "Błąd"
                    self.alertMessage = error.localizedDescription
                }
                return Just(self.weekData)
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                self?.weekData = entries
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Save work entries
    
    /// Zapisuje bieżące wpisy jako wersję roboczą
    func saveDraft() {
        isLoading = true
        
        // Odśwież token przed wysłaniem żądania
        if APIService.shared.authToken == nil {
            APIService.shared.refreshTokenFromKeychain()
        }
        
        // Sprawdź przyszłe daty - odrzuć wpisy z przyszłości
        let futureDates = weekData.filter { entry in
            return entry.isFutureDate && (entry.startTime != nil || entry.endTime != nil)
        }
        
        if !futureDates.isEmpty {
            DispatchQueue.main.async {
                self.alertTitle = "Błąd"
                self.alertMessage = "Nie można zapisać godzin dla przyszłych dni."
                self.showAlert = true
                self.isLoading = false
            }
            return
        }
        
        // Przygotuj wpisy do API
        let apiEntries = prepareEntriesForAPI(asDraft: true)
        
        // Jeśli nie ma wpisów do zapisania, pokaż sukces
        if apiEntries.isEmpty {
            DispatchQueue.main.async {
                self.alertTitle = "Sukces"
                self.alertMessage = "Zapisano wersję roboczą"
                self.showAlert = true
                self.isLoading = false
            }
            return
        }
        
        // Walidacja dat - sprawdź, czy end_time jest późniejsze niż start_time
        for entry in apiEntries {
            if let start = entry.start_time, let end = entry.end_time,
               end.compare(start) == .orderedAscending {
                DispatchQueue.main.async {
                    self.alertTitle = "Błąd"
                    self.alertMessage = "Godzina zakończenia nie może być wcześniejsza niż godzina rozpoczęcia."
                    self.showAlert = true
                    self.isLoading = false
                }
                return
            }
        }
        
        // Wykonaj zapytanie API
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Wysyłanie \(apiEntries.count) wpisów jako wersję roboczą")
        #endif
        
        APIService.shared.upsertWorkEntries(apiEntries)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                switch completion {
                case .finished:
                    // Ponowne załadowanie danych po sukcesie, aby zsynchronizować entry_id
                    self.loadWeekDataFromAPI()
                case .failure(let error):
                    self.alertTitle = "Błąd"
                    if case .serverError(401, _) = error {
                        self.alertMessage = "Wygasła sesja. Zaloguj się ponownie."
                    } else if case .serverError(409, _) = error {
                        self.alertMessage = "Wystąpił konflikt danych. Wpis o tych parametrach już istnieje."
                    } else {
                        self.alertMessage = error.localizedDescription
                    }
                    self.showAlert = true
                    #if DEBUG
                    print("[WeeklyWorkEntryViewModel] Zapisywanie nie powiodło się: \(error.localizedDescription)")
                    #endif
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.alertTitle = "Sukces"
                self.alertMessage = response.message.isEmpty ? "Zapisano wersję roboczą" : response.message
                self.showAlert = true
                self.anyDrafts = true
                #if DEBUG
                print("[WeeklyWorkEntryViewModel] Zapis pomyślny: \(response.message)")
                #endif
                // Ponowne załadowanie danych po sukcesie
                self.loadWeekDataFromAPI()
            }
            .store(in: &cancellables)
    }
    
    /// Przygotowuje dane do zatwierdzenia (status: submitted) i wysyła e-mail do przełożonego
    func submitEntries() {
        isLoading = true
        
        // Sprawdź przyszłe daty - odrzuć wpisy z przyszłości
        let futureDates = weekData.filter { entry in
            return entry.isFutureDate && (entry.startTime != nil || entry.endTime != nil)
        }
        
        if !futureDates.isEmpty {
            DispatchQueue.main.async {
                self.alertTitle = "Błąd"
                self.alertMessage = "Nie można zapisać godzin dla przyszłych dni."
                self.showAlert = true
                self.isLoading = false
            }
            return
        }
        
        // Ustaw flagę, aby zapobiec duplikatom
        isConfirmingSubmission = true
        
        // Oznacz wszystkie wpisy jako nie-draft, jeśli nie są z przyszłości
        for i in 0..<weekData.count where !weekData[i].isFutureDate {
            weekData[i].isDraft = false
            weekData[i].status = "submitted"
        }
        
        // Przygotuj wpisy do API
        let apiEntries = prepareEntriesForAPI(asDraft: false)
        
        // Jeśli nie ma wpisów do zatwierdzenia, pokaż błąd
        if apiEntries.isEmpty {
            DispatchQueue.main.async {
                self.alertTitle = "Błąd"
                self.alertMessage = "Brak godzin do wysłania. Wprowadź godziny pracy."
                self.showAlert = true
                self.isLoading = false
                self.isConfirmingSubmission = false
            }
            return
        }
        
        // Walidacja dat - sprawdź, czy end_time jest późniejsze niż start_time
        for entry in apiEntries {
            if let start = entry.start_time, let end = entry.end_time,
               end.compare(start) == .orderedAscending {
                DispatchQueue.main.async {
                    self.alertTitle = "Błąd"
                    self.alertMessage = "Godzina zakończenia nie może być wcześniejsza niż godzina rozpoczęcia."
                    self.showAlert = true
                    self.isLoading = false
                    self.isConfirmingSubmission = false
                }
                return
            }
        }
        
        // Wykonaj zapytanie API - backend wyśle e-mail z potwierdzeniem
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Wysyłanie \(apiEntries.count) wpisów do zatwierdzenia")
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
                    self.alertTitle = "Błąd"
                    if case .serverError(401, _) = error {
                        self.alertMessage = "Wygasła sesja. Zaloguj się ponownie."
                    } else if case .serverError(409, _) = error {
                        self.alertMessage = "Wystąpił konflikt danych. Wpis o tych parametrach już istnieje."
                    } else {
                        self.alertMessage = "Nie udało się wysłać godzin: \(error.localizedDescription)"
                    }
                    self.showAlert = true
                    #if DEBUG
                    print("[WeeklyWorkEntryViewModel] Wysyłanie nie powiodło się: \(error.localizedDescription)")
                    #endif
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.alertTitle = "Sukces"
                var message = response.message.isEmpty ? "Twoje godziny zostały wysłane do zatwierdzenia przełożonemu." : response.message
                if let confirmationSent = response.confirmationSent, confirmationSent {
                    message += "\nE-mail z potwierdzeniem został wysłany do przełożonego."
                    if let token = response.confirmationToken {
                        message += "\nToken: \(token)"
                    }
                } else if let confirmationError = response.confirmationError {
                    message += "\nNie udało się wysłać e-maila z potwierdzeniem: \(confirmationError)"
                }
                self.alertMessage = message
                self.showAlert = true
                self.anyDrafts = false
                #if DEBUG
                print("[WeeklyWorkEntryViewModel] Wysyłanie pomyślne. Wiadomość: \(response.message)")
                print("[WeeklyWorkEntryViewModel] Potwierdzenie wysłane: \(response.confirmationSent ?? false)")
                if let token = response.confirmationToken {
                    print("[WeeklyWorkEntryViewModel] Token potwierdzenia: \(token)")
                }
                #endif
                // Ponowne załadowanie danych po sukcesie
                self.loadWeekDataFromAPI()
            }
            .store(in: &cancellables)
    }
    
    /// Konwertuje bieżące dane EditableWorkEntry na model WorkHourEntry dla API
    private func prepareEntriesForAPI(asDraft: Bool = true) -> [APIService.WorkHourEntry] {
        // Filtruj wpisy bez czasu rozpoczęcia lub zakończenia i przyszłe dni
        let validEntries = weekData.filter { entry in
            return (entry.startTime != nil && entry.endTime != nil) && !entry.isFutureDate
        }
        
        // Mapuj EditableWorkEntry na APIService.WorkHourEntry, używając istniejącego id
        return validEntries.map { entry in
            APIService.WorkHourEntry(
                entry_id: entry.id, // Użyj istniejącego ID
                employee_id: Int(employeeId) ?? 0,
                task_id: Int(taskId) ?? 0,
                work_date: entry.date,
                start_time: entry.startTime,
                end_time: entry.endTime,
                pause_minutes: entry.pauseMinutes,
                status: asDraft ? "pending" : "submitted",
                confirmation_status: "pending", // Dodajemy confirmation_status
                is_draft: asDraft,
                description: entry.notes,
                tasks: nil
            )
        }
    }

    /// Generuje pustą tablicę 7 wpisów, zaczynając od poniedziałku `selectedMonday`
    private func generateEmptyWeekData() -> [EditableWorkEntry] {
        var arr: [EditableWorkEntry] = []
        let cal = Calendar.current
        for offset in 0..<7 {
            if let date = cal.date(byAdding: .day, value: offset, to: selectedMonday) {
                arr.append(.init(date: date))
            }
        }
        
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Wygenerowano \(arr.count) pustych dni dla tygodnia")
        #endif
        
        return arr
    }
    
    // MARK: - Update methods for UI bindings
    
    /// Aktualizuje godzinę rozpoczęcia dla wpisu
    func updateStartTime(at index: Int, to newTime: Date) {
        guard index < weekData.count else { return }
        if !weekData[index].isFutureDate {
            weekData[index].startTime = newTime
        }
    }
    
    /// Aktualizuje godzinę zakończenia dla wpisu
    func updateEndTime(at index: Int, to newTime: Date) {
        guard index < weekData.count else { return }
        if !weekData[index].isFutureDate {
            weekData[index].endTime = newTime
        }
    }
    
    /// Aktualizuje opis/notatki dla wpisu
    func updateDescription(at index: Int, to newDescription: String) {
        guard index < weekData.count else { return }
        if !weekData[index].isFutureDate {
            weekData[index].notes = newDescription
        }
    }
    
    /// Aktualizuje minuty przerwy dla wpisu
    func updatePauseMinutes(at index: Int, to minutes: Int) {
        guard index < weekData.count else { return }
        if !weekData[index].isFutureDate {
            weekData[index].pauseMinutes = minutes
        }
    }
}   
