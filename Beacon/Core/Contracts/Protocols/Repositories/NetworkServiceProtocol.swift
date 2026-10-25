import Foundation

protocol NetworkServiceProtocol {
    func fetchDevices() async throws -> [Device]
    func updateDevice(_device:Device) async throws
    func fetchDevice(id:UUID) async throws -> Device
    func scanNetwork(subnet: String, timeout: Double) async throws -> [Device]
    func deleteDevice(id:UUID) async throws
    func reserveDevice(_ device: Device) async throws
    func connectToDevice(_ device: Device) async throws
    func wakeOnLAN(_ device: Device) async throws
}

