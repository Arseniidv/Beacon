import Foundation

enum AuthError: LocalizedError, Equatable {
    case emptyFields
    case invalidEmail
    case weakPassword
    case passwordMismatch
    case emailAlreadyExists
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Заполните все поля"
        case .invalidEmail:
            return "Введите корректный email"
        case .weakPassword:
            return "Пароль должен содержать не менее 6 символов"
        case .passwordMismatch:
            return "Пароли не совпадают"
        case .emailAlreadyExists:
            return "Аккаунт с таким email уже существует"
        case .invalidCredentials:
            return "Неверный email или пароль"
        }
    }
}
