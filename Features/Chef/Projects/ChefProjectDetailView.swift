//
//  ChefProjectDetailView.swift - FIXED with Enhanced Error Handling
//  KSR Cranes App
//
//  Detailed project view for Chef role with robust task loading
//

import SwiftUI
import Combine

struct ChefProjectDetailView: View {
    let project: Project
    
    @StateObject private var viewModel = ProjectDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: DetailTab = .overview
    @State private var showCreateTask = false
    @State private var showEditProject = false
    @State private var showDeleteConfirmation = false
    @State private var selectedTask: ProjectTask?
    @State private var cancellables = Set<AnyCancellable>()
    
    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case tasks = "Tasks"
        case billing = "Billing"
        case timeline = "Timeline"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .tasks: return "list.bullet.clipboard.fill"
            case .billing: return "dollarsign.circle.fill"
            case .timeline: return "calendar"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Project Header
                projectHeader
                
                // Tab Selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    overviewTab.tag(DetailTab.overview)
                    tasksTab.tag(DetailTab.tasks)
                    billingTab.tag(DetailTab.billing)
                    timelineTab.tag(DetailTab.timeline)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(backgroundGradient)
            .navigationTitle(project.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showEditProject = true
                        } label: {
                            Label("Edit Project", systemImage: "pencil")
                        }
                        
