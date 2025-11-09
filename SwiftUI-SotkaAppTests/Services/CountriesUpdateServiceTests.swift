import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

@MainActor
struct CountriesUpdateServiceTests {
    private static let lastCountriesUpdateDateKey = "lastCountriesUpdateDate"

    private static func waitForTaskCompletion(_ service: CountriesUpdateService) async {
        if let task = service.updateTask {
            await task.value
        }
    }

    private static func setLastUpdateDate(_ defaults: UserDefaults, date: Date) {
        defaults.set(date.timeIntervalSinceReferenceDate, forKey: lastCountriesUpdateDateKey)
    }

    private static func getLastUpdateDate(_ defaults: UserDefaults) -> Date? {
        let storedTime = defaults.double(forKey: lastCountriesUpdateDateKey)
        guard storedTime > 0 else { return nil }
        return Date(timeIntervalSinceReferenceDate: storedTime)
    }

    @Test("Должен успешно обновить страны при отсутствии стран в БД")
    func updateWhenNoCountriesInDatabase() async throws {
        let testCountry1 = CountryResponse(
            cities: [
                CityResponse(id: "1", name: "Москва", lat: "55.753215", lon: "37.622504"),
                CityResponse(id: "2", name: "Санкт-Петербург", lat: "59.934280", lon: "30.335098")
            ],
            id: "1",
            name: "Россия"
        )
        let mockClient = MockCountryClient(mockedCountries: [testCountry1])
        let defaults = try MockUserDefaults.create()
        let service = CountriesUpdateService(defaults: defaults, client: mockClient)
        let container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        service.update(context)
        await Self.waitForTaskCompletion(service)

        let countries = try context.fetch(FetchDescriptor<Country>())
        #expect(countries.count == 1)
        let country = try #require(countries.first)
        #expect(country.id == "1")
        #expect(country.name == "Россия")
        #expect(country.cities.count == 2)
        #expect(country.cities[0].id == "1")
        #expect(country.cities[0].name == "Москва")
        #expect(!service.isLoading)
        let lastUpdateDate = Self.getLastUpdateDate(defaults)
        #expect(lastUpdateDate != nil)
    }

    @Test("Должен удалить старые страны и добавить новые при обновлении")
    func updateWhenCountriesExistInDatabase() async throws {
        let oldCountry1 = Country(id: "old1", name: "Старая страна 1")
        let oldCountry2 = Country(id: "old2", name: "Старая страна 2")
        let container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        context.insert(oldCountry1)
        context.insert(oldCountry2)
        try context.save()

        let initialCountries = try context.fetch(FetchDescriptor<Country>())
        #expect(initialCountries.count == 2)

        let newCountry = CountryResponse(
            cities: [CityResponse(id: "1", name: "Город", lat: "0", lon: "0")],
            id: "new",
            name: "Новая страна"
        )
        let mockClient = MockCountryClient(mockedCountries: [newCountry])
        let defaults = try MockUserDefaults.create()
        let service = CountriesUpdateService(defaults: defaults, client: mockClient)

        service.update(context)
        await Self.waitForTaskCompletion(service)

        let countries = try context.fetch(FetchDescriptor<Country>())
        #expect(countries.count == 1)
        let country = try #require(countries.first)
        #expect(country.id == "new")
        #expect(country.name == "Новая страна")
        #expect(countries.allSatisfy { $0.id != "old1" && $0.id != "old2" })
    }

    @Test("Не должен обновлять, если прошло меньше дня")
    func noUpdateWhenLessThanDayPassed() async throws {
        let mockClient = MockCountryClient()
        let defaults = try MockUserDefaults.create()
        let service = CountriesUpdateService(defaults: defaults, client: mockClient)
        Self.setLastUpdateDate(defaults, date: .now)

        let oldCountry = Country(id: "old", name: "Старая страна")
        let container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        context.insert(oldCountry)
        try context.save()

        service.update(context)
        await Self.waitForTaskCompletion(service)

        #expect(mockClient.getCountriesCallCount == 0)
        let countries = try context.fetch(FetchDescriptor<Country>())
        #expect(countries.count == 1)
        #expect(!service.isLoading)
    }

