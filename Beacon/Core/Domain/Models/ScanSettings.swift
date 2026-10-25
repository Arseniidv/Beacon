import Foundation

/// Настройки сканирования сети. Редактируются администратором в админ-панели
/// и используются экранами сканирования (карта, список устройств).
struct ScanSettings: Codable, Equatable {
    /// Подсеть для сканирования «локального сигнала» в формате `адрес/префикс`.
    var subnet: String
    /// Таймаут ожидания отклика хоста в секундах.
    var pingTimeoutSeconds: Double
    /// Интервал автосканирования в секундах. 0 — автосканирование выключено.
    var autoRefreshIntervalSeconds: Double
    /// Сканирование локальной подсети.
    var isLocalSignalEnabled: Bool
    /// Сканирование WiFi-сетей.
    var isWiFiEnabled: Bool
    /// Сканирование Bluetooth-устройств.
    var isBluetoothEnabled: Bool

    static let defaultSubnet = "192.168.1.0/24"

    static let initial = ScanSettings(
        subnet: defaultSubnet,
        pingTimeoutSeconds: 2,
        autoRefreshIntervalSeconds: 0,
        isLocalSignalEnabled: true,
        isWiFiEnabled: true,
        isBluetoothEnabled: true
    )

    /// Проверяет, что строка является корректной подсетью вида `192.168.1.0/24`.
    static func isValidSubnet(_ subnet: String) -> Bool {
        let parts = subnet.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, let prefixLength = Int(parts[1]) else {
            return false
        }

        guard let address = try? IPAddress(String(parts[0])) else {
            return false
        }

        return (try? NetworkSubnet(address: address, prefixLength: prefixLength)) != nil
    }

    /// Включён ли конкретный источник сканирования.
    func isEnabled(_ source: ScanSource) -> Bool {
        switch source {
        case .localSignal: return isLocalSignalEnabled
        case .wifi: return isWiFiEnabled
        case .bluetooth: return isBluetoothEnabled
        }
    }
}
