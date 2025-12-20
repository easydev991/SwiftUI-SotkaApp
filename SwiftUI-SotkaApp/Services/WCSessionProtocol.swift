import Foundation
import WatchConnectivity

/// Протокол для абстракции WCSession для тестирования на iPhone
@MainActor
protocol WCSessionProtocol: AnyObject {
    var isReachable: Bool { get }
    var delegate: WCSessionDelegate? { get set }

    func activate()
    func sendMessageToWatch(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    )
    func updateApplicationContextOnWatch(_ applicationContext: [String: Any])
}

/// WCSession соответствует протоколу
extension WCSession: WCSessionProtocol {
    func sendMessageToWatch(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
        sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    func updateApplicationContextOnWatch(_ applicationContext: [String: Any]) {
        // WCSession уже имеет метод updateApplicationContext с throws
        // Используем существующий метод напрямую, обернув в do-catch
        do {
            try updateApplicationContext(applicationContext)
        } catch {
            // Игнорируем ошибки при обновлении applicationContext
        }
    }
}
