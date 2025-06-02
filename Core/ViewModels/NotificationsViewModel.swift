// NotificationsViewModel.swift
import Foundation
import Combine
import SwiftUI

final class NotificationsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var filteredNotifications: [AppNotification] = []
    @Published var selectedCategory: NotificationCategory? = nil
    @Published var selectedPriority: NotificationPriority? = nil
    @Published var showUnreadOnly: Bool = false
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var lastError: NotificationError?
    
    // MARK: - Private Properties
    private let notificationService: NotificationService
    private var cancellables = Set<AnyCancellable>()
    private var allNotifications: [AppNotification] = []
    
    // MARK: - Computed Properties
    var hasActiveFilters: Bool {
        selectedCategory != nil || selectedPriority != nil || showUnreadOnly || !searchText.isEmpty
    }
    
    var displayedNotifications: [AppNotification] {
        return filteredNotifications.isEmpty && !hasActiveFilters ? allNotifications : filteredNotifications
    }
    
    var unreadCount: Int {
        notificationService.unreadCount
    }
    
    var urgentUnreadCount: Int {
        allNotifications.filter { !$0.isRead && $0.isUrgent }.count
    }
    
    // MARK: - Initialization
    init(notificationService: NotificationService = NotificationService.shared) {
        self.notificationService = notificationService
        setupBindings()
        setupFilterObservers()
    }
    
    // MARK: - Public Methods
    func loadNotifications() {
        isLoading = true
        lastError = nil
        notificationService.fetchNotifications()
    }
    
    func refreshNotifications() {
        notificationService.forceRefresh()
    }
    
    func markAsRead(_ notification: AppNotification) {
        notificationService.markAsRead(notification)
    }
    
    func markAllAsRead() {
        notificationService.markAllAsRead()
    }
    
    func clearFilters() {
        selectedCategory = nil
        selectedPriority = nil
        showUnreadOnly = false
        searchText = ""
    }
    
    func applyFilters() {
        filterNotifications()
    }
    
    // MARK: - Filter Methods
    func setCategory(_ category: NotificationCategory?) {
        selectedCategory = category
        filterNotifications()
    }
    
    func setPriority(_ priority: NotificationPriority?) {
        selectedPriority = priority
        filterNotifications()
    }
    
    func setShowUnreadOnly(_ unreadOnly: Bool) {
        showUnreadOnly = unreadOnly
        filterNotifications()
    }
    
    func setSearchText(_ text: String) {
        searchText = text
        filterNotifications()
    }
    
    // MARK: - Utility Methods
    func getNotificationsRequiringAction() -> [AppNotification] {
        return displayedNotifications.filter { $0.requiresAction && !$0.isRead }
    }
    
    func getNotificationsByCategory(_ category: NotificationCategory) -> [AppNotification] {
        return displayedNotifications.filter { $0.category == category }
    }
    
    func getExpiringNotifications() -> [AppNotification] {
        let threshold = Date().addingTimeInterval(3600) // 1 hour
        return displayedNotifications.filter { notification in
            guard let expiresAt = notification.expiresAt else { return false }
            return expiresAt <= threshold && expiresAt > Date()
        }
    }
    
    // MARK: - Navigation Helpers
    func handleNotificationTap(_ notification: AppNotification) -> NotificationAction? {
        // Mark as read if unread
        if !notification.isRead {
            markAsRead(notification)
        }
        
        // Determine action based on notification type
        switch notification.type {
        case .hoursRejected:
            // Check if it's a week rejection notification
            if let metadata = notification.metadata,
               let entryIdsJson = metadata["entryIds"],
               let entryIdsData = entryIdsJson.data(using: .utf8),
               let entryIds = try? JSONDecoder().decode([Int].self, from: entryIdsData),
               let firstEntryId = entryIds.first {
                return .navigateToWorkEntry(
                    taskId: notification.taskId,
                    workEntryId: firstEntryId
                )
            }
            // Fallback to single entry rejection
            return .navigateToWorkEntry(
                taskId: notification.taskId,
                workEntryId: notification.workEntryId
            )
        case .taskAssigned:
            return .navigateToTask(taskId: notification.taskId)
        case .emergencyAlert:
            return .showEmergencyDetails(notification: notification)
        case .licenseExpiring:
            return .navigateToProfile
        default:
            if let actionUrl = notification.actionUrl {
                return .openURL(url: actionUrl)
            }
            return nil
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Bind to notification service
        notificationService.$notifications
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notifications in
                self?.allNotifications = notifications
                self?.filterNotifications()
            }
            .store(in: &cancellables)
        
        notificationService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        notificationService.$lastError
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastError, on: self)
            .store(in: &cancellables)
    }
    
    private func setupFilterObservers() {
        // Debounce search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.filterNotifications()
            }
            .store(in: &cancellables)
    }
    
    private func filterNotifications() {
        var filtered = allNotifications
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by priority
        if let priority = selectedPriority {
            filtered = filtered.filter { $0.priority == priority }
        }
        
        // Filter by read status
        if showUnreadOnly {
            filtered = filtered.filter { !$0.isRead }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { notification in
                notification.title.localizedCaseInsensitiveContains(searchText) ||
                notification.message.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by priority and date
        filtered = filtered.sorted { first, second in
            // First sort by priority
            let firstPriorityOrder = priorityOrder(first.priority)
            let secondPriorityOrder = priorityOrder(second.priority)
            
            if firstPriorityOrder != secondPriorityOrder {
                return firstPriorityOrder < secondPriorityOrder
            }
            
            // Then by date (newest first)
            return first.createdAt > second.createdAt
        }
        
        filteredNotifications = filtered
    }
    
    private func priorityOrder(_ priority: NotificationPriority?) -> Int {
        switch priority {
        case .urgent: return 0
        case .high: return 1
        case .normal: return 2
        case .low: return 3
        case nil: return 4
        }
    }
}

// MARK: - Notification Actions
enum NotificationAction {
    case navigateToWorkEntry(taskId: Int?, workEntryId: Int?)
    case navigateToTask(taskId: Int?)
    case navigateToProfile
    case showEmergencyDetails(notification: AppNotification)
    case openURL(url: String)
}

// MARK: - Extensions
extension NotificationsViewModel {
    
    // MARK: - Quick Actions
    func getQuickActions(for notification: AppNotification) -> [QuickAction] {
        switch notification.type {
        case .hoursRejected:
            // Check if it's a week rejection notification
            if let metadata = notification.metadata,
               let _ = metadata["weekNumber"],
               let _ = metadata["entryIds"] {
                return [
                    QuickAction(
                        title: "Fix & Resubmit Week",
                        icon: "pencil.circle.fill",
                        color: .blue,
                        action: { [weak self] in
                            self?.handleWeekResubmit(notification)
                        }
                    ),
                    QuickAction(
                        title: "View Week Entries",
                        icon: "eye.fill",
                        color: .gray,
                        action: { [weak self] in
                            _ = self?.handleNotificationTap(notification)
                        }
                    )
                ]
            }
            // Single entry rejection
            return [
                QuickAction(
                    title: "Fix & Resubmit",
                    icon: "pencil.circle.fill",
                    color: .blue,
                    action: { [weak self] in
                        self?.handleQuickResubmit(notification)
                    }
                ),
                QuickAction(
                    title: "View Details",
                    icon: "eye.fill",
                    color: .gray,
                    action: { [weak self] in
                        _ = self?.handleNotificationTap(notification)
                    }
                )
            ]
        case .taskAssigned:
            return [
                QuickAction(
                    title: "View Task",
                    icon: "briefcase.fill",
                    color: .green,
                    action: { [weak self] in
                        _ = self?.handleNotificationTap(notification)
                    }
                ),
                QuickAction(
                    title: "Accept",
                    icon: "checkmark.circle.fill",
                    color: .blue,
                    action: { [weak self] in
                        self?.handleTaskAcceptance(notification)
                    }
                )
            ]
        default:
            return []
        }
    }
    
    private func handleQuickResubmit(_ notification: AppNotification) {
        markAsRead(notification)
        // Post notification to open work entry form
        NotificationCenter.default.post(
            name: .openWorkEntryForm,
            object: nil,
            userInfo: [
                "taskId": notification.taskId ?? 0,
                "workEntryId": notification.workEntryId ?? 0
            ]
        )
    }
    
    private func handleWeekResubmit(_ notification: AppNotification) {
        markAsRead(notification)
        // Extract entryIds from metadata
        if let metadata = notification.metadata,
           let entryIdsJson = metadata["entryIds"],
           let entryIdsData = entryIdsJson.data(using: .utf8),
           let entryIds = try? JSONDecoder().decode([Int].self, from: entryIdsData),
           let firstEntryId = entryIds.first {
            NotificationCenter.default.post(
                name: .openWorkEntryForm,
                object: nil,
                userInfo: [
                    "taskId": notification.taskId ?? 0,
                    "workEntryId": firstEntryId
                ]
            )
        } else {
            // Fallback to single entry if metadata parsing fails
            NotificationCenter.default.post(
                name: .openWorkEntryForm,
                object: nil,
                userInfo: [
                    "taskId": notification.taskId ?? 0,
                    "workEntryId": notification.workEntryId ?? 0
                ]
            )
        }
    }
    
    private func handleTaskAcceptance(_ notification: AppNotification) {
        markAsRead(notification)
        // Handle task acceptance logic
        print("Task acceptance for notification: \(notification.id)")
    }
}

// MARK: - Quick Action Model
struct QuickAction {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
}

// MARK: - Additional Notification Names
extension Notification.Name {
    static let openWorkEntryForm = Notification.Name("openWorkEntryForm")
    static let openTaskDetails = Notification.Name("openTaskDetails")
}
