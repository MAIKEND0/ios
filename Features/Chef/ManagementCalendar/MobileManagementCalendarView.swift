import SwiftUI

struct MobileManagementCalendarView: View {
    @StateObject private var viewModel = ChefManagementCalendarViewModel()
    @State private var selectedTab: MobileCalendarTab = .today
    @State private var showingEventDetail = false
    @State private var selectedEvent: ManagementCalendarEvent?
    @State private var showingQuickActions = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Compact Header
                MobileCalendarHeader(viewModel: viewModel)
                    .frame(height: 60)
                
                // Main Content
                TabView(selection: $selectedTab) {
                    // Today View
                    TodayView(viewModel: viewModel, onEventTap: selectEvent)
                        .tag(MobileCalendarTab.today)
                    
                    // Week View
                    MobileWeekView(viewModel: viewModel, onEventTap: selectEvent)
                        .tag(MobileCalendarTab.week)
                    
                    // Month Overview
                    MobileMonthView(viewModel: viewModel, onDateTap: { date in
                        viewModel.selectDate(date)
                    })
                    .tag(MobileCalendarTab.month)
                    
                    // Team View
                    MobileTeamView(viewModel: viewModel)
                        .tag(MobileCalendarTab.team)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom Tab Bar
                MobileCalendarTabBar(selectedTab: $selectedTab)
                    .frame(height: 56)
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    MobileQuickActionButton(
                        isExpanded: $showingQuickActions,
                        viewModel: viewModel
                    )
                    .padding(16)
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            MobileEventDetailSheet(
                event: event,
                viewModel: viewModel,
                onDismiss: { selectedEvent = nil }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            viewModel.loadInitialData()
        }
    }
    
    private func selectEvent(_ event: ManagementCalendarEvent) {
        selectedEvent = event
        showingEventDetail = true
    }
}

// MARK: - Tab Bar

enum MobileCalendarTab {
    case today, week, month, team
    
    var icon: String {
        switch self {
        case .today: return "calendar.day.timeline.left"
        case .week: return "calendar"
        case .month: return "calendar.badge.clock"
        case .team: return "person.3.fill"
        }
    }
    
    var label: String {
        switch self {
        case .today: return "Today"
        case .week: return "Week"
        case .month: return "Month"
        case .team: return "Team"
        }
    }
}

struct MobileCalendarTabBar: View {
    @Binding var selectedTab: MobileCalendarTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([MobileCalendarTab.today, .week, .month, .team], id: \.self) { tab in
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab 
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        Text(tab.label)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == tab ? .ksrPrimary : .secondary)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.bottom, 8)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: -1)
        )
    }
}

// MARK: - Header

struct MobileCalendarHeader: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Management Calendar")
                    .font(.headline)
                Text(DateFormatter.dayMonth.string(from: Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Refresh Button
            Button(action: {
                Task { await viewModel.refreshCalendarData() }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
}

// MARK: - Today View

struct TodayView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    let onEventTap: (ManagementCalendarEvent) -> Void
    
    private var todayEvents: [ManagementCalendarEvent] {
        viewModel.eventsForSelectedDate
    }
    
    private var urgentItems: [ManagementCalendarEvent] {
        viewModel.filteredEvents.filter { event in
            (event.priority == .high || event.priority == .critical) ||
            !event.conflicts.isEmpty
        }.prefix(3).map { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick Stats
                QuickStatsCard(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Urgent Items
                if !urgentItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ManagementSectionHeader(title: "Urgent Attention", icon: "exclamationmark.triangle.fill")
                            .padding(.horizontal)
                        
                        ForEach(urgentItems) { event in
                            UrgentEventCard(event: event)
                                .padding(.horizontal)
                                .onTapGesture { onEventTap(event) }
                        }
                    }
                }
                
                // Today's Schedule
                VStack(alignment: .leading, spacing: 12) {
                    ManagementSectionHeader(title: "Today's Schedule", icon: "calendar")
                        .padding(.horizontal)
                    
                    if todayEvents.isEmpty {
                        EmptyScheduleCard()
                            .padding(.horizontal)
                    } else {
                        ForEach(todayEvents) { event in
                            MobileEventCard(event: event)
                                .padding(.horizontal)
                                .onTapGesture { onEventTap(event) }
                        }
                    }
                }
                
                // Team Quick Status
                TeamQuickStatus(viewModel: viewModel)
                    .padding(.horizontal)
                    .padding(.bottom, 80) // Space for FAB
            }
            .padding(.vertical)
        }
        .refreshable {
            await viewModel.refreshCalendarData()
        }
    }
}

