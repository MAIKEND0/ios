import SwiftUI

// Component displaying the worker's work hours
struct WorkerWorkHoursView: View {
    @StateObject private var viewModel = WorkerWorkHoursViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    // State for date picker
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedWeekIndex: Int = 0
    @State private var availableWeeks: [WeekOption] = []
    
    // Helper struct to represent a week option in the picker
    struct WeekOption: Identifiable {
        let id = UUID()
        let index: Int
        let weekNumber: Int
        let startDate: Date
        let endDate: Date
        
        var label: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: startDate)
            let end = formatter.string(from: endDate)
            return "Week \(weekNumber) (\(start)–\(end))"
        }
    }
    
    // Initialize the state with the current year and month
    init() {
        let calendar = Calendar.current
        let currentDate = Date()
        _selectedYear = State(initialValue: calendar.component(.year, from: currentDate))
        _selectedMonth = State(initialValue: calendar.component(.month, from: currentDate))
        _viewModel = StateObject(wrappedValue: WorkerWorkHoursViewModel())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // --- Date Picker Navigation ---
                VStack(spacing: 12) {
                    // Year and Month Pickers
                    HStack {
                        // Year Picker
                        Picker("Year", selection: $selectedYear) {
                            ForEach((2020...2030), id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // Month Picker
                        Picker("Month", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(DateFormatter().monthSymbols[month - 1]).tag(month)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Week Picker
                    Picker("Week", selection: $selectedWeekIndex) {
                        ForEach(availableWeeks.indices, id: \.self) { index in
                            Text(availableWeeks[index].label).tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                Divider()
                    .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))

                // --- Content ---
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(
                                Text("Loading…")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                            )
                    } else if let err = viewModel.errorMessage {
                        Text(err)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.entries.isEmpty {
                        Text("No entries for this week")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(viewModel.entries) { entry in
                            workHourRow(entry: entry)
                        }
                        .listStyle(.plain)
                        .refreshable {
                            viewModel.loadEntries()
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .navigationTitle("Work Hours")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.loadEntries() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(viewModel.isLoading ? .gray : .blue)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear {
                updateAvailableWeeks()
                updateWeekStart()
                viewModel.loadEntries()
            }
            .onChange(of: selectedYear) { _ in
                updateAvailableWeeks()
                updateWeekStart()
            }
            .onChange(of: selectedMonth) { _ in
                updateAvailableWeeks()
                updateWeekStart()
            }
            .onChange(of: selectedWeekIndex) { _ in
                updateWeekStart()
            }
        }
    }

    // Row for each work hour entry
    private func workHourRow(entry: APIService.WorkHourEntry) -> some View {
        let status = effectiveStatus(for: entry)
        let (statusLabel, statusColor) = statusLabel(for: status)

        return HStack(alignment: .center, spacing: 0) {
            // Date
            Text(formatDate(entry.work_date))
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .frame(width: 100, alignment: .leading)

            // Time Range
            Text("\(entry.startTimeFormatted ?? "-") – \(entry.endTimeFormatted ?? "-")")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .center)

            Spacer()

            // Status
            Text(statusLabel)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color.white)
        .cornerRadius(8)
        .padding(.horizontal)
    }

    // Function to determine the effective status for an entry
    private func effectiveStatus(for entry: APIService.WorkHourEntry) -> EntryStatus {
        if let confirmationStatus = entry.confirmation_status, confirmationStatus != "pending" {
            switch confirmationStatus {
            case "confirmed":
                return .confirmed
            case "rejected":
                return .rejected
            default:
                break
            }
        }

        if entry.is_draft == true {
            return .draft
        }

        if let status = entry.status {
            switch status {
            case "submitted":
                return .submitted
            case "pending":
                return .pending
            default:
                break
            }
        }

        return .pending
    }

    // Helper function to determine label and color for status
    private func statusLabel(for status: EntryStatus) -> (String, Color) {
        switch status {
        case .draft:
            return ("Draft", .orange)
        case .pending:
            return ("Pending", .blue)
        case .submitted:
            return ("Submitted", .purple)
        case .confirmed:
            return ("Confirmed", .green)
        case .rejected:
            return ("Rejected", .red)
        }
    }

    // Format the date for each entry
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, E" // e.g., "May 12, Mon"
        return formatter.string(from: date)
    }

    // Calculate available weeks for the selected year and month
    private func updateAvailableWeeks() {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday as the first day (ISO 8601)
        calendar.minimumDaysInFirstWeek = 4 // ISO 8601 standard

        // Create a date for the first day of the selected month and year
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        guard let firstDayOfMonth = calendar.date(from: components) else {
            availableWeeks = []
            selectedWeekIndex = 0
            return
        }

        // Find the last day of the month
        guard let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth),
              let lastDayOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: firstDayOfMonth) else {
            availableWeeks = []
            selectedWeekIndex = 0
            return
        }

        // Find the first Monday on or before the first day of the month
        var currentDate = firstDayOfMonth
        while calendar.component(.weekday, from: currentDate) != 2 { // Monday
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }

        // Generate weeks until we pass the last day of the month
        var weeks: [WeekOption] = []
        var index = 0
        while currentDate <= lastDayOfMonth {
            let weekNumber = calendar.component(.weekOfYear, from: currentDate)
            let weekStart = currentDate
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            
            // Only include weeks that have at least one day in the selected month
            if weekEnd >= firstDayOfMonth && weekStart <= lastDayOfMonth {
                weeks.append(WeekOption(index: index, weekNumber: weekNumber, startDate: weekStart, endDate: weekEnd))
                index += 1
            }
            
            // Move to the next Monday
            currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate)!
        }

        availableWeeks = weeks

        // Ensure selectedWeekIndex is valid
        if availableWeeks.isEmpty {
            selectedWeekIndex = 0
        } else if selectedWeekIndex >= availableWeeks.count {
            selectedWeekIndex = availableWeeks.count - 1
        }

        // If this is the current month, try to select the current week
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        if selectedYear == currentYear && selectedMonth == currentMonth {
            let currentWeekNumber = calendar.component(.weekOfYear, from: today)
            if let currentWeekIndex = availableWeeks.firstIndex(where: { $0.weekNumber == currentWeekNumber }) {
                selectedWeekIndex = currentWeekIndex
            }
        }
    }

    // Update viewModel.weekStart based on the selected week
    private func updateWeekStart() {
        guard !availableWeeks.isEmpty, selectedWeekIndex < availableWeeks.count else {
            // Default to the current week's Monday if no weeks are available
            var calendar = Calendar.current
            calendar.firstWeekday = 2
            calendar.minimumDaysInFirstWeek = 4
            let today = Date()
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            components.weekday = 2 // Monday
            viewModel.weekStart = calendar.date(from: components) ?? today
            viewModel.loadEntries()
            return
        }

        viewModel.weekStart = availableWeeks[selectedWeekIndex].startDate
        viewModel.loadEntries()
    }
}

struct WorkerWorkHoursView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WorkerWorkHoursView()
                .preferredColorScheme(.light)
            
            WorkerWorkHoursView()
                .preferredColorScheme(.dark)
        }
    }
}
