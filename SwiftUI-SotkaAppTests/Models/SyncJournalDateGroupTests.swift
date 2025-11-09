import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для SyncJournalDateGroup")
struct SyncJournalDateGroupTests {
    @Test("Создает DateGroup с датой и записями")
    func createsDateGroupWithDateAndEntries() {
        let date = Date()
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)

        let entry1 = SyncJournalEntry(
            startDate: date,
            result: .success
        )
        let entry2 = SyncJournalEntry(
            startDate: date.addingTimeInterval(3600),
            result: .success
        )

        let group = DateGroup(date: dateOnly, entries: [entry1, entry2])

        #expect(group.date == dateOnly)
        #expect(group.entries.count == 2)
        #expect(group.entries.contains { $0.id == entry1.id })
        #expect(group.entries.contains { $0.id == entry2.id })
    }

    @Test("Локализованный заголовок использует правильный формат")
    func localizedTitleUsesCorrectFormat() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)

        let entry = SyncJournalEntry(
            startDate: date,
            result: .success
        )

        let group = DateGroup(date: dateOnly, entries: [entry])
        let title = group.localizedTitle

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let expectedTitle = formatter.string(from: dateOnly)

        #expect(title == expectedTitle)
    }

    @Test("Группирует записи по дате")
    func groupsEntriesByDate() throws {
        let calendar = Calendar.current
        let date1 = calendar.startOfDay(for: Date())
        let date2 = calendar.startOfDay(for: Date().addingTimeInterval(86400))

        let entry1 = SyncJournalEntry(
            startDate: date1.addingTimeInterval(3600),
            result: .success
        )
        let entry2 = SyncJournalEntry(
            startDate: date1.addingTimeInterval(7200),
            result: .success
        )
        let entry3 = SyncJournalEntry(
            startDate: date2.addingTimeInterval(3600),
            result: .success
        )

        let groups = DateGroup.groupEntriesByDate([entry1, entry2, entry3])

        #expect(groups.count == 2)

        let group1 = groups.first { calendar.isDate($0.date, inSameDayAs: date1) }
        let group2 = groups.first { calendar.isDate($0.date, inSameDayAs: date2) }

        let group1Entries = try #require(group1)
        let group2Entries = try #require(group2)

        #expect(group1Entries.entries.count == 2)
        #expect(group2Entries.entries.count == 1)
        #expect(group1Entries.entries.contains { $0.id == entry1.id })
        #expect(group1Entries.entries.contains { $0.id == entry2.id })
        #expect(group2Entries.entries.contains { $0.id == entry3.id })
    }

    @Test("Сортирует группы по дате - новые даты сверху")
    func sortsGroupsByDateNewestFirst() {
        let calendar = Calendar.current
        let date1 = calendar.startOfDay(for: Date())
        let date2 = calendar.startOfDay(for: Date().addingTimeInterval(-86400))
        let date3 = calendar.startOfDay(for: Date().addingTimeInterval(-172800))

        let entry1 = SyncJournalEntry(
            startDate: date1.addingTimeInterval(3600),
            result: .success
        )
        let entry2 = SyncJournalEntry(
            startDate: date2.addingTimeInterval(3600),
            result: .success
        )
        let entry3 = SyncJournalEntry(
            startDate: date3.addingTimeInterval(3600),
            result: .success
        )

        let groups = DateGroup.groupEntriesByDate([entry1, entry2, entry3])

        #expect(groups.count == 3)
        #expect(calendar.isDate(groups[0].date, inSameDayAs: date1))
        #expect(calendar.isDate(groups[1].date, inSameDayAs: date2))
        #expect(calendar.isDate(groups[2].date, inSameDayAs: date3))
    }

    @Test("Сортирует записи внутри группы - новые записи сверху")
    func sortsEntriesInGroupNewestFirst() throws {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: Date())

        let entry1 = SyncJournalEntry(
            startDate: date.addingTimeInterval(3600),
            result: .success
        )
        let entry2 = SyncJournalEntry(
            startDate: date.addingTimeInterval(7200),
            result: .success
        )
        let entry3 = SyncJournalEntry(
            startDate: date.addingTimeInterval(1800),
            result: .success
        )

        let groups = DateGroup.groupEntriesByDate([entry1, entry2, entry3])

        let group = try #require(groups.first)
        #expect(group.entries.count == 3)
        #expect(group.entries[0].id == entry2.id)
        #expect(group.entries[1].id == entry1.id)
        #expect(group.entries[2].id == entry3.id)
    }

    @Test("Обрабатывает записи без endDate - группирует по дате startDate")
    func handlesEntriesWithoutEndDate() throws {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: Date())

        let entry1 = SyncJournalEntry(
            startDate: date.addingTimeInterval(3600),
            endDate: nil,
            result: .success
        )
        let entry2 = SyncJournalEntry(
            startDate: date.addingTimeInterval(7200),
            endDate: date.addingTimeInterval(7300),
            result: .success
        )

        let groups = DateGroup.groupEntriesByDate([entry1, entry2])

        #expect(groups.count == 1)
        let group = try #require(groups.first)
        #expect(group.entries.count == 2)
        #expect(group.entries.contains { $0.id == entry1.id })
        #expect(group.entries.contains { $0.id == entry2.id })
    }

    @Test("Обрабатывает пустой список записей")
    func handlesEmptyEntriesList() {
        let groups = DateGroup.groupEntriesByDate([])

        #expect(groups.isEmpty)
    }

    @Test("Обрабатывает записи с разными датами - создает разные группы")
    func handlesEntriesWithDifferentDates() throws {
        let calendar = Calendar.current
        let date1 = calendar.startOfDay(for: Date())
        let date2 = calendar.startOfDay(for: Date().addingTimeInterval(86400))
        let date3 = calendar.startOfDay(for: Date().addingTimeInterval(172800))

        let entry1 = SyncJournalEntry(
            startDate: date1.addingTimeInterval(3600),
            result: .success
        )
        let entry2 = SyncJournalEntry(
            startDate: date2.addingTimeInterval(3600),
            result: .success
        )
        let entry3 = SyncJournalEntry(
            startDate: date3.addingTimeInterval(3600),
            result: .success
        )

        let groups = DateGroup.groupEntriesByDate([entry1, entry2, entry3])

        #expect(groups.count == 3)

        let group1 = groups.first { calendar.isDate($0.date, inSameDayAs: date1) }
        let group2 = groups.first { calendar.isDate($0.date, inSameDayAs: date2) }
        let group3 = groups.first { calendar.isDate($0.date, inSameDayAs: date3) }

        #expect(group1 != nil)
        #expect(group2 != nil)
        #expect(group3 != nil)

        let g1 = try #require(group1)
        let g2 = try #require(group2)
        let g3 = try #require(group3)

        #expect(g1.entries.count == 1)
        #expect(g2.entries.count == 1)
        #expect(g3.entries.count == 1)
        #expect(g1.entries.first?.id == entry1.id)
        #expect(g2.entries.first?.id == entry2.id)
        #expect(g3.entries.first?.id == entry3.id)
    }
}
