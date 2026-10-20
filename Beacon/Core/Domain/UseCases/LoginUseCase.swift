import Foundation

protocol LoginUseCaseProtocol {
    func execute(email: String, password: String) throws -> UserAccount
}

final class LoginUseCase: LoginUseCaseProtocol {
    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    func execute(email: String, password: String) throws -> UserAccount {
        try repository.login(email: email, password: password)
    }
}
