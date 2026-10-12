import SwiftUI

/// Точка входа в тему. Приложение тёмное по ТЗ, поэтому схема фиксируется.
struct AppThemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.backgroundApp)
            .foregroundStyle(AppColors.textPrimary)
            .font(AppTypography.body)
            .preferredColorScheme(.dark)
    }
}

extension View {
    /// Применяется один раз на корневом View в `LANTrafficMonitorApp`.
    func appTheme() -> some View { modifier(AppThemeModifier()) }
}
