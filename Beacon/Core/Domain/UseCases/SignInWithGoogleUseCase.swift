import Foundation

protocol SignInWithGoogleUseCaseProtocol {
    func execute() async throws -> UserAccount
}

final class SignInWithGoogleUseCase: SignInWithGoogleUseCaseProtocol {
    private let authService: GoogleAuthServiceProtocol
    private let repository: AuthRepositoryProtocol

    init(authService: GoogleAuthServiceProtocol, repository: AuthRepositoryProtocol) {
        self.authService = authService
        self.repository = repository
    }

    func execute() async throws -> UserAccount {
        let profile = try await authService.signIn()
        return try repository.authenticateExternal(email: profile.email, name: profile.name)
    }
}
