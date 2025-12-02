import Foundation
import Observation
import OSLog
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
            migrateFromStandardUserDefaults(to: userDefaults)
        } else if let appGroupDefaults = UserDefaults(suiteName: Constants.appGroupIdentifier) {
            self.defaults = appGroupDefaults
            migrateFromStandardUserDefaults(to: appGroupDefaults)
        } else {
            logger.error("App Group '\(Constants.appGroupIdentifier)' недоступен, используется стандартный UserDefaults")
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
        case migrationCompleted = "migrationToAppGroupCompleted"
    }

    /// Миграция данных из UserDefaults.standard в App Group UserDefaults
    func migrateFromStandardUserDefaults(to appGroupDefaults: UserDefaults) {
        // Проверяем, была ли уже выполнена миграция
        if appGroupDefaults.bool(forKey: Key.migrationCompleted.rawValue) {
            return
        }
        let standardDefaults = UserDefaults.standard
        let key = Constants.isAuthorizedKey
        let hasDataInStandard = standardDefaults.object(forKey: key) != nil
        let hasDataInAppGroup = appGroupDefaults.object(forKey: key) != nil
        if hasDataInStandard, !hasDataInAppGroup {
            let isAuthorizedValue = standardDefaults.bool(forKey: key)
            appGroupDefaults.set(isAuthorizedValue, forKey: key)
            logger.info("Выполнена миграция статуса авторизации из UserDefaults.standard в App Group: \(isAuthorizedValue)")
        }
        appGroupDefaults.set(true, forKey: Key.migrationCompleted.rawValue)
    }
}
