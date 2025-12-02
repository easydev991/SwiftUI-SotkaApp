import Foundation
import OSLog

/// Утилиты для чтения данных из App Group UserDefaults
struct WatchAppGroupHelper {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaWatch",
        category: String(describing: WatchAppGroupHelper.self)
    )

    private let appGroupDefaults: UserDefaults?

    /// Инициализатор с возможностью передачи UserDefaults для тестирования
    /// - Parameter userDefaults: UserDefaults для использования. Если `nil`, используется App Group UserDefaults
    init(userDefaults: UserDefaults? = nil) {
        if let userDefaults {
            self.appGroupDefaults = userDefaults
        } else {
            self.appGroupDefaults = UserDefaults(suiteName: Constants.appGroupIdentifier)
        }
    }

    /// Статус авторизации из App Group UserDefaults
    /// - Returns: `true` если пользователь авторизован, `false` в противном случае или если App Group недоступен
    var isAuthorized: Bool {
        guard let defaults = appGroupDefaults else {
            logger.warning("App Group '\(Constants.appGroupIdentifier)' недоступен, возвращаем false для статуса авторизации")
            return false
        }

        let isAuthorized = defaults.bool(forKey: Constants.isAuthorizedKey)
        logger.debug("Прочитан статус авторизации из App Group: \(isAuthorized)")
        return isAuthorized
    }

    /// Дата начала программы из App Group UserDefaults
    /// - Returns: Дата начала программы или `nil` если значение отсутствует или App Group недоступен
    var startDate: Date? {
        guard let defaults = appGroupDefaults else {
            logger.warning("App Group '\(Constants.appGroupIdentifier)' недоступен, возвращаем nil для startDate")
            return nil
        }

        let storedTime = defaults.double(forKey: Constants.startDateKey)
        guard storedTime != 0 else {
            logger.debug("startDate не установлен в App Group UserDefaults")
            return nil
        }

        let startDate = Date(timeIntervalSinceReferenceDate: storedTime)
        logger.debug("Прочитана дата начала программы из App Group: \(startDate)")
        return startDate
    }

    /// Текущий день программы, вычисленный из `startDate`
    /// - Returns: Номер текущего дня или `nil` если `startDate` отсутствует
    var currentDay: Int? {
        guard let startDate else {
            logger.debug("Не удалось вычислить текущий день: startDate отсутствует")
            return nil
        }

        let currentDate = Date.now
        let calculator = DayCalculator(startDate, currentDate)
        let currentDay = calculator.currentDay
        logger.debug("Вычислен текущий день программы: \(currentDay) (из startDate: \(startDate))")
        return currentDay
    }

    /// Время отдыха между подходами/кругами из App Group UserDefaults
    /// - Returns: Время отдыха в секундах или значение по умолчанию (`Constants.defaultRestTime`)
    var restTime: Int {
        guard let defaults = appGroupDefaults else {
            logger.warning("App Group '\(Constants.appGroupIdentifier)' недоступен, возвращаем значение по умолчанию для restTime")
            return Constants.defaultRestTime
        }

        let storedValue = defaults.integer(forKey: Constants.restTimeKey)
        if storedValue == 0 {
            logger.debug("restTime не установлен в App Group UserDefaults, возвращаем значение по умолчанию")
            return Constants.defaultRestTime
        }

        logger.debug("Прочитано время отдыха из App Group: \(storedValue) секунд")
        return storedValue
    }
}
