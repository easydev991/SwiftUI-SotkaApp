protocol CountriesClient: Sendable {
    /// Загружает справочник стран/городов
    /// - Returns: Справочник стран/городов
    func getCountries() async throws -> [CountryResponse]
}
