// WeeklyWorkEntryForm.swift
// KSR Cranes App
//
// Formularz do edycji wpisów godzin pracy w ramach jednego tygodnia.

import SwiftUI

struct WeeklyWorkEntryForm: View {
    @StateObject private var vm: WeeklyWorkEntryViewModel
    @Environment(\.dismiss) private var dismiss

    /// Inicjalizator przyjmujący ID pracownika, ID zadania i datę poniedziałku tygodnia
    init(
        employeeId: String,
        taskId: String,
        selectedMonday: Date
    ) {
        _vm = StateObject(
            wrappedValue: WeeklyWorkEntryViewModel(
                employeeId: employeeId,
                taskId: taskId,
                selectedMonday: selectedMonday
            )
        )
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(vm.weekData.enumerated()), id: \.element.date) { index, entry in
                    Section(header: Text(DateFormatter.dayHeader.string(from: entry.date))) {
                        // Picker godzin rozpoczęcia
                        DatePicker(
                            "Początek",
                            selection: Binding(
                                get: { entry.startTime ?? entry.date },
                                set: { vm.updateStartTime(at: index, to: $0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )

                        // Picker godzin zakończenia
                        DatePicker(
                            "Koniec",
                            selection: Binding(
                                get: { entry.endTime ?? entry.date },
                                set: { vm.updateEndTime(at: index, to: $0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )

                        // Pole na opis
                        TextField(
                            "Opis (opcjonalnie)",
                            text: Binding(
                                get: { entry.description ?? "" },
                                set: { vm.updateDescription(at: index, to: $0) }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .navigationTitle("Tydzień od \(DateFormatter.weekHeader.string(from: vm.selectedMonday))")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") {
                        vm.saveDraft()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }
            }
            .alert(vm.alertTitle, isPresented: $vm.showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.alertMessage)
            }
            .overlay {
                if vm.isLoading {
                    ZStack {
                        Color(.systemBackground)
                            .opacity(0.5)
                            .ignoresSafeArea()
                        ProgressView("Ładowanie…")
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                    }
                }
            }
        }
    }
}

private extension DateFormatter {
    /// Nagłówek dla pojedynczego dnia
    static let dayHeader: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEEE, dd.MM.yyyy"
        return df
    }()
    
    /// Nagłówek tygodnia (już masz w innym miejscu, tu tylko dla pewności)
    static let weekHeader: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "'Tydz.' W (dd.MM.yyyy)"
        return df
    }()
}

struct WeeklyWorkEntryForm_Previews: PreviewProvider {
    static var previews: some View {
        // Poniedziałek bieżącego tygodnia:
        let monday = Calendar.current.date(
            from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        )!
        WeeklyWorkEntryForm(
            employeeId: "123",
            taskId: "456",
            selectedMonday: monday
        )
    }
}
