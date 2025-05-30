//
//  WorkerDashboardComponents.swift
//  KSR Cranes App
//
//  Enhanced Worker Dashboard Components with Manager Dashboard styling
//

import SwiftUI

// MARK: - Enhanced Dashboard Styles
struct WorkerDashboardStyles {
    // Enhanced gradients with existing brand colors
    static let gradientSuccess = LinearGradient(
        colors: [Color.ksrSuccess, Color.ksrSuccess.darker(by: 0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientInfo = LinearGradient(
        colors: [Color.ksrInfo, Color.ksrInfo.darker(by: 0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientWarning = LinearGradient(
        colors: [Color.ksrWarning, Color.ksrWarning.darker(by: 0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientPrimary = LinearGradient(
        colors: [Color.ksrPrimary, Color.ksrYellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientError = LinearGradient(
        colors: [Color.ksrError, Color.ksrError.darker(by: 0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientTeal = LinearGradient(
        colors: [Color.ksrSuccessAlt, Color.ksrSuccessAlt.darker(by: 0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Enhanced card background helper
    static func cardBackground(colorScheme: ColorScheme) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                radius: 8,
                x: 0,
                y: 4
            )
    }
    
    static func cardStroke(_ color: Color = Color.gray, opacity: Double = 0.2) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(color.opacity(opacity), lineWidth: 1)
    }
    
    // Enhanced shadow styles
    static func primaryShadow(colorScheme: ColorScheme) -> some View {
        EmptyView()
            .shadow(
                color: Color.ksrPrimary.opacity(colorScheme == .dark ? 0.3 : 0.2),
                radius: 8,
                x: 0,
                y: 4
            )
    }
    
    static func successShadow(colorScheme: ColorScheme) -> some View {
        EmptyView()
            .shadow(
                color: Color.ksrSuccess.opacity(colorScheme == .dark ? 0.3 : 0.2),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Enhanced Animated Progress Ring
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    let size: CGFloat
    let showPercentage: Bool
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        lineWidth: CGFloat = 6,
        color: Color = Color.ksrPrimary,
        size: CGFloat = 60,
        showPercentage: Bool = true
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.color = color
        self.size = size
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(animatedProgress, 1.0)))
                .stroke(
                    LinearGradient(
                        colors: [color, color.darker(by: 0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: animatedProgress)
            
            // Percentage text
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.system(size: size * 0.2, weight: .bold))
                    .foregroundColor(color)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Enhanced Animated Counter
struct AnimatedCounter: View {
    let value: Double
    let format: String
    let duration: Double
    let font: Font
    let color: Color
    @State private var displayValue: Double = 0
    
    init(
        value: Double,
        format: String = "%.1f",
        duration: Double = 1.0,
        font: Font = .title2,
        color: Color = .primary
    ) {
        self.value = value
        self.format = format
        self.duration = duration
        self.font = font
        self.color = color
    }
    
    var body: some View {
        Text(String(format: format, displayValue))
            .font(font)
            .foregroundColor(color)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: duration * 0.5)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Enhanced Week Progress View
struct WeekProgressView: View {
    let currentHours: Double
    let targetHours: Double
    let showDetails: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedProgress: Double = 0
    
    init(currentHours: Double, targetHours: Double = 40.0, showDetails: Bool = true) {
        self.currentHours = currentHours
        self.targetHours = targetHours
        self.showDetails = showDetails
    }
    
    private var progress: Double {
        min(currentHours / targetHours, 1.0)
    }
    
    private var progressColor: Color {
        if progress < 0.5 { return .ksrWarning }
        if progress < 0.8 { return .ksrInfo }
        if progress < 1.0 { return .ksrSuccess }
        return .ksrError // Overtime
    }
    
    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [progressColor, progressColor.darker(by: 0.2)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showDetails {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Week Progress")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        Text(String(format: "%.1f of %.0f hours", currentHours, targetHours))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(animatedProgress * 100))%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(progressColor)
                        
                        if progress > 1.0 {
                            Text("Overtime!")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.ksrError)
                        }
                    }
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressGradient)
                        .frame(
                            width: geometry.size.width * CGFloat(animatedProgress),
                            height: 12
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(progressColor, lineWidth: 1)
                                .frame(
                                    width: geometry.size.width * CGFloat(animatedProgress),
                                    height: 12
                                )
                        )
                }
            }
            .frame(height: 12)
        }
        .padding(16)
        .background(WorkerDashboardStyles.cardBackground(colorScheme: colorScheme))
        .overlay(WorkerDashboardStyles.cardStroke(progressColor, opacity: 0.3))
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Enhanced Task Stats Grid
struct TaskStatsGrid: View {
    let stats: TaskStatistics
    @Environment(\.colorScheme) private var colorScheme
    
    struct TaskStatistics {
        let totalTasks: Int
        let completedTasks: Int
        let pendingHours: Double
        let approvedHours: Double
        let rejectedEntries: Int
        let draftEntries: Int
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task Overview")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                EnhancedStatCard(
                    value: "\(stats.totalTasks)",
                    label: "Total Tasks",
                    icon: "briefcase.fill",
                    color: .ksrPrimary,
                    trend: nil
                )
                
                EnhancedStatCard(
                    value: "\(stats.completedTasks)",
                    label: "Completed",
                    icon: "checkmark.circle.fill",
                    color: .ksrSuccess,
                    trend: stats.completedTasks > 0 ? .up : nil
                )
                
                EnhancedStatCard(
                    value: String(format: "%.1fh", stats.pendingHours),
                    label: "Pending Hours",
                    icon: "clock.fill",
                    color: .ksrWarning,
                    trend: stats.pendingHours > 0 ? .attention : nil
                )
                
                EnhancedStatCard(
                    value: String(format: "%.1fh", stats.approvedHours),
                    label: "Approved",
                    icon: "checkmark.seal.fill",
                    color: .ksrSuccess,
                    trend: stats.approvedHours > 0 ? .up : nil
                )
                
                if stats.rejectedEntries > 0 {
                    EnhancedStatCard(
                        value: "\(stats.rejectedEntries)",
                        label: "Needs Attention",
                        icon: "exclamationmark.triangle.fill",
                        color: .ksrError,
                        trend: .attention
                    )
                }
                
                if stats.draftEntries > 0 {
                    EnhancedStatCard(
                        value: "\(stats.draftEntries)",
                        label: "Drafts",
                        icon: "pencil.circle.fill",
                        color: .ksrWarning,
                        trend: .attention
                    )
                }
            }
        }
        .padding(20)
        .background(WorkerDashboardStyles.cardBackground(colorScheme: colorScheme))
        .overlay(WorkerDashboardStyles.cardStroke(Color.ksrPrimary))
    }
}

// MARK: - Enhanced Stat Card
struct EnhancedStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let trend: TrendIndicator?
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimated = false
    
    enum TrendIndicator {
        case up, down, attention
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .attention: return "exclamationmark"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .ksrSuccess
            case .down: return .ksrError
            case .attention: return .ksrWarning
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(trend.color)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Break down complex expression
                let numericString = value.filter { $0.isNumber || $0 == "." }
                let joinedString = String(numericString)
                let numericValue = Double(joinedString) ?? 0
                let displayFormat = value.contains(".") ? "%.1f" : "%.0f"
                
                AnimatedCounter(
                    value: numericValue,
                    format: displayFormat,
                    font: .title3,
                    color: colorScheme == .dark ? .white : .primary
                )
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isAnimated ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimated)
        .onAppear {
            if trend == .attention {
                withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
                    isAnimated = true
                }
            }
        }
    }
}

// MARK: - Enhanced Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let label: String?
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    @State private var isHovered = false
    
    init(
        icon: String,
        label: String? = nil,
        color: Color = Color.ksrYellow,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                if let label = label {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, label != nil ? 20 : 16)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [color, color.darker(by: 0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: label != nil ? 25 : 28))
            .shadow(
                color: color.opacity(0.3),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .animation(.spring(response: 0.3), value: isPressed)
    }
}

// MARK: - Enhanced Shimmer Loading Effect
struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 12) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.2),
                Color.gray.opacity(0.4),
                Color.gray.opacity(0.2)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.4),
                            Color.black,
                            Color.black.opacity(0.4)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .rotationEffect(.degrees(25))
                .offset(x: phase)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 300
            }
        }
    }
}

// MARK: - Enhanced Achievement Badge
struct AchievementBadge: View {
    let achievement: Achievement
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDetails = false
    @State private var isAnimated = false
    
    struct Achievement {
        let title: String
        let description: String
        let icon: String
        let color: Color
        let isUnlocked: Bool
        let progress: Double? // 0.0 to 1.0 for partial achievements
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                achievement.color,
                                achievement.color.darker(by: 0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .opacity(achievement.isUnlocked ? 1.0 : 0.5)
                
                // Progress ring for partial achievements
                if let progress = achievement.progress, !achievement.isUnlocked {
                    Circle()
                        .stroke(achievement.color.opacity(0.3), lineWidth: 3)
                        .frame(width: 85, height: 85)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            achievement.color,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 85, height: 85)
                        .rotationEffect(.degrees(-90))
                }
            }
            .scaleEffect(showDetails ? 1.1 : 1.0)
            .scaleEffect(isAnimated ? 1.05 : 1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    showDetails.toggle()
                }
            }
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if showDetails {
                    Text(achievement.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .scale))
                }
                
