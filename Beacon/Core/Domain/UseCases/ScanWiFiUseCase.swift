import Foundation
import Network
import SwiftUI
import Combine

public protocol ScanWiFiUseCaseProtocol {
    var repository: WiFiRepositoryProtocol { get }
    var isScaningWifi: Bool { get set }
    var wifiNetwork: [WiFiNetwork] { get set }

    var networks: AnyPublisher<[WiFiNetwork], Never> { get }
    var isScanning: AnyPublisher<Bool, Never> { get }

    func requestAuthorization() async -> Bool
    func startScanning()
    func stopScanning()
    func execute() async throws -> [Device]
}

public final class ScanWiFiUseCase: ScanWiFiUseCaseProtocol {
    public func execute() async throws -> [Device] {
        startScanning()
        return []
    }

    public var wifiNetwork: [WiFiNetwork] = []
    public var isScaningWifi: Bool
    public let repository: WiFiRepositoryProtocol
    public init(
        repository: WiFiRepositoryProtocol,
        isScaningWifi: Bool = false
    ) {
        self.repository = repository
        self.isScaningWifi = isScaningWifi
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
        isScaningWifi = true
        repository.startScanning()
    }

    public func stopScanning() {
        isScaningWifi = false
        repository.stopScanning()
    }
}
