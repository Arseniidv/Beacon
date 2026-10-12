import SwiftUI

// MARK: - 1. Расширение для поддержки HEX
extension Color {
    /// Инициализатор для создания цвета из HEX-числа: `Color(hex: 0x1F7AFF)`
    init(hex: UInt32, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - 2. Переключатель тем (ThemeSwitcher)
struct ThemeSwitcher {
    let light: UInt32
    let dark: UInt32

    /// Возвращает адаптивный Color в зависимости от текущей системной темы
    func getColor(for scheme: ColorScheme) -> Color {
        Color(hex: scheme == .dark ? dark : light)
    }
}

// MARK: - 3. Адаптивная палитра приложения
enum AppColors {
    // Вспомогательный метод, чтобы не дублировать вызовы во вью
    private static func dynamicColor(light: UInt32, dark: UInt32) -> Color {
        // Мы используем UIKit под капотом, чтобы цвета менялись автоматически
        // без принудительной передачи `@Environment(\.colorScheme)` в каждое свойство
        Color(uiColor: UIColor { traitCollection in
            let hex = traitCollection.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red:   CGFloat((hex >> 16) & 0xFF) / 255.0,
                green: CGFloat((hex >> 8) & 0xFF) / 255.0,
                blue:  CGFloat(hex & 0xFF) / 255.0,
                alpha: 1.0
            )
        })
    }

    // MARK: Фоны
    static let backgroundApp      = dynamicColor(light: 0xF4F6FA, dark: 0x0A1020) // окно приложения
    static let backgroundSidebar  = dynamicColor(light: 0xECEFF5, dark: 0x0D1528) // боковая панель
    static let backgroundCard     = dynamicColor(light: 0xFFFFFF, dark: 0x111B30) // карточки
    static let backgroundElevated = dynamicColor(light: 0xF1F3F7, dark: 0x16233D) // поля ввода, выпадающие списки
    static let backgroundSelected = dynamicColor(light: 0xDEEBFF, dark: 0x123A73) // выбранная строка таблицы

    // MARK: Границы и разделители
    static let borderSubtle = dynamicColor(light: 0xE2E8F0, dark: 0x1E2B47)
    static let borderStrong = dynamicColor(light: 0xCBD5E1, dark: 0x2B3B5E)

    // MARK: Текст
    static let textPrimary   = dynamicColor(light: 0x0F172A, dark: 0xF1F5FB)
    static let textSecondary = dynamicColor(light: 0x475569, dark: 0x9AA8C2)
    static let textTertiary  = dynamicColor(light: 0x94A3B8, dark: 0x66758F)
    static let textOnAccent  = Color.white

    // MARK: Акценты
    static let accentPrimary = dynamicColor(light: 0x0066FF, dark: 0x1F7AFF) // главные кнопки, активный пункт меню
    static let accentCyan    = dynamicColor(light: 0x06B6D4, dark: 0x22D3EE) // входящий трафик, сетевая активность
    static let accentTeal    = dynamicColor(light: 0x0D9488, dark: 0x14B8A6) // исходящий трафик
    static let accentPurple  = dynamicColor(light: 0x7C3AED, dark: 0x8B5CF6) // RAM, вторичные метрики

    // MARK: Статусы
    static let statusSuccess = dynamicColor(light: 0x16A34A, dark: 0x22C55E) // норма / свободен / онлайн
    static let statusWarning = dynamicColor(light: 0xD97706, dark: 0xF59E0B) // предупреждение
    static let statusDanger  = dynamicColor(light: 0xDC2626, dark: 0xEF4444) // ошибка / занят
    static let statusOffline = dynamicColor(light: 0x64748B, dark: 0x7C8AA5) // оффлайн / нет данных

    // MARK: Графики
    static let chartIncoming = accentCyan
    static let chartOutgoing = accentTeal
    static let chartGrid     = borderSubtle

    /// Палитра диаграммы протоколов (порядок = порядок сегментов).
    static let chartProtocolPalette: [Color] = [
        accentPrimary, accentCyan, accentPurple, statusWarning, statusSuccess, statusOffline
    ]
}
