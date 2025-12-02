import Foundation
@testable import SotkaWatch_Watch_App
import Testing
import WatchConnectivity

@MainActor
struct WatchConnectivityServiceTests {
    @Test("Инициализирует WCSession при создании")
    func initializesWCSessionOnCreation() throws {
        let authService = try WatchAuthService(userDefaults: MockUserDefaults.create())
        let service = WatchConnectivityService(authService: authService)

        #expect(service.session != nil)
    }

    @Test("Обрабатывает команду изменения статуса авторизации от iPhone")
    func handlesAuthStatusChangedCommandFromPhone() throws {
        let userDefaults = try MockUserDefaults.create()
        let authService = WatchAuthService(userDefaults: userDefaults)
        let service = WatchConnectivityService(authService: authService)

        #expect(!authService.isAuthorized)

        let session = try #require(service.session)

        let message: [String: Any] = [
            "command": Constants.WatchCommand.authStatusChanged.rawValue,
            "isAuthorized": true
        ]

        service.session(session, didReceiveMessage: message)

        #expect(authService.isAuthorized)
    }

    @Test("Обрабатывает команду изменения статуса авторизации с replyHandler")
    func handlesAuthStatusChangedCommandWithReplyHandler() throws {
        let userDefaults = try MockUserDefaults.create()
        let authService = WatchAuthService(userDefaults: userDefaults)
        let service = WatchConnectivityService(authService: authService)

        #expect(!authService.isAuthorized)

        let session = try #require(service.session)

        let message: [String: Any] = [
            "command": Constants.WatchCommand.authStatusChanged.rawValue,
            "isAuthorized": true
        ]

        var replyReceived = false
        service.session(session, didReceiveMessage: message) { _ in
            replyReceived = true
        }

        #expect(authService.isAuthorized)
        #expect(replyReceived)
    }

