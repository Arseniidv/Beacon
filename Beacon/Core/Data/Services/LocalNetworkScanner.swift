import Foundation
import Darwin

/// Сканер локальной сети.
///
/// Адрес и маска активного IPv4-интерфейса берутся через `getifaddrs`.
/// Каждый хост подсети проверяется ICMP-эхо (`SOCK_DGRAM` + `IPPROTO_ICMP`,
/// работает без прав root) и TCP-пробами по типовым портам.
final class LocalNetworkScanner: Sendable {

    /// Порты, которые проверяются TCP-пробой при сканировании хоста.
    static let probePorts: [UInt16] = [22, 80, 139, 443, 445, 3389, 8080]

    /// Максимум хостов, проверяемых одновременно.
    private let maxConcurrentHosts = 48
    /// Ограничение на размер подсети в одном сканировании.
    private let maxHostsPerScan = 512

    /// Результат проверки одного хоста.
    struct Host: Sendable {
        let ip: String
        /// MAC-адрес из ARP-таблицы ядра. Пустая строка, если запись ещё не создана.
        let mac: String
        let pingMilliseconds: Int
        let openPorts: [Int]
    }

    /// Сканирует подсеть.
    /// - Parameters:
    ///   - subnet: подсеть вида `192.168.1.0/24`. Если она невалидна или не
    ///     содержит адрес текущего интерфейса, используется автоматически
    ///     определённая подсеть.
    ///   - timeout: таймаут ответа хоста в секундах.
    func scan(subnet: String?, timeout: TimeInterval) async -> [Host] {
        let targets = resolveTargets(subnet: subnet)
        guard !targets.isEmpty else { return [] }

        let pingTimeout = max(0.2, min(timeout, 2.0))
        let portTimeout = max(0.1, min(timeout, 1.0) * 0.4)
        let ports = Self.probePorts

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let group = DispatchGroup()
                let semaphore = DispatchSemaphore(value: self.maxConcurrentHosts)
                let lock = NSLock()
                var hosts: [Host] = []

                for target in targets {
                    semaphore.wait()
                    group.enter()

                    DispatchQueue.global(qos: .userInitiated).async {
                        defer {
                            semaphore.signal()
                            group.leave()
                        }

                        let ping = self.icmpPing(host: target, timeout: pingTimeout)
                        var openPorts: [Int] = []
                        for port in ports where self.tcpProbe(host: target, port: port, timeout: portTimeout) {
                            openPorts.append(Int(port))
                        }

                        // Хост считается найденным, если ответил на ping или открыл порт.
                        guard ping != nil || !openPorts.isEmpty else { return }

                        let host = Host(
                            ip: target,
                            mac: "",
                            pingMilliseconds: ping ?? 0,
                            openPorts: openPorts
                        )

                        lock.lock()
                        hosts.append(host)
                        lock.unlock()
                    }
                }

                group.notify(queue: .global(qos: .userInitiated)) {
                    // ARP-таблица читается после проб: записи создаются ядром
                    // в момент первого обращения к хосту.
                    let arp = Self.arpTable()
                    let result = hosts
                        .map { Host(
                            ip: $0.ip,
                            mac: arp[$0.ip] ?? "",
                            pingMilliseconds: $0.pingMilliseconds,
                            openPorts: $0.openPorts
                        ) }
                        .sorted { Self.sortKey($0.ip) < Self.sortKey($1.ip) }

                    continuation.resume(returning: result)
                }
            }
        }
    }

    // MARK: - Определение цели сканирования

    private func resolveTargets(subnet: String?) -> [String] {
        guard let local = Self.localIPv4Interface() else { return [] }

        if let subnet,
           let range = Self.range(fromSubnet: subnet),
           range.contains(Self.ipToUInt32(local.ip) ?? 0) {
            return range.hostAddresses(limit: maxHostsPerScan)
        }

        // Подсеть не задана или не совпадает с текущей сетью — считаем по маске интерфейса.
        guard let address = Self.ipToUInt32(local.ip),
              let mask = Self.ipToUInt32(local.netmask) else {
            return []
        }

        return Self.IPv4Range(network: address & mask, broadcast: (address & mask) | ~mask)
            .hostAddresses(limit: maxHostsPerScan)
    }

    /// Адрес и маска активного IPv4-интерфейса (`getifaddrs`).
    private static func localIPv4Interface() -> (ip: String, netmask: String)? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let first = interfaces else { return nil }
        defer { freeifaddrs(interfaces) }

        var candidates: [(name: String, ip: String, netmask: String)] = []
        var pointer: UnsafeMutablePointer<ifaddrs>? = first

        while let interface = pointer {
            defer { pointer = interface.pointee.ifa_next }

            let flags = Int32(interface.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isRunning = (flags & IFF_RUNNING) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0

            guard isUp, isRunning, !isLoopback,
                  let address = interface.pointee.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_INET),
                  let netmask = interface.pointee.ifa_netmask else {
                continue
            }

            let name = String(cString: interface.pointee.ifa_name)
            let ip = Self.ipString(from: address)
            let mask = Self.ipString(from: netmask)

            guard !ip.isEmpty, !mask.isEmpty else { continue }
            candidates.append((name: name, ip: ip, netmask: mask))
        }

        // Предпочитаем Wi-Fi/Ethernet-интерфейс.
        return candidates.first(where: { $0.name.hasPrefix("en") })
            .map { (ip: $0.ip, netmask: $0.netmask) }
            ?? candidates.first.map { (ip: $0.ip, netmask: $0.netmask) }
    }

    private static func ipString(from address: UnsafeRawPointer) -> String {
        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let sockaddrPointer = address.assumingMemoryBound(to: sockaddr.self)
        let length = socklen_t(sockaddrPointer.pointee.sa_len)

        guard getnameinfo(sockaddrPointer, length, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 else {
            return ""
        }
        return String(cString: host)
    }

    // MARK: - ARP-таблица

    /// Сопоставление IPv4 → MAC из ARP-таблицы ядра (`sysctl`, `NET_RT_FLAGS`).
    private static func arpTable() -> [String: String] {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, rtfLLInfo]
        var size = 0

        guard sysctl(&mib, UInt32(mib.count), nil, &size, nil, 0) == 0, size > 0 else { return [:] }

        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, UInt32(mib.count), &buffer, &size, nil, 0) == 0 else { return [:] }

        var table: [String: String] = [:]
        buffer.withUnsafeBytes { raw in
            var offset = 0

            while offset + MemoryLayout<RoutingMessageHeader>.size <= size {
                let header = raw.loadUnaligned(fromByteOffset: offset, as: RoutingMessageHeader.self)
                let messageLength = Int(header.rtm_msglen)

                guard messageLength > 0, offset + messageLength <= size else { break }

                if let entry = Self.arpEntry(in: raw, at: offset, length: messageLength) {
                    table[entry.ip] = entry.mac
                }
                offset += messageLength
            }
        }
        return table
    }

    /// Разбирает одно сообщение ARP-таблицы: адрес назначения и аппаратный адрес.
    private static func arpEntry(
        in raw: UnsafeRawBufferPointer,
        at offset: Int,
        length: Int
    ) -> (ip: String, mac: String)? {
        guard let base = raw.baseAddress else { return nil }

        // После rt_msghdr идут sockaddr-структуры: RTA_DST, RTA_GATEWAY, RTA_NETMASK.
        var cursor = offset + MemoryLayout<RoutingMessageHeader>.size
        let end = offset + length
        var addresses: [UnsafeRawPointer] = []

        while cursor + MemoryLayout<sockaddr>.size <= end, addresses.count < 3 {
            let pointer = base.advanced(by: cursor)
            let addressLength = Int(pointer.assumingMemoryBound(to: sockaddr.self).pointee.sa_len)
            guard addressLength > 0 else { break }

            addresses.append(pointer)
            cursor += addressLength
        }

        guard addresses.count >= 2 else { return nil }

        let destination = addresses[0].assumingMemoryBound(to: sockaddr.self).pointee
        guard destination.sa_family == UInt8(AF_INET) else { return nil }

        let ip = ipString(from: addresses[0])
        guard !ip.isEmpty else { return nil }

        let link = addresses[1].assumingMemoryBound(to: sockaddr_dl.self).pointee
        guard link.sdl_family == UInt8(AF_LINK), Int(link.sdl_alen) == 6 else { return nil }

        // lladdr лежит сразу после имени интерфейса: offsetof(sockaddr_dl, sdl_data) == 8.
        let lladdr = addresses[1].advanced(by: 8 + Int(link.sdl_nlen))
        let bytes = (0..<6).map { lladdr.load(fromByteOffset: $0, as: UInt8.self) }

        return (ip, bytes.map { String(format: "%02x", $0) }.joined(separator: ":"))
    }

    // MARK: - ICMP

    /// Отправляет ICMP-эхо и возвращает время отклика в миллисекундах.
    private func icmpPing(host: String, timeout: TimeInterval) -> Int? {
        let descriptor = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)
        guard descriptor >= 0 else { return nil }
        defer { close(descriptor) }

        var receiveTimeout = timeval(
            tv_sec: Int(timeout),
            tv_usec: Int32((timeout - Double(Int(timeout))) * 1_000_000)
        )
        _ = withUnsafePointer(to: &receiveTimeout) {
            setsockopt(descriptor, SOL_SOCKET, SO_RCVTIMEO, $0, socklen_t(MemoryLayout<timeval>.size))
        }

        var destination = sockaddr_in()
        destination.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        destination.sin_family = sa_family_t(AF_INET)
        destination.sin_port = 0
        guard inet_pton(AF_INET, host, &destination.sin_addr) == 1 else { return nil }

        // Тело ICMP echo request: type=8, code=0, checksum, id, seq, payload.
        let identifier = UInt16(truncatingIfNeeded: Int(arc4random()))
        let sequence: UInt16 = 1
        var packet = [UInt8](repeating: 0, count: 16)
        packet[0] = 8
        packet[4] = UInt8(identifier >> 8)
        packet[5] = UInt8(identifier & 0xFF)
        packet[6] = UInt8(sequence >> 8)
        packet[7] = UInt8(sequence & 0xFF)

        let checksum = Self.icmpChecksum(packet)
        packet[2] = UInt8(checksum >> 8)
        packet[3] = UInt8(checksum & 0xFF)

        let started = DispatchTime.now()
        let sent = packet.withUnsafeBytes { buffer -> Int in
            withUnsafePointer(to: &destination) { pointer in
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
        guard sent > 0 else { return nil }

        var reply = [UInt8](repeating: 0, count: 64)
        let received = recv(descriptor, &reply, reply.count, 0)
        // type = 0 — echo reply.
        guard received > 0, reply[0] == 0 else { return nil }

        let elapsed = DispatchTime.now().uptimeNanoseconds &- started.uptimeNanoseconds
        return max(1, Int(elapsed / 1_000_000))
    }

    private static func icmpChecksum(_ data: [UInt8]) -> UInt16 {
        var sum: UInt32 = 0
        var index = 0

        while index + 1 < data.count {
            sum += UInt32(data[index]) << 8 | UInt32(data[index + 1])
            index += 2
        }
        if index < data.count {
            sum += UInt32(data[index]) << 8
        }

        while sum >> 16 != 0 {
            sum = (sum & 0xFFFF) + (sum >> 16)
        }
        return UInt16(~sum & 0xFFFF)
    }

    // MARK: - TCP-пробы

    /// Пробует установить TCP-соединение с портом, не блокируя поток надолго.
    private func tcpProbe(host: String, port: UInt16, timeout: TimeInterval) -> Bool {
        let descriptor = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
        guard descriptor >= 0 else { return false }
        defer { close(descriptor) }

        let flags = fcntl(descriptor, F_GETFL, 0)
        _ = fcntl(descriptor, F_SETFL, flags | O_NONBLOCK)

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        guard inet_pton(AF_INET, host, &address.sin_addr) == 1 else { return false }

        let connectResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        if connectResult == 0 { return true }
        guard errno == EINPROGRESS else { return false }

        var pollDescriptor = pollfd(fd: descriptor, events: Int16(POLLOUT), revents: 0)
        guard poll(&pollDescriptor, 1, Int32(timeout * 1000)) > 0 else { return false }

        var socketError: Int32 = 0
        var length = socklen_t(MemoryLayout<Int32>.size)
        guard getsockopt(descriptor, SOL_SOCKET, SO_ERROR, &socketError, &length) == 0 else {
            return false
        }
        return socketError == 0
    }

    // MARK: - Работа с адресами

    private static func ipToUInt32(_ value: String) -> UInt32? {
        var address = in_addr()
        guard inet_pton(AF_INET, value, &address) == 1 else { return nil }
        return UInt32(bigEndian: address.s_addr)
    }

    private static func range(fromSubnet subnet: String) -> IPv4Range? {
        let parts = subnet.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2,
              let prefix = Int(parts[1]),
              (1...32).contains(prefix),
              let base = ipToUInt32(String(parts[0])) else {
            return nil
        }

        let mask: UInt32 = prefix == 32 ? 0xFFFF_FFFF : ~UInt32(0) << (32 - prefix)
        let network = base & mask
        return IPv4Range(network: network, broadcast: network | ~mask)
    }

    private static func sortKey(_ ip: String) -> UInt32 {
        ipToUInt32(ip) ?? 0
    }

    private struct IPv4Range {
        let network: UInt32
        let broadcast: UInt32

        func contains(_ address: UInt32) -> Bool {
            address >= network && address <= broadcast
        }

        func hostAddresses(limit: Int) -> [String] {
            guard broadcast > network + 1 else { return [] }

            var addresses: [String] = []
            var current = network + 1
            while current < broadcast, addresses.count < limit {
                addresses.append(Self.string(from: current))
                current += 1
            }
            return addresses
        }

        static func string(from value: UInt32) -> String {
            var address = in_addr(s_addr: value.bigEndian)
            var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            inet_ntop(AF_INET, &address, &buffer, socklen_t(INET_ADDRSTRLEN))
            return String(cString: buffer)
        }
    }
}

// MARK: - Таблица маршрутизации

/// `RTF_LLINFO` из `<net/route.h>`: запись, созданная канальным уровнем (ARP).
private let rtfLLInfo: Int32 = 0x400

/// `struct rt_msghdr` из `<net/route.h>`.
///
/// Тип не импортируется в Swift, поэтому раскладка повторена полями один в один:
/// 36 байт заголовка + 56 байт `rt_metrics`, итого 92 байта.
private struct RoutingMessageHeader {
    var rtm_msglen: UInt16
    var rtm_version: UInt8
    var rtm_type: UInt8
    var rtm_index: UInt16
    var rtm_flags: Int32
    var rtm_addrs: Int32
    var rtm_pid: Int32
    var rtm_seq: Int32
    var rtm_errno: Int32
    var rtm_use: Int32
    var rtm_inits: UInt32
    /// Содержимое `rt_metrics` не используется, важна только длина.
    var rtm_rmx: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32)
}
