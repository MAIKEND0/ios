//
//  EditWorkPlanView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 20/05/2025.
//  Updated with enhanced UI/UX and bug fixes on 21/05/2025.
//  Updated week selector on 22/05/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct EditWorkPlanView: View {
    let workPlan: WorkPlanAPIService.WorkPlan
    @Binding var isPresented: Bool
    @StateObject private var viewModel: EditWorkPlanViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showFilePicker = false
    @State private var selectedFile: URL?
    @State private var showPreview = false
    @State private var searchQuery = ""
    @State private var showDatePicker = false

    init(workPlan: WorkPlanAPIService.WorkPlan, isPresented: Binding<Bool>) {
        self.workPlan = workPlan
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: EditWorkPlanViewModel())
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
            .background(backgroundColor)
            .navigationTitle("Edit Work Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .onAppear { initializeView() }
            .alert(isPresented: $viewModel.showAlert, content: alertContent)
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .png, .jpeg, .plainText, UTType(filenameExtension: "docx") ?? .data, UTType(filenameExtension: "doc") ?? .data],
                allowsMultipleSelection: false,
                onCompletion: handleFileImport
            )
            .sheet(isPresented: $showPreview) { previewSheet }
            .sheet(isPresented: $showDatePicker) { datePickerSheet }
            .onTapGesture { dismissKeyboard() }
        }
    }

    private var headerSection: some View {
        Text("Edit Work Plan")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .padding(.horizontal)
    }

    private var weekSelectorSection: some View {
        WorkPlanWeekSelector(viewModel: viewModel, isWeekInFuture: viewModel.isWeekInFuture())
            .padding(.horizontal)
            .onTapGesture { showDatePicker = true }
    }

    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Task: \(workPlan.task_title)")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.horizontal)
    }

    private var employeeSelectionSection: some View {
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

    private var scheduleGridSection: some View {
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

    private var descriptionSection: some View {
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

    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attachment")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Button(action: { showFilePicker = true }) {
                Text(selectedFile?.lastPathComponent ?? (workPlan.attachment_url != nil ? "Replace File" : "Upload File"))
                    .foregroundColor(Color.ksrYellow)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.ksrYellow, lineWidth: 1)
                    )
            }
            if let url = workPlan.attachment_url {
                Link("Current Attachment", destination: URL(string: url)!)
                    .font(.caption)
                    .foregroundColor(Color.ksrYellow)
            }
            if let file = selectedFile {
                Text("Selected: \(file.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var actionButtonsSection: some View {
        WorkPlanActionButtons(viewModel: viewModel, isPresented: $isPresented)
            .padding(.horizontal)
    }

    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.red)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Preview") {
                    showPreview = true
                }
                .foregroundColor(Color.ksrYellow)
                .disabled(viewModel.assignments.isEmpty)
            }
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(.systemBackground)
    }

    private func alertContent() -> Alert {
        Alert(
            title: Text(viewModel.alertTitle),
            message: Text(viewModel.alertMessage),
            dismissButton: .default(Text("OK"))
        )
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
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

    private var previewSheet: some View {
        WorkPlanPreviewView(
            viewModel: viewModel,
            isPresented: $showPreview,
            onConfirm: {
                viewModel.publish()
                isPresented = false
            }
        )
    }

    private var datePickerSheet: some View {
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

    private var filteredEmployees: [ManagerAPIService.Worker] {
        if searchQuery.isEmpty {
            return viewModel.employees
        }
        return viewModel.employees.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
    }

    private func initializeView() {
        viewModel.initializeWithWorkPlan(workPlan)
        if let url = workPlan.attachment_url {
            selectedFile = URL(string: url)
        }
    }

    private func toggleEmployeeSelection(_ employee: ManagerAPIService.Worker) {
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

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct EditWorkPlanView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleWorkPlan = WorkPlanAPIService.WorkPlan(
            id: 1,
            work_plan_id: 1,
            task_id: 1,
            task_title: "Sample Task",
            weekNumber: 21,
            year: 2025,
            status: "DRAFT",
            creator_name: "John Doe",
            description: "Sample description",
            additional_info: "Sample info",
            attachment_url: nil,
            assignments: []
        )
        
        EditWorkPlanView(
            workPlan: sampleWorkPlan,
            isPresented: .constant(true)
        )
        .preferredColorScheme(.light)
        .previewDisplayName("Light Mode")
        
        EditWorkPlanView(
            workPlan: sampleWorkPlan,
            isPresented: .constant(true)
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
