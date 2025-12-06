import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing
import WatchConnectivity

@MainActor
@Suite("Тесты для WatchConnectivityManager")
struct WatchConnectivityManagerTests {
    // MARK: - Helper Methods

    private func createStatusManagerWithMockSession(
        mockSession: MockWCSession,
        container _: ModelContainer
    ) throws -> (StatusManager, StatusManager.WatchConnectivityManager) {
        let mockDaysClient = MockDaysClient()
        let statusManager = try MockStatusManager.create(
            daysClient: mockDaysClient,
            userDefaults: MockUserDefaults.create()
        )

        // Создаем manager с сильной ссылкой на statusManager
        // Важно: statusManager должен оставаться в памяти, так как WatchConnectivityManager хранит weak ссылку
        let manager = StatusManager.WatchConnectivityManager(
            statusManager: statusManager,
            sessionProtocol: mockSession
        )

        // Возвращаем statusManager, чтобы он не был освобожден до завершения теста
        return (statusManager, manager)
    }

    private func processPendingRequests(
        manager: StatusManager.WatchConnectivityManager,
        context: ModelContext
    ) {
        let requests = manager.pendingRequests
        for request in requests {
            switch request {
            case let .setActivity(day, activityType):
                _ = manager.handleSetActivity(day: day, activityType: activityType, context: context)
            case let .saveWorkout(day, result, executionType):
                _ = manager.handleSaveWorkout(day: day, result: result, executionType: executionType, context: context)
            case let .getCurrentActivity(day, replyHandler):
                let reply = manager.handleGetCurrentActivity(day: day, context: context)
                replyHandler(reply)
            case let .getWorkoutData(day, replyHandler):
                let reply = manager.handleGetWorkoutData(day: day, context: context)
                replyHandler(reply)
            case let .deleteActivity(day):
                _ = manager.handleDeleteActivity(day: day, context: context)
            }
        }
        manager.pendingRequests = []
    }

