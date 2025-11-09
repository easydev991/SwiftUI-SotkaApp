import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для SyncJournalRowView")
@MainActor
struct SyncJournalRowViewTests {
    @Test("Форматирует время с миллисекундами в правильном формате")
    func formatsTimeWithMillisecondsInCorrectFormat() throws {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        components.hour = 14
        components.minute = 30
        components.second = 45
        components.nanosecond = 123_000_000

        let date = try #require(calendar.date(from: components))
        let formatted = SyncJournalRowView.formatTimeWithMilliseconds(date)

        #expect(formatted == "14:30:45.123")
    }

    @Test("Обрабатывает время утром")
    func handlesMorningTime() throws {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        components.hour = 8
        components.minute = 15
        components.second = 30
        components.nanosecond = 0

        let date = try #require(calendar.date(from: components))
        let formatted = SyncJournalRowView.formatTimeWithMilliseconds(date)

        #expect(formatted == "08:15:30.000")
    }

    @Test("Обрабатывает время днем")
    func handlesDayTime() throws {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        components.hour = 15
        components.minute = 45
        components.second = 20
        components.nanosecond = 0

        let date = try #require(calendar.date(from: components))
        let formatted = SyncJournalRowView.formatTimeWithMilliseconds(date)

        #expect(formatted == "15:45:20.000")
    }

    @Test("Обрабатывает время вечером")
    func handlesEveningTime() throws {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        components.hour = 22
        components.minute = 10
        components.second = 5
        components.nanosecond = 0

        let date = try #require(calendar.date(from: components))
        let formatted = SyncJournalRowView.formatTimeWithMilliseconds(date)

        #expect(formatted == "22:10:05.000")
    }

    @Test("Обрабатывает миллисекунды 0")
    func handlesZeroMilliseconds() throws {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.nanosecond = 0

        let date = try #require(calendar.date(from: components))
        let formatted = SyncJournalRowView.formatTimeWithMilliseconds(date)

        #expect(formatted == "12:00:00.000")
    }

    @Test("Обрабатывает миллисекунды 123")
    func handlesMilliseconds123() throws {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.nanosecond = 123_000_000

        let date = try #require(calendar.date(from: components))
        let formatted = SyncJournalRowView.formatTimeWithMilliseconds(date)

        #expect(formatted == "12:00:00.123")
    }

    @Test("Обрабатывает миллисекунды 999")
    func handlesMilliseconds999() throws {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.nanosecond = 999_000_000

        let date = try #require(calendar.date(from: components))
        let formatted = SyncJournalRowView.formatTimeWithMilliseconds(date)

        #expect(formatted == "12:00:00.999")
    }
}
