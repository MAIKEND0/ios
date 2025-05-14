//
//  UIApplication+Extensions.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 14/05/2025.
//

// Core/Extensions/UIApplication+Extensions.swift
import SwiftUI

extension UIApplication {
    /// Ukrywa klawiaturę
    func hideKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }
}
