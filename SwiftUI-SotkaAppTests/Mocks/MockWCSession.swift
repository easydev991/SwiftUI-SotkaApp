import Foundation
@testable import SwiftUI_SotkaApp
import WatchConnectivity

/// Мок для WCSession для тестирования WatchConnectivityManager на iPhone
@MainActor
final class MockWCSession: WCSessionProtocol {
    var isReachable: Bool
    weak var delegate: WCSessionDelegate?

    var shouldSucceed = true
    var mockError: Error?
    var mockReply: [String: Any]?

    private(set) var sentMessages: [[String: Any]] = []
    private(set) var receivedMessages: [[String: Any]] = []
    private(set) var activateCallCount = 0

    init(isReachable: Bool = true) {
        self.isReachable = isReachable
    }

    func activate() {
        activateCallCount += 1
    }

    func sendMessageToWatch(
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

    func simulateReceivedMessage(_ message: [String: Any]) {
        receivedMessages.append(message)
        // В новых тестах мы вызываем методы обработки напрямую через очередь
        // Этот метод оставлен для обратной совместимости, но не используется
        // в обновленных тестах, которые работают через pendingRequests
    }

    func simulateReceivedMessageWithReply(
        _ message: [String: Any],
        replyHandler _: @escaping ([String: Any]) -> Void
    ) {
        receivedMessages.append(message)
        // В новых тестах мы вызываем методы обработки напрямую через очередь
        // Этот метод оставлен для обратной совместимости, но не используется
        // в обновленных тестах, которые работают через pendingRequests
        // replyHandler будет вызван после обработки запроса из очереди
    }
}

/// Ошибки WatchConnectivity для iPhone
enum WatchConnectivityError: LocalizedError {
    case sessionUnavailable
    case serializationError
    case deserializationError
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .sessionUnavailable:
            "Сессия WatchConnectivity недоступна"
        case .serializationError:
            "Ошибка сериализации данных"
        case .deserializationError:
            "Ошибка десериализации данных"
        case .invalidResponse:
            "Неверный формат ответа от часов"
        }
    }
}
