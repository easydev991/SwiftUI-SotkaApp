import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("JournalPagePersistence")
struct JournalPagePersistenceTests {
    @Test("Восстанавливает сохранённую страницу в пределах валидного диапазона")
    func restoresSavedPageWithinRange() throws {
        let defaults = try MockUserDefaults.create()
        JournalPagePersistence.saveSelectedPage(2, defaults: defaults, totalDays: 350)

        let restoredPage = JournalPagePersistence.restoreSelectedPage(
            defaults: defaults,
            totalDays: 350
        )

        #expect(restoredPage == 2)
    }

    @Test("Clamp в 0, если сохранённая страница выходит за pageCount")
    func restoresAndClampsOutOfRangePageToZero() throws {
        let defaults = try MockUserDefaults.create()
        defaults.set(99, forKey: JournalPagePersistence.storageKey)

        let restoredPage = JournalPagePersistence.restoreSelectedPage(
            defaults: defaults,
            totalDays: 100
        )

        #expect(restoredPage == 0)
    }

    @Test("Сохранение страницы применяет clamp по текущему totalDays")
    func saveAppliesClamp() throws {
        let defaults = try MockUserDefaults.create()
        JournalPagePersistence.saveSelectedPage(9, defaults: defaults, totalDays: 250)

        let storedPage = defaults.integer(forKey: JournalPagePersistence.storageKey)
        let restoredPage = JournalPagePersistence.restoreSelectedPage(
            defaults: defaults,
            totalDays: 250
        )

        #expect(storedPage == 2)
        #expect(restoredPage == 2)
    }

    @Test("clear удаляет сохранённую страницу")
    func clearRemovesStoredValue() throws {
        let defaults = try MockUserDefaults.create()
        defaults.set(3, forKey: JournalPagePersistence.storageKey)

        JournalPagePersistence.clear(defaults: defaults)

        let valueAfterClear = defaults.object(forKey: JournalPagePersistence.storageKey)
        let restoredAfterClear = JournalPagePersistence.restoreSelectedPage(
            defaults: defaults,
            totalDays: 300
        )
        #expect(valueAfterClear == nil)
        #expect(restoredAfterClear == 0)
    }
}
