//
//  Calendar+Extensions.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 14/05/2025.
//

// Utils/Calendar+Extensions.swift
import Foundation

extension Calendar {
    /// Returns the start date (Monday) of the week containing the given date
    func startOfWeek(for date: Date) -> Date {
        let components = self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
    
    /// Returns the end date (Sunday) of the week containing the given date
    func endOfWeek(for date: Date) -> Date {
        let startOfWeek = self.startOfWeek(for: date)
        return self.date(byAdding: .day, value: 6, to: startOfWeek) ?? date
    }
    
    /// Checks if the given date is today
    func isToday(_ date: Date) -> Bool {
        return self.isDate(date, inSameDayAs: Date())
    }
    
    /// Checks if the given date was yesterday
    func isYesterday(_ date: Date) -> Bool {
        guard let yesterday = self.date(byAdding: .day, value: -1, to: Date()) else {
            return false
        }
        return self.isDate(date, inSameDayAs: yesterday)
    }
    
    /// Checks if the given date is tomorrow
    func isTomorrow(_ date: Date) -> Bool {
        guard let tomorrow = self.date(byAdding: .day, value: 1, to: Date()) else {
            return false
        }
        return self.isDate(date, inSameDayAs: tomorrow)
    }
    
    /// Checks if the given date is this week
    func isThisWeek(_ date: Date) -> Bool {
        return self.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Checks if the given date is this month
    func isThisMonth(_ date: Date) -> Bool {
        return self.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    /// Checks if the given date is this year
    func isThisYear(_ date: Date) -> Bool {
        return self.isDate(date, equalTo: Date(), toGranularity: .year)
    }
    
    /// Returns the number of days between two dates
    func daysBetween(_ startDate: Date, and endDate: Date) -> Int {
        let components = self.dateComponents([.day], from: startDate, to: endDate)
        return components.day ?? 0
    }
    
    /// Returns the number of hours between two dates
    func hoursBetween(_ startDate: Date, and endDate: Date) -> Int {
        let components = self.dateComponents([.hour], from: startDate, to: endDate)
        return components.hour ?? 0
    }
    
    /// Returns the end of the day for the given date
    func endOfDay(for date: Date) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return self.date(byAdding: components, to: self.startOfDay(for: date)) ?? date
    }
    
    /// Returns the start of the month for the given date
    func startOfMonth(for date: Date) -> Date {
        let components = self.dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    /// Returns the end of the month for the given date
    func endOfMonth(for date: Date) -> Date {
        guard let startOfNextMonth = self.date(byAdding: .month, value: 1, to: self.startOfMonth(for: date)) else {
            return date
        }
        return self.date(byAdding: .second, value: -1, to: startOfNextMonth) ?? date
    }
    
    /// Returns all dates in the given month
    func datesInMonth(for date: Date) -> [Date] {
        let startOfMonth = self.startOfMonth(for: date)
        let range = self.range(of: .day, in: .month, for: date) ?? 0..<1
        
        return range.compactMap { day in
            return self.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    /// Returns all dates in the current week (Monday to Sunday)
    func datesInWeek(for date: Date) -> [Date] {
        let startOfWeek = self.startOfWeek(for: date)
        return (0..<7).compactMap { dayOffset in
            return self.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    /// Returns the week number for the given date
    func weekNumber(for date: Date) -> Int {
        return self.component(.weekOfYear, from: date)
    }
    
    /// Returns the year for the given date
    func year(for date: Date) -> Int {
        return self.component(.year, from: date)
    }
    
    /// Checks if a date is within a certain number of days from now
    func isWithin(days: Int, of targetDate: Date, from referenceDate: Date = Date()) -> Bool {
        let daysBetween = abs(self.daysBetween(referenceDate, and: targetDate))
        return daysBetween <= days
    }
    
    /// Returns a relative description of the date (e.g., "2 days ago", "in 3 hours")
    func relativeDescription(for date: Date, from referenceDate: Date = Date()) -> String {
        let components = self.dateComponents([.year, .month, .day, .hour, .minute], from: referenceDate, to: date)
        
        if let years = components.year, years != 0 {
            return years > 0 ? "in \(years) year\(years == 1 ? "" : "s")" : "\(-years) year\(years == -1 ? "" : "s") ago"
        }
        
        if let months = components.month, months != 0 {
            return months > 0 ? "in \(months) month\(months == 1 ? "" : "s")" : "\(-months) month\(months == -1 ? "" : "s") ago"
        }
        
        if let days = components.day, days != 0 {
            if days == 1 { return "tomorrow" }
            if days == -1 { return "yesterday" }
            return days > 0 ? "in \(days) days" : "\(-days) days ago"
        }
        
        if let hours = components.hour, hours != 0 {
            return hours > 0 ? "in \(hours) hour\(hours == 1 ? "" : "s")" : "\(-hours) hour\(hours == -1 ? "" : "s") ago"
        }
        
        if let minutes = components.minute, minutes != 0 {
            return minutes > 0 ? "in \(minutes) minute\(minutes == 1 ? "" : "s")" : "\(-minutes) minute\(minutes == -1 ? "" : "s") ago"
        }
        
        return "now"
    }
}

// MARK: - Date Extensions for easier use

extension Date {
    /// Returns true if this date is today
    var isToday: Bool {
        return Calendar.current.isToday(self)
    }
    
    /// Returns true if this date was yesterday
    var isYesterday: Bool {
        return Calendar.current.isYesterday(self)
    }
    
    /// Returns true if this date is tomorrow
    var isTomorrow: Bool {
        return Calendar.current.isTomorrow(self)
    }
    
    /// Returns true if this date is in the current week
    var isThisWeek: Bool {
        return Calendar.current.isThisWeek(self)
    }
    
    /// Returns true if this date is in the current month
    var isThisMonth: Bool {
        return Calendar.current.isThisMonth(self)
    }
    
    /// Returns true if this date is in the current year
    var isThisYear: Bool {
        return Calendar.current.isThisYear(self)
    }
    
    /// Returns the start of the day for this date
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Returns the end of the day for this date
    var endOfDay: Date {
        return Calendar.current.endOfDay(for: self)
    }
    
    /// Returns the start of the week for this date
    var startOfWeek: Date {
        return Calendar.current.startOfWeek(for: self)
    }
    
    /// Returns the end of the week for this date
    var endOfWeek: Date {
        return Calendar.current.endOfWeek(for: self)
    }
    
    /// Returns the start of the month for this date
    var startOfMonth: Date {
        return Calendar.current.startOfMonth(for: self)
    }
    
    /// Returns the end of the month for this date
    var endOfMonth: Date {
        return Calendar.current.endOfMonth(for: self)
    }
    
    /// Returns the week number for this date
    var weekNumber: Int {
        return Calendar.current.weekNumber(for: self)
    }
    
    /// Returns the year for this date
    var year: Int {
        return Calendar.current.year(for: self)
    }
    
    /// Returns a relative description of this date
    var relativeDescription: String {
        return Calendar.current.relativeDescription(for: self)
    }
    
    /// Returns the number of days between this date and another date
    func days(to date: Date) -> Int {
        return Calendar.current.daysBetween(self, and: date)
    }
    
    /// Returns the number of hours between this date and another date
    func hours(to date: Date) -> Int {
        return Calendar.current.hoursBetween(self, and: date)
    }
    
    /// Checks if this date is within a certain number of days from another date
    func isWithin(days: Int, of date: Date) -> Bool {
        return Calendar.current.isWithin(days: days, of: self, from: date)
    }
}
