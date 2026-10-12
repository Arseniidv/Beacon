import SwiftUI
import Combine

enum AppTab: String, CaseIterable {
    case overview = "Обзор"
    case devices = "Устройства"
    case map = "Карта"
    case profile = "Профиль"

    var icon: String {
        switch self {
        case .overview: return "chart.bar"
        case .devices: return "desktopcomputer"
        case .map: return "map"
        case .profile: return "person.circle"
        }
    }
}

@MainActor
final class TabCoordinator: ObservableObject {
    @Published var selectedTab: AppTab = .overview
    @Published var navigationPath = NavigationPath()

    func navigateToDeviceDetail(device: Device) {
        navigationPath.append(device)
    }

    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    @ViewBuilder
    func tabView(for tab: AppTab) -> some View {
        switch tab {
        case .overview:
            DashboardView()
        case .devices:
            DevicesView()
        case .map:
            mapPlaceholder
        case .profile:
            profilePlaceholder
        }
    }

    private var mapPlaceholder: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textTertiary)
            Text("Карта сети")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("Функционал в разработке")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundApp)
    }

    private var profilePlaceholder: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "person.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textTertiary)
            Text("Профиль")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("Функционал в разработке")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundApp)
    }
}
