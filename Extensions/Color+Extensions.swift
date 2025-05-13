import SwiftUI

extension Color {
    // KSR Cranes brand colors
    static let ksrYellow = Color(hex: "FFD700") // Adjust to match your exact yellow
    static let ksrDarkGray = Color(hex: "333333")
    static let ksrMediumGray = Color(hex: "666666")
    static let ksrLightGray = Color(hex: "EEEEEE")
    
    // Helper to create colors from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b, a: Double
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = (Double((int >> 8) & 0xF) / 15.0,
                           Double((int >> 4) & 0xF) / 15.0,
                           Double(int & 0xF) / 15.0,
                           1.0)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (Double((int >> 16) & 0xFF) / 255.0,
                           Double((int >> 8) & 0xFF) / 255.0,
                           Double(int & 0xFF) / 255.0,
                           1.0)
        case 8: // ARGB (32-bit)
            (r, g, b, a) = (Double((int >> 16) & 0xFF) / 255.0,
                           Double((int >> 8) & 0xFF) / 255.0,
                           Double(int & 0xFF) / 255.0,
                           Double((int >> 24) & 0xFF) / 255.0)
        default:
            (r, g, b, a) = (0, 0, 0, 1)
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
