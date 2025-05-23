import SwiftUI

protocol WeekSelectorViewModel: ObservableObject {
    var weekRangeText: String { get }
    var selectedMonday: Date { get }
    func changeWeek(by offset: Int)
}

protocol WorkPlanViewModel: ObservableObject {
    var assignments: [WorkPlanAssignment] { get set }
    var description: String { get set }
    var additionalInfo: String { get set }
    var attachment: WorkPlanAPIService.Attachment? { get }
    var showAlert: Bool { get set }
    var alertTitle: String { get set }
    var alertMessage: String { get set }
    func saveDraft()
    func publish()
    func setAttachment(from url: URL)
    func copyHoursToOtherEmployees(from assignment: WorkPlanAssignment)
}

struct WorkPlanAssignment: Identifiable {
    let id: UUID = UUID()
    let employee_id: Int
    var availableEmployees: [ManagerAPIService.Worker]
    let weekStart: Date
    var dailyHours: [DailyHours]
    var notes: String
    
    mutating func copyHoursToAllDays() {
        guard let firstActiveDay = dailyHours.first(where: { $0.isActive }) else {
            // Jeśli nie ma aktywnego dnia, użyj domyślnych godzin 7-15
            let defaultHours = DailyHours(isActive: true) // Automatycznie 7:00-15:00
            dailyHours = Array(repeating: defaultHours, count: dailyHours.count)
            return
        }
        
        let newHours = DailyHours(
            isActive: true,
            start_time: firstActiveDay.start_time,
            end_time: firstActiveDay.end_time
        )
        dailyHours = Array(repeating: newHours, count: dailyHours.count)
    }
}

extension WorkPlanAssignment {
    func toRequestAssignments() -> [WorkPlanAPIService.WorkPlanAssignmentRequest] {
        dailyHours.enumerated().compactMap { index, hours in
            guard hours.isActive, hours.start_time != hours.end_time else { return nil }
            let work_date = Calendar.current.date(byAdding: .day, value: index, to: weekStart)!
            
            // Formatter do czasu - tylko HH:mm format
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            
            // Pobierz godziny i minuty z start_time i end_time jako stringi HH:mm
            let startTimeString = timeFormatter.string(from: hours.start_time)
            let endTimeString = timeFormatter.string(from: hours.end_time)
            
            #if DEBUG
            print("[WorkPlanAssignment] Creating assignment for employee \(employee_id), date: \(work_date), start_time: '\(startTimeString)', end_time: '\(endTimeString)'")
            #endif
            
            return WorkPlanAPIService.WorkPlanAssignmentRequest(
                employee_id: employee_id,
                work_date: work_date,
                start_time: startTimeString, // ✅ Now just "HH:mm" format like "08:00"
                end_time: endTimeString,     // ✅ Now just "HH:mm" format like "17:30"
                notes: notes.isEmpty ? nil : notes
            )
        }
    }
}

struct DailyHours: Identifiable, Equatable {
    let id: UUID = UUID()
    var isActive: Bool
    var start_time: Date
    var end_time: Date
    
    // NOWA INICJALIZACJA: Domyślne godziny 7:00-15:00
    init(isActive: Bool = false, start_time: Date? = nil, end_time: Date? = nil) {
        self.isActive = isActive
        
        // Jeśli nie podano konkretnych czasów, użyj domyślnych 7:00-15:00
        if let start = start_time {
            self.start_time = start
        } else {
            // Domyślnie 7:00 dzisiaj
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 7
            components.minute = 0
            components.second = 0
            self.start_time = calendar.date(from: components) ?? Date()
        }
        
        if let end = end_time {
            self.end_time = end
        } else {
            // Domyślnie 15:00 dzisiaj
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 15
            components.minute = 0
            components.second = 0
            self.end_time = calendar.date(from: components) ?? Date()
        }
    }
    
