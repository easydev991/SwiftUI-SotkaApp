import Foundation
@testable import SWUtils
import Testing

struct KeyedDecodingContainerExtensionTests {
    // MARK: - Опциональное декодирование Int

    @Test("Должен декодировать Int из строки")
    func decodeIntOrStringIfPresent_fromString() throws {
        let json = try #require("""
        {
            "value": "123"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntContainer.self, from: json)
        let value = try #require(result.value)
        #expect(value == 123)
    }

    @Test("Должен декодировать Int из числа")
    func decodeIntOrStringIfPresent_fromInt() throws {
        let json = try #require("""
        {
            "value": 123
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntContainer.self, from: json)
        let value = try #require(result.value)
        #expect(value == 123)
    }

    @Test("Должен возвращать nil для отсутствующего ключа")
    func decodeIntOrStringIfPresent_missingKey() throws {
        let json = try #require("""
        {
            "other": "value"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntContainer.self, from: json)
        #expect(result.value == nil)
    }

    @Test("Должен возвращать nil для невалидной строки")
    func decodeIntOrStringIfPresent_invalidString() throws {
        let json = try #require("""
        {
            "value": "not_a_number"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntContainer.self, from: json)
        #expect(result.value == nil)
    }

    @Test("Должен возвращать nil для пустой строки")
    func decodeIntOrStringIfPresent_emptyString() throws {
        let json = try #require("""
        {
            "value": ""
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntContainer.self, from: json)
        #expect(result.value == nil)
    }

    @Test("Должен возвращать nil для null значения")
    func decodeIntOrStringIfPresent_nullValue() throws {
        let json = try #require("""
        {
            "value": null
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntContainer.self, from: json)
        #expect(result.value == nil)
    }

    // MARK: - Обязательное декодирование Int

