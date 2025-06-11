//
//  CreateBatchView.swift
//  KSR Cranes App
//
//  Improved view for creating payroll batches with KSR's 2-week period system
//

import SwiftUI

struct CreateBatchView: View {
    @StateObject private var viewModel = CreateBatchViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                // Main content
                mainContent
                
                // Bottom navigation
                bottomNavigation
            }
            .background(Color.ksrBackground)
            .navigationTitle("Create Payroll Batch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if viewModel.hasUnsavedChanges {
                            viewModel.showCancelConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.ksrError)
                }
            }
            .alert("Unsaved Changes", isPresented: $viewModel.showCancelConfirmation) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if viewModel.shouldDismissOnSuccess {
                            dismiss()
                        }
                    }
                )
            }
        }
        .onAppear {
            viewModel.loadInitialData()
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack {
            ForEach(CreateBatchStep.allCases, id: \.self) { step in
                HStack(spacing: 8) {
                    Circle()
                        .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.ksrPrimary : Color.ksrLightGray)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(step.rawValue + 1)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                    
                    if step != CreateBatchStep.allCases.last {
                        Rectangle()
                            .fill(step.rawValue < viewModel.currentStep.rawValue ? Color.ksrPrimary : Color.ksrLightGray)
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.ksrBackgroundSecondary)
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Step header
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.currentStep.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrTextPrimary)
                    
                    Text(viewModel.currentStep.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                // Step content
                Group {
                    switch viewModel.currentStep {
                    case .selectPeriod:
                        selectPeriodContent
                    case .reviewHours:
                        reviewHoursContent
                    case .configureBatch:
                        configureBatchContent
                    case .confirmation:
                        confirmationContent
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Step 1: Select Period (Improved for 2-week system)
    private var selectPeriodContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // KSR Period Explanation
            InfoCard(
                title: "KSR 2-Week Payroll System",
                content: "KSR Cranes operates on a bi-weekly payroll schedule. Each period covers exactly 2 weeks (14 days), running Monday to Sunday.",
                icon: "calendar.badge.clock",
                color: .ksrInfo
            )
            
            Text("Available Payroll Periods")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrTextPrimary)
            
            if viewModel.quickPeriodOptions.isEmpty {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .ksrPrimary))
                    
                    Text("Loading available 2-week periods...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.quickPeriodOptions) { period in
                        BiWeeklyPeriodCard(
                            period: period,
                            isSelected: viewModel.selectedPeriod?.id == period.id
                        ) {
                            viewModel.selectPeriod(period)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Review Hours (Enhanced)
    private var reviewHoursContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Period Summary Header
            if let period = viewModel.selectedPeriod {
                PeriodSummaryHeader(period: period)
            }
            
            // Work Entries Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Work Entries for Period")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrTextPrimary)
                    
                    Text("\(viewModel.availableWorkEntries.count) entries • \(viewModel.uniqueEmployeeCount) employees")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.totalSelectedAmount.currencyFormatted)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrPrimary)
                    
                    Text("\(viewModel.totalSelectedHours, specifier: "%.1f") hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(cardBackground)
            
            // Selection controls
            HStack {
                Button("Select All (\(viewModel.availableWorkEntries.count))") {
                    viewModel.selectAllWorkEntries()
                }
                .font(.caption)
                .foregroundColor(.ksrPrimary)
                .disabled(viewModel.availableWorkEntries.isEmpty)
                
                Spacer()
                
                Button("Clear Selection") {
                    viewModel.clearAllWorkEntries()
                }
                .font(.caption)
                .foregroundColor(.ksrError)
                .disabled(viewModel.selectedWorkEntries.isEmpty)
            }
            
            // Work entries list
            if viewModel.availableWorkEntries.isEmpty {
                EmptyWorkEntriesView()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.availableWorkEntries) { entry in
                        EnhancedWorkEntryRow(
                            entry: entry,
                            isSelected: viewModel.selectedWorkEntries.contains(entry.id)
                        ) { isSelected in
                            viewModel.toggleWorkEntrySelection(entry.id, isSelected: isSelected)
                        }
                        
                        if entry.id != viewModel.availableWorkEntries.last?.id {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(cardBackground)
            }
        }
    }
    
    // MARK: - Step 3: Configure Batch (Enhanced)
    private var configureBatchContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Batch Overview
            BatchOverviewCard(
                periodName: viewModel.selectedPeriod?.displayName ?? "",
                entryCount: viewModel.selectedWorkEntries.count,
                totalHours: viewModel.totalSelectedHours,
                totalAmount: viewModel.totalSelectedAmount
            )
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Batch Configuration")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrTextPrimary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Batch Number")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ksrTextPrimary)
                    
                    HStack {
                        TextField("Auto-generated", text: $viewModel.batchNumber)
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)
                        
                        Button("Regenerate") {
                            viewModel.generateBatchNumber()
                        }
                        .font(.caption)
                        .foregroundColor(.ksrPrimary)
                    }
                    
                    Text("Format: YYYY-PP (Year-Period)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ksrTextPrimary)
                    
                    TextField("Add notes about this payroll batch...", text: $viewModel.batchNotes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Create as Draft", isOn: $viewModel.createAsDraft)
                        .font(.subheadline)
                        .foregroundColor(.ksrTextPrimary)
                    
                    Text(viewModel.createAsDraft ? 
                         "Batch will be saved as draft for review before submission" : 
                         "Batch will be ready for immediate approval and processing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(cardBackground)
        }
    }
    
    // MARK: - Step 4: Confirmation (Enhanced)
    private var confirmationContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Review & Confirm Batch Creation")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrTextPrimary)
            
            VStack(spacing: 16) {
                // Period summary
                ConfirmationSection(title: "Payroll Period") {
                    if let period = viewModel.selectedPeriod {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(period.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.ksrTextPrimary)
                            
                            Text(period.dateRange)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Duration: 2 weeks (14 days)")
                                .font(.caption)
                                .foregroundColor(.ksrInfo)
                        }
                    }
                }
                
                // Work entries summary
                ConfirmationSection(title: "Work Entries") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.selectedWorkEntries.count) entries from \(viewModel.uniqueEmployeeCount) employees")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.ksrTextPrimary)
                        
                        Text("Total: \(viewModel.totalSelectedHours, specifier: "%.1f") hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Amount: \(viewModel.totalSelectedAmount.currencyFormatted)")
                            .font(.caption)
                            .foregroundColor(.ksrPrimary)
                            .fontWeight(.medium)
                    }
                }
                
                // Batch configuration summary
                ConfirmationSection(title: "Batch Settings") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Batch #\(viewModel.batchNumber)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.ksrTextPrimary)
                        
                        Text(viewModel.createAsDraft ? "Status: Draft (requires approval)" : "Status: Ready for processing")
                            .font(.caption)
                            .foregroundColor(viewModel.createAsDraft ? .ksrWarning : .ksrSuccess)
                        
                        if !viewModel.batchNotes.isEmpty {
                            Text("Notes: \(viewModel.batchNotes)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                    }
                }
            }
            
            // Final warning/info
            InfoCard(
                title: "Important",
                content: "Once created, this batch will include all selected work entries. Make sure all hours have been properly reviewed and approved.",
                icon: "exclamationmark.triangle",
                color: .ksrWarning
            )
        }
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack(spacing: 16) {
            if viewModel.canGoBack {
                Button("Back") {
                    viewModel.goToPreviousStep()
                }
                .buttonStyle(.bordered)
                .tint(.ksrSecondary)
            }
            
            Spacer()
            
            Button(viewModel.nextButtonTitle) {
                if viewModel.isLastStep {
                    viewModel.createBatch()
                } else {
                    viewModel.goToNextStep()
                }
            }
            .disabled(!viewModel.canProceed || viewModel.isLoading)
            .buttonStyle(.borderedProminent)
            .tint(.ksrPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.ksrBackgroundSecondary)
    }
    
    // MARK: - Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Enhanced Components

