//
//  ChefDashboardViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//  Updated with Payroll Integration - FIXED VERSION
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ChefDashboardViewModel: ObservableObject {
    @Published var dashboardStats: ChefDashboardStats?
    @Published var payrollStats: PayrollStats = PayrollStats.mockData
    @Published var recentActivities: [CombinedActivity] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var lastRefreshTime: Date?
    @Published var selectedNavigationDestination: NavigationDestination?
    @Published var pendingLeaveRequests: Int = 0
    
    private var apiService: ChefAPIService {
        return ChefAPIService.shared
    }
    private var payrollAPIService: PayrollAPIService {
        return PayrollAPIService.shared
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
    
    // Payroll-related computed properties
    var shouldShowPayrollAlert: Bool {
        return payrollStats.pendingHours > 0 || payrollStats.activeBatches > 3
    }
    
    init() {
        Task {
            await loadEnhancedData()
        }
        setupAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Enhanced Data Loading with Payroll Integration
    
    func loadEnhancedData() async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = true
            }
        }
        
        #if DEBUG
        print("[ChefDashboardViewModel] Loading enhanced dashboard with payroll data...")
        #endif
        
        // Combine dashboard stats and payroll data loading
        let dashboardStatsPublisher = apiService.fetchChefDashboardStats()
        let payrollStatsPublisher = payrollAPIService.fetchPayrollDashboardStats()
        let recentActivityPublisher = payrollAPIService.fetchRecentActivity()
        
        Publishers.CombineLatest3(dashboardStatsPublisher, payrollStatsPublisher, recentActivityPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.isLoading = false
                    }
                    
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "loading enhanced dashboard")
                        // Fall back to mock data if API fails
                        self?.loadMockData()
                    }
                    
                    self?.lastRefreshTime = Date()
                },
                receiveValue: { [weak self] (dashboardStats, payrollStatsResponse, recentActivity) in
                    self?.dashboardStats = dashboardStats
                    // 🔧 FIXED: Extract overview from PayrollDashboardStatsResponse
                    self?.payrollStats = PayrollStats.from(payrollStatsResponse.overview)
                    self?.combineRecentActivities(regular: self?.getRecentActivities(limit: 10) ?? [], payroll: recentActivity)
                    
                    // TODO: Fetch from leave API endpoint
                    self?.pendingLeaveRequests = 3 // Hardcoded for now
                    
                    #if DEBUG
                    print("[ChefDashboardViewModel] Enhanced dashboard data loaded successfully")
                    print("- Pending payroll hours: \(payrollStatsResponse.overview.pendingHours)")
                    print("- Active payroll batches: \(payrollStatsResponse.overview.activeBatches)")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func loadData() {
        Task {
            await loadEnhancedData()
        }
    }
    
    func refreshData() {
        Task {
            await loadEnhancedData()
        }
    }
    
    // MARK: - Mock Data Loading
    
    private func loadMockData() {
        dashboardStats = ChefDashboardStats.mockData
        payrollStats = PayrollStats.mockData
        combineRecentActivities(regular: getRecentActivities(limit: 10), payroll: [])
        
        #if DEBUG
        print("[ChefDashboardViewModel] Loaded enhanced mock data")
        #endif
    }
    
    // MARK: - Payroll Integration Methods
    
    func getPayrollAlertMessage() -> String {
        var messages: [String] = []
        
        if payrollStats.pendingHours > 0 {
            messages.append("\(payrollStats.pendingHours) hours pending approval")
        }
        
        if payrollStats.activeBatches > 3 {
            messages.append("\(payrollStats.activeBatches) active batches")
        }
        
        if payrollStats.failedBatches > 0 {
            messages.append("\(payrollStats.failedBatches) failed batches need attention")
        }
        
        return messages.isEmpty ? "System operating normally" : messages.joined(separator: " • ")
    }
    
    func getCombinedRecentActivities() -> [CombinedActivity] {
        return recentActivities.sorted { activity1, activity2 in
            activity1.timestamp > activity2.timestamp
        }
    }
    
    private func combineRecentActivities(regular: [RecentActivity], payroll: [PayrollActivity]) {
        var combined: [CombinedActivity] = []
        
        // Add regular activities
        for activity in regular {
            combined.append(CombinedActivity(
                icon: activity.icon,
                title: activity.title,
                subtitle: activity.subtitle,
                timeAgo: activity.timeAgo,
                color: activity.color,
                type: .regular,
                timestamp: activity.timestamp
            ))
        }
        
        // Add payroll activities
        for activity in payroll {
            combined.append(CombinedActivity(
                icon: activity.type.icon,
                title: activity.title,
                subtitle: activity.description,
                timeAgo: activity.timeAgo,
                color: activity.type.color,
                type: .payroll,
                timestamp: activity.timestamp
            ))
        }
        
        // Sort by timestamp and take most recent
        recentActivities = combined.sorted { activity1, activity2 in
            activity1.timestamp > activity2.timestamp
        }
    }
    
    // MARK: - Auto Refresh
    
    private func setupAutoRefresh() {
        // Refresh every 5 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.loadEnhancedData()
            }
        }
    }
    
    // MARK: - Quick Actions
    
    func handleQuickAction(_ actionType: QuickActionType) {
        #if DEBUG
        print("[ChefDashboardViewModel] handleQuickAction called with: \(actionType)")
        #endif
        
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
            
        case .leaveManagement:
            #if DEBUG
            print("[ChefDashboardViewModel] Leave Management action triggered")
            #endif
            selectedNavigationDestination = .leaveManagement
            
        case .payrollDashboard:
            #if DEBUG
            print("[ChefDashboardViewModel] Payroll Dashboard action triggered")
            #endif
            selectedNavigationDestination = .payrollDashboard
            
        case .pendingHours:
            #if DEBUG
            print("[ChefDashboardViewModel] Pending Hours action triggered")
            #endif
            selectedNavigationDestination = .pendingHours
            
        case .payrollBatches:
            #if DEBUG
            print("[ChefDashboardViewModel] Payroll Batches action triggered")
            #endif
            selectedNavigationDestination = .payrollBatches
            
        case .createBatch:
            #if DEBUG
            print("[ChefDashboardViewModel] Create Batch action triggered")
            #endif
            selectedNavigationDestination = .createBatch
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

// MARK: - Payroll Stats Model

struct PayrollStats {
    let pendingHours: Int
    let readyEmployees: Int
    let activeBatches: Int
    let failedBatches: Int
    let monthlyAmount: Decimal
    let completedBatches: Int
    
    static let mockData = PayrollStats(
        pendingHours: 87,
        readyEmployees: 15,
        activeBatches: 3,
        failedBatches: 1,
        monthlyAmount: Decimal(156750.0),
        completedBatches: 12
    )
    
    static func from(_ dashboardStats: PayrollDashboardStats) -> PayrollStats {
        return PayrollStats(
            pendingHours: dashboardStats.pendingHours,
            readyEmployees: dashboardStats.readyEmployees,
            activeBatches: dashboardStats.activeBatches,
            failedBatches: 0, // Add to PayrollDashboardStats if needed
            monthlyAmount: dashboardStats.totalAmount,
            completedBatches: 0 // Add to PayrollDashboardStats if needed
        )
    }
}

// MARK: - Supporting Models

enum QuickActionType {
    case addCustomer
    case newProject
    case addWorker
    case createTask
    case leaveManagement
    case payrollDashboard
    case pendingHours
    case payrollBatches
    case createBatch
}

enum NavigationDestination: Identifiable {
    case payrollDashboard
    case pendingHours
    case payrollBatches
    case createBatch
    case leaveManagement
    
    var id: String {
        switch self {
        case .payrollDashboard: return "payrollDashboard"
        case .pendingHours: return "pendingHours"
        case .payrollBatches: return "payrollBatches"
        case .createBatch: return "createBatch"
        case .leaveManagement: return "leaveManagement"
        }
    }
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

// MARK: - Enhanced Combined Activity Model

struct CombinedActivity: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let timeAgo: String
    let color: Color
    let type: ActivityType
    let timestamp: Date
    
    enum ActivityType {
        case regular
        case payroll
    }
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

// Note: Decimal.shortCurrencyFormatted is already defined in PayrollModels.swift
