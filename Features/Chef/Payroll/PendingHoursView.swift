//
//  PendingHoursView.swift
//  KSR Cranes App
//
//  Ekran do przeglądania i zatwierdzania oczekujących godzin pracowników
//

import SwiftUI

struct PendingHoursView: View {
    @StateObject private var viewModel = PendingHoursViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters and search bar
                filterSection
                
                // Content area
                if viewModel.isLoading && viewModel.workEntries.isEmpty {
                    loadingView
                } else if viewModel.filteredWorkEntries.isEmpty {
                    emptyStateView
                } else {
                    hoursListView
                }
            }
            .background(Color.ksrBackground)
            .navigationTitle("Pending Hours")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.ksrPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        if viewModel.hasSelectedItems {
                            Menu {
                                Button(action: {
                                    viewModel.bulkApproveSelected()
                                }) {
                                    Label("Approve Selected (\(viewModel.selectedWorkEntries.count))", systemImage: "checkmark.circle")
                                }
                                .foregroundColor(.ksrSuccess)
                                
                                Button(action: {
                                    viewModel.bulkRejectSelected()
                                }) {
                                    Label("Reject Selected (\(viewModel.selectedWorkEntries.count))", systemImage: "xmark.circle")
                                }
                                .foregroundColor(.ksrError)
                                
                                Button(action: {
                                    viewModel.bulkRequestChanges()
                                }) {
                                    Label("Request Changes (\(viewModel.selectedWorkEntries.count))", systemImage: "pencil.circle")
                                }
                                .foregroundColor(.ksrWarning)
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(.ksrPrimary)
                            }
                        }
                        
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
            .alert("Confirm Action", isPresented: $viewModel.showConfirmationAlert) {
                Button("Cancel", role: .cancel) { }
                Button(viewModel.confirmationAction.title, role: viewModel.confirmationAction.isDestructive ? .destructive : .none) {
                    viewModel.executeConfirmedAction()
                }
            } message: {
                Text(viewModel.confirmationMessage)
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
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
                
                TextField("Search employees, projects...", text: $viewModel.searchText)
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
                    PendingHoursFilterChip(
                        title: "All",
                        count: viewModel.totalCount,
                        isSelected: viewModel.selectedFilter == .all,
                        color: .ksrInfo
                    ) {
                        viewModel.selectedFilter = .all
                    }
                    
                    PendingHoursFilterChip(
                        title: "This Week",
                        count: viewModel.thisWeekCount,
                        isSelected: viewModel.selectedFilter == .thisWeek,
                        color: .ksrSuccess
                    ) {
                        viewModel.selectedFilter = .thisWeek
                    }
                    
                    PendingHoursFilterChip(
                        title: "Last Week",
                        count: viewModel.lastWeekCount,
                        isSelected: viewModel.selectedFilter == .lastWeek,
                        color: .ksrWarning
                    ) {
                        viewModel.selectedFilter = .lastWeek
                    }
                    
                    PendingHoursFilterChip(
                        title: "High Hours",
                        count: viewModel.highHoursCount,
                        isSelected: viewModel.selectedFilter == .highHours,
                        color: .ksrError
                    ) {
                        viewModel.selectedFilter = .highHours
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Summary bar
            if !viewModel.filteredWorkEntries.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.filteredWorkEntries.count) entries")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(viewModel.totalFilteredHours, specifier: "%.1f") hours total")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ksrTextPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Est. Cost")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.totalFilteredAmount.currencyFormatted)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ksrPrimary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.ksrLightGray.opacity(0.5))
                .cornerRadius(8)
            }
            
            // Bulk action bar (when items selected)
            if viewModel.hasSelectedItems {
                HStack {
                    Button("Select All") {
                        viewModel.selectAll()
                    }
                    .font(.caption)
                    .foregroundColor(.ksrPrimary)
                    
                    Spacer()
                    
                    Text("\(viewModel.selectedWorkEntries.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button {
                            viewModel.bulkApproveSelected()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                Text("Approve")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ksrSuccess)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        
                        Button {
                            viewModel.bulkRejectSelected()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                Text("Reject")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ksrError)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.ksrWarning.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.ksrBackgroundSecondary)
    }
    
    // MARK: - Hours List View
    private var hoursListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredWorkEntries) { workEntry in
                    WorkEntryReviewCard(
                        workEntry: workEntry,
                        isSelected: viewModel.selectedWorkEntries.contains(workEntry.id),
                        onSelectionChanged: { isSelected in
                            viewModel.toggleSelection(workEntry.id, isSelected: isSelected)
                        },
                        onApprove: {
                            viewModel.approveWorkEntry(workEntry.id)
                        },
                        onReject: {
                            viewModel.rejectWorkEntry(workEntry.id)
                        },
                        onViewDetails: {
                            viewModel.viewWorkEntryDetails(workEntry.id)
                        }
                    )
                    
                    if workEntry.id != viewModel.filteredWorkEntries.last?.id {
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
            
            Text("Loading pending hours...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.searchText.isEmpty ? "checkmark.circle.fill" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(viewModel.searchText.isEmpty ? .ksrSuccess : .secondary)
            
            VStack(spacing: 8) {
                Text(viewModel.searchText.isEmpty ? "All caught up!" : "No results found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrTextPrimary)
                
                Text(viewModel.searchText.isEmpty ?
                     "No pending hours require your review" :
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

// MARK: - Filter Chip
struct PendingHoursFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : color.opacity(0.3))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color.ksrLightGray)
            .foregroundColor(isSelected ? .white : .ksrTextPrimary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Work Entry Review Card
struct WorkEntryReviewCard: View {
    let workEntry: WorkEntryForReview
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    let onApprove: () -> Void
    let onReject: () -> Void
    let onViewDetails: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Selection checkbox
                Button {
                    onSelectionChanged(!isSelected)
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .ksrPrimary : .secondary)
                }
                
                // Employee info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(workEntry.employee.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ksrTextPrimary)
                        
                        Spacer()
                        
                        // Status badge
                        WorkEntryStatusBadge(status: workEntry.status)
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(workEntry.project.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(workEntry.task.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                // Hours and amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(workEntry.totalHours, specifier: "%.1f") hrs")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrTextPrimary)
                    
                    Text(workEntry.totalAmount.shortCurrencyFormatted)
                        .font(.caption)
                        .foregroundColor(.ksrPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Period and supervisor info
            VStack(spacing: 8) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(workEntry.displayDateRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.checkmark")
                            .font(.caption)
                            .foregroundColor(.ksrSuccess)
                        
                        Text("Approved by \(workEntry.supervisorConfirmation.supervisorName)")
                            .font(.caption)
                            .foregroundColor(.ksrSuccess)
                    }
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    Button("View Details") {
                        onViewDetails()
                    }
                    .font(.caption)
                    .foregroundColor(.ksrInfo)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button {
                            onReject()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                Text("Reject")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ksrError.opacity(0.1))
                            .foregroundColor(.ksrError)
                            .cornerRadius(6)
                        }
                        
                        Button {
                            onApprove()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                Text("Approve")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ksrSuccess)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(isSelected ? Color.ksrPrimary.opacity(0.05) : Color.clear)
        )
        .overlay(
            Rectangle()
                .fill(isSelected ? Color.ksrPrimary : Color.clear)
                .frame(width: 4)
                .cornerRadius(2),
            alignment: .leading
        )
    }
}

// MARK: - Work Entry Status Badge
struct WorkEntryStatusBadge: View {
    let status: WorkEntryReviewStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            
            Text(status.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(status.color.opacity(0.2))
        .foregroundColor(status.color)
        .cornerRadius(6)
    }
}

// MARK: - Preview
struct PendingHoursView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PendingHoursView()
                .preferredColorScheme(.light)
            PendingHoursView()
                .preferredColorScheme(.dark)
        }
    }
}
