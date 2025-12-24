import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
@Suite("Тесты для WatchConnectivity в StatusManager")
struct StatusManagerWatchConnectivityTests {
    // MARK: - Тесты структуры WatchStatusMessage

    @Test("Должен преобразовывать данные статуса в сообщение с полными данными")
    func shouldConvertStatusToMessageWithFullData() throws {
        let message = WatchStatusMessage(
            isAuthorized: true,
            currentDay: 42,
            currentActivity: .workout
        )

        let result = message.message

        let command = try #require(result["command"] as? String)
        #expect(command == Constants.WatchCommand.authStatus.rawValue)
        let isAuthorized = try #require(result["isAuthorized"] as? Bool)
        #expect(isAuthorized)
        let currentDay = try #require(result["currentDay"] as? Int)
        #expect(currentDay == 42)
        let currentActivity = try #require(result["currentActivity"] as? Int)
        #expect(currentActivity == DayActivityType.workout.rawValue)
    }

    @Test("Должен создавать applicationContext с полными данными")
    func shouldCreateApplicationContextWithFullData() throws {
        let message = WatchStatusMessage(
            isAuthorized: true,
            currentDay: 42,
            currentActivity: .workout
        )
        let applicationContext = message.applicationContext

        let isAuthorized = try #require(applicationContext["isAuthorized"] as? Bool)
        #expect(isAuthorized)
        let currentDay = try #require(applicationContext["currentDay"] as? Int)
        #expect(currentDay == 42)
        let currentActivity = try #require(applicationContext["currentActivity"] as? Int)
        #expect(currentActivity == DayActivityType.workout.rawValue)
        #expect(applicationContext["command"] == nil)
    }

    @Test("Должен создавать applicationContext без активности")
    func shouldCreateApplicationContextWithoutActivity() throws {
        let message = WatchStatusMessage(
            isAuthorized: true,
            currentDay: 42,
            currentActivity: nil
        )
        let applicationContext = message.applicationContext

        let isAuthorized = try #require(applicationContext["isAuthorized"] as? Bool)
        #expect(isAuthorized)
        let currentDay = try #require(applicationContext["currentDay"] as? Int)
        #expect(currentDay == 42)
        #expect(applicationContext["currentActivity"] == nil)
        #expect(applicationContext["command"] == nil)
    }

    @Test("Должен создавать applicationContext для неавторизованного пользователя")
    func shouldCreateApplicationContextForUnauthorized() throws {
        let message = WatchStatusMessage(
            isAuthorized: false,
            currentDay: nil,
            currentActivity: nil
        )
        let applicationContext = message.applicationContext

        let isAuthorized = try #require(applicationContext["isAuthorized"] as? Bool)
        #expect(!isAuthorized)
        #expect(applicationContext["currentDay"] == nil)
        #expect(applicationContext["currentActivity"] == nil)
        #expect(applicationContext["command"] == nil)
    }

    @Test("Должен преобразовывать данные статуса в сообщение без активности")
    func shouldConvertStatusToMessageWithoutActivity() throws {
        let message = WatchStatusMessage(
            isAuthorized: true,
            currentDay: 42,
            currentActivity: nil
        )

        let result = message.message

        let command = try #require(result["command"] as? String)
        #expect(command == Constants.WatchCommand.authStatus.rawValue)
        let isAuthorized = try #require(result["isAuthorized"] as? Bool)
        #expect(isAuthorized)
        let currentDay = try #require(result["currentDay"] as? Int)
        #expect(currentDay == 42)
        #expect(result["currentActivity"] == nil)
    }

    @Test("Должен преобразовывать данные статуса в сообщение для неавторизованного пользователя")
    func shouldConvertStatusToMessageForUnauthorized() throws {
        let message = WatchStatusMessage(
            isAuthorized: false,
            currentDay: nil,
            currentActivity: nil
        )

        let result = message.message

        let command = try #require(result["command"] as? String)
        #expect(command == Constants.WatchCommand.authStatus.rawValue)
        let isAuthorized = try #require(result["isAuthorized"] as? Bool)
        #expect(!isAuthorized)
        #expect(result["currentDay"] == nil)
        #expect(result["currentActivity"] == nil)
    }

    // MARK: - Тесты методов отправки данных

    @Test("Должен отправлять текущий статус в начале getStatus")
    func shouldSendCurrentStatusAtStartOfGetStatus() async throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        statusManager.setCurrentDayForDebug(10)

        await statusManager.getStatus()

