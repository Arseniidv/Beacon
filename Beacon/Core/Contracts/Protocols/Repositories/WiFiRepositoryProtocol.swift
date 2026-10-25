import Foundation
import Combine

public protocol WiFiRepositoryProtocol {
    var networks: AnyPublisher<[WiFiNetwork], Never> { get }
    var isScanning: AnyPublisher<Bool, Never> { get }

    func requestAuthorization() async -> Bool
    func startScanning()
    func stopScanning()
}
