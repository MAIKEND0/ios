import SwiftUI

struct MobileWeekView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    let onEventTap: (ManagementCalendarEvent) -> Void
    
    @State private var selectedWeek = Date()
    @GestureState private var dragOffset: CGFloat = 0
    
    private var weekDays: [Date] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedWeek) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = weekInterval.start
        
        for _ in 0..<7 {
            days.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Week Navigation Header
            WeekNavigationHeader(
                selectedWeek: $selectedWeek,
                onPrevious: previousWeek,
                onNext: nextWeek
            )
            .padding()
            
            // Week Days
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(weekDays, id: \.self) { date in
                        CompactDayColumn(
                            date: date,
                            events: eventsForDate(date),
                            isToday: Calendar.current.isDateInToday(date),
                            viewModel: viewModel,
                            onEventTap: onEventTap
                        )
                        .frame(width: UIScreen.main.bounds.width * 0.4)
                    }
                }
                .padding(.horizontal)
            }
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        if value.translation.width > 50 {
                            previousWeek()
                        } else if value.translation.width < -50 {
                            nextWeek()
                        }
                    }
            )
            
            // Week Summary
            WeekSummaryCard(viewModel: viewModel, weekDays: weekDays)
                .padding()
            
            Spacer()
        }
    }
    
    private func eventsForDate(_ date: Date) -> [ManagementCalendarEvent] {
        viewModel.getEventsForDate(date)
    }
    
    private func previousWeek() {
        withAnimation {
            selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedWeek) ?? selectedWeek
        }
    }
    
    private func nextWeek() {
        withAnimation {
            selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedWeek) ?? selectedWeek
        }
    }
}

struct WeekNavigationHeader: View {
    @Binding var selectedWeek: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    private var weekRangeText: String {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedWeek) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let start = formatter.string(from: weekInterval.start)
        let end = formatter.string(from: calendar.date(byAdding: .day, value: -1, to: weekInterval.end) ?? weekInterval.end)
        
        return "\(start) - \(end)"
    }
    
    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Week View")
                    .font(.headline)
                Text(weekRangeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
            }
        }
    }
}

struct CompactDayColumn: View {
    let date: Date
    let events: [ManagementCalendarEvent]
    let isToday: Bool
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    let onEventTap: (ManagementCalendarEvent) -> Void
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var hasConflicts: Bool {
        events.contains { !$0.conflicts.isEmpty }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Day Header
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(dayNumber)
                    .font(.system(size: 20, weight: isToday ? .bold : .medium))
                    .foregroundColor(isToday ? .white : .primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isToday ? Color.ksrPrimary : Color.clear)
                    )
            }
            .padding(.vertical, 12)
            
            // Events Summary
            VStack(spacing: 8) {
                if events.isEmpty {
                    Text("No events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                } else {
                    // Event Count Badge
                    HStack(spacing: 4) {
                        Text("\(events.count)")
                            .font(.system(size: 16, weight: .semibold))
                        Text("events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if hasConflicts {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Event Pills (show max 4)
                    VStack(spacing: 6) {
                        ForEach(events.prefix(4)) { event in
                            MiniEventPill(event: event)
                                .onTapGesture { onEventTap(event) }
                        }
                        
                        if events.count > 4 {
                            Text("+\(events.count - 4) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            
            Spacer()
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onTapGesture {
            viewModel.selectDate(date)
        }
    }
}

struct MiniEventPill: View {
    let event: ManagementCalendarEvent
    
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
        HStack(spacing: 4) {
            Circle()
                .fill(eventColor)
                .frame(width: 4, height: 4)
            
            Text(event.title)
                .font(.caption2)
                .lineLimit(1)
            
            if event.priority == .critical || event.priority == .high {
                Image(systemName: "flag.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(eventColor.opacity(0.1))
        .cornerRadius(6)
    }
}

struct WeekSummaryCard: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    let weekDays: [Date]
    
    private var weekEvents: [ManagementCalendarEvent] {
        weekDays.flatMap { viewModel.getEventsForDate($0) }
    }
    
    private var conflictCount: Int {
        weekEvents.filter { !$0.conflicts.isEmpty }.count
    }
    
    private var highPriorityCount: Int {
        weekEvents.filter { $0.priority == .high || $0.priority == .critical }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Week Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                SummaryItem(
                    value: "\(weekEvents.count)",
                    label: "Total Events",
                    color: .blue
                )
                
                SummaryItem(
                    value: "\(highPriorityCount)",
                    label: "High Priority",
                    color: .orange
                )
                
                SummaryItem(
                    value: "\(conflictCount)",
                    label: "Conflicts",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct SummaryItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}