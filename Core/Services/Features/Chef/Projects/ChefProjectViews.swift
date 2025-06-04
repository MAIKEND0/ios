//
//  ChefProjectViews.swift
//  KSR Cranes App
//
//  Project management views for Chef role
//

import SwiftUI
import Combine

// MARK: - Projects List View
struct ChefProjectsView: View {
    @StateObject private var viewModel = ChefProjectsViewModel()
    @State private var showCreateProject = false
    @State private var selectedProject: Project?
    @State private var viewMode: ViewMode = .grid
    @Environment(\.colorScheme) private var colorScheme
    
    enum ViewMode {
        case grid, list
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Stats Header
                    projectStatsHeader
                    
                    // Search and View Controls
                    searchAndControlsSection
                    
                    // Projects Content
                    if viewModel.isLoading && viewModel.projects.isEmpty {
                        loadingView
                    } else if viewModel.filteredProjects.isEmpty {
                        emptyStateView
                    } else {
                        projectsContent
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateProject = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showCreateProject) {
                ChefCreateProjectView { newProject in  // ✅ UŻYWA PEŁNEGO VIEW
                    viewModel.loadProjects() // Refresh after creation
                    showCreateProject = false
                }
            }
            .sheet(item: $selectedProject) { project in
                ChefProjectDetailView(project: project)
            }
            .refreshable {
                await refreshProjects()
            }
            .onAppear {
                viewModel.loadProjects()
            }
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
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
    
