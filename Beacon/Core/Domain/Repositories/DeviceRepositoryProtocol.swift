import Foundation

protocol DeviceRepositoryProtocol {
    func fetchDevices() async throws -> [Device]
    func fetchDevice(id: UUID) async throws -> Device
    func scanNetwork(subnet: String) async throws -> [Device]
    func reserveDevice(_ device: Device) async throws
    func connectToDevice(_ device: Device) async throws
}
