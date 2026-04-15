import Foundation
import Observation
import OSLog
import SWKeychain

@MainActor
protocol AuthHelper: AnyObject, Sendable {
    /// Токен авторизации для запросов к серверу
    var authToken: String? { get }
    /// Статус авторизации
    var isAuthorized: Bool { get }
    /// Флаг офлайн-пользователя
    var isOfflineOnly: Bool { get }
    /// Логаут с удалением всех данных пользователя
    func triggerLogout()
    /// Офлайн-авторизация без серверных кредов
    func performOfflineLogin()
}

@MainActor
@Observable
final class AuthHelperImp: AuthHelper {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaApp",
        category: String(describing: AuthHelperImp.self)
    )
    @ObservationIgnored private let defaults: UserDefaults

    @ObservationIgnored
    @KeychainWrapper(Key.authData.rawValue)
    private var authData: AuthData?

    init(userDefaults: UserDefaults? = nil) {
        if let userDefaults {
            self.defaults = userDefaults
        } else {
            self.defaults = UserDefaults.standard
        }
    }

    private(set) var isAuthorized: Bool {
        get {
            access(keyPath: \.isAuthorized)
            return defaults.bool(forKey: Constants.isAuthorizedKey)
        }
        set {
            withMutation(keyPath: \.isAuthorized) {
                defaults.set(newValue, forKey: Constants.isAuthorizedKey)
            }
        }
    }

    private(set) var isOfflineOnly: Bool {
        get {
            access(keyPath: \.isOfflineOnly)
            return defaults.bool(forKey: Constants.isOfflineOnlyKey)
        }
        set {
            withMutation(keyPath: \.isOfflineOnly) {
                defaults.set(newValue, forKey: Constants.isOfflineOnlyKey)
            }
        }
    }

    var authToken: String? {
        authData?.token
    }

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
        isOfflineOnly = false
    }

    func performOfflineLogin() {
        authData = nil
        isOfflineOnly = true
        isAuthorized = true
    }

    func triggerLogout() {
        authData = nil
        isAuthorized = false
        isOfflineOnly = false
    }
}

private extension AuthHelperImp {
    enum Key: String {
        case authData
    }
}
