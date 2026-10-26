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
    @Published private(set) var isScanningLocalSignal: Bool = false
    @Published private(set) var userLocation: CLLocationCoordinate2D?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    /// Видимая область карты. По её размеру считается кластеризация маркеров.
    @Published private(set) var visibleRegion: MKCoordinateRegion = NetworkMapViewModel.defaultRegion

    // Состояние карты: источник сканирования и фильтр
    @Published var listMode: ScanSource = .localSignal
    @Published var statusFilter: DeviceFilter = .all
    @Published var selectedDevice: Device?

    @Published var cameraPosition: MapCameraPosition = .region(NetworkMapViewModel.defaultRegion)

    /// Стартовая область карты (Москва).
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    /// На сколько ячеек по каждой оси делится видимая область при кластеризации.
    private static let clusterGridDivisions: Double = 10

    // MARK: - Dependencies
    private let scanBluetoothUseCase: ScanBluetoothDevicesUseCaseProtocol
    private let scanWiFiUseCase: ScanWiFiUseCaseProtocol
    private let scanNetworkUseCase: ScanNetworkUseCaseProtocol
    private let settingsStore: ScanSettingsStore
    private var cancellables = Set<AnyCancellable>()
    private var localScanTask: Task<Void, Never>?
    private var autoRefreshTask: Task<Void, Never>?
    private let locationManager = CLLocationManager()

    // MARK: - Init
    init(
        scanBluetoothUseCase: ScanBluetoothDevicesUseCaseProtocol,
        scanWiFiUseCase: ScanWiFiUseCaseProtocol,
        scanNetworkUseCase: ScanNetworkUseCaseProtocol,
        settingsStore: ScanSettingsStore
    ) {
        self.scanBluetoothUseCase = scanBluetoothUseCase
        self.scanWiFiUseCase = scanWiFiUseCase
        self.scanNetworkUseCase = scanNetworkUseCase
        self.settingsStore = settingsStore
        super.init()

        setupLocationManager()
        setupBluetoothSubscriptions()
        setupWiFiSubscriptions()
        setupSettingsSubscription()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
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

    private func setupWiFiSubscriptions() {
        // Подставьте правильные имена паблишеров из вашего ScanWiFiUseCaseProtocol
        // Пример (если они называются networks и isScanning):
        /*
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
        */
    }

    private func setupSettingsSubscription() {
        settingsStore.$settings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if !self.settingsStore.settings.isEnabled(self.listMode) {
                    self.stopScan()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    /// Источники, разрешённые администратором в настройках.
    var availableSources: [ScanSource] {
        let settings = settingsStore.settings
        return ScanSource.allCases.filter { settings.isEnabled($0) }
    }

    /// Идёт ли сканирование текущего источника.
    var isScanning: Bool {
        switch listMode {
        case .localSignal: return isScanningLocalSignal
        case .wifi: return isScanningWiFi
        case .bluetooth: return isScanningBluetooth
        }
    }

    /// Запускает сканирование по выбранному источнику.
    func startScan() {
        guard settingsStore.settings.isEnabled(listMode) else { return }

        switch listMode {
        case .localSignal:
            startLocalScan()
        case .wifi:
            Task { await startWiFiScan() }
        case .bluetooth:
            Task { await startBluetoothScan() }
        }
    }

    /// Останавливает сканирование текущего источника.
    func stopScan() {
        switch listMode {
        case .localSignal:
            stopLocalScan()
        case .wifi:
            stopWiFiScan()
        case .bluetooth:
            stopBluetoothScan()
        }
    }

    // MARK: - Local network scan

    private func startLocalScan() {
        guard !isScanningLocalSignal else { return }

        let subnet = settingsStore.settings.subnet
        isScanningLocalSignal = true

        localScanTask = Task { [weak self] in
            guard let self else { return }

            do {
                let scanned = try await self.scanNetworkUseCase.execute(
                    subnet: subnet,
                    timeout: self.settingsStore.settings.pingTimeoutSeconds
                )
                self.mergeScannedDevices(scanned)
                self.addEvent(
                    type: .scanCompleted,
                    message: "Сканирование \(subnet) завершено. Найдено \(scanned.count) устройств"
                )
            } catch {
                self.addEvent(
                    type: .timeout,
                    message: "Не удалось просканировать \(subnet)"
                )
            }

            self.isScanningLocalSignal = false
        }
    }

    private func stopLocalScan() {
        localScanTask?.cancel()
        localScanTask = nil
        isScanningLocalSignal = false
    }

    private func mergeScannedDevices(_ scanned: [Device]) {
        for device in scanned {
            guard let index = networkDevices.firstIndex(where: { $0.ip == device.ip }) else {
                networkDevices.append(device)
                continue
            }

            let known = networkDevices[index]
            networkDevices[index] = device.copying(coordinate: known.coordinate ?? device.coordinate)
        }
    }

    private func addEvent(type: NetworkEvent.EventType, message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        networkEvents.insert(
            NetworkEvent(time: formatter.string(from: Date()), type: type, message: message),
            at: 0
        )
    }

    // MARK: - Bluetooth

    func startBluetoothScan() async {
        guard !isScanningBluetooth else { return }

        let authorized = await scanBluetoothUseCase.requestAuthorization()

        guard !Task.isCancelled, authorized else {
            addEvent(
                type: .timeout,
                message: "Не удалось получить разрешение на Bluetooth"
            )
            return
        }

        scanBluetoothUseCase.startScanning()
    }

    func stopBluetoothScan() {
        scanBluetoothUseCase.stopScanning()
    }

    // MARK: - Wi-Fi

    func startWiFiScan() async {
        guard !isScanningWiFi else { return }

        let authorized = await scanWiFiUseCase.requestAuthorization()

        guard !Task.isCancelled, authorized else {
            addEvent(
                type: .timeout,
                message: "Не удалось получить разрешение для получения данных Wi-Fi"
            )
            return
        }

        scanWiFiUseCase.startScanning()
    }

    func stopWiFiScan() {
        scanWiFiUseCase.stopScanning()
    }

    // MARK: - Computed Properties for View
    var filteredNetworkDevices: [Device] {
        switch statusFilter {
        case .all:
            return networkDevices
        case .free:
            return networkDevices.filter { $0.status == .free || $0.status == .busy }
        case .offline:
            return networkDevices.filter { $0.status == .offline }
        case .busy:
            return networkDevices.filter { $0.status == .busy }
            
        // Добавьте остальные кейсы DeviceFilter, если они есть
        default:
            return networkDevices
        }
    }

    var totalCount: Int {
        networkDevices.count
    }

    var bluetoothCount: Int {
        bluetoothDevices.count
    }

    /// Wi-Fi сети, у которых есть координаты (для отображения на карте)
    var mappedWiFiNetworks: [WiFiNetwork] {
        wifiNetworks.filter { $0.coordinate != nil }
    }

    /// Кластеры устройств для карты (простая версия без реальной кластеризации)
    var deviceClusters: [DeviceCluster] {
        var clusters: [DeviceCluster] = []

        for device in networkDevices {
            guard let coordinate = device.coordinate else {
                continue
            }

            let cluster = DeviceCluster(
                id: device.id.uuidString,
                coordinate: coordinate.clLocationCoordinate,
                devices: [device]
            )

            clusters.append(cluster)
        }

        return clusters
    }
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func updateVisibleRegion(_ region: MKCoordinateRegion) {
        visibleRegion = region
    }

    func centerOnUserLocation() {
        guard let location = userLocation else { return }
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        }
    }

    func select(_ device: Device) {
        selectedDevice = device
        if let coordinate = device.coordinate {
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate.clLocationCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }
        }
    }

    func focus(on cluster: DeviceCluster) {
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: cluster.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
    }

    func focus(on device: BluetoothDevice) {
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: device.coordinate.clLocationCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
    }
}

