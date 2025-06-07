//
//  WorkerLeaveCalendarView.swift
//  KSR Cranes App
//
//  Calendar view for worker leave requests and public holidays
//

import SwiftUI

struct WorkerLeaveCalendarView: View {
    let leaveRequests: [LeaveRequest]
    let publicHolidays: [PublicHoliday]
    
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Calendar Header
            CalendarHeaderView(
                displayedMonth: $displayedMonth,
                onPreviousMonth: goToPreviousMonth,
                onNextMonth: goToNextMonth,
                onToday: goToToday
            )
            
            // Calendar Grid
            CalendarGridView(
                displayedMonth: displayedMonth,
                selectedDate: $selectedDate,
                leaveRequests: leaveRequests,
                publicHolidays: publicHolidays
            )
            
            // Selected Date Details
            if let selectedDateLeave = leaveForDate(selectedDate) {
                SelectedDateDetailView(
                    date: selectedDate,
                    leaveRequest: selectedDateLeave,
                    holiday: holidayForDate(selectedDate)
                )
            } else if let holiday = holidayForDate(selectedDate) {
                SelectedDateHolidayView(
                    date: selectedDate,
                    holiday: holiday
                )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Navigation Actions
    
    private func goToPreviousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        }
    }
    
    private func goToNextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        }
    }
    
    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedMonth = Date()
            selectedDate = Date()
        }
    }
    
    // MARK: - Data Helpers
    
    private func leaveForDate(_ date: Date) -> LeaveRequest? {
        return leaveRequests.first { request in
            date >= Calendar.current.startOfDay(for: request.start_date) &&
            date <= Calendar.current.startOfDay(for: request.end_date)
        }
    }
    
    private func holidayForDate(_ date: Date) -> PublicHoliday? {
        return publicHolidays.first { holiday in
            Calendar.current.isDate(holiday.date, inSameDayAs: date)
        }
    }
}

// MARK: - Calendar Header

struct CalendarHeaderView: View {
    @Binding var displayedMonth: Date
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    let onToday: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack {
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Button("I dag") {
                    onToday()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "da_DK")
        return formatter.string(from: displayedMonth)
    }
}

// MARK: - Calendar Grid

struct CalendarGridView: View {
    let displayedMonth: Date
    @Binding var selectedDate: Date
    let leaveRequests: [LeaveRequest]
    let publicHolidays: [PublicHoliday]
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday headers
            WeekdayHeadersView()
            
            // Calendar days
            let weeks = getWeeksInMonth()
            ForEach(weeks, id: \.self) { week in
                HStack(spacing: 0) {
                    ForEach(week, id: \.self) { date in
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isCurrentMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
                            isToday: calendar.isDateInToday(date),
                            leaveRequest: leaveForDate(date),
                            holiday: holidayForDate(date)
                        ) {
                            selectedDate = date
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func getWeeksInMonth() -> [[Date]] {
        guard let monthRange = calendar.range(of: .weekOfYear, in: .month, for: displayedMonth) else {
            return []
        }
        
        let firstOfMonth = calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
        var weeks: [[Date]] = []
        
        for weekOfYear in monthRange {
            var week: [Date] = []
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: firstOfMonth)?.start {
                let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: weekOfYear - 1, to: weekStart) ?? weekStart
                
                for i in 0..<7 {
                    if let day = calendar.date(byAdding: .day, value: i, to: targetWeekStart) {
                        week.append(day)
                    }
                }
            }
            weeks.append(week)
        }
        
        return weeks
    }
    
    private func leaveForDate(_ date: Date) -> LeaveRequest? {
        return leaveRequests.first { request in
            date >= calendar.startOfDay(for: request.start_date) &&
            date <= calendar.startOfDay(for: request.end_date)
        }
    }
    
    private func holidayForDate(_ date: Date) -> PublicHoliday? {
        return publicHolidays.first { holiday in
            calendar.isDate(holiday.date, inSameDayAs: date)
        }
    }
}

// MARK: - Weekday Headers

struct WeekdayHeadersView: View {
    private let weekdays = ["Man", "Tir", "Ons", "Tor", "Fre", "Lør", "Søn"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Calendar Day

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isToday: Bool
    let leaveRequest: LeaveRequest?
    let holiday: PublicHoliday?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundColor(textColor)
                
                // Leave/Holiday indicators
                HStack(spacing: 2) {
                    if let leaveRequest = leaveRequest {
                        Circle()
                            .fill(colorForLeaveType(leaveRequest.type))
                            .frame(width: 6, height: 6)
                    }
                    
                    if holiday != nil {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(2)
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary
        } else if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue.opacity(0.2)
        } else if leaveRequest != nil {
            return colorForLeaveType(leaveRequest!.type).opacity(0.2)
        } else if holiday != nil {
            return .purple.opacity(0.1)
        } else {
            return .clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        isSelected || isToday ? 2 : 0
    }
    
    private func colorForLeaveType(_ type: LeaveType) -> Color {
        switch type {
        case .vacation: return .green
        case .sick: return .red
        case .personal: return .orange
        case .parental: return .pink
        case .compensatory: return .cyan
        case .emergency: return .red
        }
    }
}

// MARK: - Selected Date Detail Views

struct SelectedDateDetailView: View {
    let date: Date
    let leaveRequest: LeaveRequest
    let holiday: PublicHoliday?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(date, formatter: DateFormatter.selectedDateFormatter)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Leave Request Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(colorForLeaveType(leaveRequest.type))
                        .frame(width: 12, height: 12)
                    
                    Text(leaveRequest.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    StatusBadge(status: leaveRequest.status)
                }
                
                if let reason = leaveRequest.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Periode: \(formatDateRange(leaveRequest.start_date, leaveRequest.end_date))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Holiday info if present
            if let holiday = holiday {
                Divider()
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.purple)
                    
                    Text(holiday.name)
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func colorForLeaveType(_ type: LeaveType) -> Color {
        switch type {
        case .vacation: return .green
        case .sick: return .red
        case .personal: return .orange
        case .parental: return .pink
        case .compensatory: return .cyan
        case .emergency: return .red
        }
    }
    
    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if Calendar.current.isDate(start, inSameDayAs: end) {
            return formatter.string(from: start)
        } else {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
}

struct SelectedDateHolidayView: View {
    let date: Date
    let holiday: PublicHoliday
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(date, formatter: DateFormatter.selectedDateFormatter)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(holiday.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    
                    if let description = holiday.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        formatter.locale = Locale(identifier: "da_DK")
        return formatter
    }()
}

#if DEBUG
struct WorkerLeaveCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerLeaveCalendarView(
            leaveRequests: [],
            publicHolidays: []
        )
    }
}
#endif