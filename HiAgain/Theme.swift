import SwiftUI

/// The only place colors, fonts, spacing, radius, shadow and motion are defined (docs/design/DESIGN-v3.md).
enum Theme {
    // MARK: Colors
    static let paper = Color(hex: 0xF2F2EE)     // every screen background
    static let surface = Color(hex: 0xFFFFFF)   // grouped rows, inputs, the note card
    static let ink = Color(hex: 0x141414)       // text, primary buttons
    static let muted = Color(hex: 0x66665F)     // secondary text
    static let faint = Color(hex: 0x9A9A92)     // placeholders, chevrons
    static let rule = Color(hex: 0xDDDDD6)      // borders, section rules
    static let ruleSoft = Color(hex: 0xECECE6)  // dividers inside a group
    static let stamp = Color(hex: 0xD23B24)     // stamps, scan button, scan screen, wordmark period. Nothing else
    static let danger = Color(hex: 0xB8301C)    // Unlink, Remove
    static let unknown = Color(hex: 0xF2C230)   // "Not on the app yet" screen
    static let noteLine = Color(hex: 0xC7D4EC)  // blue rules on the note card

    static func badge(_ color: BadgeColor) -> Color {
        switch color {
        case .red: Color(hex: 0xD23B24)
        case .blue: Color(hex: 0x2556C4)
        case .green: Color(hex: 0x1D7A4F)
        case .yellow: Color(hex: 0xF2C230)
        case .pink: Color(hex: 0xC83C78)
        case .black: Color(hex: 0x1E1E1E)
        }
    }

    /// Text color on a badge's color band ("HELLO", the Me initial).
    static func onBadge(_ color: BadgeColor) -> Color { color == .yellow ? ink : .white }

    // MARK: Fonts
    /// Screen titles and headlines: Archivo ExtraBold, width 87.5. 30 to 38 pt, tracking -0.3.
    static func title(_ size: CGFloat = 34) -> Font { .custom("Archivo-ExtraBoldSemiCondensed", size: size) }
    /// The `hi again.` wordmark: Archivo Black, width 112.
    static func wordmark(_ size: CGFloat = 22) -> Font { .custom("Archivo-BlackSemiExpanded", size: size) }
    /// "HELLO" on stickers: Archivo Black, width 125, tracking +2.
    static func hello(_ size: CGFloat) -> Font { .custom("Archivo-BlackExpanded", size: size) }
    /// "my name is" on stickers: Archivo SemiBold.
    static func nameIs(_ size: CGFloat) -> Font { .custom("Archivo-SemiBold", size: size) }
    /// Names on stickers and the Me initial only: Caveat Brush.
    static func marker(_ size: CGFloat) -> Font { .custom("CaveatBrush-Regular", size: size) }
    /// Stamp text, always caps: Archivo Bold, width 75.
    static func stampText(_ size: CGFloat) -> Font { .custom("Archivo-BoldCondensed", size: size) }
    /// Everything else (UI, body, buttons, notes): system SF Pro, 13 to 17 pt.
    static func ui(_ size: CGFloat = 17, weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight) }

    static let titleTracking: CGFloat = -0.3

    // MARK: Spacing, radius, sizes
    enum Space {
        static let xs: CGFloat = 4, s: CGFloat = 8, m: CGFloat = 12, l: CGFloat = 16, xl: CGFloat = 24, xxl: CGFloat = 32
    }
    static let groupRadius: CGFloat = 12    // grouped rows
    static let rowHeight: CGFloat = 50
    static let buttonRadius: CGFloat = 14
    static let buttonHeight: CGFloat = 54
    static let scanButtonSize: CGFloat = 92

    // MARK: Motion
    static let drop = Animation.spring(response: 0.45, dampingFraction: 0.75)  // the sticker drop
    static let thunk = Animation.easeOut(duration: 0.12)                       // stamp 1.15 → 1.0
}

extension View {
    /// Sticker and scan-button shadow: 0 1 2 ink 18% plus 0 8 18 ink 8%.
    func stickerShadow() -> some View {
        shadow(color: Theme.ink.opacity(0.18), radius: 1, x: 0, y: 1)
            .shadow(color: Theme.ink.opacity(0.08), radius: 9, x: 0, y: 8)
    }

    /// Grouped iOS-style box: white, 1 pt rule border, radius 12.
    func groupBox() -> some View {
        background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.groupRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.groupRadius).strokeBorder(Theme.rule, lineWidth: 1))
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
