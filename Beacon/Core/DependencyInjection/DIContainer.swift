import Foundation

final class DIContainer {
    static let shared = DIContainer()
    
    private let networkService = NetworkService()
    private lazy var bluetoothService = BluetoothService()
    private lazy var wifiService = WiFiService()

    private lazy var deviceRepository = DeviceRepository(networkService: networkService)
    private lazy var bluetoothRepository = BluetoothRepository(bluetoothService: bluetoothService)
    private lazy var wifiRepository = WiFiRepository(service: wifiService)
    private lazy var authRepository = AuthRepository()
    private lazy var googleAuthService = GoogleAuthService()
    private lazy var networkProfileRepository = NetworkProfileRepository()

    private(set) lazy var authSession = AuthSessionStore(repository: authRepository)

    /// Общие настройки сканирования, редактируемые в админ-панели.
    private(set) lazy var scanSettings = ScanSettingsStore()

    private lazy var bluetoothManager = BluetoothDeviceManager()

    private init() {}


    /// Создание DashboardViewModel с автоматическим подсчетом Bluetooth
    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            fetchDevicesUseCase: FetchDevicesUseCase(
                repository: deviceRepository
            ),
            scanBluetoothUseCase: ScanBluetoothDevicesUseCase(
                repository: bluetoothRepository
            ),
            scanWiFiUseCase: ScanWiFiUseCase(
                repository: wifiRepository
            ),
            bluetoothManager: bluetoothManager
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
        let scanNetworkUseCase = ScanNetworkUseCase(repository: deviceRepository)
        return NetworkMapViewModel(
            scanBluetoothUseCase: scanBluetoothUseCase,
            scanWiFiUseCase: scanWiFiUseCase,
            scanNetworkUseCase: scanNetworkUseCase,
            settingsStore: scanSettings
        )
    }

    func makeDeviceDetailViewModel(device: Device) -> DeviceDetailViewModel {
        DeviceDetailViewModel(device: device)
    }

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(
            loginUseCase: LoginUseCase(repository: authRepository),
            registerUseCase: RegisterUseCase(repository: authRepository),
            googleSignInUseCase: SignInWithGoogleUseCase(
                authService: googleAuthService,
                repository: authRepository
            ),
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
        AdminPanelViewModel(
            authRepository: authRepository,
            session: authSession,
            settingsStore: scanSettings,
            networkProfileRepository: networkProfileRepository
        )
    }

    func makeNetworkProfileViewModel() -> NetworkProfileViewModel {
        NetworkProfileViewModel(repository: networkProfileRepository)
    }
}