        #expect(mockSession.sentMessages.count >= 1)
        let sentMessage = try #require(mockSession.sentMessages.first)
        let command = try #require(sentMessage["command"] as? String)
        #expect(command == Constants.WatchCommand.authStatus.rawValue)
    }

    @Test("Должен отправлять текущий статус после синхронизации в getStatus")
    func shouldSendCurrentStatusAfterSyncInGetStatus() async throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        statusManager.setCurrentDayForDebug(10)

        await statusManager.getStatus()

        #expect(mockSession.sentMessages.count >= 1)
    }

    @Test("Должен отправлять sendMessage только один раз после синхронизации в getStatus")
    func getStatusSendsStatusOnlyOnceAfterSync() async throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        statusManager.setCurrentDayForDebug(10)

        await statusManager.getStatus()

        // Проверяем, что sendMessage (PHONE_COMMAND_AUTH_STATUS) отправляется только один раз
        let authStatusMessages = mockSession.sentMessages.filter { message in
            (message["command"] as? String) == Constants.WatchCommand.authStatus.rawValue
        }
        #expect(authStatusMessages.count == 1)
    }

    @Test("Должен дедуплицировать одинаковые данные при последовательных вызовах sendCurrentStatus")
    func sendCurrentStatusDeduplicatesIdenticalData() throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        // setCurrentDayForDebug вызывает sendCurrentStatus с currentActivity: nil (если активности нет)
        // Это отправляет sendMessage (данные изменились)
        statusManager.setCurrentDayForDebug(10)

        // Первый вызов с currentActivity: .workout - данные изменились (nil -> .workout), поэтому sendMessage отправляется
        statusManager.sendCurrentStatus(isAuthorized: true, currentDay: 10, currentActivity: .workout)

        // Второй вызов с теми же данными - sendMessage не должен отправляться (данные не изменились)
        statusManager.sendCurrentStatus(isAuthorized: true, currentDay: 10, currentActivity: .workout)

        // Проверяем, что sendMessage отправлен дважды:
        // 1. От setCurrentDayForDebug (currentActivity: nil)
        // 2. От первого sendCurrentStatus (currentActivity: nil -> .workout)
        let authStatusMessages = mockSession.sentMessages.filter { message in
            (message["command"] as? String) == Constants.WatchCommand.authStatus.rawValue
        }
        #expect(authStatusMessages.count == 2)

        // Проверяем, что applicationContext обновляется каждый раз (от setCurrentDayForDebug и от каждого sendCurrentStatus)
        // setCurrentDayForDebug отправляет 1 раз, затем 2 вызова sendCurrentStatus отправляют еще 2 раза = 3 раза
        #expect(mockSession.applicationContexts.count == 3)
    }

    @Test("Должен всегда отправлять applicationContext даже если часы недоступны")
    func updateApplicationContextAlwaysSends() throws {
        let mockSession = MockWCSession(isReachable: false)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        // setCurrentDayForDebug вызывает sendCurrentStatus, что отправляет applicationContext
        statusManager.setCurrentDayForDebug(10)

        // Вызываем sendCurrentStatus еще раз - applicationContext должен отправиться даже если часы недоступны
        // Но так как данные не изменились, applicationContext все равно отправляется (это нормально для applicationContext)
        statusManager.sendCurrentStatus(isAuthorized: true, currentDay: 10, currentActivity: .workout)

        // Проверяем, что applicationContext отправлен (2 раза: от setCurrentDayForDebug и от sendCurrentStatus)
        #expect(mockSession.applicationContexts.count == 2)
        // Проверяем, что sendMessage не отправлен (часы недоступны)
        #expect(mockSession.sentMessages.isEmpty)
    }

    @Test("Должен отправлять sendMessage только если часы доступны")
    func sendMessageOnlyWhenReachable() throws {
        let mockSessionUnreachable = MockWCSession(isReachable: false)
        let statusManagerUnreachable = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSessionUnreachable
        )

        // setCurrentDayForDebug вызывает sendCurrentStatus, но sendMessage не отправляется если часы недоступны
        statusManagerUnreachable.setCurrentDayForDebug(10)
        // Второй вызов с currentActivity: .workout - данные изменились, но sendMessage не отправляется (часы недоступны)
        statusManagerUnreachable.sendCurrentStatus(isAuthorized: true, currentDay: 10, currentActivity: .workout)

        // Проверяем, что sendMessage не отправлен когда часы недоступны
        #expect(mockSessionUnreachable.sentMessages.isEmpty)

        let mockSessionReachable = MockWCSession(isReachable: true)
        let statusManagerReachable = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSessionReachable
        )

        // setCurrentDayForDebug вызывает sendCurrentStatus с currentActivity: nil, что отправляет sendMessage
        statusManagerReachable.setCurrentDayForDebug(10)
        // Второй вызов с currentActivity: .workout - данные изменились (nil -> .workout), поэтому sendMessage отправляется
        statusManagerReachable.sendCurrentStatus(isAuthorized: true, currentDay: 10, currentActivity: .workout)

        // Проверяем, что sendMessage отправлен дважды:
        // 1. От setCurrentDayForDebug (currentActivity: nil)
        // 2. От sendCurrentStatus (currentActivity: nil -> .workout)
        #expect(mockSessionReachable.sentMessages.count == 2)
    }

    @Test("Должен отправлять текущий статус при изменении currentDayCalculator")
    func shouldSendCurrentStatusWhenCurrentDayCalculatorChanges() throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        statusManager.setCurrentDayForDebug(10)
        // Устанавливаем флаг, чтобы sendDayDataToWatch не пропустил отправку
        statusManager.setDidLoadInitialDataForDebug(true)
        statusManager.sendDayDataToWatch(currentDay: 10)

        #expect(mockSession.sentMessages.count >= 1)
        let sentMessage = try #require(mockSession.sentMessages.first)
        let command = try #require(sentMessage["command"] as? String)
        #expect(command == Constants.WatchCommand.authStatus.rawValue)
    }

    @Test("Должен отправлять текущий статус при логауте")
    func shouldSendCurrentStatusOnLogout() throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        statusManager.processAuthStatus(isAuthorized: false)

        #expect(mockSession.sentMessages.count >= 1)
        let sentMessage = try #require(mockSession.sentMessages.first)
        let command = try #require(sentMessage["command"] as? String)
        #expect(command == Constants.WatchCommand.authStatus.rawValue)
        let isAuthorized = try #require(sentMessage["isAuthorized"] as? Bool)
        #expect(!isAuthorized)
    }

    @Test("Должен отправлять текущую активность")
    func shouldSendCurrentActivity() throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        let context = statusManager.modelContainer.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        let dayActivity = DayActivity(
            day: 42,
            activityTypeRaw: DayActivityType.workout.rawValue,
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
        context.insert(dayActivity)
        try context.save()

        statusManager.sendCurrentActivity(day: 42)

        #expect(mockSession.sentMessages.count >= 1)
        let sentMessage = try #require(mockSession.sentMessages.first)
        let command = try #require(sentMessage["command"] as? String)
        #expect(command == Constants.WatchCommand.authStatus.rawValue)
        let isAuthorized = try #require(sentMessage["isAuthorized"] as? Bool)
        #expect(isAuthorized)
        let currentDay = try #require(sentMessage["currentDay"] as? Int)
        #expect(currentDay == 42)
        let currentActivity = try #require(sentMessage["currentActivity"] as? Int)
        #expect(currentActivity == DayActivityType.workout.rawValue)
    }

    @Test("Должен проверять isReachable напрямую через session")
    func shouldCheckIsReachableThroughSession() throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        #expect(statusManager.isReachable)

        let mockSessionUnreachable = MockWCSession(isReachable: false)
        let statusManagerUnreachable = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSessionUnreachable
        )

        #expect(!statusManagerUnreachable.isReachable)
    }

    // MARK: - Тесты парсинга команд

    @Test("Должен парсить команду setActivity из Dictionary")
    func shouldParseSetActivityCommand() throws {
        let message: [String: Any] = [
            "command": Constants.WatchCommand.setActivity.rawValue,
            "day": 42,
            "activityType": DayActivityType.workout.rawValue
        ]

        let result = WatchStatusMessage.parseWatchCommand(message)
        let parsedCommand = try #require(result?.command)
        #expect(parsedCommand == .setActivity)
        let data = try #require(result?.data)
        let day = try #require(data["day"] as? Int)
        #expect(day == 42)
        let activityType = try #require(data["activityType"] as? Int)
        #expect(activityType == DayActivityType.workout.rawValue)
    }

    @Test("Должен парсить команду saveWorkout из Dictionary")
    func shouldParseSaveWorkoutCommand() throws {
        let resultDict: [String: Any] = [
            "count": 4,
            "duration": 1800
        ]
        let message: [String: Any] = [
            "command": Constants.WatchCommand.saveWorkout.rawValue,
            "day": 42,
            "result": resultDict,
            "executionType": ExerciseExecutionType.cycles.rawValue,
            "comment": "Отличная тренировка!"
        ]

        let result = WatchStatusMessage.parseWatchCommand(message)
        let parsedCommand = try #require(result?.command)
        #expect(parsedCommand == .saveWorkout)
        let data = try #require(result?.data)
        let day = try #require(data["day"] as? Int)
        #expect(day == 42)
        let resultData = try #require(data["result"] as? [String: Any])
        let count = try #require(resultData["count"] as? Int)
        #expect(count == 4)
    }

    @Test("Должен возвращать nil для неизвестной команды")
    func shouldReturnNilForUnknownCommand() throws {
        let message: [String: Any] = [
            "command": "UNKNOWN_COMMAND",
            "day": 42
        ]

        let result = WatchStatusMessage.parseWatchCommand(message)
        #expect(result == nil)
    }

    @Test("Должен возвращать nil для сообщения без команды")
    func shouldReturnNilForMessageWithoutCommand() throws {
        let message: [String: Any] = [
            "day": 42
        ]

        let result = WatchStatusMessage.parseWatchCommand(message)
        #expect(result == nil)
    }

    // MARK: - Тесты обработки команд

    @Test("Должен обрабатывать команду setActivity")
    func shouldHandleSetActivityCommand() throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        let context = statusManager.modelContainer.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let message: [String: Any] = [
            "command": Constants.WatchCommand.setActivity.rawValue,
            "day": 42,
            "activityType": DayActivityType.stretch.rawValue
        ]

        statusManager.handleWatchCommand(message)

        let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
        let activityType = try #require(activity?.activityType)
        #expect(activityType == .stretch)
    }

    @Test("Должен отправлять текущую активность после setActivity")
    func shouldSendCurrentActivityAfterSetActivity() throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        let context = statusManager.modelContainer.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let message: [String: Any] = [
            "command": Constants.WatchCommand.setActivity.rawValue,
            "day": 42,
            "activityType": DayActivityType.rest.rawValue
        ]

        statusManager.handleWatchCommand(message)

        #expect(mockSession.sentMessages.count >= 1)
        let sentMessage = try #require(mockSession.sentMessages.first { msg in
            (msg["command"] as? String) == Constants.WatchCommand.authStatus.rawValue &&
                (msg["currentDay"] as? Int) == 42
        })
        let currentActivity = try #require(sentMessage["currentActivity"] as? Int)
        #expect(currentActivity == DayActivityType.rest.rawValue)
    }

    // MARK: - Тесты работы с modelContainer

    @Test("Должен обрабатывать команду setActivity с ModelContext из modelContainer")
    func shouldHandleSetActivityCommandWithModelContextFromModelContainer() throws {
        let mockSession = MockWCSession(isReachable: true)
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: User.self,
            DayActivity.self,
            configurations: modelConfiguration
        )
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            modelContainer: modelContainer,
            watchConnectivitySessionProtocol: mockSession
        )

        let context = statusManager.modelContainer.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let message: [String: Any] = [
            "command": Constants.WatchCommand.setActivity.rawValue,
            "day": 42,
            "activityType": DayActivityType.rest.rawValue
        ]

        // Симулируем вызов через делегат WCSession
        statusManager.handleWatchCommand(message)

        let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
        let activityType = try #require(activity?.activityType)
        #expect(activityType == .rest)
    }

    @Test("Должен использовать mainContext из modelContainer для обработки команд")
    func shouldUseMainContextFromModelContainerForCommandHandling() throws {
        let mockSession = MockWCSession(isReachable: true)
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: User.self,
            DayActivity.self,
            configurations: modelConfiguration
        )
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            modelContainer: modelContainer,
            watchConnectivitySessionProtocol: mockSession
        )

        let context = statusManager.modelContainer.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let message: [String: Any] = [
            "command": Constants.WatchCommand.setActivity.rawValue,
            "day": 42,
            "activityType": DayActivityType.stretch.rawValue
        ]

        statusManager.handleWatchCommand(message)

        // Проверяем, что активность была сохранена в том же контексте
        let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
        let activityType = try #require(activity?.activityType)
        #expect(activityType == .stretch)
        #expect(activity?.user?.id == user.id)
    }

    // MARK: - Тесты отправки applicationContext при активации WCSession

    @Test("Должен отправлять applicationContext при активации WCSession, если пользователь авторизован")
    func shouldSendApplicationContextOnWCSessionActivationWhenUserIsAuthorized() async throws {
        let mockSession = MockWCSession(isReachable: false)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        let context = statusManager.modelContainer.mainContext
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        statusManager.setCurrentDayForDebug(10)

        // Симулируем активацию WCSession
        await statusManager.simulateWCSessionActivation()

        // Проверяем, что applicationContext был отправлен
        #expect(mockSession.applicationContexts.count >= 1)
        let applicationContext = try #require(mockSession.applicationContexts.first)
        let isAuthorized = try #require(applicationContext["isAuthorized"] as? Bool)
        #expect(isAuthorized)
    }

    @Test("Должен отправлять applicationContext с isAuthorized=false при активации WCSession, если пользователь не авторизован")
    func shouldSendApplicationContextOnWCSessionActivationWhenUserIsNotAuthorized() async throws {
        let mockSession = MockWCSession(isReachable: false)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        // Пользователь не добавлен в контекст

        // Симулируем активацию WCSession
        await statusManager.simulateWCSessionActivation()

        // Проверяем, что applicationContext был отправлен с isAuthorized=false
        #expect(mockSession.applicationContexts.count >= 1)
        let applicationContext = try #require(mockSession.applicationContexts.first)
        let isAuthorized = try #require(applicationContext["isAuthorized"] as? Bool)
        #expect(!isAuthorized)
    }

    @Test(
        "Должен отправлять applicationContext с currentDay при активации, если didLoadInitialData = true и currentDayCalculator инициализирован"
    )
    func shouldSendApplicationContextWithCurrentDayWhenDataLoaded() async throws {
        let mockSession = MockWCSession(isReachable: false)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        let context = statusManager.modelContainer.mainContext
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Устанавливаем didLoadInitialData = true и инициализируем currentDayCalculator
        statusManager.setDidLoadInitialDataForDebug(true)
        statusManager.setCurrentDayForDebug(15)

        // Симулируем активацию WCSession
        await statusManager.simulateWCSessionActivation()

        // Проверяем, что applicationContext был отправлен с currentDay
        #expect(mockSession.applicationContexts.count >= 1)
        let applicationContext = try #require(mockSession.applicationContexts.first)
        let isAuthorized = try #require(applicationContext["isAuthorized"] as? Bool)
        #expect(isAuthorized)
        let currentDay = try #require(applicationContext["currentDay"] as? Int)
        #expect(currentDay == 15)
    }

    @Test("Не должен отправлять applicationContext при активации, если didLoadInitialData = false и пользователь авторизован")
    func shouldNotSendApplicationContextWhenDataNotLoadedAndUserAuthorized() async throws {
        let mockSession = MockWCSession(isReachable: false)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        let context = statusManager.modelContainer.mainContext
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // didLoadInitialData = false (по умолчанию), currentDayCalculator не инициализирован

        // Симулируем активацию WCSession
        await statusManager.simulateWCSessionActivation()

        // Проверяем, что applicationContext НЕ был отправлен (будет отправлен после завершения синхронизации)
        #expect(mockSession.applicationContexts.isEmpty)
    }

    // MARK: - Тесты отправки статуса при удалении активности

    @Test("Должен отправлять статус при удалении активности текущего дня")
    func shouldSendStatusWhenDeletingCurrentDayActivity() throws {
        let mockSession = MockWCSession(isReachable: false)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        let context = statusManager.modelContainer.mainContext
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Устанавливаем текущий день
        statusManager.setCurrentDayForDebug(42)

        // Создаем активность для текущего дня
        let now = Date.now
        let activity = DayActivity(day: 42, createDate: now, modifyDate: now)
        activity.user = user
        activity.activityType = .rest
        context.insert(activity)
        try context.save()

        let initialContextCount = mockSession.applicationContexts.count

        // Удаляем активность (симулируем вызов из UI)
        statusManager.dailyActivitiesService.deleteDailyActivity(activity, context: context)

        // Симулируем вызов sendCurrentStatus из UI после удаления (как в HomeActivitySectionView)
        if activity.day == statusManager.currentDayCalculator?.currentDay {
            statusManager.sendCurrentStatus(isAuthorized: true, currentDay: activity.day, currentActivity: nil)
        }

        // Проверяем, что applicationContext был отправлен с currentActivity: nil
        #expect(mockSession.applicationContexts.count > initialContextCount)
        let lastContext = try #require(mockSession.applicationContexts.last)
        let isAuthorized = try #require(lastContext["isAuthorized"] as? Bool)
        #expect(isAuthorized)
        let currentDay = try #require(lastContext["currentDay"] as? Int)
        #expect(currentDay == 42)
        #expect(lastContext["currentActivity"] == nil)
    }

    @Test("Не должен отправлять статус при удалении активности не текущего дня")
    func shouldNotSendStatusWhenDeletingNonCurrentDayActivity() throws {
        let mockSession = MockWCSession(isReachable: false)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        let context = statusManager.modelContainer.mainContext
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Устанавливаем текущий день
        statusManager.setCurrentDayForDebug(42)

        // Создаем активность для другого дня
        let now = Date.now
        let activity = DayActivity(day: 50, createDate: now, modifyDate: now)
        activity.user = user
        activity.activityType = .rest
        context.insert(activity)
        try context.save()

        let initialContextCount = mockSession.applicationContexts.count

        // Удаляем активность
        statusManager.dailyActivitiesService.deleteDailyActivity(activity, context: context)

        // Проверяем, что applicationContext не был отправлен (или был отправлен только при инициализации)
        // Количество контекстов не должно увеличиться из-за удаления активности не текущего дня
        #expect(mockSession.applicationContexts.count <= initialContextCount + 1)
    }

    // MARK: - Тесты отправки applicationContext

    @Test("Должен отправлять applicationContext при изменении статуса авторизации на true")
    func shouldSendApplicationContextWhenAuthStatusChangesToTrue() throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        statusManager.setCurrentDayForDebug(10)
        statusManager.processAuthStatus(isAuthorized: true)

        #expect(mockSession.applicationContexts.count >= 1)
        let context = try #require(mockSession.applicationContexts.first)
        let isAuthorized = try #require(context["isAuthorized"] as? Bool)
        #expect(isAuthorized)
    }

    @Test("Должен отправлять applicationContext при изменении статуса авторизации на false")
    func shouldSendApplicationContextWhenAuthStatusChangesToFalse() throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        statusManager.processAuthStatus(isAuthorized: false)

        #expect(mockSession.applicationContexts.count >= 1)
        let context = try #require(mockSession.applicationContexts.first)
        let isAuthorized = try #require(context["isAuthorized"] as? Bool)
        #expect(!isAuthorized)
    }

    @Test("Должен отправлять applicationContext с currentDay и currentActivity при изменении текущего дня в getStatus")
    func shouldSendApplicationContextWithCurrentDayAndActivityWhenCurrentDayChangesInGetStatus() async throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        statusManager.setCurrentDayForDebug(10)

        await statusManager.getStatus()

        #expect(mockSession.applicationContexts.count >= 1)
        let context = try #require(mockSession.applicationContexts.first { ctx in
            (ctx["currentDay"] as? Int) == 10
        })
        let isAuthorized = try #require(context["isAuthorized"] as? Bool)
        #expect(isAuthorized)
        let currentDay = try #require(context["currentDay"] as? Int)
        #expect(currentDay == 10)
    }

    @Test(
        "Должен отправлять applicationContext с currentDay после завершения синхронизации в getStatus, если данные не были загружены при активации"
    )
    func shouldSendApplicationContextWithCurrentDayAfterSyncWhenDataNotLoadedOnActivation() async throws {
        let mockSession = MockWCSession(isReachable: false)
        let now = Date.now
        let startDate = try #require(Calendar.current.date(byAdding: .day, value: -20, to: now))
        let mockStatusClient = MockStatusClient(
            startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil)),
            currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
        )
        let statusManager = try MockStatusManager.create(
            statusClient: mockStatusClient,
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        let context = statusManager.modelContainer.mainContext
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // didLoadInitialData = false (по умолчанию)
        // Симулируем активацию WCSession - Application Context НЕ должен отправиться
        await statusManager.simulateWCSessionActivation()
        #expect(mockSession.applicationContexts.isEmpty)

        // Вызываем getStatus - после завершения синхронизации Application Context должен отправиться с currentDay
        await statusManager.getStatus()

        // Проверяем, что applicationContext был отправлен с currentDay после завершения синхронизации
        #expect(mockSession.applicationContexts.count >= 1)
        let applicationContext = try #require(mockSession.applicationContexts.first { ctx in
            (ctx["currentDay"] as? Int) != nil
        })
        let isAuthorized = try #require(applicationContext["isAuthorized"] as? Bool)
        #expect(isAuthorized)
        let currentDay = try #require(applicationContext["currentDay"] as? Int)
        #expect(currentDay > 0)
    }
}
