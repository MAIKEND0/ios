import SwiftUI

struct MobileMonthView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    let onDateTap: (Date) -> Void
    
    @State private var selectedDate: Date?
    @State private var showingDateDetail = false
    
    private var monthDates: [Date] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: viewModel.displayedMonth),
              let monthFirstWeek = Calendar.current.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = Calendar.current.dateInterval(of: .weekOfYear, for: monthInterval.end)
        else { return [] }
        
        var dates: [Date] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthLastWeek.end {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Month Navigation
                MonthNavigationHeader(
                    currentMonth: viewModel.displayedMonth,
                    onPrevious: { viewModel.navigateToMonth(.previous) },
                    onNext: { viewModel.navigateToMonth(.next) },
                    onToday: { viewModel.navigateToToday() }
                )
                .padding(.horizontal)
                
                // Calendar Grid
                VStack(spacing: 0) {
                    // Weekday Headers
                    MobileWeekdayHeaders()
                    
                    // Days Grid
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                        spacing: 4
                    ) {
                        ForEach(monthDates, id: \.self) { date in
                            MobileDayCell(
                                date: date,
                                events: viewModel.getEventsForDate(date),
                                isSelected: selectedDate == date,
                                isToday: Calendar.current.isDateInToday(date),
                                isCurrentMonth: Calendar.current.isDate(date, equalTo: viewModel.displayedMonth, toGranularity: .month),
                                onTap: {
                                    selectedDate = date
                                    showingDateDetail = true
                                    onDateTap(date)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                // Selected Date Detail
                if showingDateDetail, let date = selectedDate {
                    SelectedDateDetail(
                        date: date,
                        events: viewModel.getEventsForDate(date),
                        onClose: { showingDateDetail = false }
                    )
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Month Summary
                MonthSummaryCard(viewModel: viewModel)
                    .padding(.horizontal)
                    .padding(.bottom, 80) // Space for FAB
            }
            .padding(.vertical)
        }
        .animation(.easeInOut(duration: 0.2), value: showingDateDetail)
    }
}

struct MonthNavigationHeader: View {
    let currentMonth: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
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
                Text(monthYearText)
                    .font(.headline)
                
                Button(action: onToday) {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.ksrPrimary)
                }
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

struct MobileWeekdayHeaders: View {
    private let weekdays = Calendar.current.veryShortWeekdaySymbols
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }
}

struct MobileDayCell: View {
    let date: Date
    let events: [ManagementCalendarEvent]
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var hasEvents: Bool {
        !events.isEmpty
    }
    
    private var hasConflicts: Bool {
        events.contains { !$0.conflicts.isEmpty }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.ksrPrimary.opacity(0.2)
        } else if isToday {
            return Color.ksrPrimary.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else if isToday {
            return .ksrPrimary
        } else {
            return .primary
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundColor(textColor)
                
                // Event Indicators
                if hasEvents {
                    HStack(spacing: 2) {
                        if hasConflicts {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                        } else {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                        }
                        
                        if events.count > 1 {
                            Text("\(events.count)")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Spacer()
                        .frame(height: 10)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.ksrPrimary : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!isCurrentMonth)
    }
}

struct SelectedDateDetail: View {
    let date: Date
    let events: [ManagementCalendarEvent]
    let onClose: () -> Void
    
    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateText)
                        .font(.headline)
                    Text("\(events.count) events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
            
            // Events List
            if events.isEmpty {
                Text("No events scheduled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(events.prefix(3)) { event in
                        MiniEventRow(event: event)
                    }
                    
                    if events.count > 3 {
                        Text("View all \(events.count) events →")
                            .font(.caption)
                            .foregroundColor(.ksrPrimary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MiniEventRow: View {
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
        HStack(spacing: 8) {
            Circle()
                .fill(eventColor)
                .frame(width: 8, height: 8)
            
            Text(event.title)
                .font(.system(size: 14))
                .lineLimit(1)
            
            Spacer()
            
            if !event.conflicts.isEmpty {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
}

struct MonthSummaryCard: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    private var monthEvents: [ManagementCalendarEvent] {
        let calendar = Calendar.current
        return viewModel.filteredEvents.filter { event in
            calendar.isDate(event.date, equalTo: viewModel.displayedMonth, toGranularity: .month)
        }
    }
    
    private var eventsByType: [CalendarEventType: Int] {
        Dictionary(grouping: monthEvents, by: { $0.type })
            .mapValues { $0.count }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Month Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Event Type Distribution
            HStack(spacing: 12) {
                ForEach(CalendarEventType.allCases.prefix(4), id: \.self) { type in
                    if let count = eventsByType[type], count > 0 {
                        EventTypeCount(type: type, count: count)
                    }
                }
            }
            
            // Total Summary
            HStack {
                Label("\(monthEvents.count) total events", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if monthEvents.contains(where: { !$0.conflicts.isEmpty }) {
                    Label("Has conflicts", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct EventTypeCount: View {
    let type: CalendarEventType
    let count: Int
    
    private var typeColor: Color {
        switch type {
        case .leave: return .orange
        case .project: return .blue
        case .task: return .green
        case .deadline: return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(typeColor)
                    .frame(width: 8, height: 8)
                Text("\(count)")
                    .font(.system(size: 16, weight: .semibold))
            }
            Text(type.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}