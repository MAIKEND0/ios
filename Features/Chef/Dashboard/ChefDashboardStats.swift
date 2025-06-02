//
//  ChefDashboardStats.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//

import Foundation
import SwiftUI

// MARK: - Chef Dashboard Statistics Model

struct ChefDashboardStats: Codable {
    let overview: DashboardOverview
    let customers: CustomerMetrics
    let projects: ProjectMetrics
    let hiringRequests: HiringRequestMetrics
    let revenue: RevenueMetrics
    let performance: PerformanceMetrics
    let recentActivity: [RecentActivity]
    let upcomingTasks: [UpcomingTask]
    
    private enum CodingKeys: String, CodingKey {
        case overview, customers, projects
        case hiringRequests = "hiring_requests"
        case revenue, performance
        case recentActivity = "recent_activity"
        case upcomingTasks = "upcoming_tasks"
    }
    
    // MARK: - Dashboard Overview
    struct DashboardOverview: Codable {
        let totalCustomers: Int
        let activeProjects: Int
        let pendingRequests: Int
        let monthlyRevenue: Double
        let growthPercentage: Double
        let lastUpdated: Date
        
        private enum CodingKeys: String, CodingKey {
            case totalCustomers = "total_customers"
            case activeProjects = "active_projects"
            case pendingRequests = "pending_requests"
            case monthlyRevenue = "monthly_revenue"
            case growthPercentage = "growth_percentage"
            case lastUpdated = "last_updated"
        }
    }
    
    // MARK: - Customer Metrics
    struct CustomerMetrics: Codable {
        let total: Int
        let newThisMonth: Int
        let newThisWeek: Int
        let active: Int
        let inactive: Int
        let topCustomers: [TopCustomer]
        
        private enum CodingKeys: String, CodingKey {
            case total
            case newThisMonth = "new_this_month"
            case newThisWeek = "new_this_week"
            case active, inactive
            case topCustomers = "top_customers"
        }
        
        struct TopCustomer: Codable, Identifiable {
            let customerId: Int
            let name: String
            let projectCount: Int
            let totalRevenue: Double
            let lastProject: Date?
            
            var id: Int { customerId }
            
            private enum CodingKeys: String, CodingKey {
                case customerId = "customer_id"
                case name
                case projectCount = "project_count"
                case totalRevenue = "total_revenue"
                case lastProject = "last_project"
            }
        }
    }
    
    // MARK: - Project Metrics
    struct ProjectMetrics: Codable {
        let total: Int
        let active: Int
        let completed: Int
        let pending: Int
        let onHold: Int
        let completionRate: Double
        let averageDuration: Int // in days
        let upcomingDeadlines: [ProjectDeadline]
        
        private enum CodingKeys: String, CodingKey {
            case total, active, completed, pending
            case onHold = "on_hold"
            case completionRate = "completion_rate"
            case averageDuration = "average_duration"
            case upcomingDeadlines = "upcoming_deadlines"
        }
        
        struct ProjectDeadline: Codable, Identifiable {
            let projectId: Int
            let title: String
            let customerName: String
            let deadline: Date
            let daysRemaining: Int
            let status: String
            
            var id: Int { projectId }
            
            private enum CodingKeys: String, CodingKey {
                case projectId = "project_id"
                case title
                case customerName = "customer_name"
                case deadline
                case daysRemaining = "days_remaining"
                case status
            }
        }
    }
    
    // MARK: - Hiring Request Metrics
    struct HiringRequestMetrics: Codable {
        let total: Int
        let pending: Int
        let approved: Int
        let rejected: Int
        let fulfilled: Int
        let avgResponseTime: Double // in hours
        let urgentRequests: Int
        let recentRequests: [RecentHiringRequest]
        
        private enum CodingKeys: String, CodingKey {
            case total, pending, approved, rejected, fulfilled
            case avgResponseTime = "avg_response_time"
            case urgentRequests = "urgent_requests"
            case recentRequests = "recent_requests"
        }
        
        struct RecentHiringRequest: Codable, Identifiable {
            let requestId: Int
            let customerName: String
            let projectTitle: String
            let position: String
            let urgency: String
            let submittedAt: Date
            let status: String
            
