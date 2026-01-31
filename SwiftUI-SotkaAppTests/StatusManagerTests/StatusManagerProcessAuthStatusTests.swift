import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для processAuthStatus")
    @MainActor
    struct ProcessAuthStatusTests {
        @Test("Отправляет команду авторизации при isAuthorized == true")
        func sendsAuthCommandWhenAuthorized() async throws {
            let mockSession = MockWCSession(isReachable: true)
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                watchConnectivitySessionProtocol: mockSession
            )

            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            await statusManager.startNewRun(appDate: startDate)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            statusManager.processAuthStatus(isAuthorized: true)

            #expect(mockSession.sentMessages.count == 1)
            let sentMessage = try #require(mockSession.sentMessages.first)
            let command = try #require(sentMessage["command"] as? String)
            #expect(command == Constants.WatchCommand.authStatus.rawValue)
            let isAuthorized = try #require(sentMessage["isAuthorized"] as? Bool)
            #expect(isAuthorized)
        }

        @Test("Включает currentDay в команду авторизации если currentDayCalculator доступен")
        func includesCurrentDayInAuthCommandWhenCalculatorAvailable() async throws {
            let mockSession = MockWCSession(isReachable: true)
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                watchConnectivitySessionProtocol: mockSession
            )
            await statusManager.startNewRun(appDate: startDate)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            statusManager.processAuthStatus(isAuthorized: true)

            let sentMessage = try #require(mockSession.sentMessages.first)
            let currentDay = try #require(sentMessage["currentDay"] as? Int)
            // DayCalculator считает: daysBetween + 1, где daysBetween = 30 (от startDate до now)
            // Поэтому currentDay = 30 + 1 = 31
            #expect(currentDay == 31)
        }

        @Test("Вызывает didLogout при isAuthorized == false")
        func callsDidLogoutWhenNotAuthorized() async throws {
            let mockSession = MockWCSession(isReachable: true)
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                watchConnectivitySessionProtocol: mockSession
            )
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            await statusManager.startNewRun(appDate: startDate)

            #expect(statusManager.currentDayCalculator != nil)

            statusManager.processAuthStatus(isAuthorized: false)

            #expect(statusManager.currentDayCalculator == nil)
            #expect(mockSession.sentMessages.count == 1)
            let sentMessage = try #require(mockSession.sentMessages.first)
            let command = try #require(sentMessage["command"] as? String)
            #expect(command == Constants.WatchCommand.authStatus.rawValue)
            let isAuthorized = try #require(sentMessage["isAuthorized"] as? Bool)
            #expect(!isAuthorized)
        }

        @Test("Не включает currentDay в команду авторизации если currentDayCalculator недоступен")
        func doesNotIncludeCurrentDayWhenCalculatorUnavailable() throws {
            let mockSession = MockWCSession(isReachable: true)
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                watchConnectivitySessionProtocol: mockSession
            )

            #expect(statusManager.currentDayCalculator == nil)

            statusManager.processAuthStatus(isAuthorized: true)

            let sentMessage = try #require(mockSession.sentMessages.first)
            #expect(sentMessage["currentDay"] == nil)
        }

        @Test("Удаляет данные пользователя из контекста при логауте")
        func deletesUserDataFromContextOnLogout() throws {
            let mockSession = MockWCSession(isReachable: true)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            let usersBefore = try context.fetch(FetchDescriptor<User>())
            #expect(usersBefore.count == 1)

            statusManager.processAuthStatus(isAuthorized: false)

            let usersAfter = try context.fetch(FetchDescriptor<User>())
            #expect(usersAfter.isEmpty)
        }
    }
}
