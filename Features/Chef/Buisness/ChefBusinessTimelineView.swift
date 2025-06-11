//
//  ChefBusinessTimelineView.swift
//  KSR Cranes App
//
//  Business Intelligence Timeline for Operator Service Lifecycle
//  Replaces technical project timeline with business-focused timeline
//

import SwiftUI
import Combine

struct ChefBusinessTimelineView: View {
    let projectId: Int
    
    @StateObject private var viewModel = BusinessTimelineViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingInsights = false
    @State private var selectedEvent: BusinessTimelineEvent?
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.timeline == nil {
                loadingView
            } else if let timeline = viewModel.timeline {
                VStack(spacing: 0) {
                    // Business Health Header
                    businessHealthHeader(timeline.businessHealth)
                    
                    // Key Metrics Dashboard
                    keyMetricsSection(timeline.keyMetrics)
                    
                    // Filter Controls
                    filterControlsSection
                    
                    // Timeline Events
                    timelineEventsSection
                }
            } else if viewModel.showError {
                errorView
            }
        }
        .background(backgroundGradient)
        .navigationTitle("Business Timeline")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingInsights = true
                } label: {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.ksrYellow)
                }
            }
        }
        .sheet(isPresented: $showingInsights) {
            if let timeline = viewModel.timeline {
                BusinessInsightsView(
                    insights: timeline.insights,
                    recommendations: timeline.recommendations,
                    keyMetrics: timeline.keyMetrics
                )
            }
        }
        .sheet(item: $selectedEvent) { event in
            BusinessEventDetailView(event: event)
        }
        .onAppear {
            viewModel.loadBusinessTimeline(for: projectId)
        }
        .refreshable {
            await refreshTimeline()
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
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
    
    // MARK: - Business Health Header
    
    private func businessHealthHeader(_ health: BusinessHealthScore) -> some View {
        VStack(spacing: 16) {
            // Overall Health Score
            HStack(spacing: 20) {
                // Health Score Circle
                ZStack {
                    Circle()
                        .stroke(Color.ksrLightGray.opacity(0.3), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: health.overall / 100)
                        .stroke(health.status.color, lineWidth: 8)
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: health.overall)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(health.overall))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Health")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Status Badge
                    HStack(spacing: 6) {
                        Image(systemName: health.status.icon)
                            .foregroundColor(health.status.color)
                        
                        Text(health.status.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(health.status.color)
                    }
                    
                    // Trend Indicator
                    HStack(spacing: 6) {
                        Image(systemName: health.trend.icon)
                            .font(.caption)
                            .foregroundColor(health.trend.color)
                        
                        Text(health.trend.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Quick Stats
                    VStack(alignment: .leading, spacing: 4) {
                        healthStatRow("Financial", value: health.financial, color: .purple)
                        healthStatRow("Operational", value: health.operational, color: .ksrWarning)
                        healthStatRow("Client", value: health.client, color: .ksrInfo)
                    }
                }
                
                Spacer()
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
    
    private func healthStatRow(_ title: String, value: Double, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            
            Text("\(Int(value))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
    
    // MARK: - Key Metrics Section
    
    private func keyMetricsSection(_ metrics: BusinessKeyMetrics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Key Performance Indicators")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    showingInsights = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Insights")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(.ksrYellow)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                BusinessMetricCard(
                    title: "Operator Utilization",
                    value: "\(operatorUtilizationValue(metrics.operatorUtilization))%",
                    target: "\(operatorUtilizationTarget(metrics.utilizationTarget))%",
                    icon: "person.3.fill",
                    color: metrics.operatorUtilization >= metrics.utilizationTarget ? .ksrSuccess : .ksrWarning,
                    trend: metrics.operatorUtilization >= metrics.utilizationTarget ? .improving : .stable
                )
                
                BusinessMetricCard(
                    title: "Weekly Revenue",
                    value: weeklyRevenueValue(metrics.weeklyRevenue),
                    target: weeklyRevenueTarget(metrics.revenueTarget),
                    icon: "banknote.fill",
                    color: metrics.weeklyRevenue >= metrics.revenueTarget ? .ksrSuccess : .ksrWarning,
                    trend: metrics.weeklyRevenue >= metrics.revenueTarget ? .improving : .stable
                )
                
                BusinessMetricCard(
                    title: "Profit Margin",
                    value: profitMarginValue(metrics.profitMargin),
                    target: "20%+",
                    icon: "chart.pie.fill",
                    color: metrics.profitMargin >= 20 ? .ksrSuccess : .ksrWarning,
                    trend: metrics.profitMargin >= 25 ? .improving : .stable
                )
                
                BusinessMetricCard(
                    title: "Safety Score",
                    value: safetyScoreValue(metrics.safetyIncidentRate),
                    target: "95%+",
                    icon: "shield.checkered",
                    color: metrics.safetyIncidentRate <= metrics.safetyTarget ? .ksrSuccess : .ksrError,
                    trend: metrics.safetyIncidentRate <= metrics.safetyTarget ? .improving : .declining
                )
                
                BusinessMetricCard(
                    title: "Client Satisfaction",
                    value: clientSatisfactionValue(metrics.clientSatisfaction),
                    target: clientSatisfactionTarget(metrics.satisfactionTarget),
                    icon: "hand.thumbsup.fill",
                    color: metrics.clientSatisfaction >= metrics.satisfactionTarget ? .ksrSuccess : .ksrWarning,
                    trend: metrics.clientSatisfaction >= 9.0 ? .improving : .stable
                )
                
                BusinessMetricCard(
                    title: "Payment Collection",
                    value: paymentCollectionValue(metrics.paymentCollection),
                    target: "95%+",
                    icon: "creditcard.fill",
                    color: metrics.paymentCollection >= 95 ? .ksrSuccess : .ksrWarning,
                    trend: metrics.paymentCollection >= 95 ? .improving : .stable
                )
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
    
    // MARK: - Helper Methods for Metrics
    
    private func operatorUtilizationValue(_ value: Any) -> String {
        if let decimal = value as? Decimal {
            return "\(NSDecimalNumber(decimal: decimal).intValue)"
        } else if let double = value as? Double {
            return "\(Int(double))"
        } else if let int = value as? Int {
            return "\(int)"
        }
        return "0"
    }
    
    private func operatorUtilizationTarget(_ value: Any) -> String {
        if let decimal = value as? Decimal {
            return "\(NSDecimalNumber(decimal: decimal).intValue)"
        } else if let double = value as? Double {
            return "\(Int(double))"
        } else if let int = value as? Int {
            return "\(int)"
        }
        return "0"
    }
    
    private func weeklyRevenueValue(_ value: Any) -> String {
        if let decimal = value as? Decimal {
            return "\(NSDecimalNumber(decimal: decimal).intValue) kr"
        } else if let double = value as? Double {
            return "\(Int(double)) kr"
        } else if let int = value as? Int {
            return "\(int) kr"
        }
        return "0 kr"
    }
    
    private func weeklyRevenueTarget(_ value: Any) -> String {
        if let decimal = value as? Decimal {
            return "\(NSDecimalNumber(decimal: decimal).intValue) kr"
        } else if let double = value as? Double {
            return "\(Int(double)) kr"
        } else if let int = value as? Int {
            return "\(int) kr"
        }
        return "0 kr"
    }
    
    private func profitMarginValue(_ value: Any) -> String {
        if let decimal = value as? Decimal {
            return "\(NSDecimalNumber(decimal: decimal).doubleValue.formatted(.number.precision(.fractionLength(1))))%"
        } else if let double = value as? Double {
            return "\(double.formatted(.number.precision(.fractionLength(1))))%"
        } else if let int = value as? Int {
            return "\(Double(int).formatted(.number.precision(.fractionLength(1))))%"
        }
        return "0.0%"
    }
    
    private func safetyScoreValue(_ incidentRate: Any) -> String {
        var rate: Double = 0.0
        
        if let decimal = incidentRate as? Decimal {
            rate = NSDecimalNumber(decimal: decimal).doubleValue
        } else if let double = incidentRate as? Double {
            rate = double
        } else if let int = incidentRate as? Int {
            rate = Double(int)
        }
        
        let safetyPercentage = (1.0 - min(rate, 0.1)) * 100
        return "\(safetyPercentage.formatted(.number.precision(.fractionLength(0))))%"
    }
    
    private func clientSatisfactionValue(_ value: Any) -> String {
        if let decimal = value as? Decimal {
            return "\(NSDecimalNumber(decimal: decimal).doubleValue.formatted(.number.precision(.fractionLength(1))))/10"
        } else if let double = value as? Double {
            return "\(double.formatted(.number.precision(.fractionLength(1))))/10"
        } else if let int = value as? Int {
            return "\(Double(int).formatted(.number.precision(.fractionLength(1))))/10"
        }
        return "0.0/10"
    }
    
    private func clientSatisfactionTarget(_ value: Any) -> String {
        if let decimal = value as? Decimal {
            return "\(NSDecimalNumber(decimal: decimal).doubleValue.formatted(.number.precision(.fractionLength(1))))+"
        } else if let double = value as? Double {
            return "\(double.formatted(.number.precision(.fractionLength(1))))+"
        } else if let int = value as? Int {
            return "\(Double(int).formatted(.number.precision(.fractionLength(1))))+"
        }
        return "0.0+"
    }
    
    private func paymentCollectionValue(_ value: Any) -> String {
        if let decimal = value as? Decimal {
            return "\(NSDecimalNumber(decimal: decimal).intValue)%"
        } else if let double = value as? Double {
            return "\(Int(double))%"
        } else if let int = value as? Int {
            return "\(int)%"
        }
        return "0%"
    }
    
    // MARK: - Filter Controls
    
    private var filterControlsSection: some View {
        VStack(spacing: 12) {
            // Time Range Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BusinessTimelineViewModel.TimeRange.allCases, id: \.self) { range in
                        Button {
                            viewModel.selectTimeRange(range)
                        } label: {
                            timeRangeButton(for: range)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        viewModel.selectCategory(nil)
                    } label: {
                        allCategoriesButton
                    }
                    
                    ForEach(BusinessTimelineEvent.EventCategory.allCases, id: \.self) { category in
                        Button {
                            viewModel.selectCategory(category)
                        } label: {
                            categoryButton(for: category)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Events Count
            if !viewModel.filteredEvents.isEmpty {
                eventsCountSection
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timeRangeButton(for range: BusinessTimelineViewModel.TimeRange) -> some View {
        HStack(spacing: 6) {
            Image(systemName: range.icon)
                .font(.caption)
            
            Text(range.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(viewModel.selectedTimeRange == range ? .black : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.selectedTimeRange == range ? Color.ksrYellow : Color.ksrLightGray.opacity(0.3))
        )
    }
    
    private var allCategoriesButton: some View {
        Text("All Categories")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(viewModel.selectedCategory == nil ? .black : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewModel.selectedCategory == nil ? Color.ksrYellow : Color.ksrLightGray.opacity(0.3))
            )
    }
    
    private func categoryButton(for category: BusinessTimelineEvent.EventCategory) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(category.color)
                .frame(width: 8, height: 8)
            
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(viewModel.selectedCategory == category ? .black : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.selectedCategory == category ? category.color.opacity(0.3) : Color.ksrLightGray.opacity(0.3))
        )
    }
    
    private var eventsCountSection: some View {
        HStack {
            Text("\(viewModel.filteredEvents.count) events")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if viewModel.highPriorityInsights.count > 0 {
                highPriorityIndicator
            }
        }
        .padding(.horizontal)
    }
    
    private var highPriorityIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.ksrWarning)
            
            Text("\(viewModel.highPriorityInsights.count) high priority")
                .font(.caption)
                .foregroundColor(.ksrWarning)
        }
    }
    
    // MARK: - Timeline Events
    
    private var timelineEventsSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredEvents) { event in
                    BusinessTimelineEventCard(event: event) {
                        selectedEvent = event
                    }
                }
                
                if viewModel.filteredEvents.isEmpty {
                    emptyStateView
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Supporting Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                .scaleEffect(1.2)
            
            Text("Loading business timeline...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red.opacity(0.6))
            
            Text("Failed to Load Timeline")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(viewModel.errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                viewModel.loadBusinessTimeline(for: projectId)
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.ksrYellow)
                    .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "timeline.selection")
                .font(.system(size: 50))
                .foregroundColor(.ksrYellow.opacity(0.6))
            
            Text("No Events Found")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("No timeline events match your selected filters")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.selectCategory(nil)
                viewModel.selectTimeRange(.all)
            } label: {
                Text("Clear Filters")
                    .font(.subheadline)
                    .foregroundColor(.ksrYellow)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Helper Methods
    
    private func refreshTimeline() async {
        await withCheckedContinuation { continuation in
            viewModel.refreshTimeline(for: projectId)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                continuation.resume()
            }
        }
    }
}

// MARK: - Business Metric Card

struct BusinessMetricCard: View {
    let title: String
    let value: String
    let target: String
    let icon: String
    let color: Color
    let trend: BusinessHealthScore.HealthTrend
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
            
            // Value
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Target
            HStack {
                Text("Target:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(target)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.systemGray6))
        )
    }
}

// MARK: - Business Timeline Event Card

struct BusinessTimelineEventCard: View {
    let event: BusinessTimelineEvent
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Event Icon and Type Indicator
                eventIconSection
                
                // Event Content
                eventContentSection
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.ksrSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var eventIconSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(event.type.color)
                    .frame(width: 40, height: 40)
                
                Image(systemName: event.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Rectangle()
                .fill(event.type.color.opacity(0.3))
                .frame(width: 2, height: 20)
        }
    }
    
    private var eventContentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                eventTitleSection
                
                Spacer()
                
                eventTimestampSection
            }
            
            // Description
            Text(event.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
            
            // Metrics (if any)
            if let metrics = event.metrics, !metrics.isEmpty {
                eventMetricsSection(metrics)
            }
        }
    }
    
    private var eventTitleSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Text(event.category.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(event.category.color)
        }
    }
    
    private var eventTimestampSection: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(event.relativeTimestamp)
                .font(.caption)
                .foregroundColor(.secondary)
            
            eventImpactBadge
        }
    }
    
    private var eventImpactBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: event.impact.icon)
                .font(.caption2)
            
            Text(event.impact.rawValue.capitalized)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(event.impact.color)
    }
    
    private func eventMetricsSection(_ metrics: [String: Any]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(metrics.keys.prefix(3)), id: \.self) { key in
                    if let value = metrics[key] {
                        MetricChip(key: key, value: AnyCodable(value))
                    }
                }
            }
        }
    }
}

