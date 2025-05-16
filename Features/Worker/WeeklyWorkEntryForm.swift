import SwiftUI

struct WeeklyWorkEntryForm: View {
    @StateObject private var vm: WeeklyWorkEntryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDayIndex: Int = 0
    @State private var selectedOutOfWeekIndex: Int?
    @State private var showingCalendarView = false
    @State private var hasCopiedEntry: Bool = false // Śledzi, czy istnieją skopiowane dane
    @State private var showClearDraftAlert: Bool = false // Śledzi alert dla Clear Draft
    
    // Filter weekData to only include entries for the current week
    private var filteredWeekData: [EditableWorkEntry] {
        let calendar = Calendar.current
        let weekStart = vm.selectedMonday
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        return vm.weekData.filter { entry in
            let entryDate = entry.date
            return entryDate >= weekStart && entryDate <= weekEnd
        }
    }
    
    // Entries outside the current week
    private var outOfWeekEntries: [EditableWorkEntry] {
        let calendar = Calendar.current
        let weekStart = vm.selectedMonday
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        return vm.weekData.filter { entry in
            let entryDate = entry.date
            return entryDate < weekStart || entryDate > weekEnd
        }.sorted { $0.date < $1.date }
    }
    
    /// Initializes the form with employee ID, task ID, and the Monday of the selected week
    init(employeeId: String, taskId: String, selectedMonday: Date) {
        let calendar = Calendar.current
        // Normalizuj selectedMonday do lokalnej strefy czasowej
        let normalizedMonday = calendar.startOfDay(for: selectedMonday)
        _vm = StateObject(
            wrappedValue: WeeklyWorkEntryViewModel(
                employeeId: employeeId,
                taskId: taskId,
                selectedMonday: normalizedMonday
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week header with day selection
                weekHeader
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Navigation hint for days
                        Text("Tap a day above to edit entries for that day")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                        
                        // Out-of-week entries
                        outOfWeekEntriesSection
                        
                        // Future date warning if applicable
                        if selectedDayIndex < filteredWeekData.count && filteredWeekData[selectedDayIndex].isFutureDate {
                            futureDateWarning
                        }
                        
                        // Selected day section
                        if selectedDayIndex < filteredWeekData.count {
                            dayEntrySection(for: filteredWeekData[selectedDayIndex], at: selectedDayIndex, isOutOfWeek: false)
                        }
                        
                        // Week summary section
                        weekSummarySection
                    }
                    .padding()
                }
                
                // Action buttons at the bottom
                bottomActionBar
            }
            .background(Color(colorScheme == .dark ? .black : .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Log Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.saveDraft()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrYellow)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
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
            .alert("Clear All Drafts?", isPresented: $showClearDraftAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    withAnimation {
                        vm.clearAllDrafts()
                    }
                }
            } message: {
                Text("This will clear all draft entries for this week. This action cannot be undone.")
            }
            .overlay {
                if vm.isLoading {
                    loadingOverlay
                }
            }
            #if DEBUG
            .withAuthDebugging()
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
            // Week title
            HStack {
                Text("Week \(getWeekNumber()) of \(formatWeek(vm.selectedMonday))")
                    .font(.headline)
                    .padding()
                Spacer()
            }
            .background(Color(colorScheme == .dark ? .black : .systemGroupedBackground))
            
