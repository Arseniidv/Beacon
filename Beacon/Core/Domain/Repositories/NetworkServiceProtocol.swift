import Foundation

protocol NetworkServiceProtocol {
    func fetchDevices() async throws -> [Device]
    func scanNetwork(subnet: String) async throws -> [Device]
    func reserveDevice(_ device: Device) async throws
    func connectToDevice(_ device: Device) async throws
    func wakeOnLAN(_ device: Device) async throws
}

final class NetworkService: NetworkServiceProtocol {
    func fetchDevices() async throws -> [Device] {
        return mockDevices
    }
    
    func scanNetwork(subnet: String) async throws -> [Device] {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return mockDevices
    }
    
    func reserveDevice(_ device: Device) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func connectToDevice(_ device: Device) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func wakeOnLAN(_ device: Device) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    private var mockDevices: [Device] {
        [
            Device(
                id: UUID(),
                name: "PC-01-ADMIN",
                ip: "192.168.1.10",
                macAddress: "00:18:44:11:3A:B7",
                status: .free,
                ping: 1,
                currentUser: nil,
                cpuUsage: 15.0,
                ramUsage: 32.0,
                diskUsage: 45.0,
                gpu: "NVIDIA RTX 3060",
                uptime: 7200,
                os: "Windows 11 Pro",
                processor: "Intel Core i7-12700K",
                storage: "512 GB SSD",
                networkAdapter: "Intel I219-V"
            ),
            Device(
                id: UUID(),
                name: "PC-02-DESIGN",
                ip: "192.168.1.11",
                macAddress: "00:18:44:22:4C:C8",
                status: .busy,
                ping: 2,
                currentUser: "ivan.petrov",
                cpuUsage: 67.0,
                ramUsage: 78.0,
                diskUsage: 62.0,
                gpu: "NVIDIA RTX 4070",
                uptime: 14400,
                os: "Windows 11 Pro",
                processor: "AMD Ryzen 9 5900X",
                storage: "1 TB NVMe",
                networkAdapter: "Realtek 8125"
            ),
            Device(
                id: UUID(),
                name: "PC-03-RENDER",
                ip: "192.168.1.12",
                macAddress: "00:18:44:33:5D:D9",
                status: .free,
                ping: 1,
                currentUser: nil,
                cpuUsage: 23.0,
                ramUsage: 45.0,
                diskUsage: 55.0,
                gpu: "NVIDIA RTX 4090",
                uptime: 28800,
                os: "Windows 10 Pro",
                processor: "Intel Core i9-13900K",
                storage: "2 TB NVMe",
                networkAdapter: "Intel I225-V"
            ),
            Device(
                id: UUID(),
                name: "PC-04-TEST",
                ip: "192.168.1.13",
                macAddress: "00:18:44:44:6E:EA",
                status: .offline,
                ping: nil,
                currentUser: nil,
                cpuUsage: nil,
                ramUsage: nil,
                diskUsage: nil,
                gpu: nil,
                uptime: nil,
                os: nil,
                processor: nil,
                storage: nil,
                networkAdapter: nil
            )
        ]
    }
}
