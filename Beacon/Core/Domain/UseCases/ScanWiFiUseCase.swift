import Foundation
import Combine

public protocol ScanWiFiUseCaseProtocol {
    var networks: AnyPublisher<[WiFiNetwork], Never> { get }
    var isScanning: AnyPublisher<Bool, Never> { get }

    func requestAuthorization() async -> Bool
    func startScanning()
    func stopScanning()
}

public final class ScanWiFiUseCase: ScanWiFiUseCaseProtocol {
    private let repository: WiFiRepositoryProtocol

    public init(repository: WiFiRepositoryProtocol) {
        self.repository = repository
    }

    public var networks: AnyPublisher<[WiFiNetwork], Never> {
        repository.networks
    }

    public var isScanning: AnyPublisher<Bool, Never> {
        repository.isScanning
    }

    public func requestAuthorization() async -> Bool {
        await repository.requestAuthorization()
    }

    public func startScanning() {
        repository.startScanning()
    }

    public func stopScanning() {
        repository.stopScanning()
    }
}
