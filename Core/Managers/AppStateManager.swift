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
