//
//  WorkerTaskDetailView.swift
//  KSR Cranes App
//
//  Enhanced Task Detail View with modern design
//

import SwiftUI

struct WorkerTaskDetailView: View {
    let task: WorkerAPIService.Task
    @StateObject private var hoursViewModel = WorkerWorkHoursViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var showContactSupervisor = false
    @State private var expandedSections: Set<DetailSection> = []
    
    enum DetailSection: CaseIterable {
        case overview, project, equipment, supervisor, assignments, workHistory
        
        var title: String {
            switch self {
            case .overview: return "Overview"
            case .project: return "Project Details"
            case .equipment: return "Equipment Requirements"
            case .supervisor: return "Supervisor"
            case .assignments: return "Assignments"
            case .workHistory: return "Work History"
            }
        }
        
        var icon: String {
            switch self {
            case .overview: return "info.circle.fill"
            case .project: return "building.2.fill"
            case .equipment: return "wrench.and.screwdriver.fill"
            case .supervisor: return "person.fill"
            case .assignments: return "list.bullet.clipboard.fill"
            case .workHistory: return "clock.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .overview: return .ksrPrimary
            case .project: return .ksrInfo
            case .equipment: return .ksrWarning
            case .supervisor: return .ksrSuccess
            case .assignments: return .purple
            case .workHistory: return .ksrSecondary
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Task Header Card
                    taskHeaderCard
                    
                    // Task Overview Section
                    if shouldShowSection(.overview) {
                        taskOverviewSection
                    }
                    
                    // Project Details Section
                    if shouldShowSection(.project) {
                        projectDetailsSection
                    }
                    
                    // Equipment Requirements Section
                    if shouldShowSection(.equipment) {
                        equipmentRequirementsSection
                    }
                    
                    // Supervisor Section
                    if shouldShowSection(.supervisor) {
                        supervisorSection
                    }
                    
                    // Assignments Section
                    if shouldShowSection(.assignments) {
                        assignmentsSection
                    }
                    
                    // Work History Section
                    workHistorySection
                    
                    // Bottom padding
                    Color.clear.frame(height: 50)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(dashboardBackground)
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolbarButtons
                }
            }
            .onAppear {
                loadWorkHistory()
            }
            .sheet(isPresented: $showContactSupervisor) {
                supervisorContactSheet
            }
        }
    }
    
    // MARK: - Task Header Card
    private var taskHeaderCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                taskIconLarge
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrTextPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if let project = task.project {
                        HStack(spacing: 6) {
                            Image(systemName: "building.2")
                                .font(.subheadline)
                                .foregroundColor(Color.ksrInfo)
                            
                            Text(project.title)
                                .font(.subheadline)
                                .foregroundColor(Color.ksrTextSecondary)
                        }
                    }
                    
                    // Status indicators
                    statusIndicatorsRow
                }
                
                Spacer()
            }
            
            // Quick stats
            quickStatsRow
        }
        .padding(20)
        .background(WorkerDashboardSections.cardBackground(colorScheme: colorScheme))
        .overlay(WorkerDashboardSections.cardStroke(.ksrPrimary))
    }
    
    private var taskIconLarge: some View {
        ZStack {
            Circle()
                .fill(taskIconGradient)
                .frame(width: 60, height: 60)
            
            taskIconContent
        }
    }
    
    private var taskIconGradient: LinearGradient {
        if hasCraneRequirements {
            return LinearGradient(
                colors: [Color.ksrWarning, Color.ksrWarning.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.ksrPrimary, Color.ksrPrimary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    @ViewBuilder
    private var taskIconContent: some View {
        if hasCraneRequirements {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
        } else {
            Text(String(task.title.prefix(1)).uppercased())
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var statusIndicatorsRow: some View {
        HStack(spacing: 8) {
            // Deadline status
            if task.deadline != nil {
                StatusChip(
                    text: deadlineStatusText,
                    color: deadlineStatusColor,
                    icon: "calendar"
                )
            }
            
            // Crane indicator
            if hasCraneRequirements {
                StatusChip(
                    text: "Crane Required",
                    color: .ksrWarning,
                    icon: "wrench.and.screwdriver"
                )
            }
            
            // Work status
            if taskHours > 0 {
                StatusChip(
                    text: "Active",
                    color: .ksrSuccess,
                    icon: "clock"
                )
            }
            
            Spacer()
        }
    }
    
    private var quickStatsRow: some View {
        HStack(spacing: 20) {
            QuickStatItem(
                icon: "clock.fill",
                value: String(format: "%.1f", taskHours) + "h",
                label: "Hours Logged",
                color: taskHours > 0 ? .ksrSuccess : .ksrTextSecondary
            )
            
            if task.deadline != nil {
                QuickStatItem(
                    icon: "calendar",
                    value: daysUntilDeadline,
                    label: "Days Left",
                    color: deadlineStatusColor
                )
            }
            
            if let entries = workEntries {
                QuickStatItem(
                    icon: "list.bullet",
                    value: "\(entries.count)",
                    label: "Work Entries",
                    color: .ksrInfo
                )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Overview Section
    private var taskOverviewSection: some View {
        DetailSectionCard(
            section: .overview,
            isExpanded: expandedSections.contains(.overview),
            onToggle: { toggleSection(.overview) }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if let description = task.description, !description.isEmpty {
                    DetailInfoRow(
                        icon: "doc.text",
                        label: "Description",
                        content: .text(description)
                    )
                } else {
                    DetailInfoRow(
                        icon: "doc.text",
                        label: "Description",
                        content: .text("No description provided")
                    )
                }
                
                if let deadline = task.deadline {
                    DetailInfoRow(
                        icon: "calendar",
                        label: "Deadline",
                        content: .text(formatDate(deadline))
                    )
                }
                
                if let createdAt = task.created_at {
                    DetailInfoRow(
                        icon: "plus.circle",
                        label: "Created",
                        content: .text(formatDate(createdAt))
                    )
                }
            }
        }
    }
    
    // MARK: - Project Details Section
    private var projectDetailsSection: some View {
        DetailSectionCard(
            section: .project,
            isExpanded: expandedSections.contains(.project),
            onToggle: { toggleSection(.project) }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if let project = task.project {
                    DetailInfoRow(
                        icon: "building.2",
                        label: "Project Name",
                        content: .text(project.title)
                    )
                    
                    if let description = project.description, !description.isEmpty {
                        DetailInfoRow(
                            icon: "doc.text",
                            label: "Description",
                            content: .text(description)
                        )
                    }
                    
                    if let customer = project.customer {
                        DetailInfoRow(
                            icon: "person.2",
                            label: "Customer",
                            content: .text(customer.name)
                        )
                    }
                    
                    if let address = formatProjectAddress(project) {
                        DetailInfoRow(
                            icon: "location",
                            label: "Location",
                            content: .address(address)
                        )
                    }
                    
                    projectDatesRow(project)
                    
                    if let status = project.status {
                        DetailInfoRow(
                            icon: "flag",
                            label: "Status",
                            content: .status(status)
                        )
                    }
                } else {
                    Text("No project information available")
                        .foregroundColor(Color.ksrTextSecondary)
                        .italic()
                }
            }
        }
    }
    
    // MARK: - Equipment Requirements Section
    private var equipmentRequirementsSection: some View {
        DetailSectionCard(
            section: .equipment,
            isExpanded: expandedSections.contains(.equipment),
            onToggle: { toggleSection(.equipment) }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if let category = task.crane_category {
                    EquipmentCard(
                        title: "Category",
                        subtitle: category.name,
                        description: category.description,
                        icon: "tag",
                        color: .ksrInfo
                    )
                }
                
                if let brand = task.crane_brand {
                    EquipmentCard(
                        title: "Brand",
                        subtitle: brand.name,
                        description: brand.website,
                        icon: "building.2",
                        color: .ksrPrimary
                    )
                }
                
                if let model = task.preferred_crane_model {
                    CraneModelCard(model: model)
                }
                
                if !hasCraneRequirements {
                    Text("No specific equipment requirements")
                        .foregroundColor(Color.ksrTextSecondary)
                        .italic()
                }
            }
        }
    }
    
    // MARK: - Supervisor Section
    private var supervisorSection: some View {
        DetailSectionCard(
            section: .supervisor,
            isExpanded: expandedSections.contains(.supervisor),
            onToggle: { toggleSection(.supervisor) }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if let supervisorName = task.supervisor_name {
                    SupervisorContactCard(
                        name: supervisorName,
                        email: task.supervisor_email,
                        phone: task.supervisor_phone,
                        onContact: { showContactSupervisor = true }
                    )
                } else {
                    Text("No supervisor assigned")
                        .foregroundColor(Color.ksrTextSecondary)
                        .italic()
                }
            }
        }
    }
    
    // MARK: - Assignments Section
    private var assignmentsSection: some View {
        DetailSectionCard(
            section: .assignments,
            isExpanded: expandedSections.contains(.assignments),
            onToggle: { toggleSection(.assignments) }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if let assignments = task.assignments, !assignments.isEmpty {
                    ForEach(assignments, id: \.assignment_id) { assignment in
                        AssignmentCard(assignment: assignment)
                    }
                } else {
                    Text("No specific assignments")
                        .foregroundColor(Color.ksrTextSecondary)
                        .italic()
                }
            }
        }
    }
    
    // MARK: - Work History Section
    private var workHistorySection: some View {
        DetailSectionCard(
            section: .workHistory,
            isExpanded: expandedSections.contains(.workHistory),
            onToggle: { toggleSection(.workHistory) }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if let entries = workEntries, !entries.isEmpty {
                    ForEach(entries.prefix(5), id: \.entry_id) { entry in
                        WorkHistoryCard(entry: entry)
                    }
                    
                    if entries.count > 5 {
                        Button("View all \(entries.count) entries") {
                            // Navigate to full work history
                        }
                        .font(.subheadline)
                        .foregroundColor(.ksrPrimary)
                        .padding(.top, 8)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 32))
                            .foregroundColor(Color.ksrTextSecondary)
                        
                        Text("No work entries yet")
                            .foregroundColor(Color.ksrTextSecondary)
                            .italic()
                        
                        Text("Work entries will appear here when hours are logged")
                            .font(.caption)
                            .foregroundColor(Color.ksrTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        }
    }
    
    // MARK: - Toolbar
    private var toolbarButtons: some View {
        HStack(spacing: 12) {
            if let phone = task.supervisor_phone {
                Button {
                    if let url = URL(string: "tel:\(phone)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(systemName: "phone.fill")
                        .foregroundColor(Color.ksrSuccess)
                }
            }
            
            Button {
                showContactSupervisor = true
            } label: {
                Image(systemName: "person.circle")
                    .foregroundColor(Color.ksrPrimary)
            }
        }
    }
    
    // MARK: - Supervisor Contact Sheet
    private var supervisorContactSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.ksrInfo)
                    
                    VStack(spacing: 4) {
                        Text(task.supervisor_name ?? "Supervisor")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Project Supervisor")
                            .font(.subheadline)
                            .foregroundColor(Color.secondary)
                    }
                }
                
                // Contact options
                VStack(spacing: 12) {
                    if let email = task.supervisor_email {
                        ContactButton(
                            icon: "envelope.fill",
                            title: "Email",
                            subtitle: email,
                            color: Color.ksrInfo
                        ) {
                            if let url = URL(string: "mailto:\(email)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    
                    if let phone = task.supervisor_phone {
                        ContactButton(
                            icon: "phone.fill",
                            title: "Call",
                            subtitle: phone,
                            color: Color.ksrSuccess
                        ) {
                            if let url = URL(string: "tel:\(phone)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Contact Supervisor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showContactSupervisor = false
                    }
                }
            }
        }
        .presentationDetents([.height(400)])
    }
    
    // MARK: - Helper Methods
    
    private var hasCraneRequirements: Bool {
        return task.crane_category != nil ||
               task.crane_brand != nil ||
               task.preferred_crane_model != nil ||
               (task.assignments?.count ?? 0) > 0
    }
    
    private var taskHours: Double {
        guard let entries = workEntries else { return 0 }
        return entries.reduce(0.0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
    }
    
    private var workEntries: [WorkerAPIService.WorkHourEntry]? {
        return hoursViewModel.entries.filter { $0.task_id == task.task_id }
    }
    
    private var deadlineStatusText: String {
        guard let deadline = task.deadline else { return "No deadline" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        
        if days < 0 { return "Overdue" }
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        if days <= 7 { return "Due soon" }
        return "On track"
    }
    
    private var deadlineStatusColor: Color {
        guard let deadline = task.deadline else { return .ksrInfo }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        
        if days < 0 { return .red }
        if days <= 2 { return .ksrError }
        if days <= 7 { return .ksrWarning }
        return .ksrInfo
    }
    
    private var daysUntilDeadline: String {
        guard let deadline = task.deadline else { return "-" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        
        if days < 0 { return "\(abs(days))" }
        if days == 0 { return "Today" }
        return "\(days)"
    }
    
    private func shouldShowSection(_ section: DetailSection) -> Bool {
        switch section {
        case .overview:
            return true
        case .project:
            return task.project != nil
        case .equipment:
            return hasCraneRequirements
        case .supervisor:
            return task.supervisor_name != nil
        case .assignments:
            return task.assignments?.isEmpty == false
        case .workHistory:
            return true
        }
    }
    
    private func toggleSection(_ section: DetailSection) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
    
    private func loadWorkHistory() {
        hoursViewModel.loadEntries()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatProjectAddress(_ project: WorkerAPIService.Task.Project) -> String? {
        let components = [project.street, project.city, project.zip].compactMap { $0 }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
    
    private func projectDatesRow(_ project: WorkerAPIService.Task.Project) -> some View {
        HStack(spacing: 20) {
            if let startDate = project.start_date {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start Date")
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                    Text(formatDate(startDate))
                        .font(.subheadline)
                        .foregroundColor(Color.ksrTextPrimary)
                }
            }
            
            if let endDate = project.end_date {
                VStack(alignment: .leading, spacing: 2) {
                    Text("End Date")
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                    Text(formatDate(endDate))
                        .font(.subheadline)
                        .foregroundColor(Color.ksrTextPrimary)
                }
            }
            
            Spacer()
        }
    }
    
    private var dashboardBackground: some View {
        Color.backgroundGradient
            .ignoresSafeArea()
    }
}

// MARK: - Supporting Components

struct DetailSectionCard<Content: View>: View {
    let section: WorkerTaskDetailView.DetailSection
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: section.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(section.color)
                            .frame(width: 24)
                        
                        Text(section.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.ksrTextPrimary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.ksrTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(20)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 20)
                    
                    content
                        .padding(20)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                }
            }
        }
        .background(WorkerDashboardSections.cardBackground(colorScheme: colorScheme))
        .overlay(WorkerDashboardSections.cardStroke(section.color))
    }
}

struct StatusChip: View {
    let text: String
    let color: Color
    let icon: String?
    
    init(text: String, color: Color, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct QuickStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrTextPrimary)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.ksrTextSecondary)
        }
    }
}

struct DetailInfoRow: View {
    let icon: String
    let label: String
    let content: ContentType
    
    enum ContentType {
        case text(String)
        case address(String)
        case status(String)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.ksrInfo)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrTextSecondary)
                
                contentView
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch content {
        case .text(let text):
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.ksrTextPrimary)
        case .address(let address):
            Text(address)
                .font(.subheadline)
                .foregroundColor(Color.ksrInfo)
        case .status(let status):
            Text(status.capitalized)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.ksrSuccess)
        }
    }
}

