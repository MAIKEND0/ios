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
    @Published var isLoading   = false
    @Published var showAlert    = false
    @Published var alertTitle   = ""
    @Published var alertMessage = ""

    // MARK: – Parametry inicjalizatora
    private let employeeId: String
    private let taskId: String
    private let selectedMonday: Date

    // MARK: – Subskrypcje Combine
    private var cancellables = Set<AnyCancellable>()

    /// Tworzymy ViewModel z danymi: identyfikator pracownika, zadania oraz tydzień (poniedziałek)
    init(employeeId: String, taskId: String, selectedMonday: Date) {
        self.employeeId     = employeeId
        self.taskId         = taskId
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

        APIService.shared
            .fetchWorkEntries(employeeId: employeeId,
                              weekStartDate: mondayStr,
                              isDraft: true)
            .flatMap { drafts -> AnyPublisher<[EditableWorkEntry], APIError> in
                let draftModels = drafts.map(EditableWorkEntry.init)
                if !draftModels.isEmpty {
                    // Jeśli są drafty, zwracamy je od razu
                    return Just(draftModels)
                        .setFailureType(to: APIError.self)
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
            .catch { _ in
                // W przypadku błędu również generujemy pustą tablicę
                Just(self.generateEmptyWeekData())
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { completion in
                // Obsługa błędu: pokaż alert
                if case let .failure(err) = completion {
                    self.showAlert    = true
                    self.alertTitle   = "Błąd"
                    self.alertMessage = err.localizedDescription
                }
                self.isLoading = false
            } receiveValue: { [weak self] entries in
                // Ostatecznie przypisujemy dane do tablicy
                self?.weekData = entries
            }
            .store(in: &cancellables)
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

    // … Tu możesz dopisać metody do aktualizacji pojedynczych pól (start/end/pauza/opis) …
}
