//
//  ChefLeaveManagementView.swift
//  KSR Cranes App
//
//  Chef Leave Management Interface
//  Main dashboard for managing team leave requests and analytics
//

import SwiftUI
import UIKit

struct ChefLeaveManagementView: View {
    @StateObject private var viewModel = ChefLeaveManagementViewModel()
    @State private var selectedTab = 0
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                // Statistics Header
                if let statistics = viewModel.leaveStatistics {
                    LeaveStatisticsHeaderView(statistics: statistics)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // Tab Selection
                Picker("Tabs", selection: $selectedTab) {
                    Text("Approvals").tag(0)
                    Text("Team").tag(1)
                    Text("Calendar").tag(2)
                    Text("Analytics").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Pending Approvals
                    PendingApprovalsView(viewModel: viewModel)
                        .tag(0)
                    
                    // Team Overview
                    TeamLeaveOverviewView(viewModel: viewModel)
                        .tag(1)
                    
                    // Team Calendar
                    TeamLeaveCalendarView(viewModel: viewModel)
                        .tag(2)
                    
                    // Analytics
                    TeamLeaveAnalyticsView(viewModel: viewModel)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Leave Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Data") {
                            exportData()
                        }
                        
                        Button("Fix Balances") {
                            Task {
                                await viewModel.recalculateAllBalances()
                            }
                        }
                        
                        Button("Refresh") {
                            viewModel.refreshData()
                        }
                        
                        Button("Filters") {
                            showingFilters = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                viewModel.refreshData()
            }
            .overlay {
                if viewModel.isLoading && viewModel.pendingRequests.isEmpty {
                    ProgressView("Loading...")
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Success", isPresented: $viewModel.showingSuccessAlert) {
                Button("OK") {
                    viewModel.successMessage = nil
                }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .sheet(isPresented: $showingFilters) {
                Text("Filters - Coming Soon")
            }
        }
        .onAppear {
            if viewModel.pendingRequests.isEmpty {
                viewModel.loadInitialData()
            }
        }
    }
    
    private func exportData() {
        viewModel.exportLeaveData(format: .csv) { downloadURL in
            if let url = downloadURL {
                // Open URL for download
                if let downloadURL = URL(string: url) {
                    UIApplication.shared.open(downloadURL)
                }
            }
        }
    }
}

// MARK: - Statistics Header

struct LeaveStatisticsHeaderView: View {
    let statistics: LeaveStatistics
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Team Overview")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Updated now")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quick response time indicator
                HStack(spacing: 3) {
                    Circle()
                        .fill(responseTimeColor)
                        .frame(width: 6, height: 6)
                    
                    Text(responseTimeText)
                        .font(.caption2)
                        .foregroundColor(responseTimeColor)
                }
            }
            
            // Main statistics
            HStack(spacing: 12) {
                EnhancedStatisticItem(
                    title: "Pending",
                    value: statistics.pending_requests,
                    color: .orange,
                    icon: "clock.fill",
                    isUrgent: statistics.pending_requests > 5
                )
                
                EnhancedStatisticItem(
                    title: "On Leave",
                    value: statistics.team_on_leave_today,
                    color: .blue,
                    icon: "person.crop.circle.badge.minus",
                    subtitle: "Today"
                )
                
                EnhancedStatisticItem(
                    title: "This Week",
                    value: statistics.team_on_leave_this_week,
                    color: .green,
                    icon: "calendar.badge.minus",
                    subtitle: "\(statistics.team_on_leave_this_week) people"
                )
                
                EnhancedStatisticItem(
                    title: "Approval",
                    value: approvalRate,
                    color: approvalRateColor,
                    icon: "checkmark.circle.fill",
                    subtitle: "\(approvalRate)%",
                    showPercentage: true
                )
            }
            
            // Additional insights
            if statistics.pending_requests > 0 || statistics.team_on_leave_today > 0 {
                HStack {
                    if statistics.pending_requests > 0 {
                        QuickInsightChip(
                            text: "\(statistics.pending_requests) awaiting approval",
                            color: .orange,
                            icon: "exclamationmark.circle.fill"
                        )
                    }
                    
                    if statistics.team_on_leave_today > 0 {
                        QuickInsightChip(
                            text: "\(statistics.team_on_leave_today) on leave today",
                            color: .blue,
                            icon: "person.fill.checkmark"
                        )
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
    }
    
    private var approvalRate: Int {
        let total = statistics.approved_requests + statistics.rejected_requests
        guard total > 0 else { return 100 }
        return Int(Double(statistics.approved_requests) / Double(total) * 100)
    }
    
    private var approvalRateColor: Color {
        if approvalRate >= 90 {
            return .green
        } else if approvalRate >= 75 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var responseTimeColor: Color {
        guard let hours = statistics.average_response_time_hours else { return .gray }
        if hours <= 24 {
            return .green
        } else if hours <= 72 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var responseTimeText: String {
        guard let hours = statistics.average_response_time_hours else { return "N/A" }
        if hours < 24 {
            return "< 1 day"
        } else {
            return "\(Int(hours / 24)) day\(Int(hours / 24) == 1 ? "" : "s")"
        }
    }
}

struct EnhancedStatisticItem: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String
    let subtitle: String?
    let isUrgent: Bool
    let showPercentage: Bool
    
    init(title: String, value: Int, color: Color, icon: String, subtitle: String? = nil, isUrgent: Bool = false, showPercentage: Bool = false) {
        self.title = title
        self.value = value
        self.color = color
        self.icon = icon
        self.subtitle = subtitle
        self.isUrgent = isUrgent
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(isUrgent ? .red : color)
            
            Text("\(value)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isUrgent ? .red : color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isUrgent ? Color.red.opacity(0.1) : color.opacity(0.1))
        )
    }
}

struct QuickInsightChip: View {
    let text: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

struct StatisticItem: View {
    let title: String
    let value: Int
    let color: Color
    let isUrgent: Bool
    
    init(title: String, value: Int, color: Color, isUrgent: Bool = false) {
        self.title = title
        self.value = value
        self.color = color
        self.isUrgent = isUrgent
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isUrgent ? .red : color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pending Approvals View

struct PendingApprovalsView: View {
    @ObservedObject var viewModel: ChefLeaveManagementViewModel
    @State private var showingBulkActions = false
    @State private var selectedRequests: Set<Int> = []
    
    var body: some View {
        VStack {
            // Actions Bar
            if !viewModel.pendingRequests.isEmpty {
                HStack {
                    if selectedRequests.isEmpty {
                        Text("\(viewModel.pendingRequests.count) anmodning(er)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(selectedRequests.count) valgt")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    if !selectedRequests.isEmpty {
                        Button("Godkend alle") {
                            bulkApproveSelected()
                        }
                        .foregroundColor(.green)
                        
                        Button("Ryd") {
                            selectedRequests.removeAll()
                        }
                        .foregroundColor(.red)
                    }
                    
                    Button(selectedRequests.isEmpty ? "Vælg" : "Afslut") {
                        if selectedRequests.isEmpty {
                            showingBulkActions = true
                        } else {
                            selectedRequests.removeAll()
                        }
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
            }
            
            if viewModel.pendingRequests.isEmpty {
                VStack {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("Ingen ventende anmodninger")
                        .font(.headline)
                    Text("Alle orlovsanmodninger er behandlet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List {
                    // Urgent requests section
                    if !viewModel.urgentPendingRequests.isEmpty {
                        Section("Haster - starter inden 2 dage") {
                            ForEach(viewModel.urgentPendingRequests) { request in
                                LeaveRequestApprovalRow(
                                    request: request,
                                    isSelected: selectedRequests.contains(request.id),
                                    isSelectionMode: showingBulkActions,
                                    onToggleSelection: { toggleSelection(request.id) },
                                    onApprove: { viewModel.approveLeaveRequest(request) },
                                    onReject: { reason in viewModel.rejectLeaveRequest(request, reason: reason) },
                                    onShowDetails: { 
                                        print("DEBUG: onShowDetails called for request ID: \(request.id)")
                                        print("DEBUG: Request employee: \(request.employee?.name ?? "nil")")
                                        viewModel.showLeaveRequestDetail(request)
                                    }
                                )
                            }
                        }
                    }
                    
                    // Regular requests
                    let regularRequests = viewModel.pendingRequests.filter { request in
                        !viewModel.urgentPendingRequests.contains { $0.id == request.id }
                    }
                    
                    if !regularRequests.isEmpty {
                        Section("Øvrige anmodninger") {
                            ForEach(regularRequests) { request in
                                LeaveRequestApprovalRow(
                                    request: request,
                                    isSelected: selectedRequests.contains(request.id),
                                    isSelectionMode: showingBulkActions,
                                    onToggleSelection: { toggleSelection(request.id) },
                                    onApprove: { viewModel.approveLeaveRequest(request) },
                                    onReject: { reason in viewModel.rejectLeaveRequest(request, reason: reason) },
                                    onShowDetails: { 
                                        print("DEBUG: onShowDetails called for request ID: \(request.id)")
                                        print("DEBUG: Request employee: \(request.employee?.name ?? "nil")")
                                        viewModel.showLeaveRequestDetail(request)
                                    }
                                )
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingDetailModal) {
            if let request = viewModel.selectedRequestForDetail {
                ChefLeaveRequestDetailView(
                    request: request,
                    onApprove: { 
                        viewModel.approveLeaveRequest(request) 
                        viewModel.hideLeaveRequestDetail()
                    },
                    onReject: { reason in 
                        viewModel.rejectLeaveRequest(request, reason: reason)
                        viewModel.hideLeaveRequestDetail()
                    }
                )
                .onAppear {
                    print("DEBUG: Sheet showing request: \(request.id)")
                    print("DEBUG: Request employee: \(request.employee?.name ?? "nil")")
                }
            } else {
                VStack {
                    Text("ERROR: No request selected")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text("This should not happen")
                        .font(.caption)
                    Text("selectedRequestForDetail is nil")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Button("Close") {
                        viewModel.hideLeaveRequestDetail()
                    }
                }
                .padding()
                .onAppear {
                    print("DEBUG: Sheet opened but ViewModel selectedRequestForDetail is nil")
                }
            }
        }
    }
    
    private func toggleSelection(_ requestId: Int) {
        if selectedRequests.contains(requestId) {
            selectedRequests.remove(requestId)
        } else {
            selectedRequests.insert(requestId)
        }
    }
    
    private func bulkApproveSelected() {
        let requestsToApprove = viewModel.pendingRequests.filter { selectedRequests.contains($0.id) }
        viewModel.bulkApproveRequests(requestsToApprove) { successful, total in
            selectedRequests.removeAll()
            showingBulkActions = false
            // Show success message
        }
    }
}

// MARK: - Leave Request Approval Row

struct LeaveRequestApprovalRow: View {
    let request: LeaveRequest
    let isSelected: Bool
    let isSelectionMode: Bool
    let onToggleSelection: () -> Void
    let onApprove: () -> Void
    let onReject: (String) -> Void
    let onShowDetails: () -> Void
    
    var body: some View {
        HStack {
            // Selection checkbox
            if isSelectionMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Request details - clickable to show details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.employee?.name ?? "Employee #\(request.employee_id)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(request.type.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if isUrgent {
                            Text("HASTER")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        
                        Text("\(request.total_days) dag(e)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(formattedDateRange)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                if let reason = request.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Status indicator
                if !isSelectionMode {
                    HStack {
                        Image(systemName: "hand.tap")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("Tryk for at se detaljer og godkende/afvise")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                print("DEBUG: Row tapped for request ID: \(request.id), isSelectionMode: \(isSelectionMode)")
                if !isSelectionMode {
                    print("DEBUG: Calling onShowDetails for request: \(request.id)")
                    onShowDetails()
                } else {
                    print("DEBUG: In selection mode, ignoring tap")
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var isUrgent: Bool {
        let twoDaysFromNow = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        return request.start_date <= twoDaysFromNow
    }
    
    private var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if Calendar.current.isDate(request.start_date, inSameDayAs: request.end_date) {
            return formatter.string(from: request.start_date)
        } else {
            return "\(formatter.string(from: request.start_date)) - \(formatter.string(from: request.end_date))"
        }
    }
}

// MARK: - Team Leave Overview

struct TeamLeaveOverviewView: View {
    @ObservedObject var viewModel: ChefLeaveManagementViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Employees on leave today
                if !viewModel.employeesOnLeaveToday.isEmpty {
                    EmployeesOnLeaveCard(
                        title: "På orlov i dag",
                        employees: viewModel.employeesOnLeaveToday,
                        color: .blue
                    )
                }
                
                // Low vacation balance alerts
                if !viewModel.employeesWithLowVacationBalance.isEmpty {
                    LowBalanceAlertCard(employees: viewModel.employeesWithLowVacationBalance)
                }
                
                // Team balances
                ForEach(viewModel.teamBalances) { employeeBalance in
                    TeamMemberBalanceCard(employeeBalance: employeeBalance)
                }
            }
            .padding()
        }
    }
}

struct EmployeesOnLeaveCard: View {
    let title: String
    let employees: [EmployeeLeaveDay]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(employees.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            ForEach(employees, id: \.employee_id) { employee in
                HStack {
                    // Profile image placeholder
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(employee.employee_name.prefix(1)))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(employee.employee_name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(employee.leave_type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if employee.is_half_day {
                        Text("Halv dag")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LowBalanceAlertCard: View {
    let employees: [EmployeeLeaveBalance]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Lav feriesaldo")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            ForEach(employees) { employee in
                HStack {
                    Text(employee.employee_name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(employee.balance.vacation_days_remaining) dage tilbage")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TeamMemberBalanceCard: View {
    let employeeBalance: EmployeeLeaveBalance
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Profile image placeholder
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(employeeBalance.employee_name.prefix(1)))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(employeeBalance.employee_name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(employeeBalance.role.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("Ferie")
                        .font(.caption)
                    Text("\(employeeBalance.balance.vacation_days_remaining)/\(employeeBalance.balance.vacation_days_total)")
                        .foregroundColor(.green)
                }
                
                VStack {
                    Text("Personligt")
                        .font(.caption)
                    Text("\(employeeBalance.balance.personal_days_remaining)/\(employeeBalance.balance.personal_days_total)")
                        .foregroundColor(.orange)
                }
                
                VStack {
                    Text("Sygedage")
                        .font(.caption)
                    Text("\(employeeBalance.balance.sick_days_used)")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Team Leave Calendar View

struct TeamLeaveCalendarView: View {
    @ObservedObject var viewModel: ChefLeaveManagementViewModel
    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Calendar Header
                ChefCalendarHeaderView(
                    displayedMonth: $displayedMonth,
                    onPreviousMonth: goToPreviousMonth,
                    onNextMonth: goToNextMonth,
                    onToday: goToToday
                )
                
                // Debug info for calendar data
                if !viewModel.teamCalendar.isEmpty {
                    HStack {
                        Text("Calendar Data: \(viewModel.teamCalendar.count) days with leave")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Calendar Grid
                ChefCalendarGridView(
                    displayedMonth: displayedMonth,
                    selectedDate: $selectedDate,
                    teamCalendar: viewModel.teamCalendar
                )
                
                // Selected Date Details
                if !employeesOnLeave(for: selectedDate).isEmpty {
                    ChefSelectedDateDetailView(
                        date: selectedDate,
                        employeesOnLeave: employeesOnLeave(for: selectedDate)
                    )
                } else {
                    // Show empty state for selected date
                    VStack(spacing: 8) {
                        Text("No Team Members on Leave")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Selected: \(formatDate(selectedDate))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            // Load calendar data for initially displayed month
            viewModel.updateDateRange(for: displayedMonth)
        }
    }
    
    // MARK: - Navigation Actions
    
    private func goToPreviousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        }
        // Update calendar data for new month
        viewModel.updateDateRange(for: displayedMonth)
    }
    
    private func goToNextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        }
        // Update calendar data for new month
        viewModel.updateDateRange(for: displayedMonth)
    }
    
    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedMonth = Date()
            selectedDate = Date()
        }
    }
    
    // MARK: - Data Helpers
    
    private func employeesOnLeave(for date: Date) -> [EmployeeLeaveDay] {
        let calendar = Calendar.current
        return viewModel.teamCalendar
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .flatMap { $0.employees_on_leave }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}

// MARK: - Chef Calendar Header

struct ChefCalendarHeaderView: View {
    @Binding var displayedMonth: Date
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    let onToday: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack {
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Button("Today") {
                    onToday()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: displayedMonth)
    }
}

// MARK: - Chef Calendar Grid

struct ChefCalendarGridView: View {
    let displayedMonth: Date
    @Binding var selectedDate: Date
    let teamCalendar: [TeamLeaveCalendar]
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday headers
            ChefWeekdayHeadersView()
            
            // Calendar days
            let weeks = getWeeksInMonth()
            ForEach(weeks, id: \.self) { week in
                HStack(spacing: 0) {
                    ForEach(week, id: \.self) { date in
                        ChefCalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isCurrentMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
                            isToday: calendar.isDateInToday(date),
                            employeesOnLeave: employeesOnLeave(for: date)
                        ) {
                            selectedDate = date
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func getWeeksInMonth() -> [[Date]] {
        let startOfMonth = calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: displayedMonth)?.end ?? displayedMonth
        
        // Get the first day of the week that contains the first day of the month
        let startOfCalendar = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        // Calculate how many weeks we need to display
        let numberOfWeeks = calendar.dateComponents([.weekOfYear], from: startOfCalendar, to: endOfMonth).weekOfYear! + 1
        
        var weeks: [[Date]] = []
        var currentWeekStart = startOfCalendar
        
        for _ in 0..<numberOfWeeks {
            var week: [Date] = []
            for i in 0..<7 {
                if let day = calendar.date(byAdding: .day, value: i, to: currentWeekStart) {
                    week.append(day)
                }
            }
            weeks.append(week)
            currentWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) ?? currentWeekStart
        }
        
        return weeks
    }
    
    private func employeesOnLeave(for date: Date) -> [EmployeeLeaveDay] {
        return teamCalendar
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .flatMap { $0.employees_on_leave }
    }
}

// MARK: - Chef Weekday Headers

struct ChefWeekdayHeadersView: View {
    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
    }
}

struct ChefCalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isToday: Bool
    let employeesOnLeave: [EmployeeLeaveDay]
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundColor(textColor)
                
                // Leave indicators
                HStack(spacing: 2) {
                    if !employeesOnLeave.isEmpty {
                        // Show up to 3 indicators
                        ForEach(Array(employeesOnLeave.prefix(3).enumerated()), id: \.offset) { index, employee in
                            Circle()
                                .fill(colorForLeaveType(employee.leave_type))
                                .frame(width: 6, height: 6)
                        }
                        
                        // Show "+X" if more than 3 employees
                        if employeesOnLeave.count > 3 {
                            Text("+\(employeesOnLeave.count - 3)")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(2)
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary
        } else if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue.opacity(0.2)
        } else if !employeesOnLeave.isEmpty {
            return .orange.opacity(0.1)
        } else {
            return .clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        if isSelected || isToday {
            return 2
        } else {
            return 0
        }
    }
    
    private func colorForLeaveType(_ type: LeaveType) -> Color {
        switch type {
        case .vacation:
            return .green
        case .sick:
            return .red
        case .personal:
            return .orange
        case .parental:
            return .purple
        case .compensatory:
            return .blue
        case .emergency:
            return .red
        }
    }
}

struct ChefSelectedDateDetailView: View {
    let date: Date
    let employeesOnLeave: [EmployeeLeaveDay]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formatDate(date))
                .font(.headline)
                .foregroundColor(.primary)
            
            if employeesOnLeave.isEmpty {
                Text("No employees on leave")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("\(employeesOnLeave.count) employee\(employeesOnLeave.count == 1 ? "" : "s") on leave")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(employeesOnLeave, id: \.employee_id) { employee in
                    HStack {
                        Circle()
                            .fill(colorForLeaveType(employee.leave_type))
                            .frame(width: 8, height: 8)
                        
                        Text(employee.employee_name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(employee.leave_type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if employee.is_half_day {
                            Text("Half Day")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
    
    private func colorForLeaveType(_ type: LeaveType) -> Color {
        switch type {
        case .vacation:
            return .green
        case .sick:
            return .red
        case .personal:
            return .orange
        case .parental:
            return .purple
        case .compensatory:
            return .blue
        case .emergency:
            return .red
        }
    }
}

// MARK: - Team Leave Analytics View

struct TeamLeaveAnalyticsView: View {
    @ObservedObject var viewModel: ChefLeaveManagementViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall Statistics
                if let statistics = viewModel.leaveStatistics {
                    LeaveAnalyticsCard(statistics: statistics)
                }
                
                // Response Time Analysis
                if let statistics = viewModel.leaveStatistics {
                    ResponseTimeAnalyticsCard(statistics: statistics)
                }
                
                // Leave Type Distribution
                LeaveTypeDistributionCard(requests: viewModel.allRequests)
                
                // Monthly Trends
                MonthlyLeaveTrendsCard(requests: viewModel.allRequests)
                
                // Team Availability
                TeamAvailabilityCard(
                    teamBalances: viewModel.teamBalances,
                    statistics: viewModel.leaveStatistics
                )
            }
            .padding()
        }
    }
}

struct LeaveAnalyticsCard: View {
    let statistics: LeaveStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics Overview")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                AnalyticsMetric(
                    title: "Approval\nRate",
                    value: "\(approvalRate)%",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                AnalyticsMetric(
                    title: "Average\nResponse Time",
                    value: responseTimeText,
                    color: .blue,
                    icon: "clock.fill"
                )
                
                AnalyticsMetric(
                    title: "Most Common\nType",
                    value: mostCommonType,
                    color: .purple,
                    icon: "chart.bar.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var approvalRate: Int {
        let total = statistics.approved_requests + statistics.rejected_requests
        guard total > 0 else { return 0 }
        return Int(Double(statistics.approved_requests) / Double(total) * 100)
    }
    
    private var responseTimeText: String {
        guard let hours = statistics.average_response_time_hours else { return "N/A" }
        if hours < 24 {
            return "\(Int(hours))t"
        } else {
            return "\(Int(hours / 24))d"
        }
    }
    
    private var mostCommonType: String {
        guard let type = statistics.most_common_leave_type else { return "N/A" }
        switch type {
        case .vacation: return "Vacation"
        case .sick: return "Sick"
        case .personal: return "Personal"
        case .parental: return "Parental"
        case .compensatory: return "Comp Time"
        case .emergency: return "Emergency"
        }
    }
}

struct AnalyticsMetric: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ResponseTimeAnalyticsCard: View {
    let statistics: LeaveStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Response Time Analysis")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average processing time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let hours = statistics.average_response_time_hours {
                        Text(formatResponseTime(hours))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(responseTimeColor(hours))
                    } else {
                        Text("Not available")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let hours = statistics.average_response_time_hours {
                        HStack {
                            Circle()
                                .fill(responseTimeColor(hours))
                                .frame(width: 8, height: 8)
                            
                            Text(responseTimeStatus(hours))
                                .font(.caption)
                                .foregroundColor(responseTimeColor(hours))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatResponseTime(_ hours: Double) -> String {
        if hours < 1 {
            return "< 1 hour"
        } else if hours < 24 {
            return "\(Int(hours)) hour\(Int(hours) == 1 ? "" : "s")"
        } else {
            let days = Int(hours / 24)
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }
    
    private func responseTimeColor(_ hours: Double) -> Color {
        if hours <= 24 {
            return .green
        } else if hours <= 72 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func responseTimeStatus(_ hours: Double) -> String {
        if hours <= 24 {
            return "Excellent"
        } else if hours <= 72 {
            return "Acceptable"
        } else {
            return "Needs Improvement"
        }
    }
}

struct LeaveTypeDistributionCard: View {
    let requests: [LeaveRequest]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leave Type Distribution")
                .font(.headline)
                .foregroundColor(.primary)
            
            let distribution = calculateLeaveTypeDistribution()
            
            ForEach(distribution, id: \.type) { item in
                VStack(spacing: 4) {
                    HStack {
                        Circle()
                            .fill(colorForLeaveType(item.type))
                            .frame(width: 12, height: 12)
                        
                        Text(item.type.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(item.count) (\(item.percentage)%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: Double(item.count), total: Double(requests.count))
                        .tint(colorForLeaveType(item.type))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func calculateLeaveTypeDistribution() -> [(type: LeaveType, count: Int, percentage: Int)] {
        let typeCounts = Dictionary(grouping: requests, by: \.type)
            .mapValues { $0.count }
        
        let total = requests.count
        guard total > 0 else { return [] }
        
        return LeaveType.allCases.compactMap { type in
            let count = typeCounts[type] ?? 0
            guard count > 0 else { return nil }
            let percentage = Int(Double(count) / Double(total) * 100)
            return (type: type, count: count, percentage: percentage)
        }
        .sorted { $0.count > $1.count }
    }
    
    private func colorForLeaveType(_ type: LeaveType) -> Color {
        switch type {
        case .vacation: return .green
        case .sick: return .red
        case .personal: return .orange
        case .parental: return .purple
        case .compensatory: return .blue
        case .emergency: return .red
        }
    }
}

struct MonthlyLeaveTrendsCard: View {
    let requests: [LeaveRequest]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Trends")
                .font(.headline)
                .foregroundColor(.primary)
            
            let monthlyData = calculateMonthlyData()
            
            if monthlyData.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(monthlyData, id: \.month) { data in
                    HStack {
                        Text(data.monthName)
                            .font(.subheadline)
                            .frame(width: 80, alignment: .leading)
                        
                        ProgressView(value: Double(data.count), total: Double(monthlyData.map(\.count).max() ?? 1))
                            .tint(.blue)
                        
                        Text("\(data.count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func calculateMonthlyData() -> [(month: Int, monthName: String, count: Int)] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        let monthlyRequests = Dictionary(grouping: requests) { request in
            let requestYear = calendar.component(.year, from: request.start_date)
            guard requestYear == currentYear else { return -1 }
            return calendar.component(.month, from: request.start_date)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        
        return (1...12).compactMap { month in
            let count = monthlyRequests[month]?.count ?? 0
            guard count > 0 else { return nil }
            
            let date = calendar.date(from: DateComponents(year: currentYear, month: month, day: 1)) ?? Date()
            dateFormatter.dateFormat = "MMM"
            let monthName = dateFormatter.string(from: date)
            
            return (month: month, monthName: monthName, count: count)
        }
    }
}

struct TeamAvailabilityCard: View {
    let teamBalances: [EmployeeLeaveBalance]
    let statistics: LeaveStatistics?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Team Availability")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Active\nEmployees")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("\(teamBalances.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack {
                    Text("On Leave\nToday")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("\(statistics?.team_on_leave_today ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                VStack {
                    Text("Available\nCapacity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("\(availabilityPercentage)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(availabilityColor)
                }
            }
            
            ProgressView(value: Double(availabilityPercentage), total: 100.0)
                .tint(availabilityColor)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var availabilityPercentage: Int {
        let totalEmployees = teamBalances.count
        let onLeaveToday = statistics?.team_on_leave_today ?? 0
        guard totalEmployees > 0 else { return 0 }
        return Int(Double(totalEmployees - onLeaveToday) / Double(totalEmployees) * 100)
    }
    
    private var availabilityColor: Color {
        if availabilityPercentage >= 80 {
            return .green
        } else if availabilityPercentage >= 60 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Chef Leave Request Detail View

struct ChefLeaveRequestDetailView: View {
    let request: LeaveRequest
    let onApprove: () -> Void
    let onReject: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChefLeaveManagementViewModel()
    
    @State private var showingApprovalConfirmation = false
    @State private var showingRejectionDialog = false
    @State private var rejectionReason = ""
    @State private var isLoadingHistory = false
    @State private var employeeLeaveHistory: [LeaveRequest] = []
    
    var body: some View {
        VStack {
            // Header with close button
            HStack {
                Text("Leave Request Details")
                    .font(.headline)
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            .padding()
            
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Debug info
                    VStack(alignment: .leading) {
                        Text("DEBUG: Request ID \(request.id)")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("DEBUG: Employee: \(request.employee?.name ?? "nil")")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("DEBUG: Type: \(request.type.rawValue)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.3))
                    .cornerRadius(8)
                    
                    // Request Status Card
                    DetailRequestStatusCard(request: request)
                    
                    // Employee Information Card
                    DetailEmployeeInfoCard(employee: request.employee)
                    
                    // Leave Details Card
                    DetailLeaveDetailsCard(request: request)
                    
                    // Leave Balance Card - TODO: Implement when API is available
                    // if let balance = viewModel.getEmployeeLeaveBalance(employeeId: request.employee_id) {
                    //     DetailLeaveBalanceCard(balance: balance)
                    // }
                    
                    // Employee Leave History
                    DetailEmployeeLeaveHistoryCard(
                        employeeId: request.employee_id,
                        currentRequestId: request.id,
                        history: employeeLeaveHistory
                    )
                    
                    // Action Buttons (only for pending requests)
                    if request.status == .pending {
                        DetailActionButtonsSection(
                            onApprove: { showingApprovalConfirmation = true },
                            onReject: { showingRejectionDialog = true }
                        )
                    }
                }
                .padding()
            }
            .onAppear {
                loadEmployeeHistory()
            }
            .confirmationDialog("Approve Leave Request", isPresented: $showingApprovalConfirmation) {
                Button("Approve", role: .destructive) {
                    onApprove()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to approve this leave request for \(request.employee?.name ?? "this employee")?")
            }
            .alert("Reject Leave Request", isPresented: $showingRejectionDialog) {
                TextField("Rejection reason", text: $rejectionReason)
                
                Button("Reject", role: .destructive) {
                    if !rejectionReason.isEmpty {
                        onReject(rejectionReason)
                        dismiss()
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    rejectionReason = ""
                }
            } message: {
                Text("Please provide a reason for rejection:")
            }
        }
    }
    
    private func loadEmployeeHistory() {
        isLoadingHistory = true
        viewModel.fetchEmployeeLeaveHistory(employeeId: request.employee_id) { history in
            self.employeeLeaveHistory = history
            self.isLoadingHistory = false
        }
    }
}

// MARK: - Detail View Components

struct DetailRequestStatusCard: View {
    let request: LeaveRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Request Status")
                        .font(.headline)
                    Text("Submitted \(formattedSubmissionDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                DetailStatusBadge(status: request.status)
            }
            
            if request.status == .pending && isUrgent {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Urgent: Leave starts in less than 48 hours")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var isUrgent: Bool {
        let twoDaysFromNow = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        return request.start_date <= twoDaysFromNow
    }
    
    private var formattedSubmissionDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: request.created_at, relativeTo: Date())
    }
}

struct DetailEmployeeInfoCard: View {
    let employee: LeaveEmployee?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Employee Information")
                .font(.headline)
            
            if let employee = employee {
                HStack(spacing: 12) {
                    // Profile Image
                    if let profileUrl = employee.profilePictureUrl {
                        AsyncImage(url: URL(string: profileUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(employee.name.prefix(2).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                )
                        }
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(employee.name.prefix(2).uppercased())
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(employee.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Label(employee.email, systemImage: "envelope")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(employee.role.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            } else {
                Text("Employee information not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct DetailLeaveDetailsCard: View {
    let request: LeaveRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Leave Details")
                .font(.headline)
            
            // Leave Type
            HStack {
                Label(request.type.displayName, systemImage: request.type.icon)
                    .foregroundColor(request.type.color)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if request.emergency_leave {
                    Label("Emergency", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Divider()
            
            // Dates
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Start Date", value: formattedDate(request.start_date))
                DetailRow(label: "End Date", value: formattedDate(request.end_date))
                DetailRow(label: "Duration", value: "\(request.total_days) working day(s)")
                
                if request.half_day {
                    DetailRow(label: "Half Day", value: "Yes")
                }
            }
            
            // Reason
            if let reason = request.reason, !reason.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reason")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(reason)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            
            // Sick Note
            if request.type == .sick && request.sick_note_url != nil {
                Divider()
                
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                    Text("Sick note attached")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                    Button("View") {
                        // Open sick note URL
                        if let url = URL(string: request.sick_note_url!) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}


struct DetailBalanceItem: View {
    let title: String
    let used: Int
    let total: Int?
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let total = total {
                Text("\(used)/\(total)")
                    .font(.headline)
                    .foregroundColor(color)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(color.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(color)
                            .frame(width: geometry.size.width * CGFloat(used) / CGFloat(total), height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            } else {
                Text("\(used)")
                    .font(.headline)
                    .foregroundColor(color)
                
                Text("Unlimited")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct DetailEmployeeLeaveHistoryCard: View {
    let employeeId: Int
    let currentRequestId: Int
    let history: [LeaveRequest]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Leave History")
                .font(.headline)
            
            if history.isEmpty {
                Text("No previous leave requests")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(history.filter { $0.id != currentRequestId }.prefix(5)) { request in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(request.type.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(formattedDateRange(request)) • \(request.total_days) day(s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        DetailStatusBadge(status: request.status, small: true)
                    }
                    .padding(.vertical, 4)
                    
                    if request.id != history.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formattedDateRange(_ request: LeaveRequest) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        if Calendar.current.isDate(request.start_date, inSameDayAs: request.end_date) {
            return formatter.string(from: request.start_date)
        } else {
            return "\(formatter.string(from: request.start_date)) - \(formatter.string(from: request.end_date))"
        }
    }
}

struct DetailActionButtonsSection: View {
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onReject) {
                Label("Reject", systemImage: "xmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: onApprove) {
                Label("Approve", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(.top)
    }
}

struct DetailStatusBadge: View {
    let status: LeaveStatus
    let small: Bool
    
    init(status: LeaveStatus, small: Bool = false) {
        self.status = status
        self.small = small
    }
    
    var body: some View {
        Text(status.displayName)
            .font(small ? .caption2 : .caption)
            .fontWeight(.medium)
            .padding(.horizontal, small ? 6 : 8)
            .padding(.vertical, small ? 2 : 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(small ? 4 : 6)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Leave Type Extensions for Detail View

extension LeaveType {
    var icon: String {
        switch self {
        case .vacation: return "sun.max.fill"
        case .sick: return "heart.text.square.fill"
        case .personal: return "person.fill"
        case .parental: return "figure.2.and.child.holdinghands"
        case .compensatory: return "clock.arrow.circlepath"
        case .emergency: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .vacation: return .blue
        case .sick: return .orange
        case .personal: return .purple
        case .parental: return .pink
        case .compensatory: return .green
        case .emergency: return .red
        }
    }
}

extension LeaveStatus {
    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .cancelled: return .gray
        case .expired: return .gray
        }
    }
}


#if DEBUG
struct ChefLeaveManagementView_Previews: PreviewProvider {
    static var previews: some View {
        ChefLeaveManagementView()
    }
}
#endif