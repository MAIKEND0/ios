//
//  WorkerWorkHoursView.swift
//  KSR Cranes App
//
//  Enhanced Worker Work Hours View with Timesheet Preview
//

import SwiftUI

// MARK: - Minimal Local Components (only what's needed)

// MARK: - Stats Card Component (local version to avoid conflicts)
struct LocalStatsCard: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Text(unit)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.ksrTextSecondary)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.ksrTextSecondary)
                .lineLimit(1)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Period Filter Chip (local version)
struct LocalPeriodFilterChip: View {
    let period: WorkerWorkHoursView.TimePeriod
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: period.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(period.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : Color.ksrTextPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.ksrPrimary : Color.ksrLightGray)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Local Work Entry Card
struct LocalWorkEntryCard: View {
    let entry: WorkerAPIService.WorkHourEntry
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: entry.work_date)
    }
    
    private var timeRange: String {
        guard let start = entry.start_time, let end = entry.end_time else {
            return "No time recorded"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    private var hoursWorked: Double {
        guard let start = entry.start_time, let end = entry.end_time else { return 0 }
        let interval = end.timeIntervalSince(start)
        let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
        return max(0, (interval - pauseSeconds) / 3600)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    if let task = entry.tasks {
                        Text(task.title)
                            .font(.caption)
                            .foregroundColor(Color.ksrTextSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Simple status badge
                HStack(spacing: 4) {
                    let statusText = getStatusText(for: entry)
                    let statusColor = getStatusColor(for: entry)
                    
                    Text(statusText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            // Time and Details
            HStack(spacing: 16) {
                // Time
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                    
                    Text(timeRange)
                        .font(.caption)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Text("(\(String(format: "%.1fh", hoursWorked)))")
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                }
                
                // Break
                if let pauseMinutes = entry.pause_minutes, pauseMinutes > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "pause.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color.ksrTextSecondary)
                        
                        Text("\(pauseMinutes)m")
                            .font(.caption)
                            .foregroundColor(Color.ksrTextPrimary)
                    }
                }
                
                // Distance
                if let km = entry.km, km > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "car.fill")
                            .font(.caption)
                            .foregroundColor(Color.ksrTextSecondary)
                        
                        Text(String(format: "%.1f km", km))
                            .font(.caption)
                            .foregroundColor(Color.ksrTextPrimary)
                    }
                }
                
                Spacer()
            }
            
            // Notes
            if let description = entry.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.ksrTextSecondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ksrLightGray)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.ksrPrimary.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Helper functions for status
    private func getStatusText(for entry: WorkerAPIService.WorkHourEntry) -> String {
        if entry.confirmation_status == "confirmed" {
            return "Confirmed"
        } else if entry.status == "submitted" {
            return "Submitted"
        } else {
            return "Draft"
        }
    }
    
    private func getStatusColor(for entry: WorkerAPIService.WorkHourEntry) -> Color {
        if entry.confirmation_status == "confirmed" {
            return Color.ksrSuccess
        } else if entry.status == "submitted" {
            return Color.purple
        } else {
            return Color.ksrWarning
        }
    }
}

// MARK: - Local Dashboard Styles
struct LocalDashboardStyles {
    static func cardBackground(colorScheme: ColorScheme) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.ksrMediumGray)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
    }
    
    static func cardStroke(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(color.opacity(0.3), lineWidth: 1)
    }
}

// MARK: - Main View

struct WorkerWorkHoursView: View {
    @StateObject private var viewModel = WorkerWorkHoursViewModel()
    @StateObject private var timesheetViewModel = WorkerTimesheetReportsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    // Filter States
    @State private var selectedPeriod: TimePeriod = .thisWeek
    @State private var selectedTaskFilter: Int = 0 // 0 = All tasks
    @State private var selectedStatusFilter: StatusFilter = .all
    @State private var searchText: String = ""
    @State private var showDatePicker = false
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    
    // UI States
    @State private var showExportOptions = false
    @State private var isRefreshing = false
    @State private var selectedTimesheet: WorkerAPIService.WorkerTimesheet?
    @State private var expandedWeeks: Set<String> = []
    
    enum TimePeriod: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"
        case lastWeek = "Last Week"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case custom = "Custom Range"
        
