import Foundation

protocol AuthRepositoryProtocol {
    func login(email: String, password: String) throws -> UserAccount
    func register(name: String, email: String, password: String) throws -> UserAccount
    /// Вход через внешнего провайдера (Google): аккаунт создаётся при первом входе.
    func authenticateExternal(email: String, name: String) throws -> UserAccount
    func loadSession() -> UserAccount?
    func clearSession()

    /// Все зарегистрированные аккаунты — для админ-панели.
    func fetchAccounts() -> [UserAccount]
    /// Меняет роль пользователя и сохраняет изменение. Возвращает обновлённый аккаунт.
    func updateRole(userId: UUID, role: UserRole) -> UserAccount?
}