                        Button {
                            showCreateTask = true
                        } label: {
                            Label("Add Task", systemImage: "plus")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Archive Project", systemImage: "archivebox")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.ksrYellow)
                    }
                }
            }
            .sheet(isPresented: $showCreateTask) {
                ChefCreateTaskView(projectId: project.id) { newTask in
                    viewModel.loadTasks(for: project.id)
                }
            }
            .sheet(isPresented: $showEditProject) {
                ChefEditProjectView(project: project) { updatedProject in
                    // Handle project update
                }
            }
            .sheet(item: $selectedTask) { task in
                ChefFullTaskDetailView(task: task)
            }
            .confirmationDialog(
                "Archive Project",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Archive", role: .destructive) {
                    deleteProject()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will archive the project and all its tasks. This action cannot be undone.")
            }
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                loadProjectData()
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
    
    private var projectHeader: some View {
        VStack(spacing: 16) {
            // Customer and Status Row
            HStack {
                // Customer Logo and Info
                if let customer = project.customer {
                    HStack(spacing: 12) {
                        if let logoUrl = customer.logo_url {
                            AsyncImage(url: URL(string: logoUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(.ksrSecondary)
                            }
                            .frame(width: 50, height: 50)
                            .cornerRadius(10)
                        } else {
                            Image(systemName: "building.2.fill")
                                .font(.title2)
                                .foregroundColor(.ksrSecondary)
                                .frame(width: 50, height: 50)
                                .background(Color.ksrLightGray.opacity(0.3))
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(customer.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if let email = customer.contact_email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Project Status - Use existing ChefStatusBadge
                ChefStatusBadge(status: project.status)
            }
            
            // Project Location
            if let street = project.street, let city = project.city {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.ksrInfo)
                    
                    Text("\(street), \(city)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let zip = project.zip {
                        Text(zip)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Project Progress
            if let completion = project.completionPercentage {
                let safeCompletion = completion.safePercentage
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(safeCompletion))% Complete")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(project.status.color)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.ksrLightGray.opacity(0.3))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(project.status.color)
                                .frame(width: geometry.size.width * (safeCompletion / 100), height: 8)
                                .animation(.easeInOut, value: safeCompletion)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedTab == tab ? .black : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTab == tab ? Color.ksrYellow : Color.ksrLightGray.opacity(0.3))
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Tab Content
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Project Stats
                projectStats
                
                // Recent Activity
                recentActivity
                
                // Quick Actions
                quickActions
            }
            .padding()
        }
    }
    
    // ✅ FIXED: Enhanced Tasks Tab with Error Handling
    private var tasksTab: some View {
        VStack(spacing: 0) {
            // Tasks Header
            HStack {
                Text("Tasks")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if viewModel.isLoadingTasks {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button {
                        showCreateTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.ksrYellow)
                    }
                }
            }
            .padding()
            
            // Tasks Content with Error Handling
            if let error = viewModel.tasksError {
                // Error State
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red.opacity(0.6))
                    
                    Text("Failed to Load Tasks")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button {
                        viewModel.loadTasks(for: project.id)
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.ksrYellow)
                            .cornerRadius(25)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                
            } else if viewModel.isLoadingTasks {
                // Loading State
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                        .scaleEffect(1.2)
                    
                    Text("Loading tasks...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if viewModel.tasks.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 50))
                        .foregroundColor(.ksrYellow.opacity(0.6))
                    
                    Text("No Tasks Yet")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Create your first task to get started")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showCreateTask = true
                    } label: {
                        Label("Create Task", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.ksrYellow)
                            .cornerRadius(25)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                
            } else {
                // Success State - Tasks List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.tasks) { task in
                            ChefTaskDetailCard(task: task) {
                                selectedTask = task
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var billingTab: some View {
            ChefProjectBillingView(projectId: project.id)
        }
    
    private var timelineTab: some View {
        ChefBusinessTimelineView(projectId: project.id)
    }
    
    // MARK: - Overview Components
    
    private var projectStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Project Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ChefProjectDetailStatCard(
                    title: "Tasks",
                    value: "\(project.tasksCount ?? 0)",
                    icon: "list.bullet",
                    color: .ksrInfo
                )
                
                ChefProjectDetailStatCard(
                    title: "Workers",
                    value: "\(project.assignedWorkersCount ?? 0)",
                    icon: "person.3.fill",
                    color: .ksrSuccess
                )
                
                ChefProjectDetailStatCard(
                    title: "Progress",
                    value: "\(Int(project.completionPercentage?.safePercentage ?? 0))",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .ksrWarning
                )
                
                ChefProjectDetailStatCard(
                    title: "Status",
                    value: project.status.displayName,
                    icon: project.status.icon,
                    color: project.status.color
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ChefActivityItem(
                    icon: "plus.circle.fill",
                    title: "Project created",
                    time: project.createdAt ?? Date(),
                    color: .ksrSuccess
                )
                
                if !viewModel.tasks.isEmpty {
                    ChefActivityItem(
                        icon: "list.bullet.clipboard.fill",
                        title: "Tasks added",
                        time: viewModel.tasks.first?.createdAt ?? Date(),
                        color: .ksrInfo
                    )
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
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ChefQuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Add Task",
                    subtitle: "Create a new task for this project",
                    color: .ksrYellow,
                    action: {
                        showCreateTask = true
                    }
                )
                
                ChefQuickActionButton(
                    icon: "person.badge.plus",
                    title: "Assign Workers",
                    subtitle: "Assign workers to project tasks",
                    color: .ksrSuccess,
                    action: {
                        // TODO: Navigate to worker assignment
                    }
                )
                
                ChefQuickActionButton(
                    icon: "dollarsign.circle.fill",
                    title: "Manage Billing",
                    subtitle: "Update billing rates and settings",
                    color: .ksrInfo,
                    action: {
                        selectedTab = .billing
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // ✅ FIXED: Better project data loading with proper initialization
    private func loadProjectData() {
        #if DEBUG
        print("🔄 [ChefProjectDetailView] Loading project data for: \(project.title)")
        #endif
        
        // Set the current project immediately to avoid blank screen
        viewModel.project = project
        
        // Load tasks (this works fine according to your logs)
        viewModel.loadTasks(for: project.id)
        
        // Try to load additional project details, but don't fail if it doesn't work
        // Use the simple method since your API appears to return a simple Project object
        viewModel.loadProjectDetailSimple(projectId: project.id)
    }
    
    private func deleteProject() {
        ChefProjectsAPIService.shared.deleteProject(id: project.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        viewModel.errorMessage = error.localizedDescription
                        viewModel.showError = true
                    }
                },
                receiveValue: { response in
                    // Project deleted successfully
                    dismiss()
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Views (Only new ones, not duplicating existing)

struct ChefProjectDetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.systemGray6))
        )
    }
}

struct ChefActivityItem: View {
    let icon: String
    let title: String
    let time: Date
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(time.relativeDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ChefQuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.ksrSecondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ChefTaskDetailCard: View {
    let task: ProjectTask
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Task Status Indicator
                Circle()
                    .fill(task.isActive ? Color.ksrSuccess : Color.ksrSecondary)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let description = task.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        if let assignmentsCount = task.assignmentsCount, assignmentsCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                Text("\(assignmentsCount) assigned")
                                    .font(.caption)
                            }
                            .foregroundColor(.ksrInfo)
                        }
                        
                        if let deadline = task.deadline {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text(deadline, style: .date)
                                    .font(.caption)
                            }
                            .foregroundColor(.ksrWarning)
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.ksrSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Project View (Placeholder)

struct ChefEditProjectView: View {
    let project: Project
    let onProjectUpdated: ((Project) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    init(project: Project, onProjectUpdated: ((Project) -> Void)? = nil) {
        self.project = project
        self.onProjectUpdated = onProjectUpdated
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Edit Project")
                    .font(.title)
                Text("To Be Implemented")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
