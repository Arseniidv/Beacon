import Foundation
import SwiftUI

public struct Device: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let ip: String
    public let macAddress: String
    public let status: DeviceStatus
    public let ping: Int?
    public let currentUser: String?
    public let cpuUsage: Double?
    public let ramUsage: Double?
    public let diskUsage: Double?
    public let gpu: String?
    public let uptime: Int?
    public let os: String?
    public let processor: String?
    public let storage: String?
    public let networkAdapter: String?

    public init(
        id: UUID = UUID(),
        name: String,
        ip: String,
        macAddress: String,
        status: DeviceStatus,
        ping: Int? = nil,
        currentUser: String? = nil,
        cpuUsage: Double? = nil,
        ramUsage: Double? = nil,
        diskUsage: Double? = nil,
        gpu: String? = nil,
        uptime: Int? = nil,
        os: String? = nil,
        processor: String? = nil,
        storage: String? = nil,
        networkAdapter: String? = nil
    ) {
        self.id = id
        self.name = name
        self.ip = ip
        self.macAddress = macAddress
        self.status = status
        self.ping = ping
        self.currentUser = currentUser
        self.cpuUsage = cpuUsage
        self.ramUsage = ramUsage
        self.diskUsage = diskUsage
        self.gpu = gpu
        self.uptime = uptime
        self.os = os
        self.processor = processor
        self.storage = storage
        self.networkAdapter = networkAdapter
    }

    public var formattedPing: String {
        guard let ping = ping else {
            return "—"
        }
        return "\(ping) ms"
    }

    public var formattedUptime: String {
        guard let uptime = uptime else {
            return "—"
        }

        let hours = uptime / 3600
        let minutes = (uptime % 3600) / 60

        if hours > 24 {
            let days = hours / 24
            return "\(days)д \(hours % 24)ч"
        }

        return "\(hours)ч \(minutes)м"
    }
}

