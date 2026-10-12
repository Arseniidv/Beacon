
import Foundation

struct ProtocolStatistics: Identifiable, Codable, Sendable {
    let id: NetworkProtocolType
    let bytes: UInt64
    let packets: UInt64

    init(
        protocolType: NetworkProtocolType,
        bytes: UInt64,
        packets: UInt64
    ) {
        self.id = protocolType
        self.bytes = bytes
        self.packets = packets
    }

    var protocolType: NetworkProtocolType {
        id
    }
}

