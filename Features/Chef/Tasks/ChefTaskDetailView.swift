//
//  ChefTaskDetailView.swift
//  KSR Cranes App
//
//  Detailed task view with worker management for Chef role - ENHANCED WITH EQUIPMENT DISPLAY
//

import SwiftUI
import Combine

// MARK: - Task Detail View

struct ChefFullTaskDetailView: View {
    let task: ProjectTask
    
    @StateObject private var viewModel = ChefTaskDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: TaskDetailTab = .overview
    @State private var showEditTask = false
    @State private var showDeleteConfirmation = false
    
    // Computed property for current task (updated or original)
    private var currentTask: ProjectTask {
        viewModel.taskDetail?.task ?? task
    }
    
    enum TaskDetailTab: String, CaseIterable {
        case overview = "Overview"
        case equipment = "Equipment"  // ✅ ADDED: Equipment tab
        case workers = "Workers"
        case timeline = "Timeline"
        
        var icon: String {
            switch self {
            case .overview: return "doc.text.fill"
            case .equipment: return "wrench.and.screwdriver.fill"  // ✅ ADDED
            case .workers: return "person.3.fill"
            case .timeline: return "calendar"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Task Header
                taskHeader
                
                // Tab Selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    overviewTab.tag(TaskDetailTab.overview)
                    equipmentTab.tag(TaskDetailTab.equipment)  // ✅ ADDED: Equipment tab
                    workersTab.tag(TaskDetailTab.workers)
                    timelineTab.tag(TaskDetailTab.timeline)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(backgroundGradient)
            .navigationTitle(currentTask.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showEditTask = true
                        } label: {
                            Label("Edit Task", systemImage: "pencil")
                        }
                        
                        Button {
                            viewModel.showWorkerPicker = true
                        } label: {
                            Label("Manage Workers", systemImage: "person.3.fill")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Task", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.ksrYellow)
                    }
                }
            }
            .sheet(isPresented: $showEditTask) {
                ChefEditTaskView(task: currentTask) { updatedTask in
                    viewModel.updateLocalTask(updatedTask)
                }
            }
            .sheet(isPresented: $viewModel.showWorkerPicker, onDismiss: {
                if !viewModel.selectedWorkersToAdd.isEmpty {
                    viewModel.assignSelectedWorkers()
                }
            }) {
                ChefWorkerPickerView(
                    selectedWorkers: $viewModel.selectedWorkersToAdd,
                    projectId: task.projectId,
                    excludeTaskId: task.id,
                    requiredCraneTypes: nil,  // Don't use crane types - use certificates instead
                    requiredCertificates: task.requiredCertificates  // ✅ NEW: Pass certificate requirements
                )
            }
            .confirmationDialog(
                "Delete Task",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteTask()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete the task and remove all worker assignments. This action cannot be undone.")
            }
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $viewModel.showSuccess) {
                Alert(
                    title: Text("Success"),
                    message: Text(viewModel.successMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                #if DEBUG
                print("[ChefFullTaskDetailView] 🔄 Loading task detail for: \(task.title) (ID: \(task.id))")
                #endif
                viewModel.loadTaskDetail(taskId: task.id)
                viewModel.loadEquipmentDetails(for: task)  // ✅ ADDED: Load equipment details
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
    
    private var taskHeader: some View {
        VStack(spacing: 16) {
            // Task Status and Project Info
            HStack {
                let projectTitle = viewModel.taskDetail?.project.title ?? "Project \(task.projectId)"
                
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.ksrInfo)
                    
                    Text(projectTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.ksrInfo.opacity(0.1))
                )
                
                Spacer()
                
                TaskStatusBadge(isActive: task.isActive)
            }
            
            // Task Description
            if let description = task.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // ✅ ENHANCED: Equipment Summary in Header
            if hasEquipmentRequirements {
                equipmentSummaryCard
            }
            
            // Task Deadline and Supervisor
            HStack(spacing: 16) {
                if let deadline = currentTask.deadline {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(.ksrWarning)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Deadline")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(deadline, style: .date)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
                
                if let supervisorName = currentTask.supervisorName {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.shield.checkmark")
                            .foregroundColor(.ksrSuccess)
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Supervisor")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(supervisorName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
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
    
    // ✅ ADDED: Equipment summary card for header
    private var equipmentSummaryCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.title3)
                .foregroundColor(.ksrWarning)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.ksrWarning.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Equipment Requirements")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(getEquipmentSummaryText())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button {
                selectedTab = .equipment
            } label: {
                Text("Details")
                    .font(.caption)
                    .foregroundColor(.ksrWarning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.ksrWarning.opacity(0.1))
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ksrWarning.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.ksrWarning.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var hasEquipmentRequirements: Bool {
        return currentTask.requiredCraneTypes?.isEmpty == false ||
               currentTask.preferredCraneModelId != nil ||
               currentTask.equipmentCategoryId != nil ||
               currentTask.equipmentBrandId != nil
    }
    
    private func getEquipmentSummaryText() -> String {
        var components: [String] = []
        
        if let craneTypes = task.requiredCraneTypes, !craneTypes.isEmpty {
            components.append("\(craneTypes.count) crane type\(craneTypes.count == 1 ? "" : "s")")
        }
        
        if task.preferredCraneModelId != nil {
            components.append("specific model")
        }
        
        if task.equipmentCategoryId != nil {
            components.append("category specified")
        }
        
        if task.equipmentBrandId != nil {
            components.append("brand specified")
        }
        
        return components.isEmpty ? "No requirements" : components.joined(separator: ", ")
    }
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskDetailTab.allCases, id: \.self) { tab in
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
                taskStatistics
                managementCalendarInfo    // ✅ NEW: Management calendar information
                certificateRequirementsInfo  // ✅ NEW: Certificate requirements
                supervisorDetails
                quickActions
            }
            .padding()
        }
    }
    
    // ✅ ADDED: Equipment Tab
    private var equipmentTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                equipmentRequirementsSection
                assignedEquipmentSection
                equipmentCompatibilitySection
            }
            .padding()
        }
    }
    
    private var workersTab: some View {
        VStack(spacing: 0) {
            // Workers Header
            HStack {
                Text("Assigned Workers")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !viewModel.assignments.isEmpty {
                    Text("\(viewModel.assignments.count) assigned")
                        .font(.caption)
                        .foregroundColor(.ksrSuccess)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.ksrSuccess.opacity(0.1))
                        )
                }
                
                Button {
                    viewModel.showWorkerPicker = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.title2)
                        .foregroundColor(.ksrYellow)
                }
                .disabled(viewModel.isAssigningWorkers)
            }
            .padding()
            
            if viewModel.isAssigningWorkers {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Assigning workers...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            if viewModel.isLoading {
                ProgressView("Loading workers...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.assignments.isEmpty {
                emptyWorkersView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.assignments, id: \.assignment.id) { assignmentDetail in
                            FixedWorkerAssignmentCard(
                                assignmentDetail: assignmentDetail,
                                onRemove: {
                                    #if DEBUG
                                    print("[ChefTaskDetailView] 🗑️ Removing worker: \(assignmentDetail.employee.name)")
                                    #endif
                                    viewModel.removeWorkerAssignmentWithConfirmation(
                                        assignmentDetail.assignment.id,
                                        workerName: assignmentDetail.employee.name
                                    )
                                },
                                onEditCrane: { newCraneId in
                                    #if DEBUG
                                    print("[ChefTaskDetailView] 🔧 Updating crane for: \(assignmentDetail.employee.name)")
                                    #endif
                                    viewModel.updateWorkerCrane(
                                        assignmentId: assignmentDetail.assignment.id,
                                        craneModelId: newCraneId
                                    )
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var timelineTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Task Timeline")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Coming soon - task timeline and activity history")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }
    
    // MARK: - ✅ ADDED: Equipment Sections
    
    private var equipmentRequirementsSection: some View {
        TaskEquipmentSection(title: "Equipment Requirements", icon: "list.bullet.clipboard") {
            VStack(spacing: 16) {
                if let categoryId = task.equipmentCategoryId {
                    EquipmentRequirementRow(
                        icon: "folder.fill",
                        label: "Category",
                        value: viewModel.equipmentDetails.categoryName ?? "Category ID: \(categoryId)",
                        color: .ksrInfo
                    )
                }
                
                if let craneTypes = task.requiredCraneTypes, !craneTypes.isEmpty {
                    EquipmentRequirementRow(
                        icon: "wrench.and.screwdriver.fill",
                        label: "Required Types",
                        value: "\(craneTypes.count) crane type\(craneTypes.count == 1 ? "" : "s")",
                        color: .ksrWarning
                    )
                    
                    // Show individual crane types if loaded
                    ForEach(viewModel.equipmentDetails.craneTypes, id: \.id) { craneType in
                        HStack {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(craneType.name)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Text("(\(craneType.code))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.leading, 20)
                    }
                }
                
                if let brandId = task.equipmentBrandId {
                    EquipmentRequirementRow(
                        icon: "building.2.fill",
                        label: "Brand",
                        value: viewModel.equipmentDetails.brandName ?? "Brand ID: \(brandId)",
                        color: .ksrSecondary
                    )
                }
                
                if let modelId = task.preferredCraneModelId {
                    EquipmentRequirementRow(
                        icon: "wrench.adjustable",
                        label: "Preferred Model",
                        value: viewModel.equipmentDetails.modelName ?? "Model ID: \(modelId)",
                        color: .ksrSuccess
                    )
                }
                
                if !hasEquipmentRequirements {
                    Text("No specific equipment requirements")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            }
        }
    }
    
    private var assignedEquipmentSection: some View {
        TaskEquipmentSection(title: "Assigned Equipment", icon: "checkmark.circle.fill") {
            VStack(spacing: 12) {
                if viewModel.assignments.isEmpty {
                    Text("No workers assigned yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(viewModel.assignments, id: \.assignment.id) { assignmentDetail in
                        AssignedEquipmentRow(
                            workerName: assignmentDetail.employee.name,
                            craneModel: assignmentDetail.craneModel
                        )
                    }
                }
            }
        }
    }
    
    private var equipmentCompatibilitySection: some View {
        TaskEquipmentSection(title: "Compatibility Check", icon: "checkmark.shield.fill") {
            VStack(spacing: 12) {
                if let requiredTypes = task.requiredCraneTypes, !requiredTypes.isEmpty, !viewModel.assignments.isEmpty {
                    ForEach(viewModel.assignments, id: \.assignment.id) { assignmentDetail in
                        WorkerCompatibilityRow(
                            assignmentDetail: assignmentDetail,
                            requiredCraneTypes: requiredTypes
                        )
                    }
                } else {
                    Text("No compatibility requirements to check")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            }
        }
    }
    
    // MARK: - Overview Components (existing)
    
    private var taskStatistics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                TaskStatCard(
                    title: "Workers",
                    value: "\(viewModel.assignments.count)",
                    icon: "person.3.fill",
                    color: .ksrSuccess
                )
                
                TaskStatCard(
                    title: "Status",
                    value: task.isActive ? "Active" : "Inactive",
                    icon: task.isActive ? "checkmark.circle.fill" : "pause.circle.fill",
                    color: task.isActive ? .ksrSuccess : .ksrWarning
                )
                
                if let deadline = task.deadline {
                    TaskStatCard(
                        title: "Days Left",
                        value: "\(Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0)",
                        icon: "calendar.badge.clock",
                        color: .ksrInfo
                    )
                }
                
                let projectStatus = viewModel.taskDetail?.project.status.displayName ?? "Unknown"
                TaskStatCard(
                    title: "Project",
                    value: projectStatus,
                    icon: "folder.fill",
                    color: .ksrInfo
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
    
    // ✅ NEW: Management Calendar Info Section
    private var managementCalendarInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Scheduling & Resource Info")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Task Status
                if let status = currentTask.status {
                    TaskStatCard(
                        title: "Status",
                        value: status.displayName,
                        icon: status.icon,
                        color: status.color
                    )
                }
                
                // Task Priority
                if let priority = currentTask.priority {
                    TaskStatCard(
                        title: "Priority",
                        value: priority.displayName,
                        icon: priority.icon,
                        color: priority.color
                    )
                }
                
                // Start Date
                if let startDate = currentTask.startDate {
                    TaskStatCard(
                        title: "Start Date",
                        value: {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateStyle = .short
                            return dateFormatter.string(from: startDate)
                        }(),
                        icon: "calendar.badge.plus",
                        color: .ksrInfo
                    )
                }
                
                // Estimated Hours
                if let estimatedHours = currentTask.estimatedHours {
                    TaskStatCard(
                        title: "Est. Hours",
                        value: String(format: "%.1f h", estimatedHours),
                        icon: "clock.fill",
                        color: .ksrWarning
                    )
                }
                
                // Required Operators
                if let requiredOperators = currentTask.requiredOperators {
                    TaskStatCard(
                        title: "Operators Needed",
                        value: "\(requiredOperators)",
                        icon: "person.3.fill",
                        color: .ksrSuccess
                    )
                }
            }
            
            // Client Equipment Info
            if let clientEquipmentInfo = currentTask.clientEquipmentInfo, !clientEquipmentInfo.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Client Equipment Information")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(clientEquipmentInfo)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
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
    
    // ✅ NEW: Certificate Requirements Info
    private var certificateRequirementsInfo: some View {
        Group {
            if let requiredCertificates = task.requiredCertificates, !requiredCertificates.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundColor(.ksrInfo)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.ksrInfo.opacity(0.1))
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Certificate Requirements")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("\(requiredCertificates.count) certificate(s) required")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Certificate list
                    VStack(spacing: 8) {
                        ForEach(requiredCertificates, id: \.self) { certificateId in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal")
                                    .font(.body)
                                    .foregroundColor(.ksrInfo)
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle()
                                            .fill(Color.ksrInfo.opacity(0.1))
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    // In a real implementation, we would fetch certificate details
                                    Text("Certificate ID: \(certificateId)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text("Required for this task")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.ksrLightGray.opacity(0.1))
                            )
                        }
                    }
                    
                    // Warning about worker assignment
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.ksrWarning)
                        
                        Text("Only workers with these certificates can be assigned to this task")
                            .font(.caption)
                            .foregroundColor(.ksrWarning)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.ksrWarning.opacity(0.1))
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
            }
        }
    }
    
    private var supervisorDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Supervisor Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let supervisorName = task.supervisorName {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "person.badge.shield.checkmark")
                            .font(.title2)
                            .foregroundColor(.ksrSuccess)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(supervisorName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if let email = task.supervisorEmail {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let phone = task.supervisorPhone {
                                Text(phone)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        if let email = task.supervisorEmail {
                            Button {
                                if let url = URL(string: "mailto:\(email)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label("Email", systemImage: "envelope.fill")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.ksrInfo.opacity(0.1))
                                    .foregroundColor(.ksrInfo)
                                    .cornerRadius(12)
                            }
                        }
                        
                        if let phone = task.supervisorPhone {
                            Button {
                                if let url = URL(string: "tel:\(phone)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label("Call", systemImage: "phone.fill")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.ksrSuccess.opacity(0.1))
                                    .foregroundColor(.ksrSuccess)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Spacer()
                    }
                }
            } else {
                Text("No supervisor assigned")
                    .font(.body)
                    .foregroundColor(.secondary)
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
                TaskQuickActionButton(
                    icon: "person.badge.plus",
                    title: "Manage Workers",
                    subtitle: "Add or remove worker assignments",
                    color: .ksrYellow,
                    action: {
                        viewModel.showWorkerPicker = true
                    }
                )
                .disabled(viewModel.isAssigningWorkers)
                
                TaskQuickActionButton(
                    icon: "pencil.circle.fill",
                    title: "Edit Task",
                    subtitle: "Update task details and deadline",
                    color: .ksrInfo,
                    action: {
                        showEditTask = true
                    }
                )
                
                TaskQuickActionButton(
                    icon: task.isActive ? "pause.circle.fill" : "play.circle.fill",
                    title: task.isActive ? "Pause Task" : "Activate Task",
                    subtitle: task.isActive ? "Temporarily pause this task" : "Resume this task",
                    color: task.isActive ? .ksrWarning : .ksrSuccess,
                    action: {
                        viewModel.toggleTaskStatus()
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
    
    private var emptyWorkersView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.ksrYellow.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Workers Assigned")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Assign workers to get started with this task")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel.showWorkerPicker = true
            } label: {
                Label("Assign Workers", systemImage: "person.badge.plus")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.ksrYellow)
                    .cornerRadius(25)
            }
            .disabled(viewModel.isAssigningWorkers)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func deleteTask() {
        #if DEBUG
        print("[ChefFullTaskDetailView] 🗑️ Deleting task: \(task.title)")
        #endif
        
        viewModel.deleteTask {
            dismiss()
        }
    }
}

// MARK: - ✅ ADDED: Equipment Components

struct TaskEquipmentSection<Content: View>: View {
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
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.ksrYellow)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 4)
            
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

struct EquipmentRequirementRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AssignedEquipmentRow: View {
    let workerName: String
    let craneModel: CraneModel?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.ksrSecondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(workerName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Group {
                    if let crane = craneModel {
                        Text(crane.name)
                            .font(.caption)
                            .foregroundColor(.ksrSuccess)
                    } else {
                        Text("No crane assigned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if craneModel != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.ksrSuccess)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.ksrWarning)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

struct WorkerCompatibilityRow: View {
    let assignmentDetail: TaskAssignmentDetail
    let requiredCraneTypes: [Int]
    
    private var isCompatible: Bool {
        // Check if worker has skills for any of the required crane types
        let workerTypeIds = Set(assignmentDetail.employee.craneTypes?.map { $0.craneTypeId } ?? [])
        let requiredTypeIds = Set(requiredCraneTypes)
        return !workerTypeIds.intersection(requiredTypeIds).isEmpty
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.ksrSecondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(assignmentDetail.employee.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if isCompatible {
                    Text("Compatible with task requirements")
                        .font(.caption)
                        .foregroundColor(.ksrSuccess)
                } else {
                    Text("Missing required crane skills")
                        .font(.caption)
                        .foregroundColor(.ksrError)
                }
            }
            
            Spacer()
            
            Image(systemName: isCompatible ? "checkmark.shield.fill" : "xmark.shield.fill")
                .font(.system(size: 16))
                .foregroundColor(isCompatible ? .ksrSuccess : .ksrError)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCompatible ? Color.ksrSuccess.opacity(0.1) : Color.ksrError.opacity(0.1))
        )
    }
}

// MARK: - Enhanced Task Detail ViewModel with Equipment Support

class ChefTaskDetailViewModel: ObservableObject {
    @Published var taskDetail: ChefTaskDetail?
    @Published var assignments: [TaskAssignmentDetail] = []
    @Published var availableWorkers: [AvailableWorker] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    @Published var selectedWorkersToAdd: [AvailableWorker] = []
    @Published var showWorkerPicker = false
    @Published var isAssigningWorkers = false
    @Published var showSuccess = false
    @Published var successMessage = ""
    
    // ✅ ADDED: Equipment details
    @Published var equipmentDetails = TaskEquipmentDetails()
    @Published var isLoadingEquipment = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // ✅ FIXED: Error type alias for consistency
    typealias APIError = ChefProjectsAPIService.APIError
    
    func loadTaskDetail(taskId: Int) {
        isLoading = true
        
        #if DEBUG
        print("[ChefTaskDetailViewModel] 🔄 Loading task detail for ID: \(taskId)")
        #endif
        
        ChefProjectsAPIService.shared.makeRequest(
            endpoint: "/api/app/chef/tasks/\(taskId)?include_project=true&include_assignments=true&include_workers=true&include_conversation=true",
            method: "GET",
            body: Optional<String>.none
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    #if DEBUG
                    print("❌ [ChefTaskDetailViewModel] API Error: \(error)")
                    #endif
                    self?.showError("Failed to load task details: \(error.localizedDescription)")
                case .finished:
                    #if DEBUG
                    print("✅ [ChefTaskDetailViewModel] API call completed successfully")
                    #endif
                }
            },
            receiveValue: { [weak self] data in
                #if DEBUG
                print("🔍 [ChefTaskDetailViewModel] Raw API Response:")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print(jsonString.prefix(500))
                }
                print("🔍 [ChefTaskDetailViewModel] Response size: \(data.count) bytes")
                #endif
                
                self?.parseTaskDetailResponse(data)
            }
        )
        .store(in: &cancellables)
    }
    
    // ✅ FIXED: Load equipment details with proper error type mapping
    func loadEquipmentDetails(for task: ProjectTask) {
        guard task.requiredCraneTypes?.isEmpty == false ||
              task.equipmentCategoryId != nil ||
              task.equipmentBrandId != nil ||
              task.preferredCraneModelId != nil else {
            #if DEBUG
            print("[ChefTaskDetailViewModel] ⏭️ No equipment requirements to load")
            #endif
            return
        }
        
        isLoadingEquipment = true
        
        #if DEBUG
        print("[ChefTaskDetailViewModel] 🔄 Loading equipment details for task")
        print("   - Category ID: \(task.equipmentCategoryId?.description ?? "none")")
        print("   - Required Types: \(task.requiredCraneTypes?.description ?? "none")")
        print("   - Brand ID: \(task.equipmentBrandId?.description ?? "none")")
        print("   - Model ID: \(task.preferredCraneModelId?.description ?? "none")")
        #endif
        
        // Load equipment hierarchy data
        var publishers: [AnyPublisher<Void, APIError>] = []
        
        // Load category if specified
        if let categoryId = task.equipmentCategoryId {
            let categoryPublisher = EquipmentAPIService.shared.fetchCraneCategories()
                .mapError { APIError.decodingError($0) } // ✅ FIXED: Map error type
                .map { [weak self] categories in
                    if let category = categories.first(where: { $0.id == categoryId }) {
                        self?.equipmentDetails.categoryName = category.name
                    }
                    return ()
                }
                .eraseToAnyPublisher()
            publishers.append(categoryPublisher)
        }
        
        // Load crane types if specified
        if let requiredTypes = task.requiredCraneTypes, !requiredTypes.isEmpty {
            let typesPublisher = EquipmentAPIService.shared.fetchCraneTypes()
                .mapError { APIError.decodingError($0) } // ✅ FIXED: Map error type
                .map { [weak self] allTypes in
                    self?.equipmentDetails.craneTypes = allTypes.filter { type in
                        requiredTypes.contains(type.id)
                    }
                    return ()
                }
                .eraseToAnyPublisher()
            publishers.append(typesPublisher)
        }
        
        // Load brand if specified
        if let brandId = task.equipmentBrandId {
            let brandPublisher = EquipmentAPIService.shared.fetchCraneBrands()
                .mapError { APIError.decodingError($0) } // ✅ FIXED: Map error type
                .map { [weak self] brands in
                    if let brand = brands.first(where: { $0.id == brandId }) {
                        self?.equipmentDetails.brandName = brand.name
                    }
                    return ()
                }
                .eraseToAnyPublisher()
            publishers.append(brandPublisher)
        }
        
        // Load model if specified
        if let modelId = task.preferredCraneModelId {
            let modelPublisher = EquipmentAPIService.shared.fetchCraneModels()
                .mapError { APIError.decodingError($0) } // ✅ FIXED: Map error type
                .map { [weak self] models in
                    if let model = models.first(where: { $0.id == modelId }) {
                        self?.equipmentDetails.modelName = model.name
                    }
                    return ()
                }
                .eraseToAnyPublisher()
            publishers.append(modelPublisher)
        }
        
        // Execute all publishers
        if !publishers.isEmpty {
            Publishers.MergeMany(publishers)
                .collect()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoadingEquipment = false
                        if case .failure(let error) = completion {
                            #if DEBUG
                            print("❌ [ChefTaskDetailViewModel] Failed to load equipment details: \(error)")
                            #endif
                        } else {
                            #if DEBUG
                            print("✅ [ChefTaskDetailViewModel] Equipment details loaded successfully")
                            #endif
                        }
                    },
                    receiveValue: { _ in
                        #if DEBUG
                        print("✅ [ChefTaskDetailViewModel] All equipment details loaded")
                        #endif
                    }
                )
                .store(in: &cancellables)
        } else {
            isLoadingEquipment = false
        }
    }
    
    private func parseTaskDetailResponse(_ data: Data) {
        do {
            let decoder = ChefProjectsAPIService.shared.jsonDecoder()
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            #if DEBUG
            print("🔍 [ChefTaskDetailViewModel] JSON Keys: \(json?.keys.sorted() ?? [])")
            #endif
            
            guard let json = json else {
                showError("Invalid JSON response")
                return
            }
            
            var taskData = json
            let projectsData = taskData.removeValue(forKey: "Projects")
            let taskAssignmentsData = taskData.removeValue(forKey: "TaskAssignments")
            _ = taskData.removeValue(forKey: "Employees") // ✅ FIXED: Use _ assignment
            let conversationData = taskData.removeValue(forKey: "conversation")
            _ = taskData.removeValue(forKey: "statistics") // ✅ FIXED: Use _ assignment
            
            let taskJSON = try JSONSerialization.data(withJSONObject: taskData)
            let task = try decoder.decode(ProjectTask.self, from: taskJSON)
            
            #if DEBUG
            print("✅ [ChefTaskDetailViewModel] Successfully parsed task: \(task.title)")
            #endif
            
            var project: Project
            if let projectData = projectsData as? [String: Any] {
                let projectJSON = try JSONSerialization.data(withJSONObject: projectData)
                project = try decoder.decode(Project.self, from: projectJSON)
                #if DEBUG
                print("✅ [ChefTaskDetailViewModel] Successfully parsed project: \(project.title)")
                #endif
            } else {
                project = Project(
                    id: task.projectId,
                    title: "Unknown Project",
                    description: nil,
                    startDate: nil,
                    endDate: nil,
                    status: .active,
                    customerId: nil,
                    customer: nil,
                    street: nil,
                    city: nil,
                    zip: nil,
                    isActive: true,
                    createdAt: nil
                )
                #if DEBUG
                print("⚠️ [ChefTaskDetailViewModel] Using fallback project")
                #endif
            }
            
            var assignments: [TaskAssignmentDetail] = []
            if let assignmentsArray = taskAssignmentsData as? [[String: Any]] {
                for assignmentData in assignmentsArray {
                    do {
                        let assignmentJSON = try JSONSerialization.data(withJSONObject: assignmentData)
                        let rawAssignment = try decoder.decode(RawTaskAssignment.self, from: assignmentJSON)
                        
                        let assignmentDetail = TaskAssignmentDetail(
                            assignment: TaskAssignment(
                                id: rawAssignment.assignment_id,
                                taskId: rawAssignment.task_id,
                                employeeId: rawAssignment.employee_id,
                                assignedAt: rawAssignment.assigned_at,
                                craneModelId: rawAssignment.crane_model_id,
                                workDate: rawAssignment.work_date,
                                status: rawAssignment.status,
                                notes: rawAssignment.notes,
                                employee: rawAssignment.Employees,
                                craneModel: rawAssignment.CraneModel
                            ),
                            employee: rawAssignment.Employees,
                            craneModel: rawAssignment.CraneModel,
                            availability: nil
                        )
                        assignments.append(assignmentDetail)
                    } catch {
                        #if DEBUG
                        print("⚠️ [ChefTaskDetailViewModel] Failed to parse assignment: \(error)")
                        #endif
                    }
                }
                #if DEBUG
                print("✅ [ChefTaskDetailViewModel] Successfully parsed \(assignments.count) assignments")
                #endif
            }
            
            var conversation: ConversationInfo?
            if let conversationData = conversationData as? [String: Any] {
                do {
                    let conversationJSON = try JSONSerialization.data(withJSONObject: conversationData)
                    conversation = try decoder.decode(ConversationInfo.self, from: conversationJSON)
                    #if DEBUG
                    print("✅ [ChefTaskDetailViewModel] Successfully parsed conversation")
                    #endif
                } catch {
                    #if DEBUG
                    print("⚠️ [ChefTaskDetailViewModel] Failed to parse conversation: \(error)")
                    #endif
                }
            }
            
            let taskDetail = ChefTaskDetail(
                task: task,
                project: project,
                assignments: assignments,
                conversation: conversation
            )
            
            self.taskDetail = taskDetail
            self.assignments = assignments
            
            #if DEBUG
            print("🎉 [ChefTaskDetailViewModel] Successfully created ChefTaskDetail")
            print("   - Task: \(task.title)")
            print("   - Project: \(project.title)")
            print("   - Assignments: \(assignments.count)")
            print("   - Conversation: \(conversation != nil ? "Yes" : "No")")
            #endif
            
        } catch {
            #if DEBUG
            print("❌ [ChefTaskDetailViewModel] Parsing error: \(error)")
            #endif
            showError("Failed to parse task details: \(error.localizedDescription)")
        }
    }
    
    func assignSelectedWorkers() {
        guard !selectedWorkersToAdd.isEmpty,
              let task = taskDetail?.task else {
            #if DEBUG
            print("⚠️ [ChefTaskDetailViewModel] No workers selected or task not available")
            #endif
            return
        }
        
        isAssigningWorkers = true
        
        #if DEBUG
        print("[ChefTaskDetailViewModel] 👥 Assigning \(selectedWorkersToAdd.count) workers to task \(task.id)")
        print("   Task required certificates: \(task.requiredCertificates ?? [])")
        selectedWorkersToAdd.forEach { worker in
            print("   - \(worker.employee.name) (ID: \(worker.employee.employeeId))")
            print("     • Has required certificates: \(worker.hasRequiredCertificates ?? false)")
            if let validation = worker.certificateValidation {
                print("     • Required: \(validation.requiredCount), Valid: \(validation.validCount)")
                if !validation.missingCertificates.isEmpty {
                    print("     • Missing certificates: \(validation.missingCertificates)")
                }
            }
            if let certificates = worker.certificates {
                print("     • Worker certificates: \(certificates.map { $0.certificateTypeId ?? -1 })")
            }
        }
        #endif
        
        let assignments = selectedWorkersToAdd.map { worker in
            // Check if worker has required certificates
            let hasRequiredCerts = worker.hasRequiredCertificates ?? true
            
            // If worker doesn't have required certificates but is being assigned anyway,
            // we need to tell the server to skip validation
            let shouldSkipCertValidation = !hasRequiredCerts
            
            #if DEBUG
            if shouldSkipCertValidation {
                print("     ⚠️ Worker \(worker.employee.name) missing certificates, will skip validation")
            }
            #endif
            
            return CreateTaskAssignmentRequest(
                employeeId: worker.employee.employeeId,
                craneModelId: worker.craneTypes.first?.id,
                skipCertificateValidation: shouldSkipCertValidation,
                skipCraneTypeValidation: false, // Always validate crane types
                workDate: nil,
                status: nil,
                notes: nil
            )
        }
        
        // Check if any workers are missing certificates
        let workersWithMissingCerts = selectedWorkersToAdd.filter { worker in
            worker.hasRequiredCertificates == false
        }
        
        if !workersWithMissingCerts.isEmpty {
            #if DEBUG
            print("⚠️ [ChefTaskDetailViewModel] \(workersWithMissingCerts.count) workers missing required certificates")
            #endif
        }
        
        ChefProjectsAPIService.shared.assignWorkersToTask(
            taskId: task.id,
            assignments: assignments
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isAssigningWorkers = false
                
                switch completion {
                case .failure(let error):
                    #if DEBUG
                    print("❌ [ChefTaskDetailViewModel] Failed to assign workers: \(error)")
                    #endif
                    self?.showError("Failed to assign workers: \(error.localizedDescription)")
                    
                case .finished:
                    #if DEBUG
                    print("✅ [ChefTaskDetailViewModel] Worker assignment completed")
                    #endif
                }
            },
            receiveValue: { [weak self] newAssignments in
                #if DEBUG
                print("✅ [ChefTaskDetailViewModel] Received \(newAssignments.count) new assignments")
                newAssignments.forEach { assignment in
                    print("   - Assignment ID: \(assignment.id) for Employee ID: \(assignment.employeeId)")
                }
                #endif
                
                let newAssignmentDetails = newAssignments.compactMap { assignment -> TaskAssignmentDetail? in
                    guard let selectedWorker = self?.selectedWorkersToAdd.first(where: {
                        $0.employee.employeeId == assignment.employeeId
                    }) else {
                        #if DEBUG
                        print("⚠️ [ChefTaskDetailViewModel] Could not find selected worker for assignment \(assignment.id)")
                        #endif
                        return nil
                    }
                    
                    return TaskAssignmentDetail(
                        assignment: assignment,
                        employee: selectedWorker.employee,
                        craneModel: assignment.craneModel,
                        availability: selectedWorker.availability
                    )
                }
                
                self?.assignments.append(contentsOf: newAssignmentDetails)
                self?.selectedWorkersToAdd.removeAll()
                
                let assignedCount = newAssignments.count
                self?.showSuccessMessage(
                    "Workers assigned successfully",
                    "\(assignedCount) worker\(assignedCount == 1 ? "" : "s") \(assignedCount == 1 ? "has" : "have") been assigned to this task."
                )
                
                #if DEBUG
                print("🎉 [ChefTaskDetailViewModel] Successfully assigned \(assignedCount) workers")
                print("   - Total assignments now: \(self?.assignments.count ?? 0)")
                #endif
            }
        )
        .store(in: &cancellables)
    }
    
    func removeWorkerAssignmentWithConfirmation(_ assignmentId: Int, workerName: String) {
        #if DEBUG
        print("[ChefTaskDetailViewModel] 🗑️ Removing assignment ID: \(assignmentId) for worker: \(workerName)")
        #endif
        
        guard assignments.contains(where: { $0.assignment.id == assignmentId }) else {
            #if DEBUG
            print("❌ [ChefTaskDetailViewModel] Assignment \(assignmentId) not found in local list")
            #endif
            showError("Worker assignment not found")
            return
        }
        
        ChefProjectsAPIService.shared.removeTaskAssignment(assignmentId: assignmentId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        #if DEBUG
                        print("❌ [ChefTaskDetailViewModel] API Error removing assignment: \(error)")
                        #endif
                        
                        let errorMessage: String
                        // ✅ FIXED: Removed redundant conditional cast
                        switch error {
                        case .serverError(let code, _):
                            switch code {
                            case 404:
                                errorMessage = "Worker assignment no longer exists"
                            case 403:
                                errorMessage = "You don't have permission to remove this worker"
                            case 409:
                                errorMessage = "Cannot remove worker - task is currently active"
                            default:
                                errorMessage = "Failed to remove worker from task"
                            }
                        case .networkError:
                            errorMessage = "Network error - please check your connection"
                        default:
                            errorMessage = "Failed to remove worker from task"
                        }
                        
                        self?.showError(errorMessage)
                        
                    case .finished:
                        #if DEBUG
                        print("✅ [ChefTaskDetailViewModel] Assignment removal completed")
                        #endif
                    }
                },
                receiveValue: { [weak self] response in
                    #if DEBUG
                    print("✅ [ChefTaskDetailViewModel] Assignment removed successfully")
                    print("   - Server response: \(response)")
                    #endif
                    
                    self?.assignments.removeAll { $0.assignment.id == assignmentId }
                    
                    self?.showSuccessMessage(
                        "Worker Removed",
                        "\(workerName) has been successfully removed from this task."
                    )
                    
                    #if DEBUG
                    print("   - Remaining assignments: \(self?.assignments.count ?? 0)")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func updateLocalTask(_ task: ProjectTask) {
        if let currentDetail = taskDetail {
            let updatedDetail = ChefTaskDetail(
                task: task,
                project: currentDetail.project,
                assignments: currentDetail.assignments,
                conversation: currentDetail.conversation
            )
            taskDetail = updatedDetail
        }
    }
    
    func removeWorkerAssignment(_ assignmentId: Int) {
        #if DEBUG
        print("[ChefTaskDetailViewModel] 🗑️ Removing assignment ID: \(assignmentId)")
        #endif
        
        ChefProjectsAPIService.shared.removeTaskAssignment(assignmentId: assignmentId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        #if DEBUG
                        print("❌ [ChefTaskDetailViewModel] Remove assignment failed: \(error)")
                        #endif
                        self?.showError("Failed to remove worker: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] _ in
                    #if DEBUG
                    print("✅ [ChefTaskDetailViewModel] Assignment removed successfully")
                    #endif
                    self?.assignments.removeAll { $0.assignment.id == assignmentId }
                }
            )
            .store(in: &cancellables)
    }
    
    func updateWorkerCrane(assignmentId: Int, craneModelId: Int?) {
        let updateData = UpdateTaskAssignmentRequest(craneModelId: craneModelId)
        
        #if DEBUG
        print("[ChefTaskDetailViewModel] 🔧 Updating crane for assignment \(assignmentId) to crane \(craneModelId?.description ?? "none")")
        #endif
        
        ChefProjectsAPIService.shared.updateTaskAssignment(assignmentId: assignmentId, data: updateData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        #if DEBUG
                        print("❌ [ChefTaskDetailViewModel] Update crane failed: \(error)")
                        #endif
                        self?.showError("Failed to update crane assignment: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] updatedAssignment in
                    #if DEBUG
                    print("✅ [ChefTaskDetailViewModel] Crane updated successfully")
                    #endif
                    
                    if let index = self?.assignments.firstIndex(where: { $0.assignment.id == assignmentId }) {
                        let currentDetail = self?.assignments[index]
                        self?.assignments[index] = TaskAssignmentDetail(
                            assignment: updatedAssignment,
                            employee: currentDetail?.employee ?? Employee(
                                id: 0,
                                name: "",
                                email: "",
                                role: "",
                                phoneNumber: nil,
                                profilePictureUrl: nil,
                                isActivated: nil,
                                craneTypes: nil,
                                address: nil,
                                emergencyContact: nil,
                                cprNumber: nil,
                                birthDate: nil,
                                hasDrivingLicense: nil,
                                drivingLicenseCategory: nil,
                                drivingLicenseExpiration: nil
                            ),
                            craneModel: updatedAssignment.craneModel,
                            availability: currentDetail?.availability
                        )
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func toggleTaskStatus() {
        guard let task = taskDetail?.task else { return }
        
        #if DEBUG
        print("[ChefTaskDetailViewModel] 🔄 Toggling task status for \(task.title)")
        #endif
        
        ChefProjectsAPIService.shared.toggleTaskStatus(id: task.id, isActive: !task.isActive)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        #if DEBUG
                        print("❌ [ChefTaskDetailViewModel] Toggle status failed: \(error)")
                        #endif
                        self?.showError("Failed to update task status: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] updatedTask in
                    #if DEBUG
                    print("✅ [ChefTaskDetailViewModel] Task status updated to: \(updatedTask.isActive ? "active" : "inactive")")
                    #endif
                    self?.updateLocalTask(updatedTask)
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteTask(completion: @escaping () -> Void) {
        guard let task = taskDetail?.task else { return }
        
        #if DEBUG
        print("[ChefTaskDetailViewModel] 🗑️ Deleting task: \(task.title)")
        #endif
        
        ChefProjectsAPIService.shared.deleteTask(id: task.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    if case .failure(let error) = completionResult {
                        #if DEBUG
                        print("❌ [ChefTaskDetailViewModel] Delete task failed: \(error)")
                        #endif
                        self?.showError("Failed to delete task: \(error.localizedDescription)")
                    }
                },
                receiveValue: { _ in
                    #if DEBUG
                    print("✅ [ChefTaskDetailViewModel] Task deleted successfully")
                    #endif
                    completion()
                }
            )
            .store(in: &cancellables)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
        
        #if DEBUG
        print("🚨 [ChefTaskDetailViewModel] Error: \(message)")
        #endif
    }
    
    private func showSuccessMessage(_ title: String, _ message: String) {
        successMessage = message
        showSuccess = true
        
        #if DEBUG
        print("✅ [ChefTaskDetailViewModel] Success: \(title) - \(message)")
        #endif
    }
}

// ✅ ADDED: Task Equipment Details Model
struct TaskEquipmentDetails {
    var categoryName: String?
    var craneTypes: [CraneTypeAPIResponse] = []
    var brandName: String?
    var modelName: String?
}

// MARK: - Supporting Components (existing)

struct TaskStatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                .font(.caption)
            
            Text(isActive ? "Active" : "Paused")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(isActive ? .ksrSuccess : .ksrWarning)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill((isActive ? Color.ksrSuccess : Color.ksrWarning).opacity(0.15))
        )
    }
}

struct TaskStatCard: View {
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

struct TaskQuickActionButton: View {
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

struct FixedWorkerAssignmentCard: View {
    let assignmentDetail: TaskAssignmentDetail
    let onRemove: () -> Void
    let onEditCrane: (Int?) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCraneMenu = false
    @State private var showDeleteConfirmation = false
    @State private var isRemoving = false
    
    var body: some View {
        HStack(spacing: 16) {
            if let profileUrl = assignmentDetail.employee.profilePictureUrl, !profileUrl.isEmpty {
                AsyncImage(url: URL(string: profileUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.ksrSecondary)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.ksrSecondary)
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(assignmentDetail.employee.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(assignmentDetail.employee.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.caption)
                        .foregroundColor(.ksrInfo)
                    
                    if let craneModel = assignmentDetail.craneModel {
                        Text(craneModel.name)
                            .font(.caption)
                            .foregroundColor(.ksrInfo)
                    } else {
                        Text("No crane assigned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let availability = assignmentDetail.availability {
                    TaskAvailabilityBadge(availability: availability)
                }
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    #if DEBUG
                    print("[FixedWorkerAssignmentCard] 🔧 Edit crane tapped for \(assignmentDetail.employee.name)")
                    #endif
                    showCraneMenu = true
                } label: {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.ksrInfo)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.ksrInfo.opacity(0.1))
                                .overlay(
                                    Circle()
                                        .stroke(Color.ksrInfo.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                
                Button {
                    #if DEBUG
                    print("[FixedWorkerAssignmentCard] 🗑️ Remove tapped for \(assignmentDetail.employee.name)")
                    #endif
                    showDeleteConfirmation = true
                } label: {
                    if isRemoving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.ksrError.opacity(0.7))
                            )
                    } else {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.ksrError)
                            )
                    }
                }
                .buttonStyle(.plain)
                .disabled(isRemoving)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
        .confirmationDialog(
            "Remove Worker",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove \(assignmentDetail.employee.name)", role: .destructive) {
                performRemoval()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove \(assignmentDetail.employee.name) from this task? This action cannot be undone.")
        }
        .actionSheet(isPresented: $showCraneMenu) {
            ActionSheet(
                title: Text("Select Crane"),
                message: Text("Choose a crane model for \(assignmentDetail.employee.name)"),
                buttons: [
                    .default(Text("No Crane")) {
                        #if DEBUG
                        print("[FixedWorkerAssignmentCard] 🔧 Setting no crane for \(assignmentDetail.employee.name)")
                        #endif
                        onEditCrane(nil)
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private func performRemoval() {
        #if DEBUG
        print("[FixedWorkerAssignmentCard] 🗑️ Starting removal for \(assignmentDetail.employee.name)")
        #endif
        
        isRemoving = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onRemove()
        }
    }
}

struct TaskAvailabilityBadge: View {
    let availability: WorkerAvailability
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: availability.isAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.caption)
            
            Text(availability.isAvailable ? "Available" : "Conflict")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(availability.isAvailable ? .ksrSuccess : .ksrWarning)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill((availability.isAvailable ? Color.ksrSuccess : Color.ksrWarning).opacity(0.15))
        )
    }
}

struct ChefEditTaskView: View {
    let task: ProjectTask
    let onTaskUpdated: ((ProjectTask) -> Void)?
    
    @StateObject private var viewModel: EditTaskViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDiscardChangesAlert = false
    @State private var showWorkerPicker = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case title, description, supervisorName, supervisorEmail, supervisorPhone, clientEquipmentInfo
    }
    
    init(task: ProjectTask, onTaskUpdated: ((ProjectTask) -> Void)? = nil) {
        self.task = task
        self.onTaskUpdated = onTaskUpdated
        self._viewModel = StateObject(wrappedValue: EditTaskViewModel(task: task))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Task Information Section
                    taskInformationSection
                    
                    // Scheduling & Resource Planning Section
                    schedulingSection
                    
                    // Equipment Requirements Section
                    equipmentSection
                    
                    // Certificate Requirements Section
                    certificateSection
                    
                    // Supervisor Selection Section
                    supervisorSection
                }
                .padding()
            }
            .background(backgroundGradient)
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if viewModel.hasChanges {
                            showDiscardChangesAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isSaving || !viewModel.hasChanges)
                    .font(.headline)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .alert(isPresented: $showDiscardChangesAlert) {
                Alert(
                    title: Text("Discard Changes?"),
                    message: Text("You have unsaved changes. Are you sure you want to discard them?"),
                    primaryButton: .destructive(Text("Discard")) {
                        dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if viewModel.updateSuccess {
                            dismiss()
                        }
                    }
                )
            }
            .sheet(isPresented: $viewModel.showHierarchicalEquipmentSelector) {
                // TODO: Implement HierarchicalEquipmentSelector
                Text("Equipment selector not yet implemented")
                    .padding()
                Button("Close") {
                    viewModel.showHierarchicalEquipmentSelector = false
                }
            }
            .sheet(isPresented: $viewModel.showCertificateSelector) {
                TaskCertificateSelectionView(
                    selectedCertificates: viewModel.selectedCertificatesBinding,
                    isPresented: $viewModel.showCertificateSelector,
                    availableCertificates: viewModel.availableCertificates
                )
            }
            .overlay {
                if viewModel.isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.ksrYellow)
                            
                            Text("Updating task...")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                .shadow(radius: 10)
                        )
                    }
                }
            }
        }
        .onAppear {
            viewModel.onDismiss = { dismiss() }
            viewModel.onTaskUpdated = onTaskUpdated
        }
    }
    
    // MARK: - Sections
    
    private var taskInformationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Task Information", icon: "doc.text.fill")
            
            // Title Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Task Title *", systemImage: "textformat")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("Enter task title", text: $viewModel.taskTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .title)
                
                if let error = viewModel.titleError {
                    ErrorText(error)
                }
            }
            
            // Description Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("Enter task description", text: $viewModel.description, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .description)
            }
            
            // Deadline Toggle and Picker
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $viewModel.hasDeadline.animation()) {
                    Label("Set Deadline", systemImage: "calendar.badge.clock")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .tint(.ksrYellow)
                
                if viewModel.hasDeadline {
                    DatePicker(
                        "Deadline",
                        selection: $viewModel.deadline,
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                    
                    if let error = viewModel.deadlineError {
                        ErrorText(error)
                    }
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
    
    private var schedulingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Scheduling & Resource Planning", icon: "calendar.badge.clock")
            
            // Start Date
            Toggle("Set Start Date", isOn: $viewModel.hasStartDate.animation())
            .tint(.ksrYellow)
            
            if viewModel.hasStartDate {
                DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.leading)
                
                if let error = viewModel.startDateError {
                    ErrorText(error)
                        .padding(.leading)
                }
            }
            
            // Task Status
            VStack(alignment: .leading, spacing: 8) {
                Label("Task Status", systemImage: "flag.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Status", selection: $viewModel.status) {
                    ForEach(ProjectTaskStatus.allCases, id: \.self) { status in
                        HStack {
                            Image(systemName: status.icon)
                                .foregroundColor(status.color)
                            Text(status.displayName)
                        }
                        .tag(status)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
            
            // Task Priority
            VStack(alignment: .leading, spacing: 8) {
                Label("Priority", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Priority", selection: $viewModel.priority) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        HStack {
                            Image(systemName: priority.icon)
                                .foregroundColor(priority.color)
                            Text(priority.displayName)
                        }
                        .tag(priority)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Estimated Hours
            HStack {
                Toggle("Set Estimated Hours", isOn: $viewModel.hasEstimatedHours.animation())
                Image(systemName: "clock")
                    .foregroundColor(.ksrWarning)
            }
            .tint(.ksrYellow)
            
            if viewModel.hasEstimatedHours {
                Stepper("Estimated Hours: \(viewModel.estimatedHours, specifier: "%.1f")",
                        value: $viewModel.estimatedHours, in: 0.5...1000, step: 0.5)
                    .padding(.leading)
                
                if let error = viewModel.estimatedHoursError {
                    ErrorText(error)
                        .padding(.leading)
                }
            }
            
            // Required Operators
            HStack {
                Toggle("Set Required Operators", isOn: $viewModel.hasRequiredOperators.animation())
                Image(systemName: "person.3.fill")
                    .foregroundColor(.ksrSuccess)
            }
            .tint(.ksrYellow)
            
            if viewModel.hasRequiredOperators {
                Stepper("Required Operators: \(viewModel.requiredOperators)",
                        value: $viewModel.requiredOperators, in: 1...50)
                    .padding(.leading)
                
                if let error = viewModel.requiredOperatorsError {
                    ErrorText(error)
                        .padding(.leading)
                }
            }
            
            // Client Equipment Info
            VStack(alignment: .leading, spacing: 8) {
                Label("Client Equipment Information", systemImage: "info.circle")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Details about client's equipment...",
                          text: $viewModel.clientEquipmentInfo, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .clientEquipmentInfo)
                
                if let error = viewModel.clientEquipmentInfoError {
                    ErrorText(error)
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
    
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Equipment Requirements", icon: "wrench.and.screwdriver.fill")
            
            VStack(spacing: 16) {
                // Equipment selection button
                Button {
                    viewModel.showHierarchicalEquipmentSelector = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Equipment Requirements *")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(viewModel.selectedCraneTypeIds.isEmpty ? "Select equipment requirements" : "\(viewModel.selectedCraneTypeIds.count) selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                if let error = viewModel.equipmentError {
                    ErrorText(error)
                }
                
                // Equipment validation result
                if let result = viewModel.equipmentValidationResult {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: result.isCompletelyValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(result.isCompletelyValid ? .ksrSuccess : .ksrWarning)
                            
                            Text(result.isCompletelyValid ? "Equipment selection is valid" : "Equipment validation warnings")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        if !result.validationErrors.isEmpty {
                            ForEach(result.validationErrors, id: \.self) { error in
                                Text("• \(error)")
                                    .font(.caption)
                                    .foregroundColor(.ksrWarning)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((result.isCompletelyValid ? Color.ksrSuccess : Color.ksrWarning).opacity(0.1))
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
    
    private var certificateSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Certificate Requirements", icon: "checkmark.seal.fill")
            
            VStack(spacing: 16) {
                // Certificate selection button
                Button {
                    viewModel.showCertificateSelector = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Required Certificates")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(viewModel.selectedCertificateIds.isEmpty ? "Select required certificates" : "\(viewModel.selectedCertificateIds.count) selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                if let error = viewModel.certificateError {
                    ErrorText(error)
                }
                
                // Selected certificates display
                if !viewModel.selectedCertificateIds.isEmpty {
                    VStack(spacing: 8) {
                        // TODO: Need to convert certificate IDs to certificate objects for display
                        /* TODO: Re-implement when certificate objects are available
                        ForEach(viewModel.selectedCertificates, id: \.id) { certificate in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(.ksrInfo)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(certificate.nameEn)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Text(certificate.code)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    viewModel.toggleCertificate(certificate)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.ksrInfo.opacity(0.1))
                            )
                        }*/
                        Text("Selected \(viewModel.selectedCertificateIds.count) certificate(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
    
    private var supervisorSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Supervisor Information", icon: "person.badge.shield.checkmark")
            
            // Internal Supervisor Selection
            VStack(alignment: .leading, spacing: 8) {
                    Text("Select Supervisor *")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if viewModel.isLoadingSupervisors {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading supervisors...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else {
                        Menu {
                            ForEach(viewModel.availableSupervisors, id: \.employeeId) { supervisor in
                                Button {
                                    viewModel.supervisorId = supervisor.employeeId
                                } label: {
                                    Label(supervisor.name, systemImage: "person.fill")
                                }
                            }
                        } label: {
                            HStack {
                                if let supervisorId = viewModel.supervisorId,
                                   let selectedSupervisor = viewModel.availableSupervisors.first(where: { $0.employeeId == supervisorId }) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(selectedSupervisor.name)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Text(selectedSupervisor.role.capitalized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("Select a supervisor")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    
                    if let error = viewModel.supervisorError {
                        ErrorText(error)
                    }
                }
            // External supervisor fields removed - not supported by the model
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
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
    
    // MARK: - Actions
    
    private func saveTask() {
        viewModel.saveTask()
        // The onTaskUpdated callback will be called when the task is successfully updated
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.ksrYellow)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

struct ErrorText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
            
            Text(text)
                .font(.caption)
        }
        .foregroundColor(.ksrError)
    }
}

private struct RawTaskAssignment: Codable {
    let assignment_id: Int
    let task_id: Int
    let employee_id: Int
    let assigned_at: Date?
    let crane_model_id: Int?
    
    // ✅ MANAGEMENT CALENDAR FIELDS: Enhanced assignment tracking
    let work_date: Date?
    let status: AssignmentStatus?
    let notes: String?
    
    let Employees: Employee
    let CraneModel: CraneModel?
    
    private enum CodingKeys: String, CodingKey {
        case assignment_id
        case task_id
        case employee_id
        case assigned_at
        case crane_model_id
        case work_date
        case status
        case notes
        case Employees
        case CraneModel
    }
}
