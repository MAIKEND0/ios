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
    
    // ========== NOWE POWIADOMIENIA DLA REJECTION FLOW ==========
    
    /// Powiadomienie wysyłane, gdy wpis godzin zostanie odrzucony przez managera
    static let entryRejected = Notification.Name("entryRejected")
    
    /// Powiadomienie wysyłane, gdy pracownik ponownie wyśle poprawiony wpis
    static let entryResubmitted = Notification.Name("entryResubmitted")
    
    /// Powiadomienie wysyłane, gdy lista powiadomień zostanie zaktualizowana
    static let notificationsUpdated = Notification.Name("notificationsUpdated")
    
    /// Powiadomienie wysyłane, gdy liczba nieprzeczytanych powiadomień się zmieni
    static let unreadNotificationsCountChanged = Notification.Name("unreadNotificationsCountChanged")
    
    /// Powiadomienie wysyłane, gdy wpis zostanie zatwierdzony przez managera
    static let entryApproved = Notification.Name("entryApproved")
    
    /// Powiadomienie wysyłane, gdy nastąpi błąd w pobieraniu powiadomień
    static let notificationsFetchError = Notification.Name("notificationsFetchError")
}

// ========== STAŁE DLA POWIADOMIEŃ ==========

struct NotificationKeys {
    /// Klucz używany do przekazywania informacji o odrzuconym wpisie
    static let rejectedEntryInfo = "rejectedEntryInfo"
    
    /// Klucz używany do przekazywania informacji o zatwierdzoným wpisie
    static let approvedEntryInfo = "approvedEntryInfo"
    
    /// Klucz używany do przekazywania liczby nieprzeczytanych powiadomień
    static let unreadCount = "unreadCount"
    
    /// Klucz używany do przekazywania błędu
    static let error = "error"
    
    /// Klucz używany do przekazywania nowych powiadomień
    static let notifications = "notifications"
    
    /// Klucz używany do przekazywania ID powiadomienia
    static let notificationId = "notificationId"
}
