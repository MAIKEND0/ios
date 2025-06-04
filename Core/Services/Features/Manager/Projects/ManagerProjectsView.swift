//
//  ManagerProjectsView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 17/05/2025.
//  Visual improvements added

import SwiftUI

struct ManagerProjectsView: View {
    @StateObject private var viewModel = ManagerProjectsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedStatusFilter: ProjectStatusFilter = .all
    @State private var searchText = ""
    @State private var isGridView = false
    
    enum ProjectStatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        case pending = "Pending"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .active: return "play.circle.fill"
            case .completed: return "checkmark.circle.fill"
            case .pending: return "clock.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .active: return .green
            case .completed: return .gray
            case .pending: return .orange
            }
        }
    }
    
    var filteredProjects: [ManagerAPIService.Project] {
        let filtered = viewModel.filteredProjects
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { project in
                project.title.localizedCaseInsensitiveContains(searchText) ||
                project.customer?.name.localizedCaseInsensitiveContains(searchText) == true ||
                project.fullAddress?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Header z statystykami
                    headerStatsSection
                    
                    // Sekcja wyszukiwania i filtrowania
                    searchAndFilterSection
                    
                    // Toggle dla widoku
                    viewToggleSection
                    
                    // Sekcja projektów
                    projectsContentSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(backgroundGradient)
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.loadData()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(colorScheme == .dark ? .white : Color.primary)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
            .onAppear {
                viewModel.loadData()
            }
            .refreshable {
                await withCheckedContinuation { continuation in
                    viewModel.loadData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        continuation.resume()
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
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color(.systemBackground),
                colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6).opacity(0.5)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Stats Section
    private var headerStatsSection: some View {
        HStack(spacing: 16) {
            ProjectStatCard(
                title: "Total Projects",
                value: "\(viewModel.projects.count)",
                icon: "folder.fill",
                color: .blue
            )
            
            ProjectStatCard(
                title: "Active",
                value: "\(viewModel.projects.filter { $0.status == .aktiv }.count)",
                icon: "play.circle.fill",
                color: .green
            )
            
            ProjectStatCard(
                title: "Pending",
                value: "\(viewModel.projects.filter { $0.status == .afventer }.count)",
                icon: "clock.circle.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField("Search projects, customers, addresses...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            )
            
            // Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ProjectStatusFilter.allCases, id: \.id) { filter in
                        ProjectFilterChip(
                            filter: filter,
                            isSelected: selectedStatusFilter == filter
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedStatusFilter = filter
                                viewModel.filterProjects(by: filter)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - View Toggle Section
    private var viewToggleSection: some View {
        HStack {
            Text("\(filteredProjects.count) projects")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 8) {
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            )
        }
    }
    
    // MARK: - Projects Content Section
    private var projectsContentSection: some View {
        Group {
            if viewModel.isLoading {
                ProjectsLoadingView()
            } else if filteredProjects.isEmpty {
                ProjectsEmptyStateView()
            } else {
                if isGridView {
                    gridProjectsView
                } else {
                    listProjectsView
                }
            }
        }
    }
    
    // MARK: - Grid Projects View
    private var gridProjectsView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 16) {
            ForEach(filteredProjects) { project in
                ProjectGridCard(project: project)
            }
        }
    }
    
    // MARK: - List Projects View
    private var listProjectsView: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredProjects) { project in
                ProjectListCard(project: project)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: filteredProjects.count)
    }
    
    // MARK: - Date Formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Supporting Views

struct ProjectStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ProjectFilterChip: View {
    let filter: ManagerProjectsView.ProjectStatusFilter
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? filter.color : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProjectListCard: View {
    let project: ManagerAPIService.Project
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .lineLimit(2)
                        
                        if let customer = project.customer?.name {
                            Label(customer, systemImage: "building.2")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        ProjectStatusBadge(status: project.status)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Quick stats
                HStack(spacing: 20) {
                    ProjectStatItem(icon: "person.2", value: "\(project.assignedWorkersCount)", label: "Workers")
                    ProjectStatItem(icon: "list.clipboard", value: "\(project.tasks.count)", label: "Tasks")
                    
                    if let address = project.fullAddress {
                        Spacer()
                        Label(address, systemImage: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(20)
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if let description = project.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Description")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        // Dates
                        HStack(spacing: 20) {
                            if let startDate = project.start_date {
                                ProjectDateItem(label: "Start", date: startDate, icon: "calendar.badge.plus")
                            }
                            if let endDate = project.end_date {
                                ProjectDateItem(label: "End", date: endDate, icon: "calendar.badge.minus")
                            }
                        }
                        
                        // Tasks
                        if !project.tasks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tasks (\(project.tasks.count))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                ForEach(project.tasks.prefix(3)) { task in
                                    HStack {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 6, height: 6)
                                        
                                        Text(task.title)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                    }
                                }
                                
                                if project.tasks.count > 3 {
                                    Text("and \(project.tasks.count - 3) more...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(project.status?.color.opacity(0.3) ?? Color.clear, lineWidth: 1)
        )
    }
}

struct ProjectGridCard: View {
    let project: ManagerAPIService.Project
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                ProjectStatusBadge(status: project.status)
                Spacer()
                Image(systemName: "folder.fill")
                    .foregroundColor(project.status?.color ?? .gray)
                    .font(.system(size: 16))
            }
            
            // Title
            Text(project.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Customer
            if let customer = project.customer?.name {
                Text(customer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Stats
            HStack {
                ProjectStatItem(icon: "person.2", value: "\(project.assignedWorkersCount)", label: nil)
                Spacer()
                ProjectStatItem(icon: "list.clipboard", value: "\(project.tasks.count)", label: nil)
            }
        }
        .padding(16)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(project.status?.color.opacity(0.3) ?? Color.clear, lineWidth: 1)
        )
    }
}

struct ProjectStatusBadge: View {
    let status: ManagerAPIService.ProjectStatus?
    
    var body: some View {
        Text((status?.rawValue.capitalized ?? "Unknown").capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(status?.color ?? .gray)
            )
            .foregroundColor(.white)
    }
}

struct ProjectStatItem: View {
    let icon: String
    let value: String
    let label: String?
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            if let label = label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ProjectDateItem: View {
    let label: String
    let date: Date
    let icon: String
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Text(dateFormatter.string(from: date))
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

struct ProjectsLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading projects...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

struct ProjectsEmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No projects found")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text("No projects match your current filters or search criteria.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.vertical, 40)
    }
}

// MARK: - Extensions

extension ManagerAPIService.ProjectStatus {
    var color: Color {
        switch self {
        case .aktiv: return .green
        case .afsluttet: return .gray
        case .afventer: return .orange
        }
    }
}

struct ManagerProjectsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ManagerProjectsView()
                .preferredColorScheme(.light)
            ManagerProjectsView()
                .preferredColorScheme(.dark)
        }
    }
}
