import SwiftUI
import Combine




@available(iOS 17.0, *)
@MainActor
final class AppCoordinator: ObservableObject {
    @Published var tabCoordinator = TabCoordinator()
    private  let session: AuthSessionStore


    init(session: AuthSessionStore? = nil) {
        self.session = session ?? DIContainer.shared.authSession
    }

    @ViewBuilder
    func root() -> some View {
        RootView(session: session, tabCoordinator: tabCoordinator)
    }
}

@available(iOS 17.0, *)
struct RootView: View {
    @ObservedObject var session: AuthSessionStore
    @ObservedObject var tabCoordinator: TabCoordinator


    var body: some View {
        Group {
            if session.isAuthenticated {
                TabCoordinatorView(coordinator: tabCoordinator)
            } else {
                AuthView(viewModel: DIContainer.shared.makeAuthViewModel())
            }
        }
        .onChange(of: session.isAuthenticated) { isAuthenticated in
            if !isAuthenticated {
                tabCoordinator.selectedTab = .overview
            }
        }

    }
}

@available(iOS 17.0, *)
struct TabCoordinatorView: View {
    @ObservedObject var coordinator: TabCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                NavigationStack {
                    coordinator.tabView(for: tab)
                }
                .tabItem {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
        .tint(AppColors.accentPrimary)
        .background(AppColors.backgroundApp)
    }
}
