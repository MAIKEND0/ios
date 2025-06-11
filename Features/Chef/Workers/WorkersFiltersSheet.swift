//
//  WorkersFiltersSheet.swift
//  KSR Cranes App
//  Filters sheet for workers list
//

import SwiftUI

struct WorkersFiltersSheet: View {
    @ObservedObject var viewModel: ChefWorkersViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var tempSelectedStatuses: Set<WorkerStatus>
    @State private var tempSelectedEmploymentTypes: Set<EmploymentType>
    @State private var tempSelectedRoles: Set<WorkerRole>
    @State private var tempMinHourlyRate: Double
    @State private var tempMaxHourlyRate: Double
    @State private var tempShowOnlyActiveAssignments: Bool
    
    init(viewModel: ChefWorkersViewModel) {
        self.viewModel = viewModel
        self._tempSelectedStatuses = State(initialValue: viewModel.selectedStatuses)
        self._tempSelectedEmploymentTypes = State(initialValue: viewModel.selectedEmploymentTypes)
        self._tempSelectedRoles = State(initialValue: viewModel.selectedRoles)
        self._tempMinHourlyRate = State(initialValue: viewModel.minHourlyRate)
        self._tempMaxHourlyRate = State(initialValue: viewModel.maxHourlyRate)
        self._tempShowOnlyActiveAssignments = State(initialValue: viewModel.showOnlyActiveAssignments)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Status Filters
                    statusFiltersSection
                    
                    // Employment Type Filters
                    employmentTypeFiltersSection
                    
                    // Role Filters
                    roleFiltersSection
                    
                    // Hourly Rate Range
                    hourlyRateSection
                    
                    // Additional Filters
                    additionalFiltersSection
                    
                    // Active Filters Summary
                    if hasActiveFilters {
                        activeFiltersSummarySection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(backgroundGradient)
            .navigationTitle("Filter Workers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button("Clear All") {
                            clearAllFilters()
                        }
                        .foregroundColor(.red)
                        .disabled(!hasActiveFilters)
                        
                        Button("Apply") {
                            applyFilters()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(Color.ksrPrimary)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.ksrInfo.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(Color.ksrInfo)
            }
            
            VStack(spacing: 4) {
                Text("Filter Workers")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                Text("Customize your worker list view")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Status Filters
    
    private var statusFiltersSection: some View {
        WorkersFilterSection(title: "Worker Status", icon: "person.circle.fill") {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(WorkerStatus.allCases, id: \.self) { status in
                    FilterToggleCard(
                        title: status.displayName,
                        icon: status.systemImage,
                        color: status.color,
                        isSelected: tempSelectedStatuses.contains(status)
                    ) {
                        toggleStatus(status)
                    }
                }
            }
        }
    }
    
    // MARK: - Employment Type Filters
    
    private var employmentTypeFiltersSection: some View {
        WorkersFilterSection(title: "Employment Type", icon: "briefcase.fill") {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(EmploymentType.allCases, id: \.self) { type in
                    FilterToggleCard(
                        title: type.displayName,
                        icon: "briefcase.fill",
                        color: Color.ksrPrimary,
                        isSelected: tempSelectedEmploymentTypes.contains(type)
                    ) {
                        toggleEmploymentType(type)
                    }
                }
            }
        }
    }
    
    // MARK: - Role Filters
    
    private var roleFiltersSection: some View {
        WorkersFilterSection(title: "Worker Role", icon: "person.badge.key.fill") {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(WorkerRole.allCases, id: \.self) { role in
                    FilterToggleCard(
                        title: role.danishName,
                        icon: role.systemImage,
                        color: role.color,
                        isSelected: tempSelectedRoles.contains(role)
                    ) {
                        toggleRole(role)
                    }
                }
            }
        }
    }
    
    // MARK: - Hourly Rate Section
    
