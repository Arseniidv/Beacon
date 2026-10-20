import Foundation
import Combine

enum AuthScreenMode: String, CaseIterable {
    case login = "Вход"
    case register = "Регистрация"
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var mode: AuthScreenMode = .login
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let loginUseCase: LoginUseCaseProtocol
    private let registerUseCase: RegisterUseCaseProtocol
    private let session: AuthSessionStore

    init(
        loginUseCase: LoginUseCaseProtocol,
        registerUseCase: RegisterUseCaseProtocol,
        session: AuthSessionStore
    ) {
        self.loginUseCase = loginUseCase
        self.registerUseCase = registerUseCase
        self.session = session
    }

    var primaryActionTitle: String {
        mode == .login ? "Войти" : "Создать аккаунт"
    }

    func submit() {
        errorMessage = nil

        do {
            try validate()
            isLoading = true
            let user: UserAccount
            switch mode {
            case .login:
                user = try loginUseCase.execute(email: email, password: password)
            case .register:
                user = try registerUseCase.execute(name: name, email: email, password: password)
            }
            session.apply(user)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func switchMode(to newMode: AuthScreenMode) {
        guard mode != newMode else { return }
        mode = newMode
        errorMessage = nil
        password = ""
        confirmPassword = ""
    }

    func authenticateWithGoogle() {
        // TODO: Implement Google Sign-In
        errorMessage = "Google Sign-In ещё не реализован"
    }

    func authenticateWithApple() {
        // TODO: Implement Apple Sign-In
        errorMessage = "Apple Sign-In ещё не реализован"
    }

    private func validate() throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty || trimmedPassword.isEmpty {
            throw AuthError.emptyFields
        }

        if mode == .register {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedName.isEmpty || confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw AuthError.emptyFields
            }
            if password != confirmPassword {
                throw AuthError.passwordMismatch
            }
        }

        guard isValidEmail(trimmedEmail) else {
            throw AuthError.invalidEmail
        }

        guard trimmedPassword.count >= 6 else {
            throw AuthError.weakPassword
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return value.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