// MARK: - Metric Chip

struct MetricChip: View {
    let key: String
    let value: AnyCodable
    
    private var displayText: String {
        switch value.value {
        case let number as NSNumber:
            return "\(key): \(number)"
        case let string as String:
            return "\(key): \(string)"
        default:
            return "\(key): \(value.value)"
        }
    }
    
    var body: some View {
        Text(displayText)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.ksrInfo.opacity(0.1))
            .foregroundColor(.ksrInfo)
            .cornerRadius(6)
    }
}

// MARK: - Event Detail View

struct BusinessEventDetailView: View {
    let event: BusinessTimelineEvent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event Header
                    eventHeaderSection
                    
                    Divider()
                    
                    // Description
                    eventDescriptionSection
                    
                    // Metrics
                    if let metrics = event.metrics, !metrics.isEmpty {
                        eventMetricsDetailSection(metrics)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Event Details")
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
    
    private var eventHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(event.type.color)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: event.type.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                eventDetailTimestamp
            }
            
            Text(event.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(event.category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(event.category.color)
        }
    }
    
    private var eventDetailTimestamp: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(event.formattedTimestamp)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Image(systemName: event.impact.icon)
                    .font(.caption)
                
                Text(event.impact.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(event.impact.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(event.impact.color.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var eventDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(event.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private func eventMetricsDetailSection(_ metrics: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(Array(metrics.keys), id: \.self) { key in
                    if let value = metrics[key] {
                        metricDetailCard(key: key, value: AnyCodable(value))
                    }
                }
            }
        }
    }
    
    private func metricDetailCard(key: String, value: AnyCodable) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(value.value)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.ksrLightGray.opacity(0.3))
        .cornerRadius(8)
    }
}

// MARK: - Extensions

extension BusinessTimelineEvent {
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
