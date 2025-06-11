//
//  PayrollDashboardView.swift
//  KSR Cranes App
//
//  Główny dashboard systemu payroll dla Chef
//

import SwiftUI

struct PayrollDashboardView: View {
    @StateObject private var viewModel = PayrollDashboardViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header z okresem payroll
                    payrollHeaderSection
                    
                    // Quick stats overview
                    quickStatsSection
                    
                    // Progress bar for current period
                    currentPeriodProgressSection
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Pending items summary
                    pendingItemsSection
                    
                    // Recent activity
                    recentActivitySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(dashboardBackground)
            .navigationTitle("Payroll Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            viewModel.refreshData()
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(viewModel.isLoading)
                        
                        NavigationLink(destination: PayrollReportsView()) {
                            Image(systemName: "chart.bar")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refreshAsync()
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
        // Navigation handling
        .navigationDestination(isPresented: $viewModel.navigateToPendingHours) {
            PendingHoursView()
        }
        .navigationDestination(isPresented: $viewModel.navigateToCreateBatch) {
            CreateBatchView()
        }
        .navigationDestination(isPresented: $viewModel.navigateToBatches) {
            PayrollBatchesView()
        }
        .navigationDestination(isPresented: $viewModel.navigateToReports) {
            PayrollReportsView()
        }
    }
    
    // MARK: - Header Section
    private var payrollHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payroll Management")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrTextPrimary)
                    
                    HStack(spacing: 8) {
                        Text("Current Period:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.currentPeriodText)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ksrPrimary)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.ksrWarning.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "banknote")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.ksrWarning)
                }
            }
            .padding(16)
            .background(cardBackground)
        }
    }
    
    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.ksrTextPrimary)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                PayrollStatCard(
                    title: "Pending Hours",
                    value: "\(viewModel.stats.pendingHours)",
                    subtitle: "hrs to review",
                    icon: "clock.badge.exclamationmark",
                    color: Color.ksrWarning,
                    trend: nil
                )
                
                PayrollStatCard(
                    title: "Ready Employees",
                    value: "\(viewModel.stats.readyEmployees)",
                    subtitle: "for payroll",
                    icon: "person.3.fill",
                    color: Color.ksrSuccess,
                    trend: nil
                )
                
                PayrollStatCard(
                    title: "Total Amount",
                    value: viewModel.stats.totalAmount.currencyFormatted,
                    subtitle: "this period",
                    icon: "banknote.fill",
                    color: Color.ksrInfo,
                    trend: "+5.2%"
                )
                
                PayrollStatCard(
                    title: "Batches",
                    value: "\(viewModel.stats.activeBatches)",
                    subtitle: "in progress",
                    icon: "tray.full.fill",
                    color: Color.ksrPrimary,
                    trend: nil
                )
            }
        }
    }
    
    // MARK: - Current Period Progress
    private var currentPeriodProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Period Progress")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.ksrTextPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Week \(viewModel.currentWeek) of 2")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ksrTextPrimary)
                        
                        Text("\(viewModel.daysRemaining) days remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.periodProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrPrimary)
                }
                
                ProgressView(value: viewModel.periodProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.ksrPrimary))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                HStack {
                    Text(viewModel.periodStartDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.periodEndDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(cardBackground)
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.ksrTextPrimary)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                PayrollActionCard(
                    title: "Review Hours",
                    subtitle: "\(viewModel.stats.pendingHours) pending",
                    icon: "clock.arrow.circlepath",
                    color: Color.ksrWarning,
                    badgeCount: viewModel.stats.pendingHours > 0 ? viewModel.stats.pendingHours : nil
                ) {
                    viewModel.PDVMnavigateToPendingHours()
                }
                
                PayrollActionCard(
                    title: "Create Batch",
                    subtitle: "New payroll batch",
                    icon: "plus.rectangle.on.folder",
                    color: Color.ksrSuccess,
                    badgeCount: nil
                ) {
                    viewModel.PDVMnavigateToCreateBatch()
                }
                
                PayrollActionCard(
                    title: "View Batches",
                    subtitle: "\(viewModel.stats.activeBatches) active",
                    icon: "tray.2.fill",
                    color: Color.ksrInfo,
                    badgeCount: viewModel.stats.activeBatches > 0 ? viewModel.stats.activeBatches : nil
                ) {
                    viewModel.PDVMnavigateToBatches()
                }
                
                PayrollActionCard(
                    title: "Reports",
                    subtitle: "Analytics & export",
                    icon: "chart.bar.doc.horizontal",
                    color: Color.ksrPrimary,
                    badgeCount: nil
                ) {
                    viewModel.PDVMnavigateToReports()
                }
            }
        }
    }
    
    // MARK: - Pending Items Summary
    private var pendingItemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Requires Attention")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.ksrTextPrimary)
                
                Spacer()
                
                if viewModel.pendingItems.count > 3 {
                    Button("View All") {
                        viewModel.PDVMnavigateToPendingHours()
                    }
                    .font(.caption)
                    .foregroundColor(.ksrPrimary)
                }
            }
            .padding(.horizontal, 4)
            
            if viewModel.pendingItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.ksrSuccess)
                    
                    Text("All caught up!")
                        .font(.headline)
                        .foregroundColor(.ksrTextPrimary)
                    
                    Text("No items require your attention")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(cardBackground)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.pendingItems.prefix(3).enumerated()), id: \.element.id) { index, item in
                        PendingItemRow(item: item)
                        
                        if index < min(viewModel.pendingItems.count - 1, 2) {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(cardBackground)
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
                    .foregroundColor(.ksrTextPrimary)
                
                Spacer()
                
                NavigationLink("View All", destination: PayrollActivityView())
                    .font(.caption)
                    .foregroundColor(.ksrPrimary)
            }
            .padding(.horizontal, 4)
            
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.recentActivity.prefix(5).enumerated()), id: \.element.id) { index, activity in
                    PayrollActivityRow(activity: activity)
                    
                    if index < min(viewModel.recentActivity.count - 1, 4) {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(cardBackground)
        }
    }
    
    // MARK: - Background & Styling
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
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Payroll Stat Card
struct PayrollStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: String?
    @Environment(\.colorScheme) private var colorScheme
    
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
                
                if let trend = trend {
                    Text(trend)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrSuccess)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.ksrSuccess.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.ksrTextPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(color)
                    .lineLimit(1)
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

// MARK: - Payroll Action Card
struct PayrollActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let badgeCount: Int?
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
                    
                    if let badgeCount = badgeCount, badgeCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("\(badgeCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                            .offset(x: 15, y: -15)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
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
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Pending Item Row
struct PendingItemRow: View {
    let item: PayrollPendingItem
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.priority.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(item.priority.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ksrTextPrimary)
                    .lineLimit(1)
                
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if item.requiresAction {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Payroll Activity Row
struct PayrollActivityRow: View {
    let activity: PayrollActivity
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: activity.type.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(activity.type.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ksrTextPrimary)
                    .lineLimit(1)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(activity.timeAgo)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview
struct PayrollDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PayrollDashboardView()
                .preferredColorScheme(.light)
            PayrollDashboardView()
                .preferredColorScheme(.dark)
        }
    }
}
