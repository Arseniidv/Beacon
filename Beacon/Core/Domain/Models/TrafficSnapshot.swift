
import Foundation

struct TrafficSnapshot: Identifiable, Codable, Sendable {
    let id: UUID
    let timestamp: Date
    let interfaceID: String

    let inboundBytesPerSecond: UInt64
    let outboundBytesPerSecond: UInt64

    let totalInboundBytes: UInt64
    let totalOutboundBytes: UInt64

    let protocolStatistics: [ProtocolStatistics]

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        interfaceID: String,
        inboundBytesPerSecond: UInt64,
        outboundBytesPerSecond: UInt64,
        totalInboundBytes: UInt64,
        totalOutboundBytes: UInt64,
        protocolStatistics: [ProtocolStatistics] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.interfaceID = interfaceID
        self.inboundBytesPerSecond = inboundBytesPerSecond
        self.outboundBytesPerSecond = outboundBytesPerSecond
        self.totalInboundBytes = totalInboundBytes
        self.totalOutboundBytes = totalOutboundBytes
        self.protocolStatistics = protocolStatistics
    }
}
