import Foundation
import CoreBluetooth
import Combine

class BluetoothDeviceManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var discoveredDevices: [String: Date] = [:]
    @Published var isScanning = false
    @Published var errorMessage: String? = nil

    private var centralManager: CBCentralManager!

    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    func startScan() {
        guard centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth выключен или недоступен"
            return
        }
        errorMessage = nil
        isScanning = true
        discoveredDevices.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        startDeadDevicesCleanup()
    }

    func stopScan() {
        centralManager.stopScan()
        isScanning = false
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn: errorMessage = nil
        case .poweredOff: errorMessage = "Bluetooth выключен"; stopScan()
        case .unauthorized: errorMessage = "Нет прав на Bluetooth"
        default: errorMessage = "Сбой модуля Bluetooth"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi NSNumber: NSNumber) {
        let deviceID = peripheral.identifier.uuidString
        DispatchQueue.main.async {
            self.discoveredDevices[deviceID] = Date()
        }
    }

    private func startDeadDevicesCleanup() {
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isScanning else { return }
            let activeDevices = self.discoveredDevices.filter { Date().timeIntervalSince($0.value) < 10.0 }
            if activeDevices.count != self.discoveredDevices.count {
                DispatchQueue.main.async { self.discoveredDevices = activeDevices }
            }
        }
    }
}
