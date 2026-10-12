import SwiftUI

@main
struct BeaconApp: App {
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            appCoordinator.root()
                .frame(minWidth: AppLayout.minWindowSize.width, minHeight: AppLayout.minWindowSize.height)
        }
        .windowStyle(.hiddenTitleBar)
        #else
        WindowGroup {
            appCoordinator.root()
        }
        #endif
    }
}
