import Foundation
import Observation
import OSLog

/// Сервис для управления авторизацией на Apple Watch
@MainActor
@Observable
final class WatchAuthService {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaWatch",
        category: String(describing: WatchAuthService.self)
    )

    @ObservationIgnored private let defaults: UserDefaults?

    private(set) var isAuthorized = false

    /// Инициализатор с возможностью передачи UserDefaults для тестирования
    /// - Parameter userDefaults: UserDefaults для использования. Если `nil`, используется App Group UserDefaults
    init(userDefaults: UserDefaults? = nil) {
        if let userDefaults {
            self.defaults = userDefaults
        } else {
            self.defaults = UserDefaults(suiteName: Constants.appGroupIdentifier)
        }
        self.isAuthorized = checkAuthStatus()
    }

    /// Чтение статуса авторизации напрямую из App Group UserDefaults
    /// - Returns: `true` если пользователь авторизован, `false` в противном случае
    func checkAuthStatus() -> Bool {
        guard let defaults else {
            logger.warning("App Group '\(Constants.appGroupIdentifier)' недоступен, возвращаем false для статуса авторизации")
            isAuthorized = false
            return false
        }

        let isAuthorized = defaults.bool(forKey: Constants.isAuthorizedKey)
        logger.debug("Прочитан статус авторизации из App Group: \(isAuthorized)")
        self.isAuthorized = isAuthorized
        return isAuthorized
    }

    /// Обновление статуса авторизации
    ///
    /// Вызывается при получении команды `PHONE_COMMAND_AUTH_STATUS_CHANGED` или при проверке при активации приложения
    /// - Parameter isAuthorized: Новый статус авторизации
    func updateAuthStatus(_ isAuthorized: Bool) {
        logger.info("Обновление статуса авторизации: \(isAuthorized)")
        self.isAuthorized = isAuthorized
    }
}
