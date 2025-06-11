//
//  BusinessTimelineModels.swift
//  KSR Cranes App
//
//  Business Intelligence Timeline Models for Operator Service Lifecycle
//  ✅ FIXED: Removed AnyCodable redeclaration, fixed all conflicts
//

import Foundation
import SwiftUI
import Combine

// MARK: - 🎯 Business Timeline Response Models

/// Main API response for business timeline
struct BusinessTimelineResponse: Codable {
    let projectId: Int
    let businessHealth: BusinessHealthScore
    let timeline: [BusinessTimelineEvent]
    let keyMetrics: BusinessKeyMetrics
    let insights: [BusinessInsight]
    let recommendations: [BusinessRecommendation]
    
    private enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case businessHealth = "business_health"
        case timeline
        case keyMetrics = "key_metrics"
        case insights
        case recommendations
    }
}

/// Business health score for the project
struct BusinessHealthScore: Codable {
    let overall: Double // 0-100
    let financial: Double
    let operational: Double
    let client: Double
    let status: HealthStatus
    let trend: HealthTrend
    
    enum HealthStatus: String, Codable, CaseIterable {
        case excellent = "excellent"
        case good = "good"
        case fair = "fair"
        case poor = "poor"
        
        var color: Color {
            switch self {
            case .excellent: return .ksrSuccess
            case .good: return .ksrInfo
            case .fair: return .ksrWarning
            case .poor: return .ksrError
            }
        }
        
        var icon: String {
            switch self {
            case .excellent: return "checkmark.circle.fill"
            case .good: return "checkmark.circle"
            case .fair: return "exclamationmark.triangle"
            case .poor: return "xmark.circle.fill"
            }
        }
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
    
    enum HealthTrend: String, Codable {
        case improving = "improving"
        case stable = "stable"
        case declining = "declining"
        
        var icon: String {
            switch self {
            case .improving: return "arrow.up.circle.fill"
            case .stable: return "minus.circle.fill"
            case .declining: return "arrow.down.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .improving: return .ksrSuccess
            case .stable: return .ksrInfo
            case .declining: return .ksrWarning
            }
        }
    }
}

// MARK: - 📊 Business Timeline Events

/// Individual timeline event
struct BusinessTimelineEvent: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let type: EventType
    let category: EventCategory
    let title: String
    let description: String
    let impact: EventImpact
    let metrics: [String: Any]?
    let relatedEntities: RelatedEntities?
    
