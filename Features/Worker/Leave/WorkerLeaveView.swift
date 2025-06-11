//
//  WorkerLeaveView.swift
//  KSR Cranes App
//
//  Worker Leave Management Interface
//  Main entry point for worker leave functionality
//

import SwiftUI

struct WorkerLeaveView: View {
    @StateObject private var viewModel = WorkerLeaveRequestViewModel()
    @State private var selectedTab = 0
    @State private var showingCreateRequest = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Leave Balance Card
                if let balance = viewModel.leaveBalance {
                    LeaveBalanceCard(balance: balance)
                        .padding(.horizontal)
                        .padding(.top)
                }
                
                // Tab selector
                Picker("Tabs", selection: $selectedTab) {
                    Text("Requests").tag(0)
                    Text("Balance").tag(1)
                    Text("Calendar").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        // Leave Requests Tab
                        LeaveRequestsListView(viewModel: viewModel)
                    case 1:
                        // Balance Details Tab
                        LeaveBalanceDetailView(
                            balance: viewModel.leaveBalance,
                            publicHolidays: viewModel.publicHolidays
                        )
                    case 2:
                        // Calendar View Tab
                        WorkerLeaveCalendarView(
                            leaveRequests: viewModel.approvedRequests, // Only show approved leave requests
                            publicHolidays: viewModel.publicHolidays
                        )
                    default:
                        LeaveRequestsListView(viewModel: viewModel)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
            .navigationTitle("Leave")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Request") {
                        showingCreateRequest = true
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: viewModel.refreshData) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                viewModel.refreshData()
            }
            .overlay {
                if viewModel.isLoading && viewModel.leaveRequests.isEmpty {
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
            .sheet(isPresented: $showingCreateRequest) {
                CreateLeaveRequestView { success in
                    if success {
                        viewModel.refreshData()
                    }
                }
            }
        }
        .onAppear {
            if viewModel.leaveRequests.isEmpty {
                viewModel.loadInitialData()
            }
        }
    }
}

// MARK: - Leave Balance Card