    @Test("Должен обновить, если прошло больше дня")
    func updateWhenMoreThanDayPassed() async throws {
        let testCountry = CountryResponse(
            cities: [],
            id: "1",
            name: "Новая страна"
        )
        let mockClient = MockCountryClient(mockedCountries: [testCountry])
        let defaults = try MockUserDefaults.create()
        let service = CountriesUpdateService(defaults: defaults, client: mockClient)
        let twoDaysAgo = Date().addingTimeInterval(-2 * 24 * 60 * 60)
        Self.setLastUpdateDate(defaults, date: twoDaysAgo)

        let oldCountry = Country(id: "old", name: "Старая страна")
        let container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        context.insert(oldCountry)
        try context.save()

        service.update(context)
        await Self.waitForTaskCompletion(service)

        #expect(mockClient.getCountriesCallCount == 1)
        let countries = try context.fetch(FetchDescriptor<Country>())
        #expect(countries.count == 1)
        let country = try #require(countries.first)
        #expect(country.id == "1")
        let lastUpdateDate = Self.getLastUpdateDate(defaults)
        #expect(lastUpdateDate != nil)
    }

    @Test("Не должен обновлять, если уже идет загрузка")
    func noUpdateWhenAlreadyLoading() async throws {
        let mockClient = MockCountryClient()
        mockClient.delay = 0.1
        let defaults = try MockUserDefaults.create()
        let service = CountriesUpdateService(defaults: defaults, client: mockClient)
        let container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        service.update(context)
        service.update(context)
        await Self.waitForTaskCompletion(service)

        #expect(mockClient.getCountriesCallCount == 1)
    }

    @Test("Должен обработать ошибку при первой загрузке")
    func errorHandlingOnFirstLoad() async throws {
        let mockClient = MockCountryClient()
        mockClient.shouldThrowError = true
        let defaults = try MockUserDefaults.create()
        let service = CountriesUpdateService(defaults: defaults, client: mockClient)
        let container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        service.update(context)
        await Self.waitForTaskCompletion(service)

        #expect(!service.isLoading)
        let lastUpdateDate = Self.getLastUpdateDate(defaults)
        #expect(lastUpdateDate == nil)
    }

    @Test("Должен обработать ошибку при повторной загрузке без изменения даты")
    func errorHandlingOnSubsequentLoad() async throws {
        let mockClient = MockCountryClient()
        mockClient.shouldThrowError = true
        let defaults = try MockUserDefaults.create()
        let service = CountriesUpdateService(defaults: defaults, client: mockClient)
        let pastDate = Date().addingTimeInterval(-3600)
        Self.setLastUpdateDate(defaults, date: pastDate)
        let container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        service.update(context)
        await Self.waitForTaskCompletion(service)

        #expect(!service.isLoading)
        let lastUpdateDate = Self.getLastUpdateDate(defaults)
        #expect(lastUpdateDate != nil)
        let storedTime = defaults.double(forKey: Self.lastCountriesUpdateDateKey)
        let expectedTime = pastDate.timeIntervalSinceReferenceDate
        #expect(abs(storedTime - expectedTime) < 1.0)
    }

    @Test("Должен отменить предыдущую задачу при повторном вызове")
    func taskCancellationOnSecondCall() async throws {
        let testCountry = CountryResponse(cities: [], id: "1", name: "Страна")
        let mockClient = MockCountryClient(mockedCountries: [testCountry])
        mockClient.delay = 0.2
        let defaults = try MockUserDefaults.create()
        let service = CountriesUpdateService(defaults: defaults, client: mockClient)
        let container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        service.update(context)
        #expect(service.isLoading)
        service.update(context)
        await Self.waitForTaskCompletion(service)

        let countries = try context.fetch(FetchDescriptor<Country>())
        #expect(countries.count == 1)
        #expect(mockClient.getCountriesCallCount == 1)
    }

