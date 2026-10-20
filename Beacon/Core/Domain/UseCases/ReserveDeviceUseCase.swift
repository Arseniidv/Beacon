import Foundation

protocol ReserveDeviceUseCaseProtocol {
    func execute(_ device: Device) async throws
}

final class ReserveDeviceUseCase: ReserveDeviceUseCaseProtocol {
    private let repository: DeviceRepositoryProtocol

    init(repository: DeviceRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ device: Device) async throws {
        try await repository.reserveDevice(device)
    }
}
