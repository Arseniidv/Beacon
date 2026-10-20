import Foundation

final class DIContainer {
    // 1. Возвращаем правильное имя синглтона shared
    static let shared = DIContainer()

    // 2. Сетевые сервисы
    private let networkService = NetworkService()
    private lazy var bluetoothService = BluetoothService()
    private lazy var wifiService = WiFiService()

    // 3. Исправленные репозитории (БЕЗ ДУБЛИКАТОВ И СУФФИКСОВ Impl, строго как у вас)
    private lazy var deviceRepository = DeviceRepository(networkService: networkService)
    private lazy var bluetoothRepository = BluetoothRepository(bluetoothService: bluetoothService)
    private lazy var wifiRepository = WiFiRepository(service: wifiService)
    private lazy var authRepository = AuthRepository()

    // 4. Сессия авторизации
    private(set) lazy var authSession = AuthSessionStore(repository: authRepository)

    // 5. Приватный пустой инициализатор, чтобы никто не создал вторую копию контейнера
    private init() {}

    // MARK: - Фабричные методы для создания ViewModel

    /// Создание DashboardViewModel с автоматическим подсчетом Bluetooth
    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            fetchDevicesUseCase: FetchDevicesUseCase(repository: deviceRepository),
            scanBluetoothUseCase: ScanBluetoothDevicesUseCase(repository: bluetoothRepository),
            bluetoothManager: BluetoothDeviceManager()
        )
    }

    func makeDeviceViewModel() -> DeviceViewModel {
        let fetchDevicesUseCase = FetchDevicesUseCase(repository: deviceRepository)
        let scanNetworkUseCase = ScanNetworkUseCase(repository: deviceRepository)
        let reserveDeviceUseCase = ReserveDeviceUseCase(repository: deviceRepository)
        let connectDeviceUseCase = ConnectDeviceUseCase(repository: deviceRepository)

        return DeviceViewModel(
            fetchDevicesUseCase: fetchDevicesUseCase,
            scanNetworkUseCase: scanNetworkUseCase,
            reserveDeviceUseCase: reserveDeviceUseCase,
            connectDeviceUseCase: connectDeviceUseCase
        )
    }

    @available(iOS 17.0, *)
    func makeNetworkMapViewModel() -> NetworkMapViewModel {
        let scanBluetoothUseCase = ScanBluetoothDevicesUseCase(repository: bluetoothRepository)
        let scanWiFiUseCase = ScanWiFiUseCase(repository: wifiRepository)
        return NetworkMapViewModel(
            scanBluetoothUseCase: scanBluetoothUseCase,
            scanWiFiUseCase: scanWiFiUseCase
        )
    }

    func makeDeviceDetailViewModel(device: Device) -> DeviceDetailViewModel {
        DeviceDetailViewModel(device: device)
    }

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(
            loginUseCase: LoginUseCase(repository: authRepository),
            registerUseCase: RegisterUseCase(repository: authRepository),
            session: authSession
        )
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            session: authSession,
            bluetoothService: bluetoothService
        )
    }

    func makeAdminPanelViewModel() -> AdminPanelViewModel {
        AdminPanelViewModel(authRepository: authRepository)
    }
}
