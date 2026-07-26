import Foundation
import Observation

@MainActor
protocol AuthHelper: AnyObject, Sendable {
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
    @ObservationIgnored private let defaults: UserDefaults

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

    func performOfflineLogin() {
        isOfflineOnly = true
        isAuthorized = true
    }

    func triggerLogout() {
        isAuthorized = false
        isOfflineOnly = false
    }
}
