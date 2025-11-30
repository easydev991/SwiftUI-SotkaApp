import Foundation
@testable import SwiftUI_SotkaApp
import SWNetwork
import SWUtils
import Testing

@Suite("Тесты декодирования CustomExerciseResponse")
struct CustomExerciseResponseTests {
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .flexibleDateDecoding
        return decoder
    }

    private func dateFromServerDateTimeSec(_ string: String) -> Date? {
        DateFormatterService.dateFromString(string, format: .serverDateTimeSec)
    }

    // MARK: - Декодирование с валидными данными

    @Test("Должен декодировать CustomExerciseResponse с валидными данными (все поля заполнены)")
    func decodeCustomExerciseResponseWithAllFields() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 1,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CustomExerciseResponse.self, from: json)

        #expect(response.id == "exercise-1")
        #expect(response.name == "Подтягивания")
        #expect(response.imageId == 1)
        let expectedCreateDate = try #require(dateFromServerDateTimeSec("2024-01-15T10:30:00"))
        #expect(response.createDate == expectedCreateDate)
        let expectedModifyDate = try #require(dateFromServerDateTimeSec("2024-01-16T11:00:00"))
        let modifyDate = try #require(response.modifyDate)
        #expect(modifyDate == expectedModifyDate)
        #expect(!response.isHidden)
    }

    // MARK: - Декодирование когда imageId приходит как строка или число

    @Test("Должен декодировать CustomExerciseResponse когда imageId приходит как строка")
    func decodeCustomExerciseResponseWithImageIdAsString() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": "1",
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CustomExerciseResponse.self, from: json)

        #expect(response.id == "exercise-1")
        #expect(response.name == "Подтягивания")
        #expect(response.imageId == 1)
        let expectedCreateDate = try #require(dateFromServerDateTimeSec("2024-01-15T10:30:00"))
        #expect(response.createDate == expectedCreateDate)
        let expectedModifyDate = try #require(dateFromServerDateTimeSec("2024-01-16T11:00:00"))
        let modifyDate = try #require(response.modifyDate)
        #expect(modifyDate == expectedModifyDate)
    }

    @Test("Должен декодировать CustomExerciseResponse когда imageId приходит как число")
    func decodeCustomExerciseResponseWithImageIdAsNumber() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 2,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CustomExerciseResponse.self, from: json)

        #expect(response.id == "exercise-1")
        #expect(response.name == "Подтягивания")
        #expect(response.imageId == 2)
    }

    // MARK: - Декодирование когда imageId отсутствует или null

    @Test("Должен выбрасывать ошибку когда imageId отсутствует")
    func decodeCustomExerciseResponseWithMissingImageId() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CustomExerciseResponse.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку когда imageId приходит как null")
    func decodeCustomExerciseResponseWithNullImageId() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": null,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CustomExerciseResponse.self, from: json)
        }
    }

    // MARK: - Декодирование когда imageId приходит как неожиданный тип

    @Test("Должен выбрасывать ошибку когда imageId приходит как неожиданный тип")
    func decodeCustomExerciseResponseWithImageIdAsUnexpectedType() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": false,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CustomExerciseResponse.self, from: json)
        }
    }

    // MARK: - Декодирование когда обязательные поля отсутствуют

    @Test("Должен выбрасывать ошибку когда id отсутствует")
    func decodeCustomExerciseResponseWithMissingId() throws {
        let json = try #require("""
        {
            "name": "Подтягивания",
            "image_id": 1,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CustomExerciseResponse.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку когда name отсутствует")
    func decodeCustomExerciseResponseWithMissingName() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "image_id": 1,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CustomExerciseResponse.self, from: json)
        }
    }

    // MARK: - Декодирование когда createDate отсутствует или null

    @Test("Должен выбрасывать ошибку когда createDate отсутствует")
    func decodeCustomExerciseResponseWithMissingCreateDate() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 1,
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CustomExerciseResponse.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку когда createDate приходит как null")
    func decodeCustomExerciseResponseWithNullCreateDate() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 1,
            "create_date": null,
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CustomExerciseResponse.self, from: json)
        }
    }

    // MARK: - Декодирование когда createDate приходит в формате server date time

    @Test("Должен декодировать CustomExerciseResponse когда createDate приходит в формате server date time")
    func decodeCustomExerciseResponseWithCreateDateInServerDateTimeFormat() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 1,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CustomExerciseResponse.self, from: json)

        let expectedDate = try #require(dateFromServerDateTimeSec("2024-01-15T10:30:00"))
        #expect(response.createDate == expectedDate)
    }

    // MARK: - Декодирование когда modifyDate отсутствует или null

    @Test("Должен декодировать CustomExerciseResponse когда modifyDate отсутствует")
    func decodeCustomExerciseResponseWithMissingModifyDate() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 1,
            "create_date": "2024-01-15T10:30:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CustomExerciseResponse.self, from: json)

        #expect(response.id == "exercise-1")
        #expect(response.name == "Подтягивания")
        #expect(response.imageId == 1)
        let expectedCreateDate = try #require(dateFromServerDateTimeSec("2024-01-15T10:30:00"))
        #expect(response.createDate == expectedCreateDate)
        #expect(response.modifyDate == nil)
    }

    @Test("Должен декодировать CustomExerciseResponse когда modifyDate приходит как null")
    func decodeCustomExerciseResponseWithNullModifyDate() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 1,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": null,
            "is_hidden": false
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CustomExerciseResponse.self, from: json)

        #expect(response.id == "exercise-1")
        #expect(response.name == "Подтягивания")
        #expect(response.imageId == 1)
        let expectedCreateDate = try #require(dateFromServerDateTimeSec("2024-01-15T10:30:00"))
        #expect(response.createDate == expectedCreateDate)
        #expect(response.modifyDate == nil)
    }

    // MARK: - Декодирование когда modifyDate приходит в формате server date time

    @Test("Должен декодировать CustomExerciseResponse когда modifyDate приходит в формате server date time")
    func decodeCustomExerciseResponseWithModifyDateInServerDateTimeFormat() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 1,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CustomExerciseResponse.self, from: json)

        let expectedDate = try #require(dateFromServerDateTimeSec("2024-01-16T11:00:00"))
        let modifyDate = try #require(response.modifyDate)
        #expect(modifyDate == expectedDate)
    }

    // MARK: - Декодирование когда createDate или modifyDate приходят как невалидная строка

    @Test("Должен выбрасывать ошибку когда createDate приходит как невалидная строка")
    func decodeCustomExerciseResponseWithInvalidCreateDate() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 1,
            "create_date": "invalid-date",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CustomExerciseResponse.self, from: json)
        }
    }

    @Test("Должен декодировать CustomExerciseResponse когда modifyDate приходит как невалидная строка (возвращает nil)")
    func decodeCustomExerciseResponseWithInvalidModifyDate() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 1,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "invalid-date",
            "is_hidden": false
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CustomExerciseResponse.self, from: json)

        #expect(response.id == "exercise-1")
        #expect(response.name == "Подтягивания")
        #expect(response.imageId == 1)
        let expectedCreateDate = try #require(dateFromServerDateTimeSec("2024-01-15T10:30:00"))
        #expect(response.createDate == expectedCreateDate)
        #expect(response.modifyDate == nil)
    }

    // MARK: - Декодирование когда isHidden отсутствует или null

    @Test("Должен выбрасывать ошибку когда isHidden отсутствует")
    func decodeCustomExerciseResponseWithMissingIsHidden() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 1,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00"
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CustomExerciseResponse.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку когда isHidden приходит как null")
    func decodeCustomExerciseResponseWithNullIsHidden() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 1,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": null
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CustomExerciseResponse.self, from: json)
        }
    }

    // MARK: - Декодирование когда isHidden приходит как неожиданный тип

    @Test("Должен выбрасывать ошибку когда isHidden приходит как неожиданный тип")
    func decodeCustomExerciseResponseWithIsHiddenAsUnexpectedType() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": 1,
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": "true"
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CustomExerciseResponse.self, from: json)
        }
    }

    // MARK: - Декодирование когда imageId приходит как невалидная строка

    @Test("Должен использовать значение по умолчанию когда imageId приходит как невалидная строка")
    func decodeCustomExerciseResponseWithInvalidImageIdString() throws {
        let json = try #require("""
        {
            "id": "exercise-1",
            "name": "Подтягивания",
            "image_id": "invalid",
            "create_date": "2024-01-15T10:30:00",
            "modify_date": "2024-01-16T11:00:00",
            "is_hidden": false
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CustomExerciseResponse.self, from: json)

        #expect(response.imageId == 1)
    }
}
