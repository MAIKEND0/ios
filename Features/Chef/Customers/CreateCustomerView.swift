//
//  CreateCustomerView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//  Updated with Logo Support
//

import SwiftUI
import Combine

struct CreateCustomerView: View {
    @StateObject private var viewModel = CreateCustomerViewModel()
    @StateObject private var logoManager = EnhancedCustomerLogoManager()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: CreateCustomerField?
    
    enum CreateCustomerField: Hashable {
        case name, email, phone, address, cvr
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
            .background(createCustomerBackground)
            .navigationTitle("New Customer")
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
                        createCustomer()
                    }
                    .foregroundColor(viewModel.isFormValid ? Color.ksrPrimary : .secondary)
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading || logoManager.isUploading)
                }
            }
            .onTapGesture {
                focusedField = nil
            }
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
        .alert("Logo Upload Error", isPresented: Binding<Bool>(
            get: { logoManager.lastError != nil },
            set: { _ in logoManager.lastError = nil }
        )) {
            if logoManager.canRetry() {
                Button("Retry") {
                    // Will retry in createCustomer function
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
            Text(logoManager.lastError?.localizedDescription ?? "Unknown error")
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
                Text("Add New Customer")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Enter customer information and optionally add a logo")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Company Info Section
    private var companyInfoSection: some View {
        CustomerFormSection(title: "Company Information", icon: "building.2.fill") {
            VStack(spacing: 16) {
                // Company Name (Required)
                CustomerFormField(
                    title: "Company Name",
                    text: $viewModel.name,
                    placeholder: "Enter company name",
                    isRequired: true,
                    keyboardType: .default,
                    textContentType: .organizationName,
                    focusedField: $focusedField,
                    fieldType: .name,
                    errorMessage: viewModel.nameError
                )
                
                // CVR Number
                CustomerFormField(
                    title: "CVR Number",
                    text: $viewModel.cvr,
                    placeholder: "12345678",
                    isRequired: false,
                    keyboardType: .numberPad,
                    textContentType: nil,
                    focusedField: $focusedField,
                    fieldType: .cvr,
                    errorMessage: viewModel.cvrError,
                    helpText: "8-digit Danish company registration number"
                )
            }
        }
    }
    
    // MARK: - Contact Info Section
    private var contactInfoSection: some View {
        CustomerFormSection(title: "Contact Information", icon: "envelope.fill") {
            VStack(spacing: 16) {
                // Email
                CustomerFormField(
                    title: "Email Address",
                    text: $viewModel.email,
                    placeholder: "contact@company.dk",
                    isRequired: false,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    focusedField: $focusedField,
                    fieldType: .email,
                    errorMessage: viewModel.emailError
                )
                
                // Phone
                CustomerFormField(
                    title: "Phone Number",
                    text: $viewModel.phone,
                    placeholder: "+45 12 34 56 78",
                    isRequired: false,
                    keyboardType: .phonePad,
                    textContentType: .telephoneNumber,
                    focusedField: $focusedField,
                    fieldType: .phone,
                    errorMessage: viewModel.phoneError
                )
            }
        }
    }
    
    // MARK: - Additional Info Section
    private var additionalInfoSection: some View {
        CustomerFormSection(title: "Additional Information", icon: "location.fill") {
            VStack(spacing: 16) {
                // Address
                CustomerFormField(
                    title: "Address",
                    text: $viewModel.address,
                    placeholder: "Street address, city, postal code",
                    isRequired: false,
                    keyboardType: .default,
                    textContentType: .fullStreetAddress,
                    focusedField: $focusedField,
                    fieldType: .address,
                    errorMessage: nil,
                    isMultiline: true
                )
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Create Button
            Button {
                createCustomer()
            } label: {
                HStack(spacing: 12) {
                    if viewModel.isLoading || logoManager.isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
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
                                ? Color.ksrPrimary
                                : Color.gray
                        )
                        .shadow(
                            color: viewModel.isFormValid ? Color.ksrPrimary.opacity(0.3) : Color.clear,
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
    private var createCustomerBackground: some View {
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
            return "Creating Customer..."
        } else {
            return "Create Customer"
        }
    }
    
    // MARK: - Actions
    private func createCustomer() {
        focusedField = nil
        
        // First create the customer
        viewModel.createCustomer { success in
            guard success, let newCustomer = viewModel.createdCustomer else { return }
            
            // If we have a logo to upload, upload it after customer creation
            if logoManager.selectedImage != nil {
                logoManager.uploadLogo(for: newCustomer.customer_id) { logoResult in
                    switch logoResult {
                    case .success:
                        #if DEBUG
                        print("[CreateCustomerView] Customer and logo created successfully")
                        #endif
                        // Customer was already created successfully, just dismiss
                        dismiss()
                        
                    case .failure(let error):
                        // Customer was created but logo upload failed
                        viewModel.showAlert(
                            title: "Logo Upload Failed",
                            message: "Customer was created successfully, but logo upload failed: \(error.localizedDescription). You can add the logo later."
                        )
                        // Still dismiss since customer was created
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            dismiss()
                        }
                        
                    case .progress:
                        break // Progress is handled by logoManager
                    }
                }
            } else {
                // No logo to upload, just dismiss
                dismiss()
            }
        }
    }
}

// MARK: - Customer Form Section Component
struct CustomerFormSection<Content: View>: View {
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

// MARK: - Customer Form Field Component
struct CustomerFormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isRequired: Bool
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    @FocusState.Binding var focusedField: CreateCustomerView.CreateCustomerField?
    let fieldType: CreateCustomerView.CreateCustomerField
    let errorMessage: String?
    let helpText: String?
    let isMultiline: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String,
        isRequired: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        focusedField: FocusState<CreateCustomerView.CreateCustomerField?>.Binding,
        fieldType: CreateCustomerView.CreateCustomerField,
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
struct CreateCustomerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CreateCustomerView()
                .preferredColorScheme(.light)
            CreateCustomerView()
                .preferredColorScheme(.dark)
        }
    }
}
