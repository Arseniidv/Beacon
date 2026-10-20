import Foundation

protocol NetworkServiceProtocol {
    func fetchDevices() async throws -> [Device]
    func scanNetwork(subnet: String) async throws -> [Device]
    func reserveDevice(_ device: Device) async throws
    func connectToDevice(_ device: Device) async throws
    func wakeOnLAN(_ device: Device) async throws
}
