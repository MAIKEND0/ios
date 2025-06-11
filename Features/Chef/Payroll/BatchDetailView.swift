//
//  BatchDetailView.swift
//  KSR Cranes App
//
//  Szczegółowy widok partii wypłat z możliwością zarządzania
//

import SwiftUI

struct BatchDetailView: View {
    let batch: PayrollBatch
    @StateObject private var viewModel = BatchDetailViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header card with main info
                    batchHeaderCard
                    
                    // Status timeline
                    statusTimelineSection
                    
                    // Financial summary
                    financialSummarySection
                    
                    // Employee breakdown
                    employeeBreakdownSection
                    
                    // Zenegy integration status
                    if batch.zenegySyncStatus != nil {
                        zenegyStatusSection
                    }
                    
                    // Actions section
                    actionsSection
                    
                    // Notes and metadata
                    notesSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.ksrBackground)
            .navigationTitle("Batch Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.ksrPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export PDF", systemImage: "doc.text") {
                            viewModel.exportBatchPDF(batch)
                        }
                        
                        Button("Share Summary", systemImage: "square.and.arrow.up") {
                            viewModel.shareBatchSummary(batch)
                        }
                        
                        if batch.status == .draft {
                            Button("Edit Batch", systemImage: "pencil") {
                                viewModel.editBatch(batch)
                            }
                        }
                        
                        if batch.status != .completed && batch.status != .cancelled {
                            Button("Cancel Batch", systemImage: "xmark.circle") {
                                viewModel.cancelBatch(batch)
                            }
                            .foregroundColor(.ksrError)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.ksrPrimary)
                    }
                }
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
            viewModel.loadBatchDetails(batch)
        }
    }
    
    // MARK: - Batch Header Card
    private var batchHeaderCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Batch #\(batch.batchNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrTextPrimary)
                    
                    Text(batch.displayPeriod)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                BatchStatusBadge(status: batch.status)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(batch.totalEmployees)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrPrimary)
                    
                    Text("Employees")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(batch.totalHours, specifier: "%.1f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrInfo)
                    
                    Text("Total Hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text(batch.totalAmount.shortCurrencyFormatted)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrSuccess)
                    
                    Text("Total Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    // MARK: - Status Timeline
    private var statusTimelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status Timeline")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrTextPrimary)
            
            VStack(spacing: 12) {
                TimelineItem(
                    title: "Created",
                    date: batch.createdAt,
                    isCompleted: true,
                    description: "Batch created with \(batch.totalEmployees) employees"
                )
                
                if let approvedAt = batch.approvedAt {
                    TimelineItem(
                        title: "Approved",
                        date: approvedAt,
                        isCompleted: true,
                        description: "Approved and ready for Zenegy sync"
                    )
                }
                
                if let sentToZenegyAt = batch.sentToZenegyAt {
                    TimelineItem(
                        title: "Sent to Zenegy",
                        date: sentToZenegyAt,
                        isCompleted: batch.status == .completed,
                        description: batch.status == .completed ? "Successfully processed" : "Processing in progress",
                        isInProgress: batch.zenegySyncStatus?.isInProgress == true
                    )
                }
                
                if batch.status == .completed {
                    TimelineItem(
                        title: "Completed",
                        date: batch.sentToZenegyAt ?? Date(),
                        isCompleted: true,
                        description: "Payroll processing completed"
                    )
                } else if batch.status == .failed {
                    TimelineItem(
                        title: "Failed",
                        date: batch.sentToZenegyAt ?? Date(),
                        isCompleted: false,
                        description: "Sync failed - retry required",
                        isError: true
                    )
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    // MARK: - Financial Summary
    private var financialSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Summary")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrTextPrimary)
            
            VStack(spacing: 12) {
                FinancialRow(
                    title: "Regular Hours",
                    amount: viewModel.regularHoursAmount,
                    hours: viewModel.regularHours,
                    rate: viewModel.averageRegularRate
                )
                
                FinancialRow(
                    title: "Overtime Hours",
                    amount: viewModel.overtimeAmount,
                    hours: viewModel.overtimeHours,
                    rate: viewModel.averageOvertimeRate
                )
                
                FinancialRow(
                    title: "Weekend Hours",
                    amount: viewModel.weekendAmount,
                    hours: viewModel.weekendHours,
                    rate: viewModel.averageWeekendRate
                )
                
                Divider()
                    .padding(.vertical, 4)
                
                HStack {
                    Text("Total Amount")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrTextPrimary)
                    
                    Spacer()
                    
                    Text(batch.totalAmount.currencyFormatted)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrPrimary)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    // MARK: - Employee Breakdown
    private var employeeBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Employee Breakdown")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrTextPrimary)
                
                Spacer()
                
                Button("View All") {
                    viewModel.showAllEmployees(batch)
                }
                .font(.caption)
                .foregroundColor(.ksrPrimary)
            }
            
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.topEmployees.enumerated()), id: \.element.id) { index, employee in
                    EmployeeBreakdownRow(employee: employee)
                    
                    if index < viewModel.topEmployees.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
                
                if viewModel.hasMoreEmployees {
                    Button {
                        viewModel.showAllEmployees(batch)
                    } label: {
                        HStack {
                            Text("View \(viewModel.remainingEmployeesCount) more employees")
                                .font(.caption)
                                .foregroundColor(.ksrPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.ksrPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    // MARK: - Zenegy Status Section
    private var zenegyStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Zenegy Integration")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrTextPrimary)
            
            if let syncStatus = batch.zenegySyncStatus {
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(syncStatus.color.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                
                                if syncStatus.isInProgress {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: syncStatus.color))
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: syncStatus == .completed ? "checkmark" : syncStatus == .failed ? "exclamationmark.triangle" : "clock")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(syncStatus.color)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Status: \(syncStatus.displayName)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.ksrTextPrimary)
                                
                                if let sentAt = batch.sentToZenegyAt {
                                    Text("Sent: \(sentAt.relativeDescription)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if syncStatus == .failed {
                            Button {
                                viewModel.retrySyncToZenegy(batch)
                            } label: {
                                Text("Retry")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.ksrWarning)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    
                    if viewModel.hasSyncDetails {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sync Details")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.ksrTextPrimary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Employees synced:")
                                    Spacer()
                                    Text("\(viewModel.syncedEmployees)")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("Processing time:")
                                    Spacer()
                                    Text("\(viewModel.processingTime)ms")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                if viewModel.hasWarnings {
                                    HStack {
                                        Text("Warnings:")
                                        Spacer()
                                        Text("\(viewModel.warningsCount)")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.ksrWarning)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.ksrBackgroundSecondary)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrTextPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if batch.canBeApproved {
                    BatchActionButton(
                        title: "Approve Batch",
                        icon: "checkmark.circle.fill",
                        color: .ksrSuccess,
                        isEnabled: true
                    ) {
                        viewModel.approveBatch(batch)
                    }
                }
                
                if batch.canBeSentToZenegy {
                    BatchActionButton(
                        title: "Send to Zenegy",
                        icon: "paperplane.fill",
                        color: .ksrInfo,
                        isEnabled: true
                    ) {
                        viewModel.sendToZenegy(batch)
                    }
                }
                
                BatchActionButton(
                    title: "Export PDF",
                    icon: "doc.text.fill",
                    color: .ksrPrimary,
                    isEnabled: true
                ) {
                    viewModel.exportBatchPDF(batch)
                }
                
                BatchActionButton(
                    title: "View Reports",
                    icon: "chart.bar.fill",
                    color: .ksrWarning,
                    isEnabled: true
                ) {
                    viewModel.viewBatchReports(batch)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes & Metadata")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrTextPrimary)
            
            VStack(alignment: .leading, spacing: 12) {
                if let notes = batch.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.ksrTextPrimary)
                        
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No notes available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                Divider()
                
                VStack(spacing: 8) {
                    MetadataRow(title: "Created by", value: "Chef User") // TODO: Get actual user name
                    MetadataRow(title: "Created", value: batch.createdAt.formatted(date: .abbreviated, time: .shortened))
                    MetadataRow(title: "Period", value: "\(batch.year) - Period \(batch.periodNumber)")
                    
                    if let approvedBy = batch.approvedBy {
                        MetadataRow(title: "Approved by", value: "User #\(approvedBy)") // TODO: Get actual user name
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    // MARK: - Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Timeline Item
struct TimelineItem: View {
    let title: String
    let date: Date
    let isCompleted: Bool
    let description: String
    let isInProgress: Bool
    let isError: Bool
    
    init(title: String, date: Date, isCompleted: Bool, description: String, isInProgress: Bool = false, isError: Bool = false) {
        self.title = title
        self.date = date
        self.isCompleted = isCompleted
        self.description = description
        self.isInProgress = isInProgress
        self.isError = isError
    }
    
    var statusColor: Color {
        if isError { return .ksrError }
        if isCompleted { return .ksrSuccess }
        if isInProgress { return .ksrInfo }
        return .ksrSecondary
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                if isInProgress {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: statusColor))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: isCompleted ? "checkmark" : isError ? "exclamationmark.triangle" : "circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(statusColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ksrTextPrimary)
                    
                    Spacer()
                    
                    Text(date.relativeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Financial Row
struct FinancialRow: View {
    let title: String
    let amount: Decimal
    let hours: Double
    let rate: Decimal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.ksrTextPrimary)
                
                Text("\(hours, specifier: "%.1f") hrs @ \(rate.currencyFormatted)/hr")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(amount.currencyFormatted)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrPrimary)
        }
    }
}

// MARK: - Employee Breakdown Row
struct EmployeeBreakdownRow: View {
    let employee: PayrollModels.BatchEmployeeBreakdown
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(employee.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ksrTextPrimary)
                
                Text("\(employee.totalHours, specifier: "%.1f") hours")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(employee.totalAmount.shortCurrencyFormatted)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Batch Action Button
struct BatchActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isEnabled ? color.opacity(0.1) : Color.gray.opacity(0.1))
            .foregroundColor(isEnabled ? color : Color.gray)
            .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Batch Status Badge
struct BatchStatusBadge: View {
    let status: PayrollBatchStatus
    
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

// MARK: - Metadata Row
struct MetadataRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.ksrTextPrimary)
        }
    }
}

// MARK: - Preview
struct BatchDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockBatch = PayrollBatch(
            id: 1,
            batchNumber: "2024-01",
            periodStart: Date(),
            periodEnd: Date(),
            year: 2024,
            periodNumber: 1,
            totalEmployees: 15,
            totalHours: 630.0,
            totalAmount: Decimal(47250.00),
            status: .approved,
            createdBy: 1,
            createdAt: Date(),
            approvedBy: 1,
            approvedAt: Date(),
            sentToZenegyAt: nil,
            zenegySyncStatus: nil,
            notes: "Auto-generated batch from pending hours"
        )
        
        Group {
            BatchDetailView(batch: mockBatch)
                .preferredColorScheme(.light)
            BatchDetailView(batch: mockBatch)
                .preferredColorScheme(.dark)
        }
    }
}