        var icon: String {
            switch self {
            case .today: return "sun.max"
            case .yesterday: return "moon"
            case .thisWeek: return "calendar.badge.clock"
            case .lastWeek: return "calendar"
            case .thisMonth: return "calendar.badge.plus"
            case .lastMonth: return "calendar.badge.minus"
            case .custom: return "calendar.badge.exclamationmark"
            }
        }
        
        func dateRange() -> (start: Date, end: Date) {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .today:
                let start = calendar.startOfDay(for: now)
                let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
                return (start, end)
            case .yesterday:
                let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
                let start = calendar.startOfDay(for: yesterday)
                let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
                return (start, end)
            case .thisWeek:
                let start = calendar.startOfWeek(for: now)
                let end = calendar.date(byAdding: .day, value: 7, to: start) ?? now
                return (start, end)
            case .lastWeek:
                let thisWeekStart = calendar.startOfWeek(for: now)
                let start = calendar.date(byAdding: .day, value: -7, to: thisWeekStart) ?? now
                let end = thisWeekStart
                return (start, end)
            case .thisMonth:
                let start = calendar.startOfMonth(for: now)
                let end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
                return (start, end)
            case .lastMonth:
                let thisMonthStart = calendar.startOfMonth(for: now)
                let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) ?? now
                let end = thisMonthStart
                return (start, end)
            case .custom:
                return (Date(), Date()) // Will be handled separately
            }
        }
    }
    
    enum StatusFilter: String, CaseIterable {
        case all = "All"
        case draft = "Draft"
        case pending = "Pending"
        case submitted = "Submitted"
        case confirmed = "Confirmed"
        case rejected = "Rejected"
        
        var color: Color {
            switch self {
            case .all: return .ksrPrimary
            case .draft: return .ksrWarning
            case .pending: return .ksrInfo
            case .submitted: return .purple
            case .confirmed: return .ksrSuccess
            case .rejected: return .ksrError
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Stats Overview Section
                    statsOverviewSection
                    
                    // Filters Section
                    filtersSection
                    
                    // Work Hours List Section (Weekly)
                    workHoursListSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(dashboardBackground)
            .navigationTitle("Work Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolbarButtons
                }
            }
            .onAppear {
                handleViewAppear()
            }
            .onChange(of: selectedPeriod) { _, _ in
                updateDateRangeForPeriod()
            }
            .onChange(of: selectedTaskFilter) { _, _ in
                // No need to reload entries - filtering is done locally
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showDatePicker) {
                customDatePickerSheet
            }
            .sheet(item: $selectedTimesheet) { timesheet in
                if let url = URL(string: timesheet.timesheetUrl) {
                    TimesheetPDFViewer(
                        url: url,
                        title: "Week \(timesheet.weekNumber), \(timesheet.year)",
                        onClose: { selectedTimesheet = nil }
                    )
                    .presentationDetents([.large])
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var periodDisplayText: String {
        if selectedPeriod == .custom {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(formatter.string(from: viewModel.startDate)) - \(formatter.string(from: viewModel.endDate))"
        } else {
            return selectedPeriod.rawValue
        }
    }
    
    private var taskFilterDisplayText: String {
        if selectedTaskFilter == 0 {
            return "All Tasks"
        } else if let task = viewModel.tasks.first(where: { $0.task_id == selectedTaskFilter }) {
            return task.title
        } else {
            return "Unknown Task"
        }
    }
    
    private var filteredEntries: [WorkerAPIService.WorkHourEntry] {
        var entries = viewModel.entries
        
        // Filter by task
        if selectedTaskFilter != 0 {
            entries = entries.filter { $0.task_id == selectedTaskFilter }
        }
        
        // Filter by status
        if selectedStatusFilter != .all {
            entries = entries.filter { entry in
                switch selectedStatusFilter {
                case .draft: return entry.confirmation_status != "confirmed" && entry.status != "submitted"
                case .pending: return false // Implement if you have pending logic
                case .submitted: return entry.status == "submitted" && entry.confirmation_status != "confirmed"
                case .confirmed: return entry.confirmation_status == "confirmed"
                case .rejected: return false // Implement if you have rejected logic
                case .all: return true
                }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                let searchLower = searchText.lowercased()
                return (entry.description?.lowercased().contains(searchLower) ?? false) ||
                       (entry.tasks?.title.lowercased().contains(searchLower) ?? false)
            }
        }
        
        return entries.sorted { $0.work_date > $1.work_date }
    }
    
    // Group entries by week
    private var groupedEntriesByWeek: [(key: Date, entries: [WorkerAPIService.WorkHourEntry], weekInfo: WeekInfo)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfWeek(for: entry.work_date)
        }
        
        return grouped.map { (weekStart, entries) in
            let weekNumber = calendar.component(.weekOfYear, from: weekStart)
            let year = calendar.component(.year, from: weekStart)
            let weekInfo = WeekInfo(weekNumber: weekNumber, year: year, startDate: weekStart)
            return (weekStart, entries.sorted { $0.work_date < $1.work_date }, weekInfo)
        }.sorted { $0.key > $1.key }
    }
    
    private var totalHoursInPeriod: Double {
        filteredEntries.reduce(0.0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
    }
    
    private var totalKmInPeriod: Double {
        filteredEntries.reduce(0.0) { sum, entry in
            sum + (entry.km ?? 0.0)
        }
    }
    
    private var uniqueWorkDays: Int {
        Set(filteredEntries.map { Calendar.current.startOfDay(for: $0.work_date) }).count
    }
    
    private var averageHoursPerDay: Double {
        guard uniqueWorkDays > 0 else { return 0 }
        return totalHoursInPeriod / Double(uniqueWorkDays)
    }
    
    // MARK: - Stats Overview Section
    private var statsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Overview")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Spacer()
                
                Text(periodDisplayText)
                    .font(.caption)
                    .foregroundColor(Color.ksrTextSecondary)
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                LocalStatsCard(
                    title: "Total Hours",
                    value: totalHoursInPeriod,
                    unit: "hrs",
                    icon: "clock.fill",
                    color: Color.ksrSuccess
                )
                
                LocalStatsCard(
                    title: "Total Distance",
                    value: totalKmInPeriod,
                    unit: "km",
                    icon: "car.fill",
                    color: Color.ksrInfo
                )
                
                LocalStatsCard(
                    title: "Work Days",
                    value: Double(uniqueWorkDays),
                    unit: "days",
                    icon: "calendar.badge.clock",
                    color: Color.ksrWarning
                )
                
                LocalStatsCard(
                    title: "Avg/Day",
                    value: averageHoursPerDay,
                    unit: "hrs",
                    icon: "chart.bar.fill",
                    color: Color.ksrPrimary
                )
            }
        }
        .padding(20)
        .background(LocalDashboardStyles.cardBackground(colorScheme: colorScheme))
        .overlay(LocalDashboardStyles.cardStroke(Color.ksrPrimary))
    }
    
    // MARK: - Filters Section
    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Filters")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Spacer()
                
                Button {
                    resetFilters()
                } label: {
                    Text("Reset")
                        .font(.caption)
                        .foregroundColor(Color.ksrYellow)
                }
            }
            .padding(.horizontal, 4)
            
            // Period Filter
            periodFilterSection
            
            // Task and Status Filters
            HStack(spacing: 12) {
                taskFilterSection
                statusFilterSection
            }
            
            // Search Bar
            searchBarSection
        }
        .padding(20)
        .background(LocalDashboardStyles.cardBackground(colorScheme: colorScheme))
        .overlay(LocalDashboardStyles.cardStroke(Color.ksrInfo))
    }
    
    // MARK: - Period Filter
    private var periodFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Period")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.ksrTextSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        LocalPeriodFilterChip(
                            period: period,
                            isSelected: selectedPeriod == period,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedPeriod = period
                                    if period == .custom {
                                        showDatePicker = true
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Task Filter
    private var taskFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Task")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.ksrTextSecondary)
            
            Menu {
                Button("All Tasks") {
                    selectedTaskFilter = 0
                }
                
                ForEach(viewModel.tasks, id: \.task_id) { task in
                    Button(task.title) {
                        selectedTaskFilter = task.task_id
                    }
                }
            } label: {
                HStack {
                    Text(taskFilterDisplayText)
                        .font(.subheadline)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.ksrLightGray)
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Status Filter
    private var statusFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.ksrTextSecondary)
            
            Menu {
                ForEach(StatusFilter.allCases, id: \.self) { status in
                    Button {
                        selectedStatusFilter = status
                    } label: {
                        Label(status.rawValue, systemImage: status == selectedStatusFilter ? "checkmark" : "")
                    }
                }
            } label: {
                HStack {
                    Text(selectedStatusFilter.rawValue)
                        .font(.subheadline)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Spacer()
                    
                    Circle()
                        .fill(selectedStatusFilter.color)
                        .frame(width: 8, height: 8)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.ksrLightGray)
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Search Bar
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.ksrTextSecondary)
            
            TextField("Search notes, tasks...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(Color.ksrTextPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.ksrLightGray)
        )
    }
    
    // MARK: - Work Hours List Section (Weekly)
    private var workHoursListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Work Entries")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Spacer()
                
                Text("\(filteredEntries.count) entries")
                    .font(.caption)
                    .foregroundColor(Color.ksrTextSecondary)
            }
            .padding(.horizontal, 4)
            
            if viewModel.isLoading && !isRefreshing {
                loadingView
            } else if filteredEntries.isEmpty {
                emptyStateView
            } else {
                weeklyEntriesList
            }
        }
        .padding(20)
        .background(LocalDashboardStyles.cardBackground(colorScheme: colorScheme))
        .overlay(LocalDashboardStyles.cardStroke(Color.ksrSuccess))
    }
    
    // MARK: - Weekly Entries List
    private var weeklyEntriesList: some View {
        LazyVStack(spacing: 16) {
            ForEach(groupedEntriesByWeek, id: \.key) { weekData in
                WeeklyWorkHoursCard(
                    weekInfo: weekData.weekInfo,
                    entries: weekData.entries,
                    isExpanded: expandedWeeks.contains(weekData.weekInfo.id),
                    hasTimesheet: hasTimesheetForWeek(weekData.weekInfo),
                    onToggleExpand: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if expandedWeeks.contains(weekData.weekInfo.id) {
                                expandedWeeks.remove(weekData.weekInfo.id)
                            } else {
                                expandedWeeks.insert(weekData.weekInfo.id)
                            }
                        }
                    },
                    onViewTimesheet: {
                        viewTimesheetForWeek(weekData.weekInfo, taskId: selectedTaskFilter)
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func hasTimesheetForWeek(_ weekInfo: WeekInfo) -> Bool {
        // Check if there's a confirmed timesheet for this week
        return timesheetViewModel.timesheets.contains { timesheet in
            timesheet.weekNumber == weekInfo.weekNumber &&
            timesheet.year == weekInfo.year &&
            (selectedTaskFilter == 0 || timesheet.task_id == selectedTaskFilter)
        }
    }
    
    private func viewTimesheetForWeek(_ weekInfo: WeekInfo, taskId: Int) {
        // Find timesheet for this week and task
        if let timesheet = timesheetViewModel.timesheets.first(where: { ts in
            ts.weekNumber == weekInfo.weekNumber &&
            ts.year == weekInfo.year &&
            (taskId == 0 || ts.task_id == taskId)
        }) {
            selectedTimesheet = timesheet
        } else {
            // Show message that no timesheet is available
            viewModel.showAlert = true
            viewModel.alertTitle = "No Timesheet Available"
            viewModel.alertMessage = "No confirmed timesheet found for week \(weekInfo.weekNumber), \(weekInfo.year)"
        }
    }
    
    // MARK: - Other UI Components
    private var toolbarButtons: some View {
        HStack(spacing: 12) {
            // Refresh button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isRefreshing = true
                    viewModel.loadEntries()
                    timesheetViewModel.loadData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isRefreshing = false
                    }
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(viewModel.isLoading ? .gray : Color.ksrPrimary)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(.linear(duration: 1.0).repeatCount(isRefreshing ? 10 : 0), value: isRefreshing)
            }
            .disabled(viewModel.isLoading)
            
            // Timesheets button
            NavigationLink(destination: WorkerTimesheetReportsView()) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(Color.ksrYellow)
            }
            
            // Export button
            Button {
                showExportOptions = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Color.ksrInfo)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.ksrPrimary)
            
            Text("Loading work hours...")
                .font(.subheadline)
                .foregroundColor(Color.ksrTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Color.ksrTextSecondary)
            
            VStack(spacing: 8) {
                Text("No work entries found")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Text("Try adjusting your filters or check the Dashboard to add work hours")
                    .font(.subheadline)
                    .foregroundColor(Color.ksrTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.vertical, 40)
    }
    
    private var customDatePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showDatePicker = false
                        selectedPeriod = .thisWeek
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showDatePicker = false
                        updateDateRangeForCustomPeriod()
                    }
                }
            }
        }
        .presentationDetents([.height(300)])
    }
    
    private var dashboardBackground: some View {
        Color.backgroundGradient
            .ignoresSafeArea()
    }
    
    private func handleViewAppear() {
        viewModel.loadTasks()
        timesheetViewModel.loadData()
        updateDateRangeForPeriod()
    }
    
    private func updateDateRangeForPeriod() {
        guard selectedPeriod != .custom else { return }
        
        let range = selectedPeriod.dateRange()
        viewModel.loadEntries(startDate: range.start, endDate: range.end)
    }
    
    private func updateDateRangeForCustomPeriod() {
        viewModel.loadEntries(startDate: customStartDate, endDate: customEndDate)
    }
    
    private func resetFilters() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedPeriod = .thisWeek
            selectedTaskFilter = 0
            selectedStatusFilter = .all
            searchText = ""
            updateDateRangeForPeriod()
        }
    }
    
    private func refreshData() async {
        await withCheckedContinuation { continuation in
            viewModel.loadEntries()
            timesheetViewModel.loadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
}

// MARK: - Week Info Structure
struct WeekInfo: Identifiable {
    let id: String
    let weekNumber: Int
    let year: Int
    let startDate: Date
    
    init(weekNumber: Int, year: Int, startDate: Date) {
        self.id = "\(year)-\(weekNumber)"
        self.weekNumber = weekNumber
        self.year = year
        self.startDate = startDate
    }
    
    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: startDate) ?? startDate
    }
    
    var displayTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        return "\(start) - \(end)"
    }
}

