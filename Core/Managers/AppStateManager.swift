// Core/Managers/AppStateManager.swift - FIXED VERSION
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
    
    // Leave management ViewModels
    @Published var workerLeaveVM: WorkerLeaveRequestViewModel?
    @Published var chefLeaveVM: ChefLeaveManagementViewModel?
    
    // Push notification service
    @Published var pushNotificationService: PushNotificationService
    
    // ✅ DODANE: Wymuszone odświeżenie roli
    @Published var currentUserRole: String = "" {
        didSet {
            if oldValue != currentUserRole && !oldValue.isEmpty {
                #if DEBUG
                print("[AppStateManager] 🔄 Role changed from '\(oldValue)' to '\(currentUserRole)' - clearing incompatible data")
                #endif
                clearIncompatibleRoleData(oldRole: oldValue, newRole: currentUserRole)
            }
        }
    }
    @Published var currentUserId: String = ""
    @Published var currentUserName: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Prywatny init dla singletona
        pushNotificationService = PushNotificationService.shared
        setupAuthObservers()
    }
    
    // ✅ DODANE: Obserwator zmian autoryzacji
    private func setupAuthObservers() {
        // Nasłuchuj logout
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogout),
            name: .didLogoutUser,
            object: nil
        )
        
        // Nasłuchuj login
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogin),
            name: .didLoginUser,
            object: nil
        )
    }
    
    @objc private func handleLogout() {
        #if DEBUG
        print("[AppStateManager] 🚪 Handling logout notification")
        #endif
        DispatchQueue.main.async {
            self.resetAppState()
        }
    }
    
    @objc private func handleLogin(notification: Notification) {
        #if DEBUG
        print("[AppStateManager] 🎉 Handling login notification")
        #endif
        
        // Wymuś odświeżenie danych użytkownika
        DispatchQueue.main.async {
            self.refreshUserDataFromAuth()
        }
    }
    
    // ✅ DODANE: Odświeżenie danych z AuthService
    private func refreshUserDataFromAuth() {
        guard let userId = AuthService.shared.getEmployeeId(),
              let userName = AuthService.shared.getEmployeeName(),
              let userRole = AuthService.shared.getEmployeeRole() else {
            #if DEBUG
            print("[AppStateManager] ❌ Cannot refresh user data - missing auth info")
            #endif
            return
        }
        
        #if DEBUG
        print("[AppStateManager] 🔄 Refreshing user data from AuthService")
        print("[AppStateManager] 👤 New user: \(userName) (\(userRole))")
        #endif
        
        currentUserId = userId
        currentUserName = userName
        currentUserRole = userRole
        
        // Reset initialization state
        isAppInitialized = false
        initializationError = nil
    }
    
    // ✅ DODANE: Czyszczenie danych niekompatybilnych z nową rolą
    private func clearIncompatibleRoleData(oldRole: String, newRole: String) {
        switch oldRole {
        case "arbejder":
            if newRole != "arbejder" {
                workerProfileVM = nil
                workerLeaveVM = nil
                #if DEBUG
                print("[AppStateManager] 🧹 Cleared worker profile and leave data")
                #endif
            }
        case "byggeleder", "chef":
            if newRole != "byggeleder" && newRole != "chef" {
                managerProfileVM = nil
                chefLeaveVM = nil
                #if DEBUG
                print("[AppStateManager] 🧹 Cleared manager profile and chef leave data")
                #endif
            }
        default:
            break
        }
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
        
        // ✅ POPRAWIONE: Zawsze pobieraj świeże dane z AuthService
        refreshUserDataFromAuth()
        
        guard !currentUserId.isEmpty && !currentUserRole.isEmpty else {
            initializationError = "Unable to get user information"
            isLoadingInitialData = false
            #if DEBUG
            print("[AppStateManager] ❌ Initialization failed - missing user data")
            #endif
            return
        }
        
        #if DEBUG
        print("[AppStateManager] 👤 User info loaded: \(currentUserName) (\(currentUserRole))")
        #endif
        
        // Inicjalizuj odpowiedni Profile ViewModel na podstawie roli
        initializeUserProfile()
        
        // Inicjalizuj push notifications
        initializePushNotifications()
    }
    
    private func initializeUserProfile() {
        #if DEBUG
        print("[AppStateManager] 🔧 Initializing profile for role: \(currentUserRole)")
        #endif
        
        Task { @MainActor in
            switch currentUserRole {
            case "arbejder":
                initializeWorkerProfile()
            case "byggeleder":
                initializeManagerProfile()
            case "chef":
                initializeChefProfile()
            case "system":
                // Dla system nie ładujemy profilu, tylko kończymy inicjalizację
                #if DEBUG
                print("[AppStateManager] ℹ️ Role 'system' - skipping profile initialization")
                #endif
                completeInitialization()
            default:
                #if DEBUG
                print("[AppStateManager] ⚠️ Unknown role: '\(currentUserRole)' - completing without profile")
                #endif
                completeInitialization()
            }
        }
    }
    
    @MainActor
    private func initializeWorkerProfile() {
        #if DEBUG
        print("[AppStateManager] 👷‍♂️ Initializing worker profile and leave data...")
        #endif
        
        // ✅ POPRAWIONE: Zawsze utwórz nowy ViewModel dla nowej sesji
        let workerVM = WorkerProfileViewModel()
        self.workerProfileVM = workerVM
        
        // Initialize worker leave ViewModel
        let workerLeaveVM = WorkerLeaveRequestViewModel()
        self.workerLeaveVM = workerLeaveVM
        
        // Ładuj dane raz
        workerVM.loadData()
        workerLeaveVM.loadInitialData()
        
        // Czekaj na zakończenie ładowania obu ViewModels
        Publishers.CombineLatest(workerVM.$isLoading, workerLeaveVM.$isLoading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profileLoading, leaveLoading in
                if !profileLoading && !leaveLoading {
                    self?.completeInitialization()
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func initializeManagerProfile() {
        #if DEBUG
        print("[AppStateManager] 👔 Initializing manager profile and leave data...")
        #endif
        
        // ✅ POPRAWIONE: Zawsze utwórz nowy ViewModel dla nowej sesji
        let managerVM = ManagerProfileViewModel()
        self.managerProfileVM = managerVM
        
        // Initialize chef leave ViewModel (managers can also manage leave)
        let chefLeaveVM = ChefLeaveManagementViewModel()
        self.chefLeaveVM = chefLeaveVM
        
        // Ładuj dane raz
        managerVM.loadData()
        chefLeaveVM.loadInitialData()
        
        // Czekaj na zakończenie ładowania obu ViewModels
        Publishers.CombineLatest(managerVM.$isLoading, chefLeaveVM.$isLoading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profileLoading, leaveLoading in
                if !profileLoading && !leaveLoading {
                    self?.completeInitialization()
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func initializeChefProfile() {
        #if DEBUG
        print("[AppStateManager] 👨‍💼 Initializing chef leave management...")
        #endif
        
        // Chef primarily uses leave management ViewModel
        let chefLeaveVM = ChefLeaveManagementViewModel()
        self.chefLeaveVM = chefLeaveVM
        
        // Ładuj dane raz
        chefLeaveVM.loadInitialData()
        
        // Czekaj na zakończenie ładowania
        chefLeaveVM.$isLoading
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
            print("[AppStateManager] 📊 Final state:")
            print("[AppStateManager]   - User: \(self?.currentUserName ?? "Unknown")")
            print("[AppStateManager]   - Role: \(self?.currentUserRole ?? "Unknown")")
            print("[AppStateManager]   - Worker Profile: \(self?.workerProfileVM != nil ? "Loaded" : "None")")
            print("[AppStateManager]   - Manager Profile: \(self?.managerProfileVM != nil ? "Loaded" : "None")")
            #endif
        }
    }
    
    // MARK: - Public Methods
    
    /// Force refresh profilu (np. po pull-to-refresh)
    func refreshProfile() {
        #if DEBUG
        print("[AppStateManager] 🔄 Force refreshing profile and leave data...")
        #endif
        
        Task { @MainActor in
            switch currentUserRole {
            case "arbejder":
                workerProfileVM?.loadData()
                workerProfileVM?.refreshProfileImage()
                workerLeaveVM?.refreshData()
            case "byggeleder":
                managerProfileVM?.loadData()
                managerProfileVM?.refreshProfileImage()
                chefLeaveVM?.refreshData()
            case "chef":
                chefLeaveVM?.refreshData()
            default:
                #if DEBUG
                print("[AppStateManager] ℹ️ No profile to refresh for role: \(currentUserRole)")
                #endif
                break
            }
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
        workerLeaveVM = nil
        chefLeaveVM = nil
        
        currentUserRole = ""
        currentUserId = ""
        currentUserName = ""
        
        cancellables.removeAll()
        
        // Wyczyść cache zdjęć
        ProfileImageCache.shared.clearCache()
        
        #if DEBUG
        print("[AppStateManager] ✅ App state reset complete")
        #endif
    }
    
    /// Sprawdza czy użytkownik ma dostęp do aplikacji
    var hasValidUserSession: Bool {
        let isValid = AuthService.shared.isLoggedIn &&
               !currentUserId.isEmpty &&
               !currentUserRole.isEmpty
        
        #if DEBUG
        print("[AppStateManager] 🔍 Session validation:")
        print("[AppStateManager]   - Auth logged in: \(AuthService.shared.isLoggedIn)")
        print("[AppStateManager]   - User ID: \(currentUserId.isEmpty ? "EMPTY" : "SET")")
        print("[AppStateManager]   - User Role: \(currentUserRole.isEmpty ? "EMPTY" : currentUserRole)")
        print("[AppStateManager]   - Valid: \(isValid)")
        #endif
        
        return isValid
    }
    
    // ✅ DODANE: Debug method
    #if DEBUG
    func debugState() {
        print("[AppStateManager] 🔍 === APP STATE MANAGER DEBUG ===")
        print("[AppStateManager] 🔍 isAppInitialized: \(isAppInitialized)")
        print("[AppStateManager] 🔍 isLoadingInitialData: \(isLoadingInitialData)")
        print("[AppStateManager] 🔍 initializationError: \(initializationError ?? "none")")
        print("[AppStateManager] 🔍 currentUserRole: '\(currentUserRole)'")
        print("[AppStateManager] 🔍 currentUserId: '\(currentUserId)'")
        print("[AppStateManager] 🔍 currentUserName: '\(currentUserName)'")
        print("[AppStateManager] 🔍 workerProfileVM: \(workerProfileVM != nil ? "EXISTS" : "NIL")")
        print("[AppStateManager] 🔍 managerProfileVM: \(managerProfileVM != nil ? "EXISTS" : "NIL")")
        print("[AppStateManager] 🔍 workerLeaveVM: \(workerLeaveVM != nil ? "EXISTS" : "NIL")")
        print("[AppStateManager] 🔍 chefLeaveVM: \(chefLeaveVM != nil ? "EXISTS" : "NIL")")
        print("[AppStateManager] 🔍 hasValidUserSession: \(hasValidUserSession)")
        print("[AppStateManager] 🔍 === END DEBUG ===")
    }
    #endif
    
    // MARK: - Push Notifications
    
    private func initializePushNotifications() {
        Task {
            // Request permission if not already granted
            await pushNotificationService.requestPermission()
            
            // Register any stored token now that user is logged in
            await pushNotificationService.registerStoredTokenIfNeeded()
            
            #if DEBUG
            print("[AppStateManager] 🔔 Push notifications initialized and token registered")
            #endif
        }
    }
}

// MARK: - SwiftUI Environment Key (bez zmian)

struct AppStateManagerKey: EnvironmentKey {
    static let defaultValue = AppStateManager.shared
}

extension EnvironmentValues {
    var appStateManager: AppStateManager {
        get { self[AppStateManagerKey.self] }
        set { self[AppStateManagerKey.self] = newValue }
    }
}
