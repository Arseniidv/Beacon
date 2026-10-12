import Foundation

final class DIContainer {
    static let shared = DIContainer()

    private init() {}

    private let networkService = NetworkService()
    private lazy var deviceRepository = DeviceRepository(networkService: networkService)

    func makeDashboardViewModel() -> DashboardViewModel {
        let useCase = FetchDevicesUseCase(repository: deviceRepository)
        return DashboardViewModel(fetchDevicesUseCase: useCase)
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
}
