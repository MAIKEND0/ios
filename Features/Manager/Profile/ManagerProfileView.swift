// ManagerProfileView.swift - KOMPLETNY PLIK Z WSZYSTKIMI KOMPONENTAMI
import SwiftUI
import PhotosUI

struct ManagerProfileView: View {
    @StateObject private var viewModel = ManagerProfileViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingLogoutConfirmation = false
    @State private var navigateToLogin = false
    @State private var showEditProfile = false
    @State private var selectedTab: ProfileTab = .overview
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    enum ProfileTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case projects = "Projects"
        case team = "Team"
        case performance = "Performance"
        case settings = "Settings"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .overview: return "person.circle.fill"
            case .projects: return "folder.fill"
            case .team: return "person.3.fill"
            case .performance: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .overview: return .ksrYellow
            case .projects: return .ksrInfo
            case .team: return .ksrSuccess
            case .performance: return .ksrWarning
            case .settings: return .ksrMediumGray
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    managerHeaderSection
                    tabNavigationSection
                    tabContentSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
            }
            .background(backgroundGradient)
            .navigationTitle("Manager Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                HStack(spacing: 12) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(Color.ksrYellow)
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.loadData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(viewModel.isLoading)
                }
            )
            .onAppear {
                viewModel.loadData()
            }
            .refreshable {
                await withCheckedContinuation { continuation in
                    viewModel.loadData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        continuation.resume()
                    }
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .fullScreenCover(isPresented: $navigateToLogin) {
                LoginView()
            }
            .sheet(isPresented: $showEditProfile) {
                ManagerEditProfileView(viewModel: viewModel)
            }
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedItem) {
                Task {
                    if let currentItem = selectedItem {
                        do {
                            if let data = try await currentItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                viewModel.uploadProfilePicture(image)
                            } else {
                                viewModel.showError("Failed to process the selected image.")
                            }
                        } catch {
                            viewModel.showError("Error loading image: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .confirmationDialog("Logout", isPresented: $showingLogoutConfirmation) {
                Button("Logout", role: .destructive) {
                    performLogout()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
    
    // MARK: - Private Views
    
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
    
    private var managerHeaderSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                // Profile Picture with Cache
                ZStack {
                    Circle()
                        .fill(Color.ksrLightGray)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.ksrYellow, lineWidth: 2)
                        )
                    
                    // Profile Image
                    Group {
                        if let profileImage = viewModel.profileImage {
                            // Cache'owane zdjęcie z ViewModel
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 75, height: 75)
                                .clipShape(Circle())
                        } else if let profilePictureUrl = viewModel.profileData.profilePictureUrl,
                                  !profilePictureUrl.isEmpty {
                            // Używaj ManagerCachedProfileImage dla loading
                            ManagerCachedProfileImage(
                                employeeId: AuthService.shared.getEmployeeId() ?? "",
                                currentImageUrl: profilePictureUrl,
                                size: 75
                            )
                        } else {
                            // Placeholder
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.ksrSecondary)
                        }
                    }
                    
                    // Plus button overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.ksrPrimary)
                                .background(Color.white)
                                .clipShape(Circle())
                                .offset(x: -4, y: -4)
                        }
                    }
                    .frame(width: 80, height: 80)
                    
                    // Upload progress overlay
                    if viewModel.isUploadingImage {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 80, height: 80)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                }
                .onTapGesture {
                    showingImagePicker = true
                }
                .contextMenu {
                    if viewModel.profileData.profilePictureUrl != nil {
                        Button(role: .destructive) {
                            viewModel.deleteProfilePicture()
                        } label: {
                            Label("Remove Picture", systemImage: "trash")
                        }
                    }
                    
                    Button {
                        viewModel.refreshProfileImage()
                    } label: {
                        Label("Refresh Picture", systemImage: "arrow.clockwise")
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.profileData.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .foregroundColor(Color.ksrYellow)
                            .font(.system(size: 14))
                        
                        Text("Manager")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let customer = viewModel.assignedCustomer {
                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundColor(Color.ksrInfo)
                                .font(.system(size: 14))
                            
                            Text(customer.name)
                                .font(.subheadline)
                                .foregroundColor(.ksrInfo)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                ManagerStatCard(
                    title: "Projects",
                    value: "\(viewModel.managementStats.assignedProjects)",
                    icon: "folder.fill",
                    color: .ksrInfo
                )
                
                ManagerStatCard(
                    title: "Workers",
                    value: "\(viewModel.managementStats.totalWorkers)",
                    icon: "person.3.fill",
                    color: .ksrSuccess
                )
                
                ManagerStatCard(
                    title: "Pending",
                    value: "\(viewModel.managementStats.pendingApprovals)",
                    icon: "clock.badge.exclamationmark",
                    color: .ksrWarning
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.1) : Color.white.opacity(0.8))
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.ksrYellow.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    private var tabNavigationSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ProfileTab.allCases) { tab in
                    ProfileTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(
            colorScheme == .dark ? Color(.systemGray6).opacity(0.1) : Color.white.opacity(0.5)
        )
    }
    
    private var tabContentSection: some View {
        Group {
            switch selectedTab {
            case .overview:
                ManagerOverviewTab(viewModel: viewModel)
            case .projects:
                ManagerProjectsTab(viewModel: viewModel)
            case .team:
                ManagerTeamTab(viewModel: viewModel)
            case .performance:
                ManagerPerformanceTab(viewModel: viewModel)
            case .settings:
                SettingsTabContent(showingLogoutConfirmation: $showingLogoutConfirmation)
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        ))
    }
    
    // MARK: - Private Methods
    
    private func performLogout() {
        print("🔄 Starting logout process...")
        
        AuthService.shared.logout()
        
        let keysToRemove = [
            "isLoggedIn", "userToken", "employeeId", "employeeName", "userRole",
            "loginTimestamp", "lastApiCall", "authToken", "refreshToken"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        
        ManagerAPIService.shared.authToken = nil
        WorkerAPIService.shared.authToken = nil
        
        viewModel.profileData = ManagerProfileData()  // 🔥 ZMIENIONY TYP
        viewModel.managementStats = ManagerStats()     // 🔥 ZMIENIONY TYP
        viewModel.profileImage = nil
        
        ProfileImageCache.shared.clearCache()
        
        DispatchQueue.main.async {
            self.navigateToLogin = true
        }
    }
}

// MARK: - Manager Stat Card

struct ManagerStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Manager Overview Tab

struct ManagerOverviewTab: View {
    @ObservedObject var viewModel: ManagerProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ProfileSectionCard(title: "Contract Status", icon: "doc.text.fill", color: .ksrSuccess) {
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading...")
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ContractStatusRow(
                            label: "Contract Type",
                            value: viewModel.profileData.contractType,
                            color: .ksrInfo
                        )
                        
                        ContractStatusRow(
                            label: "Assigned Since",
                            value: DateFormatter.mediumDate.string(from: viewModel.profileData.assignedSince),
                            color: .ksrSuccess
                        )
                        
                        if let endDate = viewModel.profileData.contractEndDate {
                            ContractStatusRow(
                                label: "Contract End",
                                value: DateFormatter.mediumDate.string(from: endDate),
                                color: endDate > Date().addingTimeInterval(30*24*60*60) ? .ksrSuccess : .ksrWarning
                            )
                        }
                    }
                }
            }
            
            ProfileSectionCard(title: "Current Assignments", icon: "briefcase.fill", color: .ksrInfo) {
                VStack(alignment: .leading, spacing: 12) {
                    AssignmentOverviewRow(
                        icon: "folder.fill",
                        label: "Active Projects",
                        value: "\(viewModel.managementStats.activeProjects) of \(viewModel.managementStats.assignedProjects)"
                    )
                    
                    AssignmentOverviewRow(
                        icon: "person.3.fill",
                        label: "Managed Workers",
                        value: "\(viewModel.managementStats.totalWorkers) operators"
                    )
                    
                    AssignmentOverviewRow(
                        icon: "list.bullet",
                        label: "Total Tasks",
                        value: "\(viewModel.managementStats.totalTasks) tasks"
                    )
                    
                    AssignmentOverviewRow(
                        icon: "clock.badge.exclamationmark",
                        label: "Pending Approvals",
                        value: "\(viewModel.managementStats.pendingApprovals) entries"
                    )
                }
            }
            
            // 🔥 ZMIENIONE - używa CertificationCard zamiast ExternalCertificationCard
            if !viewModel.profileData.certifications.isEmpty {
                ProfileSectionCard(title: "Certifications", icon: "award.fill", color: .ksrWarning) {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.profileData.certifications.prefix(3)) { cert in
                            CertificationCard(certification: cert)  // 🔥 ZMIENIONA NAZWA
                        }
                        
                        if viewModel.profileData.certifications.count > 3 {
                            Text("and \(viewModel.profileData.certifications.count - 3) more certifications...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Manager Projects Tab

struct ManagerProjectsTab: View {
    @ObservedObject var viewModel: ManagerProfileViewModel
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ProfileSectionCard(title: "Project Portfolio", icon: "folder.fill", color: .ksrInfo) {
                VStack(alignment: .leading, spacing: 12) {
                    ProjectSummaryRow(
                        label: "Total Assigned",
                        value: "\(viewModel.managementStats.assignedProjects)",
                        icon: "folder.fill",
                        color: .ksrInfo
                    )
                    
                    ProjectSummaryRow(
                        label: "Currently Active",
                        value: "\(viewModel.managementStats.activeProjects)",
                        icon: "play.circle.fill",
                        color: .ksrSuccess
                    )
                    
                    ProjectSummaryRow(
                        label: "Completed",
                        value: "\(viewModel.managementStats.projectsCompleted)",
                        icon: "checkmark.circle.fill",
                        color: .ksrSuccess
                    )
                }
            }
            
            if !viewModel.profileData.assignedProjects.isEmpty {
                ProfileSectionCard(title: "Assigned Projects", icon: "list.bullet", color: .ksrYellow) {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.profileData.assignedProjects.prefix(5)) { project in
                            ProjectAssignmentCard(project: project)
                        }
                        
                        if viewModel.profileData.assignedProjects.count > 5 {
                            Text("and \(viewModel.profileData.assignedProjects.count - 5) more projects...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Manager Team Tab

struct ManagerTeamTab: View {
    @ObservedObject var viewModel: ManagerProfileViewModel
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ProfileSectionCard(title: "Managed Team", icon: "person.3.fill", color: .ksrSuccess) {
                VStack(alignment: .leading, spacing: 12) {
                    TeamOverviewRow(
                        label: "Total Workers",
                        value: "\(viewModel.managementStats.totalWorkers)",
                        icon: "person.3.fill",
                        color: .ksrSuccess
                    )
                    
                    TeamOverviewRow(
                        label: "Active Assignments",
                        value: "\(viewModel.managementStats.totalTasks)",
                        icon: "list.clipboard",
                        color: .ksrInfo
                    )
                    
                    TeamOverviewRow(
                        label: "Pending Reviews",
                        value: "\(viewModel.managementStats.pendingApprovals)",
                        icon: "clock.badge.exclamationmark",
                        color: .ksrWarning
                    )
                }
            }
            
            if !viewModel.profileData.managedWorkers.isEmpty {
                ProfileSectionCard(title: "Team Members", icon: "person.circle", color: .ksrInfo) {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.profileData.managedWorkers.prefix(5)) { worker in
                            TeamMemberCard(worker: worker)
                        }
                        
                        if viewModel.profileData.managedWorkers.count > 5 {
                            Text("and \(viewModel.profileData.managedWorkers.count - 5) more team members...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Manager Performance Tab

struct ManagerPerformanceTab: View {
    @ObservedObject var viewModel: ManagerProfileViewModel
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ProfileSectionCard(title: "Performance Metrics", icon: "chart.bar.fill", color: .ksrWarning) {
                VStack(alignment: .leading, spacing: 12) {
                    PerformanceMetricRow(
                        metric: "Project Success Rate",
                        value: "\(Int(viewModel.managementStats.projectSuccessRate))%",
                        isPositive: viewModel.managementStats.projectSuccessRate >= 90
                    )
                    
                    PerformanceMetricRow(
                        metric: "Approval Response Time",
                        value: "\(Int(viewModel.managementStats.approvalResponseTime))h",
                        isPositive: viewModel.managementStats.approvalResponseTime <= 24
                    )
                    
                    PerformanceMetricRow(
                        metric: "Worker Satisfaction",
                        value: String(format: "%.1f/5.0", viewModel.managementStats.workerSatisfactionScore),
                        isPositive: viewModel.managementStats.workerSatisfactionScore >= 4.0
                    )
                }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Manager Edit Profile View

struct ManagerEditProfileView: View {
    @ObservedObject var viewModel: ManagerProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editableData: ManagerProfileData  // 🔥 ZMIENIONY TYP
    @State private var isUpdating = false
    
    init(viewModel: ManagerProfileViewModel) {
        self.viewModel = viewModel
        self._editableData = State(initialValue: viewModel.profileData)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("Email", text: $editableData.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone Number", text: Binding(
                        get: { editableData.phoneNumber ?? "" },
                        set: { editableData.phoneNumber = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section(header: Text("Manager Details")) {
                    HStack {
                        Text("Employee ID")
                        Spacer()
                        Text(editableData.employeeId)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Role")
                        Spacer()
                        Text(editableData.role)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { saveChanges() }.disabled(isUpdating)
            )
        }
    }
    
    private func saveChanges() {
        isUpdating = true
        viewModel.updateProfile(editableData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isUpdating = false
            dismiss()
        }
    }
}

// MARK: - Supporting Components

struct ContractStatusRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct AssignmentOverviewRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.ksrYellow)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

struct ProjectSummaryRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
    }
}

struct ProjectAssignmentCard: View {
    let project: ManagerAPIService.Project
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(1)
                
                if let customer = project.customer?.name {
                    Text(customer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(project.status?.rawValue.capitalized ?? "Unknown")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(project.statusColor.opacity(0.2))
                    )
                    .foregroundColor(project.statusColor)
                
                Text("\(project.tasks.count) tasks")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct TeamMemberCard: View {
    let worker: ManagerAPIService.Worker
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.ksrYellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(worker.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text("ID: \(worker.employee_id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(worker.assignedTasks.count) tasks")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.ksrInfo)
                
                Circle()
                    .fill(worker.assignedTasks.isEmpty ? Color.ksrSuccess : Color.ksrWarning)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
    }
}

struct TeamOverviewRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
    }
}

struct PerformanceMetricRow: View {
    let metric: String
    let value: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(metric)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: isPositive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(isPositive ? .ksrSuccess : .ksrWarning)
        }
    }
}

// MARK: - Extensions for Project Status Colors

extension ManagerAPIService.Project {
    var statusColor: Color {
        switch status {
        case .aktiv: return .ksrSuccess
        case .afsluttet: return .ksrMediumGray
        case .afventer: return .ksrWarning
        case .none: return .ksrMediumGray
        }
    }
}

// MARK: - Preview

struct ManagerProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ManagerProfileView()
                .preferredColorScheme(.light)
            ManagerProfileView()
                .preferredColorScheme(.dark)
        }
    }
}
