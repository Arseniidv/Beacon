import Foundation

/// Источник, по которому приложение ищет устройства.
enum ScanSource: String, CaseIterable, Identifiable {
    case localSignal = "Локальный сигнал"
    case wifi = "WiFi"
    case bluetooth = "Bluetooth"

    var id: Self { self }

    var icon: String {
        switch self {
        case .localSignal: return "desktopcomputer"
        case .wifi: return "wifi"
        case .bluetooth: return "antenna.radiowaves.left.and.right"
        }
    }
}
