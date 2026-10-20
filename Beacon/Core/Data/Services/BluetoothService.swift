import Foundation
import CoreBluetooth
import CoreLocation
import Combine

@MainActor
final class BluetoothService: NSObject, BluetoothServiceProtocol {

    // MARK: - Private Properties
    private var centralManager: CBCentralManager?
    private var locationManager: CLLocationManager?

    private var discoveredDevices: [BluetoothDevice] = []
    private var scannedPeripherals: [String: CBPeripheral] = [:]

    private let devicesSubject = CurrentValueSubject<[BluetoothDevice], Never>([])
    private let isScanningSubject = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Public API (Publishers)
    var devices: AnyPublisher<[BluetoothDevice], Never> {
        devicesSubject.eraseToAnyPublisher()
    }

    var isScanning: AnyPublisher<Bool, Never> {
        isScanningSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        setupCentralManager()
    }

    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager?.startUpdatingLocation()
    }

    private func setupCentralManager() {
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - BluetoothServiceProtocol Implementation
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

        return centralManager?.state == .poweredOn
    }

    func startScanning() {
        guard let centralManager = centralManager, centralManager.state == .poweredOn else {
            return
        }

        // Чистим список перед новым сканированием, чтобы убрать старые данные
        discoveredDevices.removeAll()
        scannedPeripherals.removeAll()
        devicesSubject.send([])

        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])

        isScanningSubject.send(true)
    }

    func stopScanning() {
        centralManager?.stopScan()
        isScanningSubject.send(false)
    }

    func connect(to device: BluetoothDevice) async throws {
        guard let peripheral = scannedPeripherals[device.identifier] else {
            throw BluetoothError.deviceNotFound
        }

        centralManager?.connect(peripheral, options: nil)
    }

    func disconnect(from device: BluetoothDevice) async throws {
        guard let peripheral = scannedPeripherals[device.identifier] else {
            throw BluetoothError.deviceNotFound
        }

        centralManager?.cancelPeripheralConnection(peripheral)
    }

    // MARK: - Math Helpers for Distance & Coordinates
    private func calculateDistance(rssi: Int) -> Double {
        let txPower = -59
        if rssi == 0 {
            return -1.0
        }

        let ratio = Double(txPower - rssi) / 10.0
        if ratio < 1.0 {
            return pow(10.0, ratio)
        }

        return (0.89976) * pow(ratio, 7.7095) + 0.111
    }

    private func coordinateForDevice(at distance: Double, angle: Double, from center: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let earthRadius = 6371000.0
        let angleRad = angle * .pi / 180.0

        let latOffset = (distance * cos(angleRad)) / earthRadius * (180.0 / .pi)
        let lonOffset = (distance * sin(angleRad)) / earthRadius * (180.0 / .pi) / cos(center.latitude * .pi / 180.0)

        return CLLocationCoordinate2D(
            latitude: center.latitude + latOffset,
            longitude: center.longitude + lonOffset
        )
    }

    // MARK: - Manufacturer Identification
    private func getManufacturerName(for manufacturerID: UInt16) -> String {
        // Known manufacturer IDs (Bluetooth SIG assigned numbers)
        switch manufacturerID {
        case 0x004C: return "Apple"
        case 0x0006: return "Microsoft"
        case 0x00E0: return "Google"
        case 0x0087: return "Garmin"
        case 0x00D7: return "Dyson"
        case 0x0090: return "HTC"
        case 0x00A0: return "Intel"
        case 0x00A2: return "Samsung"
        case 0x009A: return "Nike"
        case 0x009F: return "Huawei"
        case 0x009B: return "Siemens"
        case 0x009E: return "Sony"
        case 0x009C: return "Qualcomm"
        case 0x009D: return "Texas Instruments"
        case 0x00A4: return "Lenovo"
        case 0x00A5: return "Asus"
        case 0x00A8: return "Foxconn"
        case 0x00AA: return "Bose"
        case 0x00AC: return "Dell"
        case 0x00AD: return "HP"
        case 0x00AE: return "LG"
        case 0x00B0: return "Motorola"
        case 0x00B3: return "Cisco"
        case 0x00B4: return "Logitech"
        case 0x00B5: return "Panasonic"
        case 0x00B8: return "Shanghai Sunic"
        case 0x00BA: return "Polar"
        case 0x00C2: return "Amazon"
        case 0x00C5: return "Tile"
        case 0x00D6: return "Fitbit"
        case 0x00E8: return "Nintendo"
        case 0x00F4: return "Volkswagen"
        case 0x00F7: return "Xiaomi"
        case 0x0115: return "Broadcom"
        case 0x012A: return "Realtek"
        case 0x015D: return "Baidu"
        case 0x0167: return "Honor"
        case 0x017C: return "OPPO"
        case 0x0187: return "Vivo"
        case 0x019A: return "OnePlus"
        default: return String(format: "Unknown (0x%04X)", manufacturerID)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            break
        case .unauthorized, .poweredOff:
            stopScanning()
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {

        // 1. Умное извлечение имени устройства из данных рекламы
        var discoveredName = advertisementData[CBAdvertisementDataLocalNameKey] as? String

        // Если имя не найдено в локальном имени, пробуем извлечь из manufacturer data
        if discoveredName == nil || discoveredName?.isEmpty == true {
            if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                // Извлекаем первые байты для идентификации производителя
                let manufacturerID = manufacturerData.prefix(2).withUnsafeBytes { $0.load(as: UInt16.self) }
                discoveredName = getManufacturerName(for: manufacturerID)
            }
        }

        // Если все еще нет имени, используем системное имя периферии
        if discoveredName == nil || discoveredName?.isEmpty == true {
            discoveredName = peripheral.name
        }

        // Если и системное имя пустое, создаем информативное имя на основе UUID
        if discoveredName == nil || discoveredName?.isEmpty == true {
            let uuidPrefix = String(peripheral.identifier.uuidString.prefix(8))
            discoveredName = "Device-\(uuidPrefix)"
        }

        let identifier = peripheral.identifier.uuidString
        let rssi = RSSI.intValue
        let distance = calculateDistance(rssi: rssi)

        let existing = discoveredDevices.first(where: { $0.identifier == identifier })
        let deviceCoordinate: Coordinate

        if let existing {
            deviceCoordinate = existing.coordinate
        } else if let currentLocation = locationManager?.location?.coordinate {
            let angle = Double(Int.random(in: 0...360))
            let coordinate = coordinateForDevice(at: distance, angle: angle, from: currentLocation)
            deviceCoordinate = Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
        } else {
            deviceCoordinate = Coordinate(latitude: 55.7558, longitude: 37.6173)
        }

        let device = BluetoothDevice(
            id: existing?.id ?? UUID(),
            name: discoveredName ??  "Название" , // Передаем корректно определенное имя
            identifier: identifier,
            rssi: rssi,
            coordinate: deviceCoordinate,
            distance: distance,
            connectionStatus: existing?.connectionStatus ?? .disconnected,
            services: existing?.services ?? []
        )

        if let index = discoveredDevices.firstIndex(where: { $0.identifier == identifier }) {
            discoveredDevices[index] = device
        } else {
            discoveredDevices.append(device)
        }

        scannedPeripherals[identifier] = peripheral
        devicesSubject.send(discoveredDevices)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let index = discoveredDevices.firstIndex(where: { $0.identifier == peripheral.identifier.uuidString }) {
            let device = discoveredDevices[index]
            let updatedDevice = BluetoothDevice(
                id: device.id,
                name: device.name,
                identifier: device.identifier,
                rssi: device.rssi,
                coordinate: device.coordinate,
                distance: device.distance,
                connectionStatus: .connected,
                services: device.services,
                lastSeen: device.lastSeen
            )
            discoveredDevices[index] = updatedDevice
            devicesSubject.send(discoveredDevices)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let index = discoveredDevices.firstIndex(where: { $0.identifier == peripheral.identifier.uuidString }) {
            let device = discoveredDevices[index]
            let updatedDevice = BluetoothDevice(
                id: device.id,
                name: device.name,
                identifier: device.identifier,
                rssi: device.rssi,
                coordinate: device.coordinate,
                distance: device.distance,
                connectionStatus: .disconnected,
                services: device.services,
                lastSeen: device.lastSeen
            )
            discoveredDevices[index] = updatedDevice
            devicesSubject.send(discoveredDevices)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension BluetoothService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        default:
            break
        }
    }
}

// MARK: - Errors
enum BluetoothError: Error {
    case deviceNotFound
    case notAuthorized
    case bluetoothUnavailable
}
