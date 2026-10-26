import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif


// MARK: - 1. Расширение для поддержки динамических HEX
extension Color {
    /// Создает динамический SwiftUI Color на основе светлого и темного HEX-значений
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        #if canImport(UIKit)
        let uiColor = UIColor { traitCollection in
            let lightColor = UIColor(
                red:   CGFloat((light >> 16) & 0xFF) / 255.0,
                green: CGFloat((light >> 8) & 0xFF) / 255.0,
                blue:  CGFloat(light & 0xFF) / 255.0,
                alpha: 1.0
            )
            let darkColor = UIColor(
                red:   CGFloat((dark >> 16) & 0xFF) / 255.0,
                green: CGFloat((dark >> 8) & 0xFF) / 255.0,
                blue:  CGFloat(dark & 0xFF) / 255.0,
                alpha: 1.0
            )
            return traitCollection.userInterfaceStyle == .dark ? darkColor : lightColor
        }
        return Color(uiColor)
        #elseif canImport(AppKit)
        return Color(
            red:   CGFloat((light >> 16) & 0xFF) / 255.0,
            green: CGFloat((light >> 8) & 0xFF) / 255.0,
            blue:  CGFloat(light & 0xFF) / 255.0
        )
        #else
        return Color(
            red:   CGFloat((light >> 16) & 0xFF) / 255.0,
            green: CGFloat((light >> 8) & 0xFF) / 255.0,
            blue:  CGFloat(light & 0xFF) / 255.0
        )
        #endif
    }
}

// MARK: - 2. Адаптивная палитра приложения (Чистые статические свойства)
enum AppColors {
    // MARK: Фоны
    static let backgroundApp      = Color.dynamic(light: 0xF4F6FA, dark: 0x0A1020)
    static let backgroundSidebar  = Color.dynamic(light: 0xECEFF5, dark: 0x0D1528)
    static let backgroundCard     = Color.dynamic(light: 0xFFFFFF, dark: 0x111B30)
    static let backgroundElevated = Color.dynamic(light: 0xF1F3F7, dark: 0x16233D)
    static let backgroundSelected = Color.dynamic(light: 0xDEEBFF, dark: 0x123A73)

    // MARK: Границы
    static let borderSubtle       = Color.dynamic(light: 0xE2E8F0, dark: 0x1E2B47)
    static let borderStrong       = Color.dynamic(light: 0xCBD5E1, dark: 0x2B3B5E)

    // MARK: Текст
    static let textPrimary        = Color.dynamic(light: 0x0F172A, dark: 0xF1F5FB)
    static let textSecondary      = Color.dynamic(light: 0x475569, dark: 0x9AA8C2)
    static let textTertiary       = Color.dynamic(light: 0x94A3B8, dark: 0x66758F)
    static let textOnAccent        = Color.white

    // MARK: Акценты
    static let accentPrimary      = Color.dynamic(light: 0x0066FF, dark: 0x1F7AFF)
    static let accentCyan         = Color.dynamic(light: 0x06B6D4, dark: 0x22D3EE)
    static let accentTeal         = Color.dynamic(light: 0x0D9488, dark: 0x14B8A6)
    static let accentPurple       = Color.dynamic(light: 0x7C3AED, dark: 0x8B5CF6)

    // MARK: Статусы
    static let statusSuccess      = Color.dynamic(light: 0x16A34A, dark: 0x22C55E)
    static let statusWarning      = Color.dynamic(light: 0xD97706, dark: 0xF59E0B)
    static let statusDanger       = Color.dynamic(light: 0xDC2626, dark: 0xEF4444)
    static let statusOffline      = Color.dynamic(light: 0x64748B, dark: 0x7C8AA5)
    static let accentOrange = Color(red:1.0,green: 0.58, blue: 0.8)
}
