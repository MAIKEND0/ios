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
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // Week header
                weekHeader
                
                // Main content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        Text("Tap a day above to edit entries for that day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                        
                        outOfWeekEntriesSection
                        
                        if selectedDayIndex < filteredWeekData.count && filteredWeekData[selectedDayIndex].isFutureDate {
                            futureDateWarning
                        }
                        
                        if selectedDayIndex < filteredWeekData.count {
                            dayEntrySection(for: filteredWeekData[selectedDayIndex], at: selectedDayIndex, isOutOfWeek: false)
                        }
                        
                        weekSummarySection
                        
                        // Bottom padding for action bar
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 100)
                    }
                    .padding(.horizontal)
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
        .cornerRadius(10)
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
        .cornerRadius(10)
    }
    
    // MARK: - Week Header
    private var weekHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Week \(getWeekNumber()) of \(formatWeek(vm.selectedMonday))")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                Spacer()
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemGroupedBackground))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<filteredWeekData.count, id: \.self) { index in
                        let entry = filteredWeekData[index]
                        dayPill(for: entry, index: index, isSelected: selectedDayIndex == index)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDayIndex = index
                                    selectedOutOfWeekIndex = nil
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 80)
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
        let hasHours = entry.startTime != nil && entry.endTime != nil
        
        let background: Color = {
            if isSelected {
                return isFuture ? .ksrWarning : .ksrYellow
            } else {
                if isToday {
                    return .ksrYellowLight
                } else if isFuture {
                    return .ksrWarningLight
                } else if hasHours {
                    return .ksrSuccessLight
                } else {
                    return colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6)
                }
            }
        }()
        
        return VStack(spacing: 4) {
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
            } else if hasHours && !isSelected {
                Circle()
                    .fill(Color.ksrSuccess)
                    .frame(width: 6, height: 6)
            }
        }
        .foregroundColor(dayPillTextColor(isSelected: isSelected, isToday: isToday, isFuture: isFuture))
        .frame(width: 50, height: 64)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? .clear : Color(.systemGray4).opacity(0.5), lineWidth: 1)
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
            // Header with date and status
            VStack(alignment: .leading, spacing: 8) {
                Text(formatDate(entry.date))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                HStack {
                    statusBadge(for: entry)
                    Spacer()
                    
                    if entry.startTime != nil && entry.endTime != nil {
                        Text("\(entry.totalHours, specifier: "%.1f") hrs")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.ksrYellow)
                    } else {
                        Text("No hours")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Action buttons
            if !entry.isFutureDate {
                actionButtons(for: entry, at: index)
            }
            
            // Time entry form or future date message
            if !entry.isFutureDate {
                timeEntryForm(for: entry, at: index, isOutOfWeek: isOutOfWeek)
            } else {
                futureDateMessage
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.15) : .white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 4, x: 0, y: 2)
    }
    
    private func statusBadge(for entry: EditableWorkEntry) -> some View {
        let (text, color) = {
            if entry.isDraft == true {
                return ("Draft", Color.ksrWarning)
            } else {
                switch entry.status {
                case "submitted": return ("Submitted", Color.ksrInfo)
                case "confirmed": return ("Confirmed", Color.ksrSuccess)
                case "rejected": return ("Rejected", Color.ksrError)
                default: return ("Draft", Color.ksrWarning)
                }
            }
        }()
        
        return Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(6)
    }
    
    private func actionButtons(for entry: EditableWorkEntry, at index: Int) -> some View {
        HStack(spacing: 8) {
            ActionButton(
                title: "Copy",
                icon: "doc.on.doc",
                color: .ksrYellow,
                isEnabled: entry.startTime != nil && entry.endTime != nil && entry.status != "submitted" && entry.status != "confirmed"
            ) {
                withAnimation {
                    vm.copyEntry(from: index)
                    hasCopiedEntry = true
                }
            }
            
            ActionButton(
                title: "Paste",
                icon: "doc.on.clipboard",
                color: .ksrInfo,
                isEnabled: hasCopiedEntry && entry.status != "submitted" && entry.status != "confirmed"
            ) {
                withAnimation {
                    vm.pasteEntry(to: index)
                }
            }
            
            ActionButton(
                title: "Clear",
                icon: "trash",
                color: .ksrError,
                isEnabled: entry.status != "submitted" && entry.status != "confirmed"
            ) {
                withAnimation {
                    vm.clearDay(at: index)
                }
            }
        }
    }
    
    private var futureDateMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(.ksrWarning)
            
            Text("Cannot log hours for future dates")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.ksrWarningLight.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func timeEntryForm(for entry: EditableWorkEntry, at index: Int, isOutOfWeek: Bool) -> some View {
        VStack(spacing: 16) {
            // Time section
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    CompactTimePicker(
                        title: "Start",
                        time: startTimeBinding(for: index, defaultDate: entry.date, isOutOfWeek: isOutOfWeek),
                        isEnabled: entry.status != "submitted" && entry.status != "confirmed"
                    )
                    
                    CompactTimePicker(
                        title: "End",
                        time: endTimeBinding(for: index, defaultDate: entry.date, isOutOfWeek: isOutOfWeek),
                        isEnabled: entry.status != "submitted" && entry.status != "confirmed"
                    )
                }
                
                // Break slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Break")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(Int(entry.pauseMinutes)) min")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ksrYellow)
                    }
                    
                    Slider(
                        value: pauseMinutesBinding(for: index, isOutOfWeek: isOutOfWeek),
                        in: 0...120,
                        step: 5
                    )
                    .accentColor(.ksrYellow)
                    .disabled(entry.status == "submitted" || entry.status == "confirmed")
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.1) : Color(.systemGray6).opacity(0.3))
            .cornerRadius(12)
            
            // Kilometers field
            VStack(alignment: .leading, spacing: 8) {
                Text("Kilometers")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack {
                    TextField("0.0", value: kmBinding(for: index, isOutOfWeek: isOutOfWeek), format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 120)
                        .disabled(entry.status == "submitted" || entry.status == "confirmed")
                    
                    Text("km")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // Notes field
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("Add notes...", text: notesBinding(for: index, isOutOfWeek: isOutOfWeek), axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                    .disabled(entry.status == "submitted" || entry.status == "confirmed")
            }
        }
    }
    
    // MARK: - Out-of-Week Entries Section
    private var outOfWeekEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !outOfWeekEntries.isEmpty {
                Text("Entries Outside This Week")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                ForEach(outOfWeekEntries.indices, id: \.self) { index in
                    let entry = outOfWeekEntries[index]
                    let isSelected = selectedOutOfWeekIndex == index
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedOutOfWeekIndex = isSelected ? nil : index
                            selectedDayIndex = filteredWeekData.count
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatDate(entry.date))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(entry.status.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if entry.startTime != nil && entry.endTime != nil {
                                Text("\(entry.totalHours, specifier: "%.1f") hrs")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.ksrYellow)
                            } else {
                                Text("No hours")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Image(systemName: isSelected ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            isSelected ? Color.ksrYellowLight : (colorScheme == .dark ? Color(.systemGray6).opacity(0.15) : .white)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
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
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                ForEach(0..<filteredWeekData.count, id: \.self) { index in
                    let entry = filteredWeekData[index]
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDayIndex = index
                            selectedOutOfWeekIndex = nil
                        }
                    }) {
                        HStack {
                            Text(formatDayShort(entry.date))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(entry.isFutureDate ? .ksrWarning : .primary)
                            
                            Spacer()
                            
                            if entry.isFutureDate {
                                HStack(spacing: 4) {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                    Text("Future")
                                        .font(.caption)
                                }
                                .foregroundColor(.ksrWarning)
                            } else if entry.startTime != nil && entry.endTime != nil {
                                HStack(spacing: 8) {
                                    Text("\(entry.totalHours, specifier: "%.1f") hrs")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.ksrYellow)
                                    
                                    if let km = entry.km, km > 0 {
                                        Text("• \(km, specifier: "%.1f") km")
                                            .font(.caption)
                                            .foregroundColor(.ksrInfo)
                                    }
                                }
                            } else {
                                Text("—")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            index == selectedDayIndex ?
                                (entry.isFutureDate ? Color.ksrWarningLight : Color.ksrYellowLight) :
                                Color.clear
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if index < filteredWeekData.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
                
                Divider()
                    .background(Color.primary)
                    .padding(.horizontal, 16)
                
                HStack {
                    Text("Total")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Text("\(totalWeekHours(), specifier: "%.1f") hrs")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.ksrYellow)
                        
                        if totalWeekKm() > 0 {
                            Text("• \(totalWeekKm(), specifier: "%.1f") km")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.ksrInfo)
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.15) : Color(.systemGray6).opacity(0.3))
            }
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.1) : .white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    showClearDraftAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Draft")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ksrErrorLight)
                    .foregroundColor(.ksrError)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .cornerRadius(12)
                }
                .disabled(vm.isLoading || !vm.anyDrafts)
                
                Button(action: {
                    vm.saveDraft()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save Draft")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : .white)
                    .foregroundColor(.primary)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
                .disabled(vm.isLoading)
            }
            
            Button(action: {
                vm.submitEntries()
            }) {
                HStack {
                    Image(systemName: preselectedEntry != nil ? "arrow.clockwise" : "checkmark.circle")
                    Text(preselectedEntry != nil ? "Resubmit" : "Submit for Approval")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ksrYellow)
                .foregroundColor(.black)
                .font(.headline)
                .fontWeight(.semibold)
                .cornerRadius(12)
            }
            .disabled(vm.isLoading)
        }
        .padding()
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? .black : .white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
        )
    }
    
    // MARK: - Actions and Helper Functions
    private var loadingOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.ksrYellow)
                
                Text("Saving...")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.9) : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
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

// MARK: - Custom Components

struct CompactTimePicker: View {
    let title: String
    @Binding var time: Date
    let isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            DatePicker(
                title,
                selection: $time,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .disabled(!isEnabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isEnabled ? color.opacity(0.1) : Color.gray.opacity(0.1))
            .foregroundColor(isEnabled ? color : .gray)
            .cornerRadius(8)
        }
        .disabled(!isEnabled)
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