// MARK: - CLLocationManagerDelegate
@available(iOS 17.0, *)
extension NetworkMapViewModel: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        self.authorizationStatus = status

        #if os(macOS)
        let isAuthorized = status == .authorizedAlways
        #else
        let isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
        #endif

        if isAuthorized {
            manager.startUpdatingLocation()
        } else if status == .denied || status == .restricted {
            print("Доступ к геолокации запрещен.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Ошибка получения локации: \(error.localizedDescription)")
    }
}

// MARK: - Кластер маркеров на карте
struct DeviceCluster: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    /// Устройства кластера. Для одиночного маркера — ровно одно.
    let devices: [Device]

    var isCluster: Bool { devices.count > 1 }

    var title: String {
        guard devices.count > 1 else {
            return devices.first?.name ?? ""
        }
        return "\(devices.count) \(Self.devicesWord(for: devices.count))"
    }

    /// Цвет кластера берётся по «худшему» статусу внутри него.
    var dominantStatus: DeviceStatus {
        if devices.contains(where: { $0.status == .offline }) { return .offline }
        if devices.contains(where: { $0.status == .busy }) { return .busy }
        return .free
    }

    private static func devicesWord(for count: Int) -> String {
        let hundreds = count % 100
        if (11...14).contains(hundreds) { return "устройств" }

        switch count % 10 {
        case 1: return "устройство"
        case 2, 3, 4: return "устройства"
        default: return "устройств"
        }
    }
}

/// Ключ ячейки сетки для кластеризации.
private struct ClusterGridKey: Hashable {
    let row: Int
    let column: Int

    var id: String { "\(row):\(column)" }
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
