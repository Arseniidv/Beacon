import Foundation
import Combine

public protocol WiFiServiceProtocol {
    var networks: AnyPublisher<[WiFiNetwork], Never> { get }
    var isScanning: AnyPublisher<Bool, Never> { get }

    func requestAuthorization() async -> Bool
    func startScanning()
    func stopScanning()
}
