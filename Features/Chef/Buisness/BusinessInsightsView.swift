//
//  BusinessInsightsView.swift
//  KSR Cranes App
//
//  AI-Like Business Intelligence Modal
//  Shows insights, recommendations, and actionable intelligence
//

import SwiftUI

struct BusinessInsightsView: View {
    let insights: [BusinessInsight]
    let recommendations: [BusinessRecommendation]
    let keyMetrics: BusinessKeyMetrics
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: InsightTab = .overview
    @State private var selectedRecommendation: BusinessRecommendation?
    
    enum InsightTab: String, CaseIterable {
        case overview = "Overview"
        case insights = "Insights"
        case recommendations = "Actions"
        case metrics = "Metrics"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .insights: return "lightbulb.fill"
            case .recommendations: return "checkmark.circle.fill"
            case .metrics: return "number.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .overview: return .ksrInfo
            case .insights: return .ksrYellow
            case .recommendations: return .ksrSuccess
            case .metrics: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with AI Branding
                aiHeader
                
                // Tab Selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    overviewTab.tag(InsightTab.overview)
                    insightsTab.tag(InsightTab.insights)
                    recommendationsTab.tag(InsightTab.recommendations)
                    metricsTab.tag(InsightTab.metrics)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(backgroundGradient)
            .navigationTitle("Business Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.ksrYellow)
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedRecommendation) { recommendation in
                RecommendationDetailView(recommendation: recommendation)
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color(.systemBackground),
                colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6).opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - AI Header
    
