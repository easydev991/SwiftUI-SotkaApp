struct CountryResponse: Codable, Identifiable, Hashable, Sendable {
    let cities: [CityResponse]
    let id, name: String

    /// Россия
    static var defaultCountry: Self {
        .init(cities: [], id: "17", name: "Россия")
    }
}
