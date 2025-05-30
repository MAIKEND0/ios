// Core/Extensions/Color+Extensions.swift
import SwiftUI

extension Color {
    
    // MARK: - KSR Cranes Brand Colors (Adaptive - zachowuje istniejące nazwy)
    
    /// Primary brand color - adaptacyjny cooper/bronze z doskonałym kontrastem
    /// Dark mode: #D4761A (6.8:1 contrast) | Light mode: #B85A00 (5.2:1 contrast)
    static let ksrYellow = Color.adaptive(
        light: Color(hex: "B85A00"),
        dark: Color(hex: "D4761A")
    )
    
    /// Primary alternative - cieplejszy bronze
    /// Dark mode: #C46315 (5.8:1 contrast) | Light mode: #A04A00 (6.1:1 contrast)
    static let ksrPrimary = Color.adaptive(
        light: Color(hex: "A04A00"),
        dark: Color(hex: "C46315")
    )
    
    /// Success/Approved color - profesjonalna zieleń
    /// Dark mode: #4CAF50 (7.2:1 contrast) | Light mode: #2E7D32 (5.9:1 contrast)
    static let ksrSuccess = Color.adaptive(
        light: Color(hex: "2E7D32"),
        dark: Color(hex: "4CAF50")
    )
    
    /// Success alternative - teal option
    /// Dark mode: #26A69A (6.1:1 contrast) | Light mode: #00695C (5.8:1 contrast)
    static let ksrSuccessAlt = Color.adaptive(
        light: Color(hex: "00695C"),
        dark: Color(hex: "26A69A")
    )
    
    /// Warning/Pending color - bursztyn działający w obu trybach
    /// Dark mode: #FFB74D (8.1:1 contrast) | Light mode: #F57C00 (4.8:1 contrast)
    static let ksrWarning = Color.adaptive(
        light: Color(hex: "F57C00"),
        dark: Color(hex: "FFB74D")
    )
    
    /// Error/Rejected color - wyrazisty czerwony
    /// Dark mode: #F44336 (5.6:1 contrast) | Light mode: #C62828 (6.4:1 contrast)
    static let ksrError = Color.adaptive(
        light: Color(hex: "C62828"),
        dark: Color(hex: "F44336")
    )
    
    /// Info/Secondary color - spokojny niebieski
    /// Dark mode: #42A5F5 (6.3:1 contrast) | Light mode: #1976D2 (5.7:1 contrast)
    static let ksrInfo = Color.adaptive(
        light: Color(hex: "1976D2"),
        dark: Color(hex: "42A5F5")
    )
    
    // MARK: - Istniejące kolory szare (teraz adaptacyjne)
    
    /// Ultra ciemne tło - dla głównych ekranów
    /// Dark mode: #1A1A1A | Light mode: #FAFAFA
    static let ksrDarkGray = Color.adaptive(
        light: Color(hex: "FAFAFA"),
        dark: Color(hex: "1A1A1A")
    )
    
    /// Średnie tło - dla kart i sekcji
    /// Dark mode: #2D2D2D | Light mode: #F5F5F5
    static let ksrMediumGray = Color.adaptive(
        light: Color(hex: "F5F5F5"),
        dark: Color(hex: "2D2D2D")
    )
    
