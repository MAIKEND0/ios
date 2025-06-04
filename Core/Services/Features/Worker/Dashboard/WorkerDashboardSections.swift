//
//  WorkerDashboardSections.swift
//  KSR Cranes App
//
//  Enhanced Worker Dashboard Sections with cleaner design and period navigation
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
    
    // MARK: - Enhanced Summary Cards Section with Period Navigation
    struct SummaryCardsSection: View {
        @ObservedObject var viewModel: WorkerDashboardViewModel
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Header with period navigation
                VStack(alignment: .leading, spacing: 12) {
                    Text("Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrTextPrimary)
                        .padding(.horizontal, 4)
                    
                    // Period Navigation
                    TimePeriodNavigationView(periodManager: viewModel.periodManager)
                    
                    // Smart suggestion if current period has no data
                    SmartPeriodSuggestionView(
                        entries: viewModel.hoursViewModel.entries,
                        periodManager: viewModel.periodManager
                    )
                }
                
                // Main stats cards
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    // Hours card for current period
                    EnhancedStatCard(
                        value: String(format: "%.1f", viewModel.currentPeriodHours),
                        label: "Hours",
                        sublabel: viewModel.periodManager.currentPeriod.type.rawValue,
                        icon: "clock.fill",
                        color: .ksrSuccess,
                        trend: viewModel.hoursGrowthTrend,
                        trendValue: viewModel.hoursPercentageChange,
                        comparisonValue: viewModel.previousPeriodHours
                    )
                    
                    // Kilometers card for current period
                    EnhancedStatCard(
                        value: String(format: "%.0f", viewModel.currentPeriodKm),
                        label: "Kilometers",
                        sublabel: viewModel.periodManager.currentPeriod.type.rawValue,
                        icon: "car.fill",
                        color: .ksrInfo,
                        trend: viewModel.kmGrowthTrend,
                        trendValue: viewModel.kmPercentageChange,
                        comparisonValue: viewModel.previousPeriodKm
                    )
                    
                    // Tasks card (always shows total)
                    EnhancedStatCard(
                        value: "\(viewModel.tasksViewModel.tasks.count)",
                        label: "Tasks",
                        sublabel: "Assigned",
                        icon: "briefcase.fill",
                        color: .ksrPrimary,
                        trend: nil,
                        trendValue: nil,
                        comparisonValue: nil
                    )
                    
                    // Entries card for current period
                    EnhancedStatCard(
                        value: "\(viewModel.currentPeriodEntries)",
                        label: "Entries",
                        sublabel: viewModel.periodManager.currentPeriod.type.rawValue,
                        icon: "calendar.badge.plus",
                        color: .ksrWarning,
                        trend: nil,
                        trendValue: nil,
                        comparisonValue: nil
                    )
                }
                
                // Period summary info
                if viewModel.currentPeriodEntries > 0 {
                    PeriodSummaryView(viewModel: viewModel)
                        .padding(.top, 8)
                }
                
                // Debug info (tylko w trybie debug)
                #if DEBUG
                DebugInfoView(viewModel: viewModel)
                #endif
            }
        }
    }
    
    // MARK: - Enhanced Stat Card with Trends
    struct EnhancedStatCard: View {
        let value: String
        let label: String
        let sublabel: String
        let icon: String
        let color: Color
        let trend: WorkerDashboardViewModel.TrendDirection?
        let trendValue: Double?
        let comparisonValue: Double?
        
        @State private var isAnimated = false
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Header with icon and trend
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if let trend = trend {
                        HStack(spacing: 4) {
                            Image(systemName: trend.icon)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(trend.color)
                            
                            if let trendValue = trendValue {
                                Text("\(trendValue > 0 ? "+" : "")\(String(format: "%.0f", trendValue))%")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(trend.color)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(trend.color.opacity(0.15))
                        )
                    }
                }
                
                // Main value and labels
                VStack(alignment: .leading, spacing: 2) {
                    // Animated counter for main value
                    let numericValue = parseNumericValue(from: value)
                    let displayFormat = value.contains(".") ? "%.1f" : "%.0f"
                    
                    AnimatedCounter(
                        value: numericValue,
                        format: displayFormat,
                        font: .title2,
                        color: Color.ksrTextPrimary
                    )
                    
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Text(sublabel)
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                }
                
                // Comparison info
                if let comparisonValue = comparisonValue, comparisonValue > 0 {
                    Text("vs \(String(format: displayFormat.contains("f") ? "%.1f" : "%.0f", comparisonValue)) last period")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.ksrDarkGray : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isAnimated ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimated)
            .onAppear {
                if trend?.color == .red {
                    withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
                        isAnimated = true
                    }
                }
            }
        }
        
        private var displayFormat: String {
            return value.contains(".") ? "%.1f" : "%.0f"
        }
        
        // Helper function to parse numeric value from string
        private func parseNumericValue(from string: String) -> Double {
            let cleanedString = string.replacingOccurrences(of: ",", with: "")
            let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
            let filteredString = String(cleanedString.unicodeScalars.filter { allowedCharacters.contains($0) })
            return Double(filteredString) ?? 0.0
        }
    }
    
    // MARK: - Period Summary View
    struct PeriodSummaryView: View {
        @ObservedObject var viewModel: WorkerDashboardViewModel
        @Environment(\.colorScheme) private var colorScheme
        
        private var averageHoursPerDay: Double {
            let days = Calendar.current.dateComponents([.day],
                                                     from: viewModel.periodManager.currentPeriod.startDate,
                                                     to: viewModel.periodManager.currentPeriod.endDate).day ?? 1
            return viewModel.currentPeriodHours / Double(max(days, 1))
        }
        
        private var averageKmPerDay: Double {
            let days = Calendar.current.dateComponents([.day],
                                                     from: viewModel.periodManager.currentPeriod.startDate,
                                                     to: viewModel.periodManager.currentPeriod.endDate).day ?? 1
            return viewModel.currentPeriodKm / Double(max(days, 1))
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Period Summary")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                HStack {
                    SummaryItem(
                        icon: "chart.bar",
                        value: String(format: "%.1f", averageHoursPerDay),
                        label: "Avg hours/day",
                        color: .ksrSuccess
                    )
                    
                    Spacer()
                    
                    SummaryItem(
                        icon: "speedometer",
                        value: String(format: "%.1f", averageKmPerDay),
                        label: "Avg km/day",
                        color: .ksrInfo
                    )
                    
                    Spacer()
                    
                    SummaryItem(
                        icon: "calendar.badge.checkmark",
                        value: "\(viewModel.currentPeriodEntries)",
                        label: "Total entries",
                        color: .ksrWarning
                    )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.ksrDarkGray.opacity(0.5) : Color.ksrLightGray)
            )
        }
    }

    struct SummaryItem: View {
        let icon: String
        let value: String
        let label: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                    
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrTextPrimary)
                }
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(Color.ksrTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Debug Info View
    #if DEBUG
    struct DebugInfoView: View {
        @ObservedObject var viewModel: WorkerDashboardViewModel
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                
                Text("Debug Info")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                if !viewModel.isDataLoaded || viewModel.hoursViewModel.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading data...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("All entries: \(viewModel.hoursViewModel.entries.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Period entries: \(viewModel.currentPeriodEntries)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Loading: \(viewModel.hoursViewModel.isLoading ? "Yes" : "No")")
                        .font(.caption2)
                        .foregroundColor(viewModel.hoursViewModel.isLoading ? .orange : .green)
                    
                    Text("Auth: \(AuthService.shared.getEmployeeId() ?? "nil")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Period: \(viewModel.periodManager.currentPeriod.displayName)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 4)
        }
    }
    #endif

    // MARK: - Compact Stat Card (zachowujemy dla kompatybilności)
    struct CompactStatCard: View {
        let value: String
        let label: String
        let sublabel: String
        let icon: String
        let color: Color
        let trend: Trend?
        @State private var isAnimated = false
        @Environment(\.colorScheme) private var colorScheme
        
        enum Trend {
            case up, down
            
            var icon: String {
                switch self {
                case .up: return "arrow.up.right"
                case .down: return "arrow.down.right"
                }
            }
            
            var color: Color {
                switch self {
                case .up: return .ksrSuccess
                case .down: return .ksrError
                }
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if let trend = trend {
                        Image(systemName: trend.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(trend.color)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    // Lepsze parsowanie wartości numerycznej
                    let numericValue = parseNumericValue(from: value)
                    let displayFormat = value.contains(".") ? "%.1f" : "%.0f"
                    
                    AnimatedCounter(
                        value: numericValue,
                        format: displayFormat,
                        font: .title2,
                        color: Color.ksrTextPrimary
                    )
                    
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Text(sublabel)
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                }
                
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.ksrDarkGray : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        
        // Helper function to parse numeric value from string
        private func parseNumericValue(from string: String) -> Double {
            let cleanedString = string.replacingOccurrences(of: ",", with: "")
            let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
            let filteredString = String(cleanedString.unicodeScalars.filter { allowedCharacters.contains($0) })
            return Double(filteredString) ?? 0.0
        }
    }
    
    // MARK: - Redesigned Tasks Section
    struct TasksSection: View {
        @ObservedObject var viewModel: WorkerDashboardViewModel
        let onTaskSelected: (Int) -> Void
        @Environment(\.colorScheme) private var colorScheme
        @State private var selectedFilter: TaskFilter = .all
        @State private var expandedTaskId: Int? = nil
        
        enum TaskFilter: String, CaseIterable {
            case all = "All"
            case active = "Active"
            case withHours = "With Hours"
            case craneRequired = "Crane Required"
            
            var icon: String {
                switch self {
                case .all: return "square.grid.2x2"
                case .active: return "play.circle"
                case .withHours: return "clock"
                case .craneRequired: return "wrench.and.screwdriver"
                }
            }
        }
        
        private var filteredTasks: [WorkerAPIService.Task] {
            let tasks = viewModel.tasksViewModel.tasks
            switch selectedFilter {
            case .all:
                return tasks
            case .active:
                return tasks.filter { task in
                    // Filter for tasks with activity in current period
                    let periodEntries = viewModel.periodManager.getEntriesForCurrentPeriod(viewModel.hoursViewModel.entries)
                    return periodEntries.contains { $0.task_id == task.task_id }
                }
            case .withHours:
                return tasks.filter { task in
                    viewModel.hoursViewModel.entries.contains { $0.task_id == task.task_id }
                }
            case .craneRequired:
                return tasks.filter { task in
                    task.crane_category != nil ||
                    task.crane_brand != nil ||
                    task.preferred_crane_model != nil ||
                    (task.assignments?.count ?? 0) > 0
                }
            }
        }
        
        var body: some View {
            VStack(spacing: 0) {
                // Clean Header
                headerSection
                
                // Filter Pills
                filterSection
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                
                Divider()
                    .padding(.horizontal, 20)
                
                // Tasks List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.tasksViewModel.isLoading {
                            ForEach(0..<3, id: \.self) { _ in
                                TaskSkeletonLoader()
                                    .padding(.horizontal, 20)
                            }
                        } else if filteredTasks.isEmpty {
                            EmptyTasksView(filter: selectedFilter)
                                .padding(.vertical, 40)
                        } else {
                            ForEach(filteredTasks, id: \.task_id) { task in
                                MinimalTaskCard(
                                    task: task,
                                    viewModel: viewModel,
                                    isExpanded: expandedTaskId == task.task_id,
                                    onTaskSelected: onTaskSelected,
                                    onToggleExpand: {
                                        withAnimation(.spring(response: 0.3)) {
                                            expandedTaskId = expandedTaskId == task.task_id ? nil : task.task_id
                                        }
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
                .frame(maxHeight: 400) // Limit height to prevent excessive scrolling
            }
            .background(cardBackground(colorScheme: colorScheme))
            .overlay(cardStroke())
        }
        
        // MARK: - Header Section
        private var headerSection: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Tasks")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Text("\(filteredTasks.count) \(selectedFilter == .all ? "total" : selectedFilter.rawValue.lowercased())")
                        .font(.subheadline)
                        .foregroundColor(Color.ksrTextSecondary)
                }
                
                Spacer()
                
                // Quick Add Button
                Button {
                    onTaskSelected(0) // 0 means new entry
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.ksrPrimary)
                }
            }
            .padding(20)
        }
        
        // MARK: - Filter Section
        private var filterSection: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            filter: filter,
                            isSelected: selectedFilter == filter,
                            count: getCount(for: filter)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
            }
        }
        
        private func getCount(for filter: TaskFilter) -> Int {
            switch filter {
            case .all:
                return viewModel.tasksViewModel.tasks.count
            case .active:
                let periodEntries = viewModel.periodManager.getEntriesForCurrentPeriod(viewModel.hoursViewModel.entries)
                return viewModel.tasksViewModel.tasks.filter { task in
                    periodEntries.contains { $0.task_id == task.task_id }
                }.count
            case .withHours:
                return viewModel.tasksViewModel.tasks.filter { task in
                    viewModel.hoursViewModel.entries.contains { $0.task_id == task.task_id }
                }.count
            case .craneRequired:
                return viewModel.tasksViewModel.tasks.filter { task in
                    task.crane_category != nil || task.crane_brand != nil || task.preferred_crane_model != nil
                }.count
            }
        }
    }
    
    // MARK: - Minimal Task Card (Updated with period awareness)
    struct MinimalTaskCard: View {
        let task: WorkerAPIService.Task
        let viewModel: WorkerDashboardViewModel
        let isExpanded: Bool
        let onTaskSelected: (Int) -> Void
        let onToggleExpand: () -> Void
        @Environment(\.colorScheme) private var colorScheme
        
        private var taskHours: Double {
            viewModel.hoursViewModel.entries
                .filter { $0.task_id == task.task_id }
                .reduce(0.0) { sum, entry in
                    guard let start = entry.start_time, let end = entry.end_time else { return sum }
                    let interval = end.timeIntervalSince(start)
                    let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                    return sum + max(0, (interval - pauseSeconds) / 3600)
                }
        }
        
        private var periodHours: Double {
            let periodEntries = viewModel.periodManager.getEntriesForCurrentPeriod(viewModel.hoursViewModel.entries)
                .filter { $0.task_id == task.task_id }
            
            return periodEntries.reduce(0.0) { sum, entry in
                guard let start = entry.start_time, let end = entry.end_time else { return sum }
                let interval = end.timeIntervalSince(start)
                let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                return sum + max(0, (interval - pauseSeconds) / 3600)
            }
        }
        
        private var hasCraneInfo: Bool {
            task.crane_category != nil ||
            task.crane_brand != nil ||
            task.preferred_crane_model != nil ||
            (task.assignments?.count ?? 0) > 0
        }
        
        var body: some View {
            VStack(spacing: 0) {
                // Main Card Content
                Button {
                    onToggleExpand()
                } label: {
                    HStack(spacing: 12) {
                        // Task Icon/Initial
                        taskIcon
                        
                        // Task Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.headline)
                                .foregroundColor(Color.ksrTextPrimary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                // Project name
                                if let project = task.project {
                                    Label(project.title, systemImage: "building.2")
                                        .font(.caption)
                                        .foregroundColor(Color.ksrTextSecondary)
                                        .lineLimit(1)
                                }
                                
                                // Crane indicator
                                if hasCraneInfo {
                                    Label("Crane", systemImage: "wrench.and.screwdriver")
                                        .font(.caption)
                                        .foregroundColor(Color.ksrInfo)
                                }
                            }
                        }
                        
                        Spacer(minLength: 0)
                        
                        // Hours Display (for current period)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1fh", periodHours))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(periodHours > 0 ? Color.ksrSuccess : Color.ksrTextSecondary)
                            
                            Text(viewModel.periodManager.selectedType.shortName)
                                .font(.caption2)
                                .foregroundColor(Color.ksrTextSecondary)
                        }
                        
                        // Chevron
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(Color.ksrTextSecondary)
                            .frame(width: 20)
                    }
                    .padding(16)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Expanded Content
                if isExpanded {
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.horizontal, 16)
                        
                        expandedContent
                            .padding(16)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.ksrLightGray)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isExpanded ? Color.ksrPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        
        // MARK: - Task Icon
        private var taskIcon: some View {
            ZStack {
                Circle()
                    .fill(
                        hasCraneInfo ?
                        LinearGradient(colors: [Color.ksrInfo, Color.ksrInfo.darker(by: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color.ksrPrimary.opacity(0.2), Color.ksrPrimary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)
                
                if hasCraneInfo {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    Text(String(task.title.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.ksrPrimary)
                }
            }
        }
        
        // MARK: - Expanded Content
        private var expandedContent: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Quick Stats
                HStack(spacing: 16) {
                    QuickStat(
                        icon: "clock",
                        value: String(format: "%.1fh", taskHours),
                        label: "Total Hours",
                        color: .ksrSuccess
                    )
                    
                    if let deadline = task.deadline {
                        QuickStat(
                            icon: "calendar",
                            value: formatDeadline(deadline),
                            label: "Deadline",
                            color: isDeadlineNear(deadline) ? .ksrError : .ksrWarning
                        )
                    }
                    
                    if let supervisor = task.supervisor_name {
                        QuickStat(
                            icon: "person",
                            value: supervisor.components(separatedBy: " ").first ?? supervisor,
                            label: "Supervisor",
                            color: .ksrInfo
                        )
                    }
                }
                
                // Crane Info (if available)
                if hasCraneInfo {
                    craneInfoSection
                }
                
                // Description (if available)
                if let description = task.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.ksrTextSecondary)
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(Color.ksrTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // Action Button
                Button {
                    onTaskSelected(task.task_id)
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Log Hours")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        
        // MARK: - Crane Info Section
        private var craneInfoSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Equipment Requirements")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrTextSecondary)
                
                HStack(spacing: 8) {
                    if let category = task.crane_category {
                        CraneChip(
                            icon: "tag",
                            text: category.name,
                            color: .ksrInfo
                        )
                    }
                    
                    if let brand = task.crane_brand {
                        CraneChip(
                            icon: "building.2",
                            text: brand.name,
                            color: .ksrPrimary
                        )
                    }
                    
                    if let model = task.preferred_crane_model {
                        CraneChip(
                            icon: "gear",
                            text: model.name,
                            color: .ksrSuccess
                        )
                    }
                }
            }
        }
        
        // Helper functions
        private func formatDeadline(_ date: Date) -> String {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            if days == 0 { return "Today" }
            if days == 1 { return "Tomorrow" }
            if days < 0 { return "Overdue" }
            return "\(days) days"
        }
        
        private func isDeadlineNear(_ date: Date) -> Bool {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            return days <= 3
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
    
    struct FilterPill: View {
        let filter: TasksSection.TaskFilter
        let isSelected: Bool
        let count: Int
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: filter.icon)
                        .font(.caption)
                    
                    Text(filter.rawValue)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .medium)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.white.opacity(0.3) : Color.ksrPrimary.opacity(0.2))
                            )
                    }
                }
                .foregroundColor(isSelected ? .white : Color.ksrTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.ksrPrimary : Color.ksrLightGray)
                )
            }
        }
    }
    
    struct QuickStat: View {
        let icon: String
        let value: String
        let label: String
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundColor(color)
                    
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.ksrTextPrimary)
                }
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(Color.ksrTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    struct CraneChip: View {
        let icon: String
        let text: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                
                Text(text)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
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
    
    struct TaskSkeletonLoader: View {
        var body: some View {
            HStack(spacing: 12) {
                ShimmerView(cornerRadius: 22)
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 8) {
                    ShimmerView(cornerRadius: 4)
                        .frame(height: 16)
                        .frame(maxWidth: .infinity)
                    
                    ShimmerView(cornerRadius: 4)
                        .frame(height: 12)
                        .frame(maxWidth: 200)
                }
                
                ShimmerView(cornerRadius: 4)
                    .frame(width: 50, height: 30)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.ksrLightGray)
            )
        }
    }
    
    struct EmptyTasksView: View {
        let filter: TasksSection.TaskFilter
        
        private var message: String {
            switch filter {
            case .all:
                return "No tasks assigned yet"
            case .active:
                return "No active tasks this period"
            case .withHours:
                return "No tasks with logged hours"
            case .craneRequired:
                return "No tasks requiring crane equipment"
            }
        }
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "tray")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(Color.ksrTextSecondary)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Text("Tasks will appear here when assigned")
                    .font(.subheadline)
                    .foregroundColor(Color.ksrTextSecondary)
            }
            .frame(maxWidth: .infinity)
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

// MARK: - Animated Counter Component
struct WorkerAnimatedCounter: View {
    let value: Double
    let format: String
    let font: Font
    let color: Color
    @State private var displayValue: Double = 0
    
    init(
        value: Double,
        format: String = "%.1f",
        duration: Double = 1.0,
        font: Font = .title2,
        color: Color = .primary
    ) {
        self.value = value
        self.format = format
        self.font = font
        self.color = color
    }
    
    var body: some View {
        Text(String(format: format, displayValue))
            .font(font)
            .foregroundColor(color)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Shimmer View
struct WorkerShimmerView: View {
    @State private var phase: CGFloat = 0
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 12) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.2),
                Color.gray.opacity(0.4),
                Color.gray.opacity(0.2)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.4),
                            Color.black,
                            Color.black.opacity(0.4)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .rotationEffect(.degrees(25))
                .offset(x: phase)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 300
            }
        }
    }
}

// MARK: - Helper Functions
private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

// MARK: - Extensions
extension Color {
    func Workerdarker(by percentage: Double = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
    
    // Gradient helpers
    static let WorkerprimaryGradient = LinearGradient(
        colors: [Color.ksrPrimary, Color.ksrYellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension DateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
