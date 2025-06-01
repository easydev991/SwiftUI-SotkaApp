import Foundation
import Observation
import OSLog
import SwiftData
import SWUtils

@MainActor
@Observable
final class CountriesUpdateService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CountriesUpdateService.self)
    )
    private let defaults = UserDefaults.standard

    /// Нужно ли обновлять справочник
    ///
    /// По статистике Антона справочник на сервере обновляется в среднем раз в месяц
    private var shouldUpdate: Bool {
        if let lastCountriesUpdateDate {
            DateFormatterService.days(from: lastCountriesUpdateDate, to: .now) > 30
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

    /// Обновляет справочник стран и городов при необходимости
    /// - Parameters:
    ///   - context: Контекст `Swift Data`
    ///   - client: Сервис для загрузки стран
    func update(_ context: ModelContext, client: CountryClient) async {
        guard !isLoading else { return }
        let countries = try? context.fetch(FetchDescriptor<Country>())
        let hasCountries = countries?.isEmpty == false
        guard !hasCountries || shouldUpdate else { return }
        isLoading = true
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
            lastCountriesUpdateDate = .now
            logger.info("Успешно синхронизировали страны и города")
        } catch {
            logger.error("Не удалось обновить страны и города, ошибка: \(error.localizedDescription)")
            let localizedTitle = NSLocalizedString("Error.CountriesUpdate", comment: "")
            SWAlert.shared.presentDefaultUIKit(
                error,
                title: localizedTitle
            )
        }
        isLoading = false
    }
}

private extension CountriesUpdateService {
    enum Key: String {
        case lastCountriesUpdateDate
    }
}
