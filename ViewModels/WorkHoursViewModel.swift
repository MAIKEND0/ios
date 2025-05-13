import Foundation
import Combine
import SwiftUI

class WorkHoursViewModel: ObservableObject {
    @Published var workHourEntries: [WorkHourEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Dodaj zestaw do przechowywania anulowanych subskrypcji
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Inicjalizacja
    }
    
    func loadWorkHours() {
        isLoading = true
        
        // Zamiast próbować użyć 'duration', użyj właściwości 'totalHours', która istnieje
        
        // Tworzymy przykładowe wpisy
        let calendar = Calendar.current
        let today = Date()
        
        let entry1 = WorkHourEntry.example
        
        var entry2 = WorkHourEntry.example
        entry2.id = "2"
        entry2.date = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        entry2.startTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: entry2.date)
        entry2.endTime = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: entry2.date)
        entry2.description = "Crane inspection"
        
        workHourEntries = [entry1, entry2]
        isLoading = false
    }
    
    // Dodana nowa metoda do ładowania godzin pracy z API
    func loadWorkHours(for employeeId: String, weekStarting: Date) {
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let mondayString = dateFormatter.string(from: weekStarting)
        
        // Najpierw próbujemy pobrać już zatwierdzone wpisy
        APIService.shared.fetchWorkEntries(employeeId: employeeId, weekStartDate: mondayString)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Error fetching work entries: \(error)")
                    // Wciąż ustawiamy isLoading na false w przypadku błędu
                    self.isLoading = false
                    self.errorMessage = "Błąd pobierania danych: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] entries in
                guard let self = self else { return }
                self.workHourEntries = entries
                self.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    // Metoda do pobierania całkowitej liczby godzin w bieżącym tygodniu
    var totalWeeklyHours: Double {
        let currentWeekStart = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let currentWeekEntries = workHourEntries.filter { entry in
            let entryWeek = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date)
            return entryWeek.yearForWeekOfYear == currentWeekStart.yearForWeekOfYear &&
                   entryWeek.weekOfYear == currentWeekStart.weekOfYear
        }
        
        return currentWeekEntries.reduce(0) { sum, entry in
            return sum + entry.totalHours
        }
    }
    
    // Metoda do wyszukiwania wpisów według daty
    func entries(for date: Date) -> [WorkHourEntry] {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
        
        return workHourEntries.filter { entry in
            return entry.date >= dayStart && entry.date < dayEnd
        }
    }
}
