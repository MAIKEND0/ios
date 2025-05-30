//
//  KSR_Cranes_AppApp.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI
import PhotosUI

@main
struct KSR_Cranes_AppApp: App {
    // Użyj dedykowanego OrientationManagerDelegate
    @UIApplicationDelegateAdaptor(OrientationManagerDelegate.self) var appDelegate
    
    // ✨ DODANE: Globalny state manager
    @StateObject private var appStateManager = AppStateManager.shared
    
    var body: some Scene {
        WindowGroup {
            // ✨ UŻYWAJ PROSTSZEGO SYSTEMU BEZ SKOMPLIKOWANYCH ZALEŻNOŚCI
            SmartAppContainerView()
                .environmentObject(appStateManager)
                .environment(\.appStateManager, appStateManager)
        }
    }
}



// MARK: - Smart App Container - Uproszczony routing

struct SmartAppContainerView: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    @State private var showSplash = true
    
    var body: some View {
        Group {
            if showSplash {
                // Splash screen przez 2.5s
                EnhancedSplashScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                showSplash = false
                            }
                        }
                    }
            } else {
                // Główna aplikacja
                mainAppRouting
            }
        }
    }
    
    @ViewBuilder
    private var mainAppRouting: some View {
        if !AuthService.shared.isLoggedIn {
            // Nie zalogowany
            LoginView()
        } else if appStateManager.isLoadingInitialData {
            // Ładuje dane
            AppDataLoadingView()
        } else if let error = appStateManager.initializationError {
            // Błąd
            AppInitializationErrorView(error: error)
        } else if appStateManager.isAppInitialized {
            // Gotowe - główna aplikacja
            SmartMainAppRouter()
        } else {
            // Rozpocznij inicjalizację
            AppDataLoadingView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        appStateManager.initializeApp()
                    }
                }
        }
    }
}

// MARK: - Smart Main App Router (uproszczony)

struct SmartMainAppRouter: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        switch appStateManager.currentUserRole {
        case "arbejder":
            SmartWorkerMainView()
        case "byggeleder":
            SmartManagerMainView()
        case "chef":
            BossMainView()
        case "system":
            AdminMainView()
        default:
            UnauthorizedView()
        }
    }
}

// MARK: - Smart Worker Main View (używa globalnego stanu)

struct SmartWorkerMainView: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        TabView {
            WorkerDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            WorkerWorkHoursView()
                .tabItem {
                    Label("Hours", systemImage: "clock.fill")
                }
            
            WorkerTasksView()
                .tabItem {
                    Label("Tasks", systemImage: "list.bullet")
                }
            
            // ✨ UŻYWA GLOBALNEGO STANU
            SmartWorkerProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(Color.ksrYellow)
    }
}

// MARK: - Smart Manager Main View (używa globalnego stanu)

struct SmartManagerMainView: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        TabView {
            ManagerDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            ManagerProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "folder.fill")
                }
            
            ManagerWorkersView()
                .tabItem {
                    Label("Workers", systemImage: "person.3.fill")
                }
            
            ManagerWorkPlansView()
                .tabItem {
                    Label("Work Plans", systemImage: "calendar")
                }
            
            // ✨ UŻYWA GLOBALNEGO STANU
            SmartManagerProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(Color.ksrYellow)
    }
}

// MARK: - Smart Profile Views (używają globalnego stanu)

struct SmartWorkerProfileView: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        Group {
            if let workerProfileVM = appStateManager.workerProfileVM {
                // ✨ DANE JUŻ ZAŁADOWANE - UŻYWAJ ISTNIEJĄCEGO WorkerProfileView
                // ale przekaż mu gotowy ViewModel
                WorkerProfileViewWithPreloadedData(viewModel: workerProfileVM)
            } else {
                ProfileLoadingFallback(userType: "Worker")
            }
        }
    }
}

