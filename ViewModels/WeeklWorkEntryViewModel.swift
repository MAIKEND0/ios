//
//  WeeklyWorkEntryViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import Foundation
import Combine

class WeeklyWorkEntryViewModel: ObservableObject {
    @Published var weekData: [WorkHourEntry] = []
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var alertTitle: String = ""
    @Published var isReviewShowing: Bool = false
    @Published var copiedEntry: WorkHourEntry?
    
    private var employeeId: String
    private var taskId: String
    private var selectedMonday: Date
    
    // Tablica do przechowywania subskrypcji Combine
    private var cancellables = Set<AnyCancellable>()
    
    init(employeeId: String, taskId: String, selectedMonday: Date) {
        self.employeeId = employeeId
        self.taskId = taskId
        self.selectedMonday = selectedMonday
        
        // Wczytaj dane na początku - możesz wybrać między lokalnym generowaniem a API
        // loadWeekData() // Lokalne generowanie
        loadWeekDataFromAPI() // Pobieranie z API
    }
    
    var totalWeeklyHours: Double {
        weekData.reduce(0) { $0 + $1.totalHours }
    }
    
    var hasInvalidTime: Bool {
        weekData.contains { entry in
            guard let start = entry.startTime, let end = entry.endTime else { return false }
            return end < start
        }
    }
    
    var isFutureWeek: Bool {
        let calendar = Calendar.current
        let currentMonday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return selectedMonday > currentMonday
    }
    
