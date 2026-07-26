import Foundation
import SwiftData

@Model
final class Country {
    @Attribute(.unique) var id: String
    var name: String
    var cities: [City]

    init(id: String = UUID().uuidString, name: String = "", cities: [City] = []) {
        self.id = id
        self.name = name
        self.cities = cities
    }

    static func makeDefaultCountry() -> Country {
        let country = Country(id: "ru", name: "Россия")
        country.cities = [
            City(id: "msk", name: "Москва", lat: "55.7558", lon: "37.6173"),
            City(id: "spb", name: "Санкт-Петербург", lat: "59.9343", lon: "30.3351")
        ]
        return country
    }
}
