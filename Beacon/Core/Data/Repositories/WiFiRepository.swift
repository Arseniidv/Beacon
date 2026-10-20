import Foundation
import Combine

final class WiFiRepository: WiFiRepositoryProtocol {
    private let service: WiFiServiceProtocol

    init(service: WiFiServiceProtocol) {
        self.service = service
    }

    var networks: AnyPublisher<[WiFiNetwork], Never> {
        service.networks
    }

    var isScanning: AnyPublisher<Bool, Never> {
        service.isScanning
    }

    func requestAuthorization() async -> Bool {
        await service.requestAuthorization()
    }

    func startScanning() {
        service.startScanning()
    }

    func stopScanning() {
        service.stopScanning()
    }
}
