import Foundation
@testable import SWNetwork
import Testing

@Suite("Тесты гибкого декодирования дат")
struct JSONDecoderExtensionTests {
    private struct TestModel: Decodable {
        let date: Date
    }

    private struct OptionalTestModel: Decodable {
        let date: Date?
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .flexibleDateDecoding
        return decoder
    }

    @Test("Должен декодировать стандартный ISO8601 формат без изменения абсолютного момента")
    func decodeISO8601ZuluKeepsAbsoluteMoment() throws {
        let result = try decodeRequiredDate("2024-01-15T10:30:00Z")
        let expectedDate = try #require(ISO8601DateFormatter().date(from: "2024-01-15T10:30:00Z"))
        #expect(result == expectedDate)
    }

    @Test("Должен декодировать ISO8601 с дробными секундами без изменения абсолютного момента")
    func decodeISO8601FractionalSecondsKeepsAbsoluteMoment() throws {
        let result = try decodeRequiredDate("2024-01-15T10:30:00.123Z")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: "2024-01-15T10:30:00.123Z"))
        #expect(result == expectedDate)
    }

    @Test("Должен декодировать ISO8601 с явным offset без применения fallback policy")
    func decodeISO8601ExplicitOffsetKeepsAbsoluteMoment() throws {
        let result = try decodeRequiredDate("2024-01-15T10:30:00+03:00")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let expectedDate = try #require(formatter.date(from: "2024-01-15T10:30:00+03:00"))
        #expect(result == expectedDate)
    }

    @Test("Должен интерпретировать server datetime без timezone по policy Europe/Moscow")
    func decodeServerDateTimeWithoutTimezoneUsesEuropeMoscowPolicy() throws {
        let result = try decodeRequiredDate("2024-01-15T10:30:00")
        let expectedDate = try moscowDate(from: "2024-01-15T10:30:00")
        #expect(result == expectedDate)
    }

    @Test("Должен интерпретировать server datetime без timezone не как UTC")
    func decodeServerDateTimeWithoutTimezoneDoesNotUseUTCInterpretation() throws {
        let result = try decodeRequiredDate("2024-01-15T10:30:00")
        let utc = try #require(TimeZone(secondsFromGMT: 0))
        let utcDate = try date(
            from: "2024-01-15T10:30:00",
            format: "yyyy-MM-dd'T'HH:mm:ss",
            timeZone: utc
        )

        #expect(result != utcDate)
    }

    @Test("Должен применять ту же Europe/Moscow policy для опционального Date поля")
    func decodeServerDateTimeOptionalFieldUsesSamePolicy() throws {
        let result = try decodeOptionalDate("2024-01-15T10:30:00")
        let date = try #require(result)
        let expectedDate = try moscowDate(from: "2024-01-15T10:30:00")
        #expect(date == expectedDate)
    }

    @Test("Должен декодировать short date по стабильной UTC policy")
    func decodeIsoShortDateUsesStableUTCPolicy() throws {
        let result = try decodeRequiredDate("2024-01-15")
        let expectedDate = try utcShortDate(from: "2024-01-15")
        #expect(result == expectedDate)
    }

    @Test("Должен декодировать опциональное поле Date с ISO8601 значением")
    func decodeOptionalDateWithValidDate() throws {
        let result = try decodeOptionalDate("2024-01-15T10:30:00Z")
        let date = try #require(result)
        let expectedDate = try #require(ISO8601DateFormatter().date(from: "2024-01-15T10:30:00Z"))
        #expect(date == expectedDate)
    }

    @Test("Должен декодировать опциональное поле Date с null значением")
    func decodeOptionalDateWithNull() throws {
        let json = try #require("""
        {
            "date": null
        }
        """.data(using: .utf8))

        let result = try decoder.decode(OptionalTestModel.self, from: json)
        #expect(result.date == nil)
    }

    @Test("Должен декодировать опциональное поле Date с отсутствующим ключом")
    func decodeOptionalDateWithMissingKey() throws {
        let json = try #require("""
        {
            "other": "value"
        }
        """.data(using: .utf8))

        let result = try decoder.decode(OptionalTestModel.self, from: json)
        #expect(result.date == nil)
    }

    @Test("Должен выбрасывать ошибку для невалидной даты")
    func decodeInvalidDate() throws {
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
        let json = try #require("""
        {
            "date": "2024-13-45"
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(TestModel.self, from: json)
        }
    }

    private func decodeRequiredDate(_ value: String) throws -> Date {
        let json = try #require("""
        {
            "date": "\(value)"
        }
        """.data(using: .utf8))

        return try decoder.decode(TestModel.self, from: json).date
    }

    private func decodeOptionalDate(_ value: String) throws -> Date? {
        let json = try #require("""
        {
            "date": "\(value)"
        }
        """.data(using: .utf8))

        return try decoder.decode(OptionalTestModel.self, from: json).date
    }

    private func moscowDate(from string: String) throws -> Date {
        let timeZone = try #require(TimeZone(identifier: "Europe/Moscow"))
        return try date(from: string, format: "yyyy-MM-dd'T'HH:mm:ss", timeZone: timeZone)
    }

    private func utcShortDate(from string: String) throws -> Date {
        let timeZone = try #require(TimeZone(secondsFromGMT: 0))
        return try date(from: string, format: "yyyy-MM-dd", timeZone: timeZone)
    }

    private func date(from string: String, format: String, timeZone: TimeZone) throws -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        return try #require(formatter.date(from: string))
    }
}