struct LeaveBalanceCard: View {
    let balance: LeaveBalance
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Leave Balance \(balance.year)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            }
            
            HStack(spacing: 12) {
                BalanceItem(
                    title: "Vacation",
                    remaining: balance.vacation_days_remaining,
                    total: balance.vacation_days_total + balance.carry_over_days,
                    color: .green
                )
                
                Divider()
                    .frame(height: 30)
                
                BalanceItem(
                    title: "Personal",
                    remaining: balance.personal_days_remaining,
                    total: balance.personal_days_total,
                    color: .orange
                )
                
                Divider()
                    .frame(height: 30)
                
                BalanceItem(
                    title: "Sick Days",
                    remaining: nil,
                    total: balance.sick_days_used,
                    color: .red,
                    isUsageDisplay: true
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BalanceItem: View {
    let title: String
    let remaining: Int?
    let total: Int
    let color: Color
    let isUsageDisplay: Bool
    
    init(title: String, remaining: Int?, total: Int, color: Color, isUsageDisplay: Bool = false) {
        self.title = title
        self.remaining = remaining
        self.total = total
        self.color = color
        self.isUsageDisplay = isUsageDisplay
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if isUsageDisplay {
                Text("\(total)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Text("used")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else if let remaining = remaining {
                Text("\(remaining)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Text("left")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("--")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Text("N/A")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leave Requests List

struct LeaveRequestsListView: View {
    @ObservedObject var viewModel: WorkerLeaveRequestViewModel
    @State private var showingFilters = false
    @State private var showingEditRequest = false
    @State private var editingRequest: LeaveRequest?
    
    var body: some View {
        VStack {
            // Filter bar
            HStack {
                Button(action: { showingFilters = true }) {
                    HStack {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                        Text("Filters")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                if viewModel.selectedStatusFilter != nil || viewModel.selectedTypeFilter != nil {
                    Button("Clear Filters") {
                        viewModel.clearFilters()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            
            if viewModel.leaveRequests.isEmpty {
                LeaveEmptyStateView(
                    title: "No Leave Requests",
                    subtitle: "Tap 'New Request' to create your first leave request",
                    systemImage: "calendar.badge.plus"
                )
            } else {
                List {
                    ForEach(viewModel.leaveRequests) { request in
                        NavigationLink(destination: LeaveRequestDetailView(request: request)) {
                            LeaveRequestRow(
                                request: request,
                                onCancel: { viewModel.cancelLeaveRequest(request) },
                                onEdit: { 
                                    editingRequest = request
                                    showingEditRequest = true
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .sheet(isPresented: $showingFilters) {
            LeaveRequestFiltersView(
                selectedStatus: $viewModel.selectedStatusFilter,
                selectedType: $viewModel.selectedTypeFilter,
                onApply: {
                    viewModel.applyFilters()
                    showingFilters = false
                }
            )
        }
        .sheet(isPresented: $showingEditRequest) {
            if let request = editingRequest {
                EditLeaveRequestView(request: request) { success in
                    if success {
                        viewModel.refreshData()
                    }
                    showingEditRequest = false
                    editingRequest = nil
                }
            }
        }
    }
}

struct LeaveRequestRow: View {
    let request: LeaveRequest
    let onCancel: () -> Void
    let onEdit: () -> Void
    @State private var showingCancelAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.type.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(formattedDateRange)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: request.status)
                    
                    Text("\(request.total_days) day\(request.total_days == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let reason = request.reason, !reason.isEmpty {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Action buttons for different statuses
            if request.status == .pending {
                HStack {
                    Spacer()
                    
                    Button("Edit") {
                        onEdit()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Button("Cancel") {
                        showingCancelAlert = true
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            } else if request.status == .approved {
                HStack {
                    Spacer()
                    
                    Button("Request Cancellation") {
                        showingCancelAlert = true
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            } else if request.status == .rejected {
                HStack {
                    Spacer()
                    
                    Button("Edit & Resubmit") {
                        onEdit()
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
        .alert("Cancel Request", isPresented: $showingCancelAlert) {
            Button("Cancel", role: .destructive) {
                onCancel()
            }
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this leave request?")
        }
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

struct StatusBadge: View {
    let status: LeaveStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(6)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .cancelled: return .gray
        case .expired: return .purple
        }
    }
    
    private var textColor: Color {
        .white
    }
}

// MARK: - Empty State View

struct LeaveEmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Leave Request Detail View

struct LeaveRequestDetailView: View {
    let request: LeaveRequest
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(request.type.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Request #\(request.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        StatusBadge(status: request.status)
                    }
                    
                    Text(formattedDateRange)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if request.half_day {
                        Label("Half Day", systemImage: "clock.badge.checkmark")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    
                    if request.emergency_leave {
                        Label("Emergency Leave", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Details Section
                VStack(alignment: .leading, spacing: 16) {
                    LeaveDetailRow(label: "Duration", value: "\(request.total_days) day\(request.total_days == 1 ? "" : "s")")
                    LeaveDetailRow(label: "Created", value: formatDate(request.created_at))
                    
                    if let reason = request.reason, !reason.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reason")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(reason)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    if let approvedBy = request.approved_by, let approvedAt = request.approved_at {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Approval Details")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LeaveDetailRow(label: "Approved by", value: "Employee #\(approvedBy)")
                            LeaveDetailRow(label: "Approved on", value: formatDate(approvedAt))
                        }
                    }
                    
                    if let rejectionReason = request.rejection_reason, !rejectionReason.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rejection Reason")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text(rejectionReason)
                                .font(.body)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    if let sickNoteUrl = request.sick_note_url {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Documentation")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                                Text("Sick Note Uploaded")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            .onTapGesture {
                                // TODO: Open document viewer
                                print("Open sick note: \(sickNoteUrl)")
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action Buttons (if applicable)
                if request.status == .pending {
                    VStack(spacing: 12) {
                        Text("Pending Approval")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("Your request is waiting for manager approval. You will be notified once a decision is made.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Leave Request")
        .navigationBarTitleDisplayMode(.inline)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Detail Row Component

struct LeaveDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

#if DEBUG
struct WorkerLeaveView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkerLeaveView()
        }
    }
}
#endif