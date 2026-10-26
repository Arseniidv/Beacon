import SwiftUI
import Combine
import Foundation

struct UserData {
    let name: String
    let avatar: String?
    let role: String
    let email: String
    var isNotificationOn: Bool

    var roleDisplayName: String {
        let userRole = UserRole(rawValue: role) ?? .user
        switch userRole {
        case .admin:
            return "Администратор"
        case .user:
            return "Пользователь"
        }
    }

    var isAdmin: Bool {
        UserRole(rawValue: role) == .admin
    }
}


@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - AppStorage & Published Properties
    @AppStorage("isDarkModeOn") var isDarkModeOn = true

    @Published var user: UserData
    @Published var isLoading = false
    @Published private(set) var bluetoothDevices: [BluetoothDevice] = []

    // MARK: - Private Dependencies & Combine
    private let bluetoothService: BluetoothServiceProtocol
    private let session: AuthSessionStore

    // ИСПРАВЛЕНИЕ: Только ОДНО объявление переменной для подписок Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Unified Initialization
    // ИСПРАВЛЕНИЕ: Единственный общий конструктор, который корректно принимает обе зависимости
    init(session: AuthSessionStore, bluetoothService: BluetoothServiceProtocol) {
        self.session = session
        self.bluetoothService = bluetoothService

        // Сначала настраиваем данные пользователя на основе текущей сессии
        self.user = Self.userData(from: session.currentUser)

        // Затем безопасно запускаем подписки на обновления потоков данных
        setupSubscriptions()
    }

    func toggleNotifications() {
        user.isNotificationOn.toggle()
    }

    func logout() {
        session.logout()
    }

    private func setupSubscriptions() {
        session.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] account in
                self?.user = Self.userData(from: account)
            }
            .store(in: &cancellables)
        bluetoothService.devices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                self?.bluetoothDevices = devices
            }
            .store(in: &cancellables)
    }

    // MARK: - Mapping Helper
    private static func userData(from account: UserAccount?) -> UserData {
        let accountRole = UserRole(rawValue: account?.role ?? "") ?? .user

        return UserData(
            name: account?.name ?? "Пользователь (\(accountRole.rawValue))",
            avatar: nil,
            role: accountRole.rawValue,
            email: account?.email ?? "",
            isNotificationOn: true
        )
    }

}
