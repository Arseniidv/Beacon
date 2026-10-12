import CoreGraphics

/// Сетка 4 pt. Любой отступ в проекте — один из этих токенов.
enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs:  CGFloat = 8
    static let sm:  CGFloat = 12
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48

    /// Внутренний отступ карточки.
    static let cardPadding: CGFloat = md
    /// Расстояние между карточками на dashboard.
    static let cardGap: CGFloat = md
    /// Отступ содержимого окна от краёв.
    static let screenPadding: CGFloat = lg
}

/// Фиксированные размеры элементов каркаса.
enum AppLayout {
    static let sidebarWidth: CGFloat = 208
    static let detailPanelWidth: CGFloat = 320
    static let topBarHeight: CGFloat = 56
    static let tableRowHeight: CGFloat = 36
    static let minWindowSize = CGSize(width: 1100, height: 700)
}
