import Foundation
import Combine

@MainActor
final class AuthSessionStore: ObservableObject {
    @Published private(set) var currentUser: UserAccount?

    var isAuthenticated: Bool {
        currentUser != nil
    }

    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
        self.currentUser = repository.loadSession()
    }

    func apply(_ user: UserAccount) {
        currentUser = user
    }

    func logout() {
        repository.clearSession()
        currentUser = nil
    }

    /// Перечитывает текущего пользователя — например, после смены его роли.
    func refreshCurrentUser() {
        currentUser = repository.loadSession()
    }
}
