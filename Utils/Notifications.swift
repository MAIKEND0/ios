//
//  Notifications.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 15/05/2025.
//

// Utils/Notifications.swift

import Foundation

extension Notification.Name {
    /// Powiadomienie wysyłane, gdy wpisy godzin pracy zostaną zaktualizowane
    static let workEntriesUpdated = Notification.Name("workEntriesUpdated")
    
    /// Powiadomienie wysyłane, gdy uwierzytelnianie nie powiedzie się (używane w serwisach API)
    static let authenticationFailure = Notification.Name("authenticationFailure")
}
