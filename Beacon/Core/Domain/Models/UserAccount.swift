import Foundation

struct UserAccount: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let email: String
    let role: String

    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        role: String
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
    }

    var userRole: UserRole {
        UserRole(rawValue: role) ?? .user
    }

    var roleDisplayName: String {
        switch userRole {
        case .admin:
            return "Администратор"
        case .user:
            return "Пользователь"
        }
    }

    var isAdmin: Bool {
        userRole == .admin
    }
}
