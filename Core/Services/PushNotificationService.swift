//
//  PushNotificationService.swift
//  KSR Cranes App
//
//  Created by Claude on 06/06/2025.
//

import Foundation
import UserNotifications
import UIKit
import FirebaseMessaging

@MainActor
final class PushNotificationService: NSObject, ObservableObject {
    
    nonisolated static let shared = PushNotificationService()
    
    @Published var fcmToken: String?
    @Published var isPermissionGranted: Bool = false
    
    nonisolated private override init() {
        super.init()
        Task { @MainActor in
            setupNotifications()
        }
    }
    
    // MARK: - Public Methods
    
    func requestPermission() async {
        do {
            let settings = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.isPermissionGranted = settings
            }
            
            if settings {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            print("[PushNotificationService] Permission granted: \(settings)")
        } catch {
            print("[PushNotificationService] Permission request failed: \(error)")
            await MainActor.run {
                self.isPermissionGranted = false
            }
        }
    }
    
    func registerToken(_ token: String) async {
        self.fcmToken = token
        
        // Store token locally
        UserDefaults.standard.set(token, forKey: "fcmToken")
        
        print("[PushNotificationService] FCM Token stored locally: \(token)")
        
        // Only save to server if user is logged in
        if AuthService.shared.isLoggedIn {
            await saveTokenToServer(token)
        } else {
            print("[PushNotificationService] User not logged in, will register token after login")
        }
    }
    
    func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        // Handle notification tap - navigate to specific screen
        print("[PushNotificationService] Notification tapped: \(userInfo)")
        