    static func == (lhs: DailyHours, rhs: DailyHours) -> Bool {
        lhs.isActive == rhs.isActive &&
        lhs.start_time == rhs.start_time &&
        lhs.end_time == rhs.end_time
    }
}

struct WorkPlanWeekSelector<VM: WeekSelectorViewModel>: View {
    @ObservedObject var viewModel: VM
    @Environment(\.colorScheme) private var colorScheme
    let isWeekInFuture: Bool
    
    // Use WeekUtils for consistent week calculations
    private var weekNumber: Int {
        WeekUtils.weekNumber(for: viewModel.selectedMonday)
    }
    private var year: Int {
        WeekUtils.year(for: viewModel.selectedMonday)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Week")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 4) {
                // Numer tygodnia i rok
                Text("Week \(weekNumber), \(String(format: "%d", year))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Zakres dat z przyciskami nawigacji
                HStack {
                    Button(action: {
                        viewModel.changeWeek(by: -1)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isWeekInFuture ? Color.ksrYellow : Color.gray)
                            .padding(8)
                            .background(Circle().fill((isWeekInFuture ? Color.ksrYellow : Color.gray).opacity(0.2)))
                    }
                    .disabled(!isWeekInFuture)
                    
                    Text(viewModel.weekRangeText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        viewModel.changeWeek(by: 1)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.ksrYellow)
                            .padding(8)
                            .background(Circle().fill(Color.ksrYellow.opacity(0.2)))
                    }
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
            .cornerRadius(12)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 50 && isWeekInFuture {
                            viewModel.changeWeek(by: -1)
                        } else if value.translation.width < -50 {
                            viewModel.changeWeek(by: 1)
                        }
                    }
            )
        }
    }
}

struct WorkPlanEmployeeSection<VM: WorkPlanViewModel>: View {
    @ObservedObject var viewModel: VM
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assign Hours")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            if viewModel.assignments.isEmpty {
                Text("No employees selected")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                ForEach(Array(viewModel.assignments.enumerated()), id: \.offset) { index, _ in
                    WorkPlanAssignmentRow(
                        assignment: Binding(
                            get: { viewModel.assignments[index] },
                            set: { viewModel.assignments[index] = $0 }
                        ),
                        onCopyToOthers: { assignment in
                            viewModel.copyHoursToOtherEmployees(from: assignment)
                        }
                    )
                }
            }
        }
    }
}

struct WorkPlanAssignmentRow: View {
    @Binding var assignment: WorkPlanAssignment
    let onCopyToOthers: (WorkPlanAssignment) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var validationError: String?

