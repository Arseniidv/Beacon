
import Foundation
import Darwin

struct IPAddress: Hashable, Codable, Sendable, CustomStringConvertible {
    let value: String

    init(_ value: String) throws {
        let normalizedValue = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard Self.isValid(normalizedValue) else {
            throw IPAddressError.invalidAddress(value)
        }

        self.value = normalizedValue
    }

    var description: String {
        value
    }

    private static func isValid(_ value: String) -> Bool {
        var ipv4Address = in_addr()
        var ipv6Address = in6_addr()

        let ipv4Result = value.withCString {
            inet_pton(AF_INET, $0, &ipv4Address)
        }

        if ipv4Result == 1 {
            return true
        }

        let ipv6Result = value.withCString {
            inet_pton(AF_INET6, $0, &ipv6Address)
        }

        return ipv6Result == 1
    }
}

enum IPAddressError: Error, Equatable, Sendable {
    case invalidAddress(String)
}
