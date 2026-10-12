import Foundation

final class FetchDevicesUseCase: FetchDevicesUseCaseProtocol {
    private let repository: DeviceRepositoryProtocol

    nonisolated init(repository: DeviceRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [Device] {
        return try await repository.fetchDevices()
    }
}
