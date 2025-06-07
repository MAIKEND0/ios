//
//  KSR_Cranes_AppApp.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI
import PhotosUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
struct KSR_Cranes_AppApp: App {
    // Use Firebase-enabled AppDelegate
    @UIApplicationDelegateAdaptor(FirebaseAppDelegate.self) var appDelegate
    
    // ✨ ZACHOWANY: Globalny state manager (ważny!)
    @StateObject private var appStateManager = AppStateManager.shared
    
    var body: some Scene {
        WindowGroup {
            // ✅ UŻYWAJ PROSTSZEGO SYSTEMU - TYLKO JEDEN LOADING
            AppContainerView()
                .environmentObject(appStateManager)
                .environment(\.appStateManager, appStateManager)
                .onAppear {
                    // Initialize auth handler for global error handling
                    AuthenticationHandler.initialize()
                }
        }
    }
}

// MARK: - App Container - POPRAWIONY żeby reagował na zmiany stanu logowania

struct AppContainerView: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    @State private var currentPhase: AppPhase = .splash
    @State private var hasCheckedAuth = false
    @State private var isLoggedIn = false  // ✅ DODANE: Lokalny stan autoryzacji
    @State private var authCheckTrigger = false  // ✅ DODANE: Trigger dla sprawdzania auth
    
    enum AppPhase {
        case splash                    // Piękny splash z animacjami
        case dataLoading              // Splash + data loading (bez dodatkowego ekranu)
        case readyToShow              // Gotowe do pokazania
        case showingApp               // Pokazujemy główną aplikację
    }
    
    var body: some View {
        ZStack {
            switch currentPhase {
            case .splash, .dataLoading:
                // ✅ JEDEN PIĘKNY SPLASH - bez dodatkowych loading screen'ów
                IntegratedSplashWithDataLoading(
                    currentPhase: $currentPhase,
                    appStateManager: appStateManager
                )
                .transition(.identity)
                
            case .readyToShow:
                // Krótka faza przejściowa
                TransitionView()
                    .transition(.opacity)
                
            case .showingApp:
                // Główna aplikacja
                mainAppContent
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .identity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPhase)
        .onAppear {
            startAppFlow()
        }
        // ✅ DODANE: Nasłuchuj zmian stanu logowania
        .onReceive(NotificationCenter.default.publisher(for: .didLoginUser)) { _ in
            #if DEBUG
            print("[AppContainerView] 🔔 Received login success notification")
            #endif
            handleSuccessfulLogin()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogoutUser)) { _ in
            #if DEBUG
            print("[AppContainerView] 🔔 Received logout notification")
            #endif
            handleLogout()
        }
        // ✅ DODANE: Monitoruj zmiany stanu autoryzacji
        .onChange(of: authCheckTrigger) { _, _ in
            recheckAuthenticationState()
        }
    }
    
    @ViewBuilder
    private var mainAppContent: some View {
        if !isLoggedIn {
            // Nie zalogowany - LOGIN VIEW
            LoginView()
                .onAppear {
                    #if DEBUG
                    print("[AppContainerView] 🔄 Showing LoginView - user not logged in")
                    #endif
                }
        } else if let error = appStateManager.initializationError {
            // ✅ FIXED: Błąd inicjalizacji - inline error view
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.red)
                    
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.ksrDarkGray)
        } else if appStateManager.isAppInitialized {
            // Gotowe - główna aplikacja
            MainAppRouter()
                .onAppear {
                    #if DEBUG
                    print("[AppContainerView] 🔄 Showing MainAppRouter - user logged in and initialized")
                    #endif
                }
        } else {
            // Fallback - ładowanie
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                Text("Loading...")
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
    }
    
    private func startAppFlow() {
        #if DEBUG
        print("[AppContainerView] 🚀 Starting app flow...")
        #endif
        
        // Sprawdź autoryzację tylko raz na początku
        if !hasCheckedAuth {
            hasCheckedAuth = true
            checkAuthenticationAndProceed()
        }
    }
    
    // ✅ NOWA FUNKCJA: Obsługa pomyślnego logowania
    private func handleSuccessfulLogin() {
        #if DEBUG
        print("[AppContainerView] 🎉 Handling successful login...")
        #endif
        
        // Aktualizuj lokalny stan
        isLoggedIn = true
        
        // Przejdź do fazy ładowania danych
        DispatchQueue.main.async {
            if self.currentPhase == .showingApp {
                // Jeśli aktualnie pokazujemy LoginView, przejdź do ładowania
                self.currentPhase = .dataLoading
                self.startDataLoadingPhase()
            }
        }
    }
    
    // ✅ NOWA FUNKCJA: Obsługa wylogowania
    private func handleLogout() {
        #if DEBUG
        print("[AppContainerView] 👋 Handling logout...")
        #endif
        
        // Aktualizuj lokalny stan
        isLoggedIn = false
        
        // Resetuj fazę do splash
        DispatchQueue.main.async {
            self.currentPhase = .splash
            self.hasCheckedAuth = false
            
            // Po krótkiej pauzie sprawdź auth ponownie
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.startAppFlow()
            }
        }
    }
    
    // ✅ NOWA FUNKCJA: Ponowne sprawdzenie stanu autoryzacji
    private func recheckAuthenticationState() {
        #if DEBUG
        print("[AppContainerView] 🔄 Rechecking authentication state...")
        #endif
        
        let currentAuthState = AuthService.shared.isLoggedIn
        
        if currentAuthState != isLoggedIn {
            #if DEBUG
            print("[AppContainerView] 🔄 Auth state changed: \(isLoggedIn) -> \(currentAuthState)")
            #endif
            
            isLoggedIn = currentAuthState
            
            if currentAuthState {
                handleSuccessfulLogin()
            } else {
                handleLogout()
            }
        }
    }
    
    private func checkAuthenticationAndProceed() {
        let authResult = AuthService.shared.isLoggedIn
        isLoggedIn = authResult  // ✅ DODANE: Aktualizuj lokalny stan
        
        #if DEBUG
        print("[AppContainerView] 🔐 Auth check result: \(authResult ? "LOGGED IN" : "NOT LOGGED IN")")
        if authResult {
            print("[AppContainerView] 👤 User: \(AuthService.shared.getEmployeeName() ?? "Unknown")")
            print("[AppContainerView] 🎭 Role: \(AuthService.shared.getEmployeeRole() ?? "Unknown")")
        }
        #endif
        
        if authResult {
            // Użytkownik zalogowany - uruchom inicjalizację i pokaż splash
            startDataLoadingPhase()
        } else {
            // Użytkownik nie zalogowany - pokaż splash, potem login
            showSplashThenLogin()
        }
    }
    
    private func startDataLoadingPhase() {
        #if DEBUG
        print("[AppContainerView] 📊 Starting data loading phase for logged in user...")
        #endif
        
        // Faza 1: Splash animations (2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            currentPhase = .dataLoading
            
            // Rozpocznij ładowanie danych PODCZAS splash'a
            appStateManager.initializeApp()
            
            // Monitoruj zakończenie ładowania
            observeDataLoadingCompletion()
        }
    }
    
    private func showSplashThenLogin() {
        #if DEBUG
        print("[AppContainerView] 🔑 Showing splash then login for non-logged user...")
        #endif
        
        // Pokaż splash przez 3 sekundy, potem login
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            currentPhase = .readyToShow
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentPhase = .showingApp
            }
        }
    }
    
    private func observeDataLoadingCompletion() {
        #if DEBUG
        print("[AppContainerView] 👀 Starting to observe data loading completion...")
        #endif
        
        // Użyj prostego sprawdzania co sekundę zamiast co 0.1s
        var checkCount = 0
        let maxChecks = 10 // Maksymalnie 10 sekund
        
        func checkDataStatus() {
            checkCount += 1
            
            #if DEBUG
            print("[AppContainerView] 🔍 Data check \(checkCount)/\(maxChecks)")
            print("[AppContainerView] 🔍 - isAppInitialized: \(appStateManager.isAppInitialized)")
            print("[AppContainerView] 🔍 - isLoadingInitialData: \(appStateManager.isLoadingInitialData)")
            print("[AppContainerView] 🔍 - initializationError: \(appStateManager.initializationError != nil)")
            #endif
            
            if appStateManager.isAppInitialized || appStateManager.initializationError != nil {
                // Dane gotowe lub błąd - pokaż aplikację
                #if DEBUG
                print("[AppContainerView] ✅ Data loading completed, transitioning to app...")
                #endif
                
                DispatchQueue.main.async {
                    currentPhase = .readyToShow
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        currentPhase = .showingApp
                    }
                }
                return
            }
            
            // Jeśli przekroczono limit czasowy - force show
            if checkCount >= maxChecks {
                #if DEBUG
                print("[AppContainerView] ⏰ Timeout reached, forcing app display...")
                #endif
                
                DispatchQueue.main.async {
                    currentPhase = .showingApp
                }
                return
            }
            
            // Kontynuuj sprawdzanie za sekundę
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                checkDataStatus()
            }
        }
        
        // Rozpocznij sprawdzanie
        checkDataStatus()
    }
}

