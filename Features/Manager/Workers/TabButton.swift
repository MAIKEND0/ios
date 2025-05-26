// TabButton.swift
// KSR Cranes App

import SwiftUI

protocol TabProtocol: Identifiable, CaseIterable, RawRepresentable where RawValue == String {
    var icon: String { get }
    var color: Color { get }
}

struct TabButton<T: TabProtocol>: View {
    let tab: T
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tab.color : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tab.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
