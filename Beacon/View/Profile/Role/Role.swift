import Foundation

struct Role: Codable {
    let id: UUID
    let name: String
    let email: String
    let role: UserRole
}

enum UserRole: String, Codable {
    case admin = "admin"
    case user = "user"

    var isAdmin: Bool {
        return self == .admin
    }
}

