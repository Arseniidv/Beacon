import Foundation
import CoreLocation
import SwiftUI
import Combine

public struct WiFiNetwork: Identifiable, Codable, Hashable {
    public let id: UUID
    public let ssid: String
    public let bssid: String
    public let signalStrength: Int // RSSI in dBm
    public let channel: Int
    public let frequency: Double // in GHz (2.4 or 5)
    public let securityType: SecurityType
    public let coordinate: Coordinate
    public let distance: Double
    public let lastSeen: Date

    public init(
        id: UUID = UUID(),
        ssid: String,
        bssid: String,
        signalStrength: Int,
        channel: Int,
        frequency: Double,
        securityType: SecurityType,
        coordinate: Coordinate,
        distance: Double,
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.ssid = ssid
        self.bssid = bssid
        self.signalStrength = signalStrength
        self.channel = channel
        self.frequency = frequency
        self.securityType = securityType
        self.coordinate = coordinate
        self.distance = distance
        self.lastSeen = lastSeen
    }

    public enum SecurityType: String, Codable {
        case none
        case wep
        case wpa
        case wpa2
        case wpa3
        case wpa2Enterprise
        case wpa3Enterprise
        case unknown

        var displayName: String {
            switch self {
            case .none: return "Open"
            case .wep: return "WEP"
            case .wpa: return "WPA"
            case .wpa2: return "WPA2"
            case .wpa3: return "WPA3"
            case .wpa2Enterprise: return "WPA2 Enterprise"
            case .wpa3Enterprise: return "WPA3 Enterprise"
            case .unknown: return "Unknown"
            }
        }

        var iconName: String {
            switch self {
            case .none: return "lock.open"
            case .wep, .wpa, .wpa2, .wpa3, .wpa2Enterprise, .wpa3Enterprise: return "lock.fill"
            case .unknown: return "lock.slash"
            }
        }
    }

    public var signalQuality: SignalQuality {
        switch signalStrength {
        case -50...0: return .excellent
        case -60..<(-50): return .good
        case -70..<(-60): return .fair
        case -80..<(-70): return .weak
        default: return .poor
        }
    }

    public enum SignalQuality: String, Codable {
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

        var percentage: Int {
            switch self {
            case .excellent: return 100
            case .good: return 80
            case .fair: return 60
            case .weak: return 40
            case .poor: return 20
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
        return "\(signalStrength) dBm"
    }

    public var frequencyBand: String {
        return frequency < 3 ? "2.4 GHz" : "5 GHz"
    }
}
