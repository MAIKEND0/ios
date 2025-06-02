//
//  CustomersListView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//  Updated with Logo Support
//

import SwiftUI

struct CustomersListView: View {
    @StateObject private var viewModel = CustomersViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCreateForm = false
    @State private var showFilters = false
    @State private var selectedCustomer: Customer?
    @State private var showCustomerDetail = false
    @State private var searchText = ""
    @State private var sortOption: CustomerSortOption = .name
    @State private var filterOption: CustomerFilterOption = .all
    @State private var isGridView = false
    
    enum CustomerSortOption: String, CaseIterable {
        case name = "Name"
        case dateAdded = "Date Added"
        case projectCount = "Projects"
        case lastActivity = "Last Activity"
        
        var icon: String {
            switch self {
            case .name: return "textformat.abc"
            case .dateAdded: return "calendar.badge.plus"
            case .projectCount: return "folder.fill"
            case .lastActivity: return "clock.fill"
            }
        }
    }
    
    enum CustomerFilterOption: String, CaseIterable {
        case all = "All Customers"
        case active = "Active Projects"
        case inactive = "No Projects"
        case recent = "Added Recently"
        
        var icon: String {
            switch self {
            case .all: return "building.2.fill"
            case .active: return "folder.badge.checkmark"
            case .inactive: return "folder.badge.questionmark"
            case .recent: return "calendar.badge.plus"
            }
        }
    }
    
