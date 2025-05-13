//
//  WorkHoursView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI

struct WorkHoursView: View {
    @StateObject private var viewModel = WorkHoursViewModel()
    // Możesz przekazać employeeId i initialDate z poprzedniego widoku,
    // jeśli ten widok ma być bardziej generyczny.
    // Na razie pobierzemy je tutaj.
    
    // Zmienna określająca, czy dane zostały już załadowane po raz pierwszy
    @State private var initialDataLoaded = false

    var body: some View {
        // Usunięto NavigationView, ponieważ WorkHoursView jest prawdopodobnie
        // prezentowany wewnątrz NavigationView z WorkerDashboardView.
        // Jeśli ma to być niezależny widok z własną nawigacją, przywróć NavigationView.
        VStack {
            if viewModel.isLoading && !initialDataLoaded { // Pokaż ProgressView tylko przy pierwszym ładowaniu
                ProgressView("Ładowanie godzin pracy...")
                    .padding()
            } else if viewModel.workHourEntries.isEmpty {
                Text("Nie znaleziono godzin pracy.")
                    .foregroundColor(Color.ksrMediumGray) // Upewnij się, że ten kolor jest zdefiniowany
                    .padding()
            } else {
                List {
                    ForEach(viewModel.workHourEntries.sorted(by: { $0.date > $1.date })) { entry in // Sortowanie dla lepszej prezentacji
                        workHourCard(entry: entry)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)) // Usuń domyślne paddingi listy, jeśli karta ma własne
                            .listRowBackground(Color.clear) // Dla niestandardowego tła karty
                    }
                }
                .listStyle(PlainListStyle()) // PlainListStyle często wygląda lepiej dla niestandardowych komórek
            }
        }
        .navigationTitle("Godziny Pracy") // Tytuł dla paska nawigacyjnego
        .navigationBarTitleDisplayMode(.inline) // Mniejszy tytuł
        .onAppear {
            // Ładuj dane tylko raz przy pierwszym pojawieniu się widoku,
            // lub jeśli chcesz odświeżać za każdym razem, usuń warunek initialDataLoaded.
            if !initialDataLoaded {
                loadInitialData()
                initialDataLoaded = true
            }
        }
        // Możesz dodać przycisk odświeżania, jeśli potrzebujesz
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isLoading && initialDataLoaded { // Pokaż wskaźnik aktywności w pasku, jeśli ładuje w tle
                    ProgressView()
                } else {
                    Button(action: {
                        loadInitialData() // Akcja odświeżania
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
    
    private func loadInitialData() {
        guard let employeeId = AuthService.shared.getEmployeeId() else {
            print("WorkHoursView: Brak employeeId, nie można załadować danych.")
            viewModel.errorMessage = "Nie jesteś zalogowany." // Ustaw komunikat błędu
            viewModel.workHourEntries = [] // Wyczyść listę
            return
        }
        // Domyślnie ładujemy dane dla bieżącego tygodnia
        let currentMonday = getMondayOfCurrentWeek()
        viewModel.loadWorkHours(for: employeeId, weekStarting: currentMonday)
    }

    // Funkcja pomocnicza do pobierania poniedziałku bieżącego tygodnia
    // Powinna być w bardziej globalnym miejscu (np. Utils), jeśli używana w wielu miejscach.
    private func getMondayOfCurrentWeek() -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Ustawienie poniedziałku jako pierwszego dnia tygodnia (ISO 8601)
        let today = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        return calendar.date(from: components) ?? today
    }
    
    // Ta funkcja jest bardzo podobna do tej w WorkerDashboardView.
    // Rozważ stworzenie reużywalnego komponentu SwiftUI (osobnego View).
    @ViewBuilder
    func workHourCard(entry: WorkHourEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatDate(entry.date))
                    .font(.headline)
                    .foregroundColor(Color.ksrDarkGray) // Upewnij się, że ten kolor jest zdefiniowany
                
                Spacer()
                
                Text(entry.formattedTotalHours) // Upewnij się, że WorkHourEntry ma tę właściwość
                    .font(.headline) // Można użyć .title3 lub .headline w zależności od preferencji
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrYellow) // Upewnij się, że ten kolor jest zdefiniowany
            }
            
            HStack {
                Text("\(formatTime(entry.startTime)) - \(formatTime(entry.endTime))")
                    .font(.subheadline)
                    .foregroundColor(Color.ksrMediumGray)
                
                Spacer()
                
                // Zamiast Project ID, można pokazać status lub typ zadania
                if entry.isDraft {
                    Text("Wersja robocza")
                        .font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                } else {
                     Text(entry.status.rawValue.capitalized)
                        .font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(statusColor(entry.status).opacity(0.2))
                        .foregroundColor(statusColor(entry.status))
                        .cornerRadius(4)
                }
            }
            
            if let description = entry.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(Color.ksrDarkGray.opacity(0.8)) // Lekko przyciemniony dla lepszej czytelności
                    .lineLimit(3) // Pozwól na więcej linii opisu
                    .padding(.top, 4)
            }
             // Możesz dodać więcej informacji, np. projectId, jeśli potrzebne
            Text("Projekt: \(entry.projectId)")
                .font(.caption)
                .foregroundColor(Color.gray)
                .padding(.top, 2)

        }
        .padding()
        // Użyj kolorów systemowych dla tła, aby wspierać tryb ciemny/jasny
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal) // Dodaj padding horyzontalny do całej karty w liście
    }
    
    // Helper functions (identyczne jak w WorkerDashboardView - przenieś do Utils)
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // Kolor dla statusu (przenieś do Utils lub rozszerzenia EntryStatus)
    func statusColor(_ status: EntryStatus) -> Color {
        switch status {
        case .draft: return .orange
        case .pending: return .blue
        case .submitted: return .purple
        case .confirmed: return .green
        case .rejected: return .red
        }
    }
}

struct WorkHoursView_Previews: PreviewProvider {
    static var previews: some View {
        // Aby podgląd działał poprawnie, WorkHoursViewModel musi mieć dane.
        let mockViewModel = WorkHoursViewModel()
        // Możesz ręcznie załadować przykładowe dane do mockViewModel, jeśli jest taka potrzeba
        // mockViewModel.loadWorkHours(for: "test-emp-id", weekStarting: Date())
        
        // Jeśli WorkHoursView ma być w NavigationView
        NavigationView {
            WorkHoursView(viewModel: mockViewModel)
        }
    }
}

// Upewnij się, że masz zdefiniowane kolory (np. w Color+Extensions.swift)
// extension Color {
//     static let ksrMediumGray = Color(UIColor.systemGray2)
//     static let ksrDarkGray = Color(UIColor.label)
//     static let ksrYellow = Color.systemYellow
//     static let ksrLightGray = Color(UIColor.systemGray6) // Przykład dla tła karty
// }
