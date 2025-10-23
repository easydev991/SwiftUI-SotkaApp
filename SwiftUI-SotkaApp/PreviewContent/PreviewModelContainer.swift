import SwiftData

enum PreviewModelContainer {
    @MainActor
    static func make(with user: User) -> ModelContainer {
        let schema = Schema([User.self, Country.self, CustomExercise.self, UserProgress.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        container.mainContext.insert(user)
        let russia = CountryResponse.defaultCountry
        let country = Country(id: russia.id, name: russia.name, cities: russia.cities.map(City.init))
        container.mainContext.insert(country)
        return container
    }
}
