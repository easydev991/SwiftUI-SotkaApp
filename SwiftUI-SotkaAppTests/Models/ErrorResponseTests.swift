import Foundation
@testable import SwiftUI_SotkaApp
@testable import SWNetwork
import Testing

@Suite("Тесты декодирования ErrorResponse")
struct ErrorResponseTests {
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    // MARK: - Декодирование с валидными данными

    @Test("Должен декодировать ErrorResponse с валидными данными (все поля заполнены)")
    func decodeErrorResponseWithAllFields() throws {
        let json = try #require("""
        {
            "errors": ["Ошибка 1", "Ошибка 2"],
            "name": "ValidationError",
            "message": "Ошибка валидации",
            "code": 400,
            "status": 400
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ErrorResponse.self, from: json)

        #expect(response.errors.count == 2)
        #expect(response.errors[0] == "Ошибка 1")
        #expect(response.errors[1] == "Ошибка 2")
        let name = try #require(response.name)
        #expect(name == "ValidationError")
        let message = try #require(response.message)
        #expect(message == "Ошибка валидации")
        #expect(response.code == 400)
        #expect(response.status == 400)
    }

    // MARK: - Декодирование когда errors отсутствует или null

    @Test("Должен декодировать ErrorResponse когда errors отсутствует (должен быть пустой массив)")
    func decodeErrorResponseWithMissingErrors() throws {
        let json = try #require("""
        {
            "name": "ValidationError",
            "message": "Ошибка валидации",
            "code": 400,
            "status": 400
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ErrorResponse.self, from: json)

        #expect(response.errors.isEmpty)
        let name = try #require(response.name)
        #expect(name == "ValidationError")
        let message = try #require(response.message)
        #expect(message == "Ошибка валидации")
        #expect(response.code == 400)
        #expect(response.status == 400)
    }

    @Test("Должен декодировать ErrorResponse когда errors приходит как null (должен быть пустой массив)")
    func decodeErrorResponseWithNullErrors() throws {
        let json = try #require("""
        {
            "errors": null,
            "name": "ValidationError",
            "message": "Ошибка валидации",
            "code": 400,
            "status": 400
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ErrorResponse.self, from: json)

        #expect(response.errors.isEmpty)
        let name = try #require(response.name)
        #expect(name == "ValidationError")
        let message = try #require(response.message)
        #expect(message == "Ошибка валидации")
        #expect(response.code == 400)
        #expect(response.status == 400)
    }

    @Test("Должен декодировать ErrorResponse когда errors приходит как пустой массив")
    func decodeErrorResponseWithEmptyErrors() throws {
        let json = try #require("""
        {
            "errors": [],
            "name": "ValidationError",
            "message": "Ошибка валидации",
            "code": 400,
            "status": 400
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ErrorResponse.self, from: json)

        #expect(response.errors.isEmpty)
        let name = try #require(response.name)
        #expect(name == "ValidationError")
        let message = try #require(response.message)
        #expect(message == "Ошибка валидации")
        #expect(response.code == 400)
        #expect(response.status == 400)
    }

    // MARK: - Декодирование когда опциональные поля отсутствуют или null

    @Test("Должен декодировать ErrorResponse когда опциональные поля (name, message) отсутствуют")
    func decodeErrorResponseWithMissingOptionalFields() throws {
        let json = try #require("""
        {
            "errors": ["Ошибка 1"],
            "code": 400,
            "status": 400
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ErrorResponse.self, from: json)

        #expect(response.errors.count == 1)
        #expect(response.errors[0] == "Ошибка 1")
        #expect(response.name == nil)
        #expect(response.message == nil)
        #expect(response.code == 400)
        #expect(response.status == 400)
    }

    @Test("Должен декодировать ErrorResponse когда опциональные поля приходят как null")
    func decodeErrorResponseWithNullOptionalFields() throws {
        let json = try #require("""
        {
            "errors": ["Ошибка 1"],
            "name": null,
            "message": null,
            "code": 400,
            "status": 400
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ErrorResponse.self, from: json)

        #expect(response.errors.count == 1)
        #expect(response.errors[0] == "Ошибка 1")
        #expect(response.name == nil)
        #expect(response.message == nil)
        #expect(response.code == 400)
        #expect(response.status == 400)
    }

    // MARK: - Декодирование когда code отсутствует или null

