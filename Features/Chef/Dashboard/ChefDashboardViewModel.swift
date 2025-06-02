//
//  ChefDashboardViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//

import SwiftUI
import Combine

class ChefDashboardViewModel: ObservableObject {
    @Published var dashboardStats: ChefDashboardStats?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var lastRefreshTime: Date?
    
    private var apiService: ChefAPIService {
        return ChefAPIService.shared
    }
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // Computed properties for backwards compatibility with existing UI
    var stats: DashboardStatsCompat {
        guard let dashboardStats = dashboardStats else {
            return DashboardStatsCompat.from(ChefDashboardStats.mockData)
        }
        return DashboardStatsCompat.from(dashboardStats)
    }
    
    init() {
        loadData()
        setupAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    func loadData() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        #if DEBUG
        print("[ChefDashboardViewModel] Loading dashboard statistics...")
        #endif
        
        // Try to load from API, fall back to mock data on failure
        apiService.fetchChefDashboardStats()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "loading dashboard statistics")
                        // Fall back to mock data if API fails
                        self?.dashboardStats = ChefDashboardStats.mockData
                    }
                    
                    self?.lastRefreshTime = Date()
                },
                receiveValue: { [weak self] stats in
                    self?.dashboardStats = stats
                    
                    #if DEBUG
                    print("[ChefDashboardViewModel] Dashboard stats loaded successfully")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshData() {
        loadData()
    }
    
    // MARK: - Auto Refresh
    
    private func setupAutoRefresh() {
        // Refresh every 5 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.loadData()
        }
    }
    
    // MARK: - Quick Actions
    
    func handleQuickAction(_ actionType: QuickActionType) {
        switch actionType {
        case .addCustomer:
            #if DEBUG
            print("[ChefDashboardViewModel] Add Customer action triggered")
            #endif
            // TODO: Navigate to CreateCustomerView
            
        case .newProject:
            #if DEBUG
            print("[ChefDashboardViewModel] New Project action triggered")
            #endif
            // TODO: Navigate to CreateProjectView
            
        case .addWorker:
            #if DEBUG
            print("[ChefDashboardViewModel] Add Worker action triggered")
            #endif
            // TODO: Navigate to CreateWorkerView
            
        case .createTask:
            #if DEBUG
            print("[ChefDashboardViewModel] Create Task action triggered")
            #endif
            // TODO: Navigate to CreateTaskView
        }
    }
    
    // MARK: - Helper Methods
    
    func showError(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - Data Access Helpers
    
    func getRecentActivities(limit: Int = 5) -> [RecentActivity] {
        return Array(RecentActivity.mockActivities.prefix(limit))
    }
    
    func getFormattedLastRefresh() -> String {
        guard let lastRefresh = lastRefreshTime else { return "Never" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lastRefresh)
    }
    
    // MARK: - Error Handling
    
    private func handleAPIError(_ error: BaseAPIService.APIError, context: String) {
        var title = "Error"
        var message = "An unexpected error occurred."
        
        switch error {
        case .invalidURL:
            title = "Invalid URL"
            message = "The request URL is invalid."
        case .invalidResponse:
            title = "Invalid Response"
            message = "The server response is invalid."
        case .networkError(let networkError):
            title = "Network Error"
            message = "Please check your internet connection and try again. (\(networkError.localizedDescription))"
        case .decodingError(let decodingError):
            title = "Data Error"
            message = "Unable to process the server response. (\(decodingError.localizedDescription))"
        case .serverError(let statusCode, let serverMessage):
            title = "Server Error"
            message = "Server returned error \(statusCode): \(serverMessage)"
        case .unknown:
            title = "Unknown Error"
            message = "An unexpected error occurred while \(context)."
        }
        
        showError(title, message)
        
        #if DEBUG
        print("[ChefDashboardViewModel] API Error in \(context): \(error)")
        #endif
    }
}

// MARK: - Compatibility Layer

