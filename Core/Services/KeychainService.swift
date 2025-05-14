// Core/Services/KeychainService.swift

import Foundation
import Security

class KeychainService {
    // Singleton dla łatwego dostępu
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - Zapisywanie danych
    
    func storeToken(_ token: String) -> Bool {
        return storeString(token, forKey: Configuration.StorageKeys.authToken)
    }
    
    func storeString(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else {
            return false
        }
        
        // Przygotuj zapytanie do Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Usuń stary wpis, jeśli istnieje
        SecItemDelete(query as CFDictionary)
        
        // Dodaj nowy wpis
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Odczytywanie danych
    
    func getToken() -> String? {
        return getString(forKey: Configuration.StorageKeys.authToken)
    }
    
    func getString(forKey key: String) -> String? {
        // Przygotuj zapytanie do Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    // MARK: - Usuwanie danych
    
    func deleteToken() -> Bool {
        return deleteItem(forKey: Configuration.StorageKeys.authToken)
    }
    
    func deleteItem(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Sprawdzanie istnienia klucza
    
    func tokenExists() -> Bool {
        return itemExists(forKey: Configuration.StorageKeys.authToken)
    }
    
    func itemExists(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
