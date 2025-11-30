struct City: Codable, Identifiable, Hashable {
    let id, name, lat, lon: String

    init(id: String, name: String, lat: String, lon: String) {
        self.id = id
        self.name = name
        self.lat = lat
        self.lon = lon
    }

    init(from response: CityResponse) {
        self.init(
            id: response.id,
            name: response.name,
            lat: response.lat ?? "",
            lon: response.lon ?? ""
        )
    }
}
