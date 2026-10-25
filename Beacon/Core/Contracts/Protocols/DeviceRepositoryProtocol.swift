import Foundation

protocol DeviceRepositoryProtocol {
    func fetchDevices() async throws -> [Device]
    func fetchDevice(id: UUID) async throws -> Device
    func scanNetwork(subnet: String, timeout: Double) async throws -> [Device]
    func updateDevice(_device:Device) async throws
    func deleteDevice(_device:Device) async throws
    func reserveDevice(_ device: Device) async throws
    func connectToDevice(_ device: Device) async throws
}
