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
    @AppStorage("isDarkModeOn") var isDarkModeOn = false
    @Published var user: UserData
    @Published var isLoading = false
    @Published private(set) var bluetoothDevices: [BluetoothDevice] = []

    private let bluetoothService: BluetoothServiceProtocol
    private let session: AuthSessionStore
    private var cancellables = Set<AnyCancellable>()
    
    init(session: AuthSessionStore, bluetoothService: BluetoothServiceProtocol) {
        self.session = session
        self.bluetoothService = bluetoothService
        self.user = Self.userData(from: session.currentUser)
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