            var id: Int { requestId }
            
            private enum CodingKeys: String, CodingKey {
                case requestId = "request_id"
                case customerName = "customer_name"
                case projectTitle = "project_title"
                case position, urgency
                case submittedAt = "submitted_at"
                case status
            }
        }
    }
    
    // MARK: - Revenue Metrics
    struct RevenueMetrics: Codable {
        let thisMonth: Double
        let lastMonth: Double
        let yearToDate: Double
        let projectedMonthly: Double
        let growthRate: Double
        let topRevenueStreams: [RevenueStream]
        let monthlyTrend: [MonthlyRevenue]
        
        private enum CodingKeys: String, CodingKey {
            case thisMonth = "this_month"
            case lastMonth = "last_month"
            case yearToDate = "year_to_date"
            case projectedMonthly = "projected_monthly"
            case growthRate = "growth_rate"
            case topRevenueStreams = "top_revenue_streams"
            case monthlyTrend = "monthly_trend"
        }
        
        struct RevenueStream: Codable, Identifiable {
            let id: Int
            let source: String
            let amount: Double
            let percentage: Double
            let trend: String
        }
        
        struct MonthlyRevenue: Codable {
            let month: String
            let year: Int
            let revenue: Double
            let projectCount: Int
            
            private enum CodingKeys: String, CodingKey {
                case month, year, revenue
                case projectCount = "project_count"
            }
        }
    }
    
    // MARK: - Performance Metrics
    struct PerformanceMetrics: Codable {
        let customerSatisfaction: Double
        let onTimeDelivery: Double
        let resourceUtilization: Double
        let avgProjectDuration: Double
        let repeatCustomerRate: Double
        let operationalEfficiency: Double
        
        private enum CodingKeys: String, CodingKey {
            case customerSatisfaction = "customer_satisfaction"
            case onTimeDelivery = "on_time_delivery"
            case resourceUtilization = "resource_utilization"
            case avgProjectDuration = "avg_project_duration"
            case repeatCustomerRate = "repeat_customer_rate"
            case operationalEfficiency = "operational_efficiency"
        }
    }
    
    // MARK: - Recent Activity
    struct RecentActivity: Codable, Identifiable {
        let id: Int
        let type: String
        let title: String
        let description: String
        let timestamp: Date
        let relatedEntity: String?
        let relatedEntityId: Int?
        let importance: String
        
        private enum CodingKeys: String, CodingKey {
            case id, type, title, description, timestamp
            case relatedEntity = "related_entity"
            case relatedEntityId = "related_entity_id"
            case importance
        }
    }
    
    // MARK: - Upcoming Tasks
    struct UpcomingTask: Codable, Identifiable {
        let id: Int
        let title: String
        let description: String
        let dueDate: Date
        let priority: String
        let assignedTo: String?
        let relatedProject: String?
        let relatedCustomer: String?
        let completed: Bool
        
        private enum CodingKeys: String, CodingKey {
            case id, title, description
            case dueDate = "due_date"
            case priority
            case assignedTo = "assigned_to"
            case relatedProject = "related_project"
            case relatedCustomer = "related_customer"
            case completed
        }
    }
    
    // MARK: - Computed Properties
    
    var totalActiveEntities: Int {
        return customers.active + projects.active
    }
    
    var customerGrowthRate: Double {
        guard customers.total > 0 else { return 0.0 }
        return (Double(customers.newThisMonth) / Double(customers.total)) * 100
    }
    
    var projectSuccessRate: Double {
        guard projects.total > 0 else { return 0.0 }
        return (Double(projects.completed) / Double(projects.total)) * 100
    }
    
    var hiringRequestEfficiency: Double {
        guard hiringRequests.total > 0 else { return 0.0 }
        return (Double(hiringRequests.approved + hiringRequests.fulfilled) / Double(hiringRequests.total)) * 100
    }
    
    var revenueGrowth: Double {
        guard revenue.lastMonth > 0 else { return 0.0 }
        return ((revenue.thisMonth - revenue.lastMonth) / revenue.lastMonth) * 100
    }
    
    // MARK: - Mock Data for Development
    
