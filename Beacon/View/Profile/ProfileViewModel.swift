
import SwiftUI
import Combine
import Foundation

struct UserData {
    let name: String
    let avatar: String?
    let role: String
    let email: String
    var isNotificationOn: Bool
}

final class ProfileViewModel: ObservableObject {

    // MARK: - Settings

    @AppStorage("isDarkModeOn")
    var isDarkModeOn = true

    // MARK: - User

    @Published var user: UserData

    @Published var isLoading = false

    // MARK: - Initialization

    init() {
        self.user = UserData(
            name: "Arseniy",
            avatar: nil,
            role: "Administrator",
            email: "arseniidvornichenko@gmail.com",
            isNotificationOn: true
        )
    }

    // MARK: - Actions

    func toggleNotifications() {
        user.isNotificationOn.toggle()
    }

    func logout() {
        print("Выход из профиля...")
    }
}