    var body: some View {
        WorkPlanAssignmentContent(
            employeeName: assignment.availableEmployees.first { $0.employee_id == assignment.employee_id }?.name ?? "Unknown",
            notes: $assignment.notes,
            weekStart: assignment.weekStart,
            dailyHours: $assignment.dailyHours,
            copyHoursAction: {
                assignment.copyHoursToAllDays()
            },
            copyToOthersAction: {
                onCopyToOthers(assignment)
            }
        )
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            // Piękny gradient background
            ZStack {
                LinearGradient(
                    colors: [
                        colorScheme == .dark ? Color(.systemGray6).opacity(0.4) : Color.white,
                        colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground).opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Delikatny overlay dla tekstury
                Color.ksrYellow.opacity(0.02)
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    validationError != nil ?
                        LinearGradient(colors: [Color.red, Color.red.opacity(0.7)], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [Color.ksrYellow.opacity(0.4), Color.ksrYellow.opacity(0.2)], startPoint: .leading, endPoint: .trailing),
                    lineWidth: validationError != nil ? 2 : 1.5
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        .onChange(of: assignment.dailyHours) { _, newValue in
            validateHours(newValue)
        }
    }

    private func validateHours(_ dailyHours: [DailyHours]) {
        for hours in dailyHours where hours.isActive {
            if hours.start_time >= hours.end_time {
                validationError = "End time must be after start time"
                return
            }
        }
        validationError = nil
    }
}

struct WorkPlanAssignmentContent: View {
    let employeeName: String
    @Binding var notes: String
    let weekStart: Date
    @Binding var dailyHours: [DailyHours]
    let copyHoursAction: () -> Void
    let copyToOthersAction: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Employee Header - znacznie lepszy design
            HStack(spacing: 12) {
                // Gradient ikona pracownika
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.ksrYellow, Color.ksrYellow.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.ksrYellow.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("EMPLOYEE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(employeeName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            Divider()
                .overlay(Color.ksrYellow.opacity(0.3))
            
            // Notes Section z lepszym designem
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.ksrYellow)
                    
                    Text("NOTES")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                
                TextField("Add notes for this employee...", text: $notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.tertiarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.ksrYellow.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .frame(minHeight: 44)
            }
            
            // Daily Hours z bardziej kolorowym designem
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.ksrYellow)
                    
                    Text("WEEKLY SCHEDULE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                
                VStack(spacing: 8) {
                    ForEach(dailyHours.indices, id: \.self) { index in
                        let date = Calendar.current.date(byAdding: .day, value: index, to: weekStart)!
                        WorkPlanDayHoursRow(
                            date: date,
                            hours: $dailyHours[index]
                        )
                    }
                }
            }
            
            Divider()
                .overlay(Color.ksrYellow.opacity(0.3))
            
            // Action Buttons z lepszym designem
            HStack(spacing: 12) {
                Button(action: copyHoursAction) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 14, weight: .medium))
                        Text("Copy to All Days")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                
                Button(action: copyToOthersAction) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 14, weight: .medium))
                        Text("Copy to Others")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.ksrYellow, Color.ksrYellow.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: Color.ksrYellow.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                
                Spacer()
            }
        }
    }
}

struct WorkPlanDayHoursRow: View {
    let date: Date
    @Binding var hours: DailyHours
    @Environment(\.colorScheme) private var colorScheme
    @State private var localIsActive: Bool
    
    init(date: Date, hours: Binding<DailyHours>) {
        self.date = date
        self._hours = hours
        self._localIsActive = State(initialValue: hours.wrappedValue.isActive)
    }
    
