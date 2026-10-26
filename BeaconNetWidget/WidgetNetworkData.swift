import Foundation

struct WidgetNetworkData: Codable, Sendable {
    let isMonitoring: Bool
    let networkName: String
    let gatewayIP: String?
    let onlineDevices: Int
    let totalDevices: Int
    let lastScanDate: Date?

    static let empty = WidgetNetworkData(
        isMonitoring: false,
        networkName: "Сеть не настроена",
        gatewayIP: nil,
        onlineDevices: 0,
        totalDevices: 0,
        lastScanDate: nil
    )
}

enum WidgetDataStore {
    // Заменить на реальный App Group ID из Signing & Capabilities.
    private static let appGroupID = "group.com.example.NetPulse"
    private static let storageKey = "widget.network.data"

    static func save(_ data: WidgetNetworkData) {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let encoded = try? JSONEncoder().encode(data)
        else {
            return
        }

        defaults.set(encoded, forKey: storageKey)
    }

    static func load() -> WidgetNetworkData {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let encoded = defaults.data(forKey: storageKey),
            let data = try? JSONDecoder().decode(
                WidgetNetworkData.self,
                from: encoded
            )
        else {
            return .empty
        }

        return data
    }
}
