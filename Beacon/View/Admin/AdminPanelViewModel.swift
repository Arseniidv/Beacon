import Foundation
import Combine

@MainActor
final class AdminPanelViewModel: ObservableObject {
    @Published private(set) var users: [UserAccount] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isMaintenanceMode = false

    /// Текущие настройки сканирования — общие для карты и списка устройств.
    @Published private(set) var scanSettings: ScanSettings
    /// Текст подсети из поля ввода: может быть невалидным до исправления.
    @Published var subnetDraft: String
    /// Результат проверки введённой подсети.
    @Published private(set) var isSubnetValid = true

    private let authRepository: AuthRepositoryProtocol
    private let session: AuthSessionStore
    private let settingsStore: ScanSettingsStore

    init(
        authRepository: AuthRepositoryProtocol,
        session: AuthSessionStore,
        settingsStore: ScanSettingsStore
    ) {
        self.authRepository = authRepository
        self.session = session
        self.settingsStore = settingsStore
        self.scanSettings = settingsStore.settings
        self.subnetDraft = settingsStore.settings.subnet
    }

    // MARK: - Пользователи

    func loadUsers() {
        isLoading = true
        users = authRepository.fetchAccounts()
        isLoading = false
    }

    func toggleUserRole(_ user: UserAccount) {
        let newRole: UserRole = user.isAdmin ? .user : .admin

        // Последнего администратора нельзя понизить — иначе доступ в админку будет потерян.
        if newRole == .user && adminCount <= 1 && user.isAdmin {
            errorMessage = "Нельзя снять права с единственного администратора"
            return
        }

        guard let updated = authRepository.updateRole(userId: user.id, role: newRole) else {
            errorMessage = "Не удалось изменить роль пользователя"
            return
        }

        errorMessage = nil

        if let index = users.firstIndex(where: { $0.id == updated.id }) {
            users[index] = updated
        }

        // Если админ изменил свою роль — обновляем сессию, чтобы пересчитался доступ.
        if session.currentUser?.id == updated.id {
            session.refreshCurrentUser()
        }
    }

    var adminCount: Int {
        users.filter(\.isAdmin).count
    }

    func toggleMaintenanceMode() {
        isMaintenanceMode.toggle()
    }

    // MARK: - Настройки сканирования

    func updateSubnet(_ value: String) {
        subnetDraft = value
        isSubnetValid = ScanSettings.isValidSubnet(value)

        guard isSubnetValid else {
            errorMessage = "Подсеть должна быть в формате 192.168.1.0/24"
            return
        }

        errorMessage = nil
        settingsStore.settings.subnet = value
        syncScanSettings()
    }

    func setPingTimeout(_ seconds: Double) {
        settingsStore.settings.pingTimeoutSeconds = seconds
        syncScanSettings()
    }

    func setAutoRefreshInterval(_ seconds: Double) {
        settingsStore.settings.autoRefreshIntervalSeconds = seconds
        syncScanSettings()
    }

    func setSource(_ source: ScanSource, isEnabled: Bool) {
        switch source {
        case .localSignal: settingsStore.settings.isLocalSignalEnabled = isEnabled
        case .wifi: settingsStore.settings.isWiFiEnabled = isEnabled
        case .bluetooth: settingsStore.settings.isBluetoothEnabled = isEnabled
        }
        syncScanSettings()
    }

    func resetScanSettings() {
        settingsStore.reset()
        syncScanSettings()
        subnetDraft = settingsStore.settings.subnet
        isSubnetValid = true
        errorMessage = nil
    }

    private func syncScanSettings() {
        scanSettings = settingsStore.settings
    }
}
