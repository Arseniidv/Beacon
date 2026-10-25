import SwiftUI
import Combine

enum AppTab: String, CaseIterable {
    case overview = "Обзор"
    case devices = "Устройства"
    case map = "Карта"
    case admin = "Админ"
    case profile = "Профиль"

    var icon: String {
        switch self {
        case .overview: return "chart.bar"
        case .devices: return "desktopcomputer"
        case .map: return "map"
        case .admin: return "gearshape.2"
        case .profile: return "person.circle"
        }
    }

    var requiresAdmin: Bool {
        switch self {
        case .admin:
            return true
        default:
            return false
        }
    }
}

@available(iOS 17.0, *)
@MainActor
final class TabCoordinator: ObservableObject {
    @Published var selectedTab: AppTab = .overview
    @Published var navigationPath = NavigationPath()
    @Published var isAdmin: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        apply(session: DIContainer.shared.authSession.currentUser)

        DIContainer.shared.authSession.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.apply(session: user)
            }
            .store(in: &cancellables)
    }

    /// Доступ в админ-панель определяется ролью текущего пользователя.
    /// Роль может измениться во время работы (вход/выход, смена роли админом).
    private func apply(session user: UserAccount?) {
        isAdmin = user?.isAdmin ?? false

        if !isAdmin && selectedTab == .admin {
            selectedTab = .overview
        }
    }

    var availableTabs: [AppTab] {
        AppTab.allCases.filter { tab in
            if tab.requiresAdmin {
                return isAdmin
            }
            return true
        }
    }

    func navigateToDeviceDetail(device: Device) {
        navigationPath.append(device)
    }

    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    @ViewBuilder
    func tabView(for tab:AppTab) ->some View{
        switch tab{
        case .overview: DashboardView()
        case .devices:DevicesView()

        case .map:
            NetworkMapView(
                viewModel: DIContainer.shared.makeNetworkMapViewModel()
            )
        case .admin:
            if isAdmin {
                AdminPanelView()
            } else {
                Text("Доступ запрещен")
                    .foregroundStyle(AppColors.textSecondary)
            }
        case .profile:
            ProfileView()
        }
        }
    }