    private var hourlyRateSection: some View {
        WorkersFilterSection(title: "Hourly Rate Range", icon: "banknote.fill") {
            VStack(spacing: 16) {
                HStack {
                    Text("\(Int(tempMinHourlyRate)) DKK")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.ksrWarning)
                    
                    Spacer()
                    
                    Text("\(Int(tempMaxHourlyRate)) DKK")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.ksrWarning)
                }
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Min:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $tempMinHourlyRate, in: 0...1000, step: 25)
                            .accentColor(Color.ksrWarning)
                    }
                    
                    HStack {
                        Text("Max:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $tempMaxHourlyRate, in: 0...1000, step: 25)
                            .accentColor(Color.ksrWarning)
                    }
                }
                
                HStack(spacing: 12) {
                    Button("Reset Range") {
                        tempMinHourlyRate = 0
                        tempMaxHourlyRate = 1000
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6))
                    )
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Additional Filters
    
    private var additionalFiltersSection: some View {
        WorkersFilterSection(title: "Additional Filters", icon: "slider.horizontal.3") {
            VStack(spacing: 16) {
                FilterToggleRow(
                    title: "Only Active Assignments",
                    subtitle: "Show workers with active project assignments",
                    icon: "folder.badge.person.crop",
                    isOn: $tempShowOnlyActiveAssignments
                )
            }
        }
    }
    
    // MARK: - Active Filters Summary
    
    private var activeFiltersSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color.ksrInfo)
                
                Text("Active Filters")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if !tempSelectedStatuses.isEmpty {
                    Text("• Status: \(tempSelectedStatuses.map { $0.displayName }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !tempSelectedEmploymentTypes.isEmpty {
                    Text("• Employment: \(tempSelectedEmploymentTypes.map { $0.displayName }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !tempSelectedRoles.isEmpty {
                    Text("• Role: \(tempSelectedRoles.map { $0.danishName }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if tempMinHourlyRate > 0 || tempMaxHourlyRate < 1000 {
                    Text("• Rate: \(Int(tempMinHourlyRate))-\(Int(tempMaxHourlyRate)) DKK/hour")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if tempShowOnlyActiveAssignments {
                    Text("• Only workers with active assignments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ksrInfo.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.ksrInfo.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Background
    
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
    
    // MARK: - Helper Properties
    
    private var hasActiveFilters: Bool {
        return !tempSelectedStatuses.isEmpty ||  // Not empty means filters are active
               !tempSelectedEmploymentTypes.isEmpty ||
               !tempSelectedRoles.isEmpty ||
               tempMinHourlyRate > 0 ||
               tempMaxHourlyRate < 1000 ||
               tempShowOnlyActiveAssignments
    }
    
    // MARK: - Actions
    
    private func toggleStatus(_ status: WorkerStatus) {
        if tempSelectedStatuses.contains(status) {
            tempSelectedStatuses.remove(status)
        } else {
            tempSelectedStatuses.insert(status)
        }
    }
    
    private func toggleEmploymentType(_ type: EmploymentType) {
        if tempSelectedEmploymentTypes.contains(type) {
            tempSelectedEmploymentTypes.remove(type)
        } else {
            tempSelectedEmploymentTypes.insert(type)
        }
    }
    
    private func toggleRole(_ role: WorkerRole) {
        if tempSelectedRoles.contains(role) {
            tempSelectedRoles.remove(role)
        } else {
            tempSelectedRoles.insert(role)
        }
    }
    
    private func clearAllFilters() {
        tempSelectedStatuses = []  // Empty means show all statuses
        tempSelectedEmploymentTypes = []
        tempSelectedRoles = []
        tempMinHourlyRate = 0
        tempMaxHourlyRate = 1000
        tempShowOnlyActiveAssignments = false
    }
    
    private func applyFilters() {
        viewModel.selectedStatuses = tempSelectedStatuses
        viewModel.selectedEmploymentTypes = tempSelectedEmploymentTypes
        viewModel.selectedRoles = tempSelectedRoles
        viewModel.minHourlyRate = tempMinHourlyRate
        viewModel.maxHourlyRate = tempMaxHourlyRate
        viewModel.showOnlyActiveAssignments = tempShowOnlyActiveAssignments
    }
}

// MARK: - Supporting Components

struct WorkersFilterSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.ksrPrimary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                content
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
        }
    }
}

struct FilterToggleCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : Color.ksrDarkGray))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : (colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6).opacity(0.5)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color, lineWidth: isSelected ? 0 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.ksrPrimary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color.ksrPrimary))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

// MARK: - Preview

struct WorkersFiltersSheet_Previews: PreviewProvider {
    static var previews: some View {
        WorkersFiltersSheet(viewModel: ChefWorkersViewModel())
            .preferredColorScheme(.light)
    }
}