    @Test("Выбрасывает ошибку при отправке типа активности когда сессия недоступна")
    func throwsErrorWhenSessionUnavailableForActivityType() async throws {
        let authService = try WatchAuthService(userDefaults: MockUserDefaults.create())
        let mockSession = MockWCSession(isReachable: false)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        await #expect(throws: WatchConnectivityError.self) {
            try await service.sendActivityType(day: 5, activityType: .workout)
        }
    }

    @Test("Выбрасывает ошибку при отправке результата тренировки когда сессия недоступна")
    func throwsErrorWhenSessionUnavailableForWorkoutResult() async throws {
        let authService = try WatchAuthService(userDefaults: MockUserDefaults.create())
        let mockSession = MockWCSession(isReachable: false)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)
        let result = WorkoutResult(count: 4, duration: 1800)

        await #expect(throws: WatchConnectivityError.self) {
            try await service.sendWorkoutResult(day: 5, result: result, executionType: .cycles)
        }
    }

    @Test("Выбрасывает ошибку при запросе текущей активности когда сессия недоступна")
    func throwsErrorWhenSessionUnavailableForCurrentActivity() async throws {
        let authService = try WatchAuthService(userDefaults: MockUserDefaults.create())
        let mockSession = MockWCSession(isReachable: false)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        await #expect(throws: WatchConnectivityError.self) {
            _ = try await service.requestCurrentActivity(day: 5)
        }
    }

    @Test("Выбрасывает ошибку при запросе данных тренировки когда сессия недоступна")
    func throwsErrorWhenSessionUnavailableForWorkoutData() async throws {
        let authService = try WatchAuthService(userDefaults: MockUserDefaults.create())
        let mockSession = MockWCSession(isReachable: false)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        await #expect(throws: WatchConnectivityError.self) {
            _ = try await service.requestWorkoutData(day: 5)
        }
    }

    @Test("Сериализует и десериализует JSON через Codable")
    func serializesAndDeserializesJSONThroughCodable() throws {
        let result = WorkoutResult(count: 4, duration: 1800)

        let encoder = JSONEncoder()
        let data = try encoder.encode(result)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WorkoutResult.self, from: data)

        #expect(decoded.count == 4)
        let duration = try #require(decoded.duration)
        #expect(duration == 1800)
    }

    // MARK: - Успешные сценарии

    @Test("Успешно отправляет тип активности")
    func successfullySendsActivityType() async throws {
        let authService = try WatchAuthService(userDefaults: MockUserDefaults.create())
        let mockSession = MockWCSession(isReachable: true)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        try await service.sendActivityType(day: 5, activityType: .workout)

        #expect(mockSession.sentMessages.count == 1)
        let message = try #require(mockSession.sentMessages.first)
        #expect(message["command"] as? String == Constants.WatchCommand.setActivity.rawValue)
        #expect(message["day"] as? Int == 5)
        #expect(message["activityType"] as? Int == DayActivityType.workout.rawValue)
    }

    @Test("Успешно отправляет результат тренировки")
    func successfullySendsWorkoutResult() async throws {
        let authService = try WatchAuthService(userDefaults: MockUserDefaults.create())
        let mockSession = MockWCSession(isReachable: true)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)
        let result = WorkoutResult(count: 4, duration: 1800)

        try await service.sendWorkoutResult(day: 5, result: result, executionType: .cycles)

        #expect(mockSession.sentMessages.count == 1)
        let message = try #require(mockSession.sentMessages.first)
        #expect(message["command"] as? String == Constants.WatchCommand.saveWorkout.rawValue)
        #expect(message["day"] as? Int == 5)
        #expect(message["executionType"] as? Int == ExerciseExecutionType.cycles.rawValue)
        let resultJSON = try #require(message["result"] as? [String: Any])
        #expect(resultJSON["count"] as? Int == 4)
    }

    @Test("Успешно запрашивает текущую активность")
    func successfullyRequestsCurrentActivity() async throws {
        let authService = try WatchAuthService(userDefaults: MockUserDefaults.create())
        let mockSession = MockWCSession(isReachable: true)
        mockSession.mockReply = [
            "command": Constants.WatchCommand.currentActivity.rawValue,
            "activityType": DayActivityType.workout.rawValue
        ]
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        let activityType = try await service.requestCurrentActivity(day: 5)

        #expect(mockSession.sentMessages.count == 1)
        let message = try #require(mockSession.sentMessages.first)
        #expect(message["command"] as? String == Constants.WatchCommand.getCurrentActivity.rawValue)
        #expect(message["day"] as? Int == 5)
        let receivedActivityType = try #require(activityType)
        #expect(receivedActivityType == .workout)
    }

    @Test("Возвращает nil при запросе текущей активности если активность не установлена")
    func returnsNilWhenCurrentActivityNotSet() async throws {
        let authService = try WatchAuthService(userDefaults: MockUserDefaults.create())
        let mockSession = MockWCSession(isReachable: true)
        mockSession.mockReply = [
            "command": Constants.WatchCommand.currentActivity.rawValue
        ]
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        let activityType = try await service.requestCurrentActivity(day: 5)

        #expect(activityType == nil)
    }

    @Test("Успешно запрашивает данные тренировки")
    func successfullyRequestsWorkoutData() async throws {
        let authService = try WatchAuthService(userDefaults: MockUserDefaults.create())
        let mockSession = MockWCSession(isReachable: true)

        let trainings = [
            WorkoutPreviewTraining(
                id: "training-1",
                count: 10,
                typeId: 0,
                customTypeId: nil,
                sortOrder: 0
            )
        ]
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: trainings,
            plannedCount: 4
        )

        let encoder = JSONEncoder()
        let workoutDataJSON = try JSONSerialization.jsonObject(with: encoder.encode(workoutData)) as? [String: Any]

        mockSession.mockReply = [
            "command": Constants.WatchCommand.sendWorkoutData.rawValue
        ].merging(workoutDataJSON ?? [:]) { _, new in new }

        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        let receivedWorkoutData = try await service.requestWorkoutData(day: 5)

        #expect(mockSession.sentMessages.count == 1)
        let message = try #require(mockSession.sentMessages.first)
        #expect(message["command"] as? String == Constants.WatchCommand.getWorkoutData.rawValue)
        #expect(message["day"] as? Int == 5)
        #expect(receivedWorkoutData.day == 5)
        #expect(receivedWorkoutData.trainings.count == 1)
        #expect(receivedWorkoutData.plannedCount == 4)
    }

    @Test("Выбрасывает ошибку при ошибке отправки сообщения")
    func throwsErrorWhenMessageSendFails() async throws {
        let authService = try WatchAuthService(userDefaults: MockUserDefaults.create())
        let mockSession = MockWCSession(isReachable: true)
        mockSession.shouldSucceed = false
        mockSession.mockError = WatchConnectivityError.sessionUnavailable
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        await #expect(throws: WatchConnectivityError.self) {
            try await service.sendActivityType(day: 5, activityType: .workout)
        }
    }
}
