//
//  EditCustomerView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//  Updated with Logo Support
//

import SwiftUI
import Combine

struct EditCustomerView: View {
    let customer: Customer
    let onCustomerUpdated: (Customer) -> Void
    
    @StateObject private var viewModel = EditCustomerViewModel()
    @StateObject private var logoManager = EnhancedCustomerLogoManager()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: EditCustomerField?
    
    enum EditCustomerField: Hashable {
        case name, email, phone, address, cvr
    }
    
    init(customer: Customer, onCustomerUpdated: @escaping (Customer) -> Void) {
        self.customer = customer
        self.onCustomerUpdated = onCustomerUpdated
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section with Logo
                    headerSectionWithLogo
                    
                    // Form Sections
                    companyInfoSection
                    contactInfoSection
                    additionalInfoSection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(editCustomerBackground)
            .navigationTitle("Edit Customer")
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
                        updateCustomer()
                    }
                    .foregroundColor(viewModel.isFormValid ? Color.ksrPrimary : .secondary)
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading || logoManager.isUploading)
                }
            }
            .onTapGesture {
                focusedField = nil
            }
            .onAppear {
                viewModel.loadCustomerData(customer)
                logoManager.logoUrl = customer.logo_url
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK")) {
                    if viewModel.updateSuccess {
                        // Will be handled in completeUpdate
                    }
                }
            )
        }
        .alert("Logo Error", isPresented: Binding<Bool>(
            get: { logoManager.lastError != nil },
            set: { _ in logoManager.lastError = nil }
        )) {
            if logoManager.canRetry() {
                Button("Retry") {
                    // Will retry in updateCustomer function
                }
                
                Button("Continue", role: .cancel) {
                    logoManager.lastError = nil
                }
            } else {
                Button("OK") {
                    logoManager.lastError = nil
                }
            }
        } message: {
            Text(logoManager.lastError?.localizedDescription ?? "Unknown logo error")
        }
    }
    
    // MARK: - Header Section with Logo
    private var headerSectionWithLogo: some View {
        VStack(spacing: 20) {
            // Logo Picker
            CustomerLogoPickerView(
                selectedImage: $logoManager.selectedImage,
                logoUrl: $logoManager.logoUrl,
                size: 100,
                isEditable: true,
                placeholder: "Add Logo"
            )
            
            // Logo Upload Progress
            if logoManager.isUploading {
                LogoUploadProgressView(
                    progress: logoManager.uploadProgress,
                    retryCount: logoManager.retryCount
                )
            }
            
            VStack(spacing: 8) {
                Text("Edit Customer")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Update customer information and logo")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Company Info Section
    private var companyInfoSection: some View {
        EditCustomerFormSection(title: "Company Information", icon: "building.2.fill") {
            VStack(spacing: 16) {
                // Company Name (Required)
                EditCustomerFormField(
                    title: "Company Name",
                    text: $viewModel.name,
                    placeholder: "Enter company name",
                    isRequired: true,
                    keyboardType: UIKeyboardType.default,
                    textContentType: UITextContentType.organizationName,
                    focusedField: $focusedField,
                    fieldType: EditCustomerField.name,
                    errorMessage: viewModel.nameError
                )
                
                // CVR Number
                EditCustomerFormField(
                    title: "CVR Number",
                    text: $viewModel.cvr,
                    placeholder: "12345678",
                    isRequired: false,
                    keyboardType: UIKeyboardType.numberPad,
                    textContentType: nil,
                    focusedField: $focusedField,
                    fieldType: EditCustomerField.cvr,
                    errorMessage: viewModel.cvrError,
                    helpText: "8-digit Danish company registration number"
                )
            }
        }
    }
    
    // MARK: - Contact Info Section
    private var contactInfoSection: some View {
        EditCustomerFormSection(title: "Contact Information", icon: "envelope.fill") {
            VStack(spacing: 16) {
                // Email
                EditCustomerFormField(
                    title: "Email Address",
                    text: $viewModel.email,
                    placeholder: "contact@company.dk",
                    isRequired: false,
                    keyboardType: UIKeyboardType.emailAddress,
                    textContentType: UITextContentType.emailAddress,
                    focusedField: $focusedField,
                    fieldType: EditCustomerField.email,
                    errorMessage: viewModel.emailError
                )
                
                // Phone
                EditCustomerFormField(
                    title: "Phone Number",
                    text: $viewModel.phone,
                    placeholder: "+45 12 34 56 78",
                    isRequired: false,
                    keyboardType: UIKeyboardType.phonePad,
                    textContentType: UITextContentType.telephoneNumber,
                    focusedField: $focusedField,
                    fieldType: EditCustomerField.phone,
                    errorMessage: viewModel.phoneError
                )
            }
        }
    }
    
    // MARK: - Additional Info Section
    private var additionalInfoSection: some View {
        EditCustomerFormSection(title: "Additional Information", icon: "location.fill") {
            VStack(spacing: 16) {
                // Address
                EditCustomerFormField(
                    title: "Address",
                    text: $viewModel.address,
                    placeholder: "Street address, city, postal code",
                    isRequired: false,
                    keyboardType: UIKeyboardType.default,
                    textContentType: UITextContentType.fullStreetAddress,
                    focusedField: $focusedField,
                    fieldType: EditCustomerField.address,
                    errorMessage: nil as String?,
                    isMultiline: true
                )
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Update Button
            Button {
                updateCustomer()
            } label: {
                HStack(spacing: 12) {
                    if viewModel.isLoading || logoManager.isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Text(getButtonText())
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            viewModel.isFormValid && !viewModel.isLoading && !logoManager.isUploading
                                ? Color.ksrWarning
                                : Color.gray
                        )
                        .shadow(
                            color: viewModel.isFormValid ? Color.ksrWarning.opacity(0.3) : Color.clear,
                            radius: 8, x: 0, y: 4
                        )
                )
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading || logoManager.isUploading)
            .scaleEffect(viewModel.isLoading || logoManager.isUploading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
            
            // Cancel Button
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
            .disabled(viewModel.isLoading || logoManager.isUploading)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Background
    private var editCustomerBackground: some View {
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
    
    // MARK: - Helper Methods
    private func getButtonText() -> String {
        if logoManager.isUploading {
            return "Uploading Logo..."
        } else if viewModel.isLoading {
            return "Updating Customer..."
        } else {
            return "Update Customer"
        }
    }
    
    // MARK: - Actions
    private func updateCustomer() {
        focusedField = nil
        
        // Check if we need to handle logo changes
        let hasNewLogo = logoManager.selectedImage != nil
        let hasDeletedLogo = logoManager.logoUrl == nil && customer.hasLogo
        
        // First update the customer basic info
        viewModel.updateCustomer(customerId: customer.customer_id) { success in
            guard success else { return }
            
            if hasDeletedLogo {
                // Delete the logo
                logoManager.deleteLogo(for: customer.customer_id) { deleteResult in
                    switch deleteResult {
                    case .success:
                        logoManager.logoUrl = nil
                        completeUpdate()
                    case .failure(let error):
                        viewModel.showAlert(
                            title: "Logo Delete Failed",
                            message: "Customer was updated, but logo deletion failed: \(error.localizedDescription)"
                        )
                        completeUpdate()
                    case .progress:
                        break
                    }
                }
            } else if hasNewLogo {
                // Upload new logo
                logoManager.uploadLogo(for: customer.customer_id) { uploadResult in
                    switch uploadResult {
                    case .success(let logoUrl):
                        logoManager.logoUrl = logoUrl
                        completeUpdate()
                    case .failure(let error):
                        viewModel.showAlert(
                            title: "Logo Upload Failed",
                            message: "Customer was updated, but logo upload failed: \(error.localizedDescription)"
                        )
                        completeUpdate()
                    case .progress:
                        break
                    }
                }
            } else {
                // No logo changes, just complete
                completeUpdate()
            }
        }
    }
    
    private func completeUpdate() {
        if let updatedCustomer = viewModel.updatedCustomer {
            // Create customer with updated logo info
            let finalCustomer = Customer(
                customer_id: updatedCustomer.customer_id,
                name: updatedCustomer.name,
                contact_email: updatedCustomer.contact_email,
                phone: updatedCustomer.phone,
                address: updatedCustomer.address,
                cvr_nr: updatedCustomer.cvr_nr,
                created_at: updatedCustomer.created_at,
                logo_url: logoManager.logoUrl,
                logo_key: nil, // We don't expose logo_key in the frontend
                logo_uploaded_at: logoManager.logoUrl != nil ? Date() : nil,
                project_count: updatedCustomer.project_count,
                hiring_request_count: updatedCustomer.hiring_request_count,
                recent_projects: updatedCustomer.recent_projects
            )
            onCustomerUpdated(finalCustomer)
        }
        dismiss()
    }
}

// MARK: - Edit Customer Form Section Component
struct EditCustomerFormSection<Content: View>: View {
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
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.ksrPrimary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 4)
            
            // Section Content
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

// MARK: - Edit Customer Form Field Component
struct EditCustomerFormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isRequired: Bool
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    @FocusState.Binding var focusedField: EditCustomerView.EditCustomerField?
    let fieldType: EditCustomerView.EditCustomerField
    let errorMessage: String?
    let helpText: String?
    let isMultiline: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String,
        isRequired: Bool = false,
        keyboardType: UIKeyboardType = UIKeyboardType.default,
        textContentType: UITextContentType? = nil,
        focusedField: FocusState<EditCustomerView.EditCustomerField?>.Binding,
        fieldType: EditCustomerView.EditCustomerField,
        errorMessage: String? = nil,
        helpText: String? = nil,
        isMultiline: Bool = false
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self._focusedField = focusedField
        self.fieldType = fieldType
        self.errorMessage = errorMessage
        self.helpText = helpText
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
            // Title
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
            
            // Input Field
            Group {
                if isMultiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(3...6)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textContentType(textContentType)
            .keyboardType(keyboardType)
            .autocapitalization(keyboardType == UIKeyboardType.emailAddress ? .none : .words)
            .disableAutocorrection(keyboardType == UIKeyboardType.emailAddress)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                hasError ? Color.red :
                                isFocused ? Color.ksrPrimary :
                                Color.clear,
                                lineWidth: hasError || isFocused ? 2 : 0
                            )
                    )
            )
            .focused($focusedField, equals: fieldType)
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            // Help Text or Error Message
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            } else if let helpText = helpText {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Preview
struct EditCustomerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EditCustomerView(customer: Customer.mockData[0]) { _ in }
                .preferredColorScheme(.light)
            EditCustomerView(customer: Customer.mockData[0]) { _ in }
                .preferredColorScheme(.dark)
        }
    }
}
