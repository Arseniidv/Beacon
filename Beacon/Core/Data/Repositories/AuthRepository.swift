import Foundation
import CryptoKit

final class AuthRepository: AuthRepositoryProtocol {
    private let accountsKey = "beacon.auth.accounts"
    private let sessionKey = "beacon.auth.sessionUserId"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func login(email: String, password: String) throws -> UserAccount {
        let normalizedEmail = Self.normalize(email)
        guard let stored = loadAccounts().first(where: { $0.account.email == normalizedEmail }) else {
            throw AuthError.invalidCredentials
        }

        let hash = Self.hash(password: password, salt: stored.salt)
        guard hash == stored.passwordHash else {
            throw AuthError.invalidCredentials
        }

        saveSession(userId: stored.account.id)
        return stored.account
    }

    func register(name: String, email: String, password: String) throws -> UserAccount {
        let normalizedEmail = Self.normalize(email)
        var accounts = loadAccounts()

        if accounts.contains(where: { $0.account.email == normalizedEmail }) {
            throw AuthError.emailAlreadyExists
        }

        let salt = UUID().uuidString
        let account = UserAccount(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: normalizedEmail,
            role: accounts.isEmpty ? "admin" : "user"
        )
        let stored = StoredAccount(
            account: account,
            passwordHash: Self.hash(password: password, salt: salt),
            salt: salt
        )

        accounts.append(stored)
        saveAccounts(accounts)
        saveSession(userId: account.id)
        return account
    }

    /// Вход через Google. Пароль у таких аккаунтов не задаётся, поэтому
    /// passwordHash остаётся пустым и обычный вход по паролю для них невозможен.
    func authenticateExternal(email: String, name: String) throws -> UserAccount {
        let normalizedEmail = Self.normalize(email)
        var accounts = loadAccounts()

        if let existing = accounts.first(where: { $0.account.email == normalizedEmail }) {
            saveSession(userId: existing.account.id)
            return existing.account
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let account = UserAccount(
            name: trimmedName.isEmpty ? normalizedEmail : trimmedName,
            email: normalizedEmail,
            role: accounts.isEmpty ? "admin" : "user"
        )
        accounts.append(StoredAccount(account: account, passwordHash: "", salt: ""))
        saveAccounts(accounts)
        saveSession(userId: account.id)

        return account
    }

    func loadSession() -> UserAccount? {
        guard let idString = defaults.string(forKey: sessionKey),
              let id = UUID(uuidString: idString) else {
            return nil
        }
        return loadAccounts().first(where: { $0.account.id == id })?.account
    }

    func clearSession() {
        defaults.removeObject(forKey: sessionKey)
    }

    func fetchAccounts() -> [UserAccount] {
        loadAccounts().map(\.account)
    }

    func updateRole(userId: UUID, role: UserRole) -> UserAccount? {
        var accounts = loadAccounts()

        guard let index = accounts.firstIndex(where: { $0.account.id == userId }) else {
            return nil
        }

        let stored = accounts[index]
        let updatedAccount = UserAccount(
            id: stored.account.id,
            name: stored.account.name,
            email: stored.account.email,
            role: role.rawValue
        )
        accounts[index] = StoredAccount(
            account: updatedAccount,
            passwordHash: stored.passwordHash,
            salt: stored.salt
        )
        saveAccounts(accounts)

        return updatedAccount
    }

    private func saveSession(userId: UUID) {
        defaults.set(userId.uuidString, forKey: sessionKey)
    }

    private func loadAccounts() -> [StoredAccount] {
        guard let data = defaults.data(forKey: accountsKey),
              let accounts = try? JSONDecoder().decode([StoredAccount].self, from: data) else {
            return []
        }
        return accounts
    }

    private func saveAccounts(_ accounts: [StoredAccount]) {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        defaults.set(data, forKey: accountsKey)
    }

    private static func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func hash(password: String, salt: String) -> String {
        let bytes = Data((salt + password).utf8)
        return SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }
}

private struct StoredAccount: Codable {
    let account: UserAccount
    let passwordHash: String
    let salt: String
}