    @Test("Должен правильно преобразовать данные из CountryResponse в Country")
    func dataTransformation() async throws {
        let testCountry = CountryResponse(
            cities: [
                CityResponse(id: "1", name: "Москва", lat: "55.753215", lon: "37.622504"),
                CityResponse(id: "2", name: "СПб", lat: "59.934280", lon: "30.335098")
            ],
            id: "1",
            name: "Россия"
        )
        let mockClient = MockCountryClient(mockedCountries: [testCountry])
        let defaults = try MockUserDefaults.create()
        let service = CountriesUpdateService(defaults: defaults, client: mockClient)
        let container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        service.update(context)
        await Self.waitForTaskCompletion(service)

        let countries = try context.fetch(FetchDescriptor<Country>())
        let country = try #require(countries.first)
        #expect(country.id == "1")
        #expect(country.name == "Россия")
        #expect(country.cities.count == 2)
        let city1 = country.cities[0]
        #expect(city1.id == "1")
        #expect(city1.name == "Москва")
        #expect(city1.lat == "55.753215")
        #expect(city1.lon == "37.622504")
        let city2 = country.cities[1]
        #expect(city2.id == "2")
        #expect(city2.name == "СПб")
    }

    @Test("Должен обновить при отсутствии даты последнего обновления")
    func updateWhenNoLastUpdateDate() async throws {
        let testCountry = CountryResponse(cities: [], id: "1", name: "Страна")
        let mockClient = MockCountryClient(mockedCountries: [testCountry])
        let defaults = try MockUserDefaults.create()
        let service = CountriesUpdateService(defaults: defaults, client: mockClient)

        let oldCountry = Country(id: "old", name: "Старая страна")
        let container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        context.insert(oldCountry)
        try context.save()

        service.update(context)
        await Self.waitForTaskCompletion(service)

        #expect(mockClient.getCountriesCallCount == 1)
        let countries = try context.fetch(FetchDescriptor<Country>())
        #expect(countries.count == 1)
        let country = try #require(countries.first)
        #expect(country.id == "1")
        let lastUpdateDate = Self.getLastUpdateDate(defaults)
        #expect(lastUpdateDate != nil)
    }

    @Test("Должен очистить БД при пустом списке стран с сервера")
    func updateWithEmptyCountriesList() async throws {
        let mockClient = MockCountryClient(mockedCountries: [])
        let defaults = try MockUserDefaults.create()
        let service = CountriesUpdateService(defaults: defaults, client: mockClient)

        let oldCountry = Country(id: "old", name: "Старая страна")
        let container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        context.insert(oldCountry)
        try context.save()

        service.update(context)
        await Self.waitForTaskCompletion(service)

        let countries = try context.fetch(FetchDescriptor<Country>())
        #expect(countries.isEmpty)
        let lastUpdateDate = Self.getLastUpdateDate(defaults)
        #expect(lastUpdateDate != nil)
    }

    @Test("Должен сохранить дату обновления после успешного обновления")
    func lastUpdateDateSaving() async throws {
        let testCountry = CountryResponse(cities: [], id: "1", name: "Страна")
        let mockClient = MockCountryClient(mockedCountries: [testCountry])
        let defaults = try MockUserDefaults.create()
        let service = CountriesUpdateService(defaults: defaults, client: mockClient)
        let container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let beforeTime = Date()
        service.update(context)
        await Self.waitForTaskCompletion(service)
        let afterTime = Date()

        let lastUpdateDate = try #require(Self.getLastUpdateDate(defaults))
        #expect(lastUpdateDate >= beforeTime)
        #expect(lastUpdateDate <= afterTime)
    }
}
