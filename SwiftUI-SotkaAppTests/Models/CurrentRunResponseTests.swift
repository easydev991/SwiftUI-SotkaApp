import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты декодирования CurrentRunResponse")
struct CurrentRunResponseTests {
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - Декодирование с валидной датой

    @Test("Должен декодировать CurrentRunResponse с валидной датой")
    func decodeCurrentRunResponseWithValidDate() throws {
        let json = """
        {
            "date": "2024-01-15T10:30:00Z",
            "max_for_all_runs_day": 100
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CurrentRunResponse.self, from: json)

        let date = try #require(response.date)
        let expectedDate = ISO8601DateFormatter().date(from: "2024-01-15T10:30:00Z")
        let expectedDateValue = try #require(expectedDate)
        #expect(date == expectedDateValue)
        let maxForAllRunsDay = try #require(response.maxForAllRunsDay)
        #expect(maxForAllRunsDay == 100)
    }

    @Test("Должен декодировать CurrentRunResponse с датой с дробными секундами")
    func decodeCurrentRunResponseWithDateWithFractionalSeconds() throws {
        let json = """
        {
            "date": "2024-01-15T10:30:00.123Z",
            "max_for_all_runs_day": 50
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CurrentRunResponse.self, from: json)

        let date = try #require(response.date)
        let calendar = Calendar.current
        #expect(calendar.component(.year, from: date) == 2024)
        #expect(calendar.component(.month, from: date) == 1)
        #expect(calendar.component(.day, from: date) == 15)
        let maxForAllRunsDay = try #require(response.maxForAllRunsDay)
        #expect(maxForAllRunsDay == 50)
    }

    // MARK: - Декодирование с null датой

    @Test("Должен декодировать CurrentRunResponse с null датой")
    func decodeCurrentRunResponseWithNullDate() throws {
        let json = """
        {
            "date": null,
            "max_for_all_runs_day": 100
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CurrentRunResponse.self, from: json)

        #expect(response.date == nil)
        let maxForAllRunsDay = try #require(response.maxForAllRunsDay)
        #expect(maxForAllRunsDay == 100)
    }

    @Test("Должен декодировать CurrentRunResponse с null датой и feed_new_comments")
    func decodeCurrentRunResponseWithNullDateAndFeedNewComments() throws {
        let json = """
        {
            "date": null,
            "max_for_all_runs_day": 100,
            "feed_new_comments": 5
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CurrentRunResponse.self, from: json)

        #expect(response.date == nil)
        let maxForAllRunsDay = try #require(response.maxForAllRunsDay)
        #expect(maxForAllRunsDay == 100)
    }

    // MARK: - Декодирование с отсутствующей датой

    @Test("Должен декодировать CurrentRunResponse с отсутствующей датой")
    func decodeCurrentRunResponseWithMissingDate() throws {
        let json = """
        {
            "max_for_all_runs_day": 100
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CurrentRunResponse.self, from: json)

        #expect(response.date == nil)
        let maxForAllRunsDay = try #require(response.maxForAllRunsDay)
        #expect(maxForAllRunsDay == 100)
    }

    @Test("Должен декодировать CurrentRunResponse с отсутствующей датой и feed_new_comments")
    func decodeCurrentRunResponseWithMissingDateAndFeedNewComments() throws {
        let json = """
        {
            "max_for_all_runs_day": 100,
            "feed_new_comments": 3
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CurrentRunResponse.self, from: json)

        #expect(response.date == nil)
        let maxForAllRunsDay = try #require(response.maxForAllRunsDay)
        #expect(maxForAllRunsDay == 100)
    }

    // MARK: - Декодирование с опциональными полями

    @Test("Должен декодировать CurrentRunResponse с null maxForAllRunsDay")
    func decodeCurrentRunResponseWithNullMaxForAllRunsDay() throws {
        let json = """
        {
            "date": "2024-01-15T10:30:00Z",
            "max_for_all_runs_day": null
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CurrentRunResponse.self, from: json)

        let date = try #require(response.date)
        let expectedDate = ISO8601DateFormatter().date(from: "2024-01-15T10:30:00Z")
        let expectedDateValue = try #require(expectedDate)
        #expect(date == expectedDateValue)
        #expect(response.maxForAllRunsDay == nil)
    }

    @Test("Должен декодировать CurrentRunResponse с отсутствующим maxForAllRunsDay")
    func decodeCurrentRunResponseWithMissingMaxForAllRunsDay() throws {
        let json = """
        {
            "date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CurrentRunResponse.self, from: json)

        let date = try #require(response.date)
        let expectedDate = ISO8601DateFormatter().date(from: "2024-01-15T10:30:00Z")
        let expectedDateValue = try #require(expectedDate)
        #expect(date == expectedDateValue)
        #expect(response.maxForAllRunsDay == nil)
    }

    @Test("Должен декодировать CurrentRunResponse когда оба поля null")
    func decodeCurrentRunResponseWithBothFieldsNull() throws {
        let json = """
        {
            "date": null,
            "max_for_all_runs_day": null,
            "feed_new_comments": 2
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CurrentRunResponse.self, from: json)

        #expect(response.date == nil)
        #expect(response.maxForAllRunsDay == nil)
    }

    // MARK: - Реальный случай из логов

    @Test("Должен декодировать реальный ответ сервера с null датой")
    func decodeRealServerResponseWithNullDate() throws {
        let json = """
        {
            "date": null,
            "feed_new_comments": 0,
            "max_for_all_runs_day": false
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CurrentRunResponse.self, from: json)

        #expect(response.date == nil)
        #expect(response.maxForAllRunsDay == nil)
    }
}
