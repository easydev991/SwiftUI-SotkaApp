import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

extension StatusManagerTests {
    @Suite("Тесты продления календаря")
    @MainActor
    struct CalendarExtensionTests {
        @Test("extendCalendar добавляет локальное продление и увеличивает totalDays")
        func extendCalendarAddsLocalRecordAndIncreasesTotalDays() async throws {
            let mockStatusClient = MockStatusClient()
            let mockPurchasesClient = MockPurchasesClient()
            mockPurchasesClient.postResultsQueue = [.failure(MockPurchasesClient.MockError.demoError)]
            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                purchasesClient: mockPurchasesClient,
                modelContainer: container
            )
            statusManager.setCurrentDayForDebug(100)

            statusManager.extendCalendar()
            await waitForAsyncSync()

            let records = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(records.count == 1)
            let firstRecord = try #require(records.first)
            #expect(!firstRecord.isSynced)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.totalDays == 200)
            #expect(calculator.currentDay == 100)
            #expect(calculator.daysLeft == 100)
        }

        @Test("extendCalendar не срабатывает, если кнопка продления неактивна")
        func extendCalendarSkipsWhenButtonNotAvailable() async throws {
            let mockPurchasesClient = MockPurchasesClient()
            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(
                purchasesClient: mockPurchasesClient,
                modelContainer: container
            )
            statusManager.setCurrentDayForDebug(99)

            statusManager.extendCalendar()
            await waitForAsyncSync()

            let records = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(records.isEmpty)
            #expect(mockPurchasesClient.postCalendarPurchaseCallCount == 0)
        }

        @Test("extendCalendar не меняет настройки ежедневных уведомлений")
        func extendCalendarDoesNotAffectDailyNotificationSettings() async throws {
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)
            let notificationTime = Date(timeIntervalSinceReferenceDate: 123_321)
            appSettings.workoutNotificationsEnabled = false
            appSettings.workoutNotificationTime = notificationTime

            let enabledBefore = appSettings.workoutNotificationsEnabled
            let timeBefore = appSettings.workoutNotificationTime.timeIntervalSinceReferenceDate

            let mockPurchasesClient = MockPurchasesClient()
            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(
                purchasesClient: mockPurchasesClient,
                userDefaults: userDefaults,
                modelContainer: container
            )
            statusManager.setCurrentDayForDebug(100)

            statusManager.extendCalendar()
            await waitForAsyncSync()

            let enabledAfter = appSettings.workoutNotificationsEnabled
            let timeAfter = appSettings.workoutNotificationTime.timeIntervalSinceReferenceDate

