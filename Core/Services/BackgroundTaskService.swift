//
//  BackgroundTaskService.swift
//  KSR Cranes App
//
//  Background task management for syncing data when app is in background
//

import Foundation
import BackgroundTasks
import UIKit
import UserNotifications

/// Service responsible for managing background sync tasks
final class BackgroundTaskService {
    
    // MARK: - Properties
    
    static let shared = BackgroundTaskService()
    
    // Background task identifiers
    private enum TaskIdentifier {
        static let backgroundRefresh = "com.ksrcranes.app.backgroundrefresh"
        static let dataSync = "com.ksrcranes.app.datasync"
        static let notificationSync = "com.ksrcranes.app.notificationsync"
    }
    
    // Refresh intervals
    private enum RefreshInterval {
        static let minimum: TimeInterval = 15 * 60 // 15 minutes
        static let preferred: TimeInterval = 30 * 60 // 30 minutes
        static let maximum: TimeInterval = 60 * 60 // 1 hour
    }
    
    private let backgroundQueue = DispatchQueue(label: "com.ksrcranes.background", qos: .background)
    
    // MARK: - Initialization
    
    private init() {
        #if DEBUG
        print("[BackgroundTaskService] Initialized")
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Register background tasks with the system
    func registerBackgroundTasks() {
        #if DEBUG
        print("[BackgroundTaskService] Registering background tasks...")
        #endif
        
        // Register background refresh task
        let refreshSuccess = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.backgroundRefresh,
            using: nil
        ) { [weak self] task in
            self?.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Register data sync task
        let syncSuccess = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.dataSync,
            using: nil
        ) { [weak self] task in
            self?.handleDataSync(task: task as! BGProcessingTask)
        }
        
        // Register notification sync task
        let notificationSuccess = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.notificationSync,
            using: nil
        ) { [weak self] task in
            self?.handleNotificationSync(task: task as! BGAppRefreshTask)
        }
        
