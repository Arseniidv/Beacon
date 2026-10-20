import Foundation
import CoreLocation
import NetworkExtension
import Combine

@MainActor
final class WiFiService: NSObject, WiFiServiceProtocol {

    // MARK: - Private Properties
    private var locationManager: CLLocationManager?
    private var networkMonitor: NWPathMonitor?

    private var discoveredNetworks: [WiFiNetwork] = []

    private let networksSubject = CurrentValueSubject<[WiFiNetwork], Never>([])
    private let isScanningSubject = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Public API (Publishers)
    var networks: AnyPublisher<[WiFiNetwork], Never> {
        networksSubject.eraseToAnyPublisher()
    }

    var isScanning: AnyPublisher<Bool, Never> {
        isScanningSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        setupNetworkMonitor()
    }

    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager?.startUpdatingLocation()
    }

    private func setupNetworkMonitor() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            // Monitor network changes
            print("Network path changed: \(path.status)")
        }
        networkMonitor?.start(queue: .main)
    }

    // MARK: - WiFiServiceProtocol Implementation
    func requestAuthorization() async -> Bool {
        guard let locationManager = locationManager else {
            return false
        }

        locationManager.requestWhenInUseAuthorization()

        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }

        return locationManager.authorizationStatus == .authorizedWhenInUse ||
               locationManager.authorizationStatus == .authorizedAlways
    }

    func startScanning() {
        // Clear previous scan results
        discoveredNetworks.removeAll()
        networksSubject.send([])

        // Start scanning
        isScanningSubject.send(true)

        // Simulate WiFi scanning (actual NEHotspotNetwork scanning requires entitlements)
        simulateWiFiScan()
    }

    func stopScanning() {
        isScanningSubject.send(false)
    }

    // MARK: - Mock WiFi Scanning
    // Note: Real WiFi scanning requires NEHotspotNetworkHelper with special entitlements
    // This is a simulation for demonstration purposes
    private func simulateWiFiScan() {
        guard let currentLocation = locationManager?.location?.coordinate else {
            return
        }

        // Simulate discovered networks
        let mockNetworks = createMockNetworks(at: currentLocation)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.discoveredNetworks = mockNetworks
            self?.networksSubject.send(mockNetworks)
            self?.isScanningSubject.send(false)
        }
    }

    private func createMockNetworks(at location: CLLocationCoordinate2D) -> [WiFiNetwork] {
        let networkNames: [(String, String, Int, Int, Double, WiFiNetwork.SecurityType)] = [
            ("HomeNetwork", "AC:12:34:56:78:90", -45, 6, 2.4, .wpa2),
            ("Office_WiFi", "AC:12:34:56:78:91", -52, 11, 2.4, .wpa2Enterprise),
            ("Guest_5G", "AC:12:34:56:78:92", -58, 36, 5.0, .wpa2),
            ("Neighbor_Net", "AC:12:34:56:78:93", -65, 1, 2.4, .wpa3),
            ("Coffee_Shop", "AC:12:34:56:78:94", -72, 6, 2.4, .none),
            ("Smart_Home", "AC:12:34:56:78:95", -78, 11, 2.4, .wpa2),
            ("IoT_Device", "AC:12:34:56:78:96", -85, 1, 2.4, .wpa)
        ]


        return networkNames.map { name, mac, signal, channel, frequency, security in
            let calculatedDist = self.calculateDistance(from: signal)

            // 2. Генерируем случайный угол для красивого распределения точек на карте
            let randomAngle = Double.random(in: 0...360)

            // 3. Вычисляем координаты для моковой сети с помощью вашего хелпера coordinateForNetwork
            let calculatedCoordinate2D = self.coordinateForNetwork(at: calculatedDist, angle: randomAngle, from: location)

            // 4. Инициализируем вашу кастомную структуру Coordinate правильным образом
            let networkCoordinate = Coordinate(
                latitude: calculatedCoordinate2D.latitude,
                longitude: calculatedCoordinate2D.longitude
            )

            // 5. Собираем объект WiFiNetwork со всеми обязательными аргументами
            return WiFiNetwork(
                ssid: name,
                bssid: mac,
                signalStrength: signal,
                channel: channel,
                frequency: frequency,
                securityType: security,
                coordinate: networkCoordinate, // <-- ИСПРАВЛЕНО (передаем готовый экземпляр)
                distance: calculatedDist       // <-- ИСПРАВЛЕНО (передаем вычисленную дистанцию)
            )
        }
    }

    // MARK: - Math Helpers
    private func calculateDistance(from rssi: Int) -> Double {
        let txPower = -30
        if rssi == 0 {
            return -1.0
        }

        let ratio = Double(txPower - rssi) / 20.0
        if ratio < 1.0 {
            return pow(10.0, ratio)
        }

        return (0.89976) * pow(ratio, 7.7095) + 0.111
    }

    private func coordinateForNetwork(at distance: Double, angle: Double, from center: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let earthRadius = 6371000.0
        let angleRad = angle * .pi / 180.0

        let latOffset = (distance * cos(angleRad)) / earthRadius * (180.0 / .pi)
        let lonOffset = (distance * sin(angleRad)) / earthRadius * (180.0 / .pi) / cos(center.latitude * .pi / 180.0)

        return CLLocationCoordinate2D(
            latitude: center.latitude + latOffset,
            longitude: center.longitude + lonOffset
        )
    }
}

// MARK: - CLLocationManagerDelegate
extension WiFiService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        default:
            break
        }
    }
}