            #expect(enabledBefore == enabledAfter)
            #expect(timeBefore == timeAfter)
        }

        @Test("extendCalendar отправляет на часы только currentDay без totalDays")
        func extendCalendarSendsWatchPayloadWithoutTotalDays() async throws {
            let mockSession = MockWCSession(isReachable: true)
            let mockPurchasesClient = MockPurchasesClient()
            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(
                purchasesClient: mockPurchasesClient,
                modelContainer: container,
                watchConnectivitySessionProtocol: mockSession
            )
            statusManager.setCurrentDayForDebug(100)

            let contextsBeforeExtend = mockSession.applicationContexts.count
            statusManager.extendCalendar()
            await waitForAsyncSync()

            #expect(mockSession.applicationContexts.count == contextsBeforeExtend + 1)
            let latestContext = try #require(mockSession.applicationContexts.last)
            let currentDayInContext = try #require(latestContext["currentDay"] as? Int)
            #expect(currentDayInContext == 100)
            #expect(latestContext["totalDays"] == nil)

            let authStatusMessages = mockSession.sentMessages.filter { message in
                (message["command"] as? String) == Constants.WatchCommand.authStatus.rawValue
            }
            let latestAuthStatusMessage = try #require(authStatusMessages.last)
            let currentDayInMessage = try #require(latestAuthStatusMessage["currentDay"] as? Int)
            #expect(currentDayInMessage == 100)
            #expect(latestAuthStatusMessage["totalDays"] == nil)
        }

        @Test("offline-only: продление работает локально и не вызывает сеть покупок")
        func extendCalendarWorksOfflineWithoutPurchaseNetwork() async throws {
            let mockPurchasesClient = MockPurchasesClient()
            let container = try makeContainer()
            let context = container.mainContext
            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                purchasesClient: mockPurchasesClient,
                modelContainer: container
            )
            await statusManager.getStatus()
            statusManager.setCurrentDayForDebug(100)

            statusManager.extendCalendar()
            await waitForAsyncSync()

            let records = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(records.count == 1)
            let firstRecord = try #require(records.first)
            #expect(firstRecord.isSynced)
            #expect(mockPurchasesClient.getPurchasesCallCount == 0)
            #expect(mockPurchasesClient.postCalendarPurchaseCallCount == 0)
        }

        @Test("ошибка POST покупок оставляет запись unsynced, getStatus делает retry")
        func retryUnsyncedOnGetStatus() async throws {
            let mockStatusClient = MockStatusClient()
            let mockPurchasesClient = MockPurchasesClient()
            mockPurchasesClient.getPurchasesResult = .success(
                CalendarPurchasesResponse(customEditor: false, calendars: [])
            )
            mockPurchasesClient.postResultsQueue = [
                .failure(MockPurchasesClient.MockError.demoError),
                .success(CalendarPurchasesResponse(customEditor: false, calendars: []))
            ]
            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                purchasesClient: mockPurchasesClient,
                modelContainer: container
            )
            statusManager.setCurrentDayForDebug(100)
            let startDate = try #require(statusManager.currentDayCalculator?.startDate)
            mockStatusClient.currentResult = .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))

            statusManager.extendCalendar()
            await waitForAsyncSync()

            var records = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(records.count == 1)
            var firstRecord = try #require(records.first)
            #expect(!firstRecord.isSynced)

            await statusManager.getStatus()

            records = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(records.count == 1)
            firstRecord = try #require(records.first)
            #expect(firstRecord.isSynced)
            #expect(mockPurchasesClient.postCalendarPurchaseCallCount >= 2)
        }

        @Test("getStatus подтягивает старые покупки и увеличивает totalDays")
        func getStatusMergesServerPurchasesIntoCalculator() async throws {
            let mockStatusClient = MockStatusClient()
            let mockPurchasesClient = MockPurchasesClient()

            let date1 = Date(timeIntervalSince1970: 1_700_000_001)
            let date2 = Date(timeIntervalSince1970: 1_700_000_101)
            mockPurchasesClient.getPurchasesResult = .success(
                CalendarPurchasesResponse(
                    customEditor: false,
                    calendars: [
                        DateFormatterService.stringFromFullDate(date1, format: .isoDateTimeSec),
                        DateFormatterService.stringFromFullDate(date2, format: .isoDateTimeSec)
                    ]
                )
            )

            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                purchasesClient: mockPurchasesClient,
                modelContainer: container
            )
            statusManager.setCurrentDayForDebug(50)
            let startDate = try #require(statusManager.currentDayCalculator?.startDate)
            mockStatusClient.currentResult = .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))

            await statusManager.getStatus()

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.totalDays == 300)

            let records = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(records.count == 2)
            #expect(records.filter { !$0.isSynced }.isEmpty)
        }

        @Test("merge локальных и серверных дат убирает дубль и помечает synced")
        func mergeDeduplicatesByDateKeyAndMarksSynced() async throws {
            let mockStatusClient = MockStatusClient()
            let mockPurchasesClient = MockPurchasesClient()

            let sharedDate = Date(timeIntervalSince1970: 1_700_010_001)
            mockPurchasesClient.getPurchasesResult = .success(
                CalendarPurchasesResponse(
                    customEditor: false,
                    calendars: [DateFormatterService.stringFromFullDate(sharedDate, format: .isoDateTimeSec)]
                )
            )

            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                purchasesClient: mockPurchasesClient,
                modelContainer: container
            )
            statusManager.setCurrentDayForDebug(100)
            statusManager.addExtensionDate(sharedDate, isSynced: false)

            let startDate = try #require(statusManager.currentDayCalculator?.startDate)
            mockStatusClient.currentResult = .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))

            await statusManager.getStatus()

            let records = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(records.count == 1)
            let firstRecord = try #require(records.first)
            #expect(firstRecord.isSynced)
        }

        @Test("syncJournal сначала fetch покупок, затем retry unsynced")
        func syncJournalFetchesBeforeRetryingUnsynced() async throws {
            let mockStatusClient = MockStatusClient()
            let mockPurchasesClient = MockPurchasesClient()
            let extensionDate = Date(timeIntervalSince1970: 1_700_020_001)
            mockPurchasesClient.getPurchasesResult = .success(
                CalendarPurchasesResponse(
                    customEditor: false,
                    calendars: [DateFormatterService.stringFromFullDate(extensionDate, format: .isoDateTimeSec)]
                )
            )

            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                purchasesClient: mockPurchasesClient,
                modelContainer: container
            )
            statusManager.addExtensionDate(extensionDate, isSynced: false)

            await statusManager.start(appDate: .now)

            #expect(mockPurchasesClient.callHistory.first == .getPurchases)
            #expect(mockPurchasesClient.postCalendarPurchaseCallCount == 0)

            let records = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(records.count == 1)
            let firstRecord = try #require(records.first)
            #expect(firstRecord.isSynced)
        }

        @Test("didLogout очищает продления календаря")
        func didLogoutClearsExtensions() throws {
            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(modelContainer: container)
            statusManager.addExtensionDate(.now)

            var records = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(records.count == 1)

            statusManager.didLogout()

            records = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(records.isEmpty)
        }

        @Test("resetProgram очищает продления календаря")
        func resetProgramClearsExtensions() async throws {
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
            )
            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)

            let activity = DayActivity(
                day: 1,
                activityTypeRaw: DayActivityType.rest.rawValue,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(activity)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                modelContainer: container
            )
            statusManager.addExtensionDate(.now)

            await statusManager.resetProgram()

            let records = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(records.isEmpty)
        }

        @Test("removeLastExtensionDate откатывает последнее продление")
        func removeLastExtensionDateRemovesNewestRecord() throws {
            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(modelContainer: container)
            let first = Date(timeIntervalSince1970: 1_700_000_001)
            let second = Date(timeIntervalSince1970: 1_700_000_101)
            statusManager.addExtensionDate(first)
            statusManager.addExtensionDate(second)

            statusManager.removeLastExtensionDate()

            let records = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(records.count == 1)
            #expect(abs(records[0].date.timeIntervalSince1970 - first.timeIntervalSince1970) < 1)
        }

        private func makeContainer() throws -> ModelContainer {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(
                for: User.self,
                Country.self,
                CustomExercise.self,
                UserProgress.self,
                DayActivity.self,
                DayActivityTraining.self,
                SyncJournalEntry.self,
                CalendarExtensionRecord.self,
                configurations: config
            )
        }

        private func waitForAsyncSync() async {
            for _ in 0 ..< 20 {
                await Task.yield()
            }
        }
    }
}