    @Test("Должен декодировать обязательное Int из строки")
    func decodeIntOrString_fromString() throws {
        let json = try #require("""
        {
            "value": "123"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(RequiredIntContainer.self, from: json)
        #expect(result.value == 123)
    }

    @Test("Должен декодировать обязательное Int из числа")
    func decodeIntOrString_fromInt() throws {
        let json = try #require("""
        {
            "value": 123
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(RequiredIntContainer.self, from: json)
        #expect(result.value == 123)
    }

    @Test("Должен выбрасывать ошибку для отсутствующего обязательного ключа")
    func decodeIntOrString_missingKey() throws {
        let json = try #require("""
        {
            "other": "value"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(RequiredIntContainer.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку для невалидной строки")
    func decodeIntOrString_invalidString() throws {
        let json = try #require("""
        {
            "value": "not_a_number"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(RequiredIntContainer.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку для null значения")
    func decodeIntOrString_nullValue() throws {
        let json = try #require("""
        {
            "value": null
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(RequiredIntContainer.self, from: json)
        }
    }

    // MARK: - Опциональное декодирование Float

    @Test("Должен декодировать Float из строки")
    func decodeFloatOrStringIfPresent_fromString() throws {
        let json = try #require("""
        {
            "value": "123.45"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalFloatContainer.self, from: json)
        let value = try #require(result.value)
        #expect(value == 123.45)
    }

    @Test("Должен декодировать Float из числа")
    func decodeFloatOrStringIfPresent_fromFloat() throws {
        let json = try #require("""
        {
            "value": 123.45
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalFloatContainer.self, from: json)
        let value = try #require(result.value)
        #expect(value == 123.45)
    }

    @Test("Должен возвращать nil для отсутствующего ключа (Float)")
    func decodeFloatOrStringIfPresent_missingKey() throws {
        let json = try #require("""
        {
            "other": "value"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalFloatContainer.self, from: json)
        #expect(result.value == nil)
    }

    @Test("Должен возвращать nil для невалидной строки (Float)")
    func decodeFloatOrStringIfPresent_invalidString() throws {
        let json = try #require("""
        {
            "value": "not_a_number"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalFloatContainer.self, from: json)
        #expect(result.value == nil)
    }

    @Test("Должен возвращать nil для пустой строки (Float)")
    func decodeFloatOrStringIfPresent_emptyString() throws {
        let json = try #require("""
        {
            "value": ""
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalFloatContainer.self, from: json)
        #expect(result.value == nil)
    }

    @Test("Должен возвращать nil для null значения (Float)")
    func decodeFloatOrStringIfPresent_nullValue() throws {
        let json = try #require("""
        {
            "value": null
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalFloatContainer.self, from: json)
        #expect(result.value == nil)
    }

    // MARK: - Граничные случаи

    @Test("Должен корректно обрабатывать отрицательные числа (Int)")
    func decodeIntOrStringIfPresent_negativeNumber() throws {
        let json = try #require("""
        {
            "value": "-123"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntContainer.self, from: json)
        let value = try #require(result.value)
        #expect(value == -123)
    }

    @Test("Должен корректно обрабатывать отрицательные числа (Float)")
    func decodeFloatOrStringIfPresent_negativeNumber() throws {
        let json = try #require("""
        {
            "value": "-123.45"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalFloatContainer.self, from: json)
        let value = try #require(result.value)
        #expect(value == -123.45)
    }

    @Test("Должен корректно обрабатывать ноль (Int)")
    func decodeIntOrStringIfPresent_zero() throws {
        let json = try #require("""
        {
            "value": "0"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntContainer.self, from: json)
        let value = try #require(result.value)
        #expect(value == 0)
    }

    @Test("Должен корректно обрабатывать ноль (Float)")
    func decodeFloatOrStringIfPresent_zero() throws {
        let json = try #require("""
        {
            "value": "0.0"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalFloatContainer.self, from: json)
        let value = try #require(result.value)
        #expect(value == 0.0)
    }

    // MARK: - Декодирование ISO8601 Date

    @Test("Должен декодировать Date из ISO8601 строки")
    func decodeISO8601DateIfPresent_validDate() throws {
        let json = try #require("""
        {
            "value": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalDateContainer.self, from: json)
        let value = try #require(result.value)
        let expectedDate = ISO8601DateFormatter().date(from: "2024-01-15T10:30:00Z")
        let expectedDateValue = try #require(expectedDate)
        #expect(value == expectedDateValue)
    }

    @Test("Должен декодировать Date из ISO8601 строки с дробными секундами")
    func decodeISO8601DateIfPresent_dateWithFractionalSeconds() throws {
        let json = try #require("""
        {
            "value": "2024-01-15T10:30:00.123Z"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalDateContainer.self, from: json)
        let value = try #require(result.value)
        let calendar = Calendar.current
        #expect(calendar.component(.year, from: value) == 2024)
        #expect(calendar.component(.month, from: value) == 1)
        #expect(calendar.component(.day, from: value) == 15)
    }

    @Test("Должен возвращать nil для null значения (Date)")
    func decodeISO8601DateIfPresent_nullValue() throws {
        let json = try #require("""
        {
            "value": null
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalDateContainer.self, from: json)
        #expect(result.value == nil)
    }

    @Test("Должен возвращать nil для отсутствующего ключа (Date)")
    func decodeISO8601DateIfPresent_missingKey() throws {
        let json = try #require("""
        {
            "other": "value"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalDateContainer.self, from: json)
        #expect(result.value == nil)
    }

    @Test("Должен возвращать nil для невалидной строки (Date)")
    func decodeISO8601DateIfPresent_invalidString() throws {
        let json = try #require("""
        {
            "value": "not_a_date"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalDateContainer.self, from: json)
        #expect(result.value == nil)
    }

    // MARK: - Декодирование Int с обработкой false

    @Test("Должен декодировать Int из числа")
    func decodeIntOrNilIfPresent_fromInt() throws {
        let json = try #require("""
        {
            "value": 100
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntOrNilContainer.self, from: json)
        let value = try #require(result.value)
        #expect(value == 100)
    }

    @Test("Должен возвращать nil для false значения")
    func decodeIntOrNilIfPresent_falseValue() throws {
        let json = try #require("""
        {
            "value": false
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntOrNilContainer.self, from: json)
        #expect(result.value == nil)
    }

    @Test("Должен возвращать nil для null значения (IntOrNil)")
    func decodeIntOrNilIfPresent_nullValue() throws {
        let json = try #require("""
        {
            "value": null
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntOrNilContainer.self, from: json)
        #expect(result.value == nil)
    }

    @Test("Должен возвращать nil для отсутствующего ключа (IntOrNil)")
    func decodeIntOrNilIfPresent_missingKey() throws {
        let json = try #require("""
        {
            "other": "value"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntOrNilContainer.self, from: json)
        #expect(result.value == nil)
    }

    @Test("Должен возвращать nil для строки (IntOrNil)")
    func decodeIntOrNilIfPresent_stringValue() throws {
        let json = try #require("""
        {
            "value": "100"
        }
        """.data(using: .utf8))
        let decoder = JSONDecoder()
        let result = try decoder.decode(OptionalIntOrNilContainer.self, from: json)
        #expect(result.value == nil)
    }
}

// MARK: - Вспомогательные структуры

private struct OptionalIntContainer: Decodable {
    let value: Int?

    enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = container.decodeIntOrStringIfPresent(.value)
    }
}

private struct RequiredIntContainer: Decodable {
    let value: Int

    enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = try container.decodeIntOrString(.value)
    }
}

private struct OptionalFloatContainer: Decodable {
    let value: Float?

    enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = container.decodeFloatOrStringIfPresent(.value)
    }
}

private struct OptionalDateContainer: Decodable {
    let value: Date?

    enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = container.decodeISO8601DateIfPresent(.value)
    }
}

private struct OptionalIntOrNilContainer: Decodable {
    let value: Int?

    enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = container.decodeIntOrNilIfPresent(.value)
    }
}
