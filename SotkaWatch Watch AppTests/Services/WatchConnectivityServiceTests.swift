import Foundation
@testable import SotkaWatch_Watch_App
import Testing
import WatchConnectivity

@MainActor
struct WatchConnectivityServiceTests {
    @Test("Инициализирует WCSession при создании")
    func initializesWCSessionOnCreation() {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: true)
        _ = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)
        // При использовании мок сессии, session будет nil, но sessionProtocol установлен
        // Проверяем, что мок сессия активирована
        #expect(mockSession.activateCallCount == 1)
    }

    @Test("Обрабатывает команду изменения статуса авторизации от iPhone")
    func handlesAuthStatusCommandFromPhone() {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        #expect(!authService.isAuthorized)

        let message: [String: Any] = [
            "command": Constants.WatchCommand.authStatus.rawValue,
            "isAuthorized": true
        ]

        // Используем тестовый метод для обработки сообщения
        service.testHandleReceivedMessage(message)

        #expect(authService.isAuthorized)
    }

    @Test("Должен дедуплицировать isAuthorized, но всегда обновлять currentDay и currentActivity")
    func handleReceivedMessageDeduplicatesAuthStatus() throws {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        #expect(!authService.isAuthorized)
        #expect(service.currentDay == nil)
        #expect(service.currentActivity == nil)

        let message: [String: Any] = [
            "command": Constants.WatchCommand.authStatus.rawValue,
            "isAuthorized": true,
            "currentDay": 10,
            "currentActivity": DayActivityType.workout.rawValue
        ]

        // Первый вызов - должен обработать все данные
        service.testHandleReceivedMessage(message)
        #expect(authService.isAuthorized)
        let firstCurrentDay = try #require(service.currentDay)
        #expect(firstCurrentDay == 10)
        let firstCurrentActivity = try #require(service.currentActivity)
        #expect(firstCurrentActivity == .workout)

        // Сбрасываем isAuthorized для проверки дедупликации
        authService.updateAuthStatus(false)
        #expect(!authService.isAuthorized)

        // Второй вызов с теми же данными - isAuthorized не должен обновиться (дедупликация)
        // но currentDay и currentActivity должны обновиться (они всегда обновляются)
        service.testHandleReceivedMessage(message)
        #expect(!authService.isAuthorized) // Дедупликация для isAuthorized
        let secondCurrentDay = try #require(service.currentDay)
        #expect(secondCurrentDay == 10) // currentDay обновляется всегда
        let secondCurrentActivity = try #require(service.currentActivity)
        #expect(secondCurrentActivity == .workout) // currentActivity обновляется всегда
    }

    @Test("Обрабатывает команду изменения статуса авторизации с replyHandler")
    func handlesAuthStatusCommandWithReplyHandler() {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        #expect(!authService.isAuthorized)

        let message: [String: Any] = [
            "command": Constants.WatchCommand.authStatus.rawValue,
            "isAuthorized": true
        ]

        // Используем тестовый метод для обработки сообщения
        service.testHandleReceivedMessage(message)

        #expect(authService.isAuthorized)
    }

    @Test("Должен дедуплицировать isAuthorized, но всегда обновлять currentDay и currentActivity в applicationContext")
    func handleApplicationContextDeduplicates() throws {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        #expect(!authService.isAuthorized)
        #expect(service.currentDay == nil)
        #expect(service.currentActivity == nil)

        let context: [String: Any] = [
            "isAuthorized": true,
            "currentDay": 10,
            "currentActivity": DayActivityType.workout.rawValue
        ]

        // Первый вызов - должен обработать все данные
        service.testHandleApplicationContext(context)
        #expect(authService.isAuthorized)
        let firstCurrentDay = try #require(service.currentDay)
        #expect(firstCurrentDay == 10)
        let firstCurrentActivity = try #require(service.currentActivity)
        #expect(firstCurrentActivity == .workout)

        // Сбрасываем isAuthorized для проверки дедупликации
        authService.updateAuthStatus(false)
        #expect(!authService.isAuthorized)

        // Второй вызов с теми же данными - isAuthorized не должен обновиться (дедупликация)
        // но currentDay и currentActivity должны обновиться (они всегда обновляются)
        service.testHandleApplicationContext(context)
        #expect(!authService.isAuthorized) // Дедупликация для isAuthorized
        let secondCurrentDay = try #require(service.currentDay)
        #expect(secondCurrentDay == 10) // currentDay обновляется всегда
        let secondCurrentActivity = try #require(service.currentActivity)
        #expect(secondCurrentActivity == .workout) // currentActivity обновляется всегда
    }

    @Test("Обрабатывает команду изменения текущего дня")
    func handlesCurrentDayCommand() throws {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        #expect(service.currentDay == nil)

        let message: [String: Any] = [
            "command": Constants.WatchCommand.currentDay.rawValue,
            "currentDay": 5
        ]

        // Используем тестовый метод для обработки сообщения
        service.testHandleReceivedMessage(message)

        let currentDay = try #require(service.currentDay)
        #expect(currentDay == 5)
    }

    @Test("Выбрасывает ошибку при отправке типа активности когда сессия недоступна")
    func throwsErrorWhenSessionUnavailableForActivityType() async throws {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: false)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        await #expect(throws: WatchConnectivityError.self) {
            try await service.sendActivityType(day: 5, activityType: .workout)
        }
    }

    @Test("Выбрасывает ошибку при отправке результата тренировки когда сессия недоступна")
    func throwsErrorWhenSessionUnavailableForWorkoutResult() async throws {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: false)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)
        let result = WorkoutResult(count: 4, duration: 1800)

        await #expect(throws: WatchConnectivityError.self) {
            try await service.sendWorkoutResult(day: 5, result: result, executionType: .cycles, trainings: [], comment: nil)
        }
    }

    @Test("Выбрасывает ошибку при запросе текущей активности когда сессия недоступна")
    func throwsErrorWhenSessionUnavailableForCurrentActivity() async throws {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: false)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        await #expect(throws: WatchConnectivityError.self) {
            _ = try await service.requestCurrentActivity(day: 5)
        }
    }

    @Test("Выбрасывает ошибку при запросе данных тренировки когда сессия недоступна")
    func throwsErrorWhenSessionUnavailableForWorkoutData() async throws {
        let authService = WatchAuthService()
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
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: true)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        try await service.sendActivityType(day: 5, activityType: .workout)

        #expect(mockSession.sentMessages.count == 1)
        let message = try #require(mockSession.sentMessages.first)
        let command = try #require(message["command"] as? String)
        #expect(command == Constants.WatchCommand.setActivity.rawValue)
        let day = try #require(message["day"] as? Int)
        #expect(day == 5)
        let activityType = try #require(message["activityType"] as? Int)
        #expect(activityType == DayActivityType.workout.rawValue)
    }

    @Test("Успешно отправляет результат тренировки")
    func successfullySendsWorkoutResult() async throws {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: true)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)
        let result = WorkoutResult(count: 4, duration: 1800)

        try await service.sendWorkoutResult(day: 5, result: result, executionType: .cycles, trainings: [], comment: nil)

        #expect(mockSession.sentMessages.count == 1)
        let message = try #require(mockSession.sentMessages.first)
        let command = try #require(message["command"] as? String)
        #expect(command == Constants.WatchCommand.saveWorkout.rawValue)
        let day = try #require(message["day"] as? Int)
        #expect(day == 5)
        let executionType = try #require(message["executionType"] as? Int)
        #expect(executionType == ExerciseExecutionType.cycles.rawValue)
        let resultJSON = try #require(message["result"] as? [String: Any])
        let count = try #require(resultJSON["count"] as? Int)
        #expect(count == 4)
        let trainings = try #require(message["trainings"] as? [[String: Any]])
        #expect(trainings.isEmpty)
    }

    @Test("Успешно отправляет результат тренировки с комментарием")
    func successfullySendsWorkoutResultWithComment() async throws {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: true)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)
        let result = WorkoutResult(count: 4, duration: 1800)

        try await service.sendWorkoutResult(day: 5, result: result, executionType: .cycles, trainings: [], comment: "Отличная тренировка!")

        #expect(mockSession.sentMessages.count == 1)
        let message = try #require(mockSession.sentMessages.first)
        let command = try #require(message["command"] as? String)
        #expect(command == Constants.WatchCommand.saveWorkout.rawValue)
        let comment = try #require(message["comment"] as? String)
        #expect(comment == "Отличная тренировка!")
    }

    @Test("Не добавляет поле comment в сообщение если комментарий nil")
    func doesNotAddCommentFieldWhenCommentIsNil() async throws {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: true)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)
        let result = WorkoutResult(count: 4, duration: 1800)

        try await service.sendWorkoutResult(day: 5, result: result, executionType: .cycles, trainings: [], comment: nil)

        let message = try #require(mockSession.sentMessages.first)
        #expect(message["comment"] == nil)
    }

    @Test("Успешно запрашивает текущую активность")
    func successfullyRequestsCurrentActivity() async throws {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: true)
        mockSession.mockReply = [
            "command": Constants.WatchCommand.currentActivity.rawValue,
            "activityType": DayActivityType.workout.rawValue
        ]
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        let activityType = try await service.requestCurrentActivity(day: 5)

        #expect(mockSession.sentMessages.count == 1)
        let message = try #require(mockSession.sentMessages.first)
        let command = try #require(message["command"] as? String)
        #expect(command == Constants.WatchCommand.getCurrentActivity.rawValue)
        let day = try #require(message["day"] as? Int)
        #expect(day == 5)
        let receivedActivityType = try #require(activityType)
        #expect(receivedActivityType == .workout)
    }

    @Test("Возвращает nil при запросе текущей активности если активность не установлена")
    func returnsNilWhenCurrentActivityNotSet() async throws {
        let authService = WatchAuthService()
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
        let authService = WatchAuthService()
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
        let response = WorkoutDataResponse(
            workoutData: workoutData,
            executionCount: 3,
            comment: "Отличная тренировка!"
        )

        let encoder = JSONEncoder()
        let responseJSON = try JSONSerialization.jsonObject(with: encoder.encode(response)) as? [String: Any]

        mockSession.mockReply = [
            "command": Constants.WatchCommand.sendWorkoutData.rawValue
        ].merging(responseJSON ?? [:]) { _, new in new }

        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        let receivedResponse = try await service.requestWorkoutData(day: 5)

        #expect(mockSession.sentMessages.count == 1)
        let message = try #require(mockSession.sentMessages.first)
        let command = try #require(message["command"] as? String)
        #expect(command == Constants.WatchCommand.getWorkoutData.rawValue)
        let day = try #require(message["day"] as? Int)
        #expect(day == 5)
        #expect(receivedResponse.workoutData.day == 5)
        #expect(receivedResponse.workoutData.trainings.count == 1)
        #expect(receivedResponse.workoutData.plannedCount == 4)
        let executionCount = try #require(receivedResponse.executionCount)
        #expect(executionCount == 3)
        let comment = try #require(receivedResponse.comment)
        #expect(comment == "Отличная тренировка!")
    }

    @Test("Выбрасывает ошибку при ошибке отправки сообщения")
    func throwsErrorWhenMessageSendFails() async throws {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: true)
        mockSession.shouldSucceed = false
        mockSession.mockError = WatchConnectivityError.sessionUnavailable
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        await #expect(throws: WatchConnectivityError.self) {
            try await service.sendActivityType(day: 5, activityType: .workout)
        }
    }

    @Test("Успешно отправляет команду удаления активности")
    func successfullySendsDeleteActivityCommand() async throws {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: true)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        try await service.deleteActivity(day: 5)

        #expect(mockSession.sentMessages.count == 1)
        let message = try #require(mockSession.sentMessages.first)
        let command = try #require(message["command"] as? String)
        #expect(command == Constants.WatchCommand.deleteActivity.rawValue)
        let day = try #require(message["day"] as? Int)
        #expect(day == 5)
    }

    @Test("Выбрасывает ошибку при удалении активности когда сессия недоступна")
    func throwsErrorWhenSessionUnavailableForDeleteActivity() async throws {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: false)
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        await #expect(throws: WatchConnectivityError.self) {
            try await service.deleteActivity(day: 5)
        }
    }

    @Test("Выбрасывает ошибку при ошибке отправки команды удаления")
    func throwsErrorWhenDeleteActivityMessageSendFails() async throws {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: true)
        mockSession.shouldSucceed = false
        mockSession.mockError = WatchConnectivityError.sessionUnavailable
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        await #expect(throws: WatchConnectivityError.self) {
            try await service.deleteActivity(day: 5)
        }
    }

    // MARK: - Тесты обработки applicationContext

    @Test("Должен обрабатывать applicationContext с currentDay и currentActivity")
    func shouldHandleApplicationContextWithCurrentDayAndActivity() throws {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        #expect(service.currentDay == nil)
        #expect(service.currentActivity == nil)
        #expect(!authService.isAuthorized)

        let applicationContext: [String: Any] = [
            "isAuthorized": true,
            "currentDay": 42,
            "currentActivity": DayActivityType.workout.rawValue
        ]

        service.testHandleApplicationContext(applicationContext)

        #expect(authService.isAuthorized)
        let currentDay = try #require(service.currentDay)
        #expect(currentDay == 42)
        let currentActivity = try #require(service.currentActivity)
        #expect(currentActivity == .workout)
    }

    @Test("Должен обрабатывать applicationContext только с isAuthorized")
    func shouldHandleApplicationContextWithOnlyIsAuthorized() {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        #expect(!authService.isAuthorized)

        let applicationContext: [String: Any] = [
            "isAuthorized": true
        ]

        service.testHandleApplicationContext(applicationContext)

        #expect(authService.isAuthorized)
        #expect(service.currentDay == nil)
    }

    @Test("Должен обрабатывать applicationContext с isAuthorized=false")
    func shouldHandleApplicationContextWithIsAuthorizedFalse() throws {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        // Сначала устанавливаем авторизацию
        authService.updateAuthStatus(true)
        service.testHandleApplicationContext(["currentDay": 42])

        #expect(authService.isAuthorized)
        let currentDay = try #require(service.currentDay)
        #expect(currentDay == 42)

        // Затем получаем isAuthorized=false
        let applicationContext: [String: Any] = [
            "isAuthorized": false
        ]

        service.testHandleApplicationContext(applicationContext)

        #expect(!authService.isAuthorized)
        // currentDay должен остаться, так как он не был явно удален
    }

    @Test("Должен обрабатывать receivedApplicationContext при активации WCSession")
    func shouldHandleReceivedApplicationContextOnActivation() throws {
        let authService = WatchAuthService()
        let mockSession = MockWCSession(isReachable: false)
        mockSession.receivedApplicationContext = [
            "isAuthorized": true,
            "currentDay": 42,
            "currentActivity": DayActivityType.workout.rawValue
        ]
        let service = WatchConnectivityService(authService: authService, sessionProtocol: mockSession)

        // Симулируем активацию
        service.testHandleWCSessionActivation()

        #expect(authService.isAuthorized)
        let currentDay = try #require(service.currentDay)
        #expect(currentDay == 42)
        let currentActivity = try #require(service.currentActivity)
        #expect(currentActivity == .workout)
    }

    @Test("Должен обрабатывать applicationContext с currentActivity без currentDay")
    func shouldHandleApplicationContextWithCurrentActivityWithoutCurrentDay() throws {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        #expect(service.currentActivity == nil)

        let applicationContext: [String: Any] = [
            "isAuthorized": true,
            "currentActivity": DayActivityType.rest.rawValue
        ]

        service.testHandleApplicationContext(applicationContext)

        let currentActivity = try #require(service.currentActivity)
        #expect(currentActivity == .rest)
    }

    @Test("Должен обрабатывать applicationContext с currentActivity=nil (удаление активности)")
    func shouldHandleApplicationContextWithCurrentActivityNil() throws {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        // Сначала устанавливаем активность
        service.testHandleApplicationContext([
            "isAuthorized": true,
            "currentDay": 42,
            "currentActivity": DayActivityType.workout.rawValue
        ])

        let initialActivity = try #require(service.currentActivity)
        #expect(initialActivity == .workout)

        // Затем получаем applicationContext без currentActivity (удаление)
        let applicationContext: [String: Any] = [
            "isAuthorized": true,
            "currentDay": 42
        ]

        service.testHandleApplicationContext(applicationContext)

        #expect(service.currentActivity == nil)
    }

    @Test("Должен вызывать callback при изменении currentActivity")
    func shouldCallCallbackWhenCurrentActivityChanges() throws {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        var callbackCalled = false
        var callbackActivity: DayActivityType?

        service.onCurrentActivityChanged = { activity in
            callbackCalled = true
            callbackActivity = activity
        }

        let applicationContext: [String: Any] = [
            "isAuthorized": true,
            "currentDay": 42,
            "currentActivity": DayActivityType.stretch.rawValue
        ]

        service.testHandleApplicationContext(applicationContext)

        #expect(callbackCalled)
        let activity = try #require(callbackActivity)
        #expect(activity == .stretch)
    }

    @Test("Должен вызывать callback с nil при удалении currentActivity")
    func shouldCallCallbackWithNilWhenCurrentActivityRemoved() {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        // Сначала устанавливаем активность
        service.testHandleApplicationContext([
            "isAuthorized": true,
            "currentDay": 42,
            "currentActivity": DayActivityType.workout.rawValue
        ])

        var callbackCalled = false
        var callbackActivity: DayActivityType?

        service.onCurrentActivityChanged = { activity in
            callbackCalled = true
            callbackActivity = activity
        }

        // Затем удаляем активность
        let applicationContext: [String: Any] = [
            "isAuthorized": true,
            "currentDay": 42
        ]

        service.testHandleApplicationContext(applicationContext)

        #expect(callbackCalled)
        #expect(callbackActivity == nil)
    }

    // MARK: - Тесты обработки команды PHONE_COMMAND_SEND_WORKOUT_DATA

    @Test("Должен обрабатывать команду PHONE_COMMAND_SEND_WORKOUT_DATA и вызывать callback")
    func shouldHandleSendWorkoutDataCommandAndCallCallback() throws {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

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
            day: 15,
            executionType: 0,
            trainings: trainings,
            plannedCount: 3
        )
        let response = WorkoutDataResponse(
            workoutData: workoutData,
            executionCount: 4,
            comment: "Отличная тренировка!"
        )

        let encoder = JSONEncoder()
        let responseJSON = try JSONSerialization.jsonObject(with: encoder.encode(response)) as? [String: Any]

        var callbackCalled = false
        var callbackResponse: WorkoutDataResponse?

        service.onWorkoutDataReceived = { response in
            callbackCalled = true
            callbackResponse = response
        }

        var message: [String: Any] = responseJSON ?? [:]
        message["command"] = Constants.WatchCommand.sendWorkoutData.rawValue

        service.testHandleReceivedMessage(message)

        #expect(callbackCalled)
        let receivedResponse = try #require(callbackResponse)
        #expect(receivedResponse.workoutData.day == 15)
        #expect(receivedResponse.workoutData.trainings.count == 1)
        #expect(receivedResponse.workoutData.plannedCount == 3)
        let executionCount = try #require(receivedResponse.executionCount)
        #expect(executionCount == 4)
        let comment = try #require(receivedResponse.comment)
        #expect(comment == "Отличная тренировка!")
    }

    @Test("Должен обрабатывать команду PHONE_COMMAND_SEND_WORKOUT_DATA без опциональных полей")
    func shouldHandleSendWorkoutDataCommandWithoutOptionalFields() throws {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        let workoutData = WorkoutData(
            day: 15,
            executionType: 0,
            trainings: [],
            plannedCount: 3
        )
        let response = WorkoutDataResponse(
            workoutData: workoutData,
            executionCount: nil,
            comment: nil
        )

        let encoder = JSONEncoder()
        let responseJSON = try JSONSerialization.jsonObject(with: encoder.encode(response)) as? [String: Any]

        var callbackCalled = false
        var callbackResponse: WorkoutDataResponse?

        service.onWorkoutDataReceived = { response in
            callbackCalled = true
            callbackResponse = response
        }

        var message: [String: Any] = responseJSON ?? [:]
        message["command"] = Constants.WatchCommand.sendWorkoutData.rawValue

        service.testHandleReceivedMessage(message)

        #expect(callbackCalled)
        let receivedResponse = try #require(callbackResponse)
        #expect(receivedResponse.workoutData.day == 15)
        #expect(receivedResponse.executionCount == nil)
        #expect(receivedResponse.comment == nil)
    }

    @Test("Должен игнорировать команду PHONE_COMMAND_SEND_WORKOUT_DATA с неверным форматом данных")
    func shouldIgnoreSendWorkoutDataCommandWithInvalidFormat() {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        var callbackCalled = false

        service.onWorkoutDataReceived = { _ in
            callbackCalled = true
        }

        let message: [String: Any] = [
            "command": Constants.WatchCommand.sendWorkoutData.rawValue,
            "invalid": "data"
        ]

        service.testHandleReceivedMessage(message)

        #expect(!callbackCalled)
    }

    // MARK: - Тесты для restTime в WatchConnectivityService

    @Test("Должен извлекать restTime из applicationContext и сохранять в свойство")
    func shouldExtractRestTimeFromApplicationContext() throws {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        #expect(service.restTime == nil)

        let applicationContext: [String: Any] = [
            "isAuthorized": true,
            "currentDay": 42,
            "restTime": 90
        ]

        service.testHandleApplicationContext(applicationContext)

        let restTime = try #require(service.restTime)
        #expect(restTime == 90)
    }

    @Test("Должен извлекать restTime из команды PHONE_COMMAND_AUTH_STATUS и сохранять в свойство")
    func shouldExtractRestTimeFromAuthStatusCommand() throws {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        #expect(service.restTime == nil)

        let message: [String: Any] = [
            "command": Constants.WatchCommand.authStatus.rawValue,
            "isAuthorized": true,
            "currentDay": 42,
            "restTime": 90
        ]

        service.testHandleReceivedMessage(message)

        let restTime = try #require(service.restTime)
        #expect(restTime == 90)
    }

    @Test("Должен использовать дефолтное значение restTime если restTime отсутствует в сообщении")
    func shouldUseDefaultRestTimeWhenMissing() {
        let authService = WatchAuthService()
        let service = WatchConnectivityService(authService: authService)

        #expect(service.restTime == nil)

        let applicationContext: [String: Any] = [
            "isAuthorized": true,
            "currentDay": 42
        ]

        service.testHandleApplicationContext(applicationContext)

        // restTime должен остаться nil, если не передан в сообщении
        #expect(service.restTime == nil)
    }

    @Test("Должен делать restTime доступным через протокол WatchConnectivityServiceProtocol")
    func shouldMakeRestTimeAvailableThroughProtocol() throws {
        let authService = WatchAuthService()
        let service: any WatchConnectivityServiceProtocol = WatchConnectivityService(authService: authService)

        #expect(service.restTime == nil)

        let applicationContext: [String: Any] = [
            "isAuthorized": true,
            "currentDay": 42,
            "restTime": 90
        ]

        // Используем тестовый метод через приведение типа
        if let watchService = service as? WatchConnectivityService {
            watchService.testHandleApplicationContext(applicationContext)
        }

        let restTime = try #require(service.restTime)
        #expect(restTime == 90)
    }
}
