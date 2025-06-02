// Core/Services/KeychainService.swift
// Prosta, działająca wersja KeychainService

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - Configuration
    private let service = Bundle.main.bundleIdentifier ?? "dk.KSR-Cranes-App"
    
    // MARK: - Error Handling
    private func getErrorMessage(for status: OSStatus) -> String {
        switch status {
        case errSecSuccess: return "Success"
        case errSecItemNotFound: return "Item not found"
        case errSecDuplicateItem: return "Duplicate item"
        case errSecUnimplemented: return "Unimplemented"
        case errSecParam: return "Invalid parameter"
        case errSecAllocate: return "Allocation failure"
        case errSecNotAvailable: return "Not available"
        case errSecAuthFailed: return "Authentication failed"
        case errSecUserCanceled: return "User canceled"
        case errSecBadReq: return "Bad request"
        case errSecInternalComponent: return "Internal component error"
        default: return "Unknown error (code: \(status))"
        }
    }
    
    // MARK: - Token Storage with Simulator Fallback
    
    func storeToken(_ token: String) -> Bool {
        #if DEBUG
        print("[KeychainService] 📝 Attempting to store token...")
        print("[KeychainService] 📝 Service: \(service)")
        print("[KeychainService] 📝 Token length: \(token.count) characters")
        #endif
        
        #if targetEnvironment(simulator)
        // Na symulatorze używaj UserDefaults jako fallback
        return storeTokenInUserDefaults(token)
        #else
        // Na urządzeniu spróbuj keychain, potem fallback
        if storeTokenInKeychain(token) {
            // Jeśli keychain działa, usuń fallback
            UserDefaults.standard.removeObject(forKey: "fallback_auth_token")
            return true
        } else {
            #if DEBUG
            print("[KeychainService] ❌ Keychain failed, using UserDefaults fallback")
            #endif
            return storeTokenInUserDefaults(token)
        }
        #endif
    }
    
    private func storeTokenInKeychain(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else {
            #if DEBUG
            print("[KeychainService] ❌ Failed to convert token to data")
            #endif
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Configuration.StorageKeys.authToken,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Configuration.StorageKeys.authToken
        ]
        
        let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
        #if DEBUG
        if deleteStatus == errSecSuccess {
            print("[KeychainService] 🗑️ Deleted existing keychain item")
        } else if deleteStatus != errSecItemNotFound {
            print("[KeychainService] ⚠️ Delete warning: \(getErrorMessage(for: deleteStatus))")
        }
        #endif
        
        // Add new item
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        
        #if DEBUG
        if addStatus == errSecSuccess {
            print("[KeychainService] ✅ Successfully stored token in keychain")
        } else {
            print("[KeychainService] ❌ Failed to store in keychain: \(getErrorMessage(for: addStatus))")
        }
        #endif
        
        return addStatus == errSecSuccess
    }
    
    private func storeTokenInUserDefaults(_ token: String) -> Bool {
        #if DEBUG
        print("[KeychainService] ⚠️ Storing token in UserDefaults (fallback)")
        #endif
        
        UserDefaults.standard.set(token, forKey: "fallback_auth_token")
        UserDefaults.standard.synchronize()
        
        // Verify storage
        let stored = UserDefaults.standard.string(forKey: "fallback_auth_token")
        let success = stored == token
        
        #if DEBUG
        print("[KeychainService] \(success ? "✅" : "❌") UserDefaults storage: \(success ? "success" : "failed")")
        #endif
        
        return success
    }
    
    // MARK: - Token Retrieval with Fallback
    
    func getToken() -> String? {
        #if DEBUG
        print("[KeychainService] 🔍 Attempting to retrieve token...")
        #endif
        
        #if targetEnvironment(simulator)
        // Na symulatorze zawsze używaj UserDefaults
        return getTokenFromUserDefaults()
        #else
        // Na urządzeniu spróbuj keychain najpierw
        if let keychainToken = getTokenFromKeychain() {
            #if DEBUG
            print("[KeychainService] ✅ Token retrieved from keychain")
            #endif
            return keychainToken
        }
        
        // Fallback do UserDefaults
        if let fallbackToken = getTokenFromUserDefaults() {
            #if DEBUG
            print("[KeychainService] ⚠️ Token retrieved from UserDefaults fallback")
            #endif
            return fallbackToken
        }
        
        #if DEBUG
        print("[KeychainService] ❌ No token found anywhere")
        #endif
        return nil
        #endif
    }
    
    private func getTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Configuration.StorageKeys.authToken,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        #if DEBUG
        if status == errSecSuccess {
            print("[KeychainService] ✅ Keychain query successful")
        } else {
            print("[KeychainService] ❌ Keychain query failed: \(getErrorMessage(for: status))")
        }
        #endif
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    private func getTokenFromUserDefaults() -> String? {
        let token = UserDefaults.standard.string(forKey: "fallback_auth_token")
        
        #if DEBUG
        if let tokenValue = token {
            print("[KeychainService] ✅ Token from UserDefaults: \(String(tokenValue.prefix(10)))...")
        } else {
            print("[KeychainService] ❌ No token in UserDefaults")
        }
        #endif
        
        return token
    }
    
    // MARK: - Token Deletion
    
    func deleteToken() -> Bool {
        #if DEBUG
        print("[KeychainService] 🗑️ Deleting token from all sources...")
        #endif
        
        var success = true
        
        // Delete from keychain
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Configuration.StorageKeys.authToken
        ]
        
        let keychainStatus = SecItemDelete(keychainQuery as CFDictionary)
        if keychainStatus == errSecSuccess || keychainStatus == errSecItemNotFound {
            #if DEBUG
            print("[KeychainService] ✅ Token deleted from keychain")
            #endif
        } else {
            #if DEBUG
            print("[KeychainService] ❌ Failed to delete from keychain: \(getErrorMessage(for: keychainStatus))")
            #endif
            success = false
        }
        
        // Delete from UserDefaults fallback
        UserDefaults.standard.removeObject(forKey: "fallback_auth_token")
        UserDefaults.standard.synchronize()
        
        #if DEBUG
        print("[KeychainService] ✅ Token deleted from UserDefaults fallback")
        #endif
        
        return success
    }
    
    // MARK: - Utility Methods
    
    func tokenExists() -> Bool {
        return getToken() != nil
    }
    
    func storeString(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getString(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
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
    
    func deleteItem(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    func debugKeychainState() {
        print("[KeychainService] 🔍 === KEYCHAIN DEBUG STATE ===")
        print("[KeychainService] 🔍 App Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        print("[KeychainService] 🔍 Service: \(service)")
        
        #if targetEnvironment(simulator)
        print("[KeychainService] 🔍 Environment: Simulator")
        #else
        print("[KeychainService] 🔍 Environment: Device")
        #endif
        
        let tokenExists = self.tokenExists()
        print("[KeychainService] 🔍 Token exists: \(tokenExists)")
        
        if let token = getToken() {
            print("[KeychainService] 🔍 Token retrieved: \(String(token.prefix(15)))...")
            print("[KeychainService] 🔍 Token length: \(token.count) characters")
            
            // Check source
            #if targetEnvironment(simulator)
            print("[KeychainService] 🔍 Source: UserDefaults (simulator)")
            #else
            let fromKeychain = getTokenFromKeychain() != nil
            let fromFallback = getTokenFromUserDefaults() != nil
            print("[KeychainService] 🔍 Source - Keychain: \(fromKeychain), Fallback: \(fromFallback)")
            #endif
        } else {
            print("[KeychainService] 🔍 No token retrieved from any source")
        }
        
        print("[KeychainService] 🔍 === END DEBUG STATE ===")
    }
    
    func clearAllKeychainItems() {
        print("[KeychainService] 🧹 Clearing all keychain items for debugging...")
        
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for secItemClass in secItemClasses {
            let dictionary = [kSecClass as String: secItemClass]
            let status = SecItemDelete(dictionary as CFDictionary)
            
            if status == errSecSuccess {
                print("[KeychainService] 🧹 Cleared items for class: \(secItemClass)")
            } else if status == errSecItemNotFound {
                print("[KeychainService] 🧹 No items to clear for class: \(secItemClass)")
            } else {
                print("[KeychainService] 🧹 Error clearing class \(secItemClass): \(getErrorMessage(for: status))")
            }
        }
        
        // Clear UserDefaults fallback items
        UserDefaults.standard.removeObject(forKey: "fallback_auth_token")
        UserDefaults.standard.synchronize()
        print("[KeychainService] 🧹 Cleared UserDefaults fallback items")
    }
    #endif
}
