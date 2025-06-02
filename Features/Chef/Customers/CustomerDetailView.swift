//
//  CustomerDetailView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//  Updated with Logo Support
//

import SwiftUI

struct CustomerDetailView: View {
    let customer: Customer
    @StateObject private var viewModel = CustomerDetailViewModel()
    @StateObject private var logoManager = EnhancedCustomerLogoManager()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showEditForm = false
    @State private var showDeleteConfirmation = false
    @State private var showCreateProject = false
    @State private var showLogoOptions = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section with Logo
                    headerSectionWithLogo
                    
                    // Contact Information
                    contactInfoSection
                    
                    // Statistics Overview
                    statisticsSection
                    
                    // Recent Projects
                    if let projects = viewModel.customerDetail?.projects, !projects.isEmpty {
                        projectsSection(projects)
                    }
                    
                    // Recent Hiring Requests
                    if let hiringRequests = viewModel.customerDetail?.recent_hiring_requests, !hiringRequests.isEmpty {
                        hiringRequestsSection(hiringRequests)
                    }
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(customerDetailBackground)
            .navigationTitle(customer.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showEditForm = true
                        } label: {
                            Label("Edit Customer", systemImage: "pencil")
                        }
                        
                        Button {
                            showLogoOptions = true
                        } label: {
                            Label(customer.hasLogo ? "Change Logo" : "Add Logo", systemImage: "photo")
                        }
                        
                        if customer.hasLogo {
                            Button {
                                deleteLogo()
                            } label: {
                                Label("Remove Logo", systemImage: "photo.badge.minus")
                            }
                        }
                        
