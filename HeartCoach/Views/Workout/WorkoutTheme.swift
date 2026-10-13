import SwiftUI
import UIKit

/// Design tokens + fonts for the "Broadcast + Trace" live-workout redesign (Direction D).
/// Colors/sizes are final; the typeface uses Barlow when registered, else a system
/// condensed fallback so the layout is correct before the Barlow .ttf files are added.
enum WT {

    // MARK: Neutrals
    static let bg          = Color(hex: 0x0A0A0B)
    static let panel       = Color(hex: 0x111214)
    static let panelStroke = Color(hex: 0x1F2023)
    static let surface     = Color(hex: 0x1C1C1E)
    static let divider     = Color(hex: 0x2C2C2E)
    static let textSecondary = Color(hex: 0x8E8E93)
    static let textTertiary  = Color(hex: 0x636366)
    static let textLight     = Color(hex: 0xA1A1A6)
    static let bannerPaper   = Color(hex: 0xF2F2F0)

    // MARK: Brand / status
    static let red       = Color(hex: 0xFF3B30)
    static let redText   = Color(hex: 0xFF453A)
    static let safetyBg  = Color(hex: 0xC4140C)
    static let success   = Color(hex: 0x30D158)
    static let warning   = Color(hex: 0xFFD60A)

    // MARK: Message-type colors
    static let msgSpeedUp  = Color(hex: 0xFF9F0A)
    static let msgSlowDown = Color(hex: 0x4DACF6)
    static let msgGood     = Color(hex: 0x56D57B)
    static let msgPhase    = Color(hex: 0xFF3B30)
    static let msgStretch  = Color(hex: 0xC7C7CC)

    // MARK: Zones (Direction D) — index 0 = below Z1, 1…5 = Z1…Z5
    static func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: return Color(hex: 0x46A6EF)   // Recovery
        case 2: return Color(hex: 0x56D57B)   // Easy
        case 3: return Color(hex: 0xF2D42D)   // Aerobic
        case 4: return Color(hex: 0xFF8B00)   // Threshold
        case 5: return Color(hex: 0xF93534)   // Max
        default: return Color(hex: 0x48484A)  // below Z1
        }
    }
    static func zoneName(_ zone: Int) -> String {
        switch zone {
        case 1: return "RECOVERY"; case 2: return "EASY"; case 3: return "AEROBIC"
        case 4: return "THRESHOLD"; case 5: return "MAX"; default: return "—"
        }
    }
    /// Dimmed block = zone color mixed 32% into surface (#1C1C1E).
    static func zoneDim(_ zone: Int) -> Color {
        zoneColor(zone).mix(with: surface, by: 0.68)   // 32% zone, 68% surface
    }

    // MARK: Fonts
    /// Barlow Condensed (numerals/chips/headings/buttons) with system-condensed fallback.
    static func cond(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        let name = barlowCondName(weight)
        if UIFont(name: name, size: size) != nil { return .custom(name, size: size) }
        return .system(size: size, weight: weight).width(.condensed)
    }
    /// Barlow (labels/body) with system fallback.
    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name = barlowName(weight)
        if UIFont(name: name, size: size) != nil { return .custom(name, size: size) }
        return .system(size: size, weight: weight)
    }

    private static func barlowCondName(_ w: Font.Weight) -> String {
        switch w {
        case .heavy, .black: return "BarlowCondensed-ExtraBold"
        case .bold: return "BarlowCondensed-Bold"
        case .semibold: return "BarlowCondensed-SemiBold"
        default: return "BarlowCondensed-Medium"
        }
    }
    private static func barlowName(_ w: Font.Weight) -> String {
        switch w {
        case .bold, .heavy, .black: return "Barlow-Bold"
        case .semibold: return "Barlow-SemiBold"
        case .medium: return "Barlow-Medium"
        default: return "Barlow-Regular"
        }
    }
}

// MARK: - Helpers

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// Linear blend toward another color (`by` = fraction of `other`).
    func mix(with other: Color, by amount: Double) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let t = CGFloat(amount)
        return Color(.sRGB,
                     red: Double(ar + (br - ar) * t),
                     green: Double(ag + (bg - ag) * t),
                     blue: Double(ab + (bb - ab) * t),
                     opacity: Double(aa + (ba - aa) * t))
    }
}

/// Time formatting used throughout the broadcast UI.
extension Int {
    var msClock: String { String(format: "%d:%02d", self / 60, self % 60) }
}
