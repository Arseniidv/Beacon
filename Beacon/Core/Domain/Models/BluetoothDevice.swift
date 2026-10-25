import Foundation
import CoreLocation
import CoreBluetooth
import SwiftUI
import Combine

// MARK: - ГЕОГРАФИЧЕСКИЕ КООРДИНАТЫ
public struct Coordinate: Codable, Hashable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - BLUETOOTH УСТРОЙСТВО
public struct BluetoothDevice: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let identifier: String
    public let rssi: Int
    public let coordinate: Coordinate
    public let distance: Double
    public let connectionStatus: ConnectionStatus
    public let services: [String]
    public let lastSeen: Date

    public init(
        id: UUID = UUID(),
        name: String,
        identifier: String,
        rssi: Int,
        coordinate: Coordinate,
        distance: Double,
        connectionStatus: ConnectionStatus,
        services: [String] = [],
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.identifier = identifier
        self.rssi = rssi
        self.coordinate = coordinate
        self.distance = distance
        self.connectionStatus = connectionStatus
        self.services = services
        self.lastSeen = lastSeen
    }

    public enum ConnectionStatus: String, Codable {
        case connected
        case disconnected
        case connecting
        case unknown
    }

    // Определение текстовой мощности сигнала на основе числового RSSI
    public var signalStrength: SignalStrength {
        switch rssi {
        case -50...0: return .excellent
        case -60..<(-50): return .good
        case -70..<(-60): return .fair
        case -90..<(-70): return .weak
        default: return .poor
        }
    }

    public enum SignalStrength: String, Codable {
        case excellent
        case good
        case fair
        case weak
        case poor

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .yellow
            case .weak: return .orange
            case .poor: return .red
            }
        }

        var iconName: String {
            switch self {
            case .excellent: return "wifi"
            case .good: return "wifi"
            case .fair: return "wifi"
            case .weak: return "wifi.exclamationmark"
            case .poor: return "wifi.slash"
            }
        }
    }

    public var formattedDistance: String {
        if distance < 1 {
            return String(format: "%.0f cm", distance * 100)
        } else {
            return String(format: "%.1f m", distance)
        }
    }

    public var formattedRSSI: String {
        return "\(rssi) dBm"
    }
}