    private var filteredAndSortedCustomers: [Customer] {
        var customers = viewModel.customers
        
        // Apply search filter
        if !searchText.isEmpty {
            customers = customers.filter { $0.matches(searchText: searchText) }
        }
        
        // Apply category filter
        switch filterOption {
        case .all:
            break
        case .active:
            // Mock: customers with projects (in real app, fetch from API)
            customers = customers.filter { _ in Bool.random() }
        case .inactive:
            // Mock: customers without projects
            customers = customers.filter { _ in Bool.random() }
        case .recent:
            // Added in last 30 days
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            customers = customers.filter { customer in
                guard let createdAt = customer.created_at else { return false }
                return createdAt > thirtyDaysAgo
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .name:
            customers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .dateAdded:
            customers.sort {
                ($0.created_at ?? Date.distantPast) > ($1.created_at ?? Date.distantPast)
            }
        case .projectCount:
            // Mock sorting by project count
            customers.sort { _, _ in Bool.random() }
        case .lastActivity:
            // Mock sorting by last activity
            customers.sort { _, _ in Bool.random() }
        }
        
        return customers
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Controls Bar
                searchAndControlsSection
                
                // Stats Header
                if !viewModel.isLoading && !viewModel.customers.isEmpty {
                    statsHeaderSection
                }
                
                // Main Content
                mainContentSection
            }
            .background(customersBackground)
            .navigationTitle("Customers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(filterOption != .all ? Color.ksrYellow : Color.ksrPrimary)
                    }
                    
                    Button {
                        showCreateForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.ksrPrimary)
                            .font(.system(size: 20))
                    }
                }
            }
            .onAppear {
                viewModel.loadCustomers()
            }
            .refreshable {
                await refreshCustomers()
            }
        }
        .sheet(isPresented: $showCreateForm) {
            CreateCustomerView()
                .onDisappear {
                    viewModel.loadCustomers() // Refresh after creating
                }
        }
        .sheet(isPresented: $showFilters) {
            CustomersFiltersSheet(
                sortOption: $sortOption,
                filterOption: $filterOption,
                isGridView: $isGridView
            )
        }
        .sheet(item: $selectedCustomer) { customer in
            CustomerDetailView(customer: customer)
                .onDisappear {
                    viewModel.loadCustomers() // Refresh after potential edits
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
    
    // MARK: - Search and Controls
    private var searchAndControlsSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField("Search customers...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6))
            )
            
            // Quick Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CustomerFilterOption.allCases, id: \.self) { filter in
                        CustomerFilterChip(
                            title: filter.rawValue,
                            icon: filter.icon,
                            isSelected: filterOption == filter
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                filterOption = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.1) : Color.white)
    }
    
    // MARK: - Stats Header
    private var statsHeaderSection: some View {
        HStack(spacing: 16) {
            CustomerStatChip(
                title: "Total",
                value: "\(viewModel.customers.count)",
                icon: "building.2.fill",
                color: .ksrInfo
            )
            
            CustomerStatChip(
                title: "Filtered",
                value: "\(filteredAndSortedCustomers.count)",
                icon: "line.3.horizontal.decrease",
                color: .ksrPrimary
            )
            
            CustomerStatChip(
                title: "New",
                value: "\(newThisMonthCount)",
                icon: "calendar.badge.plus",
                color: .ksrSuccess
            )
            
            Spacer()
            
            // View Toggle
            HStack(spacing: 4) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isGridView = false
                    }
                } label: {
                    Image(systemName: "list.bullet")
                        .foregroundColor(isGridView ? .secondary : .primary)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isGridView = true
                    }
                } label: {
                    Image(systemName: "square.grid.2x2")
                        .foregroundColor(isGridView ? .primary : .secondary)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.1) : Color.white.opacity(0.8))
    }
    
    // MARK: - Main Content
    private var mainContentSection: some View {
        Group {
            if viewModel.isLoading {
                CustomersLoadingView()
            } else if viewModel.customers.isEmpty {
                CustomersEmptyStateView {
                    showCreateForm = true
                }
            } else if filteredAndSortedCustomers.isEmpty {
                CustomersNoResultsView(searchText: searchText, filterOption: filterOption) {
                    searchText = ""
                    filterOption = .all
                }
            } else {
                if isGridView {
                    customersGridView
                } else {
                    customersListView
                }
            }
        }
    }
    
    // MARK: - List View
    private var customersListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredAndSortedCustomers) { customer in
                    CustomerListCardWithLogo(customer: customer) {
                        selectedCustomer = customer
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Grid View
    private var customersGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(filteredAndSortedCustomers) { customer in
                    CustomerGridCardWithLogo(customer: customer) {
                        selectedCustomer = customer
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Background
    private var customersBackground: some View {
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
    private var newThisMonthCount: Int {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return viewModel.customers.filter { customer in
            guard let createdAt = customer.created_at else { return false }
            return createdAt >= startOfMonth
        }.count
    }
    
    private func refreshCustomers() async {
        await withCheckedContinuation { continuation in
            viewModel.loadCustomers()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
}

// MARK: - Supporting Views

struct CustomerFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.ksrPrimary : Color(.systemGray5))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomerStatChip: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Updated Customer Cards with Logo Support

struct CustomerListCardWithLogo: View {
    let customer: Customer
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Customer Avatar/Logo
                CustomerAvatarView(customer: customer, size: 50)
                
                // Customer Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(customer.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Logo indicator
                        if customer.hasLogo {
                            Image(systemName: "photo.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color.ksrSuccess)
                        }
                    }
                    
                    if let email = customer.contact_email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 12) {
                        if let phone = customer.phone {
                            Label(phone, systemImage: "phone.fill")
                                .font(.caption)
                                .foregroundColor(Color.ksrSuccess)
                        }
                        
                        if let cvr = customer.formattedCVR {
                            Text(cvr)
                                .font(.caption)
                                .foregroundColor(Color.ksrWarning)
                        }
                    }
                }
                
                Spacer()
                
                // Action Indicator
                VStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(customer.createdAtFormatted)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomerGridCardWithLogo: View {
    let customer: Customer
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Customer Avatar/Logo
                CustomerAvatarView(customer: customer, size: 60)
                
                // Customer Info
                VStack(spacing: 6) {
                    Text(customer.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        if customer.hasContactInfo {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(Color.ksrSuccess)
                                
                                Text("Contact")
                                    .font(.caption2)
                                    .foregroundColor(Color.ksrSuccess)
                            }
                        }
                        
                        if customer.hasLogo {
                            HStack(spacing: 4) {
                                Image(systemName: "photo.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(Color.ksrInfo)
                                
                                Text("Logo")
                                    .font(.caption2)
                                    .foregroundColor(Color.ksrInfo)
                            }
                        }
                    }
                    
                    if let cvr = customer.cvr_nr {
                        Text("CVR: \(cvr)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Customer Avatar View Component

struct CustomerAvatarView: View {
    let customer: Customer
    let size: CGFloat
    
    var body: some View {
        Group {
            if customer.hasLogo, let logoUrl = customer.logo_url {
                AsyncImage(url: URL(string: logoUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    CustomerAvatarPlaceholder(name: customer.name, size: size)
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                CustomerAvatarPlaceholder(name: customer.name, size: size)
            }
        }
    }
}

struct CustomerAvatarPlaceholder: View {
    let name: String
    let size: CGFloat
    
    init(name: String, size: CGFloat = 50) {
        self.name = name
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.ksrInfo.opacity(0.2))
                .frame(width: size, height: size)
            
            Text(String(name.prefix(1)))
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(Color.ksrInfo)
        }
    }
}

// MARK: - Loading and Empty States

struct CustomersLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .ksrPrimary))
                .scaleEffect(1.2)
            
            Text("Loading customers...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CustomersEmptyStateView: View {
    let onAddCustomer: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "building.2")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(Color.ksrInfo)
            
            VStack(spacing: 12) {
                Text("No Customers Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Start building your customer base by adding your first customer.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button {
                onAddCustomer()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    
                    Text("Add First Customer")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.ksrPrimary)
                        .shadow(color: Color.ksrPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct CustomersNoResultsView: View {
    let searchText: String
    let filterOption: CustomersListView.CustomerFilterOption
    let onClearFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Results Found")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !searchText.isEmpty {
                    Text("No customers match '\(searchText)'")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("No customers match the current filter")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Button {
                onClearFilters()
            } label: {
                Text("Clear Filters")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.ksrPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.ksrPrimary, lineWidth: 1)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Mock CustomersFiltersSheet for compilation
struct CustomersFiltersSheet: View {
    @Binding var sortOption: CustomersListView.CustomerSortOption
    @Binding var filterOption: CustomersListView.CustomerFilterOption
    @Binding var isGridView: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Display Mode") {
                    Picker("View Style", selection: $isGridView) {
                        Text("List View").tag(false)
                        Text("Grid View").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Sort By") {
                    Picker("Sort Option", selection: $sortOption) {
                        ForEach(CustomersListView.CustomerSortOption.allCases, id: \.self) { option in
                            HStack {
                                Image(systemName: option.icon)
                                Text(option.rawValue)
                            }
                            .tag(option)
                        }
                    }
                }
                
                Section("Filter By") {
                    Picker("Filter Option", selection: $filterOption) {
                        ForEach(CustomersListView.CustomerFilterOption.allCases, id: \.self) { option in
                            HStack {
                                Image(systemName: option.icon)
                                Text(option.rawValue)
                            }
                            .tag(option)
                        }
                    }
                }
                
                Section {
                    Button("Reset to Defaults") {
                        sortOption = .name
                        filterOption = .all
                        isGridView = false
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
    }
}

// MARK: - Preview
struct CustomersListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CustomersListView()
                .preferredColorScheme(.light)
            CustomersListView()
                .preferredColorScheme(.dark)
        }
    }
}
