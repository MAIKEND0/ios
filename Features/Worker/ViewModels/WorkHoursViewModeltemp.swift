//
//  WorkHoursViewModel.swift
//  KSR Cranes App
//
//  Logika dla ekrenu WorkHoursView

import Foundation
import Combine

final class WorkHoursViewModel: ObservableObject {
    // Teraz używamy tego samego modelu, który zwraca APIService
    @Published var workHourEntries: [APIService.WorkHourEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    /// Ładuje godziny pracy dla danego pracownika i tygodnia (poniedziałek = weekStarting)
    func loadWorkHours(for employeeId: String, weekStarting: Date) {
        let mondayStr = DateFormatter.isoDate.string(from: weekStarting)
        isLoading = true
        errorMessage = nil

        APIService.shared
            .fetchWorkEntries(
                employeeId: employeeId,
                weekStartDate: mondayStr
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case let .failure(err) = completion {
                    self.errorMessage = err.localizedDescription
                    self.workHourEntries = []
                }
            } receiveValue: { [weak self] entries in
                // entries ma teraz typ [APIService.WorkHourEntry], więc to przejdzie
                self?.workHourEntries = entries
            }
            .store(in: &cancellables)
    }
}
