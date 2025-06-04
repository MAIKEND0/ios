//
//  ChefDashboardView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//

import SwiftUI

struct ChefDashboardView: View {
    @StateObject private var viewModel = ChefDashboardViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Welcome Header
                    welcomeSection
                    
                    // Executive Summary Cards
                    executiveSummarySection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Activity
                    recentActivitySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(dashboardBackground)
            .navigationTitle("Executive Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.refreshData()
                            }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : Color.ksrDarkGray))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .disabled(viewModel.isLoading)
                        
                        Button {
                            // Notifications placeholder
                        } label: {
                            ZStack {
                                Image(systemName: "bell")
                                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                                
                                // Notification badge
                                if viewModel.stats.pendingApprovals > 0 {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 6, y: -6)
                                }
                            }
                        }
                    }
                }
            }
            .refreshable {
                await refreshDashboard()
            }
        }
        .onAppear {
            viewModel.loadData()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    
                    HStack(spacing: 8) {
                        Text("Chief Executive Dashboard")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if viewModel.lastRefreshTime != nil {
                            Text("• Updated \(viewModel.getFormattedLastRefresh())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.ksrYellow.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color.ksrYellow)
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
    
    // MARK: - Executive Summary
    private var executiveSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Business Overview")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ExecutiveSummaryCard(
                    title: "Total Customers",
                    value: "\(viewModel.stats.totalCustomers)",
                    icon: "building.2.fill",
                    color: Color.ksrInfo,
                    trend: "+5 this month"
                )
                
                ExecutiveSummaryCard(
                    title: "Active Projects",
                    value: "\(viewModel.stats.activeProjects)",
                    icon: "folder.fill",
                    color: Color.ksrSuccess,
                    trend: "\(Int(viewModel.stats.projectCompletionRate))% completion"
                )
                
                ExecutiveSummaryCard(
                    title: "Total Workers",
                    value: "\(viewModel.stats.totalWorkers)",
                    icon: "person.3.fill",
                    color: Color.ksrPrimary,
                    trend: "\(viewModel.stats.workersOnAssignment) assigned"
                )
                
                ExecutiveSummaryCard(
                    title: "Monthly Revenue",
                    value: viewModel.stats.monthlyRevenue.currencyFormatted,
                    icon: "banknote.fill",
                    color: Color.ksrWarning,
                    trend: "+12% growth"
                )
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                ChefQuickActionCard(
                    title: "Add Customer",
                    icon: "plus.circle.fill",
                    color: Color.ksrInfo
                ) {
                    viewModel.handleQuickAction(.addCustomer)
                }
                
                ChefQuickActionCard(
                    title: "New Project",
                    icon: "folder.badge.plus",
                    color: Color.ksrSuccess
                ) {
                    viewModel.handleQuickAction(.newProject)
                }
                
                ChefQuickActionCard(
                    title: "Add Worker",
                    icon: "person.badge.plus",
                    color: Color.ksrPrimary
                ) {
                    viewModel.handleQuickAction(.addWorker)
                }
                
                ChefQuickActionCard(
                    title: "Create Task",
                    icon: "plus.square.fill",
                    color: Color.ksrWarning
                ) {
                    viewModel.handleQuickAction(.createTask)
                }
            }
        }
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to full activity view
                }
                .font(.caption)
                .foregroundColor(Color.ksrPrimary)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(viewModel.getRecentActivities().enumerated()), id: \.element.id) { index, activity in
                    RecentActivityItem(
                        icon: activity.icon,
                        title: activity.title,
                        subtitle: activity.subtitle,
                        time: activity.timeAgo,
                        color: activity.color
                    )
                    
                    if index < viewModel.getRecentActivities().count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
                
                if viewModel.getRecentActivities().isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.secondary)
                        
                        Text("No recent activity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 24)
                }
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Background
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
    
    // MARK: - Helper Methods
    
    private func refreshDashboard() async {
        await withCheckedContinuation { continuation in
            viewModel.refreshData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
}

// MARK: - Executive Summary Card
struct ExecutiveSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, value: String, icon: String, color: Color, trend: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 6, height: 6)
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
                
                if let trend = trend {
                    Text(trend)
                        .font(.caption2)
                        .foregroundColor(color)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Chef Quick Action Card
struct ChefQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            action()
        }
    }
}

// MARK: - Recent Activity Item
struct RecentActivityItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview
struct ChefDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChefDashboardView()
                .preferredColorScheme(.light)
            ChefDashboardView()
                .preferredColorScheme(.dark)
        }
    }
}
