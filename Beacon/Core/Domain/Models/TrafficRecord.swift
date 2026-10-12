
import Foundation

struct TrafficRecord: Identifiable, Codable, Sendable {
    let id: UUID
    let timestamp: Date
    let interfaceID: String

    let inboundBytesPerSecond: UInt64
    let outboundBytesPerSecond: UInt64

    let totalInboundBytes: UInt64
    let totalOutboundBytes: UInt64

    init(
        id: UUID = UUID(),
        timestamp: Date,
        interfaceID: String,
        inboundBytesPerSecond: UInt64,
        outboundBytesPerSecond: UInt64,
        totalInboundBytes: UInt64,
        totalOutboundBytes: UInt64
    ) {
        self.id = id
        self.timestamp = timestamp
        self.interfaceID = interfaceID
        self.inboundBytesPerSecond = inboundBytesPerSecond
        self.outboundBytesPerSecond = outboundBytesPerSecond
        self.totalInboundBytes = totalInboundBytes
        self.totalOutboundBytes = totalOutboundBytes
    }

    init(snapshot: TrafficSnapshot) {
        self.init(
            id: snapshot.id,
            timestamp: snapshot.timestamp,
            interfaceID: snapshot.interfaceID,
            inboundBytesPerSecond: snapshot.inboundBytesPerSecond,
            outboundBytesPerSecond: snapshot.outboundBytesPerSecond,
            totalInboundBytes: snapshot.totalInboundBytes,
            totalOutboundBytes: snapshot.totalOutboundBytes
        )
    }
}
