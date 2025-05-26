// NotificationService.swift - Updated with Singleton
import Foundation
import Combine
import UIKit

class NotificationService: ObservableObject {
    
    // MARK: - Singleton Instance
    static let shared = NotificationService()
    
    // MARK: - Published Properties (same as before)
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var lastError: NotificationError?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let workerAPIService: WorkerAPIService
    private var refreshTimer: AnyCancellable?
    private var backgroundTaskTimer: AnyCancellable?
    
    // Cache settings
    private let cacheExpirationTime: TimeInterval = 300 // 5 minut
    private var lastCacheUpdate: Date?
    
    // MARK: - Private Initializer (Singleton)
    private init(workerAPIService: WorkerAPIService = WorkerAPIService.shared) {
        self.workerAPIService = workerAPIService
        setupNotificationObservers()
        startPeriodicRefresh()
    }
    
    // MARK: - Public Factory Method (for testing)
    static func create(with workerAPIService: WorkerAPIService = WorkerAPIService.shared) -> NotificationService {
        let service = NotificationService()
        return service
    }
    
    // Rest of the implementation stays the same...
    // [Previous implementation continues here]
    
    deinit {
        stopPeriodicRefresh()
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - All existing methods remain the same
    // fetchNotifications, markAsRead, etc.
    
    /// Pobiera powiadomienia z API
    func fetchNotifications(params: NotificationQueryParams = NotificationQueryParams()) {
        guard !isLoading else { return }
        
        isLoading = true
        lastError = nil
        
        workerAPIService.fetchNotifications(params: params)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.handleNotificationError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleNotificationsReceived(response.notifications)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Pobiera tylko liczbę nieprzeczytanych powiadomień
    func fetchUnreadCount() {
        workerAPIService.getUnreadNotificationsCount()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleNotificationError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    self?.updateUnreadCount(response.unreadCount)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Oznacza powiadomienie jako przeczytane
    func markAsRead(_ notification: AppNotification) {
        // Optimistic update
        updateNotificationReadStatus(notification.id, isRead: true)
        
        workerAPIService.markNotificationAsRead(id: notification.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        // Rollback optimistic update
                        self?.updateNotificationReadStatus(notification.id, isRead: false)
                        self?.handleNotificationError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    self?.decrementUnreadCount()
                    print("[NotificationService] Successfully marked notification \(notification.id) as read")
                }
            )
            .store(in: &cancellables)
    }
    
    // ... rest of the methods stay the same
    
    // MARK: - Private Helper Methods
    private func setupNotificationObservers() {
        // Obsługa wejścia aplikacji na pierwszy plan
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.refreshIfNeeded()
            }
            .store(in: &cancellables)
        
        // Obsługa błędów uwierzytelniania
        NotificationCenter.default.publisher(for: .authenticationFailure)
            .sink { [weak self] _ in
                self?.handleAuthenticationFailure()
            }
            .store(in: &cancellables)
    }
    
    private func handleNotificationsReceived(_ notifications: [AppNotification]) {
        self.notifications = notifications.sorted {
            // Sortuj według priorytetu i daty
            if $0.priority != $1.priority {
                let priority0 = $0.priority?.rawValue ?? "NORMAL"
                let priority1 = $1.priority?.rawValue ?? "NORMAL"
                let priorityOrder = ["URGENT": 0, "HIGH": 1, "NORMAL": 2, "LOW": 3]
                return (priorityOrder[priority0] ?? 2) < (priorityOrder[priority1] ?? 2)
            }
            return $0.createdAt > $1.createdAt
        }
        
        self.unreadCount = notifications.filter { !$0.isRead }.count
        self.lastCacheUpdate = Date()
        
        // Wyślij powiadomienie o aktualizacji
        NotificationCenter.default.post(
            name: .notificationsUpdated,
            object: nil,
            userInfo: [NotificationKeys.notifications: notifications]
        )
        
        print("[NotificationService] Loaded \(notifications.count) notifications, \(unreadCount) unread")
    }
    
    private func handleNotificationError(_ error: Error) {
        let notificationError: NotificationError
        
        if let apiError = error as? BaseAPIService.APIError {
            switch apiError {
            case .networkError(let underlyingError):
                notificationError = .networkError(underlyingError.localizedDescription)
            case .decodingError(let underlyingError):
                notificationError = .decodingError(underlyingError.localizedDescription)
            case .serverError(_, let message):
                notificationError = .serverError(message)
            case .invalidURL, .invalidResponse, .unknown:
                notificationError = .unknownError
            }
        } else {
            notificationError = .unknownError
        }
        
        self.lastError = notificationError
        
        // Wyślij powiadomienie o błędzie
        NotificationCenter.default.post(
            name: .notificationsFetchError,
            object: nil,
            userInfo: [NotificationKeys.error: notificationError]
        )
        
        print("[NotificationService] Error: \(notificationError.localizedDescription)")
    }
    
    private func handleAuthenticationFailure() {
        notifications = []
        unreadCount = 0
        lastError = .unauthorized
        stopPeriodicRefresh()
    }
    
    private func updateNotificationReadStatus(_ notificationId: Int, isRead: Bool) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            let notification = notifications[index]
            notifications[index] = AppNotification(
                id: notification.id,
                employeeId: notification.employeeId,
                type: notification.type,
                title: notification.title,
                message: notification.message,
                isRead: isRead,
                createdAt: notification.createdAt,
                updatedAt: Date(),
                workEntryId: notification.workEntryId,
                taskId: notification.taskId,
                projectId: notification.projectId,
                projectTitle: notification.projectTitle,
                priority: notification.priority,
                category: notification.category,
                actionRequired: notification.actionRequired,
                actionUrl: notification.actionUrl,
                expiresAt: notification.expiresAt,
                readAt: isRead ? Date() : notification.readAt,
                senderId: notification.senderId,
                targetEmployeeId: notification.targetEmployeeId,
                targetRole: notification.targetRole,
                metadata: notification.metadata
            )
        }
    }
    
    private func updateUnreadCount(_ count: Int) {
        let previousCount = unreadCount
        unreadCount = count
        
        if previousCount != count {
            NotificationCenter.default.post(
                name: .unreadNotificationsCountChanged,
                object: nil,
                userInfo: [NotificationKeys.unreadCount: count]
            )
        }
    }
    
    private func decrementUnreadCount() {
        if unreadCount > 0 {
            updateUnreadCount(unreadCount - 1)
        }
    }
    
    private func shouldRefreshCache() -> Bool {
        guard let lastUpdate = lastCacheUpdate else { return true }
        return Date().timeIntervalSince(lastUpdate) > cacheExpirationTime
    }
    
    // MARK: - Public Methods (continued)
    
    /// Odświeża dane jeśli cache wygasł
    func refreshIfNeeded() {
        if shouldRefreshCache() {
            fetchNotifications()
        }
    }
    
    /// Wymuś odświeżenie (dla pull-to-refresh)
    func forceRefresh() {
        lastCacheUpdate = nil
        fetchNotifications()
    }
    
    /// Oznacza wszystkie powiadomienia jako przeczytane
    func markAllAsRead() {
        let unreadNotifications = notifications.filter { !$0.isRead }
        guard !unreadNotifications.isEmpty else { return }
        
        // Optimistic update
        notifications = notifications.map { notification in
            if !notification.isRead {
                return AppNotification(
                    id: notification.id,
                    employeeId: notification.employeeId,
                    type: notification.type,
                    title: notification.title,
                    message: notification.message,
                    isRead: true,
                    createdAt: notification.createdAt,
                    updatedAt: Date(),
                    workEntryId: notification.workEntryId,
                    taskId: notification.taskId,
                    projectId: notification.projectId,
                    projectTitle: notification.projectTitle,
                    priority: notification.priority,
                    category: notification.category,
                    actionRequired: notification.actionRequired,
                    actionUrl: notification.actionUrl,
                    expiresAt: notification.expiresAt,
                    readAt: Date(),
                    senderId: notification.senderId,
                    targetEmployeeId: notification.targetEmployeeId,
                    targetRole: notification.targetRole,
                    metadata: notification.metadata
                )
            }
            return notification
        }
        unreadCount = 0
        
        // API calls (same as before)
        let markAsReadPublishers = unreadNotifications.map { notification in
            workerAPIService.markNotificationAsRead(id: notification.id)
        }
        
        Publishers.MergeMany(markAsReadPublishers)
            .collect()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        // Rollback - refetch notifications
                        self?.fetchNotifications()
                        self?.handleNotificationError(error)
                    }
                },
                receiveValue: { _ in
                    print("[NotificationService] Successfully marked all notifications as read")
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Periodic Refresh
    
    private func startPeriodicRefresh() {
        // Refresh co 5 minut
        refreshTimer = Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchUnreadCount()
            }
        
        // Background refresh co 30 sekund (tylko unread count)
        backgroundTaskTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                if UIApplication.shared.applicationState == .active {
                    self?.fetchUnreadCount()
                }
            }
    }
    
    private func stopPeriodicRefresh() {
        refreshTimer?.cancel()
        backgroundTaskTimer?.cancel()
        refreshTimer = nil
        backgroundTaskTimer = nil
    }
    
    // MARK: - Utility Methods (same as before)
    
    func getNotificationsRequiringAction() -> [AppNotification] {
        return notifications.filter { $0.requiresAction && !$0.isRead }
    }
    
    func getLatestNotification(ofType type: NotificationType) -> AppNotification? {
        return notifications.first { $0.type == type }
    }
    
    func getUnreadNotifications() -> [AppNotification] {
        return notifications.filter { !$0.isRead }
    }
    
    func getNotifications(forCategory category: NotificationCategory) -> [AppNotification] {
        return notifications.filter { $0.category == category }
    }
    
    func getNotifications(withPriority priority: NotificationPriority) -> [AppNotification] {
        return notifications.filter { $0.priority == priority }
    }
    
    func getUrgentUnreadNotifications() -> [AppNotification] {
        return notifications.filter { !$0.isRead && $0.isUrgent }
    }
    
    func getExpiringNotifications() -> [AppNotification] {
        let threshold = Date().addingTimeInterval(3600) // 1 hour
        return notifications.filter { notification in
            guard let expiresAt = notification.expiresAt else { return false }
            return expiresAt <= threshold && expiresAt > Date()
        }
    }
}
