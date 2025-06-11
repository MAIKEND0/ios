//
//  ChefWorkersView.swift
//  KSR Cranes App
//  Main workers management view for Chef role
//

import SwiftUI

struct ChefWorkersManagementView: View {
    @StateObject private var viewModel = ChefWorkersViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAddWorker = false
    @State private var showingFilters = false
    @State private var searchText = ""
    @State private var selectedWorker: WorkerForChef?
    @State private var showingWorkerDetail = false
    @State private var workerToEdit: WorkerForChef?
    @State private var showingEditWorker = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                    // Header with stats overview
                    workersHeaderSection
                    
                    // Search and filter bar
                    searchAndFilterSection
                    
                    // Workers list
                    workersListSection
                }
            .background(backgroundGradient)
            .navigationTitle("Workers Management")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await refreshWorkers()
            }
            .navigationBarBackButtonHidden(false)
            .navigationBarItems(
                leading: Button {
                    showingFilters = true
                } label: {
                    ZStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                        
                        if viewModel.activeFiltersCount > 0 {
                            Text("\(viewModel.activeFiltersCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(Circle().fill(Color.ksrPrimary))
                                .offset(x: 10, y: -10)
                        }
                    }
                },
                trailing: HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.refreshData()
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                        }
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button {
                        showingAddWorker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.ksrYellow)
                            .font(.system(size: 18))
                    }
                }
            )
        .onAppear {
            viewModel.loadData()
        }
        .searchable(text: $searchText, prompt: "Search workers...")
        .onChange(of: searchText) { _, newValue in
            viewModel.searchWorkers(query: newValue)
        }
        .sheet(isPresented: $showingAddWorker) {
            AddWorkerView { newWorker in
                viewModel.addWorker(newWorker)
            }
        }
        .sheet(isPresented: $showingFilters) {
            WorkersFiltersSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingEditWorker) {
            if let worker = workerToEdit {
                EditWorkerView(worker: worker) { updatedWorker in
                    viewModel.updateWorker(updatedWorker)
                    workerToEdit = nil
                }
            }
        }
        .navigationDestination(isPresented: $showingWorkerDetail) {
            if let worker = selectedWorker {
                WorkerDetailView(worker: worker, viewModel: viewModel)
                    .onAppear {
                        print("🚀 [DEBUG] Navigating to WorkerDetailView for: \(worker.name)")
                    }
            } else {
                Text("Error: No worker selected")
                    .onAppear {
                        print("❌ [DEBUG] selectedWorker is nil!")
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
    }
    
    // MARK: - Header Section with Stats
    
    private var workersHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workers Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    
                    if let lastRefresh = viewModel.lastRefreshTime {
                        Text("Updated \(lastRefresh, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.ksrPrimary.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color.ksrPrimary)
                }
            }
            .padding(.horizontal, 16)
            
            // Stats cards
            if let stats = viewModel.overallStats {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    WorkerStatsCard(
                        title: "Total",
                        value: "\(stats.total_workers)",
                        icon: "person.3.fill",
                        color: Color.ksrPrimary
                    )
                    
                    WorkerStatsCard(
                        title: "Active",
                        value: "\(stats.active_workers)",
                        icon: "checkmark.circle.fill",
                        color: Color.ksrSuccess
                    )
                    
                    WorkerStatsCard(
                        title: "Avg Rate",
                        value: "\(Int(stats.average_hourly_rate))",
                        icon: "banknote.fill",
                        color: Color.ksrWarning
                    )
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.1) : Color.white.opacity(0.8))
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.ksrPrimary.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    // MARK: - Search and Filter Section
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 0) {
            // Status filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Clear filters button
                    if viewModel.hasActiveFilters {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.clearAllFilters()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                Text("Clear Filters")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.red)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .frame(height: 20)
                            .padding(.horizontal, 4)
                    }
                    
                    // Status filter chips
                    ForEach(WorkerStatus.allCases, id: \.self) { status in
                        ChefWorkerFilterChip(
                            title: status.displayName,
                            isSelected: viewModel.selectedStatuses.contains(status),
                            color: status.color
                        ) {
                            viewModel.toggleStatusFilter(status)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
            
            // Active filters summary
            if viewModel.hasActiveFilters {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.ksrInfo)
                    
                    Text("\(viewModel.filteredWorkers.count) of \(viewModel.workers.count) workers shown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .background(
            colorScheme == .dark ? Color(.systemGray6).opacity(0.1) : Color.white.opacity(0.5)
        )
    }
    
    // MARK: - Workers List Section
    
    private var workersListSection: some View {
        Group {
            if viewModel.isLoading && viewModel.workers.isEmpty {
                loadingView
            } else if viewModel.workers.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredWorkers) { worker in
                            WorkerListItem(worker: worker) {
                                print("🔍 [DEBUG] Clicked on worker: \(worker.name)")
                                selectedWorker = worker
                                showingWorkerDetail = true
                                print("🔍 [DEBUG] showingWorkerDetail set to: \(showingWorkerDetail)")
                                print("🔍 [DEBUG] selectedWorker set to: \(selectedWorker?.name ?? "nil")")
                            } deleteAction: {
                                print("🗑️ [DEBUG] Delete action for worker: \(worker.name)")
                                viewModel.deleteWorker(worker)
                            } editAction: {
                                print("✏️ [DEBUG] Edit action for worker: \(worker.name)")
                                workerToEdit = worker
                                showingEditWorker = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                .scaleEffect(1.2)
            
            Text("Loading workers...")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: viewModel.hasActiveFilters ? "magnifyingglass" : "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.ksrSecondary)
            
            VStack(spacing: 12) {
                Text(viewModel.hasActiveFilters ? "No Workers Match Filters" : "No Workers Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(viewModel.hasActiveFilters ? 
                     "Try adjusting your filters or search query to find workers." : 
                     "Add your first worker to get started with workforce management.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if viewModel.hasActiveFilters {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.clearAllFilters()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear All Filters")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .clipShape(Capsule())
                }
            } else {
                Button {
                    showingAddWorker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Worker")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.ksrPrimary)
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
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
    
    // MARK: - Helper Methods
    
    private func refreshWorkers() async {
        await withCheckedContinuation { continuation in
            viewModel.refreshData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
}

// MARK: - Worker Stats Card

struct WorkerStatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 3, x: 0, y: 1)
        )
    }
}

// MARK: - Filter Chip

struct ChefWorkerFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Worker List Item

struct WorkerListItem: View {
    let worker: WorkerForChef
    let action: () -> Void
    let deleteAction: () -> Void
    let editAction: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image or initials
            ZStack {
                Circle()
                    .fill(Color.ksrLightGray)
                    .frame(width: 56, height: 56)
                
                if let profileUrl = worker.profile_picture_url, !profileUrl.isEmpty {
                    AsyncImage(url: URL(string: profileUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Text(worker.initials)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                } else {
                    Text(worker.initials)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .overlay(
                Circle()
                    .stroke(worker.status.color, lineWidth: 2)
            )
            
            // Worker info - clickable area
            VStack(alignment: .leading, spacing: 6) {
                // Row 1: Name and Rate
                HStack(alignment: .center, spacing: 8) {
                    Text(worker.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)
                    
                    Spacer(minLength: 4)
                    
                    Text("\(Int(worker.hourly_rate)) DKK/h")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.ksrWarning)
                        .fixedSize()
                }
                
                // Row 2: Status, Role, Employment Type
                HStack(spacing: 8) {
                    // Status
                    HStack(spacing: 3) {
                        Image(systemName: worker.status.systemImage)
                            .font(.system(size: 10))
                        Text(worker.statusDisplayName)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(worker.status.color)
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    // Role
                    Text(worker.role.danishName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    // Employment Type
                    Text(worker.employmentDisplayName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                // Row 3: Stats (if available)
                if let stats = worker.stats {
                    HStack(spacing: 12) {
                        // This week hours
                        HStack(spacing: 3) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.ksrInfo)
                            Text("\(stats.hoursThisWeekFormatted)h")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        // Active tasks
                        if let activeTasks = stats.active_tasks, activeTasks > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.ksrSuccess)
                                Text("\(activeTasks)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Completed tasks
                        if let completedTasks = stats.completed_tasks, completedTasks > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.ksrPrimary)
                                Text("\(completedTasks)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                action()
            }
            
            // Actions button
            Menu {
                Button {
                    action()
                } label: {
                    Label("View Details", systemImage: "person.text.rectangle")
                }
                
                Button {
                    editAction()
                } label: {
                    Label("Edit Worker", systemImage: "pencil")
                }
                
                if worker.status != .opsagt {
                    Button(role: .destructive) {
                        deleteAction()
                    } label: {
                        Label("Delete Worker", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 3, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

struct ChefWorkersManagementView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChefWorkersManagementView()
                .preferredColorScheme(.light)
            ChefWorkersManagementView()
                .preferredColorScheme(.dark)
        }
    }
}