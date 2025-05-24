//
//  ManagerDashboardSections.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 17/05/2025.
//  Visual improvements added - Enhanced version with better consistency

import SwiftUI

// MARK: - Enhanced ManagerDashboardSections
struct ManagerDashboardSections {
    
    // MARK: - Consistent Card Style
    static func cardBackground(colorScheme: ColorScheme) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
    }
    
    static func cardStroke(_ color: Color = Color.gray, opacity: Double = 0.2) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(color.opacity(opacity), lineWidth: 1)
    }
    
    // MARK: - Summary Cards Section
    struct SummaryCardsSection: View {
        @ObservedObject var viewModel: ManagerDashboardViewModel
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Overview")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    .padding(.horizontal, 4)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    EnhancedSummaryCard(
                        title: "Pending Hours",
                        value: "\(viewModel.pendingHoursCount)",
                        icon: "clock.fill",
                        color: Color.ksrWarning,
                        isHighlighted: viewModel.pendingHoursCount > 0
                    )
                    
                    EnhancedSummaryCard(
                        title: "Active Workers",
                        value: "\(viewModel.activeWorkersCount)",
                        icon: "person.2.fill",
                        color: Color.ksrSuccess
                    )
                    
                    EnhancedSummaryCard(
                        title: "Approved Hours",
                        value: String(format: "%.1f", viewModel.totalApprovedHours),
                        icon: "checkmark.circle.fill",
                        color: Color.ksrInfo
                    )
                    
                    EnhancedSummaryCard(
                        title: "Tasks Assigned",
                        value: "\(viewModel.supervisorTasks.count)",
                        icon: "briefcase.fill",
                        color: Color.ksrPrimary
                    )
                }
            }
        }
    }
    
    // MARK: - Enhanced Summary Card
    struct EnhancedSummaryCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color
        let isHighlighted: Bool
        @Environment(\.colorScheme) private var colorScheme
        
        init(title: String, value: String, icon: String, color: Color, isHighlighted: Bool = false) {
            self.title = title
            self.value = value
            self.icon = icon
            self.color = color
            self.isHighlighted = isHighlighted
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if isHighlighted {
                        Circle()
                            .fill(Color.ksrWarning)
                            .frame(width: 8, height: 8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(16)
            .background(cardBackground(colorScheme: colorScheme))
            .overlay(
                cardStroke(color, opacity: isHighlighted ? 0.4 : 0.2)
            )
            .scaleEffect(isHighlighted ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHighlighted)
        }
    }
    
    // MARK: - Compact Pending Section
    struct CompactPendingSection: View {
        @ObservedObject var viewModel: ManagerDashboardViewModel
        @Environment(\.colorScheme) private var colorScheme
        let isPulsing: Bool
        let onSelectTaskWeek: (ManagerDashboardViewModel.TaskWeekEntry) -> Void
        let onSelectEntry: (ManagerAPIService.WorkHourEntry) -> Void
        @State private var expandedTasks: Set<Int> = []
        @State private var isExpanded = false
        
        private var hasPendingItems: Bool {
            !viewModel.allPendingEntriesByTask.isEmpty
        }
        
        var body: some View {
            Group {
                if hasPendingItems {
                    // Full view when there are pending items
                    expandedPendingView
                } else {
                    // Compact view when no pending items
                    compactEmptyView
                }
            }
        }
        
        // MARK: - Expanded View (with pending items)
        private var expandedPendingView: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.ksrWarning)
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("Pending Approvals")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    
                    Spacer()
                    
                    // Count badge
                    Text("\(viewModel.allPendingEntriesByTask.flatMap { $0.entries }.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.ksrWarning)
                        .clipShape(Capsule())
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                if isExpanded {
                    // Full pending items list
                    let tasks = Dictionary(grouping: viewModel.allPendingEntriesByTask, by: { $0.taskId })
                    ForEach(tasks.keys.sorted(), id: \.self) { taskId in
                        let taskWeeks = tasks[taskId]!
                        let taskTitle = taskWeeks.first?.taskTitle ?? "Task ID: \(taskId)"
                        let totalPendingHours = calculateTotalPendingHours(for: taskWeeks)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TaskHeaderView(
                                taskId: taskId,
                                taskTitle: taskTitle,
                                totalPendingHours: totalPendingHours,
                                isExpanded: expandedTasks.contains(taskId),
                                toggleExpansion: {
                                    withAnimation(.easeInOut) {
                                        if expandedTasks.contains(taskId) {
                                            expandedTasks.remove(taskId)
                                        } else {
                                            expandedTasks.insert(taskId)
                                        }
                                    }
                                }
                            )
                            
                            if expandedTasks.contains(taskId) {
                                ForEach(taskWeeks) { taskWeekEntry in
                                    NavigationLink(
                                        destination: WeekDetailView(
                                            taskWeekEntry: taskWeekEntry,
                                            onApproveWithSignature: {
                                                onSelectTaskWeek(taskWeekEntry)
                                            },
                                            onReject: { entry in
                                                onSelectEntry(entry)
                                            }
                                        )
                                    ) {
                                        CompactWeekRow(taskWeekEntry: taskWeekEntry)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                } else {
                    // Summary view
                    Text("Tap to view \(viewModel.allPendingEntriesByTask.flatMap { $0.entries }.count) pending entries")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(cardBackground(colorScheme: colorScheme))
            .overlay(
                cardStroke(Color.ksrWarning, opacity: isPulsing ? 0.6 : 0.4)
                    .scaleEffect(isPulsing ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            )
        }
        
        // MARK: - Compact Empty View
        private var compactEmptyView: some View {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.ksrSuccess)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("All Caught Up!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text("No pending approvals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    viewModel.loadData()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.ksrSuccess)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.ksrSuccess.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.ksrSuccess.opacity(0.3), lineWidth: 1)
            )
        }
        
        private func calculateTotalPendingHours(for taskWeeks: [ManagerDashboardViewModel.TaskWeekEntry]) -> Double {
            taskWeeks.reduce(0.0) { sum, week in
                sum + week.entries.reduce(0.0) { innerSum, entry in
                    guard let start = entry.start_time, let end = entry.end_time else { return innerSum }
                    let interval = end.timeIntervalSince(start)
                    let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                    return innerSum + max(0, (interval - pauseSeconds) / 3600)
                }
            }
        }
    }
    
    // MARK: - Compact Week Selector Section
    struct CompactWeekSelectorSection: View {
        @ObservedObject var viewModel: ManagerDashboardViewModel
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Week Selection")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    .padding(.horizontal, 4)
                
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.changeWeek(by: -1)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.ksrPrimary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            )
                    }
                    
                    VStack(spacing: 4) {
                        Text(weekRangeText)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                            .multilineTextAlignment(.center)
                        
                        Text("Selected Week")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        viewModel.changeWeek(by: 1)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.ksrPrimary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            )
                    }
                }
                .padding(16)
                .background(cardBackground(colorScheme: colorScheme))
                .overlay(cardStroke(Color.ksrPrimary))
            }
        }
        
        private var weekRangeText: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: viewModel.selectedMonday)!
            return "\(formatter.string(from: viewModel.selectedMonday)) - \(formatter.string(from: endOfWeek))"
        }
    }
    
    // MARK: - Tasks Section (existing but with consistent styling)
    struct TasksSection: View {
        @ObservedObject var viewModel: ManagerDashboardViewModel
        @Environment(\.colorScheme) private var colorScheme
        @State private var selectedSortOption: TaskSortOption = .name
        @State private var isGridView = false
        
        enum TaskSortOption: String, CaseIterable {
            case name = "Name"
            case deadline = "Deadline"
            case pendingHours = "Pending Hours"
            case project = "Project"
            
            var icon: String {
                switch self {
                case .name: return "textformat.abc"
                case .deadline: return "calendar"
                case .pendingHours: return "clock"
                case .project: return "building.2"
                }
            }
        }
        
        private var sortedTasks: [ManagerAPIService.Task] {
            let tasks = viewModel.supervisorTasks
            switch selectedSortOption {
            case .name:
                return tasks.sorted { $0.title < $1.title }
            case .deadline:
                return tasks.sorted {
                    ($0.deadlineDate ?? Date.distantFuture) < ($1.deadlineDate ?? Date.distantFuture)
                }
            case .pendingHours:
                return tasks.sorted { task1, task2 in
                    let hours1 = calculatePendingHours(for: task1)
                    let hours2 = calculatePendingHours(for: task2)
                    return hours1 > hours2
                }
            case .project:
                return tasks.sorted {
                    ($0.project?.title ?? "") < ($1.project?.title ?? "")
                }
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                tasksSectionHeader
                
                // Controls
                tasksControlsSection
                
                // Content
                tasksContentSection
            }
            .padding(20)
            .background(cardBackground(colorScheme: colorScheme))
            .overlay(cardStroke(Color.ksrPrimary))
        }
        
        // MARK: - Header
        private var tasksSectionHeader: some View {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.ksrPrimary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Supervised Tasks")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    
                    Text("\(viewModel.supervisorTasks.count) tasks assigned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Stats badge
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Pending")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(totalPendingEntries)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(totalPendingEntries > 0 ? Color.ksrWarning : Color.ksrSuccess)
                    }
                    
                    Image(systemName: totalPendingEntries > 0 ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(totalPendingEntries > 0 ? Color.ksrWarning : Color.ksrSuccess)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color.white.opacity(0.8))
                )
            }
        }
        
        // MARK: - Controls
        private var tasksControlsSection: some View {
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
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    )
                }
                
                Spacer()
                
                // View toggle
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isGridView = false
                        }
                    } label: {
                        Image(systemName: "list.bullet")
                            .foregroundColor(isGridView ? .secondary : .primary)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isGridView = true
                        }
                    } label: {
                        Image(systemName: "square.grid.2x2")
                            .foregroundColor(isGridView ? .primary : .secondary)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                )
                
                // Refresh button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.loadData()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.ksrPrimary)
                }
                .disabled(viewModel.isLoading)
            }
        }
        
        // MARK: - Content
        private var tasksContentSection: some View {
            Group {
                if viewModel.isLoading {
                    TasksLoadingView()
                } else if viewModel.supervisorTasks.isEmpty {
                    TasksEmptyStateView()
                } else {
                    if isGridView {
                        tasksGridView
                    } else {
                        tasksListView
                    }
                }
            }
        }
        
        // MARK: - Grid View
        private var tasksGridView: some View {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(sortedTasks) { task in
                    TaskGridCard(
                        task: task,
                        pendingEntriesByTask: viewModel.pendingEntriesByTask
                    )
                }
            }
        }
        
        // MARK: - List View
        private var tasksListView: some View {
            LazyVStack(spacing: 16) {
                ForEach(sortedTasks) { task in
                    EnhancedTaskCard(
                        task: task,
                        pendingEntriesByTask: viewModel.pendingEntriesByTask
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
        private var totalPendingEntries: Int {
            viewModel.pendingEntriesByTask
                .flatMap { $0.entries }
                .count
        }
        
        private func calculatePendingHours(for task: ManagerAPIService.Task) -> Double {
            let taskEntries = viewModel.pendingEntriesByTask
                .filter { $0.taskId == task.task_id }
                .flatMap { $0.entries }
            
            return taskEntries.reduce(0.0) { sum, entry in
                guard let start = entry.start_time, let end = entry.end_time else { return sum }
                let interval = end.timeIntervalSince(start)
                let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                return sum + max(0, (interval - pauseSeconds) / 3600)
            }
        }
    }
    
    // MARK: - Enhanced Task Card
    struct EnhancedTaskCard: View {
        let task: ManagerAPIService.Task
        let pendingEntriesByTask: [ManagerDashboardViewModel.TaskWeekEntry]
        @Environment(\.colorScheme) private var colorScheme
        @State private var showWorkPlanCreator = false
        @State private var isExpanded = false
        
        private var pendingEntries: [ManagerAPIService.WorkHourEntry] {
            pendingEntriesByTask
                .filter { $0.taskId == task.task_id }
                .flatMap { $0.entries }
        }
        
        private var totalPendingHours: Double {
            pendingEntries.reduce(0.0) { sum, entry in
                guard let start = entry.start_time, let end = entry.end_time else { return sum }
                let interval = end.timeIntervalSince(start)
                let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                return sum + max(0, (interval - pauseSeconds) / 3600)
            }
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
                cardStroke(
                    pendingEntries.count > 0 ? Color.ksrWarning : Color.gray,
                    opacity: pendingEntries.count > 0 ? 0.4 : 0.2
                )
            )
            .scaleEffect(pendingEntries.count > 0 ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: pendingEntries.count > 0)
        }
        
        // MARK: - Main Header
        private var mainHeader: some View {
            HStack(spacing: 16) {
                // Status indicator
                VStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        pendingEntries.count > 0 ? Color.ksrWarning : Color.ksrSuccess,
                                        pendingEntries.count > 0 ? Color.ksrWarning.opacity(0.7) : Color.ksrSuccess.opacity(0.7)
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
                    
                    // Priority indicator
                    if pendingEntries.count > 0 {
                        Text("\(pendingEntries.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 18, y: -8)
                    }
                }
                
                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                        .lineLimit(1)
                    
                    if let project = task.project {
                        Label(project.title, systemImage: "building.2")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Status row
                    HStack(spacing: 12) {
                        StatusChip(
                            text: "\(pendingEntries.count) pending",
                            color: pendingEntries.count > 0 ? Color.ksrWarning : Color.ksrSuccess
                        )
                        
                        if totalPendingHours > 0 {
                            StatusChip(
                                text: String(format: "%.1fh", totalPendingHours),
                                color: Color.ksrWarning
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
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
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
                                .foregroundColor(.secondary)
                            
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Deadline
                    if let deadline = task.deadlineDate {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                            
                            Text("Deadline: \(deadline, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Pending entries detail
                    if !pendingEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pending Entries")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ForEach(pendingEntries.prefix(3), id: \.entry_id) { entry in
                                HStack {
                                    Circle()
                                        .fill(Color.ksrWarning)
                                        .frame(width: 6, height: 6)
                                    
                                    Text(entry.employees?.name ?? "Unknown")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(entry.work_date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if pendingEntries.count > 3 {
                                Text("and \(pendingEntries.count - 3) more...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                    showWorkPlanCreator = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("Create Work Plan")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.ksrPrimary,
                                Color.ksrYellow
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
            .sheet(isPresented: $showWorkPlanCreator) {
                WorkPlanCreatorView(
                    task: task,
                    viewModel: CreateWorkPlanViewModel(),
                    isPresented: $showWorkPlanCreator
                )
            }
        }
    }
    
    // MARK: - Task Grid Card
    struct TaskGridCard: View {
        let task: ManagerAPIService.Task
        let pendingEntriesByTask: [ManagerDashboardViewModel.TaskWeekEntry]
        @Environment(\.colorScheme) private var colorScheme
        @State private var showWorkPlanCreator = false
        
        private var pendingEntries: [ManagerAPIService.WorkHourEntry] {
            pendingEntriesByTask
                .filter { $0.taskId == task.task_id }
                .flatMap { $0.entries }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    StatusChip(
                        text: "\(pendingEntries.count)",
                        color: pendingEntries.count > 0 ? Color.ksrWarning : Color.ksrSuccess
                    )
                    
                    Spacer()
                    
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(pendingEntries.count > 0 ? Color.ksrWarning : Color.ksrSuccess)
                        .font(.system(size: 16))
                }
                
                // Title
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Project
                if let project = task.project {
                    Text(project.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Action button
                Button {
                    showWorkPlanCreator = true
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 12))
                        Text("Plan")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.ksrPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
            .frame(height: 160)
            .background(cardBackground(colorScheme: colorScheme))
            .overlay(
                cardStroke(
                    pendingEntries.count > 0 ? Color.ksrWarning : Color.gray,
                    opacity: pendingEntries.count > 0 ? 0.3 : 0.2
                )
            )
            .sheet(isPresented: $showWorkPlanCreator) {
                WorkPlanCreatorView(
                    task: task,
                    viewModel: CreateWorkPlanViewModel(),
                    isPresented: $showWorkPlanCreator
                )
            }
        }
    }
    
    // MARK: - Supporting Components
    struct StatusChip: View {
        let text: String
        let color: Color
        
        var body: some View {
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    struct TasksLoadingView: View {
        var body: some View {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Loading tasks...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 150)
        }
    }
    
    struct TasksEmptyStateView: View {
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "briefcase.badge.questionmark")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text("No supervised tasks")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text("You are not assigned as a supervisor to any tasks. Contact the administrator if this is incorrect.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Task Header View
    struct TaskHeaderView: View {
        let taskId: Int
        let taskTitle: String
        let totalPendingHours: Double
        let isExpanded: Bool
        let toggleExpansion: () -> Void
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            Button(action: toggleExpansion) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.ksrWarning)
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.ksrWarning)
                    Text(taskTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: "%.1f h", totalPendingHours))
                        .font(.caption)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.ksrWarning)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .shadow(radius: 2)
                )
            }
        }
    }
    
    // MARK: - Compact Week Row
    struct CompactWeekRow: View {
        let taskWeekEntry: ManagerDashboardViewModel.TaskWeekEntry
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            let totalHours = taskWeekEntry.entries.reduce(0.0) { sum, entry in
                guard let start = entry.start_time, let end = entry.end_time else { return sum }
                let interval = end.timeIntervalSince(start)
                let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                return sum + max(0, (interval - pauseSeconds) / 3600)
            }
            
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 12))
                    .foregroundColor(Color.ksrWarning)
                Text("Week \(taskWeekEntry.weekNumber), \(taskWeekEntry.year)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                Text("\(taskWeekEntry.entries.count) entries, \(String(format: "%.1f", totalHours))h")
                    .font(.caption)
                    .foregroundColor(Color.ksrWarning)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color.ksrWarning)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.systemBackground))
            )
        }
    }
}
