//
//  ChefTaskManagementViews.swift
//  KSR Cranes App
//
//  PRODUCTION READY - Fully integrated task creation with real API
//

import SwiftUI
import Combine

// MARK: - Create Task View

struct ChefCreateTaskView: View {
    let projectId: Int
    let onTaskCreated: ((ProjectTask) -> Void)?
    
    @StateObject private var viewModel = CreateTaskViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: CreateTaskField?
    
    enum CreateTaskField: Hashable {
        case title, description
        case supervisorName, supervisorEmail, supervisorPhone
    }
    
    init(projectId: Int, onTaskCreated: ((ProjectTask) -> Void)? = nil) {
        self.projectId = projectId
        self.onTaskCreated = onTaskCreated
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Form Sections
                    taskInfoSection
                    supervisorSection
                    workerAssignmentSection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(backgroundGradient)
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        createTask()
                    }
                    .foregroundColor(viewModel.isFormValid ? Color.ksrYellow : .secondary)
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            .sheet(isPresented: $viewModel.showWorkerPicker) {
                ChefWorkerPickerView(
                    selectedWorkers: $viewModel.selectedWorkers,
                    projectId: projectId, // ✅ FIXED: Pass the projectId
                    excludeTaskId: nil,
                    requiredCraneTypes: viewModel.requiredCraneTypes
                )
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if viewModel.creationSuccess {
                            dismiss()
                        }
                    }
                )
            }
            .onAppear {
                viewModel.projectId = projectId
                viewModel.loadAvailableSupervisors()
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
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet.clipboard.fill")
                .font(.system(size: 50))
                .foregroundColor(.ksrYellow)
            
            Text("Create New Task")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Define task details and assign workers")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    private var taskInfoSection: some View {
        TaskFormSection(title: "Task Information", icon: "doc.text.fill") {
            VStack(spacing: 16) {
                TaskFormField(
                    title: "Task Title",
                    text: $viewModel.title,
                    placeholder: "Enter task title",
                    isRequired: true,
                    focusedField: $focusedField,
                    fieldType: .title,
                    errorMessage: viewModel.titleError
                )
                
                TaskFormField(
                    title: "Description",
                    text: $viewModel.description,
                    placeholder: "Describe the task requirements",
                    isRequired: false,
                    focusedField: $focusedField,
                    fieldType: .description,
                    isMultiline: true
                )
                
                // Deadline Picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Deadline")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Toggle("", isOn: $viewModel.hasDeadline)
                            .labelsHidden()
                    }
                    
                    if viewModel.hasDeadline {
                        DatePicker(
                            "",
                            selection: $viewModel.deadline,
                            in: Date()...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        )
                    }
                }
            }
        }
    }
    
    private var supervisorSection: some View {
        TaskFormSection(title: "Task Supervisor", icon: "person.badge.shield.checkmark.fill") {
            VStack(spacing: 16) {
                // Supervisor Type Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Supervisor Type")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        SupervisorTypeButton(
                            title: "Internal",
                            icon: "person.fill.checkmark",
                            isSelected: viewModel.supervisorType == .internal,
                            action: { viewModel.supervisorType = .internal }
                        )
                        
                        SupervisorTypeButton(
                            title: "External",
                            icon: "person.badge.plus",
                            isSelected: viewModel.supervisorType == .external,
                            action: { viewModel.supervisorType = .external }
                        )
                    }
                }
                
                // Supervisor Details
                if viewModel.supervisorType == .internal {
                    internalSupervisorPicker
                } else {
                    externalSupervisorFields
                }
            }
        }
    }
    
    private var internalSupervisorPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Supervisor")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            if viewModel.isLoadingSupervisors {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading supervisors...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                Menu {
                    ForEach(viewModel.availableSupervisors) { supervisor in
                        Button {
                            viewModel.selectedSupervisor = supervisor
                        } label: {
                            HStack {
                                Text(supervisor.name)
                                Text("(\(supervisor.role))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } label: {
                    HStack {
                        if let supervisor = viewModel.selectedSupervisor {
                            if let profileUrl = supervisor.profilePictureUrl {
                                AsyncImage(url: URL(string: profileUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.ksrSecondary)
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.ksrSecondary)
                                    .frame(width: 40, height: 40)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(supervisor.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(supervisor.role.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Image(systemName: "person.badge.plus")
                                .font(.title3)
                                .foregroundColor(.ksrYellow)
                            
                            Text("Select Supervisor")
                                .font(.headline)
                                .foregroundColor(.ksrYellow)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.ksrSecondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    )
                }
            }
            
            if viewModel.supervisorError != nil {
                Text(viewModel.supervisorError!)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
    }
    
    private var externalSupervisorFields: some View {
        VStack(spacing: 16) {
            TaskFormField(
                title: "Supervisor Name",
                text: $viewModel.externalSupervisorName,
                placeholder: "Full name",
                isRequired: true,
                focusedField: $focusedField,
                fieldType: .supervisorName,
                errorMessage: viewModel.supervisorNameError
            )
            
            TaskFormField(
                title: "Email",
                text: $viewModel.externalSupervisorEmail,
                placeholder: "supervisor@example.com",
                isRequired: true,
                keyboardType: .emailAddress,
                focusedField: $focusedField,
                fieldType: .supervisorEmail,
                errorMessage: viewModel.supervisorEmailError
            )
            
            TaskFormField(
                title: "Phone",
                text: $viewModel.externalSupervisorPhone,
                placeholder: "+45 12 34 56 78",
                isRequired: true,
                keyboardType: .phonePad,
                focusedField: $focusedField,
                fieldType: .supervisorPhone,
                errorMessage: viewModel.supervisorPhoneError
            )
        }
    }
    
    private var workerAssignmentSection: some View {
        TaskFormSection(title: "Assign Workers", icon: "person.3.fill") {
            VStack(alignment: .leading, spacing: 16) {
                // Selected Workers Count
                HStack {
                    Text("Selected Workers")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if !viewModel.selectedWorkers.isEmpty {
                        Text("\(viewModel.selectedWorkers.count) selected")
                            .font(.caption)
                            .foregroundColor(.ksrSuccess)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.ksrSuccess.opacity(0.1))
                            )
                    }
                }
                
                // Worker Selection Button
                Button {
                    viewModel.showWorkerPicker = true
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.title3)
                            .foregroundColor(.ksrYellow)
                        
                        Text("Select Workers")
                            .font(.headline)
                            .foregroundColor(.ksrYellow)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.ksrSecondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    )
                }
                
                // Selected Workers List
                if !viewModel.selectedWorkers.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(viewModel.selectedWorkers) { worker in
                            SelectedWorkerRow(
                                worker: worker,
                                onRemove: {
                                    viewModel.removeWorker(worker)
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button {
                createTask()
            } label: {
                HStack(spacing: 12) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Text(viewModel.isLoading ? "Creating Task..." : "Create Task")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            viewModel.isFormValid && !viewModel.isLoading
                                ? Color.ksrYellow
                                : Color.gray
                        )
                )
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
            
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .disabled(viewModel.isLoading)
        }
        .padding(.top, 8)
    }
    
    private func createTask() {
        focusedField = nil
        
        viewModel.createTask { task in
            if let task = task {
                onTaskCreated?(task)
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Components

struct TaskFormSection<Content: View>: View {
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

struct TaskFormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isRequired: Bool
    let keyboardType: UIKeyboardType
    @FocusState.Binding var focusedField: ChefCreateTaskView.CreateTaskField?
    let fieldType: ChefCreateTaskView.CreateTaskField
    let errorMessage: String?
    let isMultiline: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String,
        isRequired: Bool = false,
        keyboardType: UIKeyboardType = .default,
        focusedField: FocusState<ChefCreateTaskView.CreateTaskField?>.Binding,
        fieldType: ChefCreateTaskView.CreateTaskField,
        errorMessage: String? = nil,
        isMultiline: Bool = false
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.keyboardType = keyboardType
        self._focusedField = focusedField
        self.fieldType = fieldType
        self.errorMessage = errorMessage
        self.isMultiline = isMultiline
    }
    
    private var isFocused: Bool {
        focusedField == fieldType
    }
    
    private var hasError: Bool {
        errorMessage != nil && !errorMessage!.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if isRequired {
                    Text("*")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                if hasError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
            }
            
            Group {
                if isMultiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(3...6)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .keyboardType(keyboardType)
            .autocapitalization(keyboardType == .emailAddress ? .none : .words)
            .disableAutocorrection(keyboardType == .emailAddress)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                hasError ? Color.red :
                                isFocused ? Color.ksrYellow :
                                Color.clear,
                                lineWidth: hasError || isFocused ? 2 : 0
                            )
                    )
            )
            .focused($focusedField, equals: fieldType)
            
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
    }
}

struct SupervisorTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .ksrSecondary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .black : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.ksrYellow : Color.ksrLightGray.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.ksrYellow : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct SelectedWorkerRow: View {
    let worker: AvailableWorker
    let onRemove: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Worker Avatar
            if let profileUrl = worker.employee.profilePictureUrl {
                AsyncImage(url: URL(string: profileUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.ksrSecondary)
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.ksrSecondary)
                    .frame(width: 36, height: 36)
            }
            
            // Worker Info
            VStack(alignment: .leading, spacing: 2) {
                Text(worker.employee.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if !worker.craneTypes.isEmpty {
                    Text(worker.craneTypes.map { $0.name }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.ksrError)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        )
    }
}
