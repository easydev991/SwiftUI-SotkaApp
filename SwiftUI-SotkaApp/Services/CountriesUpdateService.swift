import Foundation
import Observation
import OSLog
import SwiftData
import SWUtils

@MainActor
@Observable
final class CountriesUpdateService {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CountriesUpdateService.self)
    )
    @ObservationIgnored private let defaults: UserDefaults
    private let client: CountryClient

    /// Нужно ли обновлять справочник
    ///
    /// Обновляем, если прошло больше дня с момента предыдущего обновления
    private var shouldUpdate: Bool {
        if let lastCountriesUpdateDate {
            DateFormatterService.days(from: lastCountriesUpdateDate, to: .now) > 1
        } else {
            true
        }
    }

    /// Дата предыдущего обновления справочника
    private var lastCountriesUpdateDate: Date? {
        get {
            access(keyPath: \.lastCountriesUpdateDate)
            let storedTime = defaults.double(
                forKey: Key.lastCountriesUpdateDate.rawValue
            )
            return Date(timeIntervalSinceReferenceDate: storedTime)
        }
        set {
            withMutation(keyPath: \.lastCountriesUpdateDate) {
                if let newValue {
                    defaults.set(
                        newValue.timeIntervalSinceReferenceDate,
                        forKey: Key.lastCountriesUpdateDate.rawValue
                    )
                } else {
                    defaults.removeObject(forKey: Key.lastCountriesUpdateDate.rawValue)
                }
            }
        }
    }

    private(set) var isLoading = false
    private(set) var updateTask: Task<Void, Never>?

    init(defaults: UserDefaults = UserDefaults.standard, client: CountryClient) {
        self.defaults = defaults
        self.client = client
    }

    /// Обновляет справочник стран и городов при необходимости
    /// - Parameters:
    ///   - context: Контекст `Swift Data`
    func update(_ context: ModelContext) {
        guard !isLoading else { return }
        let countries = try? context.fetch(FetchDescriptor<Country>())
        let hasCountries = countries?.isEmpty == false
        guard !hasCountries || shouldUpdate else { return }
        isLoading = true
        updateTask?.cancel()
        updateTask = Task {
            do {
                let apiCountries = try await client.getCountries()
                if hasCountries {
                    // Удаляем все страны из памяти, чтобы синкануться с сервером
                    try context.delete(model: Country.self)
                }
                for apiCountry in apiCountries {
                    let country = Country(
                        id: apiCountry.id,
                        name: apiCountry.name,
                        cities: apiCountry.cities.map(City.init)
                    )
                    context.insert(country)
                }
                try context.save()
                lastCountriesUpdateDate = .now
                logger.info("Успешно синхронизировали страны и города")
            } catch is CancellationError {
                return
            } catch {
                logger.error("Не удалось обновить страны и города, ошибка: \(error.localizedDescription)")
                if lastCountriesUpdateDate == nil {
                    SWAlert.shared.presentDefaultUIKit(
                        error,
                        title: String(localized: .errorCountriesUpdate)
                    )
                }
            }
            isLoading = false
        }
    }
}

private extension CountriesUpdateService {
    enum Key: String {
        case lastCountriesUpdateDate
    }
}
