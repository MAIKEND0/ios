//
//  Configuration.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import Foundation

struct Configuration {
    // API Configuration
    struct API {
        #if DEBUG
        static let baseURL = "https://ksrcranes.dk"
        #else
        static let baseURL = "https://api.ksrcranes.dk"
        #endif
    }
    
    // Database Configuration
    struct Database {
        // Nie przechowujemy danych bazy w aplikacji mobilnej
        // Komunikacja powinna odbywać się tylko przez API
    }
    
    // Klucze do przechowywania w UserDefaults/KeyChain
    struct StorageKeys {
        static let authToken = "auth_token"
        static let employeeId = "employee_id"
        static let employeeName = "employee_name"
        static let employeeRole = "employee_role"
    }
}
