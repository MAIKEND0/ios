//
//  EditWorkerView.swift
//  KSR Cranes App
//  Form for editing existing workers
//

import SwiftUI

struct EditWorkerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: EditWorkerViewModel
    
    let onWorkerUpdated: (WorkerForChef) -> Void
    
    init(worker: WorkerForChef, onWorkerUpdated: @escaping (WorkerForChef) -> Void) {
        self._viewModel = StateObject(wrappedValue: EditWorkerViewModel(worker: worker))
        self.onWorkerUpdated = onWorkerUpdated
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
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
        .navigationTitle("Edit Worker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK")) {
                    if viewModel.workerUpdated {
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
                    .fill(Color.ksrInfo.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                if let profileUrl = viewModel.originalWorker.profile_picture_url, !profileUrl.isEmpty {
                    AsyncImage(url: URL(string: profileUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Text(viewModel.originalWorker.initials)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 76, height: 76)
                    .clipShape(Circle())
                } else {
                    Text(viewModel.originalWorker.initials)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.ksrInfo)
                }
            }
            
            VStack(spacing: 4) {
                Text("Edit Worker")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                Text("Update worker information")
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
                    title: "Status",
                    selection: $viewModel.status,
                    options: WorkerStatus.allCases,
                    displayName: { $0.displayName },
                    icon: "checkmark.circle.fill"
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
    
    // MARK: - Certificates Section
    
    private var certificatesSection: some View {
        FormSection(title: "Certificates & Qualifications", icon: "checkmark.seal.fill") {
            VStack(spacing: 16) {
                // Current certificates
                if viewModel.isLoadingCertificates {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading certificates...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else if viewModel.certificates.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("No certificates added")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            viewModel.showCertificateSelection = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Certificates")
                            }
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.ksrPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    // List of current certificates
                    ForEach(viewModel.certificates) { certificate in
                        CertificateEditRow(
                            certificate: certificate,
                            onRemove: {
                                viewModel.removeCertificate(certificate)
                            }
                        )
                    }
                    
                    // Add more certificates button
                    Button {
                        viewModel.showCertificateSelection = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add More Certificates")
                            Spacer()
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ksrPrimary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .sheet(isPresented: $viewModel.showCertificateSelection) {
            CertificateSelectionView(
                selectedStates: viewModel.selectedCertificateStates,
                onSave: { updatedStates in
                    // Handle certificate updates
                    for state in updatedStates {
                        if state.isSelected {
                            if let existingCert = viewModel.certificates.first(where: { $0.certificateTypeId == state.certificateType.id }) {
                                // Update existing certificate
                                viewModel.updateCertificate(existingCert, with: state)
                            } else {
                                // Add new certificate
                                viewModel.addCertificate(state)
                            }
                        }
                    }
                    viewModel.showCertificateSelection = false
                },
                title: "Manage Certificates"
            )
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Show changed fields
            if viewModel.hasChanges {
                changedFieldsIndicator
            }
            
            Button {
                viewModel.updateWorker { worker in
                    onWorkerUpdated(worker)
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isUpdating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    
                    Text(viewModel.isUpdating ? "Updating Worker..." : "Update Worker")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.isFormValid && viewModel.hasChanges ? Color.ksrPrimary : Color.gray)
                )
            }
            .disabled(!viewModel.isFormValid || !viewModel.hasChanges || viewModel.isUpdating)
            
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Changed Fields Indicator
    
    private var changedFieldsIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(Color.ksrInfo)
            
            Text("\(viewModel.changedFieldsCount) field(s) modified")
                .font(.caption)
                .foregroundColor(Color.ksrInfo)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.ksrInfo.opacity(0.2))
        )
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
}

// MARK: - Certificate Edit Row Component

struct CertificateEditRow: View {
    let certificate: WorkerCertificate
    let onRemove: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: certificate.icon)
                .font(.system(size: 24))
                .foregroundColor(certificate.color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(certificate.color.opacity(0.1))
                )
            
            // Certificate info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(certificate.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    
                    if certificate.isCertified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
                
                HStack(spacing: 8) {
                    // Status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(certificate.statusColor)
                            .frame(width: 6, height: 6)
                        Text(certificate.statusText)
                            .font(.caption)
                            .foregroundColor(certificate.statusColor)
                    }
                    
                    if certificate.certificationExpires != nil {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Expires: \(certificate.expiryDateFormatted)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Remove button
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6).opacity(0.5))
        )
    }
}

// MARK: - Preview

struct EditWorkerView_Previews: PreviewProvider {
    static var previews: some View {
        EditWorkerView(worker: WorkerForChef(
            id: 1,
            name: "Preview Worker",
            email: "preview@ksrcranes.dk",
            phone: "+45 12345678",
            address: "Preview Address",
            hourly_rate: 400.0,
            employment_type: .fuld_tid,
            role: .byggeleder,
            status: .aktiv,
            profile_picture_url: nil,
            created_at: Date(),
            last_active: Date(),
            stats: nil
        )) { _ in }
            .preferredColorScheme(.light)
    }
}