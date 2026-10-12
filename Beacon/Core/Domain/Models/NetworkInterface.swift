import Foundation

struct NetworkInterface:Identifiable,Hashable,Codable,Sendable{
    let id:String
    let name:String
    let displayName:String
    let macAddress:String?
    let ipAddresses:[IPAddress]
    let isUp:Bool
    let isLoopback:Bool

    init(
        id: String,
        name: String,
        displayName: String,
        macAddress: String?,
        ipAddresses: [IPAddress],
        isUp: Bool,
        isLoopback: Bool
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.macAddress = macAddress
        self.ipAddresses = ipAddresses
        self.isUp = isUp
        self.isLoopback = isLoopback
    }
}
