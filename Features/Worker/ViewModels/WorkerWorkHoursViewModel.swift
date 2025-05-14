//
//  WorkerWorkHoursViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 14/05/2025.
//

import Foundation
import Combine

final class WorkerWorkHoursViewModel: ObservableObject {
    @Published var entries: [APIService.WorkHourEntry] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var weekStart: Date = {
        let now = Date()
        let cal = Calendar.current
        return cal.date(
            from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        )!
    }()

    private var cancellables = Set<AnyCancellable>()

    func loadEntries(isDraft: Bool = false) {
        guard let empId = AuthService.shared.getEmployeeId() else {
            error = "Brak zalogowanego pracownika"
            entries = []
            return
        }

        let weekStartStr = DateFormatter.isoDate.string(from: weekStart)
        isLoading = true
        error = nil

        APIService.shared
            .fetchWorkEntries(
                employeeId: empId,
                weekStartDate: weekStartStr,
                isDraft: isDraft
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.error = err.localizedDescription
                    self?.entries = []
                }
            } receiveValue: { [weak self] fetched in
                self?.entries = fetched
            }
            .store(in: &cancellables)
    }

    func previousWeek() {
        weekStart = Calendar.current.date(
            byAdding: .weekOfYear, value: -1, to: weekStart
        )!
        loadEntries()
    }

    func nextWeek() {
        weekStart = Calendar.current.date(
            byAdding: .weekOfYear, value: 1, to: weekStart
        )!
        loadEntries()
    }
}
