struct CityResponse: Codable, Identifiable, Hashable, Sendable {
    let id, name: String
    let lat, lon: String?

    /// Москва
    static var defaultCity: Self {
        .init(id: "1", name: "Москва", lat: "55.753215", lon: "37.622504")
    }
}
