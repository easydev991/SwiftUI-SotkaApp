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

            let initialSentMessagesCount = mockSession.sentMessages.count

            statusManager.setCurrentDayForDebug(42)
            // setCurrentDayForDebug вызывает sendCurrentStatus, что отправляет applicationContext и sendMessage
            let applicationContextAfterSetDay = mockSession.applicationContexts.count
            let sentMessagesAfterSetDay = mockSession.sentMessages.count

            await statusManager.simulateWCSessionActivation()

            // Application Context НЕ отправляется при активации, если didLoadInitialData = false и пользователь авторизован
            // Будет отправлен после завершения синхронизации с полными данными
            #expect(mockSession.applicationContexts.count == applicationContextAfterSetDay)
            #expect(mockSession.sentMessages.count == sentMessagesAfterSetDay)

            statusManager.setDidLoadInitialDataForDebug(true)
            statusManager.sendDayDataToWatch(currentDay: 42)

            let applicationContextAfterLoad = try #require(mockSession.applicationContexts.last)
            let isAuthorizedAfterLoad = try #require(applicationContextAfterLoad["isAuthorized"] as? Bool)
            let currentDayAfterLoad = try #require(applicationContextAfterLoad["currentDay"] as? Int)
            let currentActivityAfterLoad = try #require(applicationContextAfterLoad["currentActivity"] as? Int)
            #expect(isAuthorizedAfterLoad)
            #expect(currentDayAfterLoad == 42)
            #expect(currentActivityAfterLoad == DayActivityType.workout.rawValue)
            // applicationContext отправляется: 1) от setCurrentDayForDebug, 2) от sendDayDataToWatch
            #expect(mockSession.applicationContexts.count == applicationContextAfterSetDay + 1)

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

            // Application Context НЕ отправляется при активации, если didLoadInitialData = false и пользователь авторизован
            // Будет отправлен после завершения синхронизации с полными данными
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount)

            // setCurrentDayForDebug вызывает sendCurrentStatus, что отправляет applicationContext
            statusManager.setCurrentDayForDebug(42)
            statusManager.setDidLoadInitialDataForDebug(true)
            // sendDayDataToWatch вызывает sendCurrentStatus, что отправляет applicationContext еще раз
            statusManager.sendDayDataToWatch(currentDay: 42)

            let applicationContextAfterLoad = try #require(mockSession.applicationContexts.last)
            let isAuthorizedAfterLoad = try #require(applicationContextAfterLoad["isAuthorized"] as? Bool)
            let currentDayAfterLoad = try #require(applicationContextAfterLoad["currentDay"] as? Int)
            let currentActivityAfterLoad = try #require(applicationContextAfterLoad["currentActivity"] as? Int)
            #expect(isAuthorizedAfterLoad)
            #expect(currentDayAfterLoad == 42)
            #expect(currentActivityAfterLoad == DayActivityType.workout.rawValue)
            // applicationContext отправляется: 1) от setCurrentDayForDebug, 2) от sendDayDataToWatch
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
        func errorHandlingWhenConnectionUnavailable() throws {
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

            let initialApplicationContextCount = mockSession.applicationContexts.count
            let initialSentMessagesCount = mockSession.sentMessages.count

            // setCurrentDayForDebug вызывает sendCurrentStatus, что отправляет applicationContext
            statusManager.setCurrentDayForDebug(42)
            statusManager.setDidLoadInitialDataForDebug(true)

            // 1. Отправляем данные когда часы недоступны
            // sendDayDataToWatch вызывает sendCurrentStatus, что отправляет applicationContext еще раз
            statusManager.sendDayDataToWatch(currentDay: 42)

            // 2. Проверяем, что applicationContext отправлен (всегда отправляется)
            let applicationContextWhenUnreachable = try #require(mockSession.applicationContexts.last)
            let isAuthorizedWhenUnreachable = try #require(applicationContextWhenUnreachable["isAuthorized"] as? Bool)
            let currentDayWhenUnreachable = try #require(applicationContextWhenUnreachable["currentDay"] as? Int)
            let currentActivityWhenUnreachable = try #require(applicationContextWhenUnreachable["currentActivity"] as? Int)
            #expect(isAuthorizedWhenUnreachable)
            #expect(currentDayWhenUnreachable == 42)
            #expect(currentActivityWhenUnreachable == DayActivityType.workout.rawValue)
            // applicationContext отправляется: 1) от setCurrentDayForDebug, 2) от sendDayDataToWatch
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 2)

            // 3. Проверяем, что sendMessage НЕ отправлен когда часы недоступны
            #expect(mockSession.sentMessages.count == initialSentMessagesCount)

            // 4. Имитируем восстановление связи
            mockSession.isReachable = true

            // 5. Отправляем данные снова после восстановления связи
            // sendDayDataToWatch вызывает sendCurrentStatus, но sendMessage не отправляется, так как данные не изменились
            statusManager.sendDayDataToWatch(currentDay: 42)

            // 6. Проверяем, что applicationContext обновлен
            let applicationContextAfterReconnect = try #require(mockSession.applicationContexts.last)
            let isAuthorizedAfterReconnect = try #require(applicationContextAfterReconnect["isAuthorized"] as? Bool)
            let currentDayAfterReconnect = try #require(applicationContextAfterReconnect["currentDay"] as? Int)
            let currentActivityAfterReconnect = try #require(applicationContextAfterReconnect["currentActivity"] as? Int)
            #expect(isAuthorizedAfterReconnect)
            #expect(currentDayAfterReconnect == 42)
            #expect(currentActivityAfterReconnect == DayActivityType.workout.rawValue)
            // applicationContext отправляется: 1) от setCurrentDayForDebug, 2) от sendDayDataToWatch когда недоступны, 3) от
            // sendDayDataToWatch после восстановления
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 3)

            // 7. Проверяем, что sendMessage НЕ отправлен после восстановления связи (данные не изменились)
            // sendMessage отправляется только если данные изменились, а здесь данные идентичны предыдущим
            #expect(mockSession.sentMessages.count == initialSentMessagesCount)
        }

        @Test("Последовательность вызовов при изменении currentDay на iPhone")
        func sequenceWhenCurrentDayChangesOniPhone() throws {
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
            // setCurrentDayForDebug вызывает sendCurrentStatus, что отправляет applicationContext
            statusManager.setCurrentDayForDebug(42)
            // sendDayDataToWatch вызывает sendCurrentStatus, что отправляет applicationContext еще раз
            statusManager.sendDayDataToWatch(currentDay: 42)

            let applicationContextAfterDay42 = try #require(mockSession.applicationContexts.last)
            let currentDayAfter42 = try #require(applicationContextAfterDay42["currentDay"] as? Int)
            let currentActivityAfter42 = try #require(applicationContextAfterDay42["currentActivity"] as? Int)
            #expect(currentDayAfter42 == 42)
            #expect(currentActivityAfter42 == DayActivityType.workout.rawValue)
            // applicationContext отправляется: 1) от setCurrentDayForDebug, 2) от sendDayDataToWatch
            // Но если initialApplicationContextCount > 0, то нужно учесть это
            #expect(mockSession.applicationContexts.count >= initialApplicationContextCount + 2)

            let sentMessageAfter42 = try #require(mockSession.sentMessages.last)
            let currentDayInMessage42 = try #require(sentMessageAfter42["currentDay"] as? Int)
            #expect(currentDayInMessage42 == 42)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount + 1)

            // 2. Изменяем currentDay на 43 и отправляем
            // setCurrentDayForDebug вызывает sendCurrentStatus, что отправляет applicationContext
            statusManager.setCurrentDayForDebug(43)
            // sendDayDataToWatch вызывает sendCurrentStatus, что отправляет applicationContext еще раз
            statusManager.sendDayDataToWatch(currentDay: 43)

            let applicationContextAfterDay43 = try #require(mockSession.applicationContexts.last)
            let currentDayAfter43 = try #require(applicationContextAfterDay43["currentDay"] as? Int)
            let currentActivityAfter43 = try #require(applicationContextAfterDay43["currentActivity"] as? Int)
            #expect(currentDayAfter43 == 43)
            #expect(currentActivityAfter43 == DayActivityType.stretch.rawValue)
            // applicationContext отправляется: 1) от setCurrentDayForDebug для дня 42, 2) от sendDayDataToWatch для дня 42,
            // 3) от setCurrentDayForDebug для дня 43, 4) от sendDayDataToWatch для дня 43
            // Итого: initialApplicationContextCount + 4
            #expect(mockSession.applicationContexts.count == initialApplicationContextCount + 4)

            let sentMessageAfter43 = try #require(mockSession.sentMessages.last)
            let currentDayInMessage43 = try #require(sentMessageAfter43["currentDay"] as? Int)
            #expect(currentDayInMessage43 == 43)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount + 2)

            // 3. Отправляем тот же currentDay еще раз (проверка дедупликации)
            // sendDayDataToWatch вызывает sendCurrentStatus, что отправляет applicationContext еще раз
            statusManager.sendDayDataToWatch(currentDay: 43)

            // 4. Проверяем, что applicationContext обновлен (всегда обновляется)
            let applicationContextAfterDuplicate = try #require(mockSession.applicationContexts.last)
            let currentDayAfterDuplicate = try #require(applicationContextAfterDuplicate["currentDay"] as? Int)
            #expect(currentDayAfterDuplicate == 43)
            // applicationContext отправляется: 1) от setCurrentDayForDebug для дня 42, 2) от sendDayDataToWatch для дня 42,
            // 3) от setCurrentDayForDebug для дня 43, 4) от sendDayDataToWatch для дня 43, 5) от sendDayDataToWatch для дня 43 (дубликат)
            // Итого: initialApplicationContextCount + 5
            #expect(mockSession.applicationContexts.count >= initialApplicationContextCount + 5)

            // 5. Проверяем, что sendMessage НЕ отправлен повторно (дедупликация работает)
            #expect(mockSession.sentMessages.count == initialSentMessagesCount + 2)
        }
    }
}
