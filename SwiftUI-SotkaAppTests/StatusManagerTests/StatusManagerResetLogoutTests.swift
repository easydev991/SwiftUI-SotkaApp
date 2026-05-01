import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

extension StatusManagerTests {
    @Suite("Этап 8: Reset / Logout продлений")
    @MainActor
    struct ResetLogoutTests {
        @Test("didLogout очищает synced и unsynced продления")
        func didLogoutClearsSyncedAndUnsyncedExtensions() throws {
            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(modelContainer: container)
            let syncedDate = Date(timeIntervalSince1970: 1_700_030_001)
            let unsyncedDate = Date(timeIntervalSince1970: 1_700_030_101)
            statusManager.addExtensionDate(syncedDate, isSynced: true)
            statusManager.addExtensionDate(unsyncedDate, isSynced: false)

            let recordsBeforeLogout = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            let unsyncedBeforeLogout = recordsBeforeLogout.filter { !$0.isSynced }
            #expect(recordsBeforeLogout.count == 2)
            #expect(unsyncedBeforeLogout.count == 1)

            statusManager.didLogout()

            let recordsAfterLogout = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(recordsAfterLogout.isEmpty)
            #expect(statusManager.currentDayCalculator == nil)
        }

        @Test("didLogout удаляет сохранённую страницу Journal из UserDefaults")
        func didLogoutClearsPersistedJournalPage() throws {
            let defaults = try MockUserDefaults.create()
            defaults.set(3, forKey: JournalPagePersistence.storageKey)
            let statusManager = try MockStatusManager.create(userDefaults: defaults)

            statusManager.didLogout()

            let storedValue = defaults.object(forKey: JournalPagePersistence.storageKey)
            #expect(storedValue == nil)
        }

        @Test("resetProgram очищает очередь продлений и возвращает totalDays к 100")
        func resetProgramClearsExtensionsAndRebuildsCalculator() async throws {
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
            )
            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                modelContainer: container
            )
            statusManager.setCurrentDayForDebug(100)
            statusManager.addExtensionDate(Date(timeIntervalSince1970: 1_700_040_001), isSynced: true)
            statusManager.addExtensionDate(Date(timeIntervalSince1970: 1_700_040_101), isSynced: false)

            let calculatorBeforeReset = try #require(statusManager.currentDayCalculator)
            #expect(calculatorBeforeReset.totalDays == 300)

            await statusManager.resetProgram()

            let recordsAfterReset = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            let calculatorAfterReset = try #require(statusManager.currentDayCalculator)
            #expect(recordsAfterReset.isEmpty)
            #expect(calculatorAfterReset.totalDays == DayCalculator.baseProgramDays)
            #expect(calculatorAfterReset.currentDay == 1)
        }

        @Test("resetProgram удаляет сохранённую страницу Journal из UserDefaults")
        func resetProgramClearsPersistedJournalPage() async throws {
            let defaults = try MockUserDefaults.create()
            defaults.set(2, forKey: JournalPagePersistence.storageKey)

            let statusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: Date.now, maxForAllRunsDay: nil))
            )
            let container = try makeContainer()
            let context = container.mainContext
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: statusClient,
                userDefaults: defaults,
                modelContainer: container
            )

            await statusManager.resetProgram()

            let storedValue = defaults.object(forKey: JournalPagePersistence.storageKey)
            #expect(storedValue == nil)
        }

        @Test("после logout и нового online login подтягиваются серверные покупки")
        func serverPurchasesAreReloadedAfterLogoutAndNewLogin() async throws {
            let mockStatusClient = MockStatusClient()
            let mockPurchasesClient = MockPurchasesClient()
            let serverDate1 = Date(timeIntervalSince1970: 1_700_050_001)
            let serverDate2 = Date(timeIntervalSince1970: 1_700_050_101)
            let serverCalendarDates = [
                DateFormatterService.stringFromFullDate(serverDate1, format: .isoDateTimeSec),
                DateFormatterService.stringFromFullDate(serverDate2, format: .isoDateTimeSec)
            ]
            mockPurchasesClient.getPurchasesResult = .success(
                CalendarPurchasesResponse(calendars: serverCalendarDates)
            )

            let container = try makeContainer()
            let context = container.mainContext
            let firstUser = User(id: 1, userName: "first-user", fullName: "First User", email: "first@example.com")
            context.insert(firstUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                purchasesClient: mockPurchasesClient,
                modelContainer: container
            )
            statusManager.setCurrentDayForDebug(50)
            statusManager.addExtensionDate(Date(timeIntervalSince1970: 1_700_050_501), isSynced: false)
            let startDate = try #require(statusManager.currentDayCalculator?.startDate)
            mockStatusClient.currentResult = .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))

            statusManager.didLogout()

            let recordsAfterLogout = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            #expect(recordsAfterLogout.isEmpty)

            context.delete(firstUser)
            let secondUser = User(id: 2, userName: "second-user", fullName: "Second User", email: "second@example.com")
            context.insert(secondUser)
            try context.save()

            await statusManager.getStatus()

            let recordsAfterLogin = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
            let calculatorAfterLogin = try #require(statusManager.currentDayCalculator)
            let syncedAfterLogin = recordsAfterLogin.filter(\.isSynced)
            #expect(recordsAfterLogin.count == 2)
            #expect(syncedAfterLogin.count == 2)
            #expect(calculatorAfterLogin.totalDays == 300)
            #expect(mockPurchasesClient.getPurchasesCallCount > 0)
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
    }
}
