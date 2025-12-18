import Foundation
import OSLog
import WatchConnectivity

/// Простой сервис для отправки данных на Apple Watch через WatchConnectivity
///
/// Делегатом является StatusManager
@MainActor
struct WatchConnectivityManager: WatchConnectivityManagerProtocol {
    private let sessionProtocol: WCSessionProtocol?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SwiftUI_SotkaApp",
        category: "WatchConnectivityManager"
    )

    /// Инициализатор
    /// - Parameter sessionProtocol: Протокол сессии для тестирования. Если `nil`, используется `WCSession.default` (если поддерживается),
    /// иначе `nil`
    init(sessionProtocol: WCSessionProtocol? = nil) {
        if let sessionProtocol {
            self.sessionProtocol = sessionProtocol
        } else if WCSession.isSupported() {
            self.sessionProtocol = WCSession.default
        } else {
            self.sessionProtocol = nil
            logger.debug("WCSession не поддерживается на этом устройстве")
        }
    }

    /// Проверяет, доступны ли часы для отправки сообщений
    var isReachable: Bool {
        sessionProtocol?.isReachable ?? false
    }

    /// Отправляет сообщение на часы
    /// - Parameters:
    ///   - message: Сообщение для отправки
    ///   - replyHandler: Обработчик ответа от часов (опционально)
    ///   - errorHandler: Обработчик ошибки (опционально)
    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
        guard let sessionProtocol else {
            logger.debug("WCSession не поддерживается на этом устройстве")
            errorHandler?(WatchConnectivityError.unsupported)
            return
        }

        guard sessionProtocol.isReachable else {
            logger.debug("Часы недоступны для отправки сообщения")
            errorHandler?(WatchConnectivityError.unreachable)
            return
        }

        sessionProtocol.sendMessage(
            message,
            replyHandler: replyHandler,
            errorHandler: { error in
                logger.error("Ошибка отправки сообщения на часы: \(error.localizedDescription)")
                errorHandler?(error)
            }
        )
    }
}

extension WatchConnectivityManager {
    /// Ошибки WatchConnectivity
    enum WatchConnectivityError: LocalizedError {
        case unsupported, unreachable

        var errorDescription: String? {
            switch self {
            case .unsupported:
                "WCSession не поддерживается на этом устройстве"
            case .unreachable:
                "Сессия WatchConnectivity недоступна"
            }
        }
    }
}
