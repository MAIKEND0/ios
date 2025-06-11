import SwiftUI

struct MobileTeamView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @State private var searchText = ""
    @State private var selectedWorker: WorkerAvailabilityRow?
    @State private var showingWorkerDetail = false
    
    private var filteredWorkers: [WorkerAvailabilityRow] {
        guard let matrix = viewModel.workerAvailabilityMatrix else { return [] }
        
        if searchText.isEmpty {
            return matrix.workers
        } else {
            return matrix.workers.filter { worker in
                worker.worker.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search Bar
                MobileSearchBar(searchText: $searchText)
                    .padding(.horizontal)
                
                // Team Overview Stats
                TeamOverviewStats(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Workers List
                VStack(spacing: 12) {
                    SectionHeader(title: "Team Members", icon: "person.3.fill")
                        .padding(.horizontal)
                    
                    if filteredWorkers.isEmpty {
                        EmptyTeamView()
                            .padding(.horizontal)
                    } else {
                        ForEach(filteredWorkers, id: \.id) { worker in
                            MobileWorkerCard(
                                worker: worker,
                                onTap: {
                                    selectedWorker = worker
                                    showingWorkerDetail = true
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 80) // Space for FAB
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedWorker) { worker in
            MobileWorkerDetailSheet(
                worker: worker,
                viewModel: viewModel,
                onDismiss: { selectedWorker = nil }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct MobileSearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            TextField("Search team members...", text: $searchText)
                .font(.system(size: 16))
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct TeamOverviewStats: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    private var summary: AvailabilitySummary? {
        viewModel.workerAvailabilityMatrix?.summary
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Team Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                TeamStatItem(
                    value: "\(summary?.totalWorkers ?? 0)",
                    label: "Total",
                    color: .blue,
                    icon: "person.3"
                )
                
                TeamStatItem(
                    value: "\(summary?.availableToday ?? 0)",
                    label: "Available",
                    color: .green,
                    icon: "checkmark.circle"
                )
                
                TeamStatItem(
                    value: "\(summary?.onLeaveToday ?? 0)",
                    label: "On Leave",
                    color: .orange,
                    icon: "airplane"
                )
                
                TeamStatItem(
                    value: String(format: "%.0f%%", (summary?.averageUtilization ?? 0) * 100),
                    label: "Utilization",
                    color: .purple,
                    icon: "chart.pie"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TeamStatItem: View {
    let value: String
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MobileWorkerCard: View {
    let worker: WorkerAvailabilityRow
    let onTap: () -> Void
    
    private var statusColor: Color {
        // Get today's availability status
        let today = Date()
        let todayAvailability = worker.getAvailability(for: today)
        
        switch todayAvailability?.status {
        case .available: return .green
        case .assigned, .partiallyBusy: return .orange
        case .onLeave: return .gray
        case .sick: return .red
        case .overloaded: return .red
        case .unavailable: return .gray
        default: return .gray
        }
    }
    
    private var statusText: String {
        // Get today's availability status
        let today = Date()
        let todayAvailability = worker.getAvailability(for: today)
        
        return todayAvailability?.status.displayName ?? "Unknown"
    }
    
    private var utilizationColor: Color {
        let utilization = worker.weeklyStats.utilization
        if utilization < 0.5 { return .green }
        else if utilization < 0.8 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(worker.worker.name.prefix(2))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                    )
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(worker.worker.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        // Status
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Utilization
                        HStack(spacing: 4) {
                            Text(String(format: "%.0f%%", worker.weeklyStats.utilization * 100))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(utilizationColor)
                            Text("utilized")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyTeamView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No team members found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try adjusting your search")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Worker Detail Sheet

struct MobileWorkerDetailSheet: View {
    let worker: WorkerAvailabilityRow
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Worker Header
                    WorkerDetailHeader(worker: worker)
                    
                    // Availability Summary
                    WorkerAvailabilitySummary(worker: worker)
                    
                    // Current Assignments
                    WorkerCurrentAssignments(worker: worker, viewModel: viewModel)
                    
                    // Skills & Certifications
                    WorkerSkillsSection(worker: worker)
                    
                    // Quick Actions
                    WorkerQuickActions(worker: worker, viewModel: viewModel)
                }
                .padding()
            }
            .navigationTitle("Worker Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }
}

struct WorkerDetailHeader: View {
    let worker: WorkerAvailabilityRow
    
    var body: some View {
        VStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(worker.worker.name.prefix(2))
                        .font(.system(size: 32, weight: .medium))
                )
            
            // Name & Role
            VStack(spacing: 4) {
                Text(worker.worker.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(worker.worker.role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WorkerAvailabilitySummary: View {
    let worker: WorkerAvailabilityRow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Availability Summary")
                .font(.headline)
            
            HStack(spacing: 20) {
                AvailabilityMetric(
                    label: "This Week",
                    value: "\(Int(worker.weeklyStats.totalHours))h",
                    color: .blue
                )
                
                AvailabilityMetric(
                    label: "Utilization",
                    value: String(format: "%.0f%%", worker.weeklyStats.utilization * 100),
                    color: worker.weeklyStats.utilization > 0.8 ? .red : .green
                )
                
                AvailabilityMetric(
                    label: "Projects",
                    value: "\(worker.weeklyStats.projectCount)",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct AvailabilityMetric: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WorkerCurrentAssignments: View {
    let worker: WorkerAvailabilityRow
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Assignments")
                .font(.headline)
            
            let todayAssignments = worker.getAvailability(for: Date())?.projects ?? []
            if todayAssignments.isEmpty {
                Text("No active assignments")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(todayAssignments.prefix(3), id: \.id) { project in
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text(project.projectName)
                                .font(.system(size: 14))
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
}

struct WorkerSkillsSection: View {
    let worker: WorkerAvailabilityRow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skills & Certifications")
                .font(.headline)
            
            if worker.worker.skills.isEmpty {
                Text("No skills listed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(worker.worker.skills, id: \.skillType) { skill in
                        Text(skill.skillType)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
}

struct WorkerQuickActions: View {
    let worker: WorkerAvailabilityRow
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Assign to task action
            }) {
                Label("Assign to Task", systemImage: "plus.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ksrPrimary)
                    .cornerRadius(12)
            }
            
            Button(action: {
                // View schedule action
            }) {
                Label("View Full Schedule", systemImage: "calendar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.ksrPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.ksrPrimary, lineWidth: 2)
                    )
            }
        }
        .padding(.top)
    }
}

// Simple Flow Layout for skills
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var height: CGFloat = 0
        
        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            height = y + rowHeight
        }
    }
}