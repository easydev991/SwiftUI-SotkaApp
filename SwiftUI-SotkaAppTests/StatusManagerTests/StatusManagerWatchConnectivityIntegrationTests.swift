import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing
import WatchConnectivity

@MainActor
@Suite("Интеграционные тесты WatchConnectivity между часами и iPhone")
struct StatusManagerWatchConnectivityIntegrationTests {
    // MARK: - Тесты синхронизации между часами и iPhone

    @Test("Должен синхронизировать установку активности с часов на iPhone")
    func shouldSyncSetActivityFromWatchToPhone() throws {
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

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
        let activityType = try #require(activity?.activityType)
        #expect(activityType == .rest)

        let reply = try #require(replyReceived)
        #expect(reply.isEmpty)

        #expect(mockSession.sentMessages.count == 1)
    }

    @Test("Должен синхронизировать сохранение тренировки с часов на iPhone")
    func shouldSyncSaveWorkoutFromWatchToPhone() throws {
        let mockSession = MockWCSession(isReachable: true)
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: User.self,
            DayActivity.self,
            DayActivityTraining.self,
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

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
        let activityType = try #require(activity?.activityType)
        #expect(activityType == .workout)
        let count = try #require(activity?.count)
        #expect(count == 4)
        let duration = try #require(activity?.duration)
        #expect(duration == 1800)
        let comment = try #require(activity?.comment)
        #expect(comment == "Отличная тренировка!")

        let reply = try #require(replyReceived)
        #expect(reply.isEmpty)

        #expect(mockSession.sentMessages.count == 1)
    }