        #if DEBUG
        print("[BackgroundTaskService] Registration results:")
        print("  - Background refresh: \(refreshSuccess ? "✅" : "❌")")
        print("  - Data sync: \(syncSuccess ? "✅" : "❌")")
        print("  - Notification sync: \(notificationSuccess ? "✅" : "❌")")
        #endif
    }
    
    /// Configure background tasks (called from AppDelegate)
    func configureBackgroundTasks() {
        // Schedule initial tasks
        scheduleBackgroundRefresh()
        scheduleDataSync()
        scheduleNotificationSync()
        
        // Listen for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        #if DEBUG
        print("[BackgroundTaskService] Background tasks configured")
        #endif
    }
    
    // MARK: - Task Scheduling
    
    /// Schedule background refresh task
    func scheduleBackgroundRefresh(afterInterval: TimeInterval = RefreshInterval.preferred) {
        let request = BGAppRefreshTaskRequest(identifier: TaskIdentifier.backgroundRefresh)
        request.earliestBeginDate = Date(timeIntervalSinceNow: afterInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            print("[BackgroundTaskService] Background refresh scheduled for \(afterInterval/60) minutes from now")
            #endif
        } catch {
            #if DEBUG
            print("[BackgroundTaskService] Failed to schedule background refresh: \(error)")
            #endif
        }
    }
    
    /// Schedule data sync task
    func scheduleDataSync() {
        let request = BGProcessingTaskRequest(identifier: TaskIdentifier.dataSync)
        request.earliestBeginDate = Date(timeIntervalSinceNow: RefreshInterval.maximum)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            print("[BackgroundTaskService] Data sync scheduled")
            #endif
        } catch {
            #if DEBUG
            print("[BackgroundTaskService] Failed to schedule data sync: \(error)")
            #endif
        }
    }
    
    /// Schedule notification sync task
    func scheduleNotificationSync() {
        let request = BGAppRefreshTaskRequest(identifier: TaskIdentifier.notificationSync)
        request.earliestBeginDate = Date(timeIntervalSinceNow: RefreshInterval.minimum)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            print("[BackgroundTaskService] Notification sync scheduled")
            #endif
        } catch {
            #if DEBUG
            print("[BackgroundTaskService] Failed to schedule notification sync: \(error)")
            #endif
        }
    }
    
    // MARK: - Task Handlers
    
    /// Handle background refresh task
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        #if DEBUG
        print("[BackgroundTaskService] Handling background refresh...")
        #endif
        
        // Schedule the next refresh
        scheduleBackgroundRefresh()
        
        // Create a background operation
        let operation = BackgroundRefreshOperation()
        
        // Set expiration handler
        task.expirationHandler = {
            operation.cancel()
            #if DEBUG
            print("[BackgroundTaskService] Background refresh task expired")
            #endif
        }
        
        // Start the operation
        operation.start { success in
            task.setTaskCompleted(success: success)
            #if DEBUG
            print("[BackgroundTaskService] Background refresh completed: \(success ? "✅" : "❌")")
            #endif
        }
    }
    
    /// Handle data sync task
    private func handleDataSync(task: BGProcessingTask) {
        #if DEBUG
        print("[BackgroundTaskService] Handling data sync...")
        #endif
        
        // Schedule the next sync
        scheduleDataSync()
        
        // Create sync operation
        let operation = DataSyncOperation()
        
        // Set expiration handler
        task.expirationHandler = {
            operation.cancel()
            #if DEBUG
            print("[BackgroundTaskService] Data sync task expired")
            #endif
        }
        
        // Start the operation
        operation.start { success in
            task.setTaskCompleted(success: success)
            #if DEBUG
            print("[BackgroundTaskService] Data sync completed: \(success ? "✅" : "❌")")
            #endif
        }
    }
    
    /// Handle notification sync task
    private func handleNotificationSync(task: BGAppRefreshTask) {
        #if DEBUG
        print("[BackgroundTaskService] Handling notification sync...")
        #endif
        
        // Schedule the next sync
        scheduleNotificationSync()
        
        // Create notification sync operation
        let operation = NotificationSyncOperation()
        
        // Set expiration handler
        task.expirationHandler = {
            operation.cancel()
            #if DEBUG
            print("[BackgroundTaskService] Notification sync task expired")
            #endif
        }
        
        // Start the operation
        operation.start { success in
            task.setTaskCompleted(success: success)
            #if DEBUG
            print("[BackgroundTaskService] Notification sync completed: \(success ? "✅" : "❌")")
            #endif
        }
    }
    
    // MARK: - App Lifecycle
    
    @objc private func appDidEnterBackground() {
        #if DEBUG
        print("[BackgroundTaskService] App entered background, ensuring tasks are scheduled")
        #endif
        
        // Ensure all tasks are scheduled
        scheduleBackgroundRefresh()
        scheduleDataSync()
        scheduleNotificationSync()
    }
    
    @objc private func appWillTerminate() {
        #if DEBUG
        print("[BackgroundTaskService] App will terminate, scheduling final tasks")
        #endif
        
        // Schedule tasks for next app launch
        scheduleBackgroundRefresh(afterInterval: RefreshInterval.minimum)
        scheduleDataSync()
        scheduleNotificationSync()
    }
}

// MARK: - Background Operations

/// Operation for background refresh
private class BackgroundRefreshOperation {
    private var isCancelled = false
    private let operationQueue = OperationQueue()
    
    func cancel() {
        isCancelled = true
        operationQueue.cancelAllOperations()
    }
    
    func start(completion: @escaping (Bool) -> Void) {
        guard !isCancelled else {
            completion(false)
            return
        }
        
        // Check if user is logged in
        guard AuthService.shared.isLoggedIn else {
            #if DEBUG
            print("[BackgroundRefresh] User not logged in, skipping refresh")
            #endif
            completion(true)
            return
        }
        
        let group = DispatchGroup()
        var success = true
        
        // Refresh notifications
        group.enter()
        NotificationService.shared.fetchUnreadCount()
        group.leave()
        
        // Refresh user-specific data based on role
        if let role = AuthService.shared.getEmployeeRole() {
            group.enter()
            refreshRoleSpecificData(role: role) { refreshSuccess in
                defer { group.leave() }
                if !refreshSuccess {
                    success = false
                }
            }
        }
        
        // Complete when all operations finish
        group.notify(queue: .main) {
            completion(success)
        }
    }
    
