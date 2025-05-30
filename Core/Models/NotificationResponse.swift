//
//  NotificationResponse.swift
//  KSR Cranes App
//
//  Created by System on 26/05/2025.
//

import Foundation

// ========== ODPOWIEDŹ DLA LISTY POWIADOMIEŃ ==========

struct NotificationsResponse: Codable {
    let notifications: [AppNotification]
    let totalCount: Int?
    let unreadCount: Int?
    
    private enum CodingKeys: String, CodingKey {
        case notifications
        case totalCount = "total_count"
        case unreadCount = "unread_count"
    }
}

// ========== ODPOWIEDŹ DLA LICZBY NIEPRZECZYTANYCH ==========

struct UnreadNotificationsCountResponse: Codable {
    let unreadCount: Int
    
    private enum CodingKeys: String, CodingKey {
        case unreadCount = "unread_count"
    }
}

// ========== ODPOWIEDŹ DLA OZNACZANIA JAKO PRZECZYTANE ==========

struct MarkAsReadResponse: Codable {
    let success: Bool
    let message: String?
    let notificationId: Int?
    let notification: AppNotification?  // ✅ DODANE: pełne dane powiadomienia
    
    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case notificationId = "notification_id"
        case notification
    }
}

// ========== ODPOWIEDŹ DLA TWORZENIA POWIADOMIENIA ==========

struct CreateNotificationResponse: Codable {
    let success: Bool
    let notificationId: Int?
    let message: String
    
    private enum CodingKeys: String, CodingKey {
        case success
        case notificationId = "notification_id"
        case message
    }
}

// ========== ODPOWIEDŹ DLA STATYSTYK POWIADOMIEŃ ==========

struct NotificationStatsResponse: Codable {
    let unreadCount: Int
    let totalCount: Int
    let urgentCount: Int
    
    private enum CodingKeys: String, CodingKey {
        case unreadCount = "unread_count"
        case totalCount = "total_count"
        case urgentCount = "urgent_count"
    }
}

// ========== OGÓLNA ODPOWIEDŹ API ==========

struct NotificationAPIResponse<T: Codable>: Codable {
    let data: T?
    let error: String?
    let success: Bool
    let timestamp: Date?
    let metadata: NotificationMetadata?
    
    struct NotificationMetadata: Codable {
        let page: Int?
        let pageSize: Int?
        let hasMore: Bool?
        let version: String?
    }
    
    init(data: T? = nil, error: String? = nil, success: Bool = true, metadata: NotificationMetadata? = nil) {
        self.data = data
        self.error = error
        self.success = success
        self.timestamp = Date()
        self.metadata = metadata
    }
}

// ========== BŁĘDY POWIADOMIEŃ ==========

enum NotificationError: Error, LocalizedError {
    case networkError(String)
    case decodingError(String)
    case unauthorized
    case notFound
    case serverError(String)
    case unknownError
    case rateLimitExceeded
    case invalidRequest(String)
    case expiredToken
    case insufficientPermissions
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Data parsing error: \(message)"
        case .unauthorized:
            return "Unauthorized access. Please log in again."
        case .notFound:
            return "Notification not found"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .expiredToken:
            return "Your session has expired. Please log in again."
        case .insufficientPermissions:
            return "You don't have permission to perform this action."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again"
        case .decodingError:
            return "Please update the app to the latest version"
        case .unauthorized, .expiredToken:
            return "Please log out and log in again"
        case .notFound:
            return "The notification may have been deleted"
        case .serverError:
            return "Please try again later"
        case .unknownError:
            return "Please restart the app and try again"
        case .rateLimitExceeded:
            return "Wait a moment before making another request"
        case .invalidRequest:
            return "Please check your input and try again"
        case .insufficientPermissions:
            return "Contact your administrator for access"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .networkError:
            return "Network connectivity issue"
        case .decodingError:
            return "Data format incompatibility"
        case .unauthorized, .expiredToken:
            return "Authentication failure"
        case .notFound:
            return "Resource not available"
        case .serverError:
            return "Server processing error"
        case .rateLimitExceeded:
            return "Request limit exceeded"
        case .invalidRequest:
            return "Invalid input parameters"
        case .insufficientPermissions:
            return "Access denied"
        case .unknownError:
            return "Unexpected error"
        }
    }
}

// ========== PARAMETRY ZAPYTANIA O POWIADOMIENIA ==========

struct NotificationQueryParams {
    let limit: Int?
    let unreadOnly: Bool?
    let type: NotificationType?
    let category: NotificationCategory?
    let priority: NotificationPriority?
    let sinceDate: Date?
    let beforeDate: Date?
    let includeExpired: Bool?
    let sortBy: SortOption?
    let sortOrder: SortOrder?
    
