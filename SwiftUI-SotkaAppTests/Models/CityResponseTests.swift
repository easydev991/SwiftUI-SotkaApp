import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты декодирования CityResponse")
struct CityResponseTests {
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    // MARK: - Декодирование с валидными данными

    @Test("Должен декодировать CityResponse с валидными данными (все поля заполнены)")
    func decodeCityResponseWithAllFields() throws {
        let json = try #require("""
        {
            "id": "1",
            "name": "Москва",
            "lat": "55.753215",
            "lon": "37.622504"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CityResponse.self, from: json)

        #expect(response.id == "1")
        #expect(response.name == "Москва")
        let lat = try #require(response.lat)
        #expect(lat == "55.753215")
        let lon = try #require(response.lon)
        #expect(lon == "37.622504")
    }

    // MARK: - Декодирование когда обязательные поля отсутствуют

    @Test("Должен выбрасывать ошибку когда id отсутствует")
    func decodeCityResponseWithMissingId() throws {
        let json = try #require("""
        {
            "name": "Москва",
            "lat": "55.753215",
            "lon": "37.622504"
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CityResponse.self, from: json)
        }
    }

    @Test("Должен выбрасывать ошибку когда name отсутствует")
    func decodeCityResponseWithMissingName() throws {
        let json = try #require("""
        {
            "id": "1",
            "lat": "55.753215",
            "lon": "37.622504"
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(CityResponse.self, from: json)
        }
    }

    // MARK: - Декодирование когда lat и lon отсутствуют или null

    @Test("Должен декодировать CityResponse когда lat отсутствует")
    func decodeCityResponseWithMissingLat() throws {
        let json = try #require("""
        {
            "id": "1",
            "name": "Москва",
            "lon": "37.622504"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CityResponse.self, from: json)

        #expect(response.id == "1")
        #expect(response.name == "Москва")
        #expect(response.lat == nil)
        let lon = try #require(response.lon)
        #expect(lon == "37.622504")
    }

    @Test("Должен декодировать CityResponse когда lon отсутствует")
    func decodeCityResponseWithMissingLon() throws {
        let json = try #require("""
        {
            "id": "1",
            "name": "Москва",
            "lat": "55.753215"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CityResponse.self, from: json)

        #expect(response.id == "1")
        #expect(response.name == "Москва")
        let lat = try #require(response.lat)
        #expect(lat == "55.753215")
        #expect(response.lon == nil)
    }

    @Test("Должен декодировать CityResponse когда lat приходит как null")
    func decodeCityResponseWithNullLat() throws {
        let json = try #require("""
        {
            "id": "1",
            "name": "Москва",
            "lat": null,
            "lon": "37.622504"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CityResponse.self, from: json)

        #expect(response.id == "1")
        #expect(response.name == "Москва")
        #expect(response.lat == nil)
        let lon = try #require(response.lon)
        #expect(lon == "37.622504")
    }

    @Test("Должен декодировать CityResponse когда lon приходит как null")
    func decodeCityResponseWithNullLon() throws {
        let json = try #require("""
        {
            "id": "1",
            "name": "Москва",
            "lat": "55.753215",
            "lon": null
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CityResponse.self, from: json)

        #expect(response.id == "1")
        #expect(response.name == "Москва")
        let lat = try #require(response.lat)
        #expect(lat == "55.753215")
        #expect(response.lon == nil)
    }

    // MARK: - Декодирование когда поля приходят как пустые строки

    @Test("Должен декодировать CityResponse когда поля приходят как пустые строки")
    func decodeCityResponseWithEmptyStrings() throws {
        let json = try #require("""
        {
            "id": "1",
            "name": "Москва",
            "lat": "",
            "lon": ""
        }
        """.data(using: .utf8))

        let response = try decoder.decode(CityResponse.self, from: json)

        #expect(response.id == "1")
        #expect(response.name == "Москва")
        let lat = try #require(response.lat)
        #expect(lat == "")
        let lon = try #require(response.lon)
        #expect(lon == "")
    }
}
