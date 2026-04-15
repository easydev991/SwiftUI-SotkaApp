import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerWatchConnectivityTests {
    @MainActor
    @Suite("Тесты Watch Connectivity для офлайн-пользователя")
    struct OfflineTests {
        @Test("getStatus для офлайн-пользователя не отправляет sendMessage на часы")
        func getStatusForOfflineUserDoesNotSendWatchMessage() async throws {
            let mockSession = MockWCSession(isReachable: true)
            let mockStatusClient = MockStatusClient()

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            await statusManager.getStatus()

            // getStatus для офлайн-пользователя не должен вызывать sendMessage
            // (applicationContext может быть отправлен, но sendMessage — нет)
            let authStatusMessages = mockSession.sentMessages.filter { message in
                (message["command"] as? String) == Constants.WatchCommand.authStatus.rawValue
            }
            #expect(authStatusMessages.isEmpty)
            #expect(mockSession.applicationContexts.isEmpty)
        }

        @Test("sendCurrentStatus отправляет локальные данные офлайн-пользователя на часы")
        func sendCurrentStatusSendsOfflineUserDataToWatch() throws {
            let mockSession = MockWCSession(isReachable: true)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            // Офлайн-пользователь — локальные данные должны отправляться на часы
            statusManager.sendCurrentStatus(isAuthorized: true, currentDay: 5, currentActivity: .workout)

            #expect(mockSession.sentMessages.count >= 1)
            let sentMessage = try #require(mockSession.sentMessages.first)
            let command = try #require(sentMessage["command"] as? String)
            #expect(command == Constants.WatchCommand.authStatus.rawValue)
            let isAuthorized = try #require(sentMessage["isAuthorized"] as? Bool)
            #expect(isAuthorized)
            let currentDay = try #require(sentMessage["currentDay"] as? Int)
            #expect(currentDay == 5)
            let currentActivity = try #require(sentMessage["currentActivity"] as? Int)
            #expect(currentActivity == DayActivityType.workout.rawValue)
        }

        @Test("sendDayDataToWatch отправляет данные дня для офлайн-пользователя после didLoadInitialData")
        func sendDayDataToWatchWorksForOfflineUserAfterInitialLoad() throws {
            let mockSession = MockWCSession(isReachable: true)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            // Симулируем, что данные уже загружены (после getStatus)
            statusManager.setDidLoadInitialDataForDebug(true)

            // sendDayDataToWatch должен отправить данные на часы
            statusManager.sendDayDataToWatch(currentDay: 3)

            #expect(mockSession.sentMessages.count >= 1)
            let sentMessage = try #require(mockSession.sentMessages.first)
            let command = try #require(sentMessage["command"] as? String)
            #expect(command == Constants.WatchCommand.authStatus.rawValue)
            let currentDay = try #require(sentMessage["currentDay"] as? Int)
            #expect(currentDay == 3)
        }

        @Test("handleWatchCommand(setActivity) сохраняет активность локально для офлайн-пользователя")
        func handleSetActivityCommandSavesActivityForOfflineUser() throws {
            let mockSession = MockWCSession(isReachable: true)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            let message: [String: Any] = [
                "command": Constants.WatchCommand.setActivity.rawValue,
                "day": 7,
                "activityType": DayActivityType.stretch.rawValue
            ]

            statusManager.handleWatchCommand(message)

            // Проверяем, что активность сохранена локально
            let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 7, context: context)
            let activityType = try #require(activity?.activityType)
            #expect(activityType == .stretch)

            // Проверяем, что ответ отправлен на часы
            #expect(mockSession.sentMessages.count >= 1)
        }

        @Test("handleWatchCommand(saveWorkout) сохраняет тренировку локально для офлайн-пользователя")
        func handleSaveWorkoutCommandSavesWorkoutForOfflineUser() throws {
            let mockSession = MockWCSession(isReachable: true)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            let workoutResult: [String: Any] = [
                "count": 5,
                "duration": 1800
            ]
            let message: [String: Any] = [
                "command": Constants.WatchCommand.saveWorkout.rawValue,
                "day": 10,
                "result": workoutResult,
                "executionType": ExerciseExecutionType.cycles.rawValue,
                "comment": "Офлайн тренировка"
            ]

            statusManager.handleWatchCommand(message)

            // Проверяем, что тренировка сохранена локально
            let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 10, context: context)
            #expect(activity != nil)
            let activityType = try #require(activity?.activityType)
            #expect(activityType == .workout)
            #expect(activity?.count == 5)

            // Проверяем, что ответ отправлен на часы
            #expect(mockSession.sentMessages.count >= 1)
        }

        @Test("sendApplicationContextOnActivation отправляет applicationContext для офлайн-пользователя после didLoadInitialData")
        func sendApplicationContextOnActivationSendsForOfflineUserAfterLoad() async throws {
            let mockSession = MockWCSession(isReachable: true)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            // Инициализируем currentDayCalculator через офлайн-путь без debug-отправки на часы
            let fiveDaysAgo = try #require(Calendar.current.date(byAdding: .day, value: -4, to: .now))
            await statusManager.startNewRun(appDate: fiveDaysAgo)
            statusManager.setDidLoadInitialDataForDebug(true)
            let contextsBeforeActivation = mockSession.applicationContexts.count

            // Вызываем sendApplicationContextOnActivation
            statusManager.sendApplicationContextOnActivation()

            // applicationContext должен быть отправлен с isAuthorized: true и currentDay
            #expect(mockSession.applicationContexts.count == contextsBeforeActivation + 1)
            let appContext = try #require(mockSession.applicationContexts.last)
            let isAuthorized = try #require(appContext["isAuthorized"] as? Bool)
            #expect(isAuthorized)
            let currentDay = try #require(appContext["currentDay"] as? Int)
            #expect(currentDay >= 1)
        }

        @Test("sendApplicationContextOnActivation не отправляет applicationContext, если офлайн-пользователь не загружен")
        func sendApplicationContextOnActivationSkipsForOfflineUserNotLoaded() throws {
            let mockSession = MockWCSession(isReachable: true)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            // didLoadInitialData = false (данные ещё не загружены)
            statusManager.setDidLoadInitialDataForDebug(false)

            // Вызываем sendApplicationContextOnActivation
            statusManager.sendApplicationContextOnActivation()

            // При isAuthorized: true и didLoadInitialData: false — отправка должна быть пропущена
            // (для офлайн-пользователя isAuthorized проверяется через fetch User)
            #expect(mockSession.applicationContexts.isEmpty)
        }

        @Test("processAuthStatus(true) отправляет isAuthorized=true на часы для офлайн-пользователя")
        func processAuthStatusAuthorizeSendsAuthorizedStatusForOfflineUser() throws {
            let mockSession = MockWCSession(isReachable: true)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            statusManager.processAuthStatus(isAuthorized: true)

            let sentMessage = try #require(mockSession.sentMessages.last)
            let command = try #require(sentMessage["command"] as? String)
            #expect(command == Constants.WatchCommand.authStatus.rawValue)
            let isAuthorized = try #require(sentMessage["isAuthorized"] as? Bool)
            #expect(isAuthorized)
        }

        @Test("processAuthStatus(false) отправляет isAuthorized=false на часы для офлайн-пользователя")
        func processAuthStatusLogoutSendsUnauthorizedStatusForOfflineUser() throws {
            let mockSession = MockWCSession(isReachable: true)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            statusManager.processAuthStatus(isAuthorized: false)

            let sentMessage = try #require(mockSession.sentMessages.last)
            let command = try #require(sentMessage["command"] as? String)
            #expect(command == Constants.WatchCommand.authStatus.rawValue)
            let isAuthorized = try #require(sentMessage["isAuthorized"] as? Bool)
            #expect(!isAuthorized)
        }
    }
}
