//
//  WorkerDashboardView.swift
//  KSR Cranes App
//
//  Enhanced Worker Dashboard with Manager Dashboard styling
//

import SwiftUI

struct WorkerDashboardView: View {
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @State private var showWorkHoursForm = false
    @State private var showFilterOptions = false
    @State private var searchText = ""
    @State private var hasAppeared = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                mainContentView
            }
            .background(dashboardBackground)
            .navigationTitle("Worker Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarContent
                }
            }
            .onAppear {
                handleViewAppear()
            }
            .onChange(of: hasAppeared) { _, _ in
                if hasAppeared {
                    viewModel.loadData()
                }
            }
            .onReceive(Timer.publish(every: 300, on: .main, in: .common).autoconnect()) { _ in
                // Refresh data every 5 minutes
                #if DEBUG
                print("[WorkerDashboardView] Timer triggered refresh, current entries: \(viewModel.hoursViewModel.entries.count)")
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
            .refreshable {
                await refreshData()
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Enhanced Summary Cards
            WorkerDashboardSections.SummaryCardsSection(viewModel: viewModel)
            
            // Quick Actions Row
            quickActionsSection
            
            // Enhanced Tasks Section
            WorkerDashboardSections.TasksSection(
                viewModel: viewModel,
                onTaskSelected: { taskId in
                    viewModel.setSelectedTaskId(taskId)
                    showWorkHoursForm = true
                }
            )
            
            // Enhanced Recent Hours Section
            WorkerDashboardSections.RecentHoursSection(
                viewModel: viewModel,
                onAddHours: {
                    showWorkHoursForm = true
                },
                onViewAll: {
                    // Navigate to work hours view
                }
            )
            
            // Enhanced Announcements Section
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
    
    // MARK: - Toolbar Content
    private var toolbarContent: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.loadData()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(viewModel.tasksViewModel.isLoading || viewModel.hoursViewModel.isLoading)
            
            Button {
                // Handle notifications
            } label: {
                Image(systemName: "bell")
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            // Log Hours Quick Action
            NavigationLink(destination: WorkerWorkHoursView()) {
                QuickActionCard(
                    title: "Work Hours",
                    icon: "clock.fill",
                    color: Color.ksrSuccess,
                    subtitle: "View & log hours"
                )
            }
            
            // Tasks Quick Action
            NavigationLink(destination: WorkerTasksView()) {
                QuickActionCard(
                    title: "My Tasks",
                    icon: "briefcase.fill",
                    color: Color.ksrPrimary,
                    subtitle: "\(viewModel.tasksViewModel.tasks.count) active"
                )
            }
            
            // Profile Quick Action
            NavigationLink(destination: WorkerProfileView()) {
                QuickActionCard(
                    title: "Profile",
                    icon: "person.fill",
                    color: Color.ksrInfo,
                    subtitle: "Settings & info"
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleViewAppear() {
        hasAppeared = true
        viewModel.loadData()
        #if DEBUG
        print("[WorkerDashboardView] View appeared, loading data...")
        #endif
    }
    
    private func refreshData() async {
        await withCheckedContinuation { continuation in
            viewModel.loadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
    
    // MARK: - Dashboard Background
    private var dashboardBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color(.systemBackground),
                colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6).opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Quick Action Card Component
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
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Floating Action Button (for quick access)
struct FloatingLogHoursButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.ksrYellow, Color.ksrPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(
                        color: Color.ksrYellow.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isPressed ? 90 : 0))
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
        }
        .animation(.spring(response: 0.3), value: isPressed)
    }
}

// MARK: - Week Progress Indicator (if needed)
struct WeekProgressIndicator: View {
    let currentHours: Double
    let targetHours: Double = 40.0
    @Environment(\.colorScheme) private var colorScheme
    
    private var progress: Double {
        min(currentHours / targetHours, 1.0)
    }
    
    private var progressColor: Color {
        if progress < 0.5 { return .orange }
        if progress < 0.8 { return .blue }
        if progress < 1.0 { return .green }
        return .red // Overtime
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Week Progress")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text(String(format: "%.1fh of %.0fh", currentHours, targetHours))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if progress > 1.0 {
                    Text("Overtime!")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6))
        )
    }
}

// MARK: - Enhanced Stats Overview (if needed)
struct StatsOverview: View {
    let weeklyHours: Double
    let monthlyHours: Double
    let yearlyHours: Double
    let activeTasks: Int
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatItem(
                    value: String(format: "%.1f", weeklyHours),
                    label: "Week",
                    color: .green
                )
                
                StatItem(
                    value: String(format: "%.1f", monthlyHours),
                    label: "Month",
                    color: .blue
                )
                
                StatItem(
                    value: String(format: "%.1f", yearlyHours),
                    label: "Year",
                    color: .purple
                )
                
                StatItem(
                    value: "\(activeTasks)",
                    label: "Tasks",
                    color: .orange
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Achievement Indicator (if needed)
struct AchievementIndicator: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color : Color.gray)
                    .frame(width: 40, height: 40)
                
                Image(systemName: isUnlocked ? "star.fill" : "star")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6).opacity(0.5))
        )
        .opacity(isUnlocked ? 1.0 : 0.6)
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
