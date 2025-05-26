// WeeklyWorkEntryForm.swift
import SwiftUI

struct WeeklyWorkEntryForm: View {
    @StateObject private var vm: WeeklyWorkEntryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDayIndex: Int = 0
    @State private var selectedOutOfWeekIndex: Int?
    @State private var showingCalendarView = false
    @State private var hasCopiedEntry: Bool = false
    @State private var showClearDraftAlert: Bool = false
    
    // Nowy parametr dla odrzuconego wpisu
    private let preselectedEntry: WorkerAPIService.WorkHourEntry?
    
    // Filter weekData to only include entries for the current week
    private var filteredWeekData: [EditableWorkEntry] {
        let calendar = Calendar.current
        let weekStart = vm.selectedMonday
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        return vm.weekData.filter { entry in
            entry.date >= weekStart && entry.date <= weekEnd
        }
    }
    
    // Entries outside the current week
    private var outOfWeekEntries: [EditableWorkEntry] {
        let calendar = Calendar.current
        let weekStart = vm.selectedMonday
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        return vm.weekData.filter { entry in
            entry.date < weekStart || entry.date > weekEnd
        }.sorted { $0.date < $1.date }
    }
    
    init(
        employeeId: String,
        taskId: String,
        selectedMonday: Date,
        preselectedEntry: WorkerAPIService.WorkHourEntry? = nil
    ) {
        let calendar = Calendar.current
        let normalizedMonday = calendar.startOfDay(for: selectedMonday)
        _vm = StateObject(
            wrappedValue: WeeklyWorkEntryViewModel(
                employeeId: employeeId,
                taskId: taskId,
                selectedMonday: normalizedMonday
            )
        )
        self.preselectedEntry = preselectedEntry
        // Ustaw początkowy indeks na dzień odrzuconego wpisu
        if let entry = preselectedEntry {
            let entryDate = calendar.startOfDay(for: entry.work_date)
            if let index = (0..<7).first(where: { calendar.date(byAdding: .day, value: $0, to: normalizedMonday) == entryDate }) {
                _selectedDayIndex = State(initialValue: index)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Baner dla odrzuconego wpisu
                if let entry = preselectedEntry, let reason = entry.rejection_reason {
                    rejectionBanner(reason: reason)
                }
                
                // Week header
                weekHeader
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Tap a day above to edit entries for that day")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                        
                        outOfWeekEntriesSection
                        
                        if selectedDayIndex < filteredWeekData.count && filteredWeekData[selectedDayIndex].isFutureDate {
                            futureDateWarning
                        }
                        
                        if selectedDayIndex < filteredWeekData.count {
                            dayEntrySection(for: filteredWeekData[selectedDayIndex], at: selectedDayIndex, isOutOfWeek: false)
                        }
                        
                        weekSummarySection
                    }
                    .padding()
                }
                
                // Action bar
                bottomActionBar
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Log Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        vm.saveDraft()
                    }) {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundColor(.ksrYellow)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(colorScheme == .dark ? .white : .blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCalendarView.toggle()
                    }) {
                        Image(systemName: "calendar")
                            .foregroundColor(.ksrYellow)
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
                Button("Cancel", role: .cancel) {}
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
    
    // MARK: - Rejection Banner
    private func rejectionBanner(reason: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.ksrError)
                Text("Entry Rejected")
                    .font(.headline)
                    .foregroundColor(.ksrError)
            }
            Text("Reason: \(reason)")
                .font(.subheadline)
                .foregroundColor(.ksrError.opacity(0.8))
            Text("Please correct the entry and resubmit.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ksrErrorLight)
        .cornerRadius(8)
    }
    
    // MARK: - Future Date Warning
    private var futureDateWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.ksrWarning)
                Text("Future Date")
                    .font(.headline)
                    .foregroundColor(.ksrWarning)
            }
            Text("You cannot log hours for future dates. Please select a current or past date.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ksrWarningLight)
        .cornerRadius(8)
    }
    
    // MARK: - Week Header
    private var weekHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Week \(getWeekNumber()) of \(formatWeek(vm.selectedMonday))")
                    .font(.headline)
                    .padding()
                Spacer()
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemGroupedBackground))
            
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
                return isFuture ? .ksrWarning : .ksrYellow
            } else {
                if isToday {
                    return .ksrYellowLight
                } else if isFuture {
                    return .ksrWarningLight
                } else {
                    return colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6)
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
                    .foregroundColor(isSelected ? .white : .ksrWarning)
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
            return .ksrYellow
        } else if isFuture {
            return .ksrWarning
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
                .foregroundColor(colorScheme == .dark ? .white : .ksrDarkGray)
            
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
                            .background(Color.ksrYellowLight)
                            .foregroundColor(.ksrYellow)
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
                            .background(hasCopiedEntry ? Color.ksrYellowLight : Color.inactiveColor.opacity(0.2))
                            .foregroundColor(hasCopiedEntry ? .ksrYellow : .inactiveColor)
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
                            .background(Color.ksrErrorLight)
                            .foregroundColor(.ksrError)
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
                    .background(entry.isDraft == true ? Color.ksrWarningLight : Color.ksrInfoLight)
                    .foregroundColor(entry.isDraft == true ? .ksrWarning : .ksrInfo)
                    .cornerRadius(8)
                
                Spacer()
                
                if entry.startTime != nil && entry.endTime != nil {
                    Text("\(entry.totalHours, specifier: "%.2f") hrs")
                        .font(.headline)
                        .foregroundColor(.ksrYellow)
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
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .ksrMediumGray)
                
                CustomTimePicker(
                    label: "Start Time",
                    time: startTimeBinding(for: index, defaultDate: entry.date, isOutOfWeek: isOutOfWeek),
                    displayTime: formatTimeOnly(entry.startTime ?? entry.date),
                    isEditable: entry.status != "submitted" && entry.status != "confirmed"
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("End Time")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .ksrMediumGray)
                
                CustomTimePicker(
                    label: "End Time",
                    time: endTimeBinding(for: index, defaultDate: entry.date, isOutOfWeek: isOutOfWeek),
                    displayTime: formatTimeOnly(entry.endTime ?? entry.date),
                    isEditable: entry.status != "submitted" && entry.status != "confirmed"
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Break (minutes)")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .ksrMediumGray)
                
                HStack {
                    Slider(value: pauseMinutesBinding(for: index, isOutOfWeek: isOutOfWeek), in: 0...120, step: 5)
                        .accentColor(.ksrYellow)
                        .disabled(entry.status == "submitted" || entry.status == "confirmed")
                    
                    Text("\(Int(entry.pauseMinutes))")
                        .font(.headline)
                        .frame(width: 50)
                        .foregroundColor(colorScheme == .dark ? .white : .ksrDarkGray)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Kilometers")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .ksrMediumGray)
                
                HStack {
                    TextField("Enter km", value: kmBinding(for: index, isOutOfWeek: isOutOfWeek), format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 100)
                        .padding(.vertical, 4)
                        .disabled(entry.status == "submitted" || entry.status != "confirmed")
                    
                    Text("km")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .ksrMediumGray)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (optional)")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .ksrMediumGray)
                
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
                    ZStack(alignment: .topLeading) {
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
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : .white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - Out-of-Week Entries Section
    private var outOfWeekEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !outOfWeekEntries.isEmpty {
                Text("Entries Outside This Week")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .ksrDarkGray)
                
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
                                    .foregroundColor(.ksrYellow)
                            } else {
                                Text("No hours")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(
                            isSelected ? Color.ksrYellowLight : (colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : .white)
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
                .foregroundColor(colorScheme == .dark ? .white : .ksrDarkGray)
            
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
                                .foregroundColor(entry.isFutureDate ? .ksrWarning : (colorScheme == .dark ? .white : .ksrDarkGray))
                            Spacer()
                            if entry.isFutureDate {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.ksrWarning)
                                    .font(.caption)
                                    .padding(.trailing, 4)
                                Text("Future")
                                    .font(.caption)
                                    .foregroundColor(.ksrWarning)
                            } else if entry.startTime != nil && entry.endTime != nil {
                                HStack {
                                    Text("\(entry.totalHours, specifier: "%.2f") hrs")
                                        .font(.subheadline)
                                        .foregroundColor(.ksrYellow)
                                    if let km = entry.km {
                                        Text("• \(km, specifier: "%.2f") km")
                                            .font(.subheadline)
                                            .foregroundColor(.ksrYellow)
                                    }
                                }
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
                                (entry.isFutureDate ? Color.ksrWarningLight : Color.ksrYellowLight) :
                                (index % 2 == 0 ? (colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6)) :
                                                  (colorScheme == .dark ? .black : .white))
                        )
                    }
                }
                
                Divider()
                    .background(colorScheme == .dark ? .gray.opacity(0.3) : .gray.opacity(0.2))
                
                HStack {
                    Text("Total")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .ksrDarkGray)
                    Spacer()
                    HStack {
                        Text("\(totalWeekHours(), specifier: "%.2f") hrs")
                            .font(.headline)
                            .foregroundColor(.ksrYellow)
                        Text("• \(totalWeekKm(), specifier: "%.2f") km")
                            .font(.headline)
                            .foregroundColor(.ksrYellow)
                    }
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
            Button(action: {
                showClearDraftAlert = true
            }) {
                Text("Clear Draft")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ksrErrorLight)
                    .foregroundColor(.ksrError)
                    .font(.headline)
                    .cornerRadius(10)
            }
            .disabled(vm.isLoading || !vm.anyDrafts)
            
            Button(action: {
                vm.saveDraft()
            }) {
                Text("Save Draft")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : .white)
                    .foregroundColor(colorScheme == .dark ? .white : .ksrDarkGray)
                    .font(.headline)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(colorScheme == .dark ? .gray.opacity(0.5) : .ksrDarkGray, lineWidth: 1)
                    )
                    .cornerRadius(10)
            }
            .disabled(vm.isLoading)
            
            Button(action: {
                vm.submitEntries()
            }) {
                Text(preselectedEntry != nil ? "Resubmit" : "Submit for Approval")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ksrYellow)
                    .foregroundColor(.black)
                    .font(.headline)
                    .cornerRadius(10)
            }
            .disabled(vm.isLoading)
        }
        .padding()
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? .black : .white)
                .shadow(color: .black.opacity(0.05), radius: 4, y: -2)
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
                    .foregroundColor(colorScheme == .dark ? .white : .ksrDarkGray)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.7) : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private func totalWeekHours() -> Double {
        filteredWeekData.reduce(0) { sum, entry in
            sum + entry.totalHours
        }
    }
    
    private func totalWeekKm() -> Double {
        filteredWeekData.reduce(0) { sum, entry in
            sum + (entry.km ?? 0.0)
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
    
    private func kmBinding(for index: Int, isOutOfWeek: Bool) -> Binding<Double?> {
        let sourceArray = isOutOfWeek ? outOfWeekEntries : filteredWeekData
        return Binding(
            get: {
                guard index < sourceArray.count else { return nil }
                return sourceArray[index].km
            },
            set: { newValue in
                if let weekDataIndex = weekDataIndex(for: index, isOutOfWeek: isOutOfWeek) {
                    vm.updateKm(at: weekDataIndex, to: newValue)
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

// MARK: - Custom Time Picker
struct CustomTimePicker: View {
    let label: String
    @Binding var time: Date
    let displayTime: String
    let isEditable: Bool
    
    var body: some View {
        DatePicker(
            label,
            selection: $time,
            displayedComponents: [.hourAndMinute]
        )
        .datePickerStyle(.wheel)
        .labelsHidden()
        .disabled(!isEditable)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6).opacity(0.3))
        )
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
