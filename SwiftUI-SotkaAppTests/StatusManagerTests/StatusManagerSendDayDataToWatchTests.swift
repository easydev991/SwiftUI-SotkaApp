import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для sendDayDataToWatch")
    @MainActor
    struct SendDayDataToWatchTests {
        @Test("Отправляет команду изменения дня при наличии дня")
        func sendsDayCommandWhenDayExists() throws {
            let mockSession = MockWCSession(isReachable: true)
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create()
            )
            let manager = StatusManager.WatchConnectivityManager(
                statusManager: statusManager,
                sessionProtocol: mockSession
            )
            statusManager.watchConnectivityManager = manager

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

            statusManager.sendDayDataToWatch(currentDay: 42, context: context)

            #expect(mockSession.sentMessages.count == 1)
            let sentMessage = try #require(mockSession.sentMessages.first)
            let command = try #require(sentMessage["command"] as? String)
            #expect(command == Constants.WatchCommand.currentDay.rawValue)
            let currentDay = try #require(sentMessage["currentDay"] as? Int)
            #expect(currentDay == 42)
        }

        @Test("Не отправляет команды при отсутствии дня")
        func doesNotSendCommandsWhenDayIsNil() throws {
            let mockSession = MockWCSession(isReachable: true)
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create()
            )
            let manager = StatusManager.WatchConnectivityManager(
                statusManager: statusManager,
                sessionProtocol: mockSession
            )
            statusManager.watchConnectivityManager = manager

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            statusManager.sendDayDataToWatch(currentDay: nil, context: context)

            #expect(mockSession.sentMessages.isEmpty)
        }

        @Test("Не отправляет команды когда часы недоступны")
        func doesNotSendCommandsWhenWatchUnavailable() throws {
            let mockSession = MockWCSession(isReachable: false)
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create()
            )
            let manager = StatusManager.WatchConnectivityManager(
                statusManager: statusManager,
                sessionProtocol: mockSession
            )
            statusManager.watchConnectivityManager = manager

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            statusManager.sendDayDataToWatch(currentDay: 42, context: context)

            #expect(mockSession.sentMessages.isEmpty)
        }
    }
}
