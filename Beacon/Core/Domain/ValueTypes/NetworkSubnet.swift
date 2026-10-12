
import Foundation

struct NetworkSubnet: Hashable, Codable, Sendable {
    let address: IPAddress
    let prefixLength: Int

    init(address: IPAddress, prefixLength: Int) throws {
        let maximumPrefixLength = address.value.contains(":") ? 128 : 32

        guard (0...maximumPrefixLength).contains(prefixLength) else {
            throw NetworkSubnetError.invalidPrefixLength(
                prefixLength,
                maximum: maximumPrefixLength
            )
        }

        self.address = address
        self.prefixLength = prefixLength
    }
}

enum NetworkSubnetError: Error, Equatable, Sendable {
    case invalidPrefixLength(Int, maximum: Int)
}
