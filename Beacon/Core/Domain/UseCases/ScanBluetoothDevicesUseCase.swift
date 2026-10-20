import Foundation
import Combine

protocol ScanBluetoothDevicesUseCaseProtocol {
    var devices: AnyPublisher<[BluetoothDevice], Never> { get }
    var isScanning: AnyPublisher<Bool, Never> { get }

    func requestAuthorization() async -> Bool
    func startScanning()
    func stopScanning()
}

final class ScanBluetoothDevicesUseCase: ScanBluetoothDevicesUseCaseProtocol {
    private let repository: BluetoothRepositoryProtocol

    init(repository: BluetoothRepositoryProtocol) {
        self.repository = repository
    }

    var devices: AnyPublisher<[BluetoothDevice], Never> {
        repository.devices
    }

    var isScanning: AnyPublisher<Bool, Never> {
        repository.isScanning
    }

    func requestAuthorization() async -> Bool {
        return await repository.requestAuthorization()
    }

    func startScanning() {
        repository.startScanning()
    }

    func stopScanning() {
        repository.stopScanning()
    }
}
