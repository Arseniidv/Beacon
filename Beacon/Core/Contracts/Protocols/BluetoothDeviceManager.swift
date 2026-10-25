
import Foundation
import CoreBluetooth
import Combine

final class BluetoothDeviceManager: NSObject,
                                   ObservableObject,
                                   CBCentralManagerDelegate {
    @Published private(set) var discoveredDevices: [String: Date] = [:]
    @Published private(set) var isScanning = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var bluetoothState: CBManagerState = .unknown
    private var centralManager: CBCentralManager!
    private var cleanupTimer: Timer?
    private let deviceTimeout: TimeInterval = 10
    private let cleanupInterval: TimeInterval = 4
    override init() {
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
        )
    }
    func startScan() {
        guard centralManager.state == .poweredOn else {
            errorMessage = bluetoothStateDescription(centralManager.state)
            return
        }
        errorMessage = nil
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true
            ]
        )

        isScanning = true
        startCleanupTimer()
    }

    func stopScan() {
        centralManager.stopScan()

        isScanning = false
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }

    // MARK: - Bluetooth State

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state

        switch central.state {
        case .poweredOn:
            errorMessage = nil

        case .poweredOff:
            stopScan()
            errorMessage = "Bluetooth выключен"

        case .unauthorized:
            stopScan()
            errorMessage = "Нет разрешения на использование Bluetooth"

        case .unsupported:
            stopScan()
            errorMessage = "Это устройство не поддерживает Bluetooth"

        case .resetting:
            stopScan()
            errorMessage = "Bluetooth перезапускается"

        case .unknown:
            stopScan()
            errorMessage = "Состояние Bluetooth пока неизвестно"

        @unknown default:
            stopScan()
            errorMessage = "Неизвестное состояние Bluetooth"
        }
    }

    // MARK: - Discovery

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard isScanning else { return }

        let deviceID = peripheral.identifier.uuidString
        discoveredDevices[deviceID] = Date()
    }

    // MARK: - Cleanup

    private func startCleanupTimer() {
        cleanupTimer?.invalidate()

        cleanupTimer = Timer.scheduledTimer(
            withTimeInterval: cleanupInterval,
            repeats: true
        ) { [weak self] _ in
            self?.removeInactiveDevices()
        }
    }

    private func removeInactiveDevices() {
        let now = Date()

        discoveredDevices = discoveredDevices.filter { _, lastSeen in
            now.timeIntervalSince(lastSeen) < deviceTimeout
        }
    }

    // MARK: - Helpers

    private func bluetoothStateDescription(
        _ state: CBManagerState
    ) -> String {
        switch state {
        case .poweredOff:
            return "Bluetooth выключен"

        case .unauthorized:
            return "Нет разрешения на использование Bluetooth"

        case .unsupported:
            return "Это устройство не поддерживает Bluetooth"

        case .resetting:
            return "Bluetooth перезапускается"

        case .unknown:
            return "Состояние Bluetooth пока неизвестно"

        case .poweredOn:
            return "Bluetooth готов к работе"

        @unknown default:
            return "Неизвестное состояние Bluetooth"
        }
    }
}
