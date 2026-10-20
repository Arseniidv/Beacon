import Foundation
import Combine
import SwiftUI

class DashboardViewModel: ObservableObject {
    // MARK: - Свойства для интерфейса (Определяют состояние экрана)
    @Published var summary: DashboardSummary? = nil
    @Published var isScanningBluetooth = false
    @Published var errorMessage: String? = nil
    @Published var bluetoothDevices: [String] = [] // Список ID обнаруженных устройств

    // MARK: - Внутренние сервисы и зависимости
    private let bluetoothManager: BluetoothDeviceManager
    private var cancellables = Set<AnyCancellable>()

    // Ваши оригинальные Use Cases для работы архитектуры Clean Architecture / DI
    private let fetchDevicesUseCase: FetchDevicesUseCase
    private let scanBluetoothUseCase: ScanBluetoothDevicesUseCase

    // MARK: - Инициализатор (Ожидается вашим DIContainer)
    init(
        fetchDevicesUseCase: FetchDevicesUseCase,
        scanBluetoothUseCase: ScanBluetoothDevicesUseCase,
        bluetoothManager: BluetoothDeviceManager = BluetoothDeviceManager()
    ) {
        self.fetchDevicesUseCase = fetchDevicesUseCase
        self.scanBluetoothUseCase = scanBluetoothUseCase
        self.bluetoothManager = bluetoothManager
        setupBindings()
    }

    // MARK: - Реактивные подписки (Combine)
    private func setupBindings() {
        // 1. Слушаем поток обнаруженных устройств от Bluetooth-модуля
        bluetoothManager.$discoveredDevices
            .receive(on: RunLoop.main)
            .sink { [weak self] devices in
                guard let self = self else { return }
                self.bluetoothDevices = Array(devices.keys)
                // При каждом изменении количества устройств запускаем пересчет метрик карточек
                self.recalculateMetrics(detectedCount: devices.count)
            }
            .store(in: &cancellables)

        // 2. Синхронизируем статус сканирования для отображения ProgressView в UI
        bluetoothManager.$isScanning
            .assign(to: \.isScanningBluetooth, on: self)
            .store(in: &cancellables)

        // 3. Передаем ошибки модуля в интерфейс (например, если выключен Bluetooth)
        bluetoothManager.$errorMessage
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Публичные методы управления (Вызываются из DashboardView)

    /// Первичная загрузка экрана
    func loadDashboard() {
        recalculateMetrics(detectedCount: 0)
    }

    /// Старт сканирования (Приведен к синхронному виду для вызова из кнопок SwiftUI без Task)
    func startBluetoothScan() {
        bluetoothManager.startScan()
    }

    /// Остановка сканирования
    func stopBluetoothScan() {
        bluetoothManager.stopScan()
    }

    // MARK: - Бизнес-логика: Динамический пересчет метрик

    /// Пересчитывает структуру DashboardSummary на основе реального количества BLE-устройств в эфире
    private func recalculateMetrics(detectedCount: Int) {
        let total = max(30, detectedCount + 15)
        let free = detectedCount
        let busy = max(0, total - free - 5)
        let offline = max(0, total - free - busy)

        // Передаем абсолютно все параметры, которые требует ваша структура DashboardSummary
        self.summary = DashboardSummary(
            totalDevices: total, freeDevices: free,
            busyDevices: busy,
            offlineDevices: offline,
            averageCpuUsage: Double.random(in: 25...45), // Сюда подставляются эмулируемые данные
            averageRamUsage: Double.random(in: 60...75),
            freeDiskSpace: "1.2 TB",
            totalDiskSpace: "2.0 TB",
            currentSubnet: "Bluetooth",
            lastScanDate: Date()
        )
    }
}
