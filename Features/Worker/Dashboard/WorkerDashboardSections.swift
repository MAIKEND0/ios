//
//  WorkerDashboardSections.swift
//  KSR Cranes App
//
//  Enhanced Worker Dashboard Sections with Manager Dashboard styling
//

import SwiftUI

// MARK: - Enhanced WorkerDashboardSections
struct WorkerDashboardSections {
    
    // MARK: - Consistent Card Style
    static func cardBackground(colorScheme: ColorScheme) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.ksrMediumGray)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
    }
    
    static func cardStroke(_ color: Color = Color.gray, opacity: Double = 0.2) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(color.opacity(opacity), lineWidth: 1)
    }
    
    // MARK: - Summary Cards Section
    struct SummaryCardsSection: View {
        @ObservedObject var viewModel: WorkerDashboardViewModel
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Stats")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
                    .padding(.horizontal, 4)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    EnhancedSummaryCard(
                        title: "Hours This Week",
                        value: String(format: "%.1f", viewModel.totalWeeklyHours),
                        unit: "hrs",
                        icon: "clock.fill",
                        gradient: DashboardGradients.success
                    )
                    
                    EnhancedSummaryCard(
                        title: "Km This Month",
                        value: viewModel.totalMonthlyKm > 0 ? String(format: "%.1f", viewModel.totalMonthlyKm) : "0.0",
                        unit: "km",
                        icon: "car.fill",
                        gradient: DashboardGradients.info
                    )
                    .onReceive(viewModel.hoursViewModel.$entries) { entries in
                        #if DEBUG
                        print("[WorkerDashboard] Entries updated: \(entries.count)")
                        let thisWeekEntries = entries.filter { Calendar.current.isDate($0.work_date, equalTo: Date(), toGranularity: .weekOfYear) }
                        let weeklyKm = thisWeekEntries.reduce(0.0) { $0 + ($1.km ?? 0.0) }
                        print("[WorkerDashboard] This week entries: \(thisWeekEntries.count), Weekly km: \(weeklyKm)")
                        print("[WorkerDashboard] ViewModel totalWeeklyKm: \(viewModel.totalWeeklyKm)")
                        #endif
                    }
                    
                    EnhancedSummaryCard(
                        title: "Hours This Month",
                        value: String(format: "%.1f", viewModel.totalMonthlyHours),
                        unit: "hrs",
                        icon: "calendar.badge.clock",
                        gradient: DashboardGradients.warning
                    )
                    
                    EnhancedSummaryCard(
                        title: "Active Tasks",
                        value: "\(viewModel.tasksViewModel.tasks.count)",
                        unit: "tasks",
                        icon: "briefcase.fill",
                        gradient: DashboardGradients.primary
                    )
                }
            }
        }
    }
    
    // MARK: - Enhanced Summary Card
    struct EnhancedSummaryCard: View {
        let title: String
        let value: String
        let unit: String
        let icon: String
        let gradient: LinearGradient
        @State private var isAnimated = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 4) {
                        AnimatedCounter(value: Double(value) ?? 0, format: "%.1f")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .onAppear {
                                #if DEBUG
                                let parsedValue = Double(value) ?? 0
                                print("[EnhancedSummaryCard] \(title) - String value: '\(value)', Parsed: \(parsedValue)")
                                #endif
                            }
                        
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, 2)
                    }
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
            }
            .padding(16)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(isAnimated ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimated)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                    isAnimated = true
                }
            }
        }
    }
    
    // MARK: - Tasks Section
    struct TasksSection: View {
        @ObservedObject var viewModel: WorkerDashboardViewModel
        let onTaskSelected: (Int) -> Void
        @Environment(\.colorScheme) private var colorScheme
        @State private var selectedSortOption: TaskSortOption = .name
        
        enum TaskSortOption: String, CaseIterable {
            case name = "Name"
            case hours = "Hours Logged"
            case recent = "Recent Activity"
            
            var icon: String {
                switch self {
                case .name: return "textformat.abc"
                case .hours: return "clock"
                case .recent: return "calendar"
                }
            }
        }
        
        private var sortedTasks: [WorkerAPIService.Task] {
            let tasks = viewModel.tasksViewModel.tasks
            switch selectedSortOption {
            case .name:
                return tasks.sorted { $0.title < $1.title }
            case .hours:
                return tasks.sorted { task1, task2 in
                    let hours1 = calculateTaskHours(for: task1)
                    let hours2 = calculateTaskHours(for: task2)
                    return hours1 > hours2
                }
            case .recent:
                return tasks.sorted { task1, task2 in
                    let recent1 = getMostRecentActivity(for: task1)
                    let recent2 = getMostRecentActivity(for: task2)
                    return recent1 > recent2
                }
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                tasksHeader
                
                // Controls
                tasksControls
                
                // Content
                tasksContent
            }
            .padding(20)
            .background(cardBackground(colorScheme: colorScheme))
            .overlay(cardStroke(Color.ksrPrimary))
        }
        
        // MARK: - Header
        private var tasksHeader: some View {
            HStack(spacing: 12) {
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.ksrPrimary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Tasks")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Text("\(viewModel.tasksViewModel.tasks.count) tasks assigned")
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                }
                
                Spacer()
                
                // Stats badge
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("This Week")
                            .font(.caption2)
                            .foregroundColor(Color.ksrTextSecondary)
                        
                        Text(String(format: "%.1fh", viewModel.totalWeeklyHours))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.ksrSuccess)
                    }
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.ksrSuccess)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.ksrLightGray)
                )
            }
        }
        
        // MARK: - Controls
        private var tasksControls: some View {
            HStack {
                // Sort picker
                Menu {
                    ForEach(TaskSortOption.allCases, id: \.self) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSortOption = option
                            }
                        } label: {
                            Label(option.rawValue, systemImage: option.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text("Sort by \(selectedSortOption.rawValue)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color.ksrTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.ksrLightGray)
                    )
                }
                
                Spacer()
                
                // Refresh button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.tasksViewModel.loadTasks()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.ksrPrimary)
                }
                .disabled(viewModel.tasksViewModel.isLoading)
            }
        }
        
        // MARK: - Content
        private var tasksContent: some View {
            Group {
                if viewModel.tasksViewModel.isLoading {
                    TasksLoadingView()
                } else if viewModel.tasksViewModel.tasks.isEmpty {
                    TasksEmptyStateView()
                } else {
                    tasksListView
                }
            }
        }
        
        // MARK: - List View
        private var tasksListView: some View {
            LazyVStack(spacing: 16) {
                ForEach(sortedTasks, id: \.task_id) { task in
                    EnhancedTaskCard(
                        task: task,
                        viewModel: viewModel,
                        onTaskSelected: onTaskSelected
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: sortedTasks.count)
        }
        
        // MARK: - Helper Methods
        private func calculateTaskHours(for task: WorkerAPIService.Task) -> Double {
            let taskEntries = viewModel.hoursViewModel.entries.filter { $0.task_id == task.task_id }
            return taskEntries.reduce(0.0) { sum, entry in
                guard let start = entry.start_time, let end = entry.end_time else { return sum }
                let interval = end.timeIntervalSince(start)
                let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                return sum + max(0, (interval - pauseSeconds) / 3600)
            }
        }
        
        private func getMostRecentActivity(for task: WorkerAPIService.Task) -> Date {
            let taskEntries = viewModel.hoursViewModel.entries.filter { $0.task_id == task.task_id }
            return taskEntries.map { $0.work_date }.max() ?? Date.distantPast
        }
    }
    
    // MARK: - Enhanced Task Card
    struct EnhancedTaskCard: View {
        let task: WorkerAPIService.Task
        let viewModel: WorkerDashboardViewModel
        let onTaskSelected: (Int) -> Void
        @Environment(\.colorScheme) private var colorScheme
        @State private var isExpanded = false
        
        private var taskEntries: [WorkerAPIService.WorkHourEntry] {
            viewModel.hoursViewModel.entries.filter { $0.task_id == task.task_id }
        }
        
        private var totalHours: Double {
            taskEntries.reduce(0.0) { sum, entry in
                guard let start = entry.start_time, let end = entry.end_time else { return sum }
                let interval = end.timeIntervalSince(start)
                let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                return sum + max(0, (interval - pauseSeconds) / 3600)
            }
        }
        
        private var totalKm: Double {
            taskEntries.reduce(0.0) { sum, entry in
                sum + (entry.km ?? 0.0)
            }
        }
        
        private var weekStatuses: [WeekStatus] {
            getWeekStatuses(for: task.task_id, entries: taskEntries, count: 4)
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Main Header
                mainHeader
                
                // Expandable Details
                if isExpanded {
                    expandedContent
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                }
                
                // Action Footer
                actionFooter
            }
            .background(cardBackground(colorScheme: colorScheme))
            .overlay(
                cardStroke(Color.ksrPrimary, opacity: 0.3)
            )
        }
        
        // MARK: - Main Header
        private var mainHeader: some View {
            HStack(spacing: 16) {
                // Task icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.ksrPrimary,
                                    Color.ksrPrimary.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrTextPrimary)
                        .lineLimit(1)
                    
                    if let project = task.project {
                        Label(project.title, systemImage: "building.2")
                            .font(.subheadline)
                            .foregroundColor(Color.ksrTextSecondary)
                            .lineLimit(1)
                    }
                    
                    // Status row
                    HStack(spacing: 12) {
                        StatusChip(
                            text: String(format: "%.1fh logged", totalHours),
                            color: Color.ksrSuccess
                        )
                        
                        if totalKm > 0 {
                            StatusChip(
                                text: String(format: "%.1fkm", totalKm),
                                color: Color.ksrInfo
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Expand button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.ksrTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.ksrLightGray)
                        )
                }
            }
            .padding(20)
        }
        
        // MARK: - Expanded Content
        private var expandedContent: some View {
            VStack(alignment: .leading, spacing: 16) {
                Divider()
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Description
                    if let description = task.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.ksrTextSecondary)
                            
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(Color.ksrTextPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Week History
                    if !weekStatuses.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Activity")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.ksrTextSecondary)
                            
                            ForEach(weekStatuses.prefix(3)) { weekStatus in
                                WeekStatusRow(weekStatus: weekStatus)
                            }
                            
                            if weekStatuses.count > 3 {
                                Text("and \(weekStatuses.count - 3) more weeks...")
                                    .font(.caption)
                                    .foregroundColor(Color.ksrTextSecondary)
                                    .italic()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        
        // MARK: - Action Footer
        private var actionFooter: some View {
            HStack {
                Spacer()
                
                Button {
                    onTaskSelected(task.task_id)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text("Log Hours")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.trailing, 20)
                .padding(.bottom, 12)
            }
        }
    }
    
    // MARK: - Recent Hours Section
    struct RecentHoursSection: View {
        @ObservedObject var viewModel: WorkerDashboardViewModel
        let onAddHours: () -> Void
        let onViewAll: () -> Void
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Recent Hours")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Spacer()
                    
                    Button("View All", action: onViewAll)
                        .font(.caption)
                        .foregroundColor(Color.ksrYellow)
                }
                .padding(.horizontal, 4)
                
                // Content
                recentHoursContent
                
                // Add Hours Button
                Button {
                    onAddHours()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Add Hours")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.ksrYellow)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
            .background(cardBackground(colorScheme: colorScheme))
            .overlay(cardStroke(Color.ksrSuccess))
        }
        
        private var recentHoursContent: some View {
            Group {
                if viewModel.hoursViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else if viewModel.hoursViewModel.entries.isEmpty {
                    EmptyHoursView()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.hoursViewModel.entries.prefix(3)) { entry in
                            EnhancedWorkHourCard(entry: entry)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Work Hour Card
    struct EnhancedWorkHourCard: View {
        let entry: WorkerAPIService.WorkHourEntry
        @Environment(\.colorScheme) private var colorScheme
        
        private var hours: Double {
            guard let start = entry.start_time, let end = entry.end_time else { return 0 }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return max(0, (interval - pauseSeconds) / 3600)
        }
        
        private var entryStatus: EntryStatus {
            effectiveStatus(for: entry)
        }
        
        private var statusColor: Color {
            switch entryStatus {
            case .draft: return .orange
            case .pending: return .blue
            case .submitted: return .purple
            case .confirmed: return .green
            case .rejected: return .red
            }
        }
        
        var body: some View {
            HStack(spacing: 16) {
                // Status indicator
                VStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                    
                    Rectangle()
                        .fill(statusColor.opacity(0.3))
                        .frame(width: 2)
                        .layoutPriority(-1)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.workDateFormatted)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.ksrTextPrimary)
                        
                        Spacer()
                        
                        Text(String(format: "%.1fh", hours))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.ksrYellow)
                    }
                    
                    HStack {
                        Text("\(entry.startTimeFormatted ?? "-") – \(entry.endTimeFormatted ?? "-")")
                            .font(.caption)
                            .foregroundColor(Color.ksrTextSecondary)
                        
                        Spacer()
                        
                        StatusChip(
                            text: entryStatus.rawValue.capitalized,
                            color: statusColor
                        )
                    }
                    
                    if let taskTitle = entry.tasks?.title {
                        Text("Task: \(taskTitle)")
                            .font(.caption2)
                            .foregroundColor(Color.ksrTextSecondary)
                    }
                    
                    if let km = entry.km, km > 0 {
                        Text("Distance: \(String(format: "%.1f", km)) km")
                            .font(.caption2)
                            .foregroundColor(Color.ksrTextSecondary)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.ksrLightGray)
            )
        }
    }
    
    // MARK: - Announcements Section
    struct AnnouncementsSection: View {
        @ObservedObject var viewModel: WorkerDashboardViewModel
        let onViewAll: () -> Void
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Announcements")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Spacer()
                    
                    Button("View All", action: onViewAll)
                        .font(.caption)
                        .foregroundColor(Color.ksrYellow)
                }
                .padding(.horizontal, 4)
                
                // Content
                announcementsContent
            }
            .padding(20)
            .background(cardBackground(colorScheme: colorScheme))
            .overlay(cardStroke(Color.ksrWarning))
        }
        
        private var announcementsContent: some View {
            Group {
                if viewModel.isLoadingAnnouncements {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else if viewModel.announcements.isEmpty {
                    EmptyAnnouncementsView()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.announcements.prefix(3)) { announcement in
                            EnhancedAnnouncementCard(announcement: announcement)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Announcement Card
    struct EnhancedAnnouncementCard: View {
        let announcement: WorkerAPIService.Announcement
        @Environment(\.colorScheme) private var colorScheme
        
        private var priorityColor: Color {
            switch announcement.priority {
            case .high: return .red
            case .normal: return .blue
            case .low: return .gray
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(announcement.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.ksrTextPrimary)
                            .lineLimit(1)
                        
                        Text(announcement.content)
                            .font(.caption)
                            .foregroundColor(Color.ksrTextSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    StatusChip(
                        text: announcement.priority.rawValue.capitalized,
                        color: priorityColor
                    )
                }
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(Color.ksrTextSecondary)
                        
                        Text(formatDate(announcement.publishedAt))
                            .font(.caption2)
                            .foregroundColor(Color.ksrTextSecondary)
                    }
                    
                    Spacer()
                    
                    if let expiresAt = announcement.expiresAt {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            
                            Text("Expires: \(formatDate(expiresAt))")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.ksrLightGray)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(priorityColor.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Supporting Components
    struct StatusChip: View {
        let text: String
        let color: Color
        
        var body: some View {
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    struct WeekStatusRow: View {
        let weekStatus: WeekStatus
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            HStack {
                Text(weekStatus.weekLabel)
                    .font(.caption)
                    .foregroundColor(Color.ksrTextPrimary)
                    .frame(width: 70, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1fh", weekStatus.hours))
                        .font(.caption)
                        .foregroundColor(Color.ksrSuccess)
                    
                    if weekStatus.km > 0 {
                        Text(String(format: "%.1fkm", weekStatus.km))
                            .font(.caption)
                            .foregroundColor(Color.ksrInfo)
                    }
                }
                .frame(width: 60, alignment: .leading)
                
                Spacer()
                
                HStack(spacing: 4) {
                    weekStatus.statusIcon.0
                        .foregroundColor(weekStatus.statusIcon.1)
                        .font(.caption)
                    
                    Text(weekStatus.status.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(weekStatus.statusIcon.1)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    struct TasksLoadingView: View {
        var body: some View {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Loading tasks...")
                    .font(.subheadline)
                    .foregroundColor(Color.ksrTextSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        }
    }
    
    struct TasksEmptyStateView: View {
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "briefcase")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color.ksrTextSecondary)
                
                VStack(spacing: 8) {
                    Text("No tasks assigned")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Text("When tasks are assigned to you, they will appear here")
                        .font(.subheadline)
                        .foregroundColor(Color.ksrTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .padding(.vertical, 40)
        }
    }
    
    struct EmptyHoursView: View {
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "clock")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color.ksrTextSecondary)
                
                Text("No hours recorded yet")
                    .font(.subheadline)
                    .foregroundColor(Color.ksrTextSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 20)
        }
    }
    
    struct EmptyAnnouncementsView: View {
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "megaphone")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color.ksrTextSecondary)
                
                Text("No announcements")
                    .font(.subheadline)
                    .foregroundColor(Color.ksrTextSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Gradient Definitions
struct DashboardGradients {
    static let primary = LinearGradient(
        colors: [Color.ksrPrimary, Color.ksrYellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let success = LinearGradient(
        colors: [Color.ksrSuccess, Color.ksrSuccess.darker(by: 0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let info = LinearGradient(
        colors: [Color.ksrInfo, Color.ksrInfo.darker(by: 0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warning = LinearGradient(
        colors: [Color.ksrWarning, Color.ksrWarning.darker(by: 0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Helper Functions
private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

private func getWeekStatuses(for taskId: Int, entries: [WorkerAPIService.WorkHourEntry], count: Int) -> [WeekStatus] {
    var statuses: [WeekStatus] = []
    let calendar = Calendar.current
    let currentDate = Date()
    
    for i in 0..<count {
        var dateComponents = DateComponents()
        dateComponents.weekOfYear = -i
        guard let weekDate = calendar.date(byAdding: dateComponents, to: currentDate) else {
            continue
        }
        
        let weekNumber = calendar.component(.weekOfYear, from: weekDate)
        let year = calendar.component(.year, from: weekDate)
        
        let weekEntries = entries.filter { entry in
            guard entry.task_id == taskId,
                  let startTime = entry.start_time else { return false }
            return calendar.component(.weekOfYear, from: startTime) == weekNumber &&
                   calendar.component(.year, from: startTime) == year
        }
        
        let weekHours = weekEntries.reduce(0.0) { sum, entry in
            guard let startTime = entry.start_time,
                  let endTime = entry.end_time else { return sum }
            let interval = endTime.timeIntervalSince(startTime)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
        
        let weekKm = weekEntries.reduce(0.0) { sum, entry in
            sum + (entry.km ?? 0.0)
        }
        
        let status: EntryStatus = {
            if weekEntries.isEmpty {
                return .pending
            }
            if weekEntries.contains(where: { effectiveStatus(for: $0) == .rejected }) {
                return .rejected
            }
            if weekEntries.contains(where: { effectiveStatus(for: $0) == .confirmed }) {
                return .confirmed
            }
            if weekEntries.contains(where: { effectiveStatus(for: $0) == .submitted }) {
                return .submitted
            }
            if weekEntries.contains(where: { effectiveStatus(for: $0) == .draft }) {
                return .draft
            }
            return .pending
        }()
        
        statuses.append(WeekStatus(
            weekNumber: weekNumber,
            year: year,
            hours: weekHours,
            km: weekKm,
            status: status
        ))
    }
    
    return statuses
}

// MARK: - Week Status Model
struct WeekStatus: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let year: Int
    let hours: Double
    let km: Double
    let status: EntryStatus
    
    var weekLabel: String {
        return "Week \(weekNumber)"
    }
    
    var statusIcon: (Image, Color) {
        switch status {
        case .draft:
            return (Image(systemName: "pencil.circle"), .ksrWarning)
        case .pending:
            return (Image(systemName: "clock"), .ksrInfo)
        case .submitted:
            return (Image(systemName: "paperplane"), .ksrPrimary)
        case .confirmed:
            return (Image(systemName: "checkmark.circle"), .ksrSuccess)
        case .rejected:
            return (Image(systemName: "xmark.circle"), .ksrError)
        }
    }
}
