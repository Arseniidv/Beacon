import SwiftUI


enum IndicatorStatus {
    case normal, warning, error, offline

    var color: Color {
        switch self {
        case .normal:  AppColors.statusSuccess
        case .warning: AppColors.statusWarning
        case .error:   AppColors.statusDanger
        case .offline: AppColors.statusOffline
        }
    }
}

struct StatusIndicator: View {
    let status: IndicatorStatus
    let title: String

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Circle().fill(status.color).frame(width: 8, height: 8)
            Text(title).font(AppTypography.body)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(alignment: .leading) {
        StatusIndicator(status: .normal, title: "Мониторинг активен")
        StatusIndicator(status: .error, title: "Helper недоступен")
    }
    .padding()
    .appTheme()
}
