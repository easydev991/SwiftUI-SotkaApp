import Foundation

/// Протокол для менеджера связи с Apple Watch
///
/// Используется для тестирования StatusManager
@MainActor
protocol WatchConnectivityManagerProtocol {
    /// Проверяет, доступны ли часы для отправки сообщений
    var isReachable: Bool { get }

    /// Отправляет сообщение на часы
    /// - Parameters:
    ///   - message: Сообщение для отправки
    ///   - replyHandler: Обработчик ответа от часов (опционально)
    ///   - errorHandler: Обработчик ошибки (опционально)
    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    )
}
