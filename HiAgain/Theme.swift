import SwiftUI

/// The only place colors, fonts, spacing, radius, shadow and motion are defined (docs/PLAN.md Part 2).
enum Theme {
    // MARK: Colors
    static let paper = Color(hex: 0xF3F0FA)
    static let card = Color(hex: 0xFFFFFF)
    static let ink = Color(hex: 0x1C1530)
    static let inkSoft = Color(hex: 0x6E6488)
    static let line = Color(hex: 0xE2DCF0)
    static let violet = Color(hex: 0x5A3FF0)
    static let butter = Color(hex: 0xFFEDB0)

    static func badge(_ color: BadgeColor) -> Color {
        switch color {
        case .peach: Color(hex: 0xFFD6C2)
        case .lilac: Color(hex: 0xD9CFFF)
        case .mint: Color(hex: 0xC9F0DE)
        case .butter: Color(hex: 0xFFEDB0)
        case .sky: Color(hex: 0xCDE4FF)
        case .rose: Color(hex: 0xFFD3E2)
        }
    }

    // MARK: Fonts
    /// Bricolage Grotesque 800. Titles and names; pair with `.tracking(Theme.displayTracking)`.
    static func display(_ size: CGFloat) -> Font { .custom("BricolageGrotesque-ExtraBold", size: size) }
    /// Instrument Serif Italic. One accent word per headline, and notes.
    static func accent(_ size: CGFloat) -> Font { .custom("InstrumentSerif-Italic", size: size) }
    /// Geist Mono 500. Places, times, labels; use ALL CAPS with `.tracking(Theme.monoTracking)`.
    static func mono(_ size: CGFloat) -> Font { .custom("GeistMono-Medium", size: size) }
    /// System UI font for buttons and fields.
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight) }

    static let displayTracking: CGFloat = -0.5
    static let monoTracking: CGFloat = 1.5

    // MARK: Spacing, radius
    enum Space {
        static let xs: CGFloat = 4, s: CGFloat = 8, m: CGFloat = 12, l: CGFloat = 16, xl: CGFloat = 24, xxl: CGFloat = 32
    }
    static let radius: CGFloat = 24
    static let buttonHeight: CGFloat = 56

    // MARK: Shadow
    static let shadowColor = ink.opacity(0.12)
    static let shadowY: CGFloat = 8
    static let shadowBlur: CGFloat = 20

    // MARK: Motion
    static let spring = Animation.spring(response: 0.45, dampingFraction: 0.7)
}

extension View {
    func themeShadow() -> some View {
        shadow(color: Theme.shadowColor, radius: Theme.shadowBlur / 2, x: 0, y: Theme.shadowY)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}
