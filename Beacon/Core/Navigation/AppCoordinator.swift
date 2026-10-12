import SwiftUI
import Combine

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var tabCoordinator = TabCoordinator()

    func root() -> some View {
        TabCoordinatorView(coordinator: tabCoordinator)
    }
}

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
    }
}