    static let mockData = ChefDashboardStats(
        overview: DashboardOverview(
            totalCustomers: 25,
            activeProjects: 12,
            pendingRequests: 8,
            monthlyRevenue: 145000.0,
            growthPercentage: 12.5,
            lastUpdated: Date()
        ),
        customers: CustomerMetrics(
            total: 25,
            newThisMonth: 5,
            newThisWeek: 2,
            active: 18,
            inactive: 7,
            topCustomers: [
                CustomerMetrics.TopCustomer(
                    customerId: 1,
                    name: "Copenhagen Construction Group",
                    projectCount: 8,
                    totalRevenue: 45000.0,
                    lastProject: Date()
                ),
                CustomerMetrics.TopCustomer(
                    customerId: 2,
                    name: "Nordic Building Solutions",
                    projectCount: 6,
                    totalRevenue: 32000.0,
                    lastProject: Calendar.current.date(byAdding: .day, value: -5, to: Date())
                )
            ]
        ),
        projects: ProjectMetrics(
            total: 45,
            active: 12,
            completed: 28,
            pending: 3,
            onHold: 2,
            completionRate: 85.5,
            averageDuration: 45,
            upcomingDeadlines: [
                ProjectMetrics.ProjectDeadline(
                    projectId: 1,
                    title: "Office Tower Construction",
                    customerName: "Copenhagen Construction Group",
                    deadline: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                    daysRemaining: 7,
                    status: "on_track"
                )
            ]
        ),
        hiringRequests: HiringRequestMetrics(
            total: 78,
            pending: 8,
            approved: 45,
            rejected: 12,
            fulfilled: 13,
            avgResponseTime: 4.2,
            urgentRequests: 3,
            recentRequests: [
                HiringRequestMetrics.RecentHiringRequest(
                    requestId: 1,
                    customerName: "Nordic Building Solutions",
                    projectTitle: "Residential Complex",
                    position: "Crane Operator",
                    urgency: "high",
                    submittedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                    status: "pending"
                )
            ]
        ),
        revenue: RevenueMetrics(
            thisMonth: 145000.0,
            lastMonth: 128000.0,
            yearToDate: 1450000.0,
            projectedMonthly: 155000.0,
            growthRate: 13.3,
            topRevenueStreams: [
                RevenueMetrics.RevenueStream(
                    id: 1,
                    source: "Crane Operations",
                    amount: 85000.0,
                    percentage: 58.6,
                    trend: "up"
                ),
                RevenueMetrics.RevenueStream(
                    id: 2,
                    source: "Equipment Rental",
                    amount: 45000.0,
                    percentage: 31.0,
                    trend: "stable"
                )
            ],
            monthlyTrend: []
        ),
        performance: PerformanceMetrics(
            customerSatisfaction: 4.8,
            onTimeDelivery: 92.0,
            resourceUtilization: 85.5,
            avgProjectDuration: 45.2,
            repeatCustomerRate: 78.0,
            operationalEfficiency: 88.5
        ),
        recentActivity: [
            RecentActivity(
                id: 1,
                type: "project_completed",
                title: "Project Completed",
                description: "Residential Tower project completed successfully",
                timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                relatedEntity: "project",
                relatedEntityId: 15,
                importance: "high"
            ),
            RecentActivity(
                id: 2,
                type: "customer_added",
                title: "New Customer",
                description: "Fresh Construction added as new customer",
                timestamp: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date(),
                relatedEntity: "customer",
                relatedEntityId: 26,
                importance: "medium"
            )
        ],
        upcomingTasks: [
            UpcomingTask(
                id: 1,
                title: "Equipment Inspection",
                description: "Monthly safety inspection for Crane Unit #A-205",
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                priority: "high",
                assignedTo: "Safety Team",
                relatedProject: nil,
                relatedCustomer: nil,
                completed: false
            ),
            UpcomingTask(
                id: 2,
                title: "Client Meeting",
                description: "Quarterly review with Copenhagen Construction Group",
                dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
                priority: "medium",
                assignedTo: "Account Manager",
                relatedProject: "Office Tower Construction",
                relatedCustomer: "Copenhagen Construction Group",
                completed: false
            )
        ]
    )
}
