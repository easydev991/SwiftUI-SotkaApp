import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты декодирования CountryResponse")
struct CountryResponseTests {
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    // MARK: - Декодирование с валидными данными

    @Test("Должен декодировать CountryResponse с валидными данными (все поля заполнены)")
    func decodeCountryResponseWithAllFields() throws {
        let json = try #require("""
        {
            "id": "17",
            "name": "Россия",
            "cities": [
                {
                    "id": "1",
                    "name": "Москва",
                    "lat": "55.753215",
                    "lon": "37.622504"
                }
            ]
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CountryResponse.self, from: json)

        #expect(response.id == "17")
        #expect(response.name == "Россия")
        #expect(response.cities.count == 1)
        let city = try #require(response.cities.first)
        #expect(city.id == "1")
        #expect(city.name == "Москва")
    }

    @Test("Должен декодировать CountryResponse с пустым массивом cities")
    func decodeCountryResponseWithEmptyCities() throws {
        let json = try #require("""
        {
            "id": "17",
            "name": "Россия",
            "cities": []
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CountryResponse.self, from: json)

        #expect(response.id == "17")
        #expect(response.name == "Россия")
        #expect(response.cities.isEmpty)
    }

    // MARK: - Декодирование когда обязательные поля отсутствуют

    @Test("Должен выбрасывать ошибку когда id отсутствует")
    func decodeCountryResponseWithMissingId() throws {
        let json = try #require("""
        {
            "name": "Россия",
            "cities": []
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CountryResponse.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку когда name отсутствует")
    func decodeCountryResponseWithMissingName() throws {
        let json = try #require("""
        {
            "id": "17",
            "cities": []
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CountryResponse.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку когда cities отсутствует")
    func decodeCountryResponseWithMissingCities() throws {
        let json = try #require("""
        {
            "id": "17",
            "name": "Россия"
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CountryResponse.self, from: json)
        }
    }

    // MARK: - Декодирование когда обязательные поля приходят как null

    @Test("Должен выбрасывать ошибку когда id приходит как null")
    func decodeCountryResponseWithNullId() throws {
        let json = try #require("""
        {
            "id": null,
            "name": "Россия",
            "cities": []
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CountryResponse.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку когда name приходит как null")
    func decodeCountryResponseWithNullName() throws {
        let json = try #require("""
        {
            "id": "17",
            "name": null,
            "cities": []
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CountryResponse.self, from: json)
        }
    }

    // MARK: - Декодирование с вложенными CityResponse

    @Test("Должен декодировать CountryResponse с вложенными CityResponse в массиве cities")
    func decodeCountryResponseWithNestedCityResponses() throws {
        let json = try #require("""
        {
            "id": "17",
            "name": "Россия",
            "cities": [
                {
                    "id": "1",
                    "name": "Москва",
                    "lat": "55.753215",
                    "lon": "37.622504"
                },
                {
                    "id": "2",
                    "name": "Санкт-Петербург",
                    "lat": "59.934280",
                    "lon": "30.335098"
                }
            ]
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CountryResponse.self, from: json)

        #expect(response.id == "17")
        #expect(response.name == "Россия")
        #expect(response.cities.count == 2)
        let firstCity = try #require(response.cities.first)
        #expect(firstCity.id == "1")
        #expect(firstCity.name == "Москва")
        let lastCity = try #require(response.cities.last)
        #expect(lastCity.id == "2")
        #expect(lastCity.name == "Санкт-Петербург")
    }
}