// MARK: - OPTIMIZED Integrated Splash With Data Loading

struct IntegratedSplashWithDataLoading: View {
    @Binding var currentPhase: AppContainerView.AppPhase
    let appStateManager: AppStateManager
    
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var logoRotation: Double = -45
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var loadingOpacity: Double = 0
    @State private var copyrightOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    
    // ✅ SIMPLIFIED - removed heavy particle animations
    @State private var showProgressIndicator = false
    
    var body: some View {
        ZStack {
            // ✅ SIMPLIFIED gradient - much lighter
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.ksrDarkGray,
                    Color.black.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // MARK: - SIMPLIFIED Logo Section
                VStack(spacing: 24) {
                    ZStack {
                        // ✅ SIMPLIFIED glow effect
                        Image("KSRLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .opacity(glowOpacity * 0.2)
                            .blur(radius: 8)
                            .foregroundColor(.ksrYellow)
                        
                        // Main logo - SIMPLIFIED shadows
                        Image("KSRLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .shadow(color: .ksrYellow.opacity(0.3), radius: 8, x: 0, y: 4)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                            .rotationEffect(.degrees(logoRotation))
                    }
                    
                    // Company branding
                    VStack(spacing: 12) {
                        Text("KSR CRANES")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(titleOpacity)
                            .offset(y: titleOffset)
                            .scaleEffect(titleOpacity)
                        
                        Text("Kranfører Udlejning")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(titleOpacity * 0.8)
                            .offset(y: titleOffset * 0.5)
                        
                        // Simple underline
                        if titleOpacity > 0.5 {
                            Rectangle()
                                .fill(Color.ksrYellow)
                                .frame(width: titleOpacity * 180, height: 2)
                                .opacity(titleOpacity)
                                .animation(.easeInOut(duration: 0.6), value: titleOpacity)
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - SIMPLIFIED Loading Section
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        if showProgressIndicator {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                                .scaleEffect(0.9)
                        }
                        
                        Text(dynamicLoadingText)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .animation(.easeInOut(duration: 0.3), value: dynamicLoadingText)
                    }
                    .opacity(loadingOpacity)
                }
                .padding(.bottom, 20)
                
                // Copyright
                Text("© 2025 KSR Cranes")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .opacity(copyrightOpacity)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startOptimizedAnimationSequence()
        }
    }
    
    private var dynamicLoadingText: String {
        if currentPhase == .splash {
            return "Initializing..."
        } else if appStateManager.isLoadingInitialData {
            return "Loading your workspace..."
        } else if appStateManager.initializationError != nil {
            return "Initialization failed"
        } else if appStateManager.isAppInitialized {
            return "Ready!"
        } else {
            return "Preparing..."
        }
    }
    
    // ✅ OPTIMIZED animation sequence - faster, lighter
    private func startOptimizedAnimationSequence() {
        // Phase 1: Logo entrance - FASTER
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.8)) {
                logoRotation = 360
            }
            
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                glowOpacity = 1.0
            }
        }
        
