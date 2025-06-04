// Features/Worker/Tasks/WorkerTasksView.swift
import SwiftUI

struct WorkerTasksView: View {
    @StateObject private var viewModel = WorkerTasksViewModel()
    @StateObject private var hoursViewModel = WorkerWorkHoursViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    // Filter and search states
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedPriority: PriorityFilter = .all
    @State private var selectedCraneType: CraneFilter = .all
    @State private var searchText = ""
    @State private var showingTaskDetail = false
    @State private var selectedTask: WorkerAPIService.Task?
    @State private var sortOption: SortOption = .deadline
    @State private var showingSortOptions = false
    @State private var expandedTaskId: Int?
    
    enum TaskFilter: String, CaseIterable, Identifiable {
        case all = "All Tasks"
        case active = "Active"
        case withHours = "With Hours"
        case craneRequired = "Crane Required"
        case recentDeadline = "Due Soon"
        case completed = "Completed"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .active: return "play.circle"
            case .withHours: return "clock"
            case .craneRequired: return "wrench.and.screwdriver"
            case .recentDeadline: return "calendar.badge.exclamationmark"
            case .completed: return "checkmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .ksrPrimary
            case .active: return .ksrSuccess
            case .withHours: return .ksrInfo
            case .craneRequired: return .ksrWarning
            case .recentDeadline: return .ksrError
            case .completed: return .ksrSecondary
            }
        }
    }
    
    enum PriorityFilter: String, CaseIterable {
        case all = "All"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        
        var color: Color {
            switch self {
            case .all: return .ksrPrimary
            case .high: return .ksrError
            case .medium: return .ksrWarning
            case .low: return .ksrInfo
            }
        }
    }
    
    enum CraneFilter: String, CaseIterable {
        case all = "All Types"
        case mobile = "Mobile"
        case tower = "Tower"
        case crawler = "Crawler"
        case truck = "Truck"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .mobile: return "car"
            case .tower: return "building.2"
            case .crawler: return "gear"
            case .truck: return "truck"
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case deadline = "Deadline"
        case created = "Created Date"
        case priority = "Priority"
        case title = "Title"
        case hours = "Hours Logged"
        
        var icon: String {
            switch self {
            case .deadline: return "calendar"
            case .created: return "clock"
            case .priority: return "exclamationmark.triangle"
            case .title: return "textformat"
            case .hours: return "timer"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Enhanced Stats Overview
                    tasksStatsSection
                    
                    // Advanced Filters & Search
                    filtersSection
                    
                    // Tasks List with Enhanced Cards
                    tasksListSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(dashboardBackground)
            .navigationTitle("My Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolbarButtons
                }
            }
            .onAppear {
                handleViewAppear()
            }
            .refreshable {
                await refreshData()
            }
            .searchable(text: $searchText, prompt: "Search tasks, projects, or descriptions")
            .sheet(item: $selectedTask) { task in
                WorkerTaskDetailView(task: task)
                    .presentationDetents([.large])
            }
            .confirmationDialog("Sort Tasks", isPresented: $showingSortOptions) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        sortOption = option
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredAndSortedTasks: [WorkerAPIService.Task] {
        let filteredTasks = applyFiltersToTasks()
        return applySortingToTasks(filteredTasks)
    }
    
    private func applyFiltersToTasks() -> [WorkerAPIService.Task] {
        var tasks = viewModel.tasks
        
        // Apply main filter
        tasks = applyMainFilter(to: tasks)
        
        // Apply search filter
        tasks = applySearchFilter(to: tasks)
        
        // Apply priority filter
        tasks = applyPriorityFilter(to: tasks)
        
        // Apply crane type filter
        tasks = applyCraneTypeFilter(to: tasks)
        
        return tasks
    }
    
    private func applyMainFilter(to tasks: [WorkerAPIService.Task]) -> [WorkerAPIService.Task] {
        switch selectedFilter {
        case .all:
            return tasks
        case .active, .withHours:
            let tasksWithHours = Set(hoursViewModel.entries.map { $0.task_id })
            return tasks.filter { tasksWithHours.contains($0.task_id) }
        case .craneRequired:
            return tasks.filter { hasCraneRequirements($0) }
        case .recentDeadline:
            return filterTasksByRecentDeadline(tasks)
        case .completed:
            // Implement completed logic based on your business rules
            return tasks
        }
    }
    
    private func filterTasksByRecentDeadline(_ tasks: [WorkerAPIService.Task]) -> [WorkerAPIService.Task] {
        let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        return tasks.filter { task in
            guard let deadline = task.deadline else { return false }
            return deadline <= twoWeeksFromNow && deadline >= Date()
        }
    }
    
    private func applySearchFilter(to tasks: [WorkerAPIService.Task]) -> [WorkerAPIService.Task] {
        guard !searchText.isEmpty else { return tasks }
        
        let searchLower = searchText.lowercased()
        return tasks.filter { task in
            return task.title.lowercased().contains(searchLower) ||
                   (task.description?.lowercased().contains(searchLower) ?? false) ||
                   (task.project?.title.lowercased().contains(searchLower) ?? false) ||
                   (task.supervisor_name?.lowercased().contains(searchLower) ?? false)
        }
    }
    
    private func applyPriorityFilter(to tasks: [WorkerAPIService.Task]) -> [WorkerAPIService.Task] {
        guard selectedPriority != .all else { return tasks }
        // Implement priority filtering based on your business logic
        // This is a placeholder as priority isn't in the current model
        return tasks
    }
    
    private func applyCraneTypeFilter(to tasks: [WorkerAPIService.Task]) -> [WorkerAPIService.Task] {
        guard selectedCraneType != .all else { return tasks }
        
        return tasks.filter { task in
            guard let category = task.crane_category else { return false }
            return category.name.lowercased().contains(selectedCraneType.rawValue.lowercased())
        }
    }
    
    private func applySortingToTasks(_ tasks: [WorkerAPIService.Task]) -> [WorkerAPIService.Task] {
        return tasks.sorted { task1, task2 in
            switch sortOption {
            case .deadline:
                return compareTasksByDeadline(task1, task2)
            case .created:
                return compareTasksByCreatedDate(task1, task2)
            case .title:
                return task1.title < task2.title
            case .priority:
                return task1.title < task2.title // Placeholder
            case .hours:
                return compareTasksByHours(task1, task2)
            }
        }
    }
    
    private func compareTasksByDeadline(_ task1: WorkerAPIService.Task, _ task2: WorkerAPIService.Task) -> Bool {
        guard let deadline1 = task1.deadline else { return false }
        guard let deadline2 = task2.deadline else { return true }
        return deadline1 < deadline2
    }
    
    private func compareTasksByCreatedDate(_ task1: WorkerAPIService.Task, _ task2: WorkerAPIService.Task) -> Bool {
        guard let created1 = task1.created_at else { return false }
        guard let created2 = task2.created_at else { return true }
        return created1 > created2
    }
    
    private func compareTasksByHours(_ task1: WorkerAPIService.Task, _ task2: WorkerAPIService.Task) -> Bool {
        let hours1 = getTaskHours(task1.task_id)
        let hours2 = getTaskHours(task2.task_id)
        return hours1 > hours2
    }
    
    private var taskStats: TaskStats {
        return calculateTaskStats()
    }
    
    private func calculateTaskStats() -> TaskStats {
        let allTasks = viewModel.tasks
        let tasksWithHours = Set(hoursViewModel.entries.map { $0.task_id })
        let craneTasks = allTasks.filter { hasCraneRequirements($0) }
        let urgentTasksCount = calculateUrgentTasks(allTasks)
        let totalHours = calculateTotalHours()
        
        return TaskStats(
            total: allTasks.count,
            active: tasksWithHours.count,
            craneRequired: craneTasks.count,
            urgent: urgentTasksCount,
            totalHours: totalHours,
            averageHoursPerTask: calculateAverageHoursPerTask(totalHours, activeCount: tasksWithHours.count)
        )
    }
    
    private func calculateUrgentTasks(_ tasks: [WorkerAPIService.Task]) -> Int {
        let oneWeekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return tasks.filter { task in
            guard let deadline = task.deadline else { return false }
            return deadline <= oneWeekFromNow && deadline >= Date()
        }.count
    }
    
    private func calculateTotalHours() -> Double {
        return hoursViewModel.entries.reduce(0.0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
    }
    
    private func calculateAverageHoursPerTask(_ totalHours: Double, activeCount: Int) -> Double {
        guard activeCount > 0 else { return 0 }
        return totalHours / Double(activeCount)
    }
    
    // MARK: - Stats Overview Section
    private var tasksStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasks Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Spacer()
                
                Text("\(filteredAndSortedTasks.count) of \(viewModel.tasks.count)")
                    .font(.caption)
                    .foregroundColor(Color.ksrTextSecondary)
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                EnhancedTaskStatCard(
                    title: "Total Tasks",
                    value: "\(taskStats.total)",
                    icon: "briefcase.fill",
                    color: .ksrPrimary,
                    subtitle: "Assigned to you"
                )
                
                EnhancedTaskStatCard(
                    title: "Active Tasks",
                    value: "\(taskStats.active)",
                    icon: "play.circle.fill",
                    color: .ksrSuccess,
                    subtitle: "With logged hours"
                )
                
                EnhancedTaskStatCard(
                    title: "Crane Tasks",
                    value: "\(taskStats.craneRequired)",
                    icon: "wrench.and.screwdriver.fill",
                    color: .ksrWarning,
                    subtitle: "Equipment required"
                )
                
                EnhancedTaskStatCard(
                    title: "Due Soon",
                    value: "\(taskStats.urgent)",
                    icon: "calendar.badge.exclamationmark",
                    color: taskStats.urgent > 0 ? .ksrError : .ksrInfo,
                    subtitle: "Within 7 days"
                )
            }
            
            // Quick insights
            if taskStats.totalHours > 0 {
                QuickInsightsRow(stats: taskStats)
            }
        }
        .padding(20)
        .background(WorkerDashboardSections.cardBackground(colorScheme: colorScheme))
        .overlay(WorkerDashboardSections.cardStroke(.ksrPrimary))
    }
    
    // MARK: - Filters Section
    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Filters & Sort")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Spacer()
                
                Button("Reset") {
                    resetFilters()
                }
                .font(.caption)
                .foregroundColor(.ksrYellow)
            }
            .padding(.horizontal, 4)
            
            // Main filters
            VStack(spacing: 12) {
                Text("Filter by")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TaskFilter.allCases) { filter in
                            WorkerFilterChip(
                                title: filter.rawValue,
                                icon: filter.icon,
                                color: filter.color,
                                isSelected: selectedFilter == filter,
                                count: getFilterCount(filter)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Sort and additional filters
            HStack(spacing: 12) {
                // Sort button
                Button {
                    showingSortOptions = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: sortOption.icon)
                            .font(.caption)
                        Text("Sort: \(sortOption.rawValue)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(Color.ksrTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.ksrLightGray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Crane type filter (if there are crane tasks)
                if taskStats.craneRequired > 0 {
                    Menu {
                        ForEach(CraneFilter.allCases, id: \.self) { filter in
                            Button {
                                selectedCraneType = filter
                            } label: {
                                Label(filter.rawValue, systemImage: filter.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: selectedCraneType.icon)
                                .font(.caption)
                            Text(selectedCraneType.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(Color.ksrTextPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.ksrLightGray)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(WorkerDashboardSections.cardBackground(colorScheme: colorScheme))
        .overlay(WorkerDashboardSections.cardStroke(.ksrInfo))
    }
    
    // MARK: - Tasks List Section
    private var tasksListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasks")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Spacer()
                
                if !searchText.isEmpty {
                    Text("Search results")
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                }
            }
            .padding(.horizontal, 4)
            
            if viewModel.isLoading {
                loadingView
            } else if filteredAndSortedTasks.isEmpty {
                emptyStateView
            } else {
                tasksListContent
            }
        }
        .padding(20)
        .background(WorkerDashboardSections.cardBackground(colorScheme: colorScheme))
        .overlay(WorkerDashboardSections.cardStroke(.ksrSuccess))
    }
    
    private var tasksListContent: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredAndSortedTasks, id: \.task_id) { task in
                EnhancedTaskCard(
                    task: task,
                    taskHours: getTaskHours(task.task_id),
                    isExpanded: expandedTaskId == task.task_id,
                    onTaskSelected: {
                        selectedTask = task
                        showingTaskDetail = true
                    },
                    onToggleExpand: {
                        withAnimation(.spring(response: 0.3)) {
                            expandedTaskId = expandedTaskId == task.task_id ? nil : task.task_id
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func hasCraneRequirements(_ task: WorkerAPIService.Task) -> Bool {
        return task.crane_category != nil ||
               task.crane_brand != nil ||
               task.preferred_crane_model != nil ||
               (task.assignments?.count ?? 0) > 0
    }
    
    private func getTaskHours(_ taskId: Int) -> Double {
        return hoursViewModel.entries
            .filter { $0.task_id == taskId }
            .reduce(0.0) { sum, entry in
                guard let start = entry.start_time, let end = entry.end_time else { return sum }
                let interval = end.timeIntervalSince(start)
                let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                return sum + max(0, (interval - pauseSeconds) / 3600)
            }
    }
    
    private func getFilterCount(_ filter: TaskFilter) -> Int {
        switch filter {
        case .all:
            return viewModel.tasks.count
        case .active, .withHours:
            return getActiveTasksCount()
        case .craneRequired:
            return getCraneRequiredTasksCount()
        case .recentDeadline:
            return getRecentDeadlineTasksCount()
        case .completed:
            return 0 // Implement based on your business logic
        }
    }
    
    private func getActiveTasksCount() -> Int {
        let tasksWithHours = Set(hoursViewModel.entries.map { $0.task_id })
        return viewModel.tasks.filter { tasksWithHours.contains($0.task_id) }.count
    }
    
    private func getCraneRequiredTasksCount() -> Int {
        return viewModel.tasks.filter { hasCraneRequirements($0) }.count
    }
    
    private func getRecentDeadlineTasksCount() -> Int {
        let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        return viewModel.tasks.filter { task in
            guard let deadline = task.deadline else { return false }
            return deadline <= twoWeeksFromNow && deadline >= Date()
        }.count
    }
    
    private func resetFilters() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedFilter = .all
            selectedPriority = .all
            selectedCraneType = .all
            searchText = ""
            sortOption = .deadline
        }
    }
    
    private func handleViewAppear() {
        viewModel.loadTasks()
        hoursViewModel.loadEntries()
    }
    
    private func refreshData() async {
        await withCheckedContinuation { continuation in
            viewModel.loadTasks()
            hoursViewModel.loadEntries()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
    
    // MARK: - UI Components
    
    private var toolbarButtons: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.loadTasks()
                    hoursViewModel.loadEntries()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(viewModel.isLoading ? .gray : Color.ksrPrimary)
            }
            .disabled(viewModel.isLoading)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.ksrPrimary)
            
            Text("Loading tasks...")
                .font(.subheadline)
                .foregroundColor(Color.ksrTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: getEmptyStateIcon())
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Color.ksrTextSecondary)
            
            VStack(spacing: 8) {
                Text(getEmptyStateTitle())
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Text(getEmptyStateSubtitle())
                    .font(.subheadline)
                    .foregroundColor(Color.ksrTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if selectedFilter != .all || !searchText.isEmpty {
                Button("Clear Filters") {
                    resetFilters()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.ksrPrimary)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.vertical, 40)
    }
    
    private var dashboardBackground: some View {
        Color.backgroundGradient
            .ignoresSafeArea()
    }
    
    private func getEmptyStateIcon() -> String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        } else {
            return selectedFilter.icon
        }
    }
    
    private func getEmptyStateTitle() -> String {
        if !searchText.isEmpty {
            return "No results found"
        } else {
            switch selectedFilter {
            case .all: return "No tasks assigned"
            case .active: return "No active tasks"
            case .withHours: return "No tasks with hours"
            case .craneRequired: return "No crane tasks"
            case .recentDeadline: return "No urgent tasks"
            case .completed: return "No completed tasks"
            }
        }
    }
    
    private func getEmptyStateSubtitle() -> String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or filters"
        } else {
            switch selectedFilter {
            case .all: return "Tasks will appear here when assigned to you"
            case .active: return "Start logging hours to see active tasks"
            case .withHours: return "Tasks with logged work hours will appear here"
            case .craneRequired: return "Tasks requiring crane equipment will appear here"
            case .recentDeadline: return "Tasks due within 7 days will appear here"
            case .completed: return "Completed tasks will appear here"
            }
        }
    }
}

// MARK: - Supporting Structures

struct TaskStats {
    let total: Int
    let active: Int
    let craneRequired: Int
    let urgent: Int
    let totalHours: Double
    let averageHoursPerTask: Double
}

// MARK: - Enhanced Task Stat Card
struct EnhancedTaskStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.ksrTextSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
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

// MARK: - Quick Insights Row
struct QuickInsightsRow: View {
    let stats: TaskStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Insights")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.ksrTextSecondary)
            
            HStack(spacing: 16) {
                InsightItem(
                    icon: "clock",
                    value: String(format: "%.1fh", stats.totalHours),
                    label: "Total hours"
                )
                
                if stats.active > 0 {
                    InsightItem(
                        icon: "chart.bar",
                        value: String(format: "%.1fh", stats.totalHours / Double(stats.active)),
                        label: "Avg per task"
                    )
                }
                
                if stats.urgent > 0 {
                    InsightItem(
                        icon: "exclamationmark.triangle",
                        value: "\(stats.urgent)",
                        label: "Urgent",
                        color: .ksrError
                    )
                }
                
                Spacer()
            }
        }
        .padding(.top, 8)
    }
}

