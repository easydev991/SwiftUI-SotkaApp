import Foundation
@testable import SwiftUI_SotkaApp
import SWNetwork
import Testing

@Suite("Тесты декодирования UserResponse")
struct UserResponseTests {
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .flexibleDateDecoding
        return decoder
    }

    // MARK: - Декодирование с валидными данными

    @Test("Должен декодировать UserResponse с валидными данными (все поля заполнены)")
    func decodeUserResponseWithAllFields() throws {
        let json = try #require("""
        {
            "id": 123,
            "name": "John",
            "fullname": "John Doe",
            "email": "john@example.com",
            "image": "https://example.com/image.jpg",
            "city_id": 1,
            "country_id": 2,
            "gender": 1,
            "birth_date": "1990-11-25"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        #expect(response.id == 123)
        let name = try #require(response.name)
        #expect(name == "John")
        let fullname = try #require(response.fullname)
        #expect(fullname == "John Doe")
        let email = try #require(response.email)
        #expect(email == "john@example.com")
        let image = try #require(response.image)
        #expect(image == "https://example.com/image.jpg")
        let cityId = try #require(response.cityId)
        #expect(cityId == 1)
        let countryId = try #require(response.countryId)
        #expect(countryId == 2)
        let gender = try #require(response.gender)
        #expect(gender == 1)
        let birthDate = try #require(response.birthDate)
        let expectedDate = try #require(createDate(year: 1990, month: 11, day: 25))
        let calendar = Calendar(identifier: .iso8601)
        #expect(calendar.isDate(birthDate, equalTo: expectedDate, toGranularity: .day))
    }

    // MARK: - Декодирование с null значениями

    @Test("Должен декодировать UserResponse с null значениями для опциональных полей")
    func decodeUserResponseWithNullOptionalFields() throws {
        let json = try #require("""
        {
            "id": 123,
            "name": null,
            "fullname": null,
            "email": null,
            "image": null,
            "city_id": null,
            "country_id": null,
            "gender": null,
            "birth_date": null
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        #expect(response.id == 123)
        #expect(response.name == nil)
        #expect(response.fullname == nil)
        #expect(response.email == nil)
        #expect(response.image == nil)
        #expect(response.cityId == nil)
        #expect(response.countryId == nil)
        #expect(response.gender == nil)
        #expect(response.birthDate == nil)
    }

    // MARK: - Декодирование с отсутствующими полями

    @Test("Должен декодировать UserResponse с отсутствующими опциональными полями")
    func decodeUserResponseWithMissingOptionalFields() throws {
        let json = try #require("""
        {
            "id": 123
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        #expect(response.id == 123)
        #expect(response.name == nil)
        #expect(response.fullname == nil)
        #expect(response.email == nil)
        #expect(response.image == nil)
        #expect(response.cityId == nil)
        #expect(response.countryId == nil)
        #expect(response.gender == nil)
        #expect(response.birthDate == nil)
    }

    // MARK: - Декодирование числовых полей как строки

    @Test("Должен декодировать UserResponse когда числовые поля приходят как строки")
    func decodeUserResponseWithNumericFieldsAsStrings() throws {
        let json = try #require("""
        {
            "id": 123,
            "city_id": "1",
            "country_id": "2",
            "gender": "1"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        #expect(response.id == 123)
        let cityId = try #require(response.cityId)
        #expect(cityId == 1)
        let countryId = try #require(response.countryId)
        #expect(countryId == 2)
        let gender = try #require(response.gender)
        #expect(gender == 1)
    }

    // MARK: - Декодирование числовых полей как числа

    @Test("Должен декодировать UserResponse когда числовые поля приходят как числа")
    func decodeUserResponseWithNumericFieldsAsNumbers() throws {
        let json = try #require("""
        {
            "id": 123,
            "city_id": 1,
            "country_id": 2,
            "gender": 1
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        #expect(response.id == 123)
        let cityId = try #require(response.cityId)
        #expect(cityId == 1)
        let countryId = try #require(response.countryId)
        #expect(countryId == 2)
        let gender = try #require(response.gender)
        #expect(gender == 1)
    }

    // MARK: - Декодирование числовых полей как null

    @Test("Должен декодировать UserResponse когда числовые поля приходят как null")
    func decodeUserResponseWithNumericFieldsAsNull() throws {
        let json = try #require("""
        {
            "id": 123,
            "city_id": null,
            "country_id": null,
            "gender": null
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        #expect(response.id == 123)
        #expect(response.cityId == nil)
        #expect(response.countryId == nil)
        #expect(response.gender == nil)
    }

    // MARK: - Декодирование числовых полей как неожиданные типы

    @Test("Должен декодировать UserResponse когда числовые поля приходят как неожиданные типы")
    func decodeUserResponseWithNumericFieldsAsUnexpectedTypes() throws {
        let json = try #require("""
        {
            "id": 123,
            "city_id": false,
            "country_id": false,
            "gender": false
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        #expect(response.id == 123)
        #expect(response.cityId == nil)
        #expect(response.countryId == nil)
        #expect(response.gender == nil)
    }

    // MARK: - Декодирование когда id отсутствует

    @Test("Должен выбрасывать ошибку когда id отсутствует")
    func decodeUserResponseWithMissingId() throws {
        let jsonData = try #require("""
        {
            "name": "John"
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(UserResponse.self, from: jsonData)
        }
    }

    // MARK: - Декодирование когда id приходит как строка

    @Test("Должен декодировать UserResponse когда id приходит как строка")
    func decodeUserResponseWithIdAsString() throws {
        let json = try #require("""
        {
            "id": "123"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        #expect(response.id == 123)
    }

    // MARK: - Декодирование birthDate

    @Test("Должен декодировать UserResponse когда birthDate отсутствует")
    func decodeUserResponseWithMissingBirthDate() throws {
        let json = try #require("""
        {
            "id": 123
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        #expect(response.birthDate == nil)
    }

    @Test("Должен декодировать UserResponse когда birthDate приходит как null")
    func decodeUserResponseWithNullBirthDate() throws {
        let json = try #require("""
        {
            "id": 123,
            "birth_date": null
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        #expect(response.birthDate == nil)
    }

    @Test("Должен декодировать UserResponse когда birthDate приходит как невалидная строка")
    func decodeUserResponseWithInvalidBirthDateString() throws {
        let json = try #require("""
        {
            "id": 123,
            "birth_date": "invalid-date"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        #expect(response.birthDate == nil)
    }

    @Test("Должен декодировать UserResponse когда birthDate приходит как неожиданный тип")
    func decodeUserResponseWithUnexpectedBirthDateType() throws {
        let json = try #require("""
        {
            "id": 123,
            "birth_date": 12345
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        #expect(response.birthDate == nil)
    }

    @Test("Должен декодировать UserResponse когда birthDate приходит в формате ISO short date")
    func decodeUserResponseWithValidBirthDate() throws {
        let json = try #require("""
        {
            "id": 123,
            "birth_date": "1990-11-25"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(UserResponse.self, from: json)

        let birthDate = try #require(response.birthDate)
        let expectedDate = try #require(createDate(year: 1990, month: 11, day: 25))
        let calendar = Calendar(identifier: .iso8601)
        #expect(calendar.isDate(birthDate, equalTo: expectedDate, toGranularity: .day))
    }

    // MARK: - Вспомогательные методы

    private func createDate(year: Int, month: Int, day: Int) -> Date? {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let components = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: components)
    }
}