// This struct provides backwards compatibility with the existing UI
struct DashboardStatsCompat {
    let totalCustomers: Int
    let activeProjects: Int
    let completedProjects: Int
    let totalTasks: Int
    let assignedTasks: Int
    let unassignedTasks: Int
    let totalWorkers: Int
    let availableWorkers: Int
    let workersOnAssignment: Int
    let totalManagers: Int
    let pendingApprovals: Int
    let monthlyRevenue: Double
    let averageProjectDuration: Double
    
    // Computed properties for display
    var projectCompletionRate: Double {
        let total = activeProjects + completedProjects
        return total > 0 ? Double(completedProjects) / Double(total) * 100 : 0
    }
    
    var workerUtilizationRate: Double {
        return totalWorkers > 0 ? Double(workersOnAssignment) / Double(totalWorkers) * 100 : 0
    }
    
    var taskAssignmentRate: Double {
        return totalTasks > 0 ? Double(assignedTasks) / Double(totalTasks) * 100 : 0
    }
    
    // Convert from comprehensive ChefDashboardStats to simple compat format
    static func from(_ stats: ChefDashboardStats) -> DashboardStatsCompat {
        return DashboardStatsCompat(
            totalCustomers: stats.overview.totalCustomers,
            activeProjects: stats.overview.activeProjects,
            completedProjects: stats.projects.completed,
            totalTasks: stats.projects.total + stats.hiringRequests.total, // Combine project and hiring tasks
            assignedTasks: stats.projects.active + stats.hiringRequests.approved,
            unassignedTasks: stats.projects.pending + stats.hiringRequests.pending,
            totalWorkers: 25, // Mock value - add to comprehensive model if needed
            availableWorkers: 10, // Mock value
            workersOnAssignment: 15, // Mock value
            totalManagers: 4, // Mock value
            pendingApprovals: stats.hiringRequests.pending,
            monthlyRevenue: stats.overview.monthlyRevenue,
            averageProjectDuration: stats.projects.averageDuration.description.isEmpty ? 14.5 : Double(stats.projects.averageDuration)
        )
    }
}

// MARK: - Supporting Models

enum QuickActionType {
    case addCustomer
    case newProject
    case addWorker
    case createTask
}

// MARK: - Recent Activity Models

struct RecentActivity {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let timestamp: Date
    let color: Color
    let actionType: RecentActivityType
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    // Mock recent activities
    static let mockActivities = [
        RecentActivity(
            icon: "folder.badge.plus",
            title: "New project created",
            subtitle: "Construction Site Alpha - Vesterbro",
            timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            color: Color.ksrSuccess,
            actionType: .projectCreated
        ),
        RecentActivity(
            icon: "person.badge.plus",
            title: "New worker added",
            subtitle: "Lars Hansen - Tower Crane Operator",
            timestamp: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date(),
            color: Color.ksrPrimary,
            actionType: .workerAdded
        ),
        RecentActivity(
            icon: "checkmark.circle.fill",
            title: "Task completed",
            subtitle: "Tower crane installation - Nørrebro Site",
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            color: Color.ksrInfo,
            actionType: .taskCompleted
        ),
        RecentActivity(
            icon: "building.2.badge.plus",
            title: "New customer registered",
            subtitle: "Copenhagen Construction Group",
            timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            color: Color.ksrWarning,
            actionType: .customerAdded
        ),
        RecentActivity(
            icon: "exclamationmark.triangle.fill",
            title: "Task requires attention",
            subtitle: "Equipment maintenance overdue",
            timestamp: Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date(),
            color: Color.red,
            actionType: .alertGenerated
        )
    ]
}

enum RecentActivityType {
    case projectCreated
    case workerAdded
    case taskCompleted
    case customerAdded
    case alertGenerated
    case managerAssigned
}

// MARK: - Extensions for Formatting

extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "DKK"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "0 kr"
    }
    
    var percentageFormatted: String {
        return String(format: "%.1f%%", self)
    }
    
    var oneDecimalFormatted: String {
        return String(format: "%.1f", self)
    }
}

extension Int {
    var shortFormatted: String {
        if self >= 1000 {
            return String(format: "%.1fK", Double(self) / 1000.0)
        }
        return "\(self)"
    }
}