// Bi-Weekly Period Card with better visual design
struct BiWeeklyPeriodCard: View {
    let period: PayrollAPIService.PayrollPeriodOption
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(period.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ksrTextPrimary)
                        
                        Text("2-Week Period")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.ksrInfo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.ksrInfo.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .ksrPrimary : .secondary)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Period")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(period.dateRange)
                            .font(.caption)
                            .foregroundColor(.ksrTextPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Available")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        HStack(spacing: 4) {
                            Text("\(period.availableHours, specifier: "%.0f")h")
                                .font(.caption)
                                .foregroundColor(.ksrTextPrimary)
                            
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(period.estimatedAmount.shortCurrencyFormatted)
                                .font(.caption)
                                .foregroundColor(.ksrPrimary)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.ksrPrimary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Period Summary Header
struct PeriodSummaryHeader: View {
    let period: PayrollAPIService.PayrollPeriodOption
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Selected Period")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(period.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrTextPrimary)
                
                Text(period.dateRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("14 Days")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.ksrInfo)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.ksrInfo.opacity(0.1))
                    .cornerRadius(4)
                
                Text("Bi-weekly period")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ksrPrimary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.ksrPrimary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// Enhanced Work Entry Row
struct EnhancedWorkEntryRow: View {
    let entry: WorkEntryForReview
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                onSelectionChanged(!isSelected)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .ksrPrimary : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.employee.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrTextPrimary)
                
                Text(entry.project.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(entry.task.title)
                    .font(.caption2)
                    .foregroundColor(.ksrInfo)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.totalHours, specifier: "%.1f") hrs")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrTextPrimary)
                
                Text(entry.totalAmount.shortCurrencyFormatted)
                    .font(.caption)
                    .foregroundColor(.ksrPrimary)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(isSelected ? Color.ksrPrimary.opacity(0.05) : Color.clear)
        )
    }
}

// Empty Work Entries View
struct EmptyWorkEntriesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No work entries found")
                .font(.headline)
                .foregroundColor(.ksrTextPrimary)
            
            Text("There are no approved work entries for the selected 2-week period. Make sure employees have submitted and supervisors have approved their hours.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
}

// Batch Overview Card
struct BatchOverviewCard: View {
    let periodName: String
    let entryCount: Int
    let totalHours: Double
    let totalAmount: Decimal
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Batch Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrTextPrimary)
                
                Spacer()
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.ksrPrimary)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Period:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(periodName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ksrTextPrimary)
                }
                
                HStack {
                    Text("Work Entries:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(entryCount) entries")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ksrTextPrimary)
                }
                
                HStack {
                    Text("Total Hours:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(totalHours, specifier: "%.1f") hours")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ksrTextPrimary)
                }
                
                Divider()
                
                HStack {
                    Text("Total Amount:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrTextPrimary)
                    
                    Spacer()
                    
                    Text(totalAmount.currencyFormatted)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.ksrPrimary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ksrPrimary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.ksrPrimary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// Info Card Component
struct InfoCard: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrTextPrimary)
                
                Text(content)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// Confirmation Section (Enhanced)
struct ConfirmationSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ksrLightGray.opacity(0.3))
        )
    }
}

// MARK: - Preview
struct CreateBatchView_Previews: PreviewProvider {
    static var previews: some View {
        CreateBatchView()
    }
}