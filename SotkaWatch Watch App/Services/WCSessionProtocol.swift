import Foundation
import WatchConnectivity

/// Протокол для абстракции WCSession для тестирования на Apple Watch
@MainActor
protocol WatchSessionProtocol: AnyObject {
    var isReachable: Bool { get }
    var delegate: WCSessionDelegate? { get set }
    var receivedApplicationContext: [String: Any] { get }

    func activate()
    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    )
}

/// WCSession соответствует протоколу, так как имеет все необходимые методы и свойства
extension WCSession: WatchSessionProtocol {}
