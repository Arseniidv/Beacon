import Foundation

enum NetworkProtocolType: String, Codable, CaseIterable, Sendable {
    case tcp
    case udp
    case icmp
    case dns
    case http
    case https
    case other
}
