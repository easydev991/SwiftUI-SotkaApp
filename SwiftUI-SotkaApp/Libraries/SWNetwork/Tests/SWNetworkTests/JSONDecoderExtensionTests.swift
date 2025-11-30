import Foundation
@testable import SWNetwork
import Testing

struct JSONDecoderExtensionTests {
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .flexibleDateDecoding
        return decoder
    }

    // MARK: - Декодирование стандартного ISO8601 формата

    @Test("Должен декодировать стандартный ISO8601 формат без дробных секунд")
    func decodeStandardISO8601Format() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let expectedDate = try #require(ISO8601DateFormatter().date(from: "2024-01-15T10:30:00Z"))
        #expect(result.date == expectedDate)
    }

    @Test("Должен декодировать ISO8601 формат с таймзоной +03:00")
    func decodeISO8601WithTimezone() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "2024-01-15T10:30:00+03:00"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let expectedDate = try #require(formatter.date(from: "2024-01-15T10:30:00+03:00"))
        #expect(result.date == expectedDate)
    }

    // MARK: - Декодирование формата с дробными секундами

    @Test("Должен декодировать ISO8601 формат с дробными секундами (одна цифра)")
    func decodeISO8601WithOneFractionalSecond() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "2024-01-15T10:30:00.1Z"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: "2024-01-15T10:30:00.1Z"))
        #expect(result.date == expectedDate)
    }

    @Test("Должен декодировать ISO8601 формат с дробными секундами (две цифры)")
    func decodeISO8601WithTwoFractionalSeconds() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "2024-01-15T10:30:00.12Z"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: "2024-01-15T10:30:00.12Z"))
        #expect(result.date == expectedDate)
    }

    @Test("Должен декодировать ISO8601 формат с дробными секундами (три цифры)")
    func decodeISO8601WithThreeFractionalSeconds() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "2024-01-15T10:30:00.123Z"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: "2024-01-15T10:30:00.123Z"))
        #expect(result.date == expectedDate)
    }

    @Test("Должен декодировать ISO8601 формат с дробными секундами (четыре цифры)")
    func decodeISO8601WithFourFractionalSeconds() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "2024-01-15T10:30:00.1234Z"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: "2024-01-15T10:30:00.1234Z"))
        #expect(result.date == expectedDate)
    }

    // MARK: - Обработка невалидных дат

    @Test("Должен выбрасывать ошибку для невалидной даты")
    func decodeInvalidDate() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "invalid-date"
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(TestModel.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку для пустой строки")
    func decodeEmptyString() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": ""
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(TestModel.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку для неправильного формата даты")
    func decodeWrongDateFormat() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "2024-13-45"
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(TestModel.self, from: json)
        }
    }

    // MARK: - Опциональные поля

    @Test("Должен декодировать опциональное поле Date? с валидной датой")
    func decodeOptionalDateWithValidDate() throws {
        struct TestModel: Decodable {
            let date: Date?
        }

        let json = try #require("""
        {
            "date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let date = try #require(result.date)
        let expectedDate = try #require(ISO8601DateFormatter().date(from: "2024-01-15T10:30:00Z"))
        #expect(date == expectedDate)
    }

    @Test("Должен декодировать опциональное поле Date? с null значением")
    func decodeOptionalDateWithNull() throws {
        struct TestModel: Decodable {
            let date: Date?
        }

        let json = try #require("""
        {
            "date": null
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        #expect(result.date == nil)
    }

    @Test("Должен декодировать опциональное поле Date? с отсутствующим ключом")
    func decodeOptionalDateWithMissingKey() throws {
        struct TestModel: Decodable {
            let date: Date?
        }

        let json = try #require("""
        {
            "other": "value"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        #expect(result.date == nil)
    }

    // MARK: - Декодирование server date time формата (без часового пояса)

    @Test("Должен декодировать server date time формат без часового пояса")
    func decodeServerDateTimeFormat() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "2024-01-15T10:30:00"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let expectedDate = try #require(formatter.date(from: "2024-01-15T10:30:00"))
        #expect(result.date == expectedDate)
    }

    @Test("Должен декодировать опциональное поле Date? с server date time форматом")
    func decodeOptionalDateWithServerDateTimeFormat() throws {
        struct TestModel: Decodable {
            let date: Date?
        }

        let json = try #require("""
        {
            "date": "2024-01-15T10:30:00"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let date = try #require(result.date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let expectedDate = try #require(formatter.date(from: "2024-01-15T10:30:00"))
        #expect(date == expectedDate)
    }

    // MARK: - Граничные случаи

    @Test("Должен декодировать минимальную дату")
    func decodeMinimumDate() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "1970-01-01T00:00:00Z"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let expectedDate = try #require(ISO8601DateFormatter().date(from: "1970-01-01T00:00:00Z"))
        #expect(result.date == expectedDate)
    }

    @Test("Должен декодировать минимальную дату в server date time формате")
    func decodeMinimumDateInServerDateTimeFormat() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "1970-01-01T00:00:00"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let expectedDate = try #require(formatter.date(from: "1970-01-01T00:00:00"))
        #expect(result.date == expectedDate)
    }

    @Test("Должен декодировать дату с максимальными дробными секундами")
    func decodeDateWithMaximumFractionalSeconds() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "2024-01-15T10:30:00.999999Z"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: "2024-01-15T10:30:00.999999Z"))
        #expect(result.date == expectedDate)
    }

    // MARK: - Декодирование ISO short date формата

    @Test("Должен декодировать ISO short date формат")
    func decodeIsoShortDateFormat() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = try #require("""
        {
            "date": "2024-01-15"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let expectedModel = try decoder.decode(TestModel.self, from: json)
        #expect(result.date == expectedModel.date)
    }

    @Test("Должен декодировать опциональное поле Date? с ISO short date форматом")
    func decodeOptionalDateWithIsoShortDateFormat() throws {
        struct TestModel: Decodable {
            let date: Date?
        }

        let json = try #require("""
        {
            "date": "1990-11-25"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(TestModel.self, from: json)
        let date = try #require(result.date)
        let expectedModel = try decoder.decode(TestModel.self, from: json)
        let expectedDate = try #require(expectedModel.date)
        let calendar = Calendar(identifier: .iso8601)
        #expect(calendar.isDate(date, equalTo: expectedDate, toGranularity: .day))
    }
}
