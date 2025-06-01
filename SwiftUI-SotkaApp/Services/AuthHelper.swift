import Foundation
import Observation
import SWKeychain

@MainActor
protocol AuthHelper: AnyObject, Sendable {
    /// Токен авторизации для запросов к серверу
    var authToken: String? { get }
    /// Логаут с удалением всех данных пользователя
    func triggerLogout()
}

@MainActor
@Observable
final class AuthHelperImp: AuthHelper {
    private let defaults = UserDefaults.standard

    @ObservationIgnored
    @KeychainWrapper(Key.authData.rawValue)
    private var authData: AuthData?

    private(set) var isAuthorized: Bool {
        get {
            access(keyPath: \.isAuthorized)
            return defaults.bool(forKey: Key.isAuthorized.rawValue)
        }
        set {
            withMutation(keyPath: \.isAuthorized) {
                defaults.set(newValue, forKey: Key.isAuthorized.rawValue)
            }
        }
    }

    var authToken: String? { authData?.token }

    func saveAuthData(_ authData: AuthData) {
        self.authData = authData
    }

    func updateAuthData(login: String, newPassword: String? = nil) {
        let updatedModel: AuthData? = if let newPassword {
            AuthData(login: login, password: newPassword)
        } else if let currentPassword = authData?.password {
            AuthData(login: login, password: currentPassword)
        } else {
            nil
        }
        guard let updatedModel else { return }
        saveAuthData(updatedModel)
    }

    func didAuthorize() {
        isAuthorized = true
    }

    func triggerLogout() {
        authData = nil
        isAuthorized = false
    }
}

private extension AuthHelperImp {
    enum Key: String {
        case authData
        case isAuthorized
    }
}