        // Extract notification data and handle navigation
        if let notificationId = userInfo["notification_id"] as? String {
            handleNotificationNavigation(notificationId: notificationId)
        }
    }
    
    /// Registers any stored FCM token with the server after login
    func registerStoredTokenIfNeeded() async {
        // Check if we have a stored token
        guard let storedToken = UserDefaults.standard.string(forKey: "fcmToken") else {
            print("[PushNotificationService] No stored FCM token to register")
            return
        }
        
        // Check if user is logged in
        guard AuthService.shared.isLoggedIn else {
            print("[PushNotificationService] User not logged in, cannot register token")
            return
        }
        
        print("[PushNotificationService] Registering stored FCM token after login")
        await saveTokenToServer(storedToken)
    }
    
    /// Force refresh FCM token (useful for debugging)
    func refreshFCMToken() {
        print("[PushNotificationService] Forcing FCM token refresh...")
        Messaging.messaging().deleteToken { error in
            if let error = error {
                print("[PushNotificationService] Error deleting token: \(error)")
            } else {
                print("[PushNotificationService] Token deleted, new token will be generated")
                // Request new token
                Messaging.messaging().token { token, error in
                    if let error = error {
                        print("[PushNotificationService] Error fetching new token: \(error)")
                    } else if let token = token {
                        print("[PushNotificationService] New token generated: \(token)")
                        Task {
                            await self.registerToken(token)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func saveTokenToServer(_ token: String) async {
        await saveTokenToServerWithRetry(token, retryCount: 0)
    }
    
    private func saveTokenToServerWithRetry(_ token: String, retryCount: Int) async {
        let maxRetries = 3
        
        guard let employeeId = AuthService.shared.getEmployeeId() else {
            print("[PushNotificationService] No employee ID found")
            return
        }
        
        let request = PushTokenRequest(
            employee_id: Int(employeeId) ?? 0,
            token: token,
            device_type: "ios",
            app_version: getAppVersion(),
            os_version: UIDevice.current.systemVersion
        )
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            
            guard let url = URL(string: "https://ksrcranes.dk/api/app/push/register-token-v2") else {
                print("[PushNotificationService] Invalid URL")
                return
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = jsonData
            
            // Add auth token if available
            if let authToken = AuthService.shared.getSavedToken() {
                print("[PushNotificationService] Auth token found, length: \(authToken.count)")
                urlRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                print("[PushNotificationService] Authorization header set")
            } else {
                print("[PushNotificationService] ⚠️ No auth token available!")
                return
            }
            
            // Debug request details
            print("[PushNotificationService] Request URL: \(urlRequest.url?.absoluteString ?? "nil")")
            print("[PushNotificationService] Request headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
            
            let (data, httpResponse) = try await URLSession.shared.data(for: urlRequest)
            
            // Debug response
            let statusCode = (httpResponse as? HTTPURLResponse)?.statusCode ?? 0
            print("[PushNotificationService] HTTP Status: \(statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("[PushNotificationService] Raw response: \(responseString)")
            }
            
            // Handle different status codes
            if statusCode == 500 {
                // Server error - check if it's a constraint error that we can retry
                if let responseString = String(data: data, encoding: .utf8),
                   responseString.contains("Unique constraint failed") {
                    print("[PushNotificationService] Database constraint error - token likely exists, trying once more...")
                    if retryCount < maxRetries {
                        // Wait a bit before retry
                        do {
                            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        } catch {
                            print("[PushNotificationService] Sleep interrupted: \(error)")
                        }
                        await saveTokenToServerWithRetry(token, retryCount: retryCount + 1)
                        return
                    }
                }
            }
            
            // Try to parse the response
            do {
                let response = try JSONDecoder().decode(PushTokenResponse.self, from: data)
                if response.success {
                    print("[PushNotificationService] ✅ Token saved to server successfully!")
                    if let tokenId = response.token_id {
                        print("[PushNotificationService] Token ID: \(tokenId)")
                    }
                } else {
                    print("[PushNotificationService] ❌ Server returned error: \(response.error ?? "Unknown error")")
                    
                    // If it's a unique constraint error and we haven't retried too much, try again
                    if let error = response.error, error.contains("constraint") && retryCount < maxRetries {
                        print("[PushNotificationService] Retrying token registration due to constraint error...")
                        do {
                            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        } catch {
                            print("[PushNotificationService] Sleep interrupted: \(error)")
                        }
                        await saveTokenToServerWithRetry(token, retryCount: retryCount + 1)
                        return
                    }
                }
            } catch {
                print("[PushNotificationService] Failed to parse JSON response: \(error)")
                
                // If parsing fails and we can retry, do it
                if retryCount < maxRetries {
                    print("[PushNotificationService] Retrying due to parse error...")
                    do {
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    } catch {
                        print("[PushNotificationService] Sleep interrupted: \(error)")
                    }
                    await saveTokenToServerWithRetry(token, retryCount: retryCount + 1)
                    return
                }
            }
        } catch {
            print("[PushNotificationService] Network error: \(error)")
            
            // Retry network errors
            if retryCount < maxRetries {
                print("[PushNotificationService] Retrying due to network error...")
                do {
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                } catch {
                    print("[PushNotificationService] Sleep interrupted: \(error)")
                }
                await saveTokenToServerWithRetry(token, retryCount: retryCount + 1)
                return
            }
        }
    }
    
    private func handleNotificationNavigation(notificationId: String) {
        // Navigate to specific screen based on notification type
        NotificationCenter.default.post(
            name: .pushNotificationTapped,
            object: nil,
            userInfo: ["notification_id": notificationId]
        )
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    // Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            self.handleNotificationTap(userInfo)
        }
        completionHandler()
    }
}

// MARK: - Models

struct PushTokenRequest: Codable {
    let employee_id: Int
    let token: String
    let device_type: String
    let app_version: String
    let os_version: String
}

struct PushTokenResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
    let token_id: String?
    
    // Handle both Int and String for token_id
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        
        // Try to decode token_id as String first, then as Int
        if let tokenIdString = try? container.decodeIfPresent(String.self, forKey: .token_id) {
            token_id = tokenIdString
        } else if let tokenIdInt = try? container.decodeIfPresent(Int.self, forKey: .token_id) {
            token_id = String(tokenIdInt)
        } else {
            token_id = nil
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pushNotificationTapped = Notification.Name("pushNotificationTapped")
}