struct SmartManagerProfileView: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        Group {
            if let managerProfileVM = appStateManager.managerProfileVM {
                // ✨ DANE JUŻ ZAŁADOWANE - UŻYWAJ ISTNIEJĄCEGO ManagerProfileView
                // ale przekaż mu gotowy ViewModel
                ManagerProfileViewWithPreloadedData(viewModel: managerProfileVM)
            } else {
                ProfileLoadingFallback(userType: "Manager")
            }
        }
    }
}

// MARK: - Profile Views z preloaded data (modyfikacje istniejących)

struct WorkerProfileViewWithPreloadedData: View {
    @ObservedObject var viewModel: WorkerProfileViewModel
    @EnvironmentObject private var appStateManager: AppStateManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingLogoutConfirmation = false
    @State private var navigateToLogin = false
    @State private var showEditProfile = false
    @State private var selectedTab: WorkerProfileView.ProfileTab = .overview
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
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
                    
                    // ✨ REFRESH UŻYWA GLOBALNEGO MANAGERA
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appStateManager.refreshProfile()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(viewModel.isLoading)
                }
            )
            // ✅ USUNIĘTO .onAppear { viewModel.loadData() } - DANE JUŻ ZAŁADOWANE!
            .refreshable {
                // Pull-to-refresh używa globalnego managera
                await withCheckedContinuation { continuation in
                    appStateManager.refreshProfile()
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
    
    // SKOPIUJ WSZYSTKIE private var z WorkerProfileView
    private func performLogout() {
        AuthService.shared.logout()
        appStateManager.resetAppState()
        
        let keysToRemove = [
            "isLoggedIn", "userToken", "employeeId", "employeeName", "userRole"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        
        WorkerAPIService.shared.authToken = nil
        
        DispatchQueue.main.async {
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
                    
                    // ✨ CACHE'OWANE ZDJĘCIE - NIE ŁADUJE PONOWNIE!
                    if let profileImage = viewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 75, height: 75)
                            .clipShape(Circle())
                    } else if viewModel.basicData.profilePictureUrl != nil && !viewModel.basicData.profilePictureUrl!.isEmpty {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
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
                    
                    Button {
                        // ✨ UŻYWA GLOBALNEGO REFRESH
                        appStateManager.refreshProfile()
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
            
            // Stats Cards - dane już załadowane
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
                ForEach(WorkerProfileView.ProfileTab.allCases) { tab in
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

// MARK: - Manager Profile z preloaded data (podobnie jak Worker)

struct ManagerProfileViewWithPreloadedData: View {
    @ObservedObject var viewModel: ManagerProfileViewModel
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        // Użyj istniejący ManagerProfileView ale bez .onAppear { viewModel.loadData() }
        // i z globalnym refresh
        ManagerProfileContentView(viewModel: viewModel)
    }
}

struct ManagerProfileContentView: View {
    @ObservedObject var viewModel: ManagerProfileViewModel
    @EnvironmentObject private var appStateManager: AppStateManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingLogoutConfirmation = false
    @State private var navigateToLogin = false
    @State private var showEditProfile = false
    @State private var selectedTab: ManagerProfileView.ProfileTab = .overview
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
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
                    
                    // ✨ REFRESH UŻYWA GLOBALNEGO MANAGERA
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appStateManager.refreshProfile()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(viewModel.isLoading)
                }
            )
            // ✅ USUNIĘTO .onAppear { viewModel.loadData() } - DANE JUŻ ZAŁADOWANE!
            .refreshable {
                await withCheckedContinuation { continuation in
                    appStateManager.refreshProfile()
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
    
    private func performLogout() {
        AuthService.shared.logout()
        appStateManager.resetAppState()
        
        let keysToRemove = [
            "isLoggedIn", "userToken", "employeeId", "employeeName", "userRole"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        
        ManagerAPIService.shared.authToken = nil
        
        DispatchQueue.main.async {
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
    
    private var managerHeaderSection: some View {
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
                    
                    // ✨ CACHE'OWANE ZDJĘCIE - NIE ŁADUJE PONOWNIE!
                    if let profileImage = viewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 75, height: 75)
                            .clipShape(Circle())
                    } else if let profilePictureUrl = viewModel.profileData.profilePictureUrl,
                              !profilePictureUrl.isEmpty {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.ksrSecondary)
                    }
                    
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
                    if viewModel.profileImage != nil || viewModel.profileData.profilePictureUrl != nil {
                        Button(role: .destructive) {
                            viewModel.deleteProfilePicture()
                        } label: {
                            Label("Remove Picture", systemImage: "trash")
                        }
                    }
                    
                    Button {
                        appStateManager.refreshProfile()
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
                    title: "Assigned Projects",
                    value: "\(viewModel.managementStats.assignedProjects)",
                    icon: "folder.fill",
                    color: Color.ksrInfo
                )
                
                ManagerStatCard(
                    title: "Managed Workers",
                    value: "\(viewModel.managementStats.totalWorkers)",
                    icon: "person.3.fill",
                    color: Color.ksrSuccess
                )
                
                ManagerStatCard(
                    title: "Pending Approvals",
                    value: "\(viewModel.managementStats.pendingApprovals)",
                    icon: "clock.badge.exclamationmark",
                    color: Color.ksrWarning
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
                ForEach(ManagerProfileView.ProfileTab.allCases) { tab in
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
}

// MARK: - Pozostałe Views (bez zmian)

struct EnhancedSplashScreen: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var logoRotation: Double = -45
    @State private var titleOffset: CGFloat = 50
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var glowEffect: Bool = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.ksrDarkGray,
                    Color.ksrDarkGray.opacity(0.9),
                    Color.black.opacity(0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 32) {
                    ZStack {
                        if glowEffect {
                            Image("KSRLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160, height: 160)
                                .blur(radius: 20)
                                .opacity(0.3)
                        }
                        
                        Image("KSRLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .shadow(
                                color: glowEffect ? .ksrYellow.opacity(0.6) : .ksrYellow.opacity(0.2),
                                radius: glowEffect ? 30 : 15,
                                x: 0,
                                y: glowEffect ? 10 : 5
                            )
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .rotationEffect(.degrees(logoRotation))
                    
                    VStack(spacing: 12) {
                        Text("KSR CRANES")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(titleOpacity)
                            .offset(y: titleOffset)
                        
                        Text("Kranfører Udlejning")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .opacity(subtitleOpacity)
                            .offset(y: titleOffset * 0.7)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.ksrYellow)
                                .frame(width: 8, height: 8)
                                .scaleEffect(glowEffect ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: glowEffect
                                )
                        }
                    }
                    
                    Text("Initializing App...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .opacity(subtitleOpacity)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startEnhancedAnimationSequence()
        }
    }
    
    private func startEnhancedAnimationSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoOpacity = 1.0
                logoScale = 1.0
            }
            withAnimation(.easeOut(duration: 1.4)) {
                logoRotation = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                subtitleOpacity = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            glowEffect = true
        }
    }
}

struct AppDataLoadingView: View {
    @State private var loadingText = "Loading your data..."
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.ksrDarkGray.opacity(0.95),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Image("KSRLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .shadow(color: .ksrYellow.opacity(0.3), radius: 15, x: 0, y: 5)
                
                VStack(spacing: 24) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                        .scaleEffect(1.3)
                    
                    VStack(spacing: 12) {
                        Text(loadingText)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("This may take a moment")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding()
        }
    }
}

struct AppInitializationErrorView: View {
    let error: String
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        ZStack {
            Color.ksrDarkGray.ignoresSafeArea()
            
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.ksrError)
                    
                    Image("KSRLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .opacity(0.6)
                }
                
                VStack(spacing: 16) {
                    Text("Failed to Initialize")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    Button(action: {
                        appStateManager.initializeApp()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry Initialization")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.ksrYellow)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        AuthService.shared.logout()
                        appStateManager.resetAppState()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left.circle")
                            Text("Return to Login")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .underline()
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding()
        }
    }
}

struct ProfileLoadingFallback: View {
    let userType: String
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                .scaleEffect(1.2)
            
            Text("Loading \(userType) Profile...")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Initializing profile data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                appStateManager.initializeApp()
            }
        }
    }
}
