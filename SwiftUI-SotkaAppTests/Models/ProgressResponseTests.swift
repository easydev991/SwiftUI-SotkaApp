import Foundation
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

@Suite("Тесты декодирования ProgressResponse")
struct ProgressResponseTests {
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .flexibleDateDecoding
        return decoder
    }

    private func dateFromISO8601String(_ string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }

    // MARK: - Декодирование с валидными данными

    @Test("Должен декодировать ProgressResponse с валидными данными (все поля заполнены)")
    func decodeProgressResponseWithAllFields() throws {
        let json = try #require("""
        {
            "id": 1,
            "pullups": 10,
            "pushups": 20,
            "squats": 30,
            "weight": 75.5,
            "create_date": "2024-01-15T10:30:00Z",
            "modify_date": "2024-01-16T11:00:00Z",
            "photo_front": "https://example.com/front.jpg",
            "photo_back": "https://example.com/back.jpg",
            "photo_side": "https://example.com/side.jpg"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let pullups = try #require(response.pullups)
        #expect(pullups == 10)
        let pushups = try #require(response.pushups)
        #expect(pushups == 20)
        let squats = try #require(response.squats)
        #expect(squats == 30)
        let weight = try #require(response.weight)
        #expect(weight == 75.5)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
        let modifyDate = try #require(response.modifyDate)
        let expectedModifyDate = try #require(dateFromISO8601String("2024-01-16T11:00:00Z"))
        #expect(modifyDate == expectedModifyDate)
        let photoFront = try #require(response.photoFront)
        #expect(photoFront == "https://example.com/front.jpg")
        let photoBack = try #require(response.photoBack)
        #expect(photoBack == "https://example.com/back.jpg")
        let photoSide = try #require(response.photoSide)
        #expect(photoSide == "https://example.com/side.jpg")
    }

    // MARK: - Декодирование когда id приходит как строка или число

    @Test("Должен декодировать ProgressResponse когда id приходит как строка")
    func decodeProgressResponseWithIdAsString() throws {
        let json = try #require("""
        {
            "id": "1",
            "create_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
    }

    @Test("Должен декодировать ProgressResponse когда id приходит как число")
    func decodeProgressResponseWithIdAsNumber() throws {
        let json = try #require("""
        {
            "id": 1,
            "create_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
    }

    // MARK: - Декодирование когда числовые поля приходят как строки или числа

    @Test("Должен декодировать ProgressResponse когда числовые поля приходят как строки")
    func decodeProgressResponseWithNumericFieldsAsStrings() throws {
        let json = try #require("""
        {
            "id": 1,
            "pullups": "10",
            "pushups": "20",
            "squats": "30",
            "create_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let pullups = try #require(response.pullups)
        #expect(pullups == 10)
        let pushups = try #require(response.pushups)
        #expect(pushups == 20)
        let squats = try #require(response.squats)
        #expect(squats == 30)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
    }

    @Test("Должен декодировать ProgressResponse когда числовые поля приходят как числа")
    func decodeProgressResponseWithNumericFieldsAsNumbers() throws {
        let json = try #require("""
        {
            "id": 1,
            "pullups": 10,
            "pushups": 20,
            "squats": 30,
            "create_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let pullups = try #require(response.pullups)
        #expect(pullups == 10)
        let pushups = try #require(response.pushups)
        #expect(pushups == 20)
        let squats = try #require(response.squats)
        #expect(squats == 30)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
    }

    // MARK: - Декодирование когда weight приходит как строка или число

    @Test("Должен декодировать ProgressResponse когда weight приходит как строка")
    func decodeProgressResponseWithWeightAsString() throws {
        let json = try #require("""
        {
            "id": 1,
            "weight": "75.5",
            "create_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let weight = try #require(response.weight)
        #expect(weight == 75.5)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
    }

    @Test("Должен декодировать ProgressResponse когда weight приходит как число")
    func decodeProgressResponseWithWeightAsNumber() throws {
        let json = try #require("""
        {
            "id": 1,
            "weight": 75.5,
            "create_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let weight = try #require(response.weight)
        #expect(weight == 75.5)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
    }

    // MARK: - Декодирование когда опциональные числовые поля отсутствуют или null

    @Test("Должен декодировать ProgressResponse когда опциональные числовые поля отсутствуют")
    func decodeProgressResponseWithMissingNumericFields() throws {
        let json = try #require("""
        {
            "id": 1,
            "create_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        #expect(response.pullups == nil)
        #expect(response.pushups == nil)
        #expect(response.squats == nil)
        #expect(response.weight == nil)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
    }

    @Test("Должен декодировать ProgressResponse когда опциональные числовые поля приходят как null")
    func decodeProgressResponseWithNullNumericFields() throws {
        let json = try #require("""
        {
            "id": 1,
            "pullups": null,
            "pushups": null,
            "squats": null,
            "weight": null,
            "create_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        #expect(response.pullups == nil)
        #expect(response.pushups == nil)
        #expect(response.squats == nil)
        #expect(response.weight == nil)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
    }

    @Test("Должен декодировать ProgressResponse когда опциональные числовые поля приходят как неожиданные типы")
    func decodeProgressResponseWithUnexpectedTypesForNumericFields() throws {
        let json = try #require("""
        {
            "id": 1,
            "pullups": false,
            "pushups": "invalid",
            "squats": [],
            "weight": {},
            "create_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        #expect(response.pullups == nil)
        #expect(response.pushups == nil)
        #expect(response.squats == nil)
        #expect(response.weight == nil)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
    }

    // MARK: - Декодирование когда createDate отсутствует или null

    @Test("Должен выбрасывать ошибку когда createDate отсутствует")
    func decodeProgressResponseWithMissingCreateDate() throws {
        let json = try #require("""
        {
            "id": 1
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(ProgressResponse.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку когда createDate приходит как null")
    func decodeProgressResponseWithNullCreateDate() throws {
        let json = try #require("""
        {
            "id": 1,
            "create_date": null
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(ProgressResponse.self, from: json)
        }
    }

    @Test("Должен декодировать ProgressResponse когда createDate приходит в формате server date time")
    func decodeProgressResponseWithCreateDateInServerDateTimeFormat() throws {
        let json = try #require("""
        {
            "id": 1,
            "create_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
    }

    // MARK: - Декодирование когда modifyDate отсутствует или null

    @Test("Должен декодировать ProgressResponse когда modifyDate отсутствует")
    func decodeProgressResponseWithMissingModifyDate() throws {
        let json = try #require("""
        {
            "id": 1,
            "create_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
        #expect(response.modifyDate == nil)
    }

    @Test("Должен декодировать ProgressResponse когда modifyDate приходит как null")
    func decodeProgressResponseWithNullModifyDate() throws {
        let json = try #require("""
        {
            "id": 1,
            "create_date": "2024-01-15T10:30:00Z",
            "modify_date": null
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
        #expect(response.modifyDate == nil)
    }

    @Test("Должен декодировать ProgressResponse когда modifyDate приходит в формате server date time")
    func decodeProgressResponseWithModifyDateInServerDateTimeFormat() throws {
        let json = try #require("""
        {
            "id": 1,
            "create_date": "2024-01-15T10:30:00Z",
            "modify_date": "2024-01-16T11:00:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
        let modifyDate = try #require(response.modifyDate)
        let expectedModifyDate = try #require(dateFromISO8601String("2024-01-16T11:00:00Z"))
        #expect(modifyDate == expectedModifyDate)
    }

    // MARK: - Декодирование когда createDate или modifyDate приходят как невалидная строка

    @Test("Должен выбрасывать ошибку когда createDate приходит как невалидная строка")
    func decodeProgressResponseWithInvalidCreateDate() throws {
        let json = try #require("""
        {
            "id": 1,
            "create_date": "invalid-date"
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(ProgressResponse.self, from: json)
        }
    }

    @Test("Должен декодировать ProgressResponse когда modifyDate приходит как невалидная строка (должно быть nil)")
    func decodeProgressResponseWithInvalidModifyDate() throws {
        let json = try #require("""
        {
            "id": 1,
            "create_date": "2024-01-15T10:30:00Z",
            "modify_date": "invalid-date"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
        #expect(response.modifyDate == nil)
    }

    // MARK: - Декодирование когда опциональные строковые поля отсутствуют или null

    @Test("Должен декодировать ProgressResponse когда опциональные строковые поля отсутствуют")
    func decodeProgressResponseWithMissingStringFields() throws {
        let json = try #require("""
        {
            "id": 1,
            "create_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
        #expect(response.photoFront == nil)
        #expect(response.photoBack == nil)
        #expect(response.photoSide == nil)
    }

    @Test("Должен декодировать ProgressResponse когда опциональные строковые поля приходят как null")
    func decodeProgressResponseWithNullStringFields() throws {
        let json = try #require("""
        {
            "id": 1,
            "create_date": "2024-01-15T10:30:00Z",
            "photo_front": null,
            "photo_back": null,
            "photo_side": null
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ProgressResponse.self, from: json)

        #expect(response.id == 1)
        let expectedCreateDate = try #require(dateFromISO8601String("2024-01-15T10:30:00Z"))
        #expect(response.createDate == expectedCreateDate)
        #expect(response.photoFront == nil)
        #expect(response.photoBack == nil)
        #expect(response.photoSide == nil)
    }
}