        // Phase 2: Title animation - FASTER
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.5)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
        }
        
        // Phase 3: Loading indicator - FASTER
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 0.3)) {
                loadingOpacity = 1.0
                showProgressIndicator = true
            }
        }
        
        // Phase 4: Copyright - FASTER
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeInOut(duration: 0.3)) {
                copyrightOpacity = 1.0
            }
        }
    }
}

// MARK: - Simple Transition View
struct TransitionView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack {
                Image("KSRLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .opacity(0.8)
            }
        }
    }
}

// MARK: - Main App Router - FIXED VERSION WITH PROPER ROLE ISOLATION
struct MainAppRouter: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        Group {
            // ✅ DODANE: Defensywne sprawdzenie
            if appStateManager.currentUserRole.isEmpty {
                // Fallback gdy nie ma roli - pokaż loading lub error
                VStack {
                    ProgressView("Loading user data...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                    
                    Text("Determining user role...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .onAppear {
                    // ✅ FIXED: Spróbuj ponownie pobrać rolę - używaj publicznej metody
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // Bezpośrednio wywołaj refresh bez private metod
                        appStateManager.initializeApp()
                    }
                }
            } else {
                // Główny routing na podstawie roli
                roleBasedContent
            }
        }
        .onAppear {
            #if DEBUG
            print("[MainAppRouter] 🔄 Showing router for role: '\(appStateManager.currentUserRole)'")
            appStateManager.debugState()
            #endif
        }
    }
    
    @ViewBuilder
    private var roleBasedContent: some View {
        switch appStateManager.currentUserRole.lowercased() {
        case "arbejder":
            WorkerMainViewWithState()
                .onAppear {
                    #if DEBUG
                    print("[MainAppRouter] 👷‍♂️ Showing Worker interface")
                    #endif
                }
            
        case "byggeleder":
            ManagerMainViewWithState()
                .onAppear {
                    #if DEBUG
                    print("[MainAppRouter] 👔 Showing Manager interface")
                    #endif
                }
            
        case "chef":
            BossMainViewFixed()  // ✅ UŻYWAJ FIXED VERSION!
                .onAppear {
                    #if DEBUG
                    print("[MainAppRouter] 👨‍💼 Showing Boss/Chef interface")
                    #endif
                }
            
        case "system":
            AdminMainView()
                .onAppear {
                    #if DEBUG
                    print("[MainAppRouter] ⚙️ Showing Admin interface")
                    #endif
                }
            
        default:
            UnauthorizedView()
                .onAppear {
                    #if DEBUG
                    print("[MainAppRouter] ❌ Unknown role: '\(appStateManager.currentUserRole)' - showing unauthorized")
                    #endif
                }
        }
    }
}

