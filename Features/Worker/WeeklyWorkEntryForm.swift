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
                    Section {
                        dayEntryView(for: entry, at: index)
                    } header: {
                        Text(formatDate(entry.date))
                    }
                }
            }
            .navigationTitle("Tydzień od \(formatWeek(vm.selectedMonday))")
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
                    loadingOverlay
                }
            }
            #if DEBUG
            .withAuthDebugging() // Dodaj przycisk debugowania w DEBUG
            #endif
        }
    }
    
    // MARK: - Helper Views
    
    private func dayEntryView(for entry: EditableWorkEntry, at index: Int) -> some View {
        VStack(spacing: 12) {
            startTimePicker(for: entry, at: index)
            endTimePicker(for: entry, at: index)
            notesField(for: entry, at: index)
        }
    }
    
    private func startTimePicker(for entry: EditableWorkEntry, at index: Int) -> some View {
        DatePicker(
            "Początek",
            selection: startTimeBinding(for: index, defaultDate: entry.date),
            displayedComponents: .hourAndMinute
        )
    }
    
    private func endTimePicker(for entry: EditableWorkEntry, at index: Int) -> some View {
        DatePicker(
            "Koniec",
            selection: endTimeBinding(for: index, defaultDate: entry.date),
            displayedComponents: .hourAndMinute
        )
    }
    
    private func notesField(for entry: EditableWorkEntry, at index: Int) -> some View {
        TextField(
            "Opis (opcjonalnie)",
            text: notesBinding(for: index)
        )
        .textFieldStyle(.roundedBorder)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.5)
                .ignoresSafeArea()
            
            ProgressView("Ładowanie…")
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                )
        }
    }
    
    // MARK: - Bindings
    
    private func startTimeBinding(for index: Int, defaultDate: Date) -> Binding<Date> {
        Binding(
            get: {
                guard index < vm.weekData.count else { return defaultDate }
                return vm.weekData[index].startTime ?? defaultDate
            },
            set: { vm.updateStartTime(at: index, to: $0) }
        )
    }
    
    private func endTimeBinding(for index: Int, defaultDate: Date) -> Binding<Date> {
        Binding(
            get: {
                guard index < vm.weekData.count else { return defaultDate }
                return vm.weekData[index].endTime ?? defaultDate
            },
            set: { vm.updateEndTime(at: index, to: $0) }
        )
    }
    
    private func notesBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < vm.weekData.count else { return "" }
                return vm.weekData[index].notes
            },
            set: { vm.updateDescription(at: index, to: $0) }
        )
    }
    
    // MARK: - Formatting
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    private func formatWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "'Tydz.' W (dd.MM.yyyy)"
        return formatter.string(from: date)
    }
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
