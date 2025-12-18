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

    private(set) var isAuthorized = false

    /// Инициализатор
    init() {
        // При инициализации статус авторизации неизвестен, устанавливаем false
        // Статус будет обновлен при получении команды от iPhone через WatchConnectivity
        self.isAuthorized = false
    }

    /// Проверка статуса авторизации
    ///
    /// Возвращает текущий статус авторизации (обновляется через WatchConnectivity)
    /// - Returns: `true` если пользователь авторизован, `false` в противном случае
    func checkAuthStatus() -> Bool {
        let result = isAuthorized
        logger.debug("Проверка статуса авторизации: \(result)")
        return result
    }

    /// Обновление статуса авторизации
    ///
    /// Вызывается при получении команды `PHONE_COMMAND_AUTH_STATUS` от iPhone через WatchConnectivity
    /// - Parameter isAuthorized: Новый статус авторизации
    func updateAuthStatus(_ isAuthorized: Bool) {
        logger.info("Обновление статуса авторизации: \(isAuthorized)")
        self.isAuthorized = isAuthorized
    }
}