    private func refreshRoleSpecificData(role: String, completion: @escaping (Bool) -> Void) {
        switch role.lowercased() {
        case "arbejder":
            // Refresh worker dashboard data
            // TODO: Implement worker dashboard data refresh when fetchDashboardData is available
            completion(true)
            
        case "byggeleder":
            // Refresh manager data
            // TODO: Implement manager-specific data refresh when dashboard methods are available
            completion(true)
            
        case "chef":
            // For chef, we can refresh basic stats
            completion(true) // Simplified for now
            
        default:
            completion(true)
        }
    }
}

/// Operation for data sync
private class DataSyncOperation {
    private var isCancelled = false
    
    func cancel() {
        isCancelled = true
    }
    
    func start(completion: @escaping (Bool) -> Void) {
        guard !isCancelled else {
            completion(false)
            return
        }
        
        // Check if user is logged in
        guard AuthService.shared.isLoggedIn else {
            #if DEBUG
            print("[DataSync] User not logged in, skipping sync")
            #endif
            completion(true)
            return
        }
        
        // Perform comprehensive data sync
        Task {
            do {
                // Sync notifications
                if !isCancelled {
                    try await syncNotifications()
                }
                
                // Sync work entries if worker
                if AuthService.shared.getEmployeeRole()?.lowercased() == "arbejder", !isCancelled {
                    try await syncWorkEntries()
                }
                
                // Sync other role-specific data
                if !isCancelled {
                    try await syncRoleSpecificData()
                }
                
                await MainActor.run {
                    completion(true)
                }
                
            } catch {
                #if DEBUG
                print("[DataSync] Sync failed: \(error)")
                #endif
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    private func syncNotifications() async throws {
        #if DEBUG
        print("[DataSync] Syncing notifications...")
        #endif
        
        // Implementation would sync notifications
        // For now, just fetch the count
        _ = try await NotificationService.shared.fetchNotificationCountAsync()
    }
    
    private func syncWorkEntries() async throws {
        #if DEBUG
        print("[DataSync] Syncing work entries...")
        #endif
        
        // Implementation would sync pending work entries
        // This is a placeholder for the actual implementation
    }
    
    private func syncRoleSpecificData() async throws {
        #if DEBUG
        print("[DataSync] Syncing role-specific data...")
        #endif
        
        // Implementation would sync data based on user role
        // This is a placeholder for the actual implementation
    }
}

/// Operation for notification sync
private class NotificationSyncOperation {
    private var isCancelled = false
    
    func cancel() {
        isCancelled = true
    }
    
    func start(completion: @escaping (Bool) -> Void) {
        guard !isCancelled else {
            completion(false)
            return
        }
        
        // Check if user is logged in
        guard AuthService.shared.isLoggedIn else {
            #if DEBUG
            print("[NotificationSync] User not logged in, skipping sync")
            #endif
            completion(true)
            return
        }
        
        // Fetch and update notifications
        NotificationService.shared.fetchNotifications()
        
        // Update badge count based on current unread count
        let unreadCount = NotificationService.shared.unreadCount
        Task { @MainActor in
            if #available(iOS 17.0, *) {
                try? await UNUserNotificationCenter.current().setBadgeCount(unreadCount)
            } else {
                UIApplication.shared.applicationIconBadgeNumber = unreadCount
            }
        }
        
        #if DEBUG
        print("[NotificationSync] Updated badge count: \(unreadCount)")
        #endif
        
        completion(true)
    }
}

// MARK: - Extensions

private extension Result {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

// MARK: - Async Extensions

extension NotificationService {
    func fetchNotificationCountAsync() async throws -> Int {
        // Since fetchUnreadCount() doesn't return the count directly,
        // we'll return the current unreadCount after triggering a refresh
        fetchUnreadCount()
        return unreadCount
    }
}