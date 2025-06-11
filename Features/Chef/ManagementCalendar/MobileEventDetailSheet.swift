import SwiftUI

struct MobileEventDetailSheet: View {
    let event: ManagementCalendarEvent
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    let onDismiss: () -> Void
    
    @State private var detailLevel: DetailLevel = .summary
    @State private var showingAssignWorker = false
    @State private var showingResolveConflict = false
    
    enum DetailLevel: String, CaseIterable {
        case summary = "Summary"
        case details = "Details"
        case actions = "Actions"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Detail Level Picker
                Picker("Detail Level", selection: $detailLevel) {
                    ForEach(DetailLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Always visible header
                        EventHeaderSection(event: event)
                        
                        // Content based on detail level
                        switch detailLevel {
                        case .summary:
                            EventSummaryContent(event: event)
                        case .details:
                            EventDetailsContent(event: event, viewModel: viewModel)
                        case .actions:
                            EventActionsContent(
                                event: event,
                                viewModel: viewModel,
                                showingAssignWorker: $showingAssignWorker,
                                showingResolveConflict: $showingResolveConflict
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onDismiss)
                }
            }
        }
        .sheet(isPresented: $showingAssignWorker) {
            // Assign worker sheet
            Text("Assign Worker Sheet")
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingResolveConflict) {
            // Resolve conflict sheet
            Text("Resolve Conflict Sheet")
                .presentationDetents([.large])
        }
    }
}

// MARK: - Header Section

struct EventHeaderSection: View {
    let event: ManagementCalendarEvent
    
    private var eventColor: Color {
        switch event.type {
        case .leave: return .orange
        case .project: return .blue
        case .task: return .green
        case .deadline: return .purple
        case .milestone: return .pink
        case .resource: return .gray
        case .maintenance: return .red
        case .workPlan: return .indigo
        }
    }
    
    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        let startDate = formatter.string(from: event.date)
        
        if let endDate = event.endDate {
            let endDateStr = formatter.string(from: endDate)
            return "\(startDate) - \(endDateStr)"
        }
        
        return startDate
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Event Type Icon
            ZStack {
                Circle()
                    .fill(eventColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: event.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(eventColor)
            }
            
            // Title & Type
            VStack(spacing: 8) {
                Text(event.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    EventTypeBadge(type: event.type)
                    
                    if event.priority != .medium {
                        EventPriorityBadge(priority: event.priority)
                    }
                    
                    if !event.conflicts.isEmpty {
                        ConflictBadge(count: event.conflicts.count)
                    }
                }
            }
            
            // Date
            Text(dateText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Summary Content

struct EventSummaryContent: View {
    let event: ManagementCalendarEvent
    
    var body: some View {
        VStack(spacing: 16) {
            // Description
            if !event.description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Description", systemImage: "text.alignleft")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(event.description)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            }
            
            // Quick Info Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickInfoCard(
                    icon: "clock",
                    label: "Duration",
                    value: formatDuration(event.duration)
                )
                
                QuickInfoCard(
                    icon: "flag",
                    label: "Status",
                    value: event.status.displayName
                )
                
                if event.resourceRequirements.count > 0 {
                    QuickInfoCard(
                        icon: "person.3",
                        label: "Resources",
                        value: "\(event.resourceRequirements.count) required"
                    )
                }
                
                if event.actionRequired {
                    QuickInfoCard(
                        icon: "exclamationmark.circle",
                        label: "Action",
                        value: "Required",
                        color: .orange
                    )
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "N/A" }
        
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

struct QuickInfoCard: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color.opacity(0.8))
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Details Content

struct EventDetailsContent: View {
    let event: ManagementCalendarEvent
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Resource Requirements
            if !event.resourceRequirements.isEmpty {
                ResourceRequirementsSection(requirements: event.resourceRequirements)
            }
            
            // Related Entities
            RelatedEntitiesSection(entities: event.relatedEntities, viewModel: viewModel)
            
            // Conflicts
            if !event.conflicts.isEmpty {
                ConflictsSection(conflicts: event.conflicts)
            }
            
            // Metadata
            MetadataSection(metadata: event.metadata)
        }
    }
}

struct ResourceRequirementsSection: View {
    let requirements: [ResourceRequirement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Resource Requirements", systemImage: "person.3.fill")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(requirements.indices, id: \.self) { index in
                    ResourceRequirementRow(requirement: requirements[index])
                }
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
        }
    }
}