                if let progress = achievement.progress, !achievement.isUnlocked {
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(achievement.color)
                }
            }
        }
        .frame(width: 100)
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
        .onAppear {
            if achievement.isUnlocked {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(Double.random(in: 0...2))) {
                    isAnimated = true
                }
            }
        }
    }
}

// MARK: - Enhanced Custom Tab Bar
struct WorkerTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) private var colorScheme
    
    let tabs = [
        TabItem(icon: "house.fill", activeIcon: "house.fill", title: "Home"),
        TabItem(icon: "clock", activeIcon: "clock.fill", title: "Hours"),
        TabItem(icon: "briefcase", activeIcon: "briefcase.fill", title: "Tasks"),
        TabItem(icon: "person", activeIcon: "person.fill", title: "Profile")
    ]
    
    struct TabItem {
        let icon: String
        let activeIcon: String
        let title: String
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                EnhancedTabBarButton(
                    tab: tabs[index],
                    isSelected: selectedTab == index,
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = index
                        }
                    }
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.9) : Color.white)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                    radius: 12,
                    x: 0,
                    y: -4
                )
        )
        .padding(.horizontal, 16)
    }
}

struct EnhancedTabBarButton: View {
    let tab: WorkerTabBar.TabItem
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Color.ksrYellow : .secondary)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                Text(tab.title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? Color.ksrYellow : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        Color.ksrYellow.opacity(0.15) :
                        Color.clear
                    )
            )
        }
        .animation(.spring(response: 0.3), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Status Indicator Component
struct StatusIndicator: View {
    let status: EntryStatus
    let showLabel: Bool
    let size: StatusSize
    
    enum StatusSize {
        case small, medium, large
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
    }
    
    init(status: EntryStatus, showLabel: Bool = true, size: StatusSize = .medium) {
        self.status = status
        self.showLabel = showLabel
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundColor(.white)
            
            if showLabel {
                Text(status.displayName)
                    .font(size.font)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding * 0.6)
        .background(status.color)
        .clipShape(RoundedRectangle(cornerRadius: size.padding))
    }
}

// MARK: - Loading States
struct LoadingCard: View {
    let height: CGFloat
    
    init(height: CGFloat = 120) {
        self.height = height
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ShimmerView()
                    .frame(width: 60, height: 20)
                Spacer()
                ShimmerView()
                    .frame(width: 40, height: 20)
            }
            
            VStack(spacing: 8) {
                ShimmerView()
                    .frame(height: 16)
                ShimmerView()
                    .frame(height: 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 60)
            }
            
            Spacer()
        }
        .padding(16)
        .frame(height: height)
        .background(WorkerDashboardStyles.cardBackground(colorScheme: .light))
    }
}

// MARK: - Empty State Component
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.ksrPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.vertical, 40)
    }
}
