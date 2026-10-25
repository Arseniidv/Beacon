import Foundation

protocol ScanNetworkUseCaseProtocol {
    func execute(subnet: String, timeout: Double) async throws -> [Device]
}

final class ScanNetworkUseCase: ScanNetworkUseCaseProtocol {
    private let repository: DeviceRepositoryProtocol

    init(repository: DeviceRepositoryProtocol) {
        self.repository = repository
    }

    func execute(subnet: String, timeout: Double) async throws -> [Device] {
        return try await repository.scanNetwork(subnet: subnet, timeout: timeout)
    }
}
