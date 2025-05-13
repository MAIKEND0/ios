//
//  WorkerDashboardViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import Foundation
import Combine
import SwiftUI

class WorkerDashboardViewModel: ObservableObject {
    @Published var workHoursViewModel = WorkHoursViewModel()
    @Published var announcements: [Announcement] = []
    @Published var isLoadingAnnouncements: Bool = false
    
    // Dodaj zestaw do przechowywania anulowanych subskrypcji
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadData()
    }
    
    func loadData() {
        // Load work hours
        workHoursViewModel.loadWorkHours()
        
        // Load announcements
        loadAnnouncements()
    }
    
    func loadAnnouncements() {
        isLoadingAnnouncements = true
        
        // W prawdziwej implementacji, należy pobierać ogłoszenia z API
        // Na przykład:
        
        // W trybie produkcyjnym, pobierz z API
        #if RELEASE
        fetchAnnouncementsFromAPI()
        #else
        // W trybie debug, użyj przykładowych danych
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.announcements = Announcement.examples
            self.isLoadingAnnouncements = false
        }
        #endif
    }
    
    private func fetchAnnouncementsFromAPI() {
        // Przykładowa implementacja pobierania ogłoszeń z API
        // Tutaj należy użyć właściwego API endpoint
        
        // 1. Utwórz URL i zapytanie
        guard let url = URL(string: "\(Configuration.API.baseURL)/announcements") else {
            self.isLoadingAnnouncements = false
            return
        }
        
        // 2. Utwórz URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 3. Dodaj token autoryzacji jeśli potrzebny
        if let token = APIService.shared.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 4. Wykonaj zapytanie
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [Announcement].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    self.isLoadingAnnouncements = false
                    
                    if case .failure(let error) = completion {
                        print("Error fetching announcements: \(error)")
                        // Użyj przykładowych danych w przypadku błędu
                        self.announcements = Announcement.examples
                    }
                },
                receiveValue: { [weak self] announcements in
                    guard let self = self else { return }
                    self.announcements = announcements
                }
            )
            .store(in: &cancellables)
    }
    
    // Pomocnicza metoda do pobierania ID wybranego zadania
    func getSelectedTaskId() -> String {
        // Tutaj implementacja logiki wyboru aktywnego zadania
        // Na razie zwracamy przykładowe ID
        return "task-123"
    }
    
    // Metoda do pobierania całkowitej liczby godzin w bieżącym tygodniu
    var weeklyHours: Double {
        return workHoursViewModel.workHourEntries.reduce(0) { sum, entry in
            return sum + entry.totalHours
        }
    }
    
    // Metoda do pobierania liczby aktywnych projektów
    var activeProjectsCount: Int {
        // W prawdziwej implementacji, pobierz liczbę z API
        return 2 // Przykładowa wartość
    }
}
