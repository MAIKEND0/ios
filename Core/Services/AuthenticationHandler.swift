//
//  AuthenticationHandler.swift
//  KSR Cranes App
//

import Foundation
import UIKit

/// Klasa obsługująca zdarzenia uwierzytelniania w całej aplikacji
class AuthenticationHandler {
    static let shared = AuthenticationHandler()
    
    private init() {
        setupObservers()
    }
    
    /// Inicjalizuje handler - wywołaj tę metodę w AppDelegate lub SceneDelegate
    static func initialize() {
        // Tylko inicjalizuje instancję singletona
        _ = shared
    }
    
    private func setupObservers() {
        // Obserwuj zdarzenia błędów uwierzytelniania (401)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthFailure),
            name: .authenticationFailure,
            object: nil
        )
    }
    
    @objc private func handleAuthFailure() {
        #if DEBUG
        print("[AuthenticationHandler] Obsługa błędu uwierzytelniania - wylogowywanie użytkownika")
        #endif
        
        // Wylogowanie użytkownika
        AuthService.shared.logout()
        
        // Pokaż alert dla użytkownika
        DispatchQueue.main.async {
            self.showAuthFailureAlert()
        }
    }
    
    private func showAuthFailureAlert() {
        let alert = UIAlertController(
            title: "Sesja wygasła",
            message: "Twoja sesja wygasła. Zaloguj się ponownie.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Znajdź najwyższy kontroler widoku do pokazania alertu
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            var topViewController = rootViewController
            while let presentedViewController = topViewController.presentedViewController {
                topViewController = presentedViewController
            }
            
            topViewController.present(alert, animated: true)
        }
    }
}
