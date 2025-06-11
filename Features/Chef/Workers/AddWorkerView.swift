//
//  AddWorkerView.swift
//  KSR Cranes App
//  Form for adding new workers
//

import SwiftUI

struct AddWorkerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = AddWorkerViewModel()
    
    let onWorkerAdded: (WorkerForChef) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Basic Information
                    basicInfoSection
                    
                    // Employment Details
                    employmentSection
                    
                    // Contact Information
                    contactSection
                    
                    // Additional Information
                    additionalInfoSection
                    
                    // Certificates Section
                    certificatesSection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(backgroundGradient)
        }
        .navigationTitle("Add Worker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $viewModel.showingCertificateSelection) {
            CertificateSelectionView(
                selectedStates: viewModel.selectedCertificates,
                onSave: { updatedStates in
                    viewModel.selectedCertificates = updatedStates
                },
                title: "Worker Certificates"
            )
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK")) {
                    if viewModel.workerCreated {
                        dismiss()
                    }
                }
            )
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.ksrPrimary.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(Color.ksrPrimary)
            }
            
            VStack(spacing: 4) {
                Text("Add New Worker")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                Text("Fill in the details to add a new team member")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        FormSection(title: "Basic Information", icon: "person.fill") {
            VStack(spacing: 16) {
                FormTextField(
                    title: "Full Name",
                    text: $viewModel.name,
                    placeholder: "Enter worker's full name",
                    icon: "person.fill",
                    isRequired: true
                )
                
                FormTextField(
                    title: "Email Address",
                    text: $viewModel.email,
                    placeholder: "worker@ksrcranes.dk",
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    isRequired: true
                )
            }
        }
    }
    
    // MARK: - Employment Section
    
    private var employmentSection: some View {
        FormSection(title: "Employment Details", icon: "briefcase.fill") {
            VStack(spacing: 16) {
                // Hourly Rate
                FormNumberField(
                    title: "Hourly Rate (DKK)",
                    value: $viewModel.hourlyRate,
                    placeholder: "350",
                    icon: "banknote.fill",
                    suffix: "DKK/hour",
                    isRequired: true
                )
                
                // Employment Type
                FormPickerField(
                    title: "Employment Type",
                    selection: $viewModel.employmentType,
                    options: EmploymentType.allCases,
                    displayName: { $0.displayName },
                    icon: "briefcase.fill"
                )
                
                // Worker Role
                FormPickerField(
                    title: "Worker Role",
                    selection: $viewModel.role,
                    options: WorkerRole.allCases,
                    displayName: { $0.danishName },
                    icon: "person.badge.key.fill"
                )
                
                // Status
                FormPickerField(
                    title: "Initial Status",
                    selection: $viewModel.status,
                    options: [.aktiv, .inaktiv],
                    displayName: { $0.displayName },
                    icon: "checkmark.circle.fill"
                )
                
                // Hire Date
                FormDateField(
                    title: "Hire Date",
                    date: $viewModel.hireDate,
                    icon: "calendar.badge.plus"
                )
            }
        }
    }
    
    // MARK: - Contact Section
    
    private var contactSection: some View {
        FormSection(title: "Contact Information", icon: "phone.fill") {
            VStack(spacing: 16) {
                FormTextField(
                    title: "Phone Number",
                    text: $viewModel.phone,
                    placeholder: "+45 12 34 56 78",
                    icon: "phone.fill",
                    keyboardType: .phonePad
                )
                
                FormTextField(
                    title: "Address",
                    text: $viewModel.address,
                    placeholder: "Street, ZIP City",
                    icon: "location.fill",
                    axis: .vertical
                )
            }
        }
    }
    
    // MARK: - Additional Info Section
    
    private var additionalInfoSection: some View {
        FormSection(title: "Additional Information", icon: "doc.text.fill") {
            VStack(spacing: 16) {
                FormTextField(
                    title: "Notes",
                    text: $viewModel.notes,
                    placeholder: "Any additional notes about the worker...",
                    icon: "doc.text.fill",
                    axis: .vertical
                )
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.createWorker { worker in
                    onWorkerAdded(worker)
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    
                    Text(viewModel.isCreating ? "Creating Worker..." : "Create Worker")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.isFormValid ? Color.ksrPrimary : Color.gray)
                )
            }
            .disabled(!viewModel.isFormValid || viewModel.isCreating)
            
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Background
    
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
    
    // MARK: - Certificates Section
    
    private var certificatesSection: some View {
        FormSection(title: "Certificates & Qualifications", icon: "checkmark.seal.fill") {
            VStack(spacing: 16) {
                // Certificate Selection Button
                Button {
                    viewModel.showingCertificateSelection = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.ksrPrimary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select Certificates")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                            
                            Text("Choose Danish crane operator certificates")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6).opacity(0.5))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Selected Certificates Summary
                if !viewModel.selectedCertificates.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Selected Certificates")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                            
                            Spacer()
                            
                            Text(viewModel.certificatesSummary)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.selectedCertificates, id: \.id) { certificate in
                                    CertificateChip(certificate: certificate) {
                                        viewModel.removeCertificate(withId: certificate.certificateType.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.ksrInfo)
                        
                        Text("No certificates selected. You can add them later from the worker details.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.ksrInfo.opacity(0.1))
                    )
                }
            }
        }
    }
}

// MARK: - Certificate Chip Component

struct CertificateChip: View {
    let certificate: CertificateSelectionState
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: certificate.certificateType.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(certificate.certificateType.color)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(certificate.certificateType.code)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if certificate.isCertified {
                    Text("Certified")
                        .font(.system(size: 9))
                        .foregroundColor(.green)
                }
            }
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(certificate.certificateType.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(certificate.certificateType.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Form Section Component

struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.ksrPrimary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                content
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Form Field Components

struct FormTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var axis: Axis = .horizontal
    var isRequired: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                if axis == .vertical {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(keyboardType)
                        .lineLimit(3...6)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(keyboardType)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
        }
    }
}

struct FormNumberField: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let icon: String
    let suffix: String?
    var isRequired: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, value: Binding<String>, placeholder: String, icon: String, suffix: String? = nil, isRequired: Bool = false) {
        self.title = title
        self._value = value
        self.placeholder = placeholder
        self.icon = icon
        self.suffix = suffix
        self.isRequired = isRequired
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                TextField(placeholder, text: $value)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(.decimalPad)
                
                if let suffix = suffix {
                    Text(suffix)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
        }
    }
}

struct FormPickerField<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let displayName: (T) -> String
    let icon: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Picker(title, selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(displayName(option)).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .accentColor(Color.ksrPrimary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
        }
    }
}

struct FormDateField: View {
    let title: String
    @Binding var date: Date
    let icon: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: .date
                )
                .datePickerStyle(CompactDatePickerStyle())
                .accentColor(Color.ksrPrimary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
        }
    }
}

// MARK: - Preview

struct AddWorkerView_Previews: PreviewProvider {
    static var previews: some View {
        AddWorkerView { _ in }
            .preferredColorScheme(.light)
    }
}