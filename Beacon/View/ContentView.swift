import SwiftUI

@available(iOS 17.0, *)
struct ContentView: View {
    @StateObject private var coordinator = TabCoordinator()
    var body: some View {
        #if os(macOS)
        macContentView
        #else
        iosContentView
        #endif
    }
    
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
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
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

#Preview {
    func makeView() -> AnyView {
        guard #available(iOS 17.0, *) else {
            return AnyView(Text("Требуется IOS 17 или новее"))
        }
        let mainView = Text("Экран для iOS 17+")
        return AnyView(mainView)
    }

    return makeView()
}
