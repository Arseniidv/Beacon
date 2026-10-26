
import Foundation
import Combine
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var summary: DashboardSummary?
    @Published private(set) var isScanningBluetooth = false
    @Published private(set) var isScanningWiFi = false
    @Published private(set) var errorMessage: String?
    // MARK: - Bluetooth
    @Published private(set) var bluetoothDevices: [String] = []
    var bluetoothCount: Int {
        bluetoothDevices.count
    }
    @Published private(set) var wifiDevices: [Device] = []

    var wifiCount: Int {
        wifiDevices.count
    }
    private let bluetoothManager: BluetoothDeviceManager
    private let fetchDevicesUseCase: FetchDevicesUseCase
    private let scanBluetoothUseCase: ScanBluetoothDevicesUseCase
    private let scanWiFiUseCase: ScanWiFiUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    private var wifiScanTask: Task<Void, Never>?
    init(
        fetchDevicesUseCase: FetchDevicesUseCase,
        scanBluetoothUseCase: ScanBluetoothDevicesUseCase,
        scanWiFiUseCase: ScanWiFiUseCaseProtocol,
        bluetoothManager: BluetoothDeviceManager
    ) {
        self.fetchDevicesUseCase = fetchDevicesUseCase
        self.scanBluetoothUseCase = scanBluetoothUseCase
        self.scanWiFiUseCase = scanWiFiUseCase
        self.bluetoothManager = bluetoothManager

        setupBindings()
    }
    // MARK: - Combine
    private func setupBindings() {
        bluetoothManager.$discoveredDevices
            .receive(on: RunLoop.main)
            .sink { [weak self] devices in
                guard let self else { return }

                self.bluetoothDevices = Array(devices.keys)
            }
            .store(in: &cancellables)

        bluetoothManager.$isScanning
            .receive(on: RunLoop.main)
            .sink { [weak self] isScanning in
                self?.isScanningBluetooth = isScanning
            }
            .store(in: &cancellables)

        bluetoothManager.$errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
    }
    func loadDashboard() {
        errorMessage = nil
        startWiFiScan()
    }
    func startBluetoothScan() {
        errorMessage = nil
        bluetoothManager.startScan()
    }
    func stopBluetoothScan() {
        bluetoothManager.stopScan()
    }

    // MARK: - Wi-Fi

    func startWiFiScan() {
        guard !isScanningWiFi else { return }

        isScanningWiFi = true
        errorMessage = nil

        wifiScanTask = Task { [weak self] in
            guard let self else { return }

            defer {
                self.isScanningWiFi = false
                self.wifiScanTask = nil
            }

            do {
                let devices = try await self.scanWiFiUseCase.execute()

                try Task.checkCancellation()

                self.wifiDevices = devices

            } catch is CancellationError {
                //
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage =
                    "Ошибка сканирования Wi-Fi: \(error.localizedDescription)"
            }
        }
    }
    func stopWiFiScan() {
        wifiScanTask?.cancel()
    }
}
