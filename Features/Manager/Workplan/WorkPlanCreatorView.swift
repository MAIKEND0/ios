//
//  WorkPlanCreatorView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 20/05/2025.
//  Updated with enhanced UI/UX and bug fixes on 21/05/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct WorkPlanCreatorView: View {
    let task: ManagerAPIService.Task
    @Binding var isPresented: Bool
    @StateObject private var viewModel: CreateWorkPlanViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showFilePicker = false
    @State private var selectedFile: URL?
    @State private var showPreview = false
    @State private var searchQuery = ""
    @State private var showDatePicker = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    init(task: ManagerAPIService.Task, viewModel: CreateWorkPlanViewModel, isPresented: Binding<Bool>) {
        self.task = task
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    weekSelectorSection
                    taskDetailsSection
                    employeeSelectionSection
                    scheduleGridSection
                    descriptionSection
                    attachmentSection
                    actionButtonsSection
                }
                .padding(.vertical, 8)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationTitle("Work Plan Creator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .onAppear(perform: initializeView)
            .alert(isPresented: $viewModel.showAlert) {
                alertContent()
            }
            .alert(isPresented: $showValidationAlert) {
                Alert(
                    title: Text("Validation Error"),
                    message: Text(validationMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .png, .jpeg, .plainText, UTType(filenameExtension: "docx") ?? .data, UTType(filenameExtension: "doc") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showPreview) { previewSheet }
            .sheet(isPresented: $showDatePicker) { datePickerSheet }
            .onTapGesture { dismissKeyboard() }
        }
    }

    var headerSection: some View {
        Text("Create Work Plan")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .padding(.horizontal)
    }

    var weekSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Week")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            HStack {
                Button(action: { viewModel.changeWeek(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.ksrYellow)
                }
                Text(viewModel.weekRangeText)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .onTapGesture { showDatePicker = true }
                Button(action: { viewModel.changeWeek(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.ksrYellow)
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Task: \(task.title)")
                .font(.subheadline)
                .foregroundColor(.primary)
            if let project = task.project {
                Text("Project: \(project.title)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    var employeeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Employees")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            TextField("Search employees...", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding(.vertical, 4)
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if viewModel.employees.isEmpty {
                Text("No employees assigned to this task")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(filteredEmployees) { employee in
                            EmployeeCard(
                                employee: employee,
                                isSelected: viewModel.assignments.contains { $0.employee_id == employee.employee_id }
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    toggleEmployeeSelection(employee)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    var scheduleGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assign Hours")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            if viewModel.assignments.isEmpty {
                Text("No employees selected")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                ForEach(Array(viewModel.assignments.enumerated()), id: \.offset) { index, _ in
                    WorkPlanAssignmentRow(
                        assignment: Binding(
                            get: { viewModel.assignments[index] },
                            set: { viewModel.assignments[index] = $0 }
                        ),
                        onCopyToOthers: { assignment in
                            viewModel.copyHoursToOtherEmployees(from: assignment)
                        }
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            TextField("Enter description...", text: $viewModel.description, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 60)
                .padding(.bottom, 8)

            Text("Additional Info")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            TextField("Enter additional info...", text: $viewModel.additionalInfo, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 60)
                .padding(.bottom, 8)
        }
        .padding(.horizontal)
    }

    var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attachment")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Button(action: { showFilePicker = true }) {
                Text(selectedFile?.lastPathComponent ?? "Upload File")
                    .foregroundColor(Color.ksrYellow)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.ksrYellow, lineWidth: 1)
                    )
            }
            if let file = selectedFile {
                Text("Selected: \(file.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    var actionButtonsSection: some View {
        HStack {
            Spacer()
            Button("Save Draft") {
                if validateAssignments() {
                    viewModel.saveDraft()
                    isPresented = false
                }
            }
            .foregroundColor(Color.ksrYellow)
            .padding(.horizontal)
            Button("Publish") {
                if validateAssignments() {
                    viewModel.publish()
                    isPresented = false
                }
            }
            .foregroundColor(.green)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.red)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Preview") {
                    if validateAssignments() {
                        showPreview = true
                    }
                }
                .foregroundColor(Color.ksrYellow)
                .disabled(viewModel.assignments.isEmpty)
            }
        }
    }

    var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(.systemBackground)
    }

    func initializeView() {
        viewModel.loadEmployees(for: task.task_id)
        viewModel.taskId = task.task_id
    }

    func alertContent() -> Alert {
        Alert(
            title: Text(viewModel.alertTitle),
            message: Text(viewModel.alertMessage),
            dismissButton: .default(Text("OK"))
        )
    }

    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedFile = url
                viewModel.setAttachment(from: url)
            }
        case .failure(let error):
            viewModel.showAlert = true
            viewModel.alertTitle = "Error"
            viewModel.alertMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }

    var previewSheet: some View {
        WorkPlanPreviewView(
            viewModel: viewModel,
            isPresented: $showPreview,
            onConfirm: {
                if validateAssignments() {
                    viewModel.publish()
                    isPresented = false
                }
            }
        )
    }

    var datePickerSheet: some View {
        DatePicker(
            "Select Week",
            selection: $viewModel.selectedMonday,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .padding()
        .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
        .onChange(of: viewModel.selectedMonday) { _, newValue in
            viewModel.updateWeekRangeText()
            showDatePicker = false
        }
    }

    var filteredEmployees: [ManagerAPIService.Worker] {
        if searchQuery.isEmpty {
            return viewModel.employees
        }
        return viewModel.employees.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
    }

    func toggleEmployeeSelection(_ employee: ManagerAPIService.Worker) {
        if let index = viewModel.assignments.firstIndex(where: { $0.employee_id == employee.employee_id }) {
            viewModel.assignments.remove(at: index)
        } else {
            viewModel.assignments.append(WorkPlanAssignment(
                employee_id: employee.employee_id,
                availableEmployees: viewModel.employees,
                weekStart: viewModel.selectedMonday,
                dailyHours: Array(repeating: DailyHours(isActive: false, start_time: Date(), end_time: Date()), count: 7),
                notes: ""
            ))
        }
    }

    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func validateAssignments() -> Bool {
        if viewModel.assignments.isEmpty {
            validationMessage = "At least one employee must be assigned."
            showValidationAlert = true
            return false
        }
        if !viewModel.assignments.contains(where: { $0.dailyHours.contains(where: { $0.isActive }) }) {
            validationMessage = "At least one active schedule is required."
            showValidationAlert = true
            return false
        }
        return true
    }
}

struct WorkPlanCreatorView_Previews: PreviewProvider {
    static var previews: some View {
        WorkPlanCreatorView(
            task: ManagerAPIService.Task(
                task_id: 1,
                title: "Sample Task",
                description: nil,
                deadline: nil,
                project: ManagerAPIService.Project(
                    id: UUID(),
                    project_id: 1,
                    title: "Sample Project",
                    description: nil,
                    start_date: nil,
                    end_date: nil,
                    street: nil,
                    city: nil,
                    zip: nil,
                    status: nil,
                    tasks: [],
                    assignedWorkersCount: 0,
                    customer: nil
                ),
                supervisor_id: nil
            ),
            viewModel: CreateWorkPlanViewModel(),
            isPresented: .constant(true)
        )
        .preferredColorScheme(.light)
        .previewDisplayName("Light Mode")
        
        WorkPlanCreatorView(
            task: ManagerAPIService.Task(
                task_id: 1,
                title: "Sample Task",
                description: nil,
                deadline: nil,
                project: ManagerAPIService.Project(
                    id: UUID(),
                    project_id: 1,
                    title: "Sample Project",
                    description: nil,
                    start_date: nil,
                    end_date: nil,
                    street: nil,
                    city: nil,
                    zip: nil,
                    status: nil,
                    tasks: [],
                    assignedWorkersCount: 0,
                    customer: nil
                ),
                supervisor_id: nil
            ),
            viewModel: CreateWorkPlanViewModel(),
            isPresented: .constant(true)
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
