protocol CountryClient: Sendable {
    /// Загружает справочник стран/городов
    /// - Returns: Справочник стран/городов
    func getCountries() async throws -> [CountryResponse]
}
