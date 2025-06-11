//
//  ChefDashboardView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//  Updated with Payroll Integration - FIXED VERSION
//

import SwiftUI

struct ChefDashboardView: View {
    @StateObject private var viewModel = ChefDashboardViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showNotifications = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Welcome Header
                    welcomeSection
                    
                    // Executive Summary Cards
                    executiveSummarySection
                    
                    // Payroll Overview Section
                    payrollStatsSection
                    
                    // Enhanced Quick Actions with Payroll
                    enhancedQuickActionsSection
                    
                    // Enhanced Recent Activity with Payroll Events
                    enhancedRecentActivitySection
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
                            showNotifications = true
                        } label: {
                            ZStack {
                                Image(systemName: "bell")
                                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                                
                                // Enhanced notification badge including payroll alerts
                                let badgeCount = viewModel.stats.pendingApprovals + (viewModel.shouldShowPayrollAlert ? 1 : 0)
                                if badgeCount > 0 {
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
            .navigationDestination(item: $viewModel.selectedNavigationDestination) { destination in
                switch destination {
                case .payrollDashboard:
                    PayrollDashboardView()
                case .pendingHours:
                    PendingHoursView()
                case .payrollBatches:
                    PayrollBatchesView()
                case .createBatch:
                    CreateBatchView()
                case .leaveManagement:
                    ChefLeaveManagementView()
                }
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
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
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
            
            // Payroll Alert Banner
            if viewModel.shouldShowPayrollAlert {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Payroll Attention Required")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(viewModel.getPayrollAlertMessage())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: PayrollDashboardView()) {
                        Text("Review")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
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
    
    // MARK: - Payroll Stats Integration
    var payrollStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Payroll Overview")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                Spacer()
                
                NavigationLink("View All", destination: PayrollDashboardView())
                    .font(.caption)
                    .foregroundColor(Color.ksrPrimary)
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ExecutiveSummaryCard(
                    title: "Pending Hours",
                    value: "\(viewModel.payrollStats.pendingHours)",
                    icon: "clock.badge.exclamationmark",
                    color: viewModel.payrollStats.pendingHours > 0 ? Color.ksrWarning : Color.ksrSuccess,
                    trend: viewModel.payrollStats.pendingHours > 0 ? "Requires attention" : "All caught up"
                )
                
                ExecutiveSummaryCard(
                    title: "Monthly Payroll",
                    value: viewModel.payrollStats.monthlyAmount.shortCurrencyFormatted,
                    icon: "banknote.fill",
                    color: Color.ksrSuccess,
                    trend: "+8.5% vs last month"
                )
                
                ExecutiveSummaryCard(
                    title: "Active Batches",
                    value: "\(viewModel.payrollStats.activeBatches)",
                    icon: "tray.full.fill",
                    color: Color.ksrInfo,
                    trend: viewModel.payrollStats.activeBatches > 0 ? "\(viewModel.payrollStats.activeBatches) in progress" : "None active"
                )
                
                ExecutiveSummaryCard(
                    title: "Ready Employees",
                    value: "\(viewModel.payrollStats.readyEmployees)",
                    icon: "person.3.fill",
                    color: Color.ksrPrimary,
                    trend: "For next payroll"
                )
            }
        }
    }
    
    // MARK: - Enhanced Quick Actions with Payroll
    var enhancedQuickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                .padding(.horizontal, 4)
            
            // Top row - existing actions
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
            
            // Middle row - leave management
            HStack(spacing: 12) {
                ChefQuickActionCard(
                    title: "Leave Management",
                    icon: "calendar.badge.exclamationmark",
                    color: Color.purple,
                    badgeCount: viewModel.pendingLeaveRequests
                ) {
                    viewModel.handleQuickAction(.leaveManagement)
                }
                
                Spacer()
            }
            
            // Bottom row - payroll actions
            HStack(spacing: 12) {
                ChefQuickActionCard(
                    title: "Payroll Dashboard",
                    icon: "banknote.fill",
                    color: Color.ksrWarning,
                    badgeCount: viewModel.payrollStats.pendingHours > 0 ? viewModel.payrollStats.pendingHours : nil
                ) {
                    viewModel.handleQuickAction(.payrollDashboard)
                }
                
                ChefQuickActionCard(
                    title: "Pending Hours",
                    icon: "clock.badge.exclamationmark",
                    color: Color.ksrError,
                    badgeCount: viewModel.payrollStats.pendingHours
                ) {
                    viewModel.handleQuickAction(.pendingHours)
                }
                
                ChefQuickActionCard(
                    title: "Payroll Batches",
                    icon: "tray.full.fill",
                    color: Color.ksrInfo,
                    badgeCount: viewModel.payrollStats.activeBatches > 0 ? viewModel.payrollStats.activeBatches : nil
                ) {
                    viewModel.handleQuickAction(.payrollBatches)
                }
                
                ChefQuickActionCard(
                    title: "Create Batch",
                    icon: "plus.rectangle.on.folder",
                    color: Color.ksrSuccess
                ) {
                    viewModel.handleQuickAction(.createBatch)
                }
            }
        }
    }
    
    // MARK: - Enhanced Recent Activity with Payroll Events
    var enhancedRecentActivitySection: some View {
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
                // Combine regular activities with payroll activities
                ForEach(Array(viewModel.getCombinedRecentActivities().prefix(5).enumerated()), id: \.element.id) { index, activity in
                    RecentActivityItem(
                        icon: activity.icon,
                        title: activity.title,
                        subtitle: activity.subtitle,
                        time: activity.timeAgo,
                        color: activity.color
                    )
                    
                    if index < min(viewModel.getCombinedRecentActivities().count - 1, 4) {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
                
                if viewModel.getCombinedRecentActivities().isEmpty {
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

// MARK: - Enhanced Chef Quick Action Card with Badge Support
struct ChefQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let badgeCount: Int?
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    init(title: String, icon: String, color: Color, badgeCount: Int? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.badgeCount = badgeCount
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                // Badge overlay
                if let badgeCount = badgeCount, badgeCount > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(badgeCount > 99 ? "99+" : "\(badgeCount)")")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.7)
                        )
                        .offset(x: 15, y: -15)
                }
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
        .onTapGesture {
            #if DEBUG
            print("[ChefQuickActionCard] Tap gesture triggered for: \(title)")
            #endif
            
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