    @Test("Должен синхронизировать получение текущей активности с часов на iPhone")
    func shouldSyncGetCurrentActivityFromWatchToPhone() throws {
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
        let dayActivity = DayActivity(
            day: 42,
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
        context.insert(dayActivity)
        try context.save()

        let message: [String: Any] = [
            "command": Constants.WatchCommand.getCurrentActivity.rawValue,
            "day": 42
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let reply = try #require(replyReceived)
        let command = try #require(reply["command"] as? String)
        #expect(command == Constants.WatchCommand.currentActivity.rawValue)
        let day = try #require(reply["day"] as? Int)
        #expect(day == 42)
        let activityType = try #require(reply["activityType"] as? Int)
        #expect(activityType == DayActivityType.stretch.rawValue)
    }

    @Test("Должен синхронизировать получение данных тренировки с часов на iPhone")
    func shouldSyncGetWorkoutDataFromWatchToPhone() throws {
        let mockSession = MockWCSession(isReachable: true)
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: User.self,
            DayActivity.self,
            DayActivityTraining.self,
            configurations: modelConfiguration
        )
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            modelContainer: modelContainer,
            watchConnectivitySessionProtocol: mockSession
        )

        let message: [String: Any] = [
            "command": Constants.WatchCommand.getWorkoutData.rawValue,
            "day": 42
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let reply = try #require(replyReceived)
        let command = try #require(reply["command"] as? String)
        #expect(command == Constants.WatchCommand.sendWorkoutData.rawValue)
        let workoutData = try #require(reply["workoutData"] as? [String: Any])
        let day = try #require(workoutData["day"] as? Int)
        #expect(day == 42)
    }

    @Test("Должен синхронизировать удаление активности с часов на iPhone")
    func shouldSyncDeleteActivityFromWatchToPhone() throws {
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
        let dayActivity = DayActivity(
            day: 42,
            activityTypeRaw: DayActivityType.rest.rawValue,
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

        let message: [String: Any] = [
            "command": Constants.WatchCommand.deleteActivity.rawValue,
            "day": 42
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
        #expect(activity == nil)

        let reply = try #require(replyReceived)
        #expect(reply.isEmpty)

        #expect(mockSession.sentMessages.count == 1)
    }

    // MARK: - Тесты обработки команд WatchConnectivity

    @Test("Должен обрабатывать команду setActivity с replyHandler")
    func shouldHandleSetActivityCommandWithReplyHandler() throws {
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
            "activityType": DayActivityType.sick.rawValue
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
        let activityType = try #require(activity?.activityType)
        #expect(activityType == .sick)

        let reply = try #require(replyReceived)
        #expect(reply.isEmpty)
    }

    @Test("Должен обрабатывать команду saveWorkout с replyHandler")
    func shouldHandleSaveWorkoutCommandWithReplyHandler() throws {
        let mockSession = MockWCSession(isReachable: true)
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: User.self,
            DayActivity.self,
            DayActivityTraining.self,
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

        let resultDict: [String: Any] = [
            "count": 5,
            "duration": 2000
        ]
        let message: [String: Any] = [
            "command": Constants.WatchCommand.saveWorkout.rawValue,
            "day": 42,
            "result": resultDict,
            "executionType": ExerciseExecutionType.cycles.rawValue,
            "comment": "Хорошая тренировка"
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
        let activityType = try #require(activity?.activityType)
        #expect(activityType == .workout)

        let reply = try #require(replyReceived)
        #expect(reply.isEmpty)
    }

    @Test("Должен обрабатывать команду getCurrentActivity с replyHandler")
    func shouldHandleGetCurrentActivityCommandWithReplyHandler() throws {
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
        let dayActivity = DayActivity(
            day: 42,
            activityTypeRaw: DayActivityType.rest.rawValue,
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

        let message: [String: Any] = [
            "command": Constants.WatchCommand.getCurrentActivity.rawValue,
            "day": 42
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let reply = try #require(replyReceived)
        let command = try #require(reply["command"] as? String)
        #expect(command == Constants.WatchCommand.currentActivity.rawValue)
        let day = try #require(reply["day"] as? Int)
        #expect(day == 42)
        let activityType = try #require(reply["activityType"] as? Int)
        #expect(activityType == DayActivityType.rest.rawValue)
    }

    @Test("Должен обрабатывать команду getWorkoutData с replyHandler")
    func shouldHandleGetWorkoutDataCommandWithReplyHandler() throws {
        let mockSession = MockWCSession(isReachable: true)
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: User.self,
            DayActivity.self,
            DayActivityTraining.self,
            configurations: modelConfiguration
        )
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            modelContainer: modelContainer,
            watchConnectivitySessionProtocol: mockSession
        )

        let message: [String: Any] = [
            "command": Constants.WatchCommand.getWorkoutData.rawValue,
            "day": 42
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let reply = try #require(replyReceived)
        let command = try #require(reply["command"] as? String)
        #expect(command == Constants.WatchCommand.sendWorkoutData.rawValue)
    }

    @Test("Должен обрабатывать команду deleteActivity с replyHandler")
    func shouldHandleDeleteActivityCommandWithReplyHandler() throws {
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
        let dayActivity = DayActivity(
            day: 42,
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
        context.insert(dayActivity)
        try context.save()

        let message: [String: Any] = [
            "command": Constants.WatchCommand.deleteActivity.rawValue,
            "day": 42
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
        #expect(activity == nil)

        let reply = try #require(replyReceived)
        #expect(reply.isEmpty)
    }

    @Test("Должен возвращать ошибку для неизвестной команды")
    func shouldReturnErrorForUnknownCommand() throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        let message: [String: Any] = [
            "command": "UNKNOWN_COMMAND",
            "day": 42
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let reply = try #require(replyReceived)
        let error = try #require(reply["error"] as? String)
        #expect(error == "Неизвестная команда")
    }

    @Test("Должен возвращать ошибку для команды setActivity с неверным форматом данных")
    func shouldReturnErrorForSetActivityWithInvalidData() throws {
        let mockSession = MockWCSession(isReachable: true)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        let message: [String: Any] = [
            "command": Constants.WatchCommand.setActivity.rawValue,
            "day": "invalid"
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let reply = try #require(replyReceived)
        let error = try #require(reply["error"] as? String)
        #expect(error == "Неверный формат данных")
    }

    // MARK: - Тесты обработки ошибок при отсутствии связи с iPhone

    @Test("Должен возвращать false для isReachable когда сессия недоступна")
    func shouldReturnFalseForIsReachableWhenSessionUnavailable() throws {
        let mockSession = MockWCSession(isReachable: false)
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            watchConnectivitySessionProtocol: mockSession
        )

        #expect(!statusManager.isReachable)
    }

    @Test("Должен обрабатывать команду setActivity когда сессия недоступна")
    func shouldHandleSetActivityCommandWhenSessionUnavailable() throws {
        let mockSession = MockWCSession(isReachable: false)
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

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
        let activityType = try #require(activity?.activityType)
        #expect(activityType == .rest)

        let reply = try #require(replyReceived)
        #expect(reply.isEmpty)

        #expect(mockSession.sentMessages.isEmpty)
    }

    @Test("Должен обрабатывать команду saveWorkout когда сессия недоступна")
    func shouldHandleSaveWorkoutCommandWhenSessionUnavailable() throws {
        let mockSession = MockWCSession(isReachable: false)
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: User.self,
            DayActivity.self,
            DayActivityTraining.self,
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

        let resultDict: [String: Any] = [
            "count": 3,
            "duration": 1500
        ]
        let message: [String: Any] = [
            "command": Constants.WatchCommand.saveWorkout.rawValue,
            "day": 42,
            "result": resultDict,
            "executionType": ExerciseExecutionType.cycles.rawValue
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
        let activityType = try #require(activity?.activityType)
        #expect(activityType == .workout)

        let reply = try #require(replyReceived)
        #expect(reply.isEmpty)

        #expect(mockSession.sentMessages.isEmpty)
    }

    @Test("Должен обрабатывать команду getCurrentActivity когда сессия недоступна")
    func shouldHandleGetCurrentActivityCommandWhenSessionUnavailable() throws {
        let mockSession = MockWCSession(isReachable: false)
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
        let dayActivity = DayActivity(
            day: 42,
            activityTypeRaw: DayActivityType.rest.rawValue,
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

        let message: [String: Any] = [
            "command": Constants.WatchCommand.getCurrentActivity.rawValue,
            "day": 42
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let reply = try #require(replyReceived)
        let command = try #require(reply["command"] as? String)
        #expect(command == Constants.WatchCommand.currentActivity.rawValue)

        #expect(mockSession.sentMessages.isEmpty)
    }

    @Test("Должен обрабатывать команду getWorkoutData когда сессия недоступна")
    func shouldHandleGetWorkoutDataCommandWhenSessionUnavailable() throws {
        let mockSession = MockWCSession(isReachable: false)
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: User.self,
            DayActivity.self,
            DayActivityTraining.self,
            configurations: modelConfiguration
        )
        let statusManager = try MockStatusManager.create(
            daysClient: MockDaysClient(),
            userDefaults: MockUserDefaults.create(),
            modelContainer: modelContainer,
            watchConnectivitySessionProtocol: mockSession
        )

        let message: [String: Any] = [
            "command": Constants.WatchCommand.getWorkoutData.rawValue,
            "day": 42
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let reply = try #require(replyReceived)
        let command = try #require(reply["command"] as? String)
        #expect(command == Constants.WatchCommand.sendWorkoutData.rawValue)

        #expect(mockSession.sentMessages.isEmpty)
    }

    @Test("Должен обрабатывать команду deleteActivity когда сессия недоступна")
    func shouldHandleDeleteActivityCommandWhenSessionUnavailable() throws {
        let mockSession = MockWCSession(isReachable: false)
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
        let dayActivity = DayActivity(
            day: 42,
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
        context.insert(dayActivity)
        try context.save()

        let message: [String: Any] = [
            "command": Constants.WatchCommand.deleteActivity.rawValue,
            "day": 42
        ]

        var replyReceived: [String: Any]?
        statusManager.handleWatchCommand(message) { reply in
            replyReceived = reply
        }

        let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
        #expect(activity == nil)

        let reply = try #require(replyReceived)
        #expect(reply.isEmpty)

        #expect(mockSession.sentMessages.isEmpty)
    }
}
