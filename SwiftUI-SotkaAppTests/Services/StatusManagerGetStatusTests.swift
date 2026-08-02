import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

/// Тесты для `StatusManager.getStatus()` — автостарт программы для пользователей без startDate.
/// Без автостарта DayCalculator возвращает nil и HomeScreen бесконечно показывает загрузку.
@Suite("Тесты для getStatus")
@MainActor
struct StatusManagerGetStatusTests {
    @Test("Автостарт: при отсутствии startDate ставит её на сегодня и строит календарь с дня 1")
    func getStatusAutoStartsProgramForUserWithoutStartDate() async throws {
        let userDefaults = try MockUserDefaults.create()
        let statusManager = try MockStatusManager.create(userDefaults: userDefaults)

        #expect(statusManager.currentDayCalculator == nil)
        #expect(userDefaults.double(forKey: Constants.startDateKey) == 0)

        await statusManager.getStatus()

        #expect(statusManager.currentDayCalculator != nil)
        #expect(statusManager.currentDayCalculator?.currentDay == 1)
        #expect(userDefaults.double(forKey: Constants.startDateKey) != 0)
    }

    @Test("Не перезаписывает существующую startDate")
    func getStatusKeepsExistingStartDate() async throws {
        let now = Date.now
        let startDate = try #require(Calendar.current.date(byAdding: .day, value: -10, to: now))
        let statusManager = try MockStatusManager.create()

        await statusManager.startNewRun(appDate: startDate)
        await statusManager.getStatus()

        #expect(statusManager.currentDayCalculator?.currentDay == 11)
    }
}
