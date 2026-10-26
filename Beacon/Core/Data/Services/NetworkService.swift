import Foundation
import Darwin

final class NetworkService: NetworkServiceProtocol {
    private let scanner = LocalNetworkScanner()
    private var devices: [Device] = []
    func fetchDevices() async throws -> [Device] {
        if devices.isEmpty {
            _ = try? await scanNetwork(subnet: ScanSettings.defaultSubnet, timeout: 1)
        }
        return devices
    }

    func fetchDevice(id: UUID) async throws -> Device {
        guard let device = devices.first(where: { $0.id == id }) else {
            throw NSError(
                domain: "NetworkService",
                code: 404,
                userInfo: [ NSLocalizedDescriptionKey: "Устройство не найдено" ]
            )
        }
        return device
    }

    func updateDevice(_device device: Device) async throws {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else {
            throw NSError(
                domain: "NetworkService",
                code: 404,
                userInfo: [ NSLocalizedDescriptionKey: "Устройство не найдено" ]
            )
        }
        devices[index] = device
    }

    func deleteDevice(id: UUID) async throws {
        guard let index = devices.firstIndex(where: { $0.id == id }) else {
            throw NSError(
                domain: "NetworkService",
                code: 404,
                userInfo: [ NSLocalizedDescriptionKey: "Устройство не найдено" ]
            )
        }
        devices.remove(at: index)
    }
    func scanNetwork(subnet: String, timeout: Double) async throws -> [Device] {
        let hosts = await scanner.scan(subnet: subnet, timeout: timeout)
        let respondedIPs = Set(hosts.map(\.ip))

        var updated = hosts.map { host -> Device in
            let existing = devices.first { $0.ip == host.ip }

            return Device(
                id: existing?.id ?? UUID(),
                name: existing?.name ?? "Хост \(host.ip)",
                ip: host.ip,
                macAddress: host.mac.isEmpty
                    ? (existing?.macAddress ?? "")
                    : host.mac,
                coordinate: existing?.coordinate,
                status: existing?.status ?? .free,
                ping: host.pingMilliseconds > 0
                    ? host.pingMilliseconds
                    : nil,
                currentUser: existing?.currentUser,
                cpuUsage: existing?.cpuUsage,
                ramUsage: existing?.ramUsage,
                diskUsage: existing?.diskUsage,
                gpu: existing?.gpu,
                uptime: existing?.uptime,
                os: existing?.os,
                processor: existing?.processor,
                storage: existing?.storage,
                networkAdapter: existing?.networkAdapter,
                openPorts: host.openPorts
            )
        }
    
        for device in devices where !respondedIPs.contains(device.ip) {
            updated.append(
                Device(
                    id: device.id,
                    name: device.name,
                    ip: device.ip,
                    macAddress: device.macAddress,
                    coordinate: device.coordinate,
                    status: device.status,
                    ping: device.ping,
                    currentUser: device.currentUser,
                    cpuUsage: device.cpuUsage,
                    ramUsage: device.ramUsage,
                    diskUsage: device.diskUsage,
                    gpu: device.gpu,
                    uptime: device.uptime,
                    os: device.os,
                    processor: device.processor,
                    storage: device.storage,
                    networkAdapter: device.networkAdapter,
                    openPorts: device.openPorts
                )
            )
        }
        devices = updated
        return devices
    }
    func reserveDevice(_ device: Device) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    func connectToDevice(_ device: Device) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func wakeOnLAN(_ device: Device) async throws {
        guard let mac = Self.macBytes(from: device.macAddress) else {
            throw NSError(
                domain: "NetworkService",
                code: 400,
                userInfo: [ NSLocalizedDescriptionKey: "MAC-адрес устройства неизвестен" ]
            )
        }

        // Магический пакет отправляется и на сам хост, и в широковещательный адрес:
        // усыплённое устройство может не отвечать на ARP, поэтому broadcast надёжнее.
        try Self.sendMagicPacket(mac: mac, to: device.ip)
        try Self.sendMagicPacket(mac: mac, to: "255.255.255.255")
    }
}

// MARK: - Wake-on-LAN

private extension NetworkService {

    /// Разбирает MAC-адрес вида `aa:bb:cc:dd:ee:ff`.
    static func macBytes(from string: String) -> [UInt8]? {
        let parts = string.split(separator: ":")
        guard parts.count == 6 else { return nil }

        var bytes: [UInt8] = []
        for part in parts {
            guard let byte = UInt8(part, radix: 16) else { return nil }
            bytes.append(byte)
        }
        return bytes
    }

    /// Отправляет магический пакет (6 × 0xFF + 16 × MAC) по UDP-порту 9.
    static func sendMagicPacket(mac: [UInt8], to host: String) throws {
        let descriptor = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard descriptor >= 0 else {
            throw NSError(
                domain: "NetworkService",
                code: 500,
                userInfo: [ NSLocalizedDescriptionKey: "Не удалось открыть сокет" ]
            )
        }
        defer { close(descriptor) }

        var broadcast: Int32 = 1
        _ = setsockopt(descriptor, SOL_SOCKET, SO_BROADCAST, &broadcast, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = UInt16(9).bigEndian
        guard inet_pton(AF_INET, host, &address.sin_addr) == 1 else {
            throw NSError(
                domain: "NetworkService",
                code: 400,
                userInfo: [ NSLocalizedDescriptionKey: "Некорректный адрес \(host)" ]
            )
        }

        var packet = [UInt8](repeating: 0xFF, count: 6)
        for _ in 0..<16 {
            packet.append(contentsOf: mac)
        }

        let sent = packet.withUnsafeBytes { buffer -> Int in
            withUnsafePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    sendto(
                        descriptor,
                        buffer.baseAddress,
                        packet.count,
                        0,
                        $0,
                        socklen_t(MemoryLayout<sockaddr_in>.size)
                    )
                }
            }
        }

        guard sent == packet.count else {
            throw NSError(
                domain: "NetworkService",
                code: 500,
                userInfo: [ NSLocalizedDescriptionKey: "Не удалось отправить магический пакет" ]
            )
        }
    }
}