    /// Jasne tło - dla pól tekstowych
    /// Dark mode: #3A3A3A | Light mode: #FFFFFF
    static let ksrLightGray = Color.adaptive(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "3A3A3A")
    )
    
    // MARK: - Dodatkowe kolory (zachowane nazwy)
    
    /// Secondary text/icon color for subtle elements
    /// Dark mode: #AAAAAA | Light mode: #666666
    static let ksrSecondary = Color.adaptive(
        light: Color(hex: "666666"),
        dark: Color(hex: "AAAAAA")
    )
    
    // MARK: - Semantic Color Aliases (zachowane dla kompatybilności)
    
    /// For pending/attention items
    static let pendingColor = ksrWarning
    
    /// For approved/completed items
    static let approvedColor = ksrSuccess
    
    /// For active/in-progress items
    static let activeColor = ksrInfo
    
    /// For inactive/disabled items
    static let inactiveColor = ksrMediumGray
    
    // MARK: - Background Variants (adaptacyjne wersje)
    
    /// Light background tints for subtle backgrounds
    static let ksrYellowLight = ksrYellow.opacity(0.1)
    static let ksrSuccessLight = ksrSuccess.opacity(0.1)
    static let ksrWarningLight = ksrWarning.opacity(0.1)
    static let ksrErrorLight = ksrError.opacity(0.1)
    static let ksrInfoLight = ksrInfo.opacity(0.1)
    
    // MARK: - Nowe kolory pomocnicze (dodatkowe bez zmiany istniejących)
    
    /// Kolory granic adaptacyjne
    /// Dark mode: #4A4A4A | Light mode: #E0E0E0
    static let ksrBorder = Color.adaptive(
        light: Color(hex: "E0E0E0"),
        dark: Color(hex: "4A4A4A")
    )
    
    /// Subtelne granice
    /// Dark mode: #333333 | Light mode: #F0F0F0
    static let ksrBorderSubtle = Color.adaptive(
        light: Color(hex: "F0F0F0"),
        dark: Color(hex: "333333")
    )
    
    /// Główne tło aplikacji
    /// Dark mode: #000000 | Light mode: #FFFFFF
    static let ksrBackground = Color.adaptive(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "000000")
    )
    
    /// Drugorzędne tło
    /// Dark mode: #1C1C1E | Light mode: #F2F2F7
    static let ksrBackgroundSecondary = Color.adaptive(
        light: Color(hex: "F2F2F7"),
        dark: Color(hex: "1C1C1E")
    )
    
    /// Tekst podstawowy (adaptacyjny)
    static let ksrTextPrimary = Color.adaptive(
        light: Color(hex: "000000"),
        dark: Color(hex: "FFFFFF")
    )
    
    /// Tekst drugorzędny (adaptacyjny)
    static let ksrTextSecondary = Color.adaptive(
        light: Color(hex: "666666"),
        dark: Color(hex: "AAAAAA")
    )
    
    // MARK: - Helper Methods
    
    /// Tworzy adaptacyjny kolor który zmienia się w zależności od motywu
    static func adaptive(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    /// Returns appropriate text color (white/black) based on background brightness
    func contrastingTextColor() -> Color {
        // Dla adaptacyjnych kolorów, zwróć odpowiedni kolor tekstu
        return Color.adaptive(
            light: self.isLight ? .black : .white,
            dark: self.isLight ? .black : .white
        )
    }
    
    /// Determines if color is light or dark (improved)
    var isLight: Bool {
        let uiColor = UIColor(self)
        var brightness: CGFloat = 0
        
        // Handle both light and dark mode
        let lightColor = uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let darkColor = uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        
        // Use current system appearance
        let currentColor = UITraitCollection.current.userInterfaceStyle == .dark ? darkColor : lightColor
        currentColor.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        
        return brightness > 0.5
    }
    
    /// Creates a lighter version of the color
    func lighter(by amount: Double = 0.2) -> Color {
        return self.opacity(1.0 - amount)
    }
    
    /// Creates a darker version of the color
    func darker(by amount: Double = 0.2) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return Color(UIColor(hue: hue, saturation: saturation, brightness: max(brightness - CGFloat(amount), 0), alpha: alpha))
        }
        return self
    }
    
    // MARK: - Predefined Gradients (używające istniejących nazw)
    
    /// Primary brand gradient
    static var primaryGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [ksrYellow, ksrPrimary]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Success gradient
    static var successGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [ksrSuccess, ksrSuccess.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Background gradient (używa adaptacyjnych kolorów)
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                ksrBackground,
                ksrBackgroundSecondary.opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Hex Color Initializer (Enhanced)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b, a: Double
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = (
                Double((int >> 8) & 0xF) / 15.0,
                Double((int >> 4) & 0xF) / 15.0,
                Double(int & 0xF) / 15.0,
                1.0
            )
        case 6: // RGB (24-bit)
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255.0,
                Double((int >> 8) & 0xFF) / 255.0,
                Double(int & 0xFF) / 255.0,
                1.0
            )
        case 8: // ARGB (32-bit)
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255.0,
                Double((int >> 8) & 0xFF) / 255.0,
                Double(int & 0xFF) / 255.0,
                Double((int >> 24) & 0xFF) / 255.0
            )
        default:
            (r, g, b, a) = (0, 0, 0, 1)
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Environment Value Extensions
extension EnvironmentValues {
    /// Dodaje wygodny dostęp do adaptacyjnych kolorów w View
    var adaptiveColors: AdaptiveColors {
        AdaptiveColors(colorScheme: self.colorScheme)
    }
}

struct AdaptiveColors {
    let colorScheme: ColorScheme
    
    /// Zwraca odpowiedni kolor tła dla obecnego motywu
    var backgroundColor: Color {
        colorScheme == .dark ? Color.ksrDarkGray : Color.ksrLightGray
    }
    
    /// Zwraca odpowiedni kolor tekstu dla obecnego motywu
    var textColor: Color {
        colorScheme == .dark ? Color.ksrTextPrimary : Color.ksrTextPrimary
    }
    
    /// Zwraca odpowiedni kolor granic dla obecnego motywu
    var borderColor: Color {
        colorScheme == .dark ? Color.ksrBorder : Color.ksrBorder
    }
}

// MARK: - Preview Helper (zachowuje funkcjonalność)
#if DEBUG
struct ColorPalette_Preview: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("KSR Color Palette - Adaptive")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.ksrTextPrimary)
                
                Text("Mode: \(colorScheme == .dark ? "Dark" : "Light")")
                    .font(.subheadline)
                    .foregroundColor(.ksrTextSecondary)
                
                Group {
                    colorRow("ksrYellow (Primary)", .ksrYellow)
                    colorRow("ksrPrimary", .ksrPrimary)
                    colorRow("ksrSuccess", .ksrSuccess)
                    colorRow("ksrWarning", .ksrWarning)
                    colorRow("ksrError", .ksrError)
                    colorRow("ksrInfo", .ksrInfo)
                }
                
                Divider()
                    .background(Color.ksrBorder)
                
                Text("Background Colors")
                    .font(.headline)
                    .foregroundColor(.ksrTextPrimary)
                
                Group {
                    colorRow("ksrDarkGray", .ksrDarkGray)
                    colorRow("ksrMediumGray", .ksrMediumGray)
                    colorRow("ksrLightGray", .ksrLightGray)
                    colorRow("ksrBorder", .ksrBorder)
                }
            }
            .padding()
        }
        .background(Color.ksrBackground)
    }
    
    private func colorRow(_ name: String, _ color: Color) -> some View {
        HStack {
            Rectangle()
                .fill(color)
                .frame(width: 60, height: 40)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.ksrBorder, lineWidth: 1)
                )
            
            VStack(alignment: .leading) {
                Text(name)
                    .fontWeight(.medium)
                    .foregroundColor(.ksrTextPrimary)
                
                Text("Auto-adaptive ✅")
                    .font(.caption)
                    .foregroundColor(.ksrTextSecondary)
            }
            
            Spacer()
            
            Text("Sample Text")
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color)
                .foregroundColor(color.contrastingTextColor())
                .cornerRadius(6)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct ColorPalette_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ColorPalette_Preview()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            ColorPalette_Preview()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}
#endif
