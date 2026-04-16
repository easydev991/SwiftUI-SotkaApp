import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты ReviewStorage — persistence attempts через UserDefaults")
@MainActor
struct ReviewStorageTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ReviewStorageTests.\(UUID().uuidString)")!
    }

    @Test("Возвращает пустой массив attemptedMilestones при отсутствии данных")
    func emptyMilestonesWhenNoData() {
        let storage = ReviewStorage(userDefaults: makeDefaults())
        #expect(storage.attemptedMilestones() == [])
    }

    @Test("Возвращает nil для lastReviewRequestAttemptDate при отсутствии данных")
    func nilDateWhenNoData() {
        let storage = ReviewStorage(userDefaults: makeDefaults())
        #expect(storage.lastReviewRequestAttemptDate() == nil)
    }

    @Test("markAttempted добавляет milestone")
    func markAttemptedAddsMilestone() {
        let storage = ReviewStorage(userDefaults: makeDefaults())
        storage.markAttempted(.first)
        #expect(storage.attemptedMilestones() == [.first])
    }

    @Test("markAttempted обновляет lastReviewRequestAttemptDate")
    func markAttemptedUpdatesDate() throws {
        let storage = ReviewStorage(userDefaults: makeDefaults())
        let before = Date()
        storage.markAttempted(.first)
        let after = Date()
        let date = try #require(storage.lastReviewRequestAttemptDate())
        #expect(date >= before && date <= after)
    }

    @Test("Несколько milestone сохраняются корректно")
    func multipleMilestonesPersist() {
        let storage = ReviewStorage(userDefaults: makeDefaults())
        storage.markAttempted(.first)
        storage.markAttempted(.tenth)
        #expect(storage.attemptedMilestones() == [.first, .tenth])
    }

    @Test("Данные переживают создание нового экземпляра (имитация перезапуска)")
    func dataSurvivesNewInstance() {
        let defaults = makeDefaults()
        let storage1 = ReviewStorage(userDefaults: defaults)
        storage1.markAttempted(.first)
        storage1.markAttempted(.tenth)

        let storage2 = ReviewStorage(userDefaults: defaults)
        #expect(storage2.attemptedMilestones() == [.first, .tenth])
        #expect(storage2.lastReviewRequestAttemptDate() != nil)
    }

    @Test("Повторный markAttempted того же milestone не дублирует запись")
    func markAttemptedDoesNotDuplicate() {
        let storage = ReviewStorage(userDefaults: makeDefaults())
        storage.markAttempted(.first)
        storage.markAttempted(.first)
        #expect(storage.attemptedMilestones() == [.first])
    }
}
