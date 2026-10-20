import Foundation
import Combine
import SwiftUI
import CoreLocation
import MapKit


@available(iOS 17.0, *)
@MainActor
final class NetworkMapViewModel: NSObject, ObservableObject {
    // MARK: - Published State
    @Published private(set) var networkDevices: [Device] = []
    @Published private(set) var bluetoothDevices: [BluetoothDevice] = []
    @Published private(set) var wifiNetworks: [WiFiNetwork] = []
    @Published private(set) var networkEvents: [NetworkEvent] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isScanningBluetooth: Bool = false
    @Published private(set) var isScanningWiFi: Bool = false
    @Published private(set) var userLocation: CLLocationCoordinate2D?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // Общая статистика подсети (для графиков)
    @Published private(set) var avgCpuUsage: Double = 0.0
    @Published private(set) var avgRamUsage: Double = 0.0
    @Published private(set) var networkSpeedMbps: Double = 0.0

    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    let subnetRange: String = "192.168.1.0/24"

    
    private let scanBluetoothUseCase: ScanBluetoothDevicesUseCaseProtocol
    private let scanWiFiUseCase: ScanWiFiUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()

    init(
        scanBluetoothUseCase: ScanBluetoothDevicesUseCaseProtocol,
        scanWiFiUseCase: ScanWiFiUseCaseProtocol
    ) {
        self.scanBluetoothUseCase = scanBluetoothUseCase
        self.scanWiFiUseCase = scanWiFiUseCase
        super.init()

        setupLocationManager()
        setupBluetoothSubscriptions()
        setupWiFiSubscriptions()
        loadMockData()
    }

    // MARK: - Public API
    func startNetworkScan() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isLoading = false
            self?.loadMockData()
        }
    }

    func startBluetoothScan() async {
        let authorized = await scanBluetoothUseCase.requestAuthorization()
        guard authorized else {
            return
        }

        scanBluetoothUseCase.startScanning()
    }

    func stopBluetoothScan() {
        scanBluetoothUseCase.stopScanning()
    }

    func startWiFiScan() async {
        let authorized = await scanWiFiUseCase.requestAuthorization()
        guard authorized else {
            return
        }

        scanWiFiUseCase.startScanning()
    }

    func stopWiFiScanstopWiFiScan() {
        scanWiFiUseCase.stopScanning()
    }

    private func setupWiFiSubscriptions() {
        scanWiFiUseCase.networks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] networks in
                self?.wifiNetworks = networks
            }
            .store(in: &cancellables)

        scanWiFiUseCase.isScanning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isScanning in
                self?.isScanningWiFi = isScanning
            }
            .store(in: &cancellables)
    }

    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func focus(on device: BluetoothDevice) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: device.coordinate.clLocationCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }

    func centerOnUserLocation() {
        guard let location = userLocation else {
            requestLocationAuthorization()
            return
        }

        cameraPosition = .region(
            MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }

    var totalCount: Int { networkDevices.count }
    var freeCount: Int { networkDevices.filter { $0.status == .free }.count }
    var busyCount: Int { networkDevices.filter { $0.status == .busy }.count }
    var offlineCount: Int { networkDevices.filter { $0.status == .offline }.count }
    var bluetoothCount: Int { bluetoothDevices.count }

    // MARK: - Private Methods
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        // Запрашиваем авторизацию. Ответ придет асинхронно в метод делегата.
        locationManager.requestWhenInUseAuthorization()
    }

    private func setupBluetoothSubscriptions() {
        scanBluetoothUseCase.devices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                self?.bluetoothDevices = devices
            }
            .store(in: &cancellables)

        scanBluetoothUseCase.isScanning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isScanning in
                self?.isScanningBluetooth = isScanning
            }
            .store(in: &cancellables)
    }

    private func loadMockData() {
        self.networkDevices = [
            Device(
                name: "Router",
                ip: "192.168.1.1",
                macAddress: "00:1A:2B:3C:4D:01",
                status: .free,
                ping: 1
            ),
            Device(name: "PC-01-ADMIN", ip: "192.168.1.10", macAddress: "00:18:44:11:3A:B7", status: .free, ping: 1, cpuUsage: 12, ramUsage: 28),
            Device(name: "PC-02-DESIGN", ip: "192.168.1.11", macAddress: "00:18:44:11:3A:B8", status: .busy, ping: 2, cpuUsage: 78, ramUsage: 72),
            Device(name: "PC-03-RENDER", ip: "192.168.1.12", macAddress: "00:18:44:11:3A:B9", status: .free, ping: 1, cpuUsage: 6, ramUsage: 18),
            Device(name: "PC-04-OFFICE", ip: "192.168.1.13", macAddress: "00:18:44:11:3A:C0", status: .busy, ping: 3, cpuUsage: 45, ramUsage: 62),
            Device(name: "PC-05-LAB", ip: "192.168.1.14", macAddress: "00:18:44:11:3A:C1", status: .offline),
            Device(name: "PC-06-TEST", ip: "192.168.1.15", macAddress: "00:18:44:11:3A:C2", status: .free, ping: 2, cpuUsage: 18, ramUsage: 34)
        ]

        let activeDevices = networkDevices.filter { $0.status != .offline }
        self.avgCpuUsage = activeDevices.compactMap { $0.cpuUsage }.reduce(0, +) / Double(activeDevices.count)
        self.avgRamUsage = activeDevices.compactMap { $0.ramUsage }.reduce(0, +) / Double(activeDevices.count)
        self.networkSpeedMbps = 120.0

        self.networkEvents = [
            NetworkEvent(time: "14:28", type: .scanCompleted, message: "Сканирование сети завершено. Найдено 52 устройства (28 свободных)"),
            NetworkEvent(time: "14:17", type: .userLeft, message: "PC-01-ADMIN стал свободен. Пользователь вышел из системы"),
            NetworkEvent(time: "13:52", type: .userJoined, message: "PC-04-OFFICE занят. Пользователь: Е. Козлов"),
            NetworkEvent(time: "12:36", type: .timeout, message: "PC-05-LAB недоступен. Устройство не отвечает (ping timeout)")
        ]
    }
}


// MARK: - CLLocationManagerDelegate
@available(iOS 17.0, *)
extension NetworkMapViewModel: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if #available(iOS 17.0, *) {
            self.authorizationStatus = status
        } else {
                // Fallback on earlier versions
        } // Обновляем SwiftUI состояние

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Разрешение получено, теперь можно безопасно запускать обновление
            manager.startUpdatingLocation()

        case .denied, .restricted:
            // Пользователь отклонил запрос
            print("Доступ к геолокации запрещен.")

        case .notDetermined:
            // Статус еще не определен, ждем выбора пользователя
            break

        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Извлекаем последние актуальные координаты
        guard let location = locations.last else { return }

        // Сохраняем в переменную состояния для отображения на карте
        self.userLocation = location.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Ошибка получения локации: \(error.localizedDescription)")
    }
}

// MARK: - Supporting Presentation Models
struct NetworkEvent: Identifiable {
    let id = UUID()
    let time: String
    let type: EventType
    let message: String

    enum EventType {
        case scanCompleted, userLeft, userJoined, timeout

        var iconName: String {
            switch self {
            case .scanCompleted: return "checkmark.circle.fill"
            case .userLeft: return "person.crop.circle.badge.minus"
            case .userJoined: return "person.crop.circle.badge.checkmark"
            case .timeout: return "exclamationmark.triangle.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .scanCompleted: return .blue
            case .userLeft: return .green
            case .userJoined: return .red
            case .timeout: return .gray
            }
        }
    }
}
