//
//  AuthDebugger.swift
//  KSR Cranes App
//

import SwiftUI
import Combine

#if DEBUG
/// Przycisk debugowania dla widoków, który pozwala sprawdzić stan tokenów autoryzacji
struct AuthDebugButton: View {
    @State private var showingDebugInfo = false
    
    var body: some View {
        Button(action: {
            showingDebugInfo = true
        }) {
            Image(systemName: "key.fill")
                .foregroundColor(.yellow)
                .padding(8)
                .background(Circle().fill(Color.black.opacity(0.2)))
        }
        .alert("Informacje o tokenie", isPresented: $showingDebugInfo) {
            Button("OK", role: .cancel) { }
            Button("Odśwież token", role: .none) {
                AuthDebugger.shared.refreshToken()
            }
            if AuthDebugger.shared.hasTokenInMemory() || AuthDebugger.shared.hasTokenInKeychain() {
                Button("Testuj token", role: .none) {
                    AuthDebugger.shared.testToken()
                }
            }
        } message: {
            Text(AuthDebugger.shared.getTokenInfo())
        }
    }
}

/// Dodatkowy widok z przyciskiem debugowania dla łatwego dodania do innych widoków
struct DebugButtonOverlay: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                HStack {
                    Spacer()
                    AuthDebugButton()
                }
                .padding(.top, 35)
                .padding(.trailing, 15)
                Spacer()
            }
        }
    }
}

extension View {
    /// Dodaje przycisk debugowania tokenów do widoku
    func withAuthDebugging() -> some View {
        self.modifier(DebugButtonOverlay())
    }
}

/// Klasa do debugowania problemów z autoryzacją
class AuthDebugger {
    static let shared = AuthDebugger()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    /// Sprawdza, czy token istnieje w pamięci
    func hasTokenInMemory() -> Bool {
        let role = AuthService.shared.getEmployeeRole()
        switch role {
        case "byggeleder":
            return ManagerAPIService.shared.authToken != nil
        case "arbejder", "chef", "system":
            return WorkerAPIService.shared.authToken != nil
        default:
            return false
        }
    }
    
    /// Sprawdza, czy token istnieje w keychain
    func hasTokenInKeychain() -> Bool {
        return KeychainService.shared.getToken() != nil
    }
    
    /// Odświeża token z keychain do pamięci
    func refreshToken() {
        let role = AuthService.shared.getEmployeeRole()
        switch role {
        case "byggeleder":
            ManagerAPIService.shared.refreshTokenFromKeychain()
        case "arbejder", "chef", "system":
            WorkerAPIService.shared.refreshTokenFromKeychain()
        default:
            print("[AuthDebugger] Brak roli użytkownika, nie można odświeżyć tokenu")
        }
    }
    
    /// Zwraca informacje o tokenie
    func getTokenInfo() -> String {
        var info = ""
        let role = AuthService.shared.getEmployeeRole()
        
        // Informacje o tokenie w pamięci
        let token: String?
        switch role {
        case "byggeleder":
            token = ManagerAPIService.shared.authToken
        case "arbejder", "chef", "system":
            token = WorkerAPIService.shared.authToken
        default:
            token = nil
        }
        
        if let token = token {
            let preview = String(token.prefix(10)) + "..."
            info += "Token w pamięci: ✅\n\(preview)\n\n"
        } else {
            info += "Token w pamięci: ❌ Brak\n\n"
        }
        
        // Informacje o tokenie w keychain
        if let keychainToken = KeychainService.shared.getToken() {
            let preview = String(keychainToken.prefix(10)) + "..."
            info += "Token w keychain: ✅\n\(preview)\n\n"
        } else {
            info += "Token w keychain: ❌ Brak\n\n"
        }
        
        // Dodatkowe informacje
        info += "Zalogowany: \(AuthService.shared.isLoggedIn ? "✅" : "❌")\n"
        info += "ID pracownika: \(AuthService.shared.getEmployeeId() ?? "Brak")\n"
        info += "Rola: \(role ?? "Brak")"
        
        return info
    }
    
    /// Testuje token wykonując proste zapytanie
    func testToken() {
        let role = AuthService.shared.getEmployeeRole()
        var hasToken = false
        
        switch role {
        case "byggeleder":
            hasToken = ManagerAPIService.shared.authToken != nil
        case "arbejder", "chef", "system":
            hasToken = WorkerAPIService.shared.authToken != nil
        default:
            hasToken = false
        }
        
        guard hasToken else {
            print("[AuthDebugger] Brak tokenu do testowania")
            return
        }
        
        print("[AuthDebugger] Testowanie tokenu...")
        
        let publisher: AnyPublisher<String, BaseAPIService.APIError>
        switch role {
        case "byggeleder":
            publisher = ManagerAPIService.shared.testConnection()
        case "arbejder", "chef", "system":
            publisher = WorkerAPIService.shared.testConnection()
        default:
            print("[AuthDebugger] Brak roli użytkownika, nie można testować tokenu")
            return
        }
        
        publisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("[AuthDebugger] Test zakończył się pomyślnie")
                case .failure(let error):
                    print("[AuthDebugger] Test nie powiódł się: \(error.localizedDescription)")
                }
            }, receiveValue: { _ in
                print("[AuthDebugger] Token działa poprawnie")
            })
            .store(in: &cancellables)
    }
}
#endif
