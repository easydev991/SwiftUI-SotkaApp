import Foundation
import WatchConnectivity

/// Протокол для абстракции WCSession для тестирования
@MainActor
protocol WCSessionProtocol: AnyObject {
    var isReachable: Bool { get }
    var delegate: WCSessionDelegate? { get set }

    func activate()
    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    )
}

/// WCSession соответствует протоколу, так как имеет все необходимые методы и свойства
extension WCSession: WCSessionProtocol {}