            // Days of the week - pills, stretched to full width
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(0..<filteredWeekData.count, id: \.self) { index in
                        let entry = filteredWeekData[index]
                        dayPill(for: entry, index: index, isSelected: selectedDayIndex == index)
                            .frame(width: geometry.size.width / 7)
                            .onTapGesture {
                                withAnimation {
                                    selectedDayIndex = index
                                    selectedOutOfWeekIndex = nil
                                }
                            }
                    }
                }
                .frame(height: 70)
            }
            .frame(height: 70)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.systemGray5)),
                alignment: .bottom
            )
        }
    }
    
    private func getWeekNumber() -> Int {
        let calendar = Calendar.current
        return calendar.component(.weekOfYear, from: vm.selectedMonday)
    }
    
    private func dayPill(for entry: EditableWorkEntry, index: Int, isSelected: Bool) -> some View {
        let dayName = formatDayName(entry.date)
        let dayNumber = formatDayNumber(entry.date)
        let isToday = Calendar.current.isDateInToday(entry.date)
        let isFuture = entry.isFutureDate
        
        let background: Color = {
            if isSelected {
                return isFuture ? Color.orange : Color.ksrYellow
            } else {
                if isToday {
                    return Color.ksrYellow.opacity(0.15)
                } else if isFuture {
                    return Color.orange.opacity(0.1)
                } else {
                    return colorScheme == .dark ? Color(UIColor.systemGray6).opacity(0.3) : Color(UIColor.systemGray6)
                }
            }
        }()
        
        return VStack(spacing: 2) {
            Text(dayName)
                .font(.caption2)
                .fontWeight(.medium)
            Text(dayNumber)
                .font(.headline)
                .fontWeight(.bold)
            
            if isFuture {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(isSelected ? .white : .orange)
            }
        }
        .foregroundColor(dayPillTextColor(isSelected: isSelected, isToday: isToday, isFuture: isFuture))
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(background)
                .padding(.horizontal, 4)
        )
    }
    
    private func dayPillTextColor(isSelected: Bool, isToday: Bool, isFuture: Bool) -> Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color.ksrYellow
        } else if isFuture {
            return .orange
        } else {
            return colorScheme == .dark ? .white : .primary
        }
    }
    
    // MARK: - Selected Day Section
    
    private func dayEntrySection(for entry: EditableWorkEntry, at index: Int, isOutOfWeek: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(formatDate(entry.date))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            
            // Przyciski Copy, Paste i Clear Day
            if !entry.isFutureDate {
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation {
                            vm.copyEntry(from: index)
                            hasCopiedEntry = true
                        }
                    }) {
                        Text("Copy")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.ksrYellow.opacity(0.2))
                            .foregroundColor(Color.ksrYellow)
                            .cornerRadius(8)
                    }
                    .disabled(entry.startTime == nil || entry.endTime == nil || entry.status == "submitted" || entry.status == "confirmed")
                    
                    Button(action: {
                        withAnimation {
                            vm.pasteEntry(to: index)
                        }
                    }) {
                        Text("Paste")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(hasCopiedEntry ? Color.ksrYellow.opacity(0.2) : Color.gray.opacity(0.2))
                            .foregroundColor(hasCopiedEntry ? Color.ksrYellow : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!hasCopiedEntry || entry.status == "submitted" || entry.status == "confirmed")
                    
                    Button(action: {
                        withAnimation {
                            vm.clearDay(at: index)
                        }
                    }) {
                        Text("Clear Day")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                    .disabled(entry.status == "submitted" || entry.status == "confirmed")
                }
            }
            
            HStack {
                Text(entry.isDraft == true ? "Draft" : "Status: \(entry.status.capitalized)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(entry.isDraft == true ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(entry.isDraft == true ? Color.orange : Color.blue)
                    .cornerRadius(8)
                
                Spacer()
                
                if entry.startTime != nil && entry.endTime != nil {
                    Text("\(entry.totalHours, specifier: "%.2f") hrs")
                        .font(.headline)
                        .foregroundColor(Color.ksrYellow)
                } else {
                    Text("No hours")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
            
            if !entry.isFutureDate {
                timeEntryForm(for: entry, at: index, isOutOfWeek: isOutOfWeek)
            } else {
                Text("Cannot log hours for future dates")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private func timeEntryForm(for entry: EditableWorkEntry, at index: Int, isOutOfWeek: Bool) -> some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Start Time")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                
                customTimePicker(
                    label: "Start Time",
                    time: startTimeBinding(for: index, defaultDate: entry.date, isOutOfWeek: isOutOfWeek),
                    displayTime: formatTimeOnly(entry.startTime ?? entry.date),
                    isEditable: entry.status != "submitted" && entry.status != "confirmed"
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("End Time")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                
                customTimePicker(
                    label: "End Time",
                    time: endTimeBinding(for: index, defaultDate: entry.date, isOutOfWeek: isOutOfWeek),
                    displayTime: formatTimeOnly(entry.endTime ?? entry.date),
                    isEditable: entry.status != "submitted" && entry.status != "confirmed"
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Break (minutes)")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                
                HStack {
                    Slider(value: pauseMinutesBinding(for: index, isOutOfWeek: isOutOfWeek), in: 0...120, step: 5)
                        .accentColor(Color.ksrYellow)
                        .disabled(entry.status == "submitted" || entry.status == "confirmed")
                    
                    Text("\(Int(entry.pauseMinutes))")
                        .font(.headline)
                        .frame(width: 50)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (optional)")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                
                if colorScheme == .dark {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: notesBinding(for: index, isOutOfWeek: isOutOfWeek))
                            .frame(height: 100)
                            .padding(4)
                            .foregroundColor(.white)
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray3), lineWidth: 1)
                            )
                            .disabled(entry.status == "submitted" || entry.status == "confirmed")
                    }
                } else {
                    TextEditor(text: notesBinding(for: index, isOutOfWeek: isOutOfWeek))
                        .frame(height: 100)
                        .padding(4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray3), lineWidth: 1)
                        )
                        .disabled(entry.status == "submitted" || entry.status == "confirmed")
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 2, x: 0, y: 2)
    }
    
    private func customTimePicker(label: String, time: Binding<Date>, displayTime: String, isEditable: Bool) -> some View {
        ZStack(alignment: .trailing) {
            DatePicker(
                label,
                selection: time,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .accentColor(.ksrYellow)
            .frame(maxWidth: .infinity, alignment: .leading)
            .disabled(!isEditable)
            
            Text(displayTime)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isEditable ? (colorScheme == .dark ? .white : .black) : .gray)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.5) : Color(.systemGray6))
                )
                .padding(.trailing, 8)
                .allowsHitTesting(false)
        }
        .padding(8)
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Out-of-Week Entries Section
    
    private var outOfWeekEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !outOfWeekEntries.isEmpty {
                Text("Entries Outside This Week")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                ForEach(outOfWeekEntries.indices, id: \.self) { index in
                    let entry = outOfWeekEntries[index]
                    let isSelected = selectedOutOfWeekIndex == index
                    Button(action: {
                        withAnimation {
                            selectedOutOfWeekIndex = isSelected ? nil : index
                            selectedDayIndex = filteredWeekData.count
                        }
                    }) {
                        HStack {
                            Text(formatDate(entry.date))
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            if entry.startTime != nil && entry.endTime != nil {
                                Text("\(entry.totalHours, specifier: "%.2f") hrs")
                                    .font(.subheadline)
                                    .foregroundColor(Color.ksrYellow)
                            } else {
                                Text("No hours")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(
                            isSelected ?
                                Color.ksrYellow.opacity(0.1) :
                                (colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color.white)
                        )
                        .cornerRadius(12)
                    }
                    
                    if isSelected {
                        dayEntrySection(for: entry, at: index, isOutOfWeek: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Week Summary Section
    
    private var weekSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Week Summary")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            
            VStack(spacing: 0) {
                ForEach(0..<filteredWeekData.count, id: \.self) { index in
                    let entry = filteredWeekData[index]
                    Button(action: {
                        withAnimation {
                            selectedDayIndex = index
                            selectedOutOfWeekIndex = nil
                        }
                    }) {
                        HStack {
                            Text(formatDayShort(entry.date))
                                .font(.subheadline)
                                .foregroundColor(entry.isFutureDate ? Color.orange : (colorScheme == .dark ? .white : Color.ksrDarkGray))
                            
                            Spacer()
                            
                            if entry.isFutureDate {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                    .padding(.trailing, 4)
                                Text("Future")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else if entry.startTime != nil && entry.endTime != nil {
                                Text("\(entry.totalHours, specifier: "%.2f") hrs")
                                    .font(.subheadline)
                                    .foregroundColor(Color.ksrYellow)
                            } else {
                                Text("No hours")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(
                            index == selectedDayIndex ?
                                (entry.isFutureDate ? Color.orange.opacity(0.1) : Color.ksrYellow.opacity(0.1)) :
                                (index % 2 == 0 ? (colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6)) :
                                                  (colorScheme == .dark ? Color.black : Color.white))
                        )
                    }
                }
                
                Divider()
                    .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                
                HStack {
                    Text("Total")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    
                    Spacer()
                    
                    Text("\(totalWeekHours(), specifier: "%.2f") hrs")
                        .font(.headline)
                        .foregroundColor(Color.ksrYellow)
                }
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6).opacity(0.5))
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .dark ? Color(.systemGray4).opacity(0.3) : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            Button("Clear Draft") {
                showClearDraftAlert = true
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.2))
            .foregroundColor(.red)
            .font(.headline)
            .cornerRadius(10)
            .disabled(vm.isLoading || !vm.anyDrafts)
            
            Button("Save Draft") {
                vm.saveDraft()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            .font(.headline)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.ksrDarkGray, lineWidth: 1)
            )
            .cornerRadius(10)
            .disabled(vm.isLoading)
            
            Button("Submit for Approval") {
                vm.submitEntries()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.ksrYellow)
            .foregroundColor(.black)
            .font(.headline)
            .cornerRadius(10)
            .disabled(vm.isLoading)
        }
        .padding()
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? Color.black : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: -2)
        )
    }
    
    // MARK: - Actions and Helper Functions
    
    private var loadingOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Saving...")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.7) : Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private func totalWeekHours() -> Double {
        filteredWeekData.reduce(0) { sum, entry in
            sum + entry.totalHours
        }
    }
    
    // MARK: - Bindings
    
    private func weekDataIndex(for index: Int, isOutOfWeek: Bool) -> Int? {
        let sourceArray = isOutOfWeek ? outOfWeekEntries : filteredWeekData
        guard index < sourceArray.count else { return nil }
        let targetEntry = sourceArray[index]
        return vm.weekData.firstIndex { $0.id == targetEntry.id }
    }
    
    private func startTimeBinding(for index: Int, defaultDate: Date, isOutOfWeek: Bool) -> Binding<Date> {
        let sourceArray = isOutOfWeek ? outOfWeekEntries : filteredWeekData
        return Binding(
            get: {
                guard index < sourceArray.count else { return defaultDate }
                return sourceArray[index].startTime ?? defaultDate
            },
            set: { newValue in
                if let weekDataIndex = weekDataIndex(for: index, isOutOfWeek: isOutOfWeek) {
                    vm.updateStartTime(at: weekDataIndex, to: newValue)
                }
            }
        )
    }
    
    private func endTimeBinding(for index: Int, defaultDate: Date, isOutOfWeek: Bool) -> Binding<Date> {
        let sourceArray = isOutOfWeek ? outOfWeekEntries : filteredWeekData
        return Binding(
            get: {
                guard index < sourceArray.count else { return defaultDate }
                return sourceArray[index].endTime ?? defaultDate
            },
            set: { newValue in
                if let weekDataIndex = weekDataIndex(for: index, isOutOfWeek: isOutOfWeek) {
                    vm.updateEndTime(at: weekDataIndex, to: newValue)
                }
            }
        )
    }
    
    private func pauseMinutesBinding(for index: Int, isOutOfWeek: Bool) -> Binding<Double> {
        let sourceArray = isOutOfWeek ? outOfWeekEntries : filteredWeekData
        return Binding(
            get: {
                guard index < sourceArray.count else { return 0 }
                return Double(sourceArray[index].pauseMinutes)
            },
            set: { newValue in
                if let weekDataIndex = weekDataIndex(for: index, isOutOfWeek: isOutOfWeek) {
                    vm.updatePauseMinutes(at: weekDataIndex, to: Int(newValue))
                }
            }
        )
    }
    
    private func notesBinding(for index: Int, isOutOfWeek: Bool) -> Binding<String> {
        let sourceArray = isOutOfWeek ? outOfWeekEntries : filteredWeekData
        return Binding(
            get: {
                guard index < sourceArray.count else { return "" }
                return sourceArray[index].notes
            },
            set: { newValue in
                if let weekDataIndex = weekDataIndex(for: index, isOutOfWeek: isOutOfWeek) {
                    vm.updateDescription(at: weekDataIndex, to: newValue)
                }
            }
        )
    }
    
    // MARK: - Formatting
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private func formatDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private func formatDayShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private func formatWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}

struct WeeklyWorkEntryForm_Previews: PreviewProvider {
    static var previews: some View {
        let monday = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        
        Group {
            WeeklyWorkEntryForm(
                employeeId: "123",
                taskId: "456",
                selectedMonday: monday
            )
            .preferredColorScheme(.light)
            
            WeeklyWorkEntryForm(
                employeeId: "123",
                taskId: "456",
                selectedMonday: monday
            )
            .preferredColorScheme(.dark)
        }
    }
}