struct ResourceRequirementRow: View {
    let requirement: ResourceRequirement
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(requirement.skillType ?? "Any Skill")
                    .font(.system(size: 14, weight: .medium))
                
                HStack(spacing: 12) {
                    Label("\(requirement.workerCount) workers", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let hours = requirement.estimatedHours {
                        Label("\(Int(hours))h", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if requirement.certificationRequired ?? false {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            }
        }
    }
}

struct RelatedEntitiesSection: View {
    let entities: RelatedEntities
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Related Items", systemImage: "link")
                .font(.headline)
            
            VStack(spacing: 8) {
                if let projectId = entities.projectId {
                    RelatedEntityRow(
                        type: "Project",
                        id: "\(projectId)",
                        icon: "folder"
                    )
                }
                
                if let taskId = entities.taskId {
                    RelatedEntityRow(
                        type: "Task",
                        id: "\(taskId)",
                        icon: "checklist"
                    )
                }
                
                if let workerId = entities.workerId {
                    RelatedEntityRow(
                        type: "Worker",
                        id: "\(workerId)",
                        icon: "person"
                    )
                }
                
                if let leaveRequestId = entities.leaveRequestId {
                    RelatedEntityRow(
                        type: "Leave Request",
                        id: "\(leaveRequestId)",
                        icon: "airplane"
                    )
                }
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
        }
    }
}

struct RelatedEntityRow: View {
    let type: String
    let id: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(type)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("#\(id)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

struct ConflictsSection: View {
    let conflicts: [ConflictInfo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Conflicts", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                ForEach(conflicts.indices, id: \.self) { index in
                    ConflictRow(conflict: conflicts[index])
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct ConflictRow: View {
    let conflict: ConflictInfo
    
    private var severityColor: Color {
        switch conflict.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(severityColor)
                    .frame(width: 8, height: 8)
                
                Text(conflict.conflictType.displayName)
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                Text(conflict.severity.displayName)
                    .font(.caption)
                    .foregroundColor(severityColor)
            }
            
            Text(conflict.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if let resolution = conflict.resolution {
                Text("Resolution: \(resolution)")
                    .font(.caption)
                    .foregroundColor(.green)
                    .italic()
            }
        }
    }
}

struct MetadataSection: View {
    let metadata: EventMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Additional Information", systemImage: "info.circle")
                .font(.headline)
            
            // Display metadata based on content
            // This is simplified - expand based on your EventMetadata structure
            Text("Metadata details...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
        }
    }
}

// MARK: - Actions Content

struct EventActionsContent: View {
    let event: ManagementCalendarEvent
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @Binding var showingAssignWorker: Bool
    @Binding var showingResolveConflict: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Primary Actions
            if event.type == .task || event.type == .project {
                EventActionButton(
                    title: "Assign Workers",
                    icon: "person.badge.plus",
                    color: .green,
                    action: { showingAssignWorker = true }
                )
            }
            
            if !event.conflicts.isEmpty {
                EventActionButton(
                    title: "Resolve Conflicts",
                    icon: "exclamationmark.triangle",
                    color: .orange,
                    action: { showingResolveConflict = true }
                )
            }
            
            // Secondary Actions
            VStack(spacing: 12) {
                SecondaryActionButton(
                    title: "Edit Event",
                    icon: "pencil",
                    action: { /* Edit action */ }
                )
                
                SecondaryActionButton(
                    title: "Duplicate Event",
                    icon: "doc.on.doc",
                    action: { /* Duplicate action */ }
                )
                
                SecondaryActionButton(
                    title: "Share Event",
                    icon: "square.and.arrow.up",
                    action: { /* Share action */ }
                )
                
                SecondaryActionButton(
                    title: "Delete Event",
                    icon: "trash",
                    color: .red,
                    action: { /* Delete action */ }
                )
            }
        }
    }
}

struct EventActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .cornerRadius(12)
        }
    }
}

struct SecondaryActionButton: View {
    let title: String
    let icon: String
    var color: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .foregroundColor(color)
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
        }
    }
}

// MARK: - Badge Components

struct EventPriorityBadge: View {
    let priority: EventPriority
    
    private var color: Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .gray
        }
    }
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

// MARK: - Extensions

// Note: CalendarEventType.icon is already defined in ChefManagementCalendarView.swift