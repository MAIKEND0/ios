//
//  WeekUtils.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 22/05/2025.
//  Utility functions for consistent week calculations across the app
//

import Foundation

struct WeekUtils {
    /// Returns a calendar configured with Monday as the first day of the week
    static var mondayFirstCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday = 2
        calendar.timeZone = TimeZone.current
        return calendar
    }
    
    /// Returns the start of the week (Monday) for a given date
    static func startOfWeek(for date: Date) -> Date {
        let calendar = mondayFirstCalendar
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
    
    /// Returns the end of the week (Sunday) for a given date
    static func endOfWeek(for date: Date) -> Date {
        let startDate = startOfWeek(for: date)
        return Calendar.current.date(byAdding: .day, value: 6, to: startDate) ?? date
    }
    
    /// Returns week number for a given date using Monday-first calendar
    static func weekNumber(for date: Date) -> Int {
        return mondayFirstCalendar.component(.weekOfYear, from: date)
    }
    
    /// Returns year for a given date using Monday-first calendar
    static func year(for date: Date) -> Int {
        return mondayFirstCalendar.component(.year, from: date)
    }
    
    /// Creates a date from week number and year using Monday-first calendar
    static func date(from weekNumber: Int, year: Int) -> Date? {
        let calendar = mondayFirstCalendar
        var components = DateComponents()
        components.weekOfYear = weekNumber
        components.yearForWeekOfYear = year
        return calendar.date(from: components)
    }
}
