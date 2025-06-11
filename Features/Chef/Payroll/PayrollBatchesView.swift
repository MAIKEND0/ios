//
//  PayrollBatchesView.swift
//  KSR Cranes App
//
//  Created by Assistant on 04/06/2025.
//

import SwiftUI

struct PayrollBatchesView: View {
    @StateObject private var viewModel = PayrollBatchesViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats overview
                statsOverviewSection
                
                // Filter and search section
                filterSection
                
                // Batches list
                if viewModel.isLoading && viewModel.batches.isEmpty {
                    loadingView
                } else if viewModel.filteredBatches.isEmpty {
                    emptyStateView
                } else {
                    batchesListView
                }
            }
            .background(Color.ksrBackground)
            .navigationTitle("Payroll Batches")
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
                        
                        NavigationLink(destination: CreateBatchView()) {
                            Image(systemName: "plus")
                                .foregroundColor(.ksrPrimary)
                        }
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
            .sheet(isPresented: $viewModel.showBatchDetails) {
                if let selectedBatch = viewModel.selectedBatch {
                    BatchDetailView(batch: selectedBatch)
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Stats Overview
    private var statsOverviewSection: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                BatchStatCard(
                    title: "Total",
                    value: "\(viewModel.stats.totalBatches)",
                    color: .ksrInfo
                )
                
                BatchStatCard(
                    title: "Pending",
                    value: "\(viewModel.stats.pendingApprovalBatches)",
                    color: .ksrWarning
                )
                
                BatchStatCard(
                    title: "Completed",
                    value: "\(viewModel.stats.completedBatches)",
                    color: .ksrSuccess
                )
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.stats.totalAmount.currencyFormatted)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Processing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.stats.avgProcessingTime, specifier: "%.1f") hours")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrInfo)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.ksrBackgroundSecondary)
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search batches...", text: $viewModel.searchText)
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
                    ForEach(BatchStatusFilter.allCases, id: \.self) { filter in
                        BatchFilterChip(
                            title: filter.displayName,
                            count: viewModel.getCountForFilter(filter),
                            isSelected: viewModel.selectedStatusFilter == filter
                        ) {
                            viewModel.selectedStatusFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.ksrBackgroundSecondary)
    }
    
    // MARK: - Batches List
    private var batchesListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredBatches) { batch in
                    PayrollBatchRow(
                        batch: batch,
                        onTap: {
                            viewModel.viewBatchDetails(batch)
                        },
                        onApprove: {
                            viewModel.approveBatch(batch.id)
                        },
                        onSendToZenegy: {
                            viewModel.sendBatchToZenegy(batch.id)
                        },
                        onCancel: {
                            viewModel.cancelBatch(batch.id)
                        },
                        onRetrySync: {
                            viewModel.retrySyncBatch(batch.id)
                        }
                    )
                    
                    if batch.id != viewModel.filteredBatches.last?.id {
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
            
            Text("Loading batches...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.searchText.isEmpty ? "tray" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(viewModel.searchText.isEmpty ? "No batches yet" : "No results found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrTextPrimary)
                
                Text(viewModel.searchText.isEmpty ?
                     "Create your first payroll batch to get started" :
                     "Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if viewModel.searchText.isEmpty {
                NavigationLink(destination: CreateBatchView()) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create Batch")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.ksrPrimary)
                    .cornerRadius(8)
                }
            } else {
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

// MARK: - Batch Stat Card
struct BatchStatCard: View {
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Batch Filter Chip
struct BatchFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
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
                        .background(isSelected ? Color.white.opacity(0.3) : Color.ksrPrimary.opacity(0.3))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.ksrPrimary : Color.ksrLightGray)
            .foregroundColor(isSelected ? .white : .ksrTextPrimary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Payroll Batch Row
struct PayrollBatchRow: View {
    let batch: PayrollBatch
    let onTap: () -> Void
    let onApprove: () -> Void
    let onSendToZenegy: () -> Void
    let onCancel: () -> Void
    let onRetrySync: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Batch info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Batch #\(batch.batchNumber)")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.ksrTextPrimary)
                            
                            Spacer()
                            
                            BatchStatusBadge(status: batch.status)
                        }
                        
                        Text(batch.displayPeriod)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.3")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(batch.totalEmployees) employees")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(batch.totalHours, specifier: "%.0f") hours")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Amount
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(batch.totalAmount.shortCurrencyFormatted)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.ksrPrimary)
                        
                        Text(batch.createdAt.relativeDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Action buttons
            if needsActionButtons(for: batch) {
                HStack(spacing: 12) {
                    Spacer()
                    
                    if batch.canBeApproved {
                        Button {
                            onApprove()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                Text("Approve")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ksrSuccess)
                            .cornerRadius(6)
                        }
                    }
                    
                    if batch.canBeSentToZenegy {
                        Button {
                            onSendToZenegy()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "paperplane")
                                Text("Send to Zenegy")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ksrInfo)
                            .cornerRadius(6)
                        }
                    }
                    
                    if batch.zenegySyncStatus == .failed {
                        Button {
                            onRetrySync()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ksrWarning)
                            .cornerRadius(6)
                        }
                    }
                    
                    if batch.status == .draft {
                        Button {
                            onCancel()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                Text("Cancel")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.ksrError)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ksrError.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }
    
    private func needsActionButtons(for batch: PayrollBatch) -> Bool {
        return batch.canBeApproved ||
               batch.canBeSentToZenegy ||
               batch.zenegySyncStatus == .failed ||
               batch.status == .draft
    }
}

// MARK: - Helper Extensions
extension Date {
    var PBVelativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Preview
struct PayrollBatchesView_Previews: PreviewProvider {
    static var previews: some View {
        PayrollBatchesView()
    }
}