struct InsightItem: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = Color.ksrInfo
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(Color.ksrTextSecondary)
            }
        }
    }
}

// MARK: - Filter Chip
struct WorkerFilterChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
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
                                .fill(isSelected ? Color.white.opacity(0.3) : color.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : Color.ksrTextPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color.ksrLightGray)
            )
        }
    }
}

// MARK: - Enhanced Task Card
struct EnhancedTaskCard: View {
    let task: WorkerAPIService.Task
    let taskHours: Double
    let isExpanded: Bool
    let onTaskSelected: () -> Void
    let onToggleExpand: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var deadlineStatus: DeadlineStatus {
        guard let deadline = task.deadline else { return .none }
        let now = Date()
        let daysDifference = Calendar.current.dateComponents([.day], from: now, to: deadline).day ?? 0
        
        if daysDifference < 0 {
            return .overdue
        } else if daysDifference <= 2 {
            return .urgent
        } else if daysDifference <= 7 {
            return .soon
        } else {
            return .normal
        }
    }
    
    private var hasCraneRequirements: Bool {
        return task.crane_category != nil ||
               task.crane_brand != nil ||
               task.preferred_crane_model != nil ||
               (task.assignments?.count ?? 0) > 0
    }
    
    enum DeadlineStatus {
        case none, normal, soon, urgent, overdue
        
