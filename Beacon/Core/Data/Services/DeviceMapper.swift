
import Foundation

enum DeviceMapper {

    static func map(_ host: LocalNetworkScanner.Host) -> Device {
        Device(
            name: host.ip,
            ip: host.ip,
            macAddress: host.mac,
            status: .free,
            ping: host.pingMilliseconds > 0
                ? host.pingMilliseconds
                : nil,
            openPorts: host.openPorts
        )
    }

    static func map(_ hosts: [LocalNetworkScanner.Host]) -> [Device] {
        hosts.map { map($0) }
    }
}
