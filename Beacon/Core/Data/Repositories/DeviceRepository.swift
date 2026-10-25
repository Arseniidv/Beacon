import Foundation

final class DeviceRepository: DeviceRepositoryProtocol {
    func deleteDevice(_device device: Device) async throws {
        try await networkService.deleteDevice(id: device.id)
    }
    private let networkService: NetworkServiceProtocol
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    func fetchDevices() async throws -> [Device] {
        return try await networkService.fetchDevices()
    }
    func fetchDevice(id: UUID) async throws -> Device {
        return try await networkService.fetchDevice(id: id)
    }
    func scanNetwork(subnet: String, timeout: Double) async throws -> [Device] {
        return try await networkService.scanNetwork(subnet: subnet, timeout: timeout)
    }
    func updateDevice(_device device: Device) async throws {
        try await networkService.updateDevice(_device: device)
    }
    func reserveDevice(_ device: Device) async throws {
        try await networkService.reserveDevice(device)
    }
    func connectToDevice(_ device: Device) async throws {
        try await networkService.connectToDevice(device)
    }
}