    // ZABEZPIECZENIE: Sprawdź czy dzień jest w przeszłości
    private var isPastDay: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let dayDate = Calendar.current.startOfDay(for: date)
        return dayDate < today
    }
    
    // Kolory dla różnych dni
    private var dayColor: Color {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        if isPastDay {
            return .gray
        }
        
        switch weekday {
        case 2: return .blue      // Monday
        case 3: return .green     // Tuesday
        case 4: return .orange    // Wednesday
        case 5: return .purple    // Thursday
        case 6: return .pink      // Friday
        case 7: return .red       // Saturday
        case 1: return .indigo    // Sunday
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Day header - kompaktowy
            HStack(spacing: 8) {
                // Day indicator z kolorem
                HStack(spacing: 6) {
                    Circle()
                        .fill(dayColor)
                        .frame(width: 8, height: 8)
                    
                    Text(dayOfWeekName(date))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isPastDay ? .gray : .primary)
                    
                    Text(dayAndMonth(date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if isPastDay {
                    Text("Past")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    // Toggle z lepszym designem
                    Toggle("", isOn: $localIsActive)
                        .toggleStyle(SwitchToggleStyle(tint: dayColor))
                        .scaleEffect(0.8)
                        .onChange(of: localIsActive) { _, newValue in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                hours.isActive = newValue
                            }
                        }
                }
            }
            
            // Time pickers - tylko gdy aktywne
            if localIsActive && !isPastDay {
                VStack(spacing: 8) {
                    // Time pickers w poziomie - podzielone na komponenty - RESPONSIVE
                    HStack(spacing: 8) { // Zmniejszone z 12 na 8
                        // Start time picker
                        TimePickerComponent(
                            title: "FROM",
                            time: $hours.start_time,
                            color: dayColor,
                            date: date
                        )
                        .frame(maxWidth: .infinity) // Dodano flexibility
                        
                        // Separator - mniejszy
                        Image(systemName: "arrow.right")
                            .font(.caption2) // Zmniejszone z .caption
                            .foregroundColor(dayColor)
                        
                        // End time picker
                        TimePickerComponent(
                            title: "TO",
                            time: $hours.end_time,
                            color: dayColor,
                            date: date
                        )
                        .frame(maxWidth: .infinity) // Dodano flexibility
                    }
                    .padding(.horizontal, 4) // Zmniejszone z głównego container
                    
                    // Quick time buttons - bardziej kompaktowe
                    HStack(spacing: 4) { // Zmniejszone z 6 na 4
                        Button("7-15") {
                            setStandardWorkHours(start: 7, end: 15)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6) // Zmniejszone z 8 na 6
                        .padding(.vertical, 2) // Zmniejszone z 3 na 2
                        .background(dayColor.opacity(0.2))
                        .foregroundColor(dayColor)
                        .cornerRadius(4)
                        
                        Button("8-16") {
                            setStandardWorkHours(start: 8, end: 16)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(dayColor.opacity(0.2))
                        .foregroundColor(dayColor)
                        .cornerRadius(4)
                        
                        Button("6-14") {
                            setStandardWorkHours(start: 6, end: 14)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(dayColor.opacity(0.2))
                        .foregroundColor(dayColor)
                        .cornerRadius(4)
                        
                        Spacer()
                        
                        // Pokaż wybrane godziny jako tekst - mniejszy
                        Text("\(timeString(hours.start_time))-\(timeString(hours.end_time))") // Usunięto spację przed -
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(dayColor.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(dayColor.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    localIsActive && !isPastDay ?
                        dayColor.opacity(0.03) :
                        Color.clear
                )
        )
        .disabled(isPastDay)
        .onAppear {
            if isPastDay && !hours.isActive {
                localIsActive = false
                hours.isActive = false
            }
        }
    }
    
    private func dayOfWeekName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func dayAndMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"
        return formatter.string(from: date)
    }
    
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // NOWE FUNKCJE: Custom 24h time handling
    private func roundMinutesToQuarter(_ minutes: Int) -> Int {
        // Zaokrągl do najbliższego kwadransu (0, 15, 30, 45)
        if minutes < 8 {
            return 0
        } else if minutes < 23 {
            return 15
        } else if minutes < 38 {
            return 30
        } else if minutes < 53 {
            return 45
        } else {
            return 0 // Dla 53+ minut, użyj 00 (będzie w następnej godzinie przez createTime)
        }
    }
    
    private func createTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        // Jeśli minuty były > 52 i zostały zaokrąglone do 0, zwiększ godzinę
        if minute == 0 && Calendar.current.component(.minute, from: Date()) > 52 {
            components.hour = (hour + 1) % 24
        }
        
        return calendar.date(from: components) ?? date
    }
    
    private func setStandardWorkHours(start: Int, end: Int) {
        hours.start_time = createTime(hour: start, minute: 0)
        hours.end_time = createTime(hour: end, minute: 0)
    }
}

struct WorkPlanActionButtons<VM: WorkPlanViewModel>: View {
    @ObservedObject var viewModel: VM
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack {
            Spacer()
            Button("Save Draft") {
                viewModel.saveDraft()
                isPresented = false
            }
            .foregroundColor(Color.ksrYellow)
            Button("Publish") {
                viewModel.publish()
                isPresented = false
            }
            .foregroundColor(.green)
        }
    }
}

struct EmployeeCard: View {
    let employee: ManagerAPIService.Worker
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Avatar z lepszym designem
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [Color.ksrYellow, Color.ksrYellow.opacity(0.7)] :
                                [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(
                        color: isSelected ? Color.ksrYellow.opacity(0.4) : Color.gray.opacity(0.2),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
                
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(employee.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Selected")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(width: 120, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12) // Zmniejszono z 16 na 12
                .fill(
                    isSelected ?
                        LinearGradient(colors: [Color.ksrYellow.opacity(0.15), Color.ksrYellow.opacity(0.08)], startPoint: .top, endPoint: .bottom) : // Zwiększono opacity
                        LinearGradient(colors: [colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white, colorScheme == .dark ? Color(.systemGray6).opacity(0.1) : Color(.secondarySystemBackground)], startPoint: .top, endPoint: .bottom)
                )
        )
        .overlay(
            // POPRAWIONA RAMKA - bardziej widoczna
            RoundedRectangle(cornerRadius: 12) // Dopasowano do background
                .strokeBorder( // Użyj strokeBorder zamiast stroke dla lepszego wyrównania
                    isSelected ?
                        Color.ksrYellow : // Jednolity kolor zamiast gradientu
                        Color.clear, // Przezroczysta dla niewybranych
                    lineWidth: isSelected ? 3 : 0 // Zwiększono z 2 na 3
                )
        )
        .overlay(
            // DODATKOWA WEWNĘTRZNA RAMKA dla większego efektu
            isSelected ?
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        Color.ksrYellow.opacity(0.4),
                        lineWidth: 1
                    )
                    .padding(2) // Inset dla podwójnej ramki
                : nil
        )
        .shadow(
            color: isSelected ? Color.ksrYellow.opacity(0.3) : Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
            radius: isSelected ? 12 : 4, // Zwiększony shadow dla selected
            x: 0,
            y: isSelected ? 6 : 2
        )
        .scaleEffect(isSelected ? 1.05 : 1.0) // Zwiększono z 1.02 na 1.05
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// NOWY KOMPONENT: TimePickerComponent z wheel picker - RESPONSIVE
struct TimePickerComponent: View {
    let title: String
    @Binding var time: Date
    let color: Color
    let date: Date
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            HStack(spacing: 2) {
                // Hour wheel picker - mniejszy
                Picker("Hour", selection: hourBinding) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(String(format: "%02d", hour))
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 50, height: 80) // Zmniejszone z 60 na 50
                .clipped()
                
                Text(":")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                // Minute wheel picker - mniejszy
                Picker("Minute", selection: minuteBinding) {
                    ForEach([0, 15, 30, 45], id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 50, height: 80) // Zmniejszone z 60 na 50
                .clipped()
            }
            .padding(.horizontal, 8) // Zmniejszone z 12 na 8
            .padding(.vertical, 6) // Zmniejszone z 8 na 6
            .background(
                RoundedRectangle(cornerRadius: 10) // Zmniejszone z 12 na 10
                    .fill(color.opacity(0.06)) // Zmniejszone z 0.08 na 0.06
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.15), lineWidth: 1) // Zmniejszone z 0.2 i 1.5
                    )
            )
        }
    }
    
    // Separated bindings for better compilation
    private var hourBinding: Binding<Int> {
        Binding(
            get: { Calendar.current.component(.hour, from: time) },
            set: { newHour in
                let currentMinute = Calendar.current.component(.minute, from: time)
                let roundedMinute = roundMinutesToQuarter(currentMinute)
                time = createTime(hour: newHour, minute: roundedMinute)
            }
        )
    }
    
    private var minuteBinding: Binding<Int> {
        Binding(
            get: { roundMinutesToQuarter(Calendar.current.component(.minute, from: time)) },
            set: { newMinute in
                let currentHour = Calendar.current.component(.hour, from: time)
                time = createTime(hour: currentHour, minute: newMinute)
            }
        )
    }
    
    // Helper functions
    private func roundMinutesToQuarter(_ minutes: Int) -> Int {
        if minutes < 8 { return 0 }
        else if minutes < 23 { return 15 }
        else if minutes < 38 { return 30 }
        else if minutes < 53 { return 45 }
        else { return 0 }
    }
    
    private func createTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? date
    }
}
