
import Foundation

// MARK: - Generic Filter Protocol

public protocol DeviceFilterProtocol {
    associatedtype DeviceType

    func matches(_ device: DeviceType) -> Bool
}

// MARK: - Bluetooth Filters

public enum BluetoothFilter: DeviceFilterProtocol {
    case all
    case byName(String)
    case byManufacturer(String)
    case bySignalStrength(ClosedRange<Int>)
    case byConnectionStatus(BluetoothDevice.ConnectionStatus)
    case custom((BluetoothDevice) -> Bool)

    public func matches(_ device: BluetoothDevice) -> Bool {
        switch self {
        case .all:
            return true

        case .byName(let name):
            return device.name.localizedCaseInsensitiveContains(name)

        case .byManufacturer(let manufacturer):
            return device.name.localizedCaseInsensitiveContains(manufacturer)

        case .bySignalStrength(let range):
            return range.contains(device.rssi)

        case .byConnectionStatus(let status):
            return device.connectionStatus == status

        case .custom(let predicate):
            return predicate(device)
        }
    }
}

// MARK: - Wi-Fi Filters

public enum WiFiFilter: DeviceFilterProtocol {
    case all
    case bySSID(String)
    case bySecurityType(WiFiNetwork.SecurityType)
    case byFrequency(Double)
    case bySignalStrength(ClosedRange<Int>)
    case custom((WiFiNetwork) -> Bool)

    public func matches(_ device: WiFiNetwork) -> Bool {
        switch self {
        case .all:
            return true

        case .bySSID(let ssid):
            return device.ssid.localizedCaseInsensitiveContains(ssid)

        case .bySecurityType(let security):
            return device.securityType == security

        case .byFrequency(let frequency):
            return abs(device.frequency - frequency) < 0.1

        case .bySignalStrength(let range):
            return range.contains(device.signalStrength)

        case .custom(let predicate):
            return predicate(device)
        }
    }
}

// MARK: - Filter Combiner

public enum FilterCombiner {
    public static func and<T>(
        _ filters: [(T) -> Bool]
    ) -> (T) -> Bool {
        { device in
            filters.allSatisfy { filter in
                filter(device)
            }
        }
    }

    public static func or<T>(
        _ filters: [(T) -> Bool]
    ) -> (T) -> Bool {
        { device in
            filters.contains { filter in
                filter(device)
            }
        }
    }
}

// MARK: - Filter Presets

public enum FilterPresets {
    public static let bluetoothStrongSignal: BluetoothFilter =
        .bySignalStrength(-60...0)

    public static let bluetoothConnected: BluetoothFilter =
        .byConnectionStatus(.connected)

    public static let bluetoothAppleDevices: BluetoothFilter =
        .byManufacturer("Apple")

    public static let wifiOpenNetworks: WiFiFilter =
        .bySecurityType(.none)

    public static let wifi5GHz: WiFiFilter =
        .byFrequency(5.0)

    public static let wifi2_4GHz: WiFiFilter =
        .byFrequency(2.4)

    public static let wifiStrongSignal: WiFiFilter =
        .bySignalStrength(-60...0)
}