    // Custom coding keys for JSON mapping
    private enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case type
        case category
        case title
        case description
        case impact
        case metrics
        case relatedEntities = "related_entities"
    }
    
    // Custom decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        type = try container.decode(EventType.self, forKey: .type)
        category = try container.decode(EventCategory.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        impact = try container.decode(EventImpact.self, forKey: .impact)
        relatedEntities = try container.decodeIfPresent(RelatedEntities.self, forKey: .relatedEntities)
        
        // Handle metrics as generic dictionary
        if let metricsData = try container.decodeIfPresent(Data.self, forKey: .metrics) {
            metrics = try JSONSerialization.jsonObject(with: metricsData) as? [String: Any]
        } else {
            metrics = nil
        }
    }
    
    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encode(category, forKey: .category)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(impact, forKey: .impact)
        try container.encodeIfPresent(relatedEntities, forKey: .relatedEntities)
        
        if let metrics = metrics {
            let metricsData = try JSONSerialization.data(withJSONObject: metrics)
            try container.encode(metricsData, forKey: .metrics)
        }
    }
    
    // Manual initializer for creating instances
    init(
        id: String,
        timestamp: Date,
        type: EventType,
        category: EventCategory,
        title: String,
        description: String,
        impact: EventImpact,
        metrics: [String: Any]? = nil,
        relatedEntities: RelatedEntities? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.category = category
        self.title = title
        self.description = description
        self.impact = impact
        self.metrics = metrics
        self.relatedEntities = relatedEntities
    }
    
    enum EventType: String, Codable, CaseIterable {
        // 📋 Contract Lifecycle
        case contractAwarded = "contract_awarded"
        case serviceAgreementSigned = "service_agreement_signed"
        case billingSetupCompleted = "billing_setup_completed"
        
        // 👷 Operator Deployment
        case operatorsAssigned = "operators_assigned"
        case onSiteDeployment = "onsite_deployment"
        case teamLeaderAppointed = "team_leader_appointed"
        
        // ⚡ Performance Events
        case weeklyMilestone = "weekly_milestone"
        case performanceTarget = "performance_target"
        case safetyMilestone = "safety_milestone"
        
        // 💰 Financial Events
        case billingCycleCompleted = "billing_cycle_completed"
        case paymentReceived = "payment_received"
        case profitMarginAchieved = "profit_margin_achieved"
        
        // 🎯 Business Intelligence
        case resourceUtilizationPeak = "resource_utilization_peak"
        case clientSatisfactionAchievement = "client_satisfaction_achievement"
        case businessAlert = "business_alert"
        case growthOpportunity = "growth_opportunity"
        
        var icon: String {
            switch self {
            // Contract
            case .contractAwarded: return "doc.fill"
            case .serviceAgreementSigned: return "signature"
            case .billingSetupCompleted: return "dollarsign.circle.fill"
            
            // Operators
            case .operatorsAssigned: return "person.badge.plus"
            case .onSiteDeployment: return "truck.box.fill"
            case .teamLeaderAppointed: return "person.crop.circle.badge.checkmark"
            
            // Performance
            case .weeklyMilestone: return "chart.line.uptrend.xyaxis"
            case .performanceTarget: return "target"
            case .safetyMilestone: return "shield.checkered"
            
            // Financial
            case .billingCycleCompleted: return "creditcard.fill"
            case .paymentReceived: return "banknote.fill"
            case .profitMarginAchieved: return "chart.pie.fill"
            
            // Business Intelligence
            case .resourceUtilizationPeak: return "gauge.high"
            case .clientSatisfactionAchievement: return "hand.thumbsup.fill"
            case .businessAlert: return "bell.fill"
            case .growthOpportunity: return "arrow.up.right.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            // Contract - Blue
            case .contractAwarded, .serviceAgreementSigned, .billingSetupCompleted:
                return .ksrInfo
            
            // Operators - Green
            case .operatorsAssigned, .onSiteDeployment, .teamLeaderAppointed:
                return .ksrSuccess
            
            // Performance - Orange
            case .weeklyMilestone, .performanceTarget, .safetyMilestone:
                return .ksrWarning
            
            // Financial - Purple
            case .billingCycleCompleted, .paymentReceived, .profitMarginAchieved:
                return .purple
            
            // Business Intelligence - Yellow
            case .resourceUtilizationPeak, .clientSatisfactionAchievement, .businessAlert, .growthOpportunity:
                return .ksrYellow
            }
        }
    }
    
    enum EventCategory: String, Codable, CaseIterable {
        case contract = "contract"
        case operators = "operators"
        case performance = "performance"
        case financial = "financial"
        case intelligence = "intelligence"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var color: Color {
            switch self {
            case .contract: return .ksrInfo
            case .operators: return .ksrSuccess
            case .performance: return .ksrWarning
            case .financial: return .purple
            case .intelligence: return .ksrYellow
            }
        }
    }
    
    enum EventImpact: String, Codable {
        case positive = "positive"
        case neutral = "neutral"
        case negative = "negative"
        case critical = "critical"
        
        var color: Color {
            switch self {
            case .positive: return .ksrSuccess
            case .neutral: return .ksrSecondary
            case .negative: return .ksrWarning
            case .critical: return .ksrError
            }
        }
        
        var icon: String {
            switch self {
            case .positive: return "plus.circle.fill"
            case .neutral: return "circle.fill"
            case .negative: return "minus.circle.fill"
            case .critical: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    struct RelatedEntities: Codable {
        let projectId: Int?
        let taskIds: [Int]?
        let employeeIds: [Int]?
        let customerId: Int?
        let billingSettingId: Int?
        
        private enum CodingKeys: String, CodingKey {
            case projectId = "project_id"
            case taskIds = "task_ids"
            case employeeIds = "employee_ids"
            case customerId = "customer_id"
            case billingSettingId = "billing_setting_id"
        }
    }
}

// MARK: - 📈 Business Key Metrics

struct BusinessKeyMetrics: Codable {
    // 💰 Financial KPIs
    let contractValue: Decimal
    let weeklyRevenue: Decimal
    let totalRevenue: Decimal
    let profitMargin: Double
    let paymentCollection: Double
    
    // 👷 Operational KPIs
    let operatorUtilization: Double
    let revenuePerOperatorPerDay: Decimal
    let onTimeDelivery: Double
    let safetyIncidentRate: Double
    
    // 😊 Client KPIs
    let clientSatisfaction: Double
    let clientRetentionRate: Double
    let bonusPayments: Decimal
    
    // 📊 Performance KPIs
    let utilizationTarget: Double
    let revenueTarget: Decimal
    let safetyTarget: Double
    let satisfactionTarget: Double
    
    private enum CodingKeys: String, CodingKey {
        case contractValue = "contract_value"
        case weeklyRevenue = "weekly_revenue"
        case totalRevenue = "total_revenue"
        case profitMargin = "profit_margin"
        case paymentCollection = "payment_collection"
        case operatorUtilization = "operator_utilization"
        case revenuePerOperatorPerDay = "revenue_per_operator_per_day"
        case onTimeDelivery = "on_time_delivery"
        case safetyIncidentRate = "safety_incident_rate"
        case clientSatisfaction = "client_satisfaction"
        case clientRetentionRate = "client_retention_rate"
        case bonusPayments = "bonus_payments"
        case utilizationTarget = "utilization_target"
        case revenueTarget = "revenue_target"
        case safetyTarget = "safety_target"
        case satisfactionTarget = "satisfaction_target"
    }
    
    // Custom initializer for creating instances
    init(
        contractValue: Decimal,
        weeklyRevenue: Decimal,
        totalRevenue: Decimal,
        profitMargin: Double,
        paymentCollection: Double,
        operatorUtilization: Double,
        revenuePerOperatorPerDay: Decimal,
        onTimeDelivery: Double,
        safetyIncidentRate: Double,
        clientSatisfaction: Double,
        clientRetentionRate: Double,
        bonusPayments: Decimal,
        utilizationTarget: Double,
        revenueTarget: Decimal,
        safetyTarget: Double,
        satisfactionTarget: Double
    ) {
        self.contractValue = contractValue
        self.weeklyRevenue = weeklyRevenue
        self.totalRevenue = totalRevenue
        self.profitMargin = profitMargin
        self.paymentCollection = paymentCollection
        self.operatorUtilization = operatorUtilization
        self.revenuePerOperatorPerDay = revenuePerOperatorPerDay
        self.onTimeDelivery = onTimeDelivery
        self.safetyIncidentRate = safetyIncidentRate
        self.clientSatisfaction = clientSatisfaction
        self.clientRetentionRate = clientRetentionRate
        self.bonusPayments = bonusPayments
        self.utilizationTarget = utilizationTarget
        self.revenueTarget = revenueTarget
        self.safetyTarget = safetyTarget
        self.satisfactionTarget = satisfactionTarget
    }
    
    // Robust decoder that handles string-to-decimal conversion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Financial metrics with robust decoding
        contractValue = try Self.decodeDecimal(container, forKey: .contractValue)
        weeklyRevenue = try Self.decodeDecimal(container, forKey: .weeklyRevenue)
        totalRevenue = try Self.decodeDecimal(container, forKey: .totalRevenue)
        revenuePerOperatorPerDay = try Self.decodeDecimal(container, forKey: .revenuePerOperatorPerDay)
        bonusPayments = try Self.decodeDecimal(container, forKey: .bonusPayments)
        revenueTarget = try Self.decodeDecimal(container, forKey: .revenueTarget)
        
        // Standard double decoding
        profitMargin = try container.decode(Double.self, forKey: .profitMargin)
        paymentCollection = try container.decode(Double.self, forKey: .paymentCollection)
        operatorUtilization = try container.decode(Double.self, forKey: .operatorUtilization)
        onTimeDelivery = try container.decode(Double.self, forKey: .onTimeDelivery)
        safetyIncidentRate = try container.decode(Double.self, forKey: .safetyIncidentRate)
        clientSatisfaction = try container.decode(Double.self, forKey: .clientSatisfaction)
        clientRetentionRate = try container.decode(Double.self, forKey: .clientRetentionRate)
        utilizationTarget = try container.decode(Double.self, forKey: .utilizationTarget)
        safetyTarget = try container.decode(Double.self, forKey: .safetyTarget)
        satisfactionTarget = try container.decode(Double.self, forKey: .satisfactionTarget)
    }
    
    // Helper for robust decimal decoding
    private static func decodeDecimal<K: CodingKey>(_ container: KeyedDecodingContainer<K>, forKey key: K) throws -> Decimal {
        // Try string first (API often sends strings)
        if let string = try? container.decode(String.self, forKey: key) {
            if let decimal = Decimal(string: string) {
                return decimal
            } else if string.isEmpty {
                return 0
            }
        }
        
        // Try number types
        if let decimal = try? container.decode(Decimal.self, forKey: key) {
            return decimal
        }
        
        if let double = try? container.decode(Double.self, forKey: key) {
            return Decimal(double)
        }
        
        if let int = try? container.decode(Int.self, forKey: key) {
            return Decimal(int)
        }
        
        // Default to 0 if all fails
        return 0
    }
}

// MARK: - 💡 Business Insights & Recommendations

struct BusinessInsight: Identifiable, Codable {
    let id: String
    let type: InsightType
    let title: String
    let description: String
    let priority: Priority
    let actionRequired: Bool
    let relatedMetrics: [String]
    
    enum InsightType: String, Codable {
        case opportunity = "opportunity"
        case risk = "risk"
        case achievement = "achievement"
        case alert = "alert"
        
        var color: Color {
            switch self {
            case .opportunity: return .ksrSuccess
            case .risk: return .ksrWarning
            case .achievement: return .ksrInfo
            case .alert: return .ksrError
            }
        }
        
        var icon: String {
            switch self {
            case .opportunity: return "lightbulb.fill"
            case .risk: return "exclamationmark.triangle.fill"
            case .achievement: return "trophy.fill"
            case .alert: return "bell.fill"
            }
        }
    }
    
    enum Priority: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
        var color: Color {
            switch self {
            case .low: return .ksrSecondary
            case .medium: return .ksrWarning
            case .high: return .orange
            case .critical: return .ksrError
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case description
        case priority
        case actionRequired = "action_required"
        case relatedMetrics = "related_metrics"
    }
}

struct BusinessRecommendation: Identifiable, Codable {
    let id: String
    let category: RecommendationCategory
    let title: String
    let description: String
    let estimatedImpact: String
    let timeframe: String
    let difficulty: Difficulty
    let actionItems: [ActionItem]
    
    enum RecommendationCategory: String, Codable {
        case financial = "financial"
        case operational = "operational"
        case client = "client"
        case growth = "growth"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var icon: String {
            switch self {
            case .financial: return "dollarsign.circle"
            case .operational: return "gear"
            case .client: return "person.2"
            case .growth: return "chart.line.uptrend.xyaxis"
            }
        }
        
        var color: Color {
            switch self {
            case .financial: return .purple
            case .operational: return .ksrWarning
            case .client: return .ksrInfo
            case .growth: return .ksrSuccess
            }
        }
    }
    
    enum Difficulty: String, Codable {
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var color: Color {
            switch self {
            case .easy: return .ksrSuccess
            case .medium: return .ksrWarning
            case .hard: return .ksrError
            }
        }
    }
    
    struct ActionItem: Identifiable, Codable {
        let id: String
        let description: String
        let responsible: String?
        let deadline: Date?
        let isCompleted: Bool
        
        private enum CodingKeys: String, CodingKey {
            case id
            case description
            case responsible
            case deadline
            case isCompleted = "is_completed"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case category
        case title
        case description
        case estimatedImpact = "estimated_impact"
        case timeframe
        case difficulty
        case actionItems = "action_items"
    }
}

// MARK: - 🎪 Business Timeline ViewModel (✅ STANDARDIZED ERROR HANDLING)

@MainActor
class BusinessTimelineViewModel: ObservableObject {
    @Published var timeline: BusinessTimelineResponse?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var selectedCategory: BusinessTimelineEvent.EventCategory?
    @Published var selectedTimeRange: TimeRange = .all
    @Published var showInsights = false
    
    private var cancellables = Set<AnyCancellable>()
    
    enum TimeRange: String, CaseIterable {
        case week = "7_days"
        case month = "30_days"
        case quarter = "90_days"
        case all = "all"
        
        var displayName: String {
            switch self {
            case .week: return "This Week"
            case .month: return "This Month"
            case .quarter: return "This Quarter"
            case .all: return "All Time"
            }
        }
        
        var icon: String {
            switch self {
            case .week: return "calendar"
            case .month: return "calendar.circle"
            case .quarter: return "calendar.badge.clock"
            case .all: return "infinity"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var filteredEvents: [BusinessTimelineEvent] {
        guard let timeline = timeline else { return [] }
        
        var events = timeline.timeline
        
        // Filter by category
        if let category = selectedCategory {
            events = events.filter { $0.category == category }
        }
        
        // Filter by time range
        if selectedTimeRange != .all {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -timeRangeDays, to: Date()) ?? Date()
            events = events.filter { $0.timestamp >= cutoffDate }
        }
        
        return events.sorted { $0.timestamp > $1.timestamp }
    }
    
    private var timeRangeDays: Int {
        switch selectedTimeRange {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .all: return Int.max
        }
    }
    
    var eventsByCategory: [BusinessTimelineEvent.EventCategory: [BusinessTimelineEvent]] {
        Dictionary(grouping: filteredEvents) { $0.category }
    }
    
    var healthScore: BusinessHealthScore? {
        return timeline?.businessHealth
    }
    
    var keyMetrics: BusinessKeyMetrics? {
        return timeline?.keyMetrics
    }
    
    var insights: [BusinessInsight] {
        return timeline?.insights ?? []
    }
    
    var recommendations: [BusinessRecommendation] {
        return timeline?.recommendations ?? []
    }
    
    var highPriorityInsights: [BusinessInsight] {
        return insights.filter { $0.priority == .high || $0.priority == .critical }
    }
    
    // MARK: - API Methods
    
    func loadBusinessTimeline(for projectId: Int) {
        isLoading = true
        clearError()
        
        #if DEBUG
        print("🔄 [BusinessTimelineViewModel] Loading timeline for project: \(projectId)")
        #endif
        
        // TODO: When backend implements business timeline endpoint, replace this with:
        // BusinessTimelineAPIService.shared.fetchBusinessTimeline(for: projectId)
        loadMockData(projectId: projectId)
    }
    
    func refreshTimeline(for projectId: Int) {
        loadBusinessTimeline(for: projectId)
    }
    
    func selectCategory(_ category: BusinessTimelineEvent.EventCategory?) {
        selectedCategory = category
    }
    
    func selectTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
    }
    
    // MARK: - Error Handling
    
    private func clearError() {
        showError = false
        errorMessage = ""
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.showError = true
            
            #if DEBUG
            print("❌ [BusinessTimelineViewModel] Error: \(error.localizedDescription)")
            #endif
        }
    }
    
    // MARK: - Mock Data (Development Only)
    
    private func loadMockData(projectId: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.timeline = self.createMockTimeline(projectId: projectId)
            self.isLoading = false
            
            #if DEBUG
            print("✅ [BusinessTimelineViewModel] Mock timeline loaded with \(self.timeline?.timeline.count ?? 0) events")
            #endif
        }
    }
    
    private func createMockTimeline(projectId: Int) -> BusinessTimelineResponse {
        let now = Date()
        let calendar = Calendar.current
        
        let events = [
            BusinessTimelineEvent(
                id: "1",
                timestamp: calendar.date(byAdding: .day, value: -30, to: now)!,
                type: .contractAwarded,
                category: .contract,
                title: "Contract Awarded",
                description: "KSR awarded operator services contract worth €87,500",
                impact: .positive,
                metrics: ["contract_value": 87500],
                relatedEntities: BusinessTimelineEvent.RelatedEntities(
                    projectId: projectId,
                    taskIds: nil,
                    employeeIds: nil,
                    customerId: 1,
                    billingSettingId: nil
                )
            ),
            BusinessTimelineEvent(
                id: "2",
                timestamp: calendar.date(byAdding: .day, value: -28, to: now)!,
                type: .operatorsAssigned,
                category: .operators,
                title: "Operators Assigned",
                description: "3 crane operators assigned: Jan Kowalski (Mobile), Peter Nielsen (Tower), Lars Hansen (Team Lead)",
                impact: .positive,
                metrics: ["operators_count": 3],
                relatedEntities: BusinessTimelineEvent.RelatedEntities(
                    projectId: projectId,
                    taskIds: [1, 2],
                    employeeIds: [101, 102, 103],
                    customerId: nil,
                    billingSettingId: nil
                )
            ),
            BusinessTimelineEvent(
                id: "3",
                timestamp: calendar.date(byAdding: .day, value: -7, to: now)!,
                type: .weeklyMilestone,
                category: .performance,
                title: "Week 3 Performance Milestone",
                description: "172h worked vs 168h planned (+4h overtime). 98% uptime achieved.",
                impact: .positive,
                metrics: [
                    "hours_worked": 172,
                    "hours_planned": 168,
                    "uptime": 98.0
                ],
                relatedEntities: BusinessTimelineEvent.RelatedEntities(
                    projectId: projectId,
                    taskIds: nil,
                    employeeIds: [101, 102, 103],
                    customerId: nil,
                    billingSettingId: nil
                )
            ),
            BusinessTimelineEvent(
                id: "4",
                timestamp: calendar.date(byAdding: .day, value: -3, to: now)!,
                type: .clientSatisfactionAchievement,
                category: .intelligence,
                title: "Client Satisfaction Achievement",
                description: "Client bonus payment +€2,000 received. Satisfaction score: 9.8/10",
                impact: .positive,
                metrics: [
                    "bonus_amount": 2000,
                    "satisfaction_score": 9.8
                ],
                relatedEntities: BusinessTimelineEvent.RelatedEntities(
                    projectId: projectId,
                    taskIds: nil,
                    employeeIds: nil,
                    customerId: 1,
                    billingSettingId: nil
                )
            )
        ]
        
        return BusinessTimelineResponse(
            projectId: projectId,
            businessHealth: BusinessHealthScore(
                overall: 94.0,
                financial: 96.0,
                operational: 92.0,
                client: 94.0,
                status: .excellent,
                trend: .improving
            ),
            timeline: events,
            keyMetrics: BusinessKeyMetrics(
                contractValue: 87500,
                weeklyRevenue: 8750,
                totalRevenue: 35000,
                profitMargin: 26.6,
                paymentCollection: 96.0,
                operatorUtilization: 94.0,
                revenuePerOperatorPerDay: 425,
                onTimeDelivery: 98.0,
                safetyIncidentRate: 0.02,
                clientSatisfaction: 9.8,
                clientRetentionRate: 92.0,
                bonusPayments: 2000,
                utilizationTarget: 90.0,
                revenueTarget: 400,
                safetyTarget: 0.05,
                satisfactionTarget: 8.5
            ),
            insights: [
                BusinessInsight(
                    id: "insight1",
                    type: .achievement,
                    title: "Exceeding All Targets",
                    description: "Project is performing above targets in all key areas: utilization (94% vs 90%), safety (0.02 vs 0.05), and client satisfaction (9.8 vs 8.5).",
                    priority: .high,
                    actionRequired: false,
                    relatedMetrics: ["utilization", "safety", "satisfaction"]
                ),
                BusinessInsight(
                    id: "insight2",
                    type: .opportunity,
                    title: "Revenue Optimization Opportunity",
                    description: "Current operator utilization at 94% suggests potential for additional project capacity or premium rate negotiation.",
                    priority: .medium,
                    actionRequired: true,
                    relatedMetrics: ["utilization", "revenue"]
                )
            ],
            recommendations: [
                BusinessRecommendation(
                    id: "rec1",
                    category: .growth,
                    title: "Propose Contract Extension",
                    description: "Given exceptional performance metrics, propose 6-month contract extension with 5% rate increase.",
                    estimatedImpact: "+€15,000 additional revenue",
                    timeframe: "2-3 weeks",
                    difficulty: .medium,
                    actionItems: [
                        BusinessRecommendation.ActionItem(
                            id: "action1",
                            description: "Prepare performance summary report",
                            responsible: "Chef",
                            deadline: calendar.date(byAdding: .day, value: 7, to: now),
                            isCompleted: false
                        ),
                        BusinessRecommendation.ActionItem(
                            id: "action2",
                            description: "Schedule client meeting",
                            responsible: "Sales",
                            deadline: calendar.date(byAdding: .day, value: 14, to: now),
                            isCompleted: false
                        )
                    ]
                )
            ]
        )
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - 🎨 Helper Extensions

extension BusinessKeyMetrics {
    var formattedContractValue: String {
        return "€\(contractValue.formatted(.number.precision(.fractionLength(0))))"
    }
    
    var formattedWeeklyRevenue: String {
        return "€\(weeklyRevenue.formatted(.number.precision(.fractionLength(0))))"
    }
    
    var formattedProfitMargin: String {
        return "\(profitMargin.formatted(.number.precision(.fractionLength(1))))%"
    }
    
    var utilizationStatus: (color: Color, icon: String) {
        if operatorUtilization >= utilizationTarget {
            return (.ksrSuccess, "checkmark.circle.fill")
        } else if operatorUtilization >= utilizationTarget * 0.8 {
            return (.ksrWarning, "exclamationmark.triangle.fill")
        } else {
            return (.ksrError, "xmark.circle.fill")
        }
    }
}
