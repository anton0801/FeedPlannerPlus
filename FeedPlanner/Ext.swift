import Foundation
import SwiftUI

extension Color {
    static let bgLight = Color(hex: "FFF6D5")
    static let card = Color(hex: "FFE8A8")
    static let panel = Color(hex: "FFF1C2")
    static let yellowBtn = Color(hex: "FFB800")
    static let orangeBtn = Color(hex: "FF7A00")
    static let highlight = Color(hex: "FFE58F")
    static let gold = Color(hex: "FFCF57")
    static let error = Color(hex: "FF2E00")
    static let warning = Color(hex: "FF7A00")
    static let good = Color(hex: "3FDA52")
    static let textPrimary = Color(hex: "3A2400")
    static let textSecondary = Color(hex: "6B4A12")
    static let icon = Color(hex: "FFC400")
    
    static let bg         = Color(hex: "FFF6D5")
    static let shine      = Color(hex: "FFE58F")
    static let textMain   = Color(hex: "3A2400")
    static let textSec    = Color(hex: "6B4A12")
}

//extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: // RGB (12-bit)
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6: // RGB (24-bit)
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8: // ARGB (32-bit)
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (1, 1, 1, 0)
//        }
//        self.init(
//            .sRGB,
//            red: Double(r) / 255,
//            green: Double(g) / 255,
//            blue: Double(b) / 255,
//            opacity: Double(a) / 255
//        )
//    }
//}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}


extension Double {
    func formate(digits: Int) -> String {
        return String(format: "%.\(digits)f", self)
    }
}
