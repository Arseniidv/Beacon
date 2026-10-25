import Foundation

/// Профиль, который Google возвращает после успешного входа.
struct GoogleProfile: Equatable {
    let userID: String
    let email: String
    let name: String
    let idToken: String?
}

protocol GoogleAuthServiceProtocol {
    /// Показывает системный экран входа Google и возвращает профиль пользователя.
    func signIn() async throws -> GoogleProfile
}

enum GoogleAuthError: LocalizedError, Equatable {
    /// В GoogleService-Info.plist нет CLIENT_ID — провайдер Google не настроен в Firebase.
    case notConfigured
    /// В Info.plist нет схемы реверс-Client ID.
    case missingURLScheme(String)
    case missingProfile
    case noPresentingController
    case unsupportedPlatform
    case canceled

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Google Sign-In не настроен: в GoogleService-Info.plist нет CLIENT_ID"
        case .missingURLScheme(let scheme):
            return "В Info.plist не добавлена URL-схема \(scheme)"
        case .missingProfile:
            return "Google не вернул данные профиля"
        case .noPresentingController:
            return "Не удалось показать экран входа Google"
        case .unsupportedPlatform:
            return "Google Sign-In доступен только на iPhone и iPad"
        case .canceled:
            return "Вход через Google отменён"
        }
    }
}
