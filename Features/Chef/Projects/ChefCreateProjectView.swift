//
//  ChefCreateProjectView.swift
//  KSR Cranes App
//
//  Project creation view for Chef role
//

import SwiftUI
import Combine

struct ChefCreateProjectView: View {
    let onProjectCreated: ((Project) -> Void)?
    
    @StateObject private var viewModel = CreateProjectViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: CreateProjectField?
    
    enum CreateProjectField: Hashable {
        case title, description
        case street, city, zip
        case normalRate, weekendRate
        case overtimeRate1, overtimeRate2
        case weekendOvertimeRate1, weekendOvertimeRate2
    }
    
    init(onProjectCreated: ((Project) -> Void)? = nil) {
        self.onProjectCreated = onProjectCreated
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Form Sections
                    customerSelectionSection
                    projectInfoSection
                    locationSection
                    projectDatesSection
                    billingSettingsSection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(backgroundGradient)
            .navigationTitle("New Project")
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
                        createProject()
                    }
                    .foregroundColor(viewModel.isFormValid ? Color.ksrYellow : .secondary)
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            .sheet(isPresented: $viewModel.showCustomerPicker) {
                CustomerPickerView(selectedCustomer: $viewModel.selectedCustomer)
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if viewModel.creationSuccess {
                            onProjectCreated?(viewModel.createdProject!)
                            dismiss()
                        }
                    }
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
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.ksrYellow)
            
            Text("Create New Project")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Set up project details and billing rates")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    private var customerSelectionSection: some View {
        ProjectFormSection(title: "Customer", icon: "building.2.fill") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Customer")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Button {
                    viewModel.showCustomerPicker = true
                } label: {
                    HStack {
                        if let customer = viewModel.selectedCustomer {
                            if let logoUrl = customer.logo_url {
                                AsyncImage(url: URL(string: logoUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Image(systemName: "building.2.fill")
                                        .foregroundColor(.ksrSecondary)
                                }
                                .frame(width: 40, height: 40)
                                .cornerRadius(8)
                            } else {
                                Image(systemName: "building.2.fill")
                                    .font(.title2)
                                    .foregroundColor(.ksrSecondary)
                                    .frame(width: 40, height: 40)
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
                        } else {
                            Image(systemName: "plus.circle")
                                .font(.title3)
                                .foregroundColor(.ksrYellow)
                            
                            Text("Select Customer")
                                .font(.headline)
                                .foregroundColor(.ksrYellow)
                        }
                        
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
                
                if let error = viewModel.customerError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var projectInfoSection: some View {
        ProjectFormSection(title: "Project Information", icon: "info.circle.fill") {
            VStack(spacing: 16) {
                ProjectFormField(
                    title: "Project Title",
                    text: $viewModel.title,
                    placeholder: "Enter project title",
                    isRequired: true,
                    focusedField: $focusedField,
                    fieldType: .title,
                    errorMessage: viewModel.titleError
                )
                
                ProjectFormField(
                    title: "Description",
                    text: $viewModel.description,
                    placeholder: "Describe the project scope and requirements",
                    isRequired: false,
                    focusedField: $focusedField,
                    fieldType: .description,
                    isMultiline: true
                )
                
                // Project Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Status")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        ForEach(Project.ProjectStatus.allCases, id: \.self) { status in
                            ProjectStatusButton(
                                status: status,
                                isSelected: viewModel.status == status,
                                action: { viewModel.status = status }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var locationSection: some View {
        ProjectFormSection(title: "Project Location", icon: "location.fill") {
            VStack(spacing: 16) {
                ProjectFormField(
                    title: "Street Address",
                    text: $viewModel.street,
                    placeholder: "Street name and number",
                    isRequired: false,
                    focusedField: $focusedField,
                    fieldType: .street
                )
                
                HStack(spacing: 12) {
                    ProjectFormField(
                        title: "City",
                        text: $viewModel.city,
                        placeholder: "City",
                        isRequired: false,
                        focusedField: $focusedField,
                        fieldType: .city
                    )
                    
                    ProjectFormField(
                        title: "ZIP Code",
                        text: $viewModel.zip,
                        placeholder: "ZIP",
                        isRequired: false,
                        keyboardType: .numberPad,
                        focusedField: $focusedField,
                        fieldType: .zip
                    )
                    .frame(maxWidth: 120)
                }
            }
        }
    }
    
    private var projectDatesSection: some View {
        ProjectFormSection(title: "Project Timeline", icon: "calendar") {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        DatePicker(
                            "",
                            selection: $viewModel.startDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        DatePicker(
                            "",
                            selection: $viewModel.endDate,
                            in: viewModel.startDate...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                    }
                }
                
                if let error = viewModel.dateError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var billingSettingsSection: some View {
        ProjectFormSection(title: "Billing Rates (DKK/hour)", icon: "dollarsign.circle.fill") {
            VStack(spacing: 16) {
                Text("Set hourly rates for different work types")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Standard Rates
                VStack(spacing: 12) {
                    Text("Standard Rates")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrInfo)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        ProjectFormField(
                            title: "Normal Rate",
                            text: $viewModel.normalRate,
                            placeholder: "0.00",
                            isRequired: false,
                            keyboardType: .decimalPad,
                            focusedField: $focusedField,
                            fieldType: .normalRate
                        )
                        
                        ProjectFormField(
                            title: "Weekend Rate",
                            text: $viewModel.weekendRate,
                            placeholder: "0.00",
                            isRequired: false,
                            keyboardType: .decimalPad,
                            focusedField: $focusedField,
                            fieldType: .weekendRate
                        )
                    }
                }
                
                // Overtime Rates
                VStack(spacing: 12) {
                    Text("Overtime Rates")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrWarning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        ProjectFormField(
                            title: "Overtime 1",
                            text: $viewModel.overtimeRate1,
                            placeholder: "0.00",
                            isRequired: false,
                            keyboardType: .decimalPad,
                            focusedField: $focusedField,
                            fieldType: .overtimeRate1
                        )
                        
                        ProjectFormField(
                            title: "Overtime 2",
                            text: $viewModel.overtimeRate2,
                            placeholder: "0.00",
                            isRequired: false,
                            keyboardType: .decimalPad,
                            focusedField: $focusedField,
                            fieldType: .overtimeRate2
                        )
                    }
                }
                
                // Weekend Overtime Rates
                VStack(spacing: 12) {
                    Text("Weekend Overtime Rates")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        ProjectFormField(
                            title: "Weekend OT 1",
                            text: $viewModel.weekendOvertimeRate1,
                            placeholder: "0.00",
                            isRequired: false,
                            keyboardType: .decimalPad,
                            focusedField: $focusedField,
                            fieldType: .weekendOvertimeRate1
                        )
                        
                        ProjectFormField(
                            title: "Weekend OT 2",
                            text: $viewModel.weekendOvertimeRate2,
                            placeholder: "0.00",
                            isRequired: false,
                            keyboardType: .decimalPad,
                            focusedField: $focusedField,
                            fieldType: .weekendOvertimeRate2
                        )
                    }
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button {
                createProject()
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
                    
                    Text(viewModel.isLoading ? "Creating Project..." : "Create Project")
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
    
    private func createProject() {
        focusedField = nil
        
        viewModel.createProject { project in
            if let project = project {
                onProjectCreated?(project)
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Components

struct ProjectFormSection<Content: View>: View {
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

struct ProjectFormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isRequired: Bool
    let keyboardType: UIKeyboardType
    @FocusState.Binding var focusedField: ChefCreateProjectView.CreateProjectField?
    let fieldType: ChefCreateProjectView.CreateProjectField
    let errorMessage: String?
    let isMultiline: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String,
        isRequired: Bool = false,
        keyboardType: UIKeyboardType = .default,
        focusedField: FocusState<ChefCreateProjectView.CreateProjectField?>.Binding,
        fieldType: ChefCreateProjectView.CreateProjectField,
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

struct ProjectStatusButton: View {
    let status: Project.ProjectStatus
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: status.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .black : status.color)
                
                Text(status.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .black : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? status.color : Color.ksrLightGray.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? status.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Customer Picker View (Placeholder)

struct CustomerPickerView: View {
    @Binding var selectedCustomer: Customer?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var customersViewModel = CustomersViewModel()
    
    var body: some View {
        NavigationStack {
            List(customersViewModel.customers) { customer in
                CustomerRowView(customer: customer) {
                    selectedCustomer = customer
                    dismiss()
                }
            }
            .navigationTitle("Select Customer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                customersViewModel.loadCustomers()
            }
        }
    }
}

struct CustomerRowView: View {
    let customer: Customer
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                if let logoUrl = customer.logo_url {
                    AsyncImage(url: URL(string: logoUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.ksrSecondary)
                    }
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                } else {
                    Image(systemName: "building.2.fill")
                        .font(.title2)
                        .foregroundColor(.ksrSecondary)
                        .frame(width: 40, height: 40)
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
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