    @Test("Инициализирует WCSession при создании")
    func initializesWCSessionOnCreation() async throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )

        // Убеждаемся, что statusManager не освобожден
        _ = statusManager

        // Ждем выполнения асинхронной задачи инициализации
        try await Task.sleep(for: .milliseconds(10))

        #expect(mockSession.activateCallCount == 1)
        #expect(mockSession.delegate === manager)
    }

    @Test("Успешно сохраняет активность stretch через set")
    func successfullySavesStretchActivity() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        _ = try createTestUser(in: context)

        // Сохраняем statusManager, чтобы он не был освобожден (manager хранит weak ссылку)
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        // Убеждаемся, что statusManager не освобожден
        _ = statusManager

        // Симулируем добавление запроса в очередь напрямую
        manager.pendingRequests.append(.setActivity(day: 5, activityType: .stretch))

        // Обрабатываем запросы из очереди
        processPendingRequests(manager: manager, context: context)

        // Проверяем, что активность была создана
        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        let activity = activities.first { $0.day == 5 }
        let savedActivity = try #require(activity)
        #expect(savedActivity.activityType == .stretch)
    }

    @Test("Успешно сохраняет активность rest через set")
    func successfullySavesRestActivity() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        _ = try createTestUser(in: context)

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        // Симулируем добавление запроса в очередь напрямую
        manager.pendingRequests.append(.setActivity(day: 10, activityType: .rest))

        // Обрабатываем запросы из очереди
        processPendingRequests(manager: manager, context: context)

        // Проверяем, что активность была создана
        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        let activity = activities.first { $0.day == 10 }
        let savedActivity = try #require(activity)
        #expect(savedActivity.activityType == .rest)
    }

    @Test("Успешно сохраняет активность sick через set")
    func successfullySavesSickActivity() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        _ = try createTestUser(in: context)

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        // Симулируем добавление запроса в очередь напрямую
        manager.pendingRequests.append(.setActivity(day: 15, activityType: .sick))

        // Обрабатываем запросы из очереди
        processPendingRequests(manager: manager, context: context)

        // Проверяем, что активность была создана
        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        let activity = activities.first { $0.day == 15 }
        let savedActivity = try #require(activity)
        #expect(savedActivity.activityType == .sick)
    }

    @Test("Отклоняет изменение активности если существует незавершенная тренировка")
    func rejectsActivityChangeWhenUnfinishedWorkoutExists() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        let user = try createTestUser(in: context)

        let existingActivity = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: nil,
            plannedCount: 4,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        context.insert(existingActivity)
        try context.save()

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        // Симулируем добавление запроса в очередь напрямую
        manager.pendingRequests.append(.setActivity(day: 5, activityType: .rest))

        // Обрабатываем запросы из очереди
        var reply: [String: Any] = [:]
        let requests = manager.pendingRequests
        for request in requests {
            if case let .setActivity(day, activityType) = request {
                reply = manager.handleSetActivity(day: day, activityType: activityType, context: context)
            }
        }
        manager.pendingRequests = []

        let error = try #require(reply["error"] as? String)
        #expect(error.contains("незавершенная тренировка"))
    }

    @Test("Разрешает изменение активности для завершенной тренировки")
    func allowsActivityChangeForCompletedWorkout() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        let user = try createTestUser(in: context)

        let existingActivity = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 4,
            plannedCount: 4,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            trainingTypeRaw: nil,
            duration: 1800,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        context.insert(existingActivity)
        try context.save()

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        // Симулируем добавление запроса в очередь напрямую
        manager.pendingRequests.append(.setActivity(day: 5, activityType: .rest))

        // Обрабатываем запросы из очереди
        processPendingRequests(manager: manager, context: context)

        // Проверяем, что активность была обновлена
        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        let activity = activities.first { $0.day == 5 }
        let savedActivity = try #require(activity)
        #expect(savedActivity.activityType == .rest)
    }

    @Test("Обрабатывает ошибку при отсутствии пользователя при установке активности")
    func handlesErrorWhenUserNotFoundForSetActivity() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        // Симулируем добавление запроса в очередь напрямую
        manager.pendingRequests.append(.setActivity(day: 5, activityType: .stretch))

        // Обрабатываем запросы из очереди
        var reply: [String: Any] = [:]
        let requests = manager.pendingRequests
        for request in requests {
            if case let .setActivity(day, activityType) = request {
                reply = manager.handleSetActivity(day: day, activityType: activityType, context: context)
            }
        }
        manager.pendingRequests = []

        let error = try #require(reply["error"] as? String)
        #expect(error.contains("Пользователь") || error.contains("пользователь"))
    }

    @Test("Успешно создает активность с результатом тренировки")
    func successfullyCreatesActivityWithWorkoutResult() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        _ = try createTestUser(in: context)

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        let result = WorkoutResult(count: 4, duration: 1800)

        // Симулируем добавление запроса в очередь напрямую
        manager.pendingRequests.append(.saveWorkout(day: 5, result: result, executionType: .cycles))

        // Обрабатываем запросы из очереди
        processPendingRequests(manager: manager, context: context)

        // Проверяем, что активность была создана
        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        let activity = activities.first { $0.day == 5 }
        let savedActivity = try #require(activity)
        #expect(savedActivity.day == 5)
        #expect(savedActivity.count == 4)
        let duration = try #require(savedActivity.duration)
        #expect(duration == 1800)
    }

    @Test("Обрабатывает ошибку при отсутствии пользователя при сохранении тренировки")
    func handlesErrorWhenUserNotFoundForSaveWorkout() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        let result = WorkoutResult(count: 4, duration: 1800)

        // Симулируем добавление запроса в очередь напрямую
        manager.pendingRequests.append(.saveWorkout(day: 5, result: result, executionType: .cycles))

        // Обрабатываем запросы из очереди
        var reply: [String: Any] = [:]
        let requests = manager.pendingRequests
        for request in requests {
            if case let .saveWorkout(day, result, executionType) = request {
                reply = manager.handleSaveWorkout(day: day, result: result, executionType: executionType, context: context)
            }
        }
        manager.pendingRequests = []

        let error = try #require(reply["error"] as? String)
        #expect(error.contains("Пользователь") || error.contains("пользователь"))
    }

    @Test("Возвращает текущую активность дня если она существует")
    func returnsCurrentActivityWhenExists() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        let user = try createTestUser(in: context)

        let existingActivity = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.stretch.rawValue,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        context.insert(existingActivity)
        try context.save()

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        // Симулируем добавление запроса в очередь напрямую
        var reply: [String: Any] = [:]
        manager.pendingRequests.append(.getCurrentActivity(day: 5, replyHandler: { response in
            reply = response
        }))

        // Обрабатываем запросы из очереди
        processPendingRequests(manager: manager, context: context)

        #expect(reply["command"] as? String == Constants.WatchCommand.currentActivity.rawValue)
        let activityType = try #require(reply["activityType"] as? Int)
        #expect(activityType == DayActivityType.stretch.rawValue)
    }

    @Test("Возвращает nil если активность не найдена")
    func returnsNilWhenActivityNotFound() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        _ = try createTestUser(in: context)

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        // Симулируем добавление запроса в очередь напрямую
        var reply: [String: Any] = [:]
        manager.pendingRequests.append(.getCurrentActivity(day: 5, replyHandler: { response in
            reply = response
        }))

        // Обрабатываем запросы из очереди
        processPendingRequests(manager: manager, context: context)

        #expect(reply["command"] as? String == Constants.WatchCommand.currentActivity.rawValue)
        #expect(reply["activityType"] == nil)
    }

    @Test("Фильтрует активность по пользователю")
    func filtersActivityByUser() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        let user1 = try createTestUser(in: context, id: 1)
        let user2 = User(id: 2, userName: "user2", fullName: "User 2", email: "user2@test.com")
        context.insert(user2)
        try context.save()

        let activityForUser1 = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.stretch.rawValue,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user1
        )
        context.insert(activityForUser1)

        let activityForUser2 = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.rest.rawValue,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user2
        )
        context.insert(activityForUser2)
        try context.save()

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        // Симулируем добавление запроса в очередь напрямую
        var reply: [String: Any] = [:]
        manager.pendingRequests.append(.getCurrentActivity(day: 5, replyHandler: { response in
            reply = response
        }))

        // Обрабатываем запросы из очереди
        processPendingRequests(manager: manager, context: context)

        let activityType = try #require(reply["activityType"] as? Int)
        #expect(activityType == DayActivityType.stretch.rawValue)
    }

    @Test("Возвращает данные тренировки из существующей активности")
    func returnsWorkoutDataFromExistingActivity() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        let user = try createTestUser(in: context)

        let training1 = DayActivityTraining(
            count: 10,
            typeId: ExerciseType.pullups.rawValue,
            customTypeId: nil,
            sortOrder: 0
        )
        let training2 = DayActivityTraining(
            count: 20,
            typeId: ExerciseType.pushups.rawValue,
            customTypeId: nil,
            sortOrder: 1
        )

        let existingActivity = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 4,
            plannedCount: 4,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            trainingTypeRaw: nil,
            duration: 1800,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        existingActivity.trainings = [training1, training2]
        context.insert(existingActivity)
        try context.save()

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        // Симулируем добавление запроса в очередь напрямую
        var reply: [String: Any] = [:]
        manager.pendingRequests.append(.getWorkoutData(day: 5, replyHandler: { response in
            reply = response
        }))

        // Обрабатываем запросы из очереди
        processPendingRequests(manager: manager, context: context)

        #expect(reply["command"] as? String == Constants.WatchCommand.sendWorkoutData.rawValue)
        let day = try #require(reply["day"] as? Int)
        #expect(day == 5)
        let executionType = try #require(reply["executionType"] as? Int)
        #expect(executionType == ExerciseExecutionType.cycles.rawValue)
        let trainings = try #require(reply["trainings"] as? [[String: Any]])
        #expect(trainings.count == 2)
    }

    @Test("Создает данные тренировки для нового дня через WorkoutProgramCreator")
    func createsWorkoutDataForNewDayThroughWorkoutProgramCreator() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        _ = try createTestUser(in: context)

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        // Симулируем добавление запроса в очередь напрямую
        var reply: [String: Any] = [:]
        manager.pendingRequests.append(.getWorkoutData(day: 5, replyHandler: { response in
            reply = response
        }))

        // Обрабатываем запросы из очереди
        processPendingRequests(manager: manager, context: context)

        #expect(reply["command"] as? String == Constants.WatchCommand.sendWorkoutData.rawValue)
        let day = try #require(reply["day"] as? Int)
        #expect(day == 5)
        let trainings = try #require(reply["trainings"] as? [[String: Any]])
        #expect(!trainings.isEmpty)
    }

    @Test("Обрабатывает ошибку при отсутствии пользователя при получении данных тренировки")
    func handlesErrorWhenUserNotFoundForGetWorkoutData() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        // Симулируем добавление запроса в очередь напрямую
        var reply: [String: Any] = [:]
        manager.pendingRequests.append(.getWorkoutData(day: 5, replyHandler: { response in
            reply = response
        }))

        // Обрабатываем запросы из очереди
        let requests = manager.pendingRequests
        for request in requests {
            if case let .getWorkoutData(day, replyHandler) = request {
                let response = manager.handleGetWorkoutData(day: day, context: context)
                replyHandler(response)
            }
        }
        manager.pendingRequests = []

        let error = try #require(reply["error"] as? String)
        #expect(error.contains("Пользователь") || error.contains("пользователь"))
    }

    @Test("Отправляет команду PHONE_COMMAND_AUTH_STATUS_CHANGED при успешной авторизации")
    func sendsAuthStatusChangedCommandOnSuccessfulAuthorization() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        manager.sendAuthStatusChanged(true)

        #expect(mockSession.sentMessages.count == 1)
        let sentMessage = try #require(mockSession.sentMessages.first)
        let command = try #require(sentMessage["command"] as? String)
        #expect(command == Constants.WatchCommand.authStatusChanged.rawValue)
        let isAuthorized = try #require(sentMessage["isAuthorized"] as? Bool)
        #expect(isAuthorized)
    }

    @Test("Отправляет команду PHONE_COMMAND_AUTH_STATUS_CHANGED при логауте")
    func sendsAuthStatusChangedCommandOnLogout() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()

        // Сохраняем statusManager, чтобы он не был освобожден
        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager // Убеждаемся, что statusManager не освобожден

        manager.sendAuthStatusChanged(false)

        #expect(mockSession.sentMessages.count == 1)
        let sentMessage = try #require(mockSession.sentMessages.first)
        let command = try #require(sentMessage["command"] as? String)
        #expect(command == Constants.WatchCommand.authStatusChanged.rawValue)
        let isAuthorized = try #require(sentMessage["isAuthorized"] as? Bool)
        #expect(!isAuthorized)
    }

    @Test("Успешно помечает активность для удаления")
    func successfullyMarksActivityForDeletion() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        let user = try createTestUser(in: context)

        let existingActivity = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.stretch.rawValue,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        context.insert(existingActivity)
        try context.save()

        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager

        manager.pendingRequests.append(.deleteActivity(day: 5))

        processPendingRequests(manager: manager, context: context)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        let activity = activities.first { $0.day == 5 }
        let deletedActivity = try #require(activity)
        #expect(deletedActivity.shouldDelete)
        #expect(!deletedActivity.isSynced)
    }

    @Test("Обрабатывает ошибку при отсутствии пользователя при удалении активности")
    func handlesErrorWhenUserNotFoundForDeleteActivity() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext

        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager

        manager.pendingRequests.append(.deleteActivity(day: 5))

        var reply: [String: Any] = [:]
        let requests = manager.pendingRequests
        for request in requests {
            if case let .deleteActivity(day) = request {
                reply = manager.handleDeleteActivity(day: day, context: context)
            }
        }
        manager.pendingRequests = []

        let error = try #require(reply["error"] as? String)
        #expect(error.contains("Пользователь") || error.contains("пользователь"))
    }

    @Test("Возвращает пустой ответ если активность не найдена при удалении")
    func returnsEmptyResponseWhenActivityNotFoundForDeletion() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        _ = try createTestUser(in: context)

        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager

        manager.pendingRequests.append(.deleteActivity(day: 5))

        var reply: [String: Any] = [:]
        let requests = manager.pendingRequests
        for request in requests {
            if case let .deleteActivity(day) = request {
                reply = manager.handleDeleteActivity(day: day, context: context)
            }
        }
        manager.pendingRequests = []

        #expect(reply.isEmpty)
    }

    @Test("Удаляет активность только для текущего пользователя")
    func deletesActivityOnlyForCurrentUser() throws {
        let mockSession = MockWCSession(isReachable: true)
        let container = try createTestModelContainer()
        let context = container.mainContext
        let user1 = try createTestUser(in: context, id: 1)
        let user2 = User(id: 2, userName: "user2", fullName: "User 2", email: "user2@test.com")
        context.insert(user2)
        try context.save()

        let activityForUser1 = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.stretch.rawValue,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user1
        )
        context.insert(activityForUser1)

        let activityForUser2 = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.rest.rawValue,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user2
        )
        context.insert(activityForUser2)
        try context.save()

        let (statusManager, manager) = try createStatusManagerWithMockSession(
            mockSession: mockSession,
            container: container
        )
        _ = statusManager

        manager.pendingRequests.append(.deleteActivity(day: 5))

        processPendingRequests(manager: manager, context: context)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        let user1Activity = activities.first { $0.day == 5 && $0.user?.id == 1 }
        let user2Activity = activities.first { $0.day == 5 && $0.user?.id == 2 }
        let deletedActivity = try #require(user1Activity)
        let notDeletedActivity = try #require(user2Activity)
        #expect(deletedActivity.shouldDelete)
        #expect(!notDeletedActivity.shouldDelete)
    }

    // MARK: - Helper Methods

    private func createTestModelContainer() throws -> ModelContainer {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: User.self,
            DayActivity.self,
            DayActivityTraining.self,
            configurations: modelConfiguration
        )
    }

    private func createTestUser(in context: ModelContext, id: Int = 1) throws -> User {
        let user = User(
            id: id,
            userName: "testuser",
            fullName: "Test User",
            email: "test@example.com"
        )
        context.insert(user)
        try context.save()
        return user
    }
}
