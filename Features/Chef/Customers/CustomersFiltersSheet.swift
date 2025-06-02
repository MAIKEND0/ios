//
//  CustomersFiltersSheet.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//

import SwiftUI

struct CustomersFiltersSheet: View {
    @Binding var sortOption: CustomersListView.CustomerSortOption
    @Binding var filterOption: CustomersListView.CustomerFilterOption
    @Binding var isGridView: Bool
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // View Mode Section
                    viewModeSection
                    
                    // Sort Options
                    sortOptionsSection
                    
                    // Filter Options
                    filterOptionsSection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(filtersBackground)
            .navigationTitle("Filters & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.ksrPrimary)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.ksrPrimary.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(Color.ksrPrimary)
            }
            
            VStack(spacing: 8) {
                Text("Customize View")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Choose how to display and organize your customers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - View Mode Section
    private var viewModeSection: some View {
        FilterSection(title: "Display Mode", icon: "square.grid.2x2.fill") {
            VStack(spacing: 12) {
                ViewModeOption(
                    title: "List View",
                    description: "Detailed list with contact information",
                    icon: "list.bullet",
                    isSelected: !isGridView
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isGridView = false
                    }
                }
                
                ViewModeOption(
                    title: "Grid View",
                    description: "Compact grid layout for quick overview",
                    icon: "square.grid.2x2",
                    isSelected: isGridView
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isGridView = true
                    }
                }
            }
        }
    }
    
    // MARK: - Sort Options Section
    private var sortOptionsSection: some View {
        FilterSection(title: "Sort By", icon: "arrow.up.arrow.down") {
            VStack(spacing: 8) {
                ForEach(CustomersListView.CustomerSortOption.allCases, id: \.self) { option in
                    SortOption(
                        title: option.rawValue,
                        description: sortDescription(for: option),
                        icon: option.icon,
                        isSelected: sortOption == option
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            sortOption = option
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Filter Options Section
    private var filterOptionsSection: some View {
        FilterSection(title: "Filter By", icon: "line.3.horizontal.decrease") {
            VStack(spacing: 8) {
                ForEach(CustomersListView.CustomerFilterOption.allCases, id: \.self) { option in
                    FilterOption(
                        title: option.rawValue,
                        description: filterDescription(for: option),
                        icon: option.icon,
                        isSelected: filterOption == option
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            filterOption = option
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Reset to Defaults
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    sortOption = .name
                    filterOption = .all
                    isGridView = false
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Reset to Defaults")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.ksrWarning)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.ksrWarning, lineWidth: 1)
                )
            }
            
            // Apply and Close
            Button {
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Apply Filters")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.ksrPrimary)
                        .shadow(color: Color.ksrPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Background
    private var filtersBackground: some View {
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
    
    // MARK: - Helper Methods
    
    private func sortDescription(for option: CustomersListView.CustomerSortOption) -> String {
        switch option {
        case .name:
            return "Alphabetical order"
        case .dateAdded:
            return "Newest customers first"
        case .projectCount:
            return "Most active customers first"
        case .lastActivity:
            return "Recently active customers first"
        }
    }
    
    private func filterDescription(for option: CustomersListView.CustomerFilterOption) -> String {
        switch option {
        case .all:
            return "Show all customers"
        case .active:
            return "Customers with ongoing projects"
        case .inactive:
            return "Customers without projects"
        case .recent:
            return "Added in the last 30 days"
        }
    }
}

// MARK: - Supporting Components

struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.ksrPrimary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 4)
            
            // Section Content
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct ViewModeOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.ksrPrimary.opacity(0.2) : Color(.systemGray5))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? Color.ksrPrimary : .secondary)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.ksrPrimary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                            ? Color.ksrPrimary.opacity(0.1)
                            : (colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.ksrPrimary : Color.clear,
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SortOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.ksrSuccess.opacity(0.2) : Color(.systemGray5))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? Color.ksrSuccess : .secondary)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.ksrSuccess : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.ksrSuccess)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6).opacity(0.5))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.ksrInfo.opacity(0.2) : Color(.systemGray5))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? Color.ksrInfo : .secondary)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection Indicator with Tag Style
                if isSelected {
                    Text("Active")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.ksrInfo)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                            ? Color.ksrInfo.opacity(0.1)
                            : (colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6).opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.ksrInfo.opacity(0.5) : Color.clear,
                                lineWidth: isSelected ? 1 : 0
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct CustomersFiltersSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                CustomersFiltersSheet(
                    sortOption: .constant(.name),
                    filterOption: .constant(.all),
                    isGridView: .constant(false)
                )
            }
            .preferredColorScheme(.light)
            
            NavigationStack {
                CustomersFiltersSheet(
                    sortOption: .constant(.dateAdded),
                    filterOption: .constant(.active),
                    isGridView: .constant(true)
                )
            }
            .preferredColorScheme(.dark)
        }
    }
}
