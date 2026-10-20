import Foundation

protocol AuthRepositoryProtocol {
    func login(email: String, password: String) throws -> UserAccount
    func register(name: String, email: String, password: String) throws -> UserAccount
    func loadSession() -> UserAccount?
    func clearSession()
}