    private var projectStatsHeader: some View {
        HStack(spacing: 12) {
            ChefProjectStatCard(
                title: "Active",
                value: "\(viewModel.projectStats.active)",
                icon: "play.circle.fill",
                color: .green
            )
            
            ChefProjectStatCard(
                title: "Waiting",
                value: "\(viewModel.projectStats.waiting)",
                icon: "clock.fill",
                color: .orange
            )
            
            ChefProjectStatCard(
                title: "Completed",
                value: "\(viewModel.projectStats.completed)",
                icon: "checkmark.circle.fill",
                color: .blue
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    private var searchAndControlsSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search projects or customers...", text: $viewModel.searchText)
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
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Filter and View Mode
            HStack {
                // Status Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ChefProjectFilterChip(
                            title: "All",
                            isSelected: viewModel.selectedStatus == nil,
                            action: { viewModel.selectedStatus = nil }
                        )
                        
                        ForEach(Project.ProjectStatus.allCases, id: \.self) { status in
                            ChefProjectFilterChip(
                                title: status.displayName,
                                isSelected: viewModel.selectedStatus == status,
                                color: status.color,
                                action: { viewModel.selectedStatus = status }
                            )
                        }
                    }
                }
                
                Spacer()
                
                // View Mode Toggle
                HStack(spacing: 4) {
                    Button {
                        viewMode = .grid
                    } label: {
                        Image(systemName: "square.grid.2x2")
                            .foregroundColor(viewMode == .grid ? .blue : .secondary)
                    }
                    
                    Button {
                        viewMode = .list
                    } label: {
                        Image(systemName: "list.bullet")
                            .foregroundColor(viewMode == .list ? .blue : .secondary)
                    }
                }
                .padding(4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
    
    private var projectsContent: some View {
        ScrollView {
            if viewMode == .grid {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(viewModel.filteredProjects) { project in
                        ChefProjectGridCard(project: project)
                            .onTapGesture {
                                selectedProject = project
                            }
                    }
                }
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredProjects) { project in
                        ChefProjectListCard(project: project)
                            .onTapGesture {
                                selectedProject = project
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
    
    private var loadingView: some View {
        ChefProjectsLoadingView()
    }
    
    private var emptyStateView: some View {
        ChefProjectsEmptyStateView {
            showCreateProject = true
        }
    }
    
    private func refreshProjects() async {
        await withCheckedContinuation { continuation in
            viewModel.loadProjects()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
}

// MARK: - Supporting Components

struct ChefProjectStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

struct ChefProjectFilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .black : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? color : Color(.systemGray5))
                )
        }
    }
}

// ✅ POPRAWIONY ChefProjectGridCard z bezpiecznym progress
struct ChefProjectGridCard: View {
    let project: Project
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with logo
            HStack {
                if let logoUrl = project.customer?.logo_url {
                    AsyncImage(url: URL(string: logoUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 30, height: 30)
                    .cornerRadius(6)
                } else {
                    Image(systemName: "building.2.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ChefStatusBadge(status: project.status, compact: true)
            }
            
            // Title and Customer
            VStack(alignment: .leading, spacing: 4) {
                Text(project.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let customer = project.customer {
                    Text(customer.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // ✅ BEZPIECZNY Progress
            if let completion = project.completionPercentage {
                let safeCompletion = completion.isNaN || completion.isInfinite ? 0.0 : max(0.0, min(100.0, completion))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(Int(safeCompletion))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("Complete")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemGray5))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(project.status.color)
                                .frame(width: max(0, geometry.size.width * (safeCompletion / 100)), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
            
            // Stats
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.caption2)
                    Text("\(project.tasksCount ?? 0)")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.3.fill")
                        .font(.caption2)
                    Text("\(project.assignedWorkersCount ?? 0)")
                        .font(.caption2)
                }
                .foregroundColor(.green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// ✅ POPRAWIONY ChefProjectListCard z bezpiecznym progress
struct ChefProjectListCard: View {
    let project: Project
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Customer Logo
            if let logoUrl = project.customer?.logo_url {
                AsyncImage(url: URL(string: logoUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 50)
                .cornerRadius(10)
            } else {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
            }
            
            // Project Info
            VStack(alignment: .leading, spacing: 6) {
                Text(project.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let customer = project.customer {
                    Text(customer.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 16) {
                    if let city = project.city {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(city)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.caption2)
                            Text("\(project.tasksCount ?? 0)")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "person.3.fill")
                                .font(.caption2)
                            Text("\(project.assignedWorkersCount ?? 0)")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // Status and Progress
            VStack(alignment: .trailing, spacing: 8) {
                ChefStatusBadge(status: project.status)
                
                // ✅ BEZPIECZNY PROGRESS
                if let completion = project.completionPercentage {
                    let safeCompletion = completion.isNaN || completion.isInfinite ? 0.0 : max(0.0, min(100.0, completion))
                    
                    ChefCircularProgressView(
                        progress: safeCompletion / 100.0, // ✅ BEZPIECZNA KONWERSJA
                        size: 35,
                        lineWidth: 3,
                        showPercentage: true,
                        fontSize: .caption2
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct ChefStatusBadge: View {
    let status: Project.ProjectStatus
    let compact: Bool
    
    init(status: Project.ProjectStatus, compact: Bool = false) {
        self.status = status
        self.compact = compact
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(compact ? .caption2 : .caption)
            
            if !compact {
                Text(status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(status.color)
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(
            RoundedRectangle(cornerRadius: compact ? 4 : 6)
                .fill(status.color.opacity(0.15))
        )
    }
}

// ✅ POPRAWIONY ChefCircularProgressView z zabezpieczeniami NaN
struct ChefCircularProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let showPercentage: Bool
    let fontSize: Font
    
    init(
        progress: Double,
        size: CGFloat = 40,
        lineWidth: CGFloat = 3,
        showPercentage: Bool = true,
        fontSize: Font = .caption2
    ) {
        // ✅ ZABEZPIECZENIE PRZED NaN
        self.progress = progress.isNaN || progress.isInfinite ? 0.0 : max(0.0, min(1.0, progress))
        self.size = size
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
        self.fontSize = fontSize
    }
    
    // ✅ ZABEZPIECZONA WARTOŚĆ PROGRESS
    private var safeProgress: Double {
        guard !progress.isNaN && !progress.isInfinite else { return 0.0 }
        return max(0.0, min(1.0, progress))
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: safeProgress) // ✅ UŻYJ BEZPIECZNEJ WARTOŚCI
                .stroke(Color.green, lineWidth: lineWidth)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: safeProgress)
            
            if showPercentage {
                Text("\(Int(safeProgress * 100))%") // ✅ UŻYJ BEZPIECZNEJ WARTOŚCI
                    .font(fontSize)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Additional Supporting Views

struct ChefProjectsLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.2)
            
            Text("Loading projects...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ChefProjectsEmptyStateView: View {
    let onCreateProject: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Projects Found")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Create your first project to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button {
                onCreateProject()
            } label: {
                Label("Create Project", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Placeholder views for components to be implemented

struct ChefTaskDetailView: View {
    let task: ProjectTask
    
    var body: some View {
        Text("Task: \(task.title)")
    }
}