                        Button {
                            showCreateProject = true
                        } label: {
                            Label("Create Project", systemImage: "plus.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Customer", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Color.ksrPrimary)
                    }
                }
            }
            .onAppear {
                viewModel.loadCustomerDetails(customerId: customer.customer_id)
                logoManager.logoUrl = customer.logo_url
            }
            .refreshable {
                await refreshCustomerDetails()
            }
        }
        .sheet(isPresented: $showEditForm) {
            EditCustomerView(customer: customer) { updatedCustomer in
                viewModel.updateLocalCustomer(updatedCustomer)
            }
        }
        .sheet(isPresented: $showCreateProject) {
            CreateProjectView(customer: customer)
        }
        .sheet(isPresented: $showLogoOptions) {
            CustomerLogoOptionsSheet(
                customer: customer,
                logoManager: logoManager
            )
        }
        .alert("Delete Customer", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteCustomer(customer.customer_id) { success in
                    if success {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \(customer.displayName)? This action cannot be undone.")
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Logo Error", isPresented: Binding<Bool>(
            get: { logoManager.lastError != nil },
            set: { _ in logoManager.lastError = nil }
        )) {
            if logoManager.canRetry() {
                Button("Retry") {
                    // Handle retry
                }
                
                Button("OK", role: .cancel) {
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
            // Customer Avatar/Logo with Upload Progress
            ZStack {
                CustomerAvatarView(customer: customer, size: 100)
                
                // Upload progress overlay
                if logoManager.isUploading {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 100, height: 100)
                        
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            
                            Text("\(logoManager.getProgressPercentage())%")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .onTapGesture {
                if !logoManager.isUploading {
                    showLogoOptions = true
                }
            }
            
            // Customer Basic Info
            VStack(spacing: 8) {
                Text(customer.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    if let cvr = customer.formattedCVR {
                        Text(cvr)
                            .font(.subheadline)
                            .foregroundColor(Color.ksrWarning)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.ksrWarning.opacity(0.1))
                            )
                    }
                    
                    if customer.hasLogo {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color.ksrSuccess)
                            
                            Text("Has Logo")
                                .font(.caption)
                                .foregroundColor(Color.ksrSuccess)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.ksrSuccess.opacity(0.1))
                        )
                    }
                }
                
                Text("Customer since \(customer.createdAtFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Loading State
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .ksrPrimary))
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Contact Information Section
    private var contactInfoSection: some View {
        CustomerDetailSection(title: "Contact Information", icon: "person.crop.circle.fill") {
            VStack(spacing: 16) {
                if let email = customer.contact_email {
                    CustomerContactInfoRow(
                        icon: "envelope.fill",
                        title: "Email",
                        value: email,
                        color: Color.ksrInfo,
                        action: {
                            if let url = URL(string: "mailto:\(email)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                }
                
                if let phone = customer.phone {
                    CustomerContactInfoRow(
                        icon: "phone.fill",
                        title: "Phone",
                        value: phone,
                        color: Color.ksrSuccess,
                        action: {
                            if let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                }
                
                if let address = customer.address {
                    CustomerContactInfoRow(
                        icon: "location.fill",
                        title: "Address",
                        value: address,
                        color: Color.ksrWarning,
                        action: {
                            let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "http://maps.apple.com/?q=\(encodedAddress)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                }
                
                if customer.contact_email == nil && customer.phone == nil && customer.address == nil {
                    CustomerEmptyStateMessage(
                        icon: "person.crop.circle.badge.exclamationmark",
                        title: "No Contact Information",
                        message: "Add contact details to improve communication."
                    )
                }
            }
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        CustomerDetailSection(title: "Statistics", icon: "chart.bar.fill") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                CustomerStatCard(
                    title: "Projects",
                    value: "\(viewModel.customerDetail?.project_count ?? customer.project_count ?? 0)",
                    icon: "folder.fill",
                    color: Color.ksrPrimary
                )
                
                CustomerStatCard(
                    title: "Requests",
                    value: "\(viewModel.customerDetail?.hiring_request_count ?? customer.hiring_request_count ?? 0)",
                    icon: "person.badge.plus",
                    color: Color.ksrSuccess
                )
                
                CustomerStatCard(
                    title: "Revenue",
                    value: "DKK 0", // TODO: Add revenue calculation
                    icon: "banknote.fill",
                    color: Color.ksrInfo
                )
                
                CustomerStatCard(
                    title: "Rating",
                    value: "4.8", // TODO: Add rating system
                    icon: "star.fill",
                    color: Color.ksrYellow
                )
            }
        }
    }
    
    // MARK: - Projects Section
    private func projectsSection(_ projects: [ProjectDetail]) -> some View {
        CustomerDetailSection(title: "Recent Projects", icon: "folder.fill") {
            VStack(spacing: 12) {
                ForEach(projects.prefix(5)) { project in
                    CustomerProjectRow(project: project)
                }
                
                if projects.count > 5 {
                    Button {
                        // TODO: Navigate to all projects view
                    } label: {
                        HStack {
                            Text("View All \(projects.count) Projects")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(Color.ksrPrimary)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
    
    // MARK: - Hiring Requests Section
    private func hiringRequestsSection(_ requests: [HiringRequestSummary]) -> some View {
        CustomerDetailSection(title: "Recent Hiring Requests", icon: "person.badge.plus.fill") {
            VStack(spacing: 12) {
                ForEach(requests.prefix(5)) { request in
                    CustomerHiringRequestRow(request: request)
                }
                
                if requests.count > 5 {
                    Button {
                        // TODO: Navigate to all hiring requests view
                    } label: {
                        HStack {
                            Text("View All \(requests.count) Requests")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(Color.ksrPrimary)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Primary Actions
            HStack(spacing: 12) {
                CustomerActionButton(
                    title: "Edit Customer",
                    icon: "pencil.circle.fill",
                    color: Color.ksrPrimary,
                    action: { showEditForm = true }
                )
                
                CustomerActionButton(
                    title: customer.hasLogo ? "Change Logo" : "Add Logo",
                    icon: customer.hasLogo ? "photo.circle" : "photo.circle.fill",
                    color: Color.ksrInfo,
                    action: { showLogoOptions = true }
                )
            }
            
            // Secondary Actions
            HStack(spacing: 12) {
                CustomerActionButton(
                    title: "Create Project",
                    icon: "plus.circle.fill",
                    color: Color.ksrSuccess,
                    action: { showCreateProject = true }
                )
                
                if let email = customer.contact_email {
                    CustomerActionButton(
                        title: "Send Email",
                        icon: "envelope.circle.fill",
                        color: Color.ksrInfo,
                        action: {
                            if let url = URL(string: "mailto:\(email)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                }
                
                if let phone = customer.phone {
                    CustomerActionButton(
                        title: "Call",
                        icon: "phone.circle.fill",
                        color: Color.ksrSuccess,
                        action: {
                            if let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                }
            }
            
            // Delete Button
            Button {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Delete Customer")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.05))
                        )
                )
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Background
    private var customerDetailBackground: some View {
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
    private func refreshCustomerDetails() async {
        await withCheckedContinuation { continuation in
            viewModel.loadCustomerDetails(customerId: customer.customer_id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
    
    private func deleteLogo() {
        logoManager.deleteLogo(for: customer.customer_id) { result in
            switch result {
            case .success:
                logoManager.logoUrl = nil
                viewModel.showAlert(
                    title: "Logo Removed",
                    message: "Customer logo has been removed successfully."
                )
            case .failure(let error):
                logoManager.lastError = error
            case .progress:
                break
            }
        }
    }
}

// MARK: - Customer Logo Options Sheet

struct CustomerLogoOptionsSheet: View {
    let customer: Customer
    @ObservedObject var logoManager: EnhancedCustomerLogoManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.ksrInfo.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "photo.circle.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(Color.ksrInfo)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Logo Options")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Manage logo for \(customer.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Logo Picker
                CustomerLogoPickerView(
                    selectedImage: $logoManager.selectedImage,
                    logoUrl: $logoManager.logoUrl,
                    size: 120,
                    isEditable: true,
                    placeholder: "Select Logo"
                )
                
                // Upload Progress
                if logoManager.isUploading {
                    LogoUploadProgressView(
                        progress: logoManager.uploadProgress,
                        retryCount: logoManager.retryCount
                    )
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if logoManager.selectedImage != nil {
                        Button {
                            uploadLogo()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "cloud.upload.fill")
                                Text("Upload Logo")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.ksrPrimary)
                            )
                        }
                        .disabled(logoManager.isUploading)
                    }
                    
                    if customer.hasLogo && logoManager.selectedImage == nil {
                        Button {
                            deleteLogo()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                Text("Remove Logo")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.red.opacity(0.1))
                                    )
                            )
                        }
                        .disabled(logoManager.isUploading)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Customer Logo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.ksrPrimary)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func uploadLogo() {
        logoManager.uploadLogo(for: customer.customer_id) { result in
            switch result {
            case .success(let logoUrl):
                logoManager.logoUrl = logoUrl
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
            case .failure:
                // Error handling is done by logoManager
                break
            case .progress:
                break
            }
        }
    }
    
    private func deleteLogo() {
        logoManager.deleteLogo(for: customer.customer_id) { result in
            switch result {
            case .success:
                logoManager.logoUrl = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
            case .failure:
                // Error handling is done by logoManager
                break
            case .progress:
                break
            }
        }
    }
}

// MARK: - Supporting Views (same as before)

struct CustomerDetailSection<Content: View>: View {
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

struct CustomerContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomerStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.systemGray6))
        )
    }
}

struct CustomerActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
    }
}

struct CustomerEmptyStateMessage: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Mock CreateProjectView for compilation
struct CreateProjectView: View {
    let customer: Customer
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Create Project for \(customer.name)")
                    .font(.title)
                    .padding()
                
                Text("Project creation form would go here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview
struct CustomerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CustomerDetailView(customer: Customer.mockData[0])
                .preferredColorScheme(.light)
            CustomerDetailView(customer: Customer.mockData[0])
                .preferredColorScheme(.dark)
        }
    }
}
