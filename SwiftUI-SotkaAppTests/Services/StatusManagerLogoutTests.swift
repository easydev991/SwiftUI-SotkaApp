import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

/// Тесты для `StatusManager.didLogout()` — покрытие восстановленного logout-флоу.
@Suite("Тесты для didLogout")
@MainActor
struct StatusManagerLogoutTests {
    @Test("Устанавливает currentDayCalculator = nil")
    func didLogoutSetsCurrentDayCalculatorToNil() async throws {
        let now = Date.now
        let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
        let statusManager = try MockStatusManager.create()

        await statusManager.startNewRun(appDate: startDate)

        #expect(statusManager.currentDayCalculator != nil)

        statusManager.didLogout()

        #expect(statusManager.currentDayCalculator == nil)
    }

    @Test("Удаляет ключ startDate из UserDefaults")
    func didLogoutRemovesStartDateFromUserDefaults() async throws {
        let now = Date.now
        let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
        let userDefaults = try MockUserDefaults.create()
        let statusManager = try MockStatusManager.create(userDefaults: userDefaults)

        await statusManager.startNewRun(appDate: startDate)

        #expect(userDefaults.double(forKey: Constants.startDateKey) != 0)

        statusManager.didLogout()

        #expect(userDefaults.double(forKey: Constants.startDateKey) == 0)
    }

    @Test("Устанавливает maxReadInfoPostDay = 0")
    func didLogoutSetsMaxReadInfoPostDayToZero() throws {
        let userDefaults = try MockUserDefaults.create()
        userDefaults.set(50, forKey: "WorkoutMaxReadInfoPostDay")
        let statusManager = try MockStatusManager.create(userDefaults: userDefaults)

        #expect(statusManager.maxReadInfoPostDay == 50)

        statusManager.didLogout()

        #expect(statusManager.maxReadInfoPostDay == 0)
    }

    @Test("Удаляет CalendarExtensionRecord записи")
    func didLogoutRemovesCalendarExtensionRecords() throws {
        let statusManager = try MockStatusManager.create()
        let context = statusManager.modelContainer.mainContext

        let user = User(id: 1, userName: "testuser")
        context.insert(user)
        statusManager.addExtensionDate(Date(timeIntervalSince1970: 1_700_030_001), isSynced: true)
        statusManager.addExtensionDate(Date(timeIntervalSince1970: 1_700_030_101), isSynced: false)
        try context.save()

        let recordsBefore = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
        #expect(recordsBefore.count == 2)

        statusManager.didLogout()

        let recordsAfter = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
        #expect(recordsAfter.isEmpty)
    }

    @Test("Удаляет сохранённую страницу Journal из UserDefaults")
    func didLogoutClearsPersistedJournalPage() throws {
        let defaults = try MockUserDefaults.create()
        defaults.set(3, forKey: JournalPagePersistence.storageKey)
        let statusManager = try MockStatusManager.create(userDefaults: defaults)

        statusManager.didLogout()

        let storedValue = defaults.object(forKey: JournalPagePersistence.storageKey)
        #expect(storedValue == nil)
    }
}