// ✅ NOWA WERSJA: BossMainView z lepszą izolacją
struct BossMainViewFixed: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChefDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: selectedTab == 0 ? "chart.bar.fill" : "chart.bar")
                }
                .tag(0)
            
            CustomersListView()
                .tabItem {
                    Label("Customers", systemImage: selectedTab == 1 ? "building.2.fill" : "building.2")
                }
                .tag(1)
            
            ChefProjectsView()
                .tabItem {
                    Label("Projects", systemImage: selectedTab == 2 ? "folder.fill" : "folder")
                }
                .tag(2)
            
            ChefWorkersManagementView() // ✅ DODANE: Dedykowany widok dla chef'a
                .tabItem {
                    Label("Workers", systemImage: selectedTab == 3 ? "person.3.fill" : "person.3")
                }
                .tag(3)
            
            ChefTasksView() // ✅ DODANE: Dedykowany widok dla chef'a
                .tabItem {
                    Label("Tasks", systemImage: selectedTab == 4 ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                }
                .tag(4)
            
            ChefProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 5 ? "person.fill" : "person")
                }
                .tag(5)
        }
        .accentColor(Color.ksrYellow)
        .onAppear {
            setupTabBarAppearance()
            
            #if DEBUG
            print("[BossMainViewFixed] 👨‍💼 Chef interface loaded")
            #endif
        }
    }
}