// MARK: - Components

struct QuickStatsCard: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            StatItem(
                value: "\(viewModel.calendarSummary?.availableWorkers ?? 0)",
                label: "Available",
                color: .green
            )
            
            StatItem(
                value: "\(viewModel.calendarSummary?.workersOnLeave ?? 0)",
                label: "On Leave",
                color: .orange
            )
            
            StatItem(
                value: "\(viewModel.calendarSummary?.totalEvents ?? 0)",
                label: "Events",
                color: .blue
            )
            
            StatItem(
                value: "\(viewModel.calendarSummary?.conflictCount ?? 0)",
                label: "Conflicts",
                color: .red
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    struct StatItem: View {
        let value: String
        let label: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ManagementSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.ksrPrimary)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
}

struct MobileEventCard: View {
    let event: ManagementCalendarEvent
    
    private var timeString: String {
        DateFormatter.mobileHourMinute.string(from: event.date)
    }
    
    private var eventColor: Color {
        switch event.type {
        case .leave: return .orange
        case .project: return .blue
        case .task: return .green
        case .deadline: return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            VStack {
                Text(timeString)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // Type Indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(eventColor)
                .frame(width: 4)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    // Type Badge
                    EventTypeBadge(type: event.type)
                    
                    // Priority
                    if event.priority == .high || event.priority == .critical {
                        MobilePriorityBadge(priority: event.priority)
                    }
                    
                    // Conflicts
                    if !event.conflicts.isEmpty {
                        ConflictBadge(count: event.conflicts.count)
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct UrgentEventCard: View {
    let event: ManagementCalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Warning Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                
                if let conflict = event.conflicts.first {
                    Text(conflict.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Action
            Text("Resolve")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct EmptyScheduleCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 40))
                .foregroundColor(.green.opacity(0.6))
            
            Text("No events scheduled")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TeamQuickStatus: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ManagementSectionHeader(title: "Team Status", icon: "person.3.fill")
            
            if let matrix = viewModel.workerAvailabilityMatrix {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(matrix.workers.prefix(5), id: \.id) { worker in
                            MiniWorkerCard(worker: worker)
                        }
                    }
                }
            }
        }
    }
}

struct MiniWorkerCard: View {
    let worker: WorkerAvailabilityRow
    
    private var statusColor: Color {
        let today = Date()
        let todayAvailability = worker.getAvailability(for: today)
        
        switch todayAvailability?.status {
        case .available: return .green
        case .assigned, .partiallyBusy: return .orange
        case .onLeave, .unavailable: return .gray
        case .sick: return .red
        case .overloaded: return .red
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(worker.worker.name.prefix(2))
                        .font(.system(size: 16, weight: .medium))
                )
            
            // Name
            Text(worker.worker.name.split(separator: " ").first ?? "")
                .font(.caption)
                .lineLimit(1)
            
            // Status
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
        .frame(width: 70)
    }
}

// MARK: - Badges

struct EventTypeBadge: View {
    let type: CalendarEventType
    
    var body: some View {
        Text(type.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(4)
    }
}

struct MobilePriorityBadge: View {
    let priority: EventPriority
    
    private var color: Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "flag.fill")
                .font(.system(size: 10))
            Text(priority.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(4)
    }
}

struct ConflictBadge: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.red.opacity(0.1))
        .foregroundColor(.red)
        .cornerRadius(4)
    }
}

// MARK: - Floating Action Button

struct MobileQuickActionButton: View {
    @Binding var isExpanded: Bool
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Action Items
            if isExpanded {
                VStack(spacing: 12) {
                    QuickActionItem(
                        icon: "person.badge.plus",
                        label: "Assign",
                        color: .green
                    ) {
                        // Handle assign worker
                        isExpanded = false
                    }
                    
                    QuickActionItem(
                        icon: "calendar.badge.plus",
                        label: "Event",
                        color: .blue
                    ) {
                        // Handle create event
                        isExpanded = false
                    }
                    
                    QuickActionItem(
                        icon: "exclamationmark.triangle",
                        label: "Conflicts",
                        color: .orange
                    ) {
                        // Handle view conflicts
                        isExpanded = false
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Main Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color.ksrPrimary)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
            }
        }
    }
}

struct QuickActionItem: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color)
                    )
            }
        }
    }
}

// MARK: - Date Formatters

extension DateFormatter {
    static let mobileDayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }()
    
    static let mobileHourMinute: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}