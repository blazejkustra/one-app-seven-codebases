import SwiftUI

/// Light/dark design tokens as dynamic UIColors (resolved by the active trait collection).
enum Palette {
    static let bg = UIColor(light: 0xF5F5F7, dark: 0x000000)
    static let surface = UIColor(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let text = UIColor(light: 0x1C1C1E, dark: 0xF5F5F7)
    static let textSecondary = UIColor(light: 0x6E6E73, dark: 0xA1A1A6)
    static let textTertiary = UIColor(light: 0x8E8E93, dark: 0x8E8E93)
    static let fill = UIColor(light: 0xE9E9EE, dark: 0x2C2C2E)
    static let separator = UIColor(light: 0xE5E5EA, dark: 0x38383A)
    static let accent = UIColor(light: 0x5B4FE9, dark: 0x7D74FF)
    static let accentSoft = UIColor(light: 0xECEBFF, dark: 0x2A2650)
    static let star = UIColor(light: 0xF5A623, dark: 0xFFB340)
    static let danger = UIColor(light: 0xE5484D, dark: 0xFF6369)
    static let codeBg = UIColor(light: 0x1C1C1E, dark: 0x2C2C2E)
    static let codeText = UIColor(light: 0xF5F5F7, dark: 0xF5F5F7)
    static let toastBg = UIColor(light: 0x1C1C1E, dark: 0x3A3A3C)
    static let toastAction = UIColor(light: 0xA79FFF, dark: 0xA79FFF)
}

enum Theme {
    static let bg = Color(uiColor: Palette.bg)
    static let surface = Color(uiColor: Palette.surface)
    static let text = Color(uiColor: Palette.text)
    static let textSecondary = Color(uiColor: Palette.textSecondary)
    static let textTertiary = Color(uiColor: Palette.textTertiary)
    static let fill = Color(uiColor: Palette.fill)
    static let separator = Color(uiColor: Palette.separator)
    static let accent = Color(uiColor: Palette.accent)
    static let accentSoft = Color(uiColor: Palette.accentSoft)
    static let star = Color(uiColor: Palette.star)
    static let danger = Color(uiColor: Palette.danger)
    static let codeBg = Color(uiColor: Palette.codeBg)
    static let codeText = Color(uiColor: Palette.codeText)
    static let toastBg = Color(uiColor: Palette.toastBg)
    static let toastAction = Color(uiColor: Palette.toastAction)

    static let mono = "Menlo"
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension UIColor {
    convenience init(light: UInt32, dark: UInt32) {
        self.init { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}

extension View {
    /// Emulates a CSS line-height: extra leading between lines plus half-leading above and below.
    func lineHeight(_ lineHeight: CGFloat, fontSize: CGFloat, font: UIFont? = nil) -> some View {
        let f = font ?? UIFont.systemFont(ofSize: fontSize)
        let extra = max(0, lineHeight - f.lineHeight)
        return self.lineSpacing(extra).padding(.vertical, extra / 2)
    }
}
