import SwiftUI

extension Color {
    // Backgrounds
    static let backgroundPrimary = Color(hex: "FFF6D5")
    static let backgroundSecondary = Color(hex: "FFE8A8")
    static let backgroundPanel = Color(hex: "FFF1C2")
    
    // Buttons and Accents
    static let accentPrimary = Color(hex: "FFB800")
    static let accentSecondary = Color(hex: "FF7A00")
    static let highlight = Color(hex: "FFE58F")
    static let golden = Color(hex: "FFCF57")
    
    // Status Colors
    static let error = Color(hex: "FF2E00")
    static let warning = Color(hex: "FF7A00")
    static let success = Color(hex: "3FDA52")
    
    // Text
    static let textPrimary = Color(hex: "3A2400")
    static let textSecondary = Color(hex: "6B4A12")
    
    // Chart Colors
    static let chartLine = Color(hex: "FF7A00")
    static let chartPoint = Color(hex: "FFB800")
    static let chartSector1 = Color(hex: "FFCF57")
    static let chartSector2 = Color(hex: "FFB800")
    static let chartSector3 = Color(hex: "FFD479")
    
    // Elements
    static let iconColor = Color(hex: "FFC400")
    static let borderBrown = Color(hex: "7A4E1D")
    static let shadow = Color(hex: "E1C48A")
    
    // Helper initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Gradient definitions
extension LinearGradient {
    static let primaryButton = LinearGradient(
        colors: [Color.accentPrimary, Color.golden],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let secondaryButton = LinearGradient(
        colors: [Color.accentSecondary, Color(hex: "FF5500")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGradient = LinearGradient(
        colors: [Color.backgroundSecondary, Color(hex: "FFD98F")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glossOverlay = LinearGradient(
        colors: [Color.white.opacity(0.4), Color.clear],
        startPoint: .top,
        endPoint: .center
    )
}
