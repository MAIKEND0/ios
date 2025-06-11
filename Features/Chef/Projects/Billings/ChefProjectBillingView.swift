//
//  ChefProjectBillingView.swift
//  KSR Cranes App
//
//  Billing management view for projects
//

import SwiftUI
import Combine

struct ChefProjectBillingView: View {
    let projectId: Int
    
    @StateObject private var viewModel: ProjectBillingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSettingForEdit: ChefBillingSettings?
    @State private var showDeleteConfirmation = false
    @State private var settingToDelete: ChefBillingSettings?
    
    init(projectId: Int) {
        self.projectId = projectId
        self._viewModel = StateObject(wrappedValue: ProjectBillingViewModel(projectId: projectId))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                billingHeaderView
                
                // Current Billing Settings
                if let currentSettings = viewModel.currentBillingSettings {
                    currentBillingSection(currentSettings)
                } else if !viewModel.isLoading && viewModel.billingSettings.isEmpty {
                    noBillingSettingsView
                } else if !viewModel.isLoading {
                    noBillingSettingsView
                }
                
                // Future Billing Settings
                if !viewModel.futureBillingSettings.isEmpty {
                    futureBillingSection
                }
                
                // Past Billing Settings
                if !viewModel.pastBillingSettings.isEmpty {
                    pastBillingSection
                }
                
                // Loading indicator
                if viewModel.isLoading {
                    loadingView
                }
            }
            .padding()
        }
        .background(backgroundGradient)
        .onAppear {
            viewModel.loadBillingSettings()
        }
        .refreshable {
            await refreshBillingSettings()
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog(
            "Delete Billing Settings",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let setting = settingToDelete {
                    viewModel.deleteBillingSettings(setting.settingId)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete these billing settings. This action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showCreateSheet) {
            ChefEditBillingRatesView(
                projectId: projectId,
                existingSettings: nil,
                onSave: { request in
                    viewModel.createBillingSettings(request)
                }
            )
        }
        .sheet(item: $selectedSettingForEdit) { setting in
            ChefEditBillingRatesView(
                projectId: projectId,
                existingSettings: setting,
                onSave: { request in
                    viewModel.updateBillingSettings(setting.settingId, with: request)
                }
            )
        }
    }
    
    private var backgroundGradient: some View {
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
    
    private var billingHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundColor(.ksrYellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Billing Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Manage hourly rates and billing periods")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    viewModel.showCreateSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.ksrYellow)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func currentBillingSection(_ settings: ChefBillingSettings) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Current Rates")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Active")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.ksrSuccess)
                    .cornerRadius(6)
            }
            
            ChefBillingRateCard(
                settings: settings,
                onEdit: {
                    selectedSettingForEdit = settings
                },
                onDelete: {
                    settingToDelete = settings
                    showDeleteConfirmation = true
                },
                showActions: true
            )
        }
    }
    
    private var futureBillingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Scheduled Changes")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            ForEach(viewModel.futureBillingSettings, id: \.settingId) { settings in
                ChefBillingRateCard(
                    settings: settings,
                    onEdit: {
                        selectedSettingForEdit = settings
                    },
                    onDelete: {
                        settingToDelete = settings
                        showDeleteConfirmation = true
                    },
                    showActions: true,
                    statusColor: .ksrWarning,
                    statusLabel: "Scheduled"
                )
            }
        }
    }
    
    private var pastBillingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rate History")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            ForEach(viewModel.pastBillingSettings, id: \.settingId) { settings in
                ChefBillingRateCard(
                    settings: settings,
                    onEdit: nil, // Can't edit past settings
                    onDelete: {
                        settingToDelete = settings
                        showDeleteConfirmation = true
                    },
                    showActions: false,
                    statusColor: .ksrSecondary,
                    statusLabel: "Expired"
                )
            }
        }
    }
    
    private var noBillingSettingsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 50))
                .foregroundColor(.ksrYellow.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Billing Settings")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Set up hourly rates to start billing for this project")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel.showCreateSheet = true
            } label: {
                Label("Create Billing Settings", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.ksrYellow)
                    .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                .scaleEffect(1.2)
            
            Text("Loading billing settings...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private func refreshBillingSettings() async {
        await withCheckedContinuation { continuation in
            viewModel.loadBillingSettings()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
}

// MARK: - Billing Rate Card Component

struct ChefBillingRateCard: View {
    let settings: ChefBillingSettings
    let onEdit: (() -> Void)?
    let onDelete: () -> Void
    let showActions: Bool
    let statusColor: Color
    let statusLabel: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        settings: ChefBillingSettings,
        onEdit: (() -> Void)?,
        onDelete: @escaping () -> Void,
        showActions: Bool = true,
        statusColor: Color = .ksrSuccess,
        statusLabel: String = "Active"
    ) {
        self.settings = settings
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.showActions = showActions
        self.statusColor = statusColor
        self.statusLabel = statusLabel
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with dates and status
            headerView
            
            // Rates Grid
            ratesGridView
            
            // Actions
            if showActions {
                actionsView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Effective Period")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(settings.effectiveFrom, style: .date)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let effectiveTo = settings.effectiveTo {
                        Text("until \(effectiveTo, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("ongoing")
                            .font(.caption)
                            .foregroundColor(.ksrSuccess)
                    }
                }
                
                Spacer()
                
                Text(statusLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(6)
            }
        }
    }
    
    private var ratesGridView: some View {
        VStack(spacing: 12) {
            // Standard Rates
            ratesSectionView(
                title: "Standard Rates",
                rates: [
                    ("Normal", settings.normalRate, .ksrInfo),
                    ("Weekend", settings.weekendRate, .ksrWarning)
                ]
            )
            
            // Overtime Rates
            ratesSectionView(
                title: "Overtime Rates",
                rates: [
                    ("Overtime 1", settings.overtimeRate1, .ksrWarning),
                    ("Overtime 2", settings.overtimeRate2, .ksrError)
                ]
            )
            
            // Weekend Overtime
            ratesSectionView(
                title: "Weekend Overtime",
                rates: [
                    ("Weekend OT 1", settings.weekendOvertimeRate1, .ksrError),
                    ("Weekend OT 2", settings.weekendOvertimeRate2, .ksrError)
                ]
            )
        }
    }
    
    private func ratesSectionView(title: String, rates: [(String, Decimal, Color)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            HStack(spacing: 12) {
                ForEach(Array(rates.enumerated()), id: \.offset) { index, rate in
                    VStack(spacing: 4) {
                        Text(rate.0)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(rate.1.formattedAsCurrency)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(rate.2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(rate.2.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private var actionsView: some View {
        HStack(spacing: 12) {
            if let onEdit = onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline)
                        .foregroundColor(.ksrInfo)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.ksrInfo.opacity(0.1))
                        )
                }
            }
            
            Button {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.subheadline)
                    .foregroundColor(.ksrError)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.ksrError.opacity(0.1))
                    )
            }
        }
    }
}
