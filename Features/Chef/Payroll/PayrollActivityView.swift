//
//  PayrollActivityView.swift
//  KSR Cranes App
//
//  Created by Assistant on 04/06/2025.
//

import SwiftUI

struct PayrollActivityView: View {
    @StateObject private var viewModel = PayrollActivityViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter section
                filterSection
                
                // Activity list
                if viewModel.isLoading && viewModel.activities.isEmpty {
                    loadingView
                } else if viewModel.filteredActivities.isEmpty {
                    emptyStateView
                } else {
                    activityListView
                }
            }
            .background(Color.ksrBackground)
            .navigationTitle("Activity Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search activities...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.ksrLightGray)
            .cornerRadius(10)
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ActivityFilterChip(
                        title: "All",
                        isSelected: viewModel.selectedFilter == .all,
                        color: .ksrInfo
                    ) {
                        viewModel.selectedFilter = .all
                    }
                    
                    ActivityFilterChip(
                        title: "Hours",
                        isSelected: viewModel.selectedFilter == .hours,
                        color: .ksrWarning
                    ) {
                        viewModel.selectedFilter = .hours
                    }
                    
                    ActivityFilterChip(
                        title: "Batches",
                        isSelected: viewModel.selectedFilter == .batches,
                        color: .ksrSuccess
                    ) {
                        viewModel.selectedFilter = .batches
                    }
                    
                    ActivityFilterChip(
                        title: "Zenegy",
                        isSelected: viewModel.selectedFilter == .zenegy,
                        color: .ksrPrimary
                    ) {
                        viewModel.selectedFilter = .zenegy
                    }
                    
                    ActivityFilterChip(
                        title: "System",
                        isSelected: viewModel.selectedFilter == .system,
                        color: .ksrSecondary
                    ) {
                        viewModel.selectedFilter = .system
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.ksrBackgroundSecondary)
    }
    
    // MARK: - Activity List
    private var activityListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredActivities) { activity in
                    PayrollActivityRowView(activity: activity)
                    
                    if activity.id != viewModel.filteredActivities.last?.id {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable {
            await viewModel.refreshAsync()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .ksrPrimary))
                .scaleEffect(1.5)
            
            Text("Loading activity...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.searchText.isEmpty ? "clock" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(viewModel.searchText.isEmpty ? "No activity yet" : "No results found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrTextPrimary)
                
                Text(viewModel.searchText.isEmpty ?
                     "Payroll activity will appear here" :
                     "Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !viewModel.searchText.isEmpty {
                Button("Clear Search") {
                    viewModel.searchText = ""
                }
                .font(.subheadline)
                .foregroundColor(.ksrPrimary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .padding(.horizontal, 40)
    }
}

// MARK: - Activity Filter Chip
struct ActivityFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.ksrLightGray)
                .foregroundColor(isSelected ? .white : .ksrTextPrimary)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Activity Row View
struct PayrollActivityRowView: View {
    let activity: PayrollActivityExtended
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity icon
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: activity.type.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(activity.type.color)
            }
            
            // Activity content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrTextPrimary)
                    
                    Spacer()
                    
                    Text(activity.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let details = activity.details {
                    Text(details)
                        .font(.caption2)
                        .foregroundColor(activity.type.color)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Activity View Model
class PayrollActivityViewModel: ObservableObject {
    @Published var activities: [PayrollActivityExtended] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedFilter: ActivityFilter = .all
    
    var filteredActivities: [PayrollActivityExtended] {
        var filtered = activities
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { activity in
                activity.title.localizedCaseInsensitiveContains(searchText) ||
                activity.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply type filter
        if selectedFilter != .all {
            filtered = filtered.filter { selectedFilter.matches($0.type) }
        }
        
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }
    
    func loadData() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        // Simulate API call - replace with actual API service
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.isLoading = false
                self.activities = self.generateMockActivities()
            }
        }
    }
    
    func refreshData() {
        loadData()
    }
    
    func refreshAsync() async {
        await withCheckedContinuation { continuation in
            refreshData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
    
    private func generateMockActivities() -> [PayrollActivityExtended] {
        [
            PayrollActivityExtended(
                title: "Batch #2024-48 Approved",
                description: "Payroll batch containing 15 employees approved for processing",
                timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
                type: .batchApproved,
                details: "Total amount: 67,450 kr"
            ),
            PayrollActivityExtended(
                title: "Hours Submitted",
                description: "Lars Hansen submitted 42.5 hours for review",
                timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
                type: .hoursSubmitted,
                details: "Project: Tower Construction Alpha"
            ),
            PayrollActivityExtended(
                title: "Zenegy Sync Completed",
                description: "Batch #2024-47 successfully synchronized with Zenegy",
                timestamp: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date(),
                type: .zenegySyncCompleted,
                details: "15 employees, processing time: 2.8s"
            ),
            PayrollActivityExtended(
                title: "Bulk Hours Approved",
                description: "127 hours approved for 8 employees",
                timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                type: .hoursApproved,
                details: "Auto-approved based on supervisor confirmation"
            ),
            PayrollActivityExtended(
                title: "New Batch Created",
                description: "Payroll batch #2024-49 created for current period",
                timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                type: .batchCreated,
                details: "12 employees, 387.5 total hours"
            ),
            PayrollActivityExtended(
                title: "Period Closed",
                description: "November 2024 payroll period finalized",
                timestamp: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                type: .periodClosed,
                details: "Total processed: 234,567 kr"
            ),
            PayrollActivityExtended(
                title: "Zenegy Sync Failed",
                description: "Batch #2024-46 sync failed - connection timeout",
                timestamp: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
                type: .zenegySyncFailed,
                details: "Retry scheduled automatically"
            ),
            PayrollActivityExtended(
                title: "System Maintenance",
                description: "Scheduled maintenance completed on payroll system",
                timestamp: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                type: .systemMaintenance,
                details: "Duration: 2 hours, no data lost"
            )
        ]
    }
}

// MARK: - Supporting Models
struct PayrollActivityExtended: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let timestamp: Date
    let type: PayrollActivityTypeExtended
    let details: String?
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

enum PayrollActivityTypeExtended {
    case hoursSubmitted
    case hoursApproved
    case hoursRejected
    case batchCreated
    case batchApproved
    case batchSent
    case zenegySyncCompleted
    case zenegySyncFailed
    case periodClosed
    case systemMaintenance
    
    var icon: String {
        switch self {
        case .hoursSubmitted: return "clock.badge.plus"
        case .hoursApproved: return "checkmark.circle.fill"
        case .hoursRejected: return "xmark.circle.fill"
        case .batchCreated: return "plus.rectangle.on.folder"
        case .batchApproved: return "checkmark.seal.fill"
        case .batchSent: return "paperplane.fill"
        case .zenegySyncCompleted: return "checkmark.icloud.fill"
        case .zenegySyncFailed: return "exclamationmark.icloud.fill"
        case .periodClosed: return "calendar.circle.fill"
        case .systemMaintenance: return "gear.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .hoursSubmitted: return .ksrInfo
        case .hoursApproved: return .ksrSuccess
        case .hoursRejected: return .ksrError
        case .batchCreated: return .ksrPrimary
        case .batchApproved: return .ksrSuccess
        case .batchSent: return .ksrInfo
        case .zenegySyncCompleted: return .ksrSuccess
        case .zenegySyncFailed: return .ksrError
        case .periodClosed: return .ksrWarning
        case .systemMaintenance: return .ksrSecondary
        }
    }
}

enum ActivityFilter: CaseIterable {
    case all
    case hours
    case batches
    case zenegy
    case system
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .hours: return "Hours"
        case .batches: return "Batches"
        case .zenegy: return "Zenegy"
        case .system: return "System"
        }
    }
    
    func matches(_ type: PayrollActivityTypeExtended) -> Bool {
        switch self {
        case .all: return true
        case .hours: return [.hoursSubmitted, .hoursApproved, .hoursRejected].contains(type)
        case .batches: return [.batchCreated, .batchApproved, .batchSent].contains(type)
        case .zenegy: return [.zenegySyncCompleted, .zenegySyncFailed].contains(type)
        case .system: return [.periodClosed, .systemMaintenance].contains(type)
        }
    }
}

// MARK: - Preview
struct PayrollActivityView_Previews: PreviewProvider {
    static var previews: some View {
        PayrollActivityView()
    }
}
