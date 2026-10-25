
import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
struct ContentView: View {

    @StateObject private var coordinator = TabCoordinator()

    var body: some View {
        #if os(macOS)
        macContentView
        #else
        iosContentView
        #endif
    }

    // MARK: - iOS

    @ViewBuilder
    private var iosContentView: some View {
        TabView(selection: $coordinator.selectedTab) {
            ForEach(coordinator.availableTabs, id: \.self) { tab in
                NavigationStack {
                    coordinator.tabView(for: tab)
                        .navigationDestination(for: Device.self) { device in
                            DeviceDetailView(device: device)
                        }
                }
                .tabItem {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
        .tint(AppColors.accentPrimary)
    }

    #if os(macOS)
@ViewBuilder
    private var macContentView: some View {
        NavigationSplitView {
            List(selection: $coordinator.selectedTab) {
                ForEach(coordinator.availableTabs, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(
                min: 180,
                ideal: 200,
                max: 250
            )
        } detail: {
            NavigationStack {
                coordinator.tabView(for: coordinator.selectedTab)
                    .navigationDestination(for: Device.self) { device in
                        DeviceDetailView(device: device)
                    }
            }
        }
        .tint(AppColors.accentPrimary)
    }

    #endif
}

// MARK: - Preview

#Preview {
    if #available(iOS 17.0, *) {
        ContentView()
    } else {
            Text("Для корректной работы необходима минимум IOS 17")
    }
}
