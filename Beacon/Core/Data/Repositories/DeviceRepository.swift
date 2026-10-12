import Foundation

final class DeviceRepository: DeviceRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func fetchDevices() async throws -> [Device] {
        return try await networkService.fetchDevices()
    }

    func fetchDevice(id: UUID) async throws -> Device {
        let devices = try await fetchDevices()
        guard let device = devices.first(where: { $0.id == id }) else {
            throw NSError(domain: "DeviceRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Device not found"])
        }
        return device
    }

    func scanNetwork(subnet: String) async throws -> [Device] {
        return try await networkService.scanNetwork(subnet: subnet)
    }

    func reserveDevice(_ device: Device) async throws {
        try await networkService.reserveDevice(device)
    }

    func connectToDevice(_ device: Device) async throws {
        try await networkService.connectToDevice(device)
    }
}
