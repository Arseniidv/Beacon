import Foundation
import GoogleSignIn

#if os(iOS)
import UIKit
#endif

/// Вход через Google поверх официального SDK GoogleSignIn.
///
/// Client ID читается из GoogleService-Info.plist, поэтому при замене файла
/// на новый (после включения провайдера в Firebase) править код не нужно.
final class GoogleAuthService: GoogleAuthServiceProtocol {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func signIn() async throws -> GoogleProfile {
        #if os(iOS)
        let clientID = try clientID()
        try validateCallbackScheme(for: clientID)

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        let result: GIDSignInResult
        do {
            result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: try presentingViewController()
            )
        } catch {
            if (error as NSError).code == GIDSignInError.canceled.rawValue {
                throw GoogleAuthError.canceled
            }
            throw error
        }
        let user = result.user

        guard let email = user.profile?.email, !email.isEmpty else {
            throw GoogleAuthError.missingProfile
        }

        return GoogleProfile(
            userID: user.userID ?? email,
            email: email,
            name: user.profile?.name ?? email,
            idToken: user.idToken?.tokenString
        )
        #else
        throw GoogleAuthError.unsupportedPlatform
        #endif
    }

    #if os(iOS)

    // MARK: - Конфигурация

    private func clientID() throws -> String {
        guard let url = bundle.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let clientID = plist["CLIENT_ID"] as? String,
              !clientID.isEmpty else {
            throw GoogleAuthError.notConfigured
        }
        return clientID
    }

    /// SDK бросает NSException, если в Info.plist нет схемы реверс-Client ID,
    /// поэтому проверяем схему сами и отдаём понятную ошибку вместо падения.
    private func validateCallbackScheme(for clientID: String) throws {
        let reversedClientID = clientID
            .components(separatedBy: ".")
            .reversed()
            .joined(separator: ".")

        let urlTypes = bundle.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
        let schemes = urlTypes
            .compactMap { $0["CFBundleURLSchemes"] as? [String] }
            .flatMap { $0 }
            .map { $0.lowercased() }

        guard schemes.contains(reversedClientID.lowercased()) else {
            throw GoogleAuthError.missingURLScheme(reversedClientID)
        }
    }

    private func presentingViewController() throws -> UIViewController {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        let rootViewController = windowScenes
            .first { $0.activationState == .foregroundActive }?
            .keyWindow?
            .rootViewController
            ?? windowScenes.first?.keyWindow?.rootViewController

        guard let rootViewController else {
            throw GoogleAuthError.noPresentingController
        }
        return rootViewController
    }

    #endif
}