        var color: Color {
            switch self {
            case .none, .normal: return .ksrInfo
            case .soon: return .ksrWarning
            case .urgent: return .ksrError
            case .overdue: return .red
            }
        }
        
        var text: String {
            switch self {
            case .none: return "No deadline"
            case .normal: return "On track"
            case .soon: return "Due soon"
            case .urgent: return "Urgent"
            case .overdue: return "Overdue"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            VStack(alignment: .leading, spacing: 12) {
                // Header with task info
                headerSection
                
                // Task details row
                detailsRow
                
                // Progress and actions row
                progressAndActionsRow
            }
            .padding(16)
            
            // Expanded content
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
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ksrMediumGray)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isExpanded ? Color.ksrPrimary.opacity(0.5) : Color.ksrPrimary.opacity(0.2), lineWidth: isExpanded ? 2 : 1)
        )
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            // Task icon
            taskIcon
            
            // Task title and project
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
                    .lineLimit(2)
                
                if let project = task.project {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.caption)
                            .foregroundColor(Color.ksrInfo)
                        
                        Text(project.title)
                            .font(.subheadline)
                            .foregroundColor(Color.ksrTextSecondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Hours and expand button
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1fh", taskHours))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(taskHours > 0 ? Color.ksrSuccess : Color.ksrTextSecondary)
                
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
    
    private var taskIcon: some View {
        ZStack {
            Circle()
                .fill(
                    hasCraneRequirements ?
                    LinearGradient(colors: [Color.ksrWarning, Color.ksrWarning.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [Color.ksrPrimary.opacity(0.2), Color.ksrPrimary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 48, height: 48)
            
            if hasCraneRequirements {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            } else {
                Text(String(task.title.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.ksrPrimary)
            }
        }
    }
    
    private var detailsRow: some View {
        HStack(spacing: 16) {
            // Deadline status
            if task.deadline != nil {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(deadlineStatus.color)
                    
                    Text(deadlineStatus.text)
                        .font(.caption)
                        .foregroundColor(deadlineStatus.color)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(deadlineStatus.color.opacity(0.15))
                )
            }
            
            // Crane indicator
            if hasCraneRequirements {
                HStack(spacing: 4) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.caption)
                        .foregroundColor(Color.ksrWarning)
                    
                    Text("Crane")
                        .font(.caption)
                        .foregroundColor(Color.ksrWarning)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.ksrWarning.opacity(0.15))
                )
            }
            
            // Supervisor indicator
            if let supervisor = task.supervisor_name {
                HStack(spacing: 4) {
                    Image(systemName: "person")
                        .font(.caption)
                        .foregroundColor(Color.ksrInfo)
                    
                    Text(supervisor.components(separatedBy: " ").first ?? supervisor)
                        .font(.caption)
                        .foregroundColor(Color.ksrInfo)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
        }
    }
    
    private var progressAndActionsRow: some View {
        HStack {
            // Hours progress indicator
            if taskHours > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(Color.ksrSuccess)
                    
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(Color.ksrSuccess)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // Action button - only Details now
            Button {
                onTaskSelected()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Details")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.ksrPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.ksrPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Description
            if let description = task.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(Color.ksrTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Crane requirements
            if hasCraneRequirements {
                craneRequirementsSection
            }
            
            // Project details
            if let project = task.project {
                projectDetailsSection(project)
            }
            
            // Supervisor contact
            if let supervisor = task.supervisor_name {
                supervisorContactSection(supervisor)
            }
        }
    }
    
    private var craneRequirementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Equipment Requirements")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.ksrTextPrimary)
            
            VStack(spacing: 6) {
                if let category = task.crane_category {
                    EquipmentDetailRow(
                        icon: "tag",
                        label: "Category",
                        value: category.name,
                        color: .ksrInfo
                    )
                }
                
                if let brand = task.crane_brand {
                    EquipmentDetailRow(
                        icon: "building.2",
                        label: "Brand",
                        value: brand.name,
                        color: .ksrPrimary
                    )
                }
                
                if let model = task.preferred_crane_model {
                    EquipmentDetailRow(
                        icon: "gear",
                        label: "Model",
                        value: model.name,
                        color: .ksrSuccess
                    )
                }
            }
        }
    }
    
    private func projectDetailsSection(_ project: WorkerAPIService.Task.Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Project Details")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.ksrTextPrimary)
            
            VStack(spacing: 6) {
                if let description = project.description {
                    ProjectDetailRow(
                        icon: "doc.text",
                        label: "Description",
                        value: description
                    )
                }
                
                if let customer = project.customer {
                    ProjectDetailRow(
                        icon: "person.2",
                        label: "Customer",
                        value: customer.name
                    )
                }
                
                if let address = formatProjectAddress(project) {
                    ProjectDetailRow(
                        icon: "location",
                        label: "Location",
                        value: address
                    )
                }
            }
        }
    }
    
    private func supervisorContactSection(_ supervisor: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supervisor")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.ksrTextPrimary)
            
            HStack {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundColor(Color.ksrInfo)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(supervisor)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    if let email = task.supervisor_email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(Color.ksrTextSecondary)
                    }
                    
                    if let phone = task.supervisor_phone {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(Color.ksrTextSecondary)
                    }
                }
                
                Spacer()
                
                if let phone = task.supervisor_phone {
                    Button {
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.ksrSuccess)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    private func formatProjectAddress(_ project: WorkerAPIService.Task.Project) -> String? {
        let components = [project.street, project.city, project.zip].compactMap { $0 }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

// MARK: - Detail Row Components
struct EquipmentDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(label)
                .font(.caption)
                .foregroundColor(Color.ksrTextSecondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.ksrTextPrimary)
            
            Spacer()
        }
    }
}

struct ProjectDetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color.ksrInfo)
                .frame(width: 16)
            
            Text(label)
                .font(.caption)
                .foregroundColor(Color.ksrTextSecondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(Color.ksrTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct WorkerTasksView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WorkerTasksView()
                .preferredColorScheme(.light)
            
            WorkerTasksView()
                .preferredColorScheme(.dark)
        }
    }
}