struct EquipmentCard: View {
    let title: String
    let subtitle: String
    let description: String?
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrTextSecondary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.ksrTextPrimary)
                
                if let description = description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(Color.ksrTextSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.ksrLightGray)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CraneModelCard: View {
    let model: WorkerAPIService.Task.CraneModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gear")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.ksrSuccess)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Crane Model")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.ksrTextSecondary)
                    
                    Text(model.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrTextPrimary)
                }
                
                Spacer()
            }
            
            if let description = model.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.ksrTextSecondary)
            }
            
            // Specifications
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                if let capacity = model.maxLoadCapacity {
                    SpecificationItem(
                        label: "Max Load",
                        value: String(format: "%.1f", capacity) + " t",
                        icon: "scalemass"
                    )
                }
                
                if let height = model.maxHeight {
                    SpecificationItem(
                        label: "Max Height",
                        value: String(format: "%.1f", height) + " m",
                        icon: "arrow.up"
                    )
                }
                
                if let radius = model.maxRadius {
                    SpecificationItem(
                        label: "Max Radius",
                        value: String(format: "%.1f", radius) + " m",
                        icon: "arrow.left.and.right"
                    )
                }
                
                if let power = model.enginePower {
                    SpecificationItem(
                        label: "Engine Power",
                        value: "\(power) kW",
                        icon: "bolt"
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ksrSuccess.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.ksrSuccess.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SpecificationItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.ksrSuccess)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(Color.ksrTextSecondary)
            }
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.ksrTextPrimary)
        }
    }
}

