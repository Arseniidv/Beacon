import SwiftUI

/// Шрифтовые токены. Системный шрифт + Dynamic Type там, где это уместно на macOS.
enum AppTypography {
    static let screenTitle  = Font.system(size: 20, weight: .semibold)
    static let sectionTitle = Font.system(size: 15, weight: .semibold)
    static let body         = Font.system(size: 13, weight: .regular)
    static let bodyStrong   = Font.system(size: 13, weight: .semibold)
    static let caption      = Font.system(size: 11, weight: .regular)

    /// Крупные числа метрик. Моноширинные цифры, чтобы значения не «прыгали».
    static let metricLarge  = Font.system(size: 28, weight: .bold).monospacedDigit()
    static let metricMedium = Font.system(size: 20, weight: .semibold).monospacedDigit()
    static let tableNumber  = Font.system(size: 12, weight: .regular).monospacedDigit()
}
