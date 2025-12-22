import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerWatchConnectivityTests.IntegrationTests {
    @Suite("Тесты полного сценария запуска")
    @MainActor
    struct FullStartupScenarios {
        @Test("Полный сценарий запуска при авторизованном пользователе с полными данными")
        func fullStartupScenarioWithAuthorizedUserAndFullData() async throws {
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

            statusManager.setCurrentDayForDebug(42)

            let initialApplicationContextCount = mockSession.applicationContexts.count
            let initialSentMessagesCount = mockSession.sentMessages.count

            await statusManager.simulateWCSessionActivation()

            let applicationContextAfterActivation = try #require(mockSession.applicationContexts.last)
            let isAuthorizedAfterActivation = try #require(applicationContextAfterActivation["isAuthorized"] as? Bool)
            #expect(isAuthorizedAfterActivation)
            #expect(applicationContextAfterActivation["currentDay"] == nil)
            #expect(applicationContextAfterActivation["currentActivity"] == nil)
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 1)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount)

            statusManager.setDidLoadInitialDataForDebug(true)
            statusManager.sendDayDataToWatch(currentDay: 42)

            let applicationContextAfterLoad = try #require(mockSession.applicationContexts.last)
            let isAuthorizedAfterLoad = try #require(applicationContextAfterLoad["isAuthorized"] as? Bool)
            let currentDayAfterLoad = try #require(applicationContextAfterLoad["currentDay"] as? Int)
            let currentActivityAfterLoad = try #require(applicationContextAfterLoad["currentActivity"] as? Int)
            #expect(isAuthorizedAfterLoad)
            #expect(currentDayAfterLoad == 42)
            #expect(currentActivityAfterLoad == DayActivityType.workout.rawValue)
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 2)

            let sentMessage = try #require(mockSession.sentMessages.last)
            let command = try #require(sentMessage["command"] as? String)
            let isAuthorizedInMessage = try #require(sentMessage["isAuthorized"] as? Bool)
            let currentDayInMessage = try #require(sentMessage["currentDay"] as? Int)
            let currentActivityInMessage = try #require(sentMessage["currentActivity"] as? Int)
            #expect(command == Constants.WatchCommand.authStatus.rawValue)
            #expect(isAuthorizedInMessage)
            #expect(currentDayInMessage == 42)
            #expect(currentActivityInMessage == DayActivityType.workout.rawValue)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount + 1)
        }

        @Test("Полный сценарий запуска при неавторизованном пользователе")
        func fullStartupScenarioWithUnauthorizedUser() async throws {
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

            let initialApplicationContextCount = mockSession.applicationContexts.count
            let initialSentMessagesCount = mockSession.sentMessages.count

            await statusManager.simulateWCSessionActivation()

            let applicationContextAfterActivation = try #require(mockSession.applicationContexts.last)
            let isAuthorizedAfterActivation = try #require(applicationContextAfterActivation["isAuthorized"] as? Bool)
            #expect(!isAuthorizedAfterActivation)
            #expect(applicationContextAfterActivation["currentDay"] == nil)
            #expect(applicationContextAfterActivation["currentActivity"] == nil)
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 1)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount)

            statusManager.setDidLoadInitialDataForDebug(true)
            statusManager.sendDayDataToWatch(currentDay: nil)

            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 1)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount)
        }

        @Test("Полный сценарий запуска с задержкой загрузки данных")
        func fullStartupScenarioWithDelayedDataLoad() async throws {
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

            let initialApplicationContextCount = mockSession.applicationContexts.count
            let initialSentMessagesCount = mockSession.sentMessages.count

            await statusManager.simulateWCSessionActivation()

            let applicationContextAfterActivation = try #require(mockSession.applicationContexts.last)
            let isAuthorizedAfterActivation = try #require(applicationContextAfterActivation["isAuthorized"] as? Bool)
            #expect(isAuthorizedAfterActivation)
            #expect(applicationContextAfterActivation["currentDay"] == nil)
            #expect(applicationContextAfterActivation["currentActivity"] == nil)
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 1)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount)

            statusManager.setCurrentDayForDebug(42)
            statusManager.setDidLoadInitialDataForDebug(true)
            statusManager.sendDayDataToWatch(currentDay: 42)

            let applicationContextAfterLoad = try #require(mockSession.applicationContexts.last)
            let isAuthorizedAfterLoad = try #require(applicationContextAfterLoad["isAuthorized"] as? Bool)
            let currentDayAfterLoad = try #require(applicationContextAfterLoad["currentDay"] as? Int)
            let currentActivityAfterLoad = try #require(applicationContextAfterLoad["currentActivity"] as? Int)
            #expect(isAuthorizedAfterLoad)
            #expect(currentDayAfterLoad == 42)
            #expect(currentActivityAfterLoad == DayActivityType.workout.rawValue)
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 2)

            let sentMessage = try #require(mockSession.sentMessages.last)
            let command = try #require(sentMessage["command"] as? String)
            let isAuthorizedInMessage = try #require(sentMessage["isAuthorized"] as? Bool)
            let currentDayInMessage = try #require(sentMessage["currentDay"] as? Int)
            let currentActivityInMessage = try #require(sentMessage["currentActivity"] as? Int)
            #expect(command == Constants.WatchCommand.authStatus.rawValue)
            #expect(isAuthorizedInMessage)
            #expect(currentDayInMessage == 42)
            #expect(currentActivityInMessage == DayActivityType.workout.rawValue)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount + 1)
        }

        @Test("Обработка ошибок при отсутствии связи")
        func errorHandlingWhenConnectionUnavailable() async throws {
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

            statusManager.setCurrentDayForDebug(42)
            statusManager.setDidLoadInitialDataForDebug(true)

            let initialApplicationContextCount = mockSession.applicationContexts.count
            let initialSentMessagesCount = mockSession.sentMessages.count

            // 1. Отправляем данные когда часы недоступны
            statusManager.sendDayDataToWatch(currentDay: 42)

            // 2. Проверяем, что applicationContext отправлен (всегда отправляется)
            let applicationContextWhenUnreachable = try #require(mockSession.applicationContexts.last)
            let isAuthorizedWhenUnreachable = try #require(applicationContextWhenUnreachable["isAuthorized"] as? Bool)
            let currentDayWhenUnreachable = try #require(applicationContextWhenUnreachable["currentDay"] as? Int)
            let currentActivityWhenUnreachable = try #require(applicationContextWhenUnreachable["currentActivity"] as? Int)
            #expect(isAuthorizedWhenUnreachable)
            #expect(currentDayWhenUnreachable == 42)
            #expect(currentActivityWhenUnreachable == DayActivityType.workout.rawValue)
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 1)

            // 3. Проверяем, что sendMessage НЕ отправлен когда часы недоступны
            #expect(mockSession.sentMessages.count == initialSentMessagesCount)

            // 4. Имитируем восстановление связи
            mockSession.isReachable = true

            // 5. Отправляем данные снова после восстановления связи
            statusManager.sendDayDataToWatch(currentDay: 42)

            // 6. Проверяем, что applicationContext обновлен
            let applicationContextAfterReconnect = try #require(mockSession.applicationContexts.last)
            let isAuthorizedAfterReconnect = try #require(applicationContextAfterReconnect["isAuthorized"] as? Bool)
            let currentDayAfterReconnect = try #require(applicationContextAfterReconnect["currentDay"] as? Int)
            let currentActivityAfterReconnect = try #require(applicationContextAfterReconnect["currentActivity"] as? Int)
            #expect(isAuthorizedAfterReconnect)
            #expect(currentDayAfterReconnect == 42)
            #expect(currentActivityAfterReconnect == DayActivityType.workout.rawValue)
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 2)

            // 7. Проверяем, что sendMessage отправлен после восстановления связи
            let sentMessage = try #require(mockSession.sentMessages.last)
            let command = try #require(sentMessage["command"] as? String)
            let isAuthorizedInMessage = try #require(sentMessage["isAuthorized"] as? Bool)
            let currentDayInMessage = try #require(sentMessage["currentDay"] as? Int)
            let currentActivityInMessage = try #require(sentMessage["currentActivity"] as? Int)
            #expect(command == Constants.WatchCommand.authStatus.rawValue)
            #expect(isAuthorizedInMessage)
            #expect(currentDayInMessage == 42)
            #expect(currentActivityInMessage == DayActivityType.workout.rawValue)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount + 1)
        }

        @Test("Последовательность вызовов при изменении currentDay на iPhone")
        func sequenceWhenCurrentDayChangesOniPhone() async throws {
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

            let dayActivity42 = DayActivity(
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
            context.insert(dayActivity42)

            let dayActivity43 = DayActivity(
                day: 43,
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
            context.insert(dayActivity43)
            try context.save()

            statusManager.setDidLoadInitialDataForDebug(true)

            let initialApplicationContextCount = mockSession.applicationContexts.count
            let initialSentMessagesCount = mockSession.sentMessages.count

            // 1. Отправляем данные для дня 42
            statusManager.setCurrentDayForDebug(42)
            statusManager.sendDayDataToWatch(currentDay: 42)

            let applicationContextAfterDay42 = try #require(mockSession.applicationContexts.last)
            let currentDayAfter42 = try #require(applicationContextAfterDay42["currentDay"] as? Int)
            let currentActivityAfter42 = try #require(applicationContextAfterDay42["currentActivity"] as? Int)
            #expect(currentDayAfter42 == 42)
            #expect(currentActivityAfter42 == DayActivityType.workout.rawValue)
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 1)

            let sentMessageAfter42 = try #require(mockSession.sentMessages.last)
            let currentDayInMessage42 = try #require(sentMessageAfter42["currentDay"] as? Int)
            #expect(currentDayInMessage42 == 42)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount + 1)

            // 2. Изменяем currentDay на 43 и отправляем
            statusManager.setCurrentDayForDebug(43)
            statusManager.sendDayDataToWatch(currentDay: 43)

            let applicationContextAfterDay43 = try #require(mockSession.applicationContexts.last)
            let currentDayAfter43 = try #require(applicationContextAfterDay43["currentDay"] as? Int)
            let currentActivityAfter43 = try #require(applicationContextAfterDay43["currentActivity"] as? Int)
            #expect(currentDayAfter43 == 43)
            #expect(currentActivityAfter43 == DayActivityType.stretch.rawValue)
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 2)

            let sentMessageAfter43 = try #require(mockSession.sentMessages.last)
            let currentDayInMessage43 = try #require(sentMessageAfter43["currentDay"] as? Int)
            #expect(currentDayInMessage43 == 43)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount + 2)

            // 3. Отправляем тот же currentDay еще раз (проверка дедупликации)
            statusManager.sendDayDataToWatch(currentDay: 43)

            // 4. Проверяем, что applicationContext обновлен (всегда обновляется)
            let applicationContextAfterDuplicate = try #require(mockSession.applicationContexts.last)
            let currentDayAfterDuplicate = try #require(applicationContextAfterDuplicate["currentDay"] as? Int)
            #expect(currentDayAfterDuplicate == 43)
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 3)

            // 5. Проверяем, что sendMessage НЕ отправлен повторно (дедупликация работает)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount + 2)
        }
    }
}