struct SupervisorContactCard: View {
    let name: String
    let email: String?
    let phone: String?
    let onContact: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.ksrSuccess)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrTextPrimary)
                
                if let email = email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                }
                
                if let phone = phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                }
            }
            
            Spacer()
            
            Button(action: onContact) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.ksrSuccess)
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color.ksrLightGray)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AssignmentCard: View {
    let assignment: WorkerAPIService.Task.TaskAssignment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let assignedDate = assignment.assigned_at {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(Color.purple)
                    
                    Text("Assigned: \(formatAssignmentDate(assignedDate))")
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                    
                    Spacer()
                }
            }
            
            if let craneModel = assignment.assigned_crane_model {
                HStack {
                    Image(systemName: "gear")
                        .font(.caption)
                        .foregroundColor(Color.ksrWarning)
                    
                    Text("Crane: \(craneModel.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Color.ksrLightGray)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func formatAssignmentDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct WorkHistoryCard: View {
    let entry: WorkerAPIService.WorkHourEntry
    
    private var entryHours: Double {
        guard let start = entry.start_time, let end = entry.end_time else { return 0 }
        let interval = end.timeIntervalSince(start)
        let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
        return max(0, (interval - pauseSeconds) / 3600)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Circle()
                    .fill(entryStatusColor)
                    .frame(width: 8, height: 8)
                
                Rectangle()
                    .fill(entryStatusColor.opacity(0.3))
                    .frame(width: 2)
                    .layoutPriority(-1)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(formatWorkDate(entry.work_date))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f", entryHours) + "h")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrSuccess)
                }
                
                if let start = entry.start_time, let end = entry.end_time {
                    Text("\(formatTime(start)) - \(formatTime(end))")
                        .font(.caption)
                        .foregroundColor(Color.ksrTextSecondary)
                }
                
                if let description = entry.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(Color.ksrTextSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .background(Color.ksrLightGray)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var entryStatusColor: Color {
        if entry.confirmation_status == "confirmed" {
            return Color.ksrSuccess
        } else if entry.status == "submitted" {
            return Color.purple
        } else {
            return Color.ksrWarning
        }
    }
    
    private func formatWorkDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ContactButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.ksrTextPrimary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color.ksrTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.ksrTextSecondary)
            }
            .padding(16)
            .background(Color.ksrLightGray)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct WorkerTaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockTask = createMockTask()
        
        return Group {
            WorkerTaskDetailView(task: mockTask)
                .preferredColorScheme(.light)
            
            WorkerTaskDetailView(task: mockTask)
                .preferredColorScheme(.dark)
        }
    }
    
    static func createMockTask() -> WorkerAPIService.Task {
        let mockJSON = """
        {
            "task_id": 1,
            "title": "Tower Crane Installation",
            "description": "Install and configure tower crane for high-rise construction project. Ensure proper foundation setup and safety protocols.",
            "deadline": "2025-06-15T12:00:00Z",
            "created_at": "2025-06-01T10:00:00Z",
            "supervisor_id": 1,
            "supervisor_email": "john.supervisor@example.com",
            "supervisor_phone": "+1 234 567 8900",
            "supervisor_name": "John Supervisor",
            "required_crane_types": null,
            "preferred_crane_model_id": 1,
            "equipment_category_id": 1,
            "equipment_brand_id": 1,
            "crane_category": {
                "id": 1,
                "name": "Tower Cranes",
                "code": "TOWER",
                "description": "High-rise construction tower cranes",
                "iconUrl": null
            },
            "crane_brand": {
                "id": 1,
                "name": "Liebherr",
                "code": "LIE",
                "logoUrl": null,
                "website": "https://liebherr.com"
            },
            "preferred_crane_model": {
                "id": 1,
                "name": "280 EC-H 12",
                "code": "280ECH12",
                "description": "High-performance tower crane for urban construction",
                "maxLoadCapacity": 12.0,
                "maxHeight": 80.0,
                "maxRadius": 65.0,
                "enginePower": 45,
                "specifications": null,
                "imageUrl": null,
                "brochureUrl": null,
                "videoUrl": null
            },
            "project": {
                "project_id": 1,
                "title": "Downtown Business Center",
                "description": "Modern 40-story mixed-use development in city center",
                "start_date": "2025-05-01T00:00:00Z",
                "end_date": "2026-12-31T00:00:00Z",
                "street": "123 Business Ave",
                "city": "New York",
                "zip": "10001",
                "status": "active",
                "customer": {
                    "customer_id": 1,
                    "name": "Urban Development Corp"
                }
            },
            "assignments": [
                {
                    "assignment_id": 1,
                    "assigned_at": "2025-06-01T14:30:00Z",
                    "crane_model_id": 1,
                    "assigned_crane_model": {
                        "id": 1,
                        "name": "280 EC-H 12",
                        "code": "280ECH12"
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            return try decoder.decode(WorkerAPIService.Task.self, from: mockJSON)
        } catch {
            print("Failed to decode mock task: \(error)")
            fatalError("Failed to create mock task for preview")
        }
    }
}