    func isFutureDay(_ date: Date) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return date > today
    }
    
    // Oryginalna metoda do lokalnego generowania danych
    func loadWeekData() {
        isLoading = true
        
        // Generujemy 7 dni zaczynając od poniedziałku
        var dayEntries = [WorkHourEntry]()
        let calendar = Calendar.current
        
        for dayOffset in 0..<7 {
            guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: selectedMonday) else { continue }
            
            // Tworzymy pusty wpis dla każdego dnia
            let entry = WorkHourEntry(
                id: UUID().uuidString,
                date: currentDate,
                startTime: nil,
                endTime: nil,
                projectId: taskId,
                description: nil,
                employeeId: employeeId,
                pauseMinutes: 0,
                status: .pending,
                isDraft: true
            )
            dayEntries.append(entry)
        }
        
        self.weekData = dayEntries
        
        // Symulacja opóźnienia pobierania danych
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    // Nowa metoda do ładowania danych z API
    func loadWeekDataFromAPI() {
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let mondayString = dateFormatter.string(from: selectedMonday)
        
        // Pobierz drafty
        APIService.shared.fetchDraftWorkEntries(employeeId: employeeId, weekStartDate: mondayString)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Error fetching drafts: \(error)")
                    self.showAlert = true
                    self.alertTitle = "Błąd"
                    self.alertMessage = "Nie udało się pobrać zapisanych wersji roboczych. \(error.localizedDescription)"
                    self.isLoading = false
                }
            } receiveValue: { [weak self] entries in
                guard let self = self else { return }
                
                // Jeśli są drafty, użyj ich
                if !entries.isEmpty {
                    self.weekData = entries
                    self.isLoading = false
                } else {
                    // Jeśli nie ma draftów, sprawdź czy są zatwierdzone wpisy
                    self.loadSubmittedEntries(mondayString)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadSubmittedEntries(_ mondayString: String) {
        APIService.shared.fetchWorkEntries(employeeId: employeeId, weekStartDate: mondayString)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    self.isLoading = false
                case .failure(let error):
                    print("Error fetching work entries: \(error)")
                    
                    // Jeśli nie udało się pobrać zatwierdzonych wpisów, generujemy puste
                    self.generateEmptyWeekData()
                    self.isLoading = false
                }
            } receiveValue: { [weak self] entries in
                guard let self = self else { return }
                
                if !entries.isEmpty {
                    self.weekData = entries
                } else {
                    // Jeśli nie ma wpisów, generujemy puste
                    self.generateEmptyWeekData()
                }
                
                self.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    private func generateEmptyWeekData() {
        // Ta metoda została przeniesiona z loadWeekData
        var dayEntries = [WorkHourEntry]()
        let calendar = Calendar.current
        
        for dayOffset in 0..<7 {
            guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: selectedMonday) else { continue }
            
            let entry = WorkHourEntry(
                id: UUID().uuidString,
                date: currentDate,
                startTime: nil,
                endTime: nil,
                projectId: taskId,
                description: nil,
                employeeId: employeeId,
                pauseMinutes: 0,
                status: .pending,
                isDraft: true
            )
            dayEntries.append(entry)
        }
        
        self.weekData = dayEntries
    }
    
    func updateEntry(at index: Int, field: String, value: Any) {
        guard index < weekData.count else { return }
        
        var entry = weekData[index]
        
        switch field {
        case "startTime":
            if let time = value as? Date {
                // Sprawdzamy czy czas zakończenia jest późniejszy
                if let endTime = entry.endTime, endTime < time {
                    showAlert = true
                    alertTitle = "Błąd"
                    alertMessage = "Czas rozpoczęcia nie może być późniejszy niż czas zakończenia"
                    return
                }
                entry.startTime = time
            }
        case "endTime":
            if let time = value as? Date {
                // Sprawdzamy czy czas rozpoczęcia jest wcześniejszy
                if let startTime = entry.startTime, time < startTime {
                    showAlert = true
                    alertTitle = "Błąd"
                    alertMessage = "Czas zakończenia nie może być wcześniejszy niż czas rozpoczęcia"
                    return
                }
                entry.endTime = time
            }
        case "pauseMinutes":
            if let minutes = value as? Int {
                entry.pauseMinutes = minutes
            }
        case "description":
            if let desc = value as? String {
                entry.description = desc
            }
        default:
            break
        }
        
        weekData[index] = entry
    }
    
    func copyEntry(at index: Int) {
        copiedEntry = weekData[index]
        
        showAlert = true
        alertTitle = "Kopiowano"
        alertMessage = "Skopiowano dane z \(formatDate(weekData[index].date))"
    }
    
    func pasteEntry(to index: Int) {
        guard let source = copiedEntry else {
            showAlert = true
            alertTitle = "Błąd"
            alertMessage = "Brak skopiowanych danych"
            return
        }
        
        var target = weekData[index]
        target.startTime = source.startTime
        target.endTime = source.endTime
        target.pauseMinutes = source.pauseMinutes
        target.description = source.description
        
        weekData[index] = target
        
        showAlert = true
        alertTitle = "Wklejono"
        alertMessage = "Wklejono dane do \(formatDate(target.date))"
    }
    
    // Zaktualizowana metoda saveDraft z integracją API
    func saveDraft() {
        // Filtrujemy tylko dni z wprowadzonymi godzinami
        let draftsToSave = weekData.filter { entry in
            return entry.startTime != nil || entry.endTime != nil || !entry.description.isNilOrEmpty
        }
        
        // Jeśli nie ma co zapisać, informujemy o tym
        if draftsToSave.isEmpty {
            showAlert = true
            alertTitle = "Informacja"
            alertMessage = "Brak danych do zapisania"
            return
        }
        
        // Oznaczamy wpisy jako draft
        let draftsWithFlag = draftsToSave.map { entry -> WorkHourEntry in
            var draft = entry
            draft.isDraft = true
            return draft
        }
        
        // Wysyłamy do API
        APIService.shared.saveDraftWorkEntries(draftsWithFlag)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.showAlert = true
                    self.alertTitle = "Błąd"
                    self.alertMessage = "Nie udało się zapisać wersji roboczej. \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] success in
                guard let self = self else { return }
                
                if success {
                    self.showAlert = true
                    self.alertTitle = "Sukces"
                    self.alertMessage = "Zapisano wersję roboczą"
                }
            }
            .store(in: &cancellables)
    }
    
    // Zaktualizowana metoda submitEntries z integracją API
    func submitEntries() {
        // Podobnie jak w saveDraft, ale z isDraft = false
        let entriesToSubmit = weekData.filter { entry in
            return entry.startTime != nil && entry.endTime != nil
        }
        
        if entriesToSubmit.isEmpty {
            showAlert = true
            alertTitle = "Informacja"
            alertMessage = "Brak kompletnych wpisów do przesłania"
            return
        }
        
        // Oznaczamy wpisy jako nie-draft
        let submittedEntries = entriesToSubmit.map { entry -> WorkHourEntry in
            var submission = entry
            submission.isDraft = false
            submission.status = .submitted
            return submission
        }
        
        // Wysyłamy do API
        APIService.shared.submitWorkEntries(submittedEntries)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.showAlert = true
                    self.alertTitle = "Błąd"
                    self.alertMessage = "Nie udało się przesłać wpisów. \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] success in
                guard let self = self else { return }
                
                if success {
                    self.showAlert = true
                    self.alertTitle = "Sukces"
                    self.alertMessage = "Wpisy zostały przesłane"
                    self.isReviewShowing = false
                }
            }
            .store(in: &cancellables)
    }
    
    // Helper funkcja do formatowania daty
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Helper funkcja do formatowania czasu
    func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
