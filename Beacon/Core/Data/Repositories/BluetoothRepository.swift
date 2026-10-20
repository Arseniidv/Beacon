import Foundation
import Combine

final class BluetoothRepository: BluetoothRepositoryProtocol {
    private let bluetoothService: BluetoothServiceProtocol

    init(bluetoothService: BluetoothServiceProtocol) {
        self.bluetoothService = bluetoothService
    }

    var devices: AnyPublisher<[BluetoothDevice], Never> {
        bluetoothService.devices
    }

    var isScanning: AnyPublisher<Bool, Never> {
        bluetoothService.isScanning
    }

    func requestAuthorization() async -> Bool {
        return await bluetoothService.requestAuthorization()
    }

    func startScanning() {
        bluetoothService.startScanning()
    }

    func stopScanning() {
        bluetoothService.stopScanning()
    }

    func connect(to device: BluetoothDevice) async throws {
        try await bluetoothService.connect(to: device)
    }

    func disconnect(from device: BluetoothDevice) async throws {
        try await bluetoothService.disconnect(from: device)
    }
}
