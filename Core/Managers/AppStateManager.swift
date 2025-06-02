// Core/Managers/AppStateManager.swift
import SwiftUI
import Combine
import Foundation

/// Globalny menedżer stanu aplikacji - ładuje dane raz na starcie
class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    // MARK: - Published Properties
    @Published var isAppInitialized = false
    @Published var isLoadingInitialData = false
    @Published var initializationError: String?
    
    // Profile data cache dla różnych ról
    @Published var workerProfileVM: WorkerProfileViewModel?
    @Published var managerProfileVM: ManagerProfileViewModel?
    
    // Shared data
    @Published var currentUserRole: String = ""
    @Published var currentUserId: String = ""
    @Published var currentUserName: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Prywatny init dla singletona
    }
    
    // MARK: - App Initialization
    
    /// Inicjalizuje aplikację z danymi użytkownika
    func initializeApp() {
        guard !isAppInitialized else {
            #if DEBUG
            print("[AppStateManager] ⚠️ App already initialized")
            #endif
            return
        }
        
        isLoadingInitialData = true
        initializationError = nil
        
        #if DEBUG
        print("[AppStateManager] 🚀 Starting app initialization...")
        #endif
        
        // Pobierz dane użytkownika z AuthService
        guard let userId = AuthService.shared.getEmployeeId(),
              let userName = AuthService.shared.getEmployeeName(),
              let userRole = AuthService.shared.getEmployeeRole() else {
            initializationError = "Unable to get user information"
            isLoadingInitialData = false
            return
        }
        
        currentUserId = userId
        currentUserName = userName
        currentUserRole = userRole
        
        #if DEBUG
        print("[AppStateManager] 👤 User info loaded: \(userName) (\(userRole))")
        #endif
        
        // Inicjalizuj odpowiedni Profile ViewModel na podstawie roli
        initializeUserProfile()
    }
    
    private func initializeUserProfile() {
        switch currentUserRole {
        case "arbejder":
            initializeWorkerProfile()
        case "byggeleder":
            initializeManagerProfile()
        default:
            // Dla innych ról na razie nie ładujemy profilu
            completeInitialization()
        }
    }
    
    private func initializeWorkerProfile() {
        #if DEBUG
        print("[AppStateManager] 👷‍♂️ Initializing worker profile...")
        #endif
        
        let workerVM = WorkerProfileViewModel()
        self.workerProfileVM = workerVM
        
        // Ładuj dane raz
        workerVM.loadData()
        
        // Czekaj na zakończenie ładowania
        workerVM.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.completeInitialization()
                }
            }
            .store(in: &cancellables)
    }
    
    private func initializeManagerProfile() {
        #if DEBUG
        print("[AppStateManager] 👔 Initializing manager profile...")
        #endif
        
        let managerVM = ManagerProfileViewModel()
        self.managerProfileVM = managerVM
        
        // Ładuj dane raz
        managerVM.loadData()
        
        // Czekaj na zakończenie ładowania
        managerVM.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.completeInitialization()
                }
            }
            .store(in: &cancellables)
    }
    
    private func completeInitialization() {
        DispatchQueue.main.async { [weak self] in
            self?.isLoadingInitialData = false
            self?.isAppInitialized = true
            
            #if DEBUG
            print("[AppStateManager] ✅ App initialization completed!")
            #endif
        }
    }
    
    // MARK: - Public Methods
    
    /// Force refresh profilu (np. po pull-to-refresh)
    func refreshProfile() {
        #if DEBUG
        print("[AppStateManager] 🔄 Force refreshing profile...")
        #endif
        
        switch currentUserRole {
        case "arbejder":
            workerProfileVM?.loadData()
            workerProfileVM?.refreshProfileImage()
        case "byggeleder":
            managerProfileVM?.loadData()
            managerProfileVM?.refreshProfileImage()
        default:
            break
        }
    }
    
    /// Resetuje stan aplikacji (przy logout)
    func resetAppState() {
        #if DEBUG
        print("[AppStateManager] 🧹 Resetting app state...")
        #endif
        
        isAppInitialized = false
        isLoadingInitialData = false
        initializationError = nil
        
        workerProfileVM = nil
        managerProfileVM = nil
        
        currentUserRole = ""
        currentUserId = ""
        currentUserName = ""
        
        cancellables.removeAll()
        
        // Wyczyść cache zdjęć
        ProfileImageCache.shared.clearCache()
    }
    
    /// Sprawdza czy użytkownik ma dostęp do aplikacji
    var hasValidUserSession: Bool {
        return AuthService.shared.isLoggedIn &&
               !currentUserId.isEmpty &&
               !currentUserRole.isEmpty
    }
}

// MARK: - SwiftUI Environment Key

struct AppStateManagerKey: EnvironmentKey {
    static let defaultValue = AppStateManager.shared
}

extension EnvironmentValues {
    var appStateManager: AppStateManager {
        get { self[AppStateManagerKey.self] }
        set { self[AppStateManagerKey.self] = newValue }
    }
}

// MARK: - Supporting Views

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