    @Test("Должен декодировать ErrorResponse когда code отсутствует (должен быть 0)")
    func decodeErrorResponseWithMissingCode() throws {
        let json = try #require("""
        {
            "errors": ["Ошибка 1"],
            "name": "ValidationError",
            "message": "Ошибка валидации",
            "status": 400
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ErrorResponse.self, from: json)

        #expect(response.errors.count == 1)
        #expect(response.errors[0] == "Ошибка 1")
        let name = try #require(response.name)
        #expect(name == "ValidationError")
        let message = try #require(response.message)
        #expect(message == "Ошибка валидации")
        #expect(response.code == 0)
        #expect(response.status == 400)
    }

    @Test("Должен декодировать ErrorResponse когда code приходит как null (должен быть 0)")
    func decodeErrorResponseWithNullCode() throws {
        let json = try #require("""
        {
            "errors": ["Ошибка 1"],
            "name": "ValidationError",
            "message": "Ошибка валидации",
            "code": null,
            "status": 400
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ErrorResponse.self, from: json)

        #expect(response.errors.count == 1)
        #expect(response.errors[0] == "Ошибка 1")
        let name = try #require(response.name)
        #expect(name == "ValidationError")
        let message = try #require(response.message)
        #expect(message == "Ошибка валидации")
        #expect(response.code == 0)
        #expect(response.status == 400)
    }

    @Test("Должен декодировать ErrorResponse когда code приходит как неожиданный тип (например, строка) - должен быть 0")
    func decodeErrorResponseWithUnexpectedTypeForCode() throws {
        let json = try #require("""
        {
            "errors": ["Ошибка 1"],
            "name": "ValidationError",
            "message": "Ошибка валидации",
            "code": "400",
            "status": 400
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ErrorResponse.self, from: json)

        #expect(response.errors.count == 1)
        #expect(response.errors[0] == "Ошибка 1")
        let name = try #require(response.name)
        #expect(name == "ValidationError")
        let message = try #require(response.message)
        #expect(message == "Ошибка валидации")
        #expect(response.code == 0)
        #expect(response.status == 400)
    }

    // MARK: - Декодирование когда status отсутствует или null

    @Test("Должен декодировать ErrorResponse когда status отсутствует (должен быть 0)")
    func decodeErrorResponseWithMissingStatus() throws {
        let json = try #require("""
        {
            "errors": ["Ошибка 1"],
            "name": "ValidationError",
            "message": "Ошибка валидации",
            "code": 400
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ErrorResponse.self, from: json)

        #expect(response.errors.count == 1)
        #expect(response.errors[0] == "Ошибка 1")
        let name = try #require(response.name)
        #expect(name == "ValidationError")
        let message = try #require(response.message)
        #expect(message == "Ошибка валидации")
        #expect(response.code == 400)
        #expect(response.status == 0)
    }

    @Test("Должен декодировать ErrorResponse когда status приходит как null (должен быть 0)")
    func decodeErrorResponseWithNullStatus() throws {
        let json = try #require("""
        {
            "errors": ["Ошибка 1"],
            "name": "ValidationError",
            "message": "Ошибка валидации",
            "code": 400,
            "status": null
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ErrorResponse.self, from: json)

        #expect(response.errors.count == 1)
        #expect(response.errors[0] == "Ошибка 1")
        let name = try #require(response.name)
        #expect(name == "ValidationError")
        let message = try #require(response.message)
        #expect(message == "Ошибка валидации")
        #expect(response.code == 400)
        #expect(response.status == 0)
    }

    @Test("Должен декодировать ErrorResponse когда status приходит как неожиданный тип (например, строка) - должен быть 0")
    func decodeErrorResponseWithUnexpectedTypeForStatus() throws {
        let json = try #require("""
        {
            "errors": ["Ошибка 1"],
            "name": "ValidationError",
            "message": "Ошибка валидации",
            "code": 400,
            "status": "400"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(ErrorResponse.self, from: json)

        #expect(response.errors.count == 1)
        #expect(response.errors[0] == "Ошибка 1")
        let name = try #require(response.name)
        #expect(name == "ValidationError")
        let message = try #require(response.message)
        #expect(message == "Ошибка валидации")
        #expect(response.code == 400)
        #expect(response.status == 0)
    }
}
