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
}