    private var aiHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // AI Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.ksrYellow, .orange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("KSR Business Intelligence")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("AI-powered insights for your operator services")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Quick Stats
            HStack(spacing: 16) {
                aiStatItem("Insights", value: "\(insights.count)", icon: "lightbulb.fill", color: .ksrYellow)
                aiStatItem("Actions", value: "\(recommendations.count)", icon: "arrow.forward.circle.fill", color: .ksrSuccess)
                aiStatItem("Priority", value: "\(highPriorityCount)", icon: "exclamationmark.triangle.fill", color: .ksrWarning)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    private func aiStatItem(_ title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InsightTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTab == tab ? tab.color : Color.ksrLightGray.opacity(0.3))
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Executive Summary
                executiveSummary
                
                // Key Highlights
                keyHighlights
                
                // Critical Actions
                if !criticalInsights.isEmpty || !urgentRecommendations.isEmpty {
                    criticalActionsSection
                }
            }
            .padding()
        }
    }
    
    private var executiveSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.ksrInfo)
                
                Text("Executive Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                summaryItem(
                    "Project Performance",
                    value: projectPerformanceStatus,
                    color: projectPerformanceColor
                )
                
                summaryItem(
                    "Financial Health",
                    value: "€\(Int(NSDecimalNumber(decimal: keyMetrics.weeklyRevenue).intValue)) weekly revenue • \(keyMetrics.profitMargin.formatted(.number.precision(.fractionLength(1))))% margin",
                    color: keyMetrics.profitMargin >= 20 ? .ksrSuccess : .ksrWarning
                )
                
                summaryItem(
                    "Operational Status",
                    value: "\(Int(keyMetrics.operatorUtilization))% utilization • \(((1.0 - min(keyMetrics.safetyIncidentRate, 0.1)) * 100).formatted(.number.precision(.fractionLength(0))))% safety score",
                    color: keyMetrics.operatorUtilization >= 90 ? .ksrSuccess : .ksrWarning
                )
                
                summaryItem(
                    "Client Relationship",
                    value: "\(keyMetrics.clientSatisfaction.formatted(.number.precision(.fractionLength(1))))/10 satisfaction • \(Int(keyMetrics.paymentCollection))% collection rate",
                    color: keyMetrics.clientSatisfaction >= 9.0 ? .ksrSuccess : .ksrWarning
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func summaryItem(_ title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
                .foregroundColor(color)
        }
    }
    
    private var keyHighlights: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.ksrYellow)
                
                Text("Key Highlights")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                highlightCard(
                    "Above Target",
                    value: "\(aboveTargetCount)",
                    subtitle: "metrics exceeding goals",
                    icon: "arrow.up.circle.fill",
                    color: .ksrSuccess
                )
                
                highlightCard(
                    "Opportunities",
                    value: "\(opportunityInsights.count)",
                    subtitle: "growth opportunities",
                    icon: "lightbulb.fill",
                    color: .ksrYellow
                )
                
                highlightCard(
                    "Action Items",
                    value: "\(totalActionItems)",
                    subtitle: "recommended actions",
                    icon: "checkmark.circle.fill",
                    color: .ksrInfo
                )
                
                highlightCard(
                    "Risk Areas",
                    value: "\(riskInsights.count)",
                    subtitle: "areas requiring attention",
                    icon: "exclamationmark.triangle.fill",
                    color: .ksrWarning
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func highlightCard(_ title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
    
    private var criticalActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.ksrWarning)
                
                Text("Critical Actions Required")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                ForEach(criticalInsights.prefix(2)) { insight in
                    CriticalInsightCard(insight: insight)
                }
                
                ForEach(urgentRecommendations.prefix(2)) { recommendation in
                    CriticalRecommendationCard(recommendation: recommendation) {
                        selectedRecommendation = recommendation
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ksrWarning.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.ksrWarning.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Insights Tab
    
    private var insightsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
                
                if insights.isEmpty {
                    BusinessEmptyStateView(
                        icon: "lightbulb",
                        title: "No Insights Available",
                        description: "Insights will appear as your project progresses"
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Recommendations Tab
    
    private var recommendationsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(recommendations) { recommendation in
                    RecommendationCard(recommendation: recommendation) {
                        selectedRecommendation = recommendation
                    }
                }
                
                if recommendations.isEmpty {
                    BusinessEmptyStateView(
                        icon: "checkmark.circle",
                        title: "No Recommendations",
                        description: "You're doing great! Check back later for optimization suggestions"
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Metrics Tab
    
    private var metricsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Financial Metrics
                MetricsSection(
                    title: "Financial Performance",
                    icon: "dollarsign.circle.fill",
                    color: .purple
                ) {
                    MetricRow(title: "Contract Value", value: keyMetrics.formattedContractValue)
                    MetricRow(title: "Weekly Revenue", value: "€\(NSDecimalNumber(decimal: keyMetrics.weeklyRevenue).intValue)")
                    MetricRow(title: "Total Revenue", value: "€\(NSDecimalNumber(decimal: keyMetrics.totalRevenue).intValue)")
                    MetricRow(title: "Profit Margin", value: keyMetrics.formattedProfitMargin)
                    MetricRow(title: "Payment Collection", value: "\(Int(keyMetrics.paymentCollection))%")
                    MetricRow(title: "Bonus Payments", value: "€\(NSDecimalNumber(decimal: keyMetrics.bonusPayments).intValue)")
                }
                
                // Operational Metrics
                MetricsSection(
                    title: "Operational Excellence",
                    icon: "gear.circle.fill",
                    color: .ksrWarning
                ) {
                    MetricRow(title: "Operator Utilization", value: "\(Int(keyMetrics.operatorUtilization))%")
                    MetricRow(title: "Revenue per Operator/Day", value: "€\(NSDecimalNumber(decimal: keyMetrics.revenuePerOperatorPerDay).intValue)")
                    MetricRow(title: "On-Time Delivery", value: "\(Int(keyMetrics.onTimeDelivery))%")
                    MetricRow(title: "Safety Incident Rate", value: "\(keyMetrics.safetyIncidentRate.formatted(.number.precision(.fractionLength(3))))")
                }
                
                // Client Metrics
                MetricsSection(
                    title: "Client Success",
                    icon: "person.2.circle.fill",
                    color: .ksrInfo
                ) {
                    MetricRow(title: "Client Satisfaction", value: "\(keyMetrics.clientSatisfaction.formatted(.number.precision(.fractionLength(1))))/10")
                    MetricRow(title: "Client Retention Rate", value: "\(Int(keyMetrics.clientRetentionRate))%")
                }
                
                // Targets
                MetricsSection(
                    title: "Performance Targets",
                    icon: "target",
                    color: .ksrSuccess
                ) {
                    MetricRow(title: "Utilization Target", value: "\(Int(keyMetrics.utilizationTarget))%")
                    MetricRow(title: "Revenue Target", value: "€\(NSDecimalNumber(decimal: keyMetrics.revenueTarget).intValue)")
                    MetricRow(title: "Safety Target", value: "<\(keyMetrics.safetyTarget.formatted(.number.precision(.fractionLength(2))))")
                    MetricRow(title: "Satisfaction Target", value: "\(keyMetrics.satisfactionTarget.formatted(.number.precision(.fractionLength(1))))+")
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    
    private var highPriorityCount: Int {
        insights.filter { $0.priority == .high || $0.priority == .critical }.count
    }
    
    private var criticalInsights: [BusinessInsight] {
        insights.filter { $0.priority == .critical }
    }
    
    private var urgentRecommendations: [BusinessRecommendation] {
        recommendations.filter {
            $0.difficulty == .easy && $0.actionItems.contains { !$0.isCompleted }
        }
    }
    
    private var opportunityInsights: [BusinessInsight] {
        insights.filter { $0.type == .opportunity }
    }
    
    private var riskInsights: [BusinessInsight] {
        insights.filter { $0.type == .risk }
    }
    
    private var aboveTargetCount: Int {
        var count = 0
        if keyMetrics.operatorUtilization >= keyMetrics.utilizationTarget { count += 1 }
        if keyMetrics.weeklyRevenue >= keyMetrics.revenueTarget { count += 1 }
        if keyMetrics.safetyIncidentRate <= keyMetrics.safetyTarget { count += 1 }
        if keyMetrics.clientSatisfaction >= keyMetrics.satisfactionTarget { count += 1 }
        return count
    }
    
    private var totalActionItems: Int {
        recommendations.reduce(0) { $0 + $1.actionItems.count }
    }
    
    private var projectPerformanceStatus: String {
        if aboveTargetCount >= 3 {
            return "Excellent - Exceeding expectations"
        } else if aboveTargetCount >= 2 {
            return "Good - Meeting most targets"
        } else if aboveTargetCount >= 1 {
            return "Fair - Some areas need attention"
        } else {
            return "Poor - Requires immediate action"
        }
    }
    
    private var projectPerformanceColor: Color {
        if aboveTargetCount >= 3 { return .ksrSuccess }
        else if aboveTargetCount >= 2 { return .ksrInfo }
        else if aboveTargetCount >= 1 { return .ksrWarning }
        else { return .ksrError }
    }
}

// MARK: - Supporting Views

struct InsightCard: View {
    let insight: BusinessInsight
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.type.icon)
                    .font(.title3)
                    .foregroundColor(insight.type.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(insight.type.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(insight.type.color)
                }
                
                Spacer()
                
                PriorityBadge(priority: insight.priority)
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            if insight.actionRequired {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.ksrWarning)
                    
                    Text("Action Required")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.ksrWarning)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct RecommendationCard: View {
    let recommendation: BusinessRecommendation
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: recommendation.category.icon)
                        .font(.title3)
                        .foregroundColor(recommendation.category.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommendation.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(recommendation.category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(recommendation.category.color)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.ksrSecondary)
                }
                
                Text(recommendation.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    HStack(spacing: 4) {
                        Text("Impact:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(recommendation.estimatedImpact)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.ksrSuccess)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Timeframe:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(recommendation.timeframe)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.ksrInfo)
                    }
                }
                
                HStack {
                    DifficultyBadge(difficulty: recommendation.difficulty)
                    
                    Spacer()
                    
                    Text("\(recommendation.actionItems.count) action items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CriticalInsightCard: View {
    let insight: BusinessInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.type.icon)
                .font(.title3)
                .foregroundColor(insight.type.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            PriorityBadge(priority: insight.priority)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(insight.type.color.opacity(0.1))
        )
    }
}

struct CriticalRecommendationCard: View {
    let recommendation: BusinessRecommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: recommendation.category.icon)
                    .font(.title3)
                    .foregroundColor(recommendation.category.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(recommendation.actionItems.count) actions • \(recommendation.timeframe)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.ksrSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(recommendation.category.color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PriorityBadge: View {
    let priority: BusinessInsight.Priority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(priority.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priority.color.opacity(0.15))
            .cornerRadius(6)
    }
}

struct DifficultyBadge: View {
    let difficulty: BusinessRecommendation.Difficulty
    
    var body: some View {
        Text(difficulty.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(difficulty.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(difficulty.color.opacity(0.15))
            .cornerRadius(6)
    }
}

struct MetricsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                content
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Business-specific Empty State View (renamed to avoid conflict)
struct BusinessEmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.ksrYellow.opacity(0.6))
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Recommendation Detail View

struct RecommendationDetailView: View {
    let recommendation: BusinessRecommendation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: recommendation.category.icon)
                                .font(.title)
                                .foregroundColor(recommendation.category.color)
                            
                            Spacer()
                            
                            DifficultyBadge(difficulty: recommendation.difficulty)
                        }
                        
                        Text(recommendation.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(recommendation.category.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(recommendation.category.color)
                    }
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(recommendation.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Impact & Timeframe
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Expected Impact")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(recommendation.estimatedImpact)
                                .font(.body)
                                .foregroundColor(.ksrSuccess)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("Timeframe")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(recommendation.timeframe)
                                .font(.body)
                                .foregroundColor(.ksrInfo)
                        }
                    }
                    
                    // Action Items
                    if !recommendation.actionItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Action Items")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(recommendation.actionItems) { actionItem in
                                ActionItemRow(actionItem: actionItem)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ActionItemRow: View {
    let actionItem: BusinessRecommendation.ActionItem
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: actionItem.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(actionItem.isCompleted ? .ksrSuccess : .ksrSecondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(actionItem.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .strikethrough(actionItem.isCompleted)
                
                HStack {
                    if let responsible = actionItem.responsible {
                        Text(responsible)
                            .font(.caption)
                            .foregroundColor(.ksrInfo)
                    }
                    
                    if let deadline = actionItem.deadline {
                        Text("• Due \(deadline, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.systemGray6))
        )
    }
}
