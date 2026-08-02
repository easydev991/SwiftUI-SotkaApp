import Foundation
import Observation

@MainActor
protocol AuthHelper: AnyObject, Sendable {
    /// Статус авторизации
    var isAuthorized: Bool { get }
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

    func performOfflineLogin() {
        isAuthorized = true
    }

    func triggerLogout() {
        isAuthorized = false
    }
}
