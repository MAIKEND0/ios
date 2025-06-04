// Features/Worker/Profile/WorkerProfileView.swift
import SwiftUI
import PhotosUI

struct WorkerProfileView: View {
    @StateObject private var viewModel = WorkerProfileViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingLogoutConfirmation = false
    @State private var navigateToLogin = false
    @State private var showEditProfile = false
    @State private var selectedTab: ProfileTab = .overview
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    enum ProfileTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case tasks = "Tasks"
        case hours = "Hours"
        case settings = "Settings"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .overview: return "person.circle.fill"
            case .tasks: return "list.bullet"
            case .hours: return "clock.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .overview: return .ksrYellow
            case .tasks: return .ksrInfo
            case .hours: return .ksrSuccess
            case .settings: return .ksrMediumGray
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    workerHeaderSection
                    
                    tabNavigationSection
                    
                    tabContentSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
            }
            .background(backgroundGradient)
            .navigationTitle("My Profile")
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
                            // 🆕 Także odśwież zdjęcie profilowe
                            viewModel.refreshProfileImage()
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
                    viewModel.refreshProfileImage() // 🆕 Odśwież też zdjęcie
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
                WorkerEditProfileView(viewModel: viewModel)
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
    
    private func performLogout() {
        AuthService.shared.logout()
        
        // Clear additional data
        let keysToRemove = [
            "isLoggedIn", "userToken", "employeeId", "employeeName", "userRole"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        
        // Clear API tokens
        WorkerAPIService.shared.authToken = nil
        
        // 🆕 Wyczyść cache zdjęć przy logowaie
        ProfileImageCache.shared.clearCache()
        
        DispatchQueue.main.async {
            self.viewModel.basicData = WorkerBasicData(employeeId: 0, name: "", email: "", role: "arbejder")
            self.viewModel.stats = WorkerStats(currentWeekHours: 0, currentMonthHours: 0, pendingEntries: 0, approvedEntries: 0, rejectedEntries: 0, approvalRate: 0)
            self.viewModel.currentTasks = []
            self.viewModel.recentWorkEntries = []
            self.navigateToLogin = true
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
    
    private var workerHeaderSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.ksrLightGray)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.ksrYellow, lineWidth: 2)
                        )
                    
                    // 🆕 Używaj cache'owanego zdjęcia z ViewModel
                    if let profileImage = viewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 75, height: 75)
                            .clipShape(Circle())
                    } else if viewModel.basicData.profilePictureUrl != nil && !viewModel.basicData.profilePictureUrl!.isEmpty {
                        // Pokaż placeholder podczas ładowania
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        // Brak zdjęcia
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.ksrSecondary)
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
                    if viewModel.profileImage != nil || viewModel.basicData.profilePictureUrl != nil {
                        Button(role: .destructive) {
                            viewModel.deleteProfilePicture()
                        } label: {
                            Label("Remove Picture", systemImage: "trash")
                        }
                    }
                    
                    // 🆕 Opcja do odświeżenia zdjęcia
                    Button {
                        viewModel.refreshProfileImage()
                    } label: {
                        Label("Refresh Picture", systemImage: "arrow.clockwise")
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.basicData.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(Color.ksrYellow)
                            .font(.system(size: 14))
                        
                        Text("Crane Operator")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(Color.ksrInfo)
                            .font(.system(size: 14))
                        
                        Text("ID: \(viewModel.basicData.employeeId)")
                            .font(.subheadline)
                            .foregroundColor(.ksrInfo)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Stats Cards
            HStack(spacing: 12) {
                WorkerStatCard(
                    title: "This Week",
                    value: "\(Int(viewModel.stats.currentWeekHours))h",
                    icon: "clock.fill",
                    color: .ksrSuccess
                )
                
                WorkerStatCard(
                    title: "Active Tasks",
                    value: "\(viewModel.currentTasks.count)",
                    icon: "list.bullet",
                    color: .ksrInfo
                )
                
                WorkerStatCard(
                    title: "Approval Rate",
                    value: "\(viewModel.stats.efficiencyPercentage)%",
                    icon: "checkmark.circle",
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
                    WorkerProfileTabButton(
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
                WorkerOverviewTab(viewModel: viewModel)
            case .tasks:
                WorkerTasksTab(viewModel: viewModel)
            case .hours:
                WorkerHoursTab(viewModel: viewModel)
            case .settings:
                WorkerSettingsTab(showingLogoutConfirmation: $showingLogoutConfirmation)
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        ))
    }
}

// MARK: - Preview

struct WorkerProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WorkerProfileView()
                .preferredColorScheme(.light)
            WorkerProfileView()
                .preferredColorScheme(.dark)
        }
    }
}
