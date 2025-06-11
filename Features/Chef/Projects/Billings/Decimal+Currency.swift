//
//  Decimal+Currency.swift
//  KSR Cranes App
//
//  Extension for formatting Decimal values as currency
//

import Foundation

extension Decimal {
    /// Formats the decimal value as DKK currency
    func formatted(_ style: FloatingPointFormatStyle<Double>.Currency) -> String {
        let double = NSDecimalNumber(decimal: self).doubleValue
        return double.formatted(style)
    }
    
    /// Formats the decimal value as DKK currency with default settings
    var formattedAsCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "DKK"
        formatter.locale = Locale(identifier: "da_DK")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSDecimalNumber(decimal: self)) ?? "0 kr"
    }
    
    /// Formats the decimal value as DKK currency with custom locale
    func formattedAsCurrency(locale: Locale = Locale(identifier: "da_DK")) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "DKK"
        formatter.locale = locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSDecimalNumber(decimal: self)) ?? "0 kr"
    }
}
