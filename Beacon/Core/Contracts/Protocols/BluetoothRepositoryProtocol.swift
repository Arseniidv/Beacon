import Foundation
import Combine

protocol BluetoothRepositoryProtocol {
    var devices: AnyPublisher<[BluetoothDevice], Never> { get }
    var isScanning: AnyPublisher<Bool, Never> { get }

    func requestAuthorization() async -> Bool
    func startScanning()
    func stopScanning()
    func connect(to device: BluetoothDevice) async throws
    func disconnect(from device: BluetoothDevice) async throws
}
