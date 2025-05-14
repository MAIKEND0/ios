//
//  WeeklyWorkEntryViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import Foundation
import Combine

/// ViewModel do obsługi tygodniowych wpisów godzin pracy.
/// Ładuje najpierw wersje robocze, a jeśli ich brak – wpisy zatwierdzone.
/// W razie błędu generuje pusty zestaw 7 dni od poniedziałku.
final class WeeklyWorkEntryViewModel: ObservableObject {
    // MARK: – Publikowane właściwości
    @Published var weekData: [EditableWorkEntry] = []
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

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

        // Automatycznie ładujemy dane z API
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
            .fetchWorkEntries(employeeId: employeeId,
                              weekStartDate: mondayStr,
                              isDraft: true)
            .flatMap { drafts -> AnyPublisher<[EditableWorkEntry], APIService.APIError> in
                let draftModels = drafts.map(EditableWorkEntry.init)
                if !draftModels.isEmpty {
                    // Jeśli są drafty, zwracamy je od razu
                    return Just(draftModels)
                        .setFailureType(to: APIService.APIError.self)
                        .eraseToAnyPublisher()
                } else {
                    // W przeciwnym razie pobieramy wpisy zatwierdzone
                    return APIService.shared
                        .fetchWorkEntries(employeeId: self.employeeId,
                                          weekStartDate: mondayStr,
                                          isDraft: false)
                        .map { $0.map(EditableWorkEntry.init) }
                        .eraseToAnyPublisher()
                }
            }
            .map { entries in
                // Jeśli wynik nadal pusty, generujemy pustą tablicę 7 dni
                entries.isEmpty
                    ? self.generateEmptyWeekData()
                    : entries
            }
            .catch { error -> AnyPublisher<[EditableWorkEntry], Never> in
                // Obsługa błędu bezpośrednio tutaj
                #if DEBUG
                print("[WeeklyWorkEntryViewModel] Error: \(error.localizedDescription)")
                #endif
                
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertTitle = "Błąd"
                    self.alertMessage = error.localizedDescription
                }
                // Zwracamy puste dane tygodnia
                return Just(self.generateEmptyWeekData())
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                // Ostatecznie przypisujemy dane do tablicy
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
        
        // Przekształć EditableWorkEntry na model API
        let apiEntries = prepareEntriesForAPI()
        
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
        
        // Wykonaj zapytanie API z rozszerzonymi logami debugowania
        #if DEBUG
        print("[WeeklyWorkEntryViewModel] Wysyłanie \(apiEntries.count) wpisów do API")
        #endif
        
        APIService.shared.upsertWorkEntries(apiEntries)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                switch completion {
                case .finished:
                    self.alertTitle = "Sukces"
                    self.alertMessage = "Zapisano wersję roboczą"
                    self.showAlert = true
                    
                case .failure(let error):
                    // Obsłuż błędy API
                    self.alertTitle = "Błąd"
                    
                    // Specjalna obsługa błędów 401
                    if case .serverError(401, _) = error {
                        self.alertMessage = "Wygasła sesja. Zaloguj się ponownie."
                    } else {
                        self.alertMessage = error.localizedDescription
                    }
                    
                    self.showAlert = true
                    
                    #if DEBUG
                    print("[WeeklyWorkEntryViewModel] Zapisywanie nie powiodło się: \(error.localizedDescription)")
                    #endif
                }
            } receiveValue: { _ in
                #if DEBUG
                print("[WeeklyWorkEntryViewModel] Zapis pomyślny")
                #endif
            }
            .store(in: &cancellables)
    }
    
    /// Konwertuje bieżące dane EditableWorkEntry na model WorkHourEntry dla API
    private func prepareEntriesForAPI() -> [APIService.WorkHourEntry] {
        // Filtruj wpisy bez czasu rozpoczęcia lub zakończenia
        let validEntries = weekData.filter { entry in
            return entry.startTime != nil && entry.endTime != nil
        }
        
        // Mapuj EditableWorkEntry na APIService.WorkHourEntry
        return validEntries.compactMap { entry in
            // Konwertuj na model API
            // UWAGA: Możesz potrzebować dostosować te pola do modelu API
            return APIService.WorkHourEntry(
                // Nie przekazuj argumentu id, ponieważ jest generowany automatycznie w inicjalizatorze
                entry_id: entry.id,
                employee_id: Int(employeeId) ?? 0,
                task_id: Int(taskId) ?? 0,
                work_date: entry.date,
                start_time: entry.startTime,
                end_time: entry.endTime,
                pause_minutes: entry.pauseMinutes,
                status: "pending",
                is_draft: true,
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
        return arr
    }
    
    // MARK: - Update methods for UI bindings
    
    /// Aktualizuje godzinę rozpoczęcia dla wpisu
    func updateStartTime(at index: Int, to newTime: Date) {
        guard index < weekData.count else { return }
        weekData[index].startTime = newTime
    }
    
    /// Aktualizuje godzinę zakończenia dla wpisu
    func updateEndTime(at index: Int, to newTime: Date) {
        guard index < weekData.count else { return }
        weekData[index].endTime = newTime
    }
    
    /// Aktualizuje opis/notatki dla wpisu
    func updateDescription(at index: Int, to newDescription: String) {
        guard index < weekData.count else { return }
        weekData[index].notes = newDescription
    }
}
