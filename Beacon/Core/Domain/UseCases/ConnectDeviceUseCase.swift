import Foundation

protocol ConnectDeviceUseCaseProtocol {
    func execute(_ device: Device) async throws
}

final class ConnectDeviceUseCase: ConnectDeviceUseCaseProtocol {
    private let repository: DeviceRepositoryProtocol

    init(repository: DeviceRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ device: Device) async throws {
        try await repository.connectToDevice(device)
    }
}
