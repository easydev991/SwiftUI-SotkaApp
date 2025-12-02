import Foundation
@testable import SotkaWatch_Watch_App
import WatchConnectivity

/// Мок для WCSession для тестирования
@MainActor
final class MockWCSession: WCSessionProtocol {
    var isReachable: Bool
    weak var delegate: WCSessionDelegate?

    // Настройки поведения для тестов
    var shouldSucceed = true
    var mockError: Error?
    var mockReply: [String: Any]?

    // Отслеживание вызовов для тестов
    private(set) var sentMessages: [[String: Any]] = []
    private(set) var activateCallCount = 0

    init(isReachable: Bool = true) {
        self.isReachable = isReachable
    }

    func activate() {
        activateCallCount += 1
    }

    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
        sentMessages.append(message)

        if shouldSucceed {
            if let replyHandler, let mockReply {
                replyHandler(mockReply)
            } else if let replyHandler {
                replyHandler([:])
            }
        } else {
            let error = mockError ?? WatchConnectivityError.sessionUnavailable
            errorHandler?(error)
        }
    }
}