// MARK: - Weekly Work Hours Card
struct WeeklyWorkHoursCard: View {
    let weekInfo: WeekInfo
    let entries: [WorkerAPIService.WorkHourEntry]
    let isExpanded: Bool
    let hasTimesheet: Bool
    let onToggleExpand: () -> Void
    let onViewTimesheet: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var totalHours: Double {
        entries.reduce(0.0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
    }
    
    private var totalKm: Double {
        entries.reduce(0.0) { sum, entry in
            sum + (entry.km ?? 0.0)
        }
    }
    
    private var workDays: Int {
        Set(entries.map { Calendar.current.startOfDay(for: $0.work_date) }).count
    }
    
    private var confirmedCount: Int {
        entries.filter { $0.confirmation_status == "confirmed" }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    
                    expandedContent
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ksrMediumGray)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.ksrPrimary.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Week Title and Stats
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Week \(weekInfo.weekNumber), \(weekInfo.year)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Text(weekInfo.displayTitle)
                        .font(.subheadline)
                        .foregroundColor(Color.ksrTextSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1fh", totalHours))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrSuccess)
                    
                    HStack(spacing: 8) {
                        if workDays > 0 {
                            Label("\(workDays) days", systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(Color.ksrTextSecondary)
                        }
                        
                        Button {
                            onToggleExpand()
                        } label: {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.ksrTextSecondary)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(Color.ksrLightGray)
                                )
                        }
                    }
                }
            }
            
            // Quick Stats Row
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color.ksrSuccess)
                    
                    Text("\(confirmedCount) confirmed")
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                }
                
                if totalKm > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "car.fill")
                            .font(.caption)
                            .foregroundColor(Color.ksrInfo)
                        
                        Text(String(format: "%.1f km", totalKm))
                            .font(.caption)
                            .foregroundColor(Color.ksrTextSecondary)
                    }
                }
                
                Spacer()
                
                // Timesheet Preview Button
                if hasTimesheet && confirmedCount > 0 {
                    Button {
                        onViewTimesheet()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 12, weight: .medium))
                            
                            Text("Timesheet")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.ksrYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(20)
    }
    
    private var expandedContent: some View {
        VStack(spacing: 12) {
            ForEach(entries.sorted(by: { $0.work_date < $1.work_date }), id: \.entry_id) { entry in
                LocalWorkEntryCard(entry: entry)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Preview
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