struct ChefTasksView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "list.bullet.rectangle.badge.gearshape")
                    .font(.system(size: 60))
                    .foregroundColor(.ksrYellow)
                
                VStack(spacing: 12) {
                    Text("Tasks Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Monitor and manage all project tasks")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Text("Coming in v1.1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Tasks")
        }
    }
}

// ✅ DODANE: Debug view dla sprawdzenia routing'u
#if DEBUG
struct RoleDebugView: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Role Debug")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Role: '\(appStateManager.currentUserRole)'")
                Text("User ID: '\(appStateManager.currentUserId)'")
                Text("User Name: '\(appStateManager.currentUserName)'")
                Text("Auth Role: '\(AuthService.shared.getEmployeeRole() ?? "nil")'")
                Text("Auth Name: '\(AuthService.shared.getEmployeeName() ?? "nil")'")
            }
            .font(.caption)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Button("Refresh State") {
                appStateManager.initializeApp()
            }
            .buttonStyle(.bordered)
            
            Button("Debug Full State") {
                appStateManager.debugState()
                AuthService.shared.debugAuthenticationState()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
#endif

// MARK: - Worker Main View With State
struct WorkerMainViewWithState: View {
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
            
            WorkerLeaveView()
                .tabItem {
                    Label("Leave", systemImage: "calendar.badge.clock")
                }
            
            WorkerProfileViewWithState()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(Color.ksrYellow)
    }
}

// MARK: - Manager Main View With State
struct ManagerMainViewWithState: View {
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
            
            ManagerProfileViewWithState()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(Color.ksrYellow)
    }
}

// MARK: - Profile Views With State
struct WorkerProfileViewWithState: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        Group {
            if let workerProfileVM = appStateManager.workerProfileVM {
                WorkerProfileViewWithPreloadedData(viewModel: workerProfileVM)
            } else {
                // ✅ FIXED: Inline ProfileLoadingFallback
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                        .scaleEffect(1.2)
                    
                    Text("Loading Worker Profile...")
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
    }
}

struct ManagerProfileViewWithState: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        Group {
            if let managerProfileVM = appStateManager.managerProfileVM {
                ManagerProfileViewWithPreloadedData(viewModel: managerProfileVM)
            } else {
                // ✅ FIXED: Inline ProfileLoadingFallback
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                        .scaleEffect(1.2)
                    
                    Text("Loading Manager Profile...")
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
    }
}

// MARK: - Worker Profile View Components

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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                                appStateManager.refreshProfile()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
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
                    if viewModel.profileImage != nil || viewModel.basicData.profilePictureUrl != nil {
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

// MARK: - Manager Profile z preloaded data (zachowany bez zmian)
struct ManagerProfileViewWithPreloadedData: View {
    @ObservedObject var viewModel: ManagerProfileViewModel
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                                appStateManager.refreshProfile()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
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

// MARK: - Firebase AppDelegate

class FirebaseAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set FCM messaging delegate
        Messaging.messaging().delegate = self
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        #if DEBUG
        print("[FirebaseAppDelegate] Firebase configured and push notifications initialized")
        #endif
        
        return true
    }
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication, 
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        #if DEBUG
        print("[FirebaseAppDelegate] APNs token received")
        #endif
        
        // Set APNs token for FCM
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, 
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("[FirebaseAppDelegate] Failed to register for remote notifications: \(error)")
        #endif
    }
    
    // MARK: - MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        #if DEBUG
        print("[FirebaseAppDelegate] FCM token received: \(fcmToken ?? "nil")")
        #endif
        
        guard let fcmToken = fcmToken else { return }
        
        // Register token with our push notification service
        Task { @MainActor in
            await PushNotificationService.shared.registerToken(fcmToken)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        #if DEBUG
        print("[FirebaseAppDelegate] Notification tapped: \(userInfo)")
        #endif
        
        // Handle notification tap
        Task { @MainActor in
            PushNotificationService.shared.handleNotificationTap(userInfo)
        }
        
        completionHandler()
    }
}
