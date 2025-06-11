//
//  WorkerDashboardView.swift
//  KSR Cranes App
//  Z systemem nawigacji po okresach czasowych
//

import SwiftUI

struct WorkerDashboardView: View {
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var showWorkHoursForm = false
    @State private var showFilterOptions = false
    @State private var searchText = ""
    @State private var hasAppeared = false
    @State private var showingDataSuggestion = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                ScrollView {
                    mainContentView
                }
                .background(dashboardBackground)
                .refreshable {
                    await refreshData()
                }
                
                // Data suggestion overlay
                if showingDataSuggestion && viewModel.currentPeriodEntries == 0 && !viewModel.hoursViewModel.entries.isEmpty {
                    dataSuggestionOverlay
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarContent
                }
                
                #if DEBUG
                ToolbarItem(placement: .navigationBarLeading) {
                    debugToolbarButton
                }
                #endif
            }
            .onAppear {
                handleViewAppear()
            }
            .onChange(of: hasAppeared) { _, _ in
                if hasAppeared {
                    viewModel.loadData()
                }
            }
            .onChange(of: viewModel.currentPeriodEntries) { _, newValue in
                // Show suggestion if current period has no data but other periods do
                showingDataSuggestion = (newValue == 0 && !viewModel.hoursViewModel.entries.isEmpty)
            }
            .onReceive(Timer.publish(every: 300, on: .main, in: .common).autoconnect()) { _ in
                // Refresh data every 5 minutes
                #if DEBUG
                print("[WorkerDashboardView] Timer triggered refresh")
                #endif
                viewModel.loadData()
            }
            .sheet(isPresented: $showWorkHoursForm) {
                WeeklyWorkEntryForm(
                    employeeId: AuthService.shared.getEmployeeId() ?? "",
                    taskId: viewModel.getSelectedTaskId(),
                    selectedMonday: Calendar.current.startOfWeek(for: Date())
                )
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Enhanced Summary Cards with Period Navigation
            WorkerDashboardSections.SummaryCardsSection(viewModel: viewModel)
            
            // Quick Actions Row
            quickActionsSection
            
            // Period-aware Tasks Section
            enhancedTasksSection
            
            // Period-aware Recent Hours Section
            enhancedRecentHoursSection
            
            // Announcements Section
            WorkerDashboardSections.AnnouncementsSection(
                viewModel: viewModel,
                onViewAll: {
                    // Navigate to announcements view
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Enhanced Tasks Section
    private var enhancedTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasks for \(viewModel.periodManager.currentPeriod.shortDisplayName)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Spacer()
                
                // Period-specific task count
                let periodTasks = getTasksWithHoursInCurrentPeriod()
                if periodTasks.count > 0 {
                    Text("\(periodTasks.count) active")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            WorkerDashboardSections.TasksSection(
                viewModel: viewModel,
                onTaskSelected: { taskId in
                    viewModel.setSelectedTaskId(taskId)
                    showWorkHoursForm = true
                }
            )
        }
    }
    
    // MARK: - Enhanced Recent Hours Section
    private var enhancedRecentHoursSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Hours for \(viewModel.periodManager.currentPeriod.shortDisplayName)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Spacer()
                
                if viewModel.currentPeriodEntries > 0 {
                    Text("\(viewModel.currentPeriodEntries) entries")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            recentHoursContent
            
            // Add Hours Button with period context
            Button {
                showWorkHoursForm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Add Hours for \(viewModel.periodManager.selectedType.rawValue)")
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
        .background(WorkerDashboardSections.cardBackground(colorScheme: colorScheme))
        .overlay(WorkerDashboardSections.cardStroke(Color.ksrSuccess))
    }
    
    private var recentHoursContent: some View {
        Group {
            if viewModel.hoursViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                let periodEntries = viewModel.periodManager.getEntriesForCurrentPeriod(viewModel.hoursViewModel.entries)
                
                if periodEntries.isEmpty {
                    EmptyPeriodHoursView(period: viewModel.periodManager.currentPeriod)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(periodEntries.prefix(3)) { entry in
                            WorkerDashboardSections.EnhancedWorkHourCard(entry: entry)
                        }
                        
                        if periodEntries.count > 3 {
                            Button("View all \(periodEntries.count) entries") {
                                // Navigate to detailed hours view
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Data Suggestion Overlay
    private var dataSuggestionOverlay: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No data for current period")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("You have \(viewModel.hoursViewModel.entries.count) entries in other periods")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        showingDataSuggestion = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 12) {
                    Button("Show recent data") {
                        if let suggestedPeriod = viewModel.periodManager.findBestPeriodForData(viewModel.hoursViewModel.entries) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.periodManager.selectPeriod(suggestedPeriod)
                            }
                        }
                        showingDataSuggestion = false
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button("Stay here") {
                        showingDataSuggestion = false
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(radius: 10)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .background(
            Color.black.opacity(0.3)
                .onTapGesture {
                    showingDataSuggestion = false
                }
        )
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        ))
        .animation(.spring(response: 0.3), value: showingDataSuggestion)
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some View {
        HStack(spacing: 12) {
            // Period navigation shortcuts
            Menu {
                Button("Previous \(viewModel.periodManager.selectedType.rawValue)") {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.goToPreviousPeriod()
                    }
                }
                
                Button("Next \(viewModel.periodManager.selectedType.rawValue)") {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.goToNextPeriod()
                    }
                }
                .disabled(!viewModel.periodManager.canNavigateNext)
                
                Divider()
                
                Button("Current \(viewModel.periodManager.selectedType.rawValue)") {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.goToCurrentPeriod()
                    }
                }
                
                Divider()
                
                ForEach(TimePeriodType.allCases, id: \.self) { type in
                    Button("\(type.rawValue) View") {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.changePeriodType(to: type)
                        }
                    }
                }
            } label: {
                Image(systemName: "calendar")
                    .foregroundColor(Color.ksrTextPrimary)
            }
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.loadData()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(Color.ksrTextPrimary)
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(viewModel.tasksViewModel.isLoading || viewModel.hoursViewModel.isLoading)
            
            NavigationLink(destination: NotificationsView()) {
                ZStack {
                    Image(systemName: "bell")
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    // Notification badge
                    if notificationService.unreadCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 6, y: -6)
                    }
                }
            }
        }
    }
    
    // MARK: - Debug Toolbar Button
    #if DEBUG
    private var debugToolbarButton: some View {
        Button("Debug") {
            print("\n🐛 === ENHANCED DASHBOARD DEBUG ===")
            viewModel.debugCurrentState()
            viewModel.testAPIConnection()
            print("🐛 === END ENHANCED DEBUG ===\n")
        }
        .foregroundColor(.orange)
        .font(.caption)
    }
    #endif
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            // Log Hours Quick Action with period context
            Button {
                showWorkHoursForm = true
            } label: {
                QuickActionCard(
                    title: "Log Hours",
                    icon: "clock.fill",
                    color: Color.ksrSuccess,
                    subtitle: "For \(viewModel.periodManager.selectedType.shortName)"
                )
            }
            
            // Tasks Quick Action
            NavigationLink(destination: WorkerTasksView()) {
                QuickActionCard(
                    title: "My Tasks",
                    icon: "briefcase.fill",
                    color: Color.ksrPrimary,
                    subtitle: "\(viewModel.tasksViewModel.tasks.count) total"
                )
            }
            
            // Period Stats Quick Action
            Menu {
                Button("Week View") { viewModel.changePeriodType(to: .week) }
                Button("Month View") { viewModel.changePeriodType(to: .month) }
                Button("14 Days View") { viewModel.changePeriodType(to: .twoWeeks) }
            } label: {
                QuickActionCard(
                    title: "Period Stats",
                    icon: "chart.bar.fill",
                    color: Color.ksrInfo,
                    subtitle: "\(viewModel.currentPeriodEntries) entries"
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleViewAppear() {
        if !hasAppeared {
            hasAppeared = true
            viewModel.loadData()
            #if DEBUG
            print("[WorkerDashboardView] View appeared, loading data...")
            #endif
        }
    }
    
    private func refreshData() async {
        #if DEBUG
        print("[WorkerDashboardView] Pull to refresh triggered")
        #endif
        
        await withCheckedContinuation { continuation in
            viewModel.loadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                continuation.resume()
            }
        }
    }
    
    private func getTasksWithHoursInCurrentPeriod() -> [WorkerAPIService.Task] {
        let periodEntries = viewModel.periodManager.getEntriesForCurrentPeriod(viewModel.hoursViewModel.entries)
        let taskIds = Set(periodEntries.map { $0.task_id })
        return viewModel.tasksViewModel.tasks.filter { taskIds.contains($0.task_id) }
    }
    
    // MARK: - Dashboard Background
    private var dashboardBackground: some View {
        Color.backgroundGradient
            .ignoresSafeArea()
    }
}

// MARK: - Empty Period Hours View
struct EmptyPeriodHoursView: View {
    let period: TimePeriod
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Color.ksrTextSecondary)
            
            Text("No hours recorded")
                .font(.headline)
                .foregroundColor(Color.ksrTextPrimary)
            
            Text("for \(period.displayName)")
                .font(.subheadline)
                .foregroundColor(Color.ksrTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(.vertical, 20)
    }
}

// MARK: - Updated Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let subtitle: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.ksrTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ksrMediumGray)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WorkerDashboardView()
                .preferredColorScheme(.light)
            
            WorkerDashboardView()
                .preferredColorScheme(.dark)
        }
    }
}
