import Foundation
@testable import SwiftUI_SotkaApp
import Testing
import WatchConnectivity

@MainActor
@Suite("Тесты для WatchConnectivityManagerProtocol")
struct WatchConnectivityManagerProtocolTests {
    @Test("Должен отправлять сообщение через WCSession")
    func shouldSendMessageThroughWCSession() throws {
        let mockSession = MockWCSession(isReachable: true)
        let manager = WatchConnectivityManager(sessionProtocol: mockSession)

        var replyReceived: [String: Any]?
        var errorReceived: Error?

        let testMessage: [String: Any] = ["command": "test", "value": 123]

        manager.sendMessage(
            testMessage,
            replyHandler: { reply in
                replyReceived = reply
            },
            errorHandler: { error in
                errorReceived = error
            }
        )

        #expect(mockSession.sentMessages.count == 1)
        let sentMessage = try #require(mockSession.sentMessages.first)
        let command = try #require(sentMessage["command"] as? String)
        #expect(command == "test")
        let value = try #require(sentMessage["value"] as? Int)
        #expect(value == 123)

        #expect(replyReceived != nil)
        #expect(errorReceived == nil)
    }

    @Test("Должен возвращать isReachable из WCSession")
    func shouldReturnIsReachableFromWCSession() throws {
        let mockSessionReachable = MockWCSession(isReachable: true)
        let managerReachable = WatchConnectivityManager(sessionProtocol: mockSessionReachable)
        #expect(managerReachable.isReachable)

        let mockSessionUnreachable = MockWCSession(isReachable: false)
        let managerUnreachable = WatchConnectivityManager(sessionProtocol: mockSessionUnreachable)
        #expect(!managerUnreachable.isReachable)
    }

    @Test("Должен вызывать errorHandler при ошибке отправки")
    func shouldCallErrorHandlerOnSendError() throws {
        let mockSession = MockWCSession(isReachable: true)
        mockSession.shouldSucceed = false
        mockSession.mockError = WatchConnectivityError.sessionUnavailable

        let manager = WatchConnectivityManager(sessionProtocol: mockSession)

        var errorReceived: Error?
        var replyReceived: [String: Any]?

        let testMessage: [String: Any] = ["command": "test"]

        manager.sendMessage(
            testMessage,
            replyHandler: { reply in
                replyReceived = reply
            },
            errorHandler: { error in
                errorReceived = error
            }
        )

        let error = try #require(errorReceived)
        #expect(error.localizedDescription.contains("недоступна"))
        #expect(replyReceived == nil)
    }

    @Test("Должен вызывать errorHandler когда сессия недоступна")
    func shouldCallErrorHandlerWhenSessionUnreachable() throws {
        let mockSession = MockWCSession(isReachable: false)
        let manager = WatchConnectivityManager(sessionProtocol: mockSession)

        var errorReceived: Error?
        var replyReceived: [String: Any]?

        let testMessage: [String: Any] = ["command": "test"]

        manager.sendMessage(
            testMessage,
            replyHandler: { reply in
                replyReceived = reply
            },
            errorHandler: { error in
                errorReceived = error
            }
        )

        let error = try #require(errorReceived)
        #expect(error.localizedDescription.contains("недоступна"))
        #expect(replyReceived == nil)
        #expect(mockSession.sentMessages.isEmpty)
    }

    @Test("Должен возвращать false для isReachable когда sessionProtocol равен nil")
    func shouldReturnFalseForIsReachableWhenSessionProtocolIsNil() throws {
        let nilSession: WCSessionProtocol? = nil
        let manager = WatchConnectivityManager(sessionProtocol: nilSession)
        #expect(!manager.isReachable)
    }
}