    enum SortOption: String, CaseIterable {
        case createdAt = "created_at"
        case priority = "priority"
        case category = "category"
        case readStatus = "read_status"
    }
    
    enum SortOrder: String, CaseIterable {
        case ascending = "asc"
        case descending = "desc"
    }
    
    init(
        limit: Int? = nil,
        unreadOnly: Bool? = nil,
        type: NotificationType? = nil,
        category: NotificationCategory? = nil,
        priority: NotificationPriority? = nil,
        sinceDate: Date? = nil,
        beforeDate: Date? = nil,
        includeExpired: Bool? = nil,
        sortBy: SortOption? = nil,
        sortOrder: SortOrder? = nil
    ) {
        self.limit = limit
        self.unreadOnly = unreadOnly
        self.type = type
        self.category = category
        self.priority = priority
        self.sinceDate = sinceDate
        self.beforeDate = beforeDate
        self.includeExpired = includeExpired
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }
    
    /// Konwertuje parametry do query string
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        if let limit = limit {
            items.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        if let unreadOnly = unreadOnly {
            items.append(URLQueryItem(name: "unread_only", value: String(unreadOnly)))
        }
        
        if let type = type {
            items.append(URLQueryItem(name: "type", value: type.rawValue))
        }
        
        if let category = category {
            items.append(URLQueryItem(name: "category", value: category.rawValue))
        }
        
        if let priority = priority {
            items.append(URLQueryItem(name: "priority", value: priority.rawValue))
        }
        
        if let sinceDate = sinceDate {
            let formatter = ISO8601DateFormatter()
            items.append(URLQueryItem(name: "since", value: formatter.string(from: sinceDate)))
        }
        
        if let beforeDate = beforeDate {
            let formatter = ISO8601DateFormatter()
            items.append(URLQueryItem(name: "before", value: formatter.string(from: beforeDate)))
        }
        
        if let includeExpired = includeExpired {
            items.append(URLQueryItem(name: "include_expired", value: String(includeExpired)))
        }
        
        if let sortBy = sortBy {
            items.append(URLQueryItem(name: "sort_by", value: sortBy.rawValue))
        }
        
        if let sortOrder = sortOrder {
            items.append(URLQueryItem(name: "sort_order", value: sortOrder.rawValue))
        }
        
        return items
    }
}

// ========== BULK OPERATIONS ==========

struct BulkMarkAsReadRequest: Codable {
    let notificationIds: [Int]
    
    private enum CodingKeys: String, CodingKey {
        case notificationIds = "notification_ids"
    }
}

struct BulkMarkAsReadResponse: Codable {
    let success: Bool
    let message: String
    let processedCount: Int
    let failedIds: [Int]?
    
    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case processedCount = "processed_count"
        case failedIds = "failed_ids"
    }
}

// ========== MOCK RESPONSES DLA TESTÓW ==========

extension NotificationsResponse {
    static let mockSuccess = NotificationsResponse(
        notifications: AppNotification.mockData,
        totalCount: 3,
        unreadCount: 2
    )
    
    static let mockEmpty = NotificationsResponse(
        notifications: [],
        totalCount: 0,
        unreadCount: 0
    )
    
    static let mockWithPriority = NotificationsResponse(
        notifications: [
            AppNotification.mockEmergencyAlert,
            AppNotification.mockRejected,
            AppNotification.mockConfirmed
        ],
        totalCount: 3,
        unreadCount: 2
    )
}

extension UnreadNotificationsCountResponse {
    static let mockWithUnread = UnreadNotificationsCountResponse(unreadCount: 5)
    static let mockNoUnread = UnreadNotificationsCountResponse(unreadCount: 0)
    static let mockHighUnread = UnreadNotificationsCountResponse(unreadCount: 25)
}

extension MarkAsReadResponse {
    static let mockSuccess = MarkAsReadResponse(
        success: true,
        message: "Notification marked as read",
        notificationId: 1,
        notification: AppNotification.mockConfirmed
    )
    
    static let mockError = MarkAsReadResponse(
        success: false,
        message: "Failed to mark notification as read",
        notificationId: nil,
        notification: nil
    )
}

extension NotificationStatsResponse {
    static let mockStats = NotificationStatsResponse(
        unreadCount: 12,
        totalCount: 45,
        urgentCount: 2
    )
    
    static let mockEmptyStats = NotificationStatsResponse(
        unreadCount: 0,
        totalCount: 0,
        urgentCount: 0
    )
}
