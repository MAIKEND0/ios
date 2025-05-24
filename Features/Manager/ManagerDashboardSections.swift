//
//  ManagerDashboardSections.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 17/05/2025.
//  Visual improvements added

import SwiftUI

// MARK: - Sekcje ManagerDashboardView
struct ManagerDashboardSections {
    // Sekcja kart podsumowania
    struct SummaryCardsSection: View {
        @ObservedObject var viewModel: ManagerDashboardViewModel
        
        var body: some View {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SummaryCard(
                    title: "Pending Hours",
                    value: "\(viewModel.pendingHoursCount)",
                    icon: "clock.fill",
                    background: DashboardStyles.gradientGreen
                )
                SummaryCard(
                    title: "Active Workers",
                    value: "\(viewModel.activeWorkersCount)",
                    icon: "person.2.fill",
                    background: DashboardStyles.gradientBlue
                )
                SummaryCard(
                    title: "Approved Hours",
                    value: String(format: "%.1f", viewModel.totalApprovedHours),
                    icon: "checkmark.circle.fill",
                    background: DashboardStyles.gradientOrange
                )
                SummaryCard(
                    title: "Tasks Assigned",
                    value: "\(viewModel.supervisorTasks.count)",
                    icon: "briefcase.fill",
                    background: DashboardStyles.gradientPurple
                )
            }
        }
    }

    // Sekcja selektora tygodnia
    struct WeekSelectorSection: View {
        @ObservedObject var viewModel: ManagerDashboardViewModel
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(Color.ksrPrimary)
                    Text("Selected Week")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                }
                HStack {
                    Button(action: {
                        viewModel.changeWeek(by: -1)
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.ksrPrimary)
                    }
                    Text(weekRangeText)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                        .frame(maxWidth: .infinity)
                    Button(action: {
                        viewModel.changeWeek(by: 1)
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.ksrPrimary)
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.15) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        
        private var weekRangeText: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: viewModel.selectedMonday)!
            return "\(formatter.string(from: viewModel.selectedMonday)) - \(formatter.string(from: endOfWeek))"
        }
    }
    
    // MARK: - Improved Tasks Section
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
                // Header with enhanced design
                tasksSectionHeader
                
                // Controls Section
                tasksControlsSection
                
                // Content
                tasksContentSection
            }
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemBackground),
                        colorScheme == .dark ? Color(.systemGray5).opacity(0.1) : Color(.systemGray6).opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.ksrYellow.opacity(0.3),
                                Color.ksrYellow.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                radius: 10,
                x: 0,
                y: 5
            )
        }
        
        // MARK: - Header
        private var tasksSectionHeader: some View {
            HStack(spacing: 12) {
                // Icon with gradient background
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.ksrYellow,
                            Color.ksrPrimary
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Image(systemName: "list.bullet.rectangle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Supervised Tasks")
                        .font(.title2)
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
                        Text("Total Pending")
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
            VStack(spacing: 12) {
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
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.1),
                        radius: pendingEntries.count > 0 ? 8 : 4,
                        x: 0,
                        y: pendingEntries.count > 0 ? 4 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        pendingEntries.count > 0 ?
                            Color.ksrWarning.opacity(0.4) :
                            Color.gray.opacity(0.2),
                        lineWidth: pendingEntries.count > 0 ? 2 : 1
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
                                Color.ksrYellow,
                                Color.ksrPrimary
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        pendingEntries.count > 0 ?
                            Color.ksrWarning.opacity(0.3) :
                            Color.gray.opacity(0.2),
                        lineWidth: 1
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
    
    // MARK: - Status Chip
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
    
    // MARK: - Loading View
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
    
    // MARK: - Empty State View
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
    
    // MARK: - Pending Tasks Section
    struct PendingTasksSection: View {
        @ObservedObject var viewModel: ManagerDashboardViewModel
        @Environment(\.colorScheme) private var colorScheme
        let isPulsing: Bool
        let onSelectTaskWeek: (ManagerDashboardViewModel.TaskWeekEntry) -> Void
        let onSelectEntry: (ManagerAPIService.WorkHourEntry) -> Void
        @State private var expandedTasks: Set<Int> = []
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Color.ksrSuccess)
                        .font(.system(size: 18, weight: .bold))
                    Text("Pending Approvals")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    Spacer()
                    Button {
                        viewModel.loadData()
                    } label: {
                        Text("Refresh")
                            .font(.caption)
                            .foregroundColor(Color.ksrSuccess)
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else if viewModel.allPendingEntriesByTask.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 24))
                            .foregroundColor(Color.gray)
                        Text("No hours pending approval")
                            .font(.subheadline)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    let tasks = Dictionary(grouping: viewModel.allPendingEntriesByTask, by: { $0.taskId })
                    ForEach(tasks.keys.sorted(), id: \.self) { taskId in
                        let taskWeeks = tasks[taskId]!
                        let taskTitle = taskWeeks.first?.taskTitle ?? "Task ID: \(taskId)"
                        let totalPendingHours = calculateTotalPendingHours(for: taskWeeks)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Nagłówek zadania
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
                            
                            // Rozwinięte tygodnie
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
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DashboardStyles.gradientGreen.opacity(colorScheme == .dark ? 0.7 : 1.0))
                    .scaleEffect(isPulsing ? 1.02 : 1.0)
                    .shadow(
                        color: isPulsing ? Color.ksrSuccess.opacity(0.4) : Color.clear,
                        radius: isPulsing ? 8 : 0,
                        x: 0,
                        y: isPulsing ? 4 : 0
                    )
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isPulsing ? Color.ksrSuccess.opacity(0.9) : Color.ksrSuccess.opacity(0.8),
                        lineWidth: isPulsing ? 3 : 2
                    )
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
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
    
    // Widok nagłówka zadania
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
                        .foregroundColor(Color.ksrSuccess)
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.ksrSuccess)
                    Text(taskTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: "%.1f h", totalPendingHours))
                        .font(.caption)
                        .foregroundColor(Color.ksrSuccess)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.ksrSuccess.opacity(0.2))
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
    
    // Kompaktowy wiersz dla tygodnia
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
                    .foregroundColor(Color.ksrSuccess)
                Text("Week \(taskWeekEntry.weekNumber), \(taskWeekEntry.year)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                Text("\(taskWeekEntry.entries.count) entries, \(String(format: "%.1f", totalHours))h")
                    .font(.caption)
                    .foregroundColor(Color.ksrSuccess)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color.ksrSuccess)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.systemBackground))
            )
        }
    }
    
    // MARK: - Original Task Card (for compatibility)
    struct TaskCard: View {
        let task: ManagerAPIService.Task
        let pendingEntriesByTask: [ManagerDashboardViewModel.TaskWeekEntry]
        @Environment(\.colorScheme) private var colorScheme
        @State private var showWorkPlanCreator: Bool = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Nagłówek z ikonką
                HStack(spacing: 12) {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.ksrYellow)
                        .frame(width: 30, height: 30)
                        .background(Color.ksrYellow.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    
                    Spacer()
                    
                    let pendingEntries = pendingEntriesByTask
                        .filter { $0.taskId == task.task_id }
                        .flatMap { $0.entries }
                        .count
                    
                    HStack(spacing: 4) {
                        Text("\(pendingEntries) pending")
                            .font(.caption)
                            .foregroundColor(pendingEntries > 0 ? Color.ksrWarning : Color.ksrSuccess)
                        
                        Image(systemName: pendingEntries > 0 ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(pendingEntries > 0 ? Color.ksrWarning : Color.ksrSuccess)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .padding(.leading, 58)
                
                // Informacje o zadaniu
                VStack(alignment: .leading, spacing: 8) {
                    if let description = task.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        if let project = task.project {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Project: \(project.title)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if let deadline = task.deadlineDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(deadline, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    let taskEntries = pendingEntriesByTask
                        .filter { $0.taskId == task.task_id }
                        .flatMap { $0.entries }
                    let totalHours = taskEntries.reduce(0.0) { sum, entry in
                        guard let start = entry.start_time, let end = entry.end_time else { return sum }
                        let interval = end.timeIntervalSince(start)
                        let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                        return sum + max(0, (interval - pauseSeconds) / 3600)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(Color.ksrWarning)
                        Text("Total Pending Hours: \(totalHours, specifier: "%.2f")h")
                            .font(.caption)
                            .foregroundColor(Color.ksrWarning)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Przycisk Create Work Plan
                HStack {
                    Spacer()
                    Button(action: {
                        showWorkPlanCreator = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(Color.ksrPrimary)
                            Text("Create Work Plan")
                                .font(.caption)
                                .foregroundColor(Color.ksrPrimary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                }
            }
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 2, x: 0, y: 1)
            .sheet(isPresented: $showWorkPlanCreator) {
                WorkPlanCreatorView(
                    task: task,
                    viewModel: CreateWorkPlanViewModel(),
                    isPresented: $showWorkPlanCreator
                )
            }
        }
    }
}
