import SwiftUI

struct WeeklyWorkEntryForm: View {
    @StateObject private var vm: WeeklyWorkEntryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDayIndex: Int = 0
    @State private var showingCalendarView = false
    
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
            VStack(spacing: 0) {
                // Nagłówek tygodnia z możliwością wyboru dnia
                weekHeader
                
                // Główna zawartość
                ScrollView {
                    VStack(spacing: 24) {
                        // Navigation hint for days
                        Text("Tap on a day above to edit entries for that day")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                        
                        // Future date warning if applicable
                        if selectedDayIndex < vm.weekData.count && vm.weekData[selectedDayIndex].isFutureDate {
                            futureDateWarning
                        }
                        
                        // Sekcja wybranego dnia
                        if selectedDayIndex < vm.weekData.count {
                            dayEntrySection(for: vm.weekData[selectedDayIndex], at: selectedDayIndex)
                        }
                        
                        // Podsumowanie tygodnia
                        weekSummarySection
                    }
                    .padding()
                }
                
                // Przyciski akcji na dole
                bottomActionBar
            }
            .navigationTitle("Log Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.saveDraft()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCalendarView.toggle()
                    }) {
                        Image(systemName: "calendar")
                            .foregroundColor(Color.ksrYellow)
                    }
                }
            }
            .alert(isPresented: $vm.showAlert) {
                Alert(
                    title: Text(vm.alertTitle),
                    message: Text(vm.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
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
    
    // MARK: - Future Date Warning
    
    private var futureDateWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Future Date")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            Text("You cannot log hours for future dates. Please select a current or past date.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Week Header
    
    private var weekHeader: some View {
        VStack(spacing: 0) {
            // Tydzień
            HStack {
                Text("Week \(getWeekNumber()) of \(formatWeek(vm.selectedMonday))")
                    .font(Font.headline)
                    .padding()
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            
            // Dni tygodnia - pills - teraz rozciągnięte na całą szerokość
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(0..<vm.weekData.count, id: \.self) { index in
                        let entry = vm.weekData[index]
                        dayPill(for: entry, index: index, isSelected: selectedDayIndex == index)
                            .frame(width: geometry.size.width / 7) // Równa szerokość dla każdego dnia
                            .onTapGesture {
                                withAnimation {
                                    selectedDayIndex = index
                                }
                            }
                    }
                }
                .frame(height: 70) // Stała wysokość dla przycisków dni
            }
            .frame(height: 70)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.systemGray5)),
                alignment: .bottom
            )
        }
    }
    
    // Pobierz numer tygodnia z daty
    private func getWeekNumber() -> Int {
        let calendar = Calendar.current
        return calendar.component(.weekOfYear, from: vm.selectedMonday)
    }
    
    private func dayPill(for entry: EditableWorkEntry, index: Int, isSelected: Bool) -> some View {
        let dayName = formatDayName(entry.date)
        let dayNumber = formatDayNumber(entry.date)
        let isToday = Calendar.current.isDateInToday(entry.date)
        let isFuture = entry.isFutureDate
        
        return VStack(spacing: 2) {
            Text(dayName)
                .font(Font.caption2)
                .fontWeight(.medium)
            Text(dayNumber)
                .font(Font.headline)
                .fontWeight(.bold)
            
            // Small indicator for future dates
            if isFuture {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(isSelected ? .white : .orange)
            }
        }
        .foregroundColor(isSelected ? Color.white : isToday ? Color.ksrYellow : isFuture ? Color.orange : Color.primary)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity) // Fill available width
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    isSelected ?
                    (isFuture ? Color.orange : Color.ksrYellow) :
                    isToday ? Color.ksrYellow.opacity(0.15) :
                    isFuture ? Color.orange.opacity(0.1) : Color(.systemGray6)
                )
                .padding(.horizontal, 4) // Add padding to the background for spacing
        )
    }
    
    // MARK: - Day Entry Section
    
    private func dayEntrySection(for entry: EditableWorkEntry, at index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Nagłówek dnia
            Text(formatDate(entry.date))
                .font(Font.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.ksrDarkGray)
            
            // Status roboczy/złożony
            HStack {
                Text(entry.isDraft ? "Draft" : "Status: \(entry.status.capitalized)")
                    .font(Font.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(entry.isDraft ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(entry.isDraft ? Color.orange : Color.blue)
                    .cornerRadius(8)
                
                Spacer()
                
                // Czas trwania (jeśli godziny są ustawione)
                if entry.startTime != nil && entry.endTime != nil {
                    Text("\(entry.totalHours, specifier: "%.2f") hrs")
                        .font(Font.headline)
                        .foregroundColor(Color.ksrYellow)
                }
            }
            
            // Formularz czasów - tylko dla dni nieprzyszłych
            if !entry.isFutureDate {
                timeEntryForm(for: entry, at: index)
            } else {
                // Information text for future dates
                Text("Time entries cannot be recorded for future dates")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private func timeEntryForm(for entry: EditableWorkEntry, at index: Int) -> some View {
        VStack(spacing: 16) {
            // Początek
            VStack(alignment: .leading, spacing: 8) {
                Text("Start Time")
                    .font(Font.subheadline)
                    .foregroundColor(Color.ksrMediumGray)
                
                // Kompaktowy selektor czasu
                DatePicker(
                    "Start Time",
                    selection: startTimeBinding(for: index, defaultDate: entry.date),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(CompactDatePickerStyle()) // Kompaktowy styl
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Koniec
            VStack(alignment: .leading, spacing: 8) {
                Text("End Time")
                    .font(Font.subheadline)
                    .foregroundColor(Color.ksrMediumGray)
                
                // Kompaktowy selektor czasu
                DatePicker(
                    "End Time",
                    selection: endTimeBinding(for: index, defaultDate: entry.date),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(CompactDatePickerStyle()) // Kompaktowy styl
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Przerwa
            VStack(alignment: .leading, spacing: 8) {
                Text("Break (minutes)")
                    .font(Font.subheadline)
                    .foregroundColor(Color.ksrMediumGray)
                
                HStack {
                    Slider(value: pauseMinutesBinding(for: index), in: 0...120, step: 5)
                        .accentColor(Color.ksrYellow)
                    
                    Text("\(Int(entry.pauseMinutes))")
                        .font(Font.headline)
                        .frame(width: 50)
                        .foregroundColor(Color.ksrDarkGray)
                }
            }
            
            // Notatki
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (optional)")
                    .font(Font.subheadline)
                    .foregroundColor(Color.ksrMediumGray)
                
                TextEditor(text: notesBinding(for: index))
                    .frame(height: 100)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - Week Summary Section
    
    private var weekSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Week Summary")
                .font(Font.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.ksrDarkGray)
            
            VStack(spacing: 0) {
                ForEach(0..<vm.weekData.count, id: \.self) { index in
                    let entry = vm.weekData[index]
                    Button(action: {
                        withAnimation {
                            selectedDayIndex = index
                        }
                    }) {
                        HStack {
                            Text(formatDayShort(entry.date))
                                .font(Font.subheadline)
                                .foregroundColor(entry.isFutureDate ? Color.orange : Color.ksrDarkGray)
                            
                            Spacer()
                            
                            if entry.isFutureDate {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                    .padding(.trailing, 4)
                                Text("Future")
                                    .font(Font.caption)
                                    .foregroundColor(.orange)
                            } else if entry.startTime != nil && entry.endTime != nil {
                                Text("\(entry.totalHours, specifier: "%.2f") hrs")
                                    .font(Font.subheadline)
                                    .foregroundColor(Color.ksrYellow)
                            } else {
                                Text("No hours")
                                    .font(Font.subheadline)
                                    .foregroundColor(Color.gray)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(
                            index == selectedDayIndex ?
                                (entry.isFutureDate ? Color.orange.opacity(0.1) : Color.ksrYellow.opacity(0.1)) :
                                (index % 2 == 0 ? Color(.systemGray6) : Color.white)
                        )
                    }
                }
                
                Divider()
                
                // Suma
                HStack {
                    Text("Total")
                        .font(Font.headline)
                        .foregroundColor(Color.ksrDarkGray)
                    
                    Spacer()
                    
                    Text("\(totalWeekHours(), specifier: "%.2f") hrs")
                        .font(Font.headline)
                        .foregroundColor(Color.ksrYellow)
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.5))
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            Button("Save Draft") {
                vm.saveDraft()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .foregroundColor(Color.ksrDarkGray)
            .font(Font.headline)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.ksrDarkGray, lineWidth: 1)
            )
            .cornerRadius(10)
            
            Button("Submit") {
                vm.submitEntries()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.ksrYellow)
            .foregroundColor(Color.black)
            .font(Font.headline)
            .cornerRadius(10)
        }
        .padding()
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: -2)
        )
    }
    
    // MARK: - Akcje i funkcje pomocnicze
    
    private var loadingOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Saving...")
                    .font(Font.headline)
                    .foregroundColor(Color.ksrDarkGray)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // Obliczenie sumy godzin w tygodniu
    private func totalWeekHours() -> Double {
        vm.weekData.reduce(0) { sum, entry in
            sum + entry.totalHours
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
    
    private func pauseMinutesBinding(for index: Int) -> Binding<Double> {
        Binding(
            get: {
                guard index < vm.weekData.count else { return 0 }
                return Double(vm.weekData[index].pauseMinutes)
            },
            set: {
                guard index < vm.weekData.count else { return }
                vm.updatePauseMinutes(at: index, to: Int($0))
            }
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
    
    // MARK: - Formatowanie
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func formatDayShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    private func formatWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
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
