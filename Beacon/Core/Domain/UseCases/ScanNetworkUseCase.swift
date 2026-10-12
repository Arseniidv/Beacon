import Foundation

protocol ScanNetworkUseCaseProtocol {
    func execute(subnet: String) async throws -> [Device]
}

final class ScanNetworkUseCase: ScanNetworkUseCaseProtocol {
    private let repository: DeviceRepositoryProtocol

    nonisolated init(repository: DeviceRepositoryProtocol) {
        self.repository = repository
    }

    func execute(subnet: String) async throws -> [Device] {
        return try await repository.scanNetwork(subnet: subnet)
    }
}
