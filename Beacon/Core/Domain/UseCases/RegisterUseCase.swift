import Foundation

protocol RegisterUseCaseProtocol {
    func execute(name: String, email: String, password: String) throws -> UserAccount
}

final class RegisterUseCase: RegisterUseCaseProtocol {
    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    func execute(name: String, email: String, password: String) throws -> UserAccount {
        try repository.register(name: name, email: email, password: password)
    }
}
