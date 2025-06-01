import Foundation
import OSLog
import SWUtils

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: DayCalculator.self)
)

struct DayCalculator: Identifiable, Equatable {
    var id: String { "\(currentDay)-\(daysLeft)" }
    /// Дата начала прохождения программы
    let startDate: Date
    /// Номер текущего дня
    let currentDay: Int
    /// Количество дней, оставшихся для завершения программы
    let daysLeft: Int

    /// `true` - программа завершена, `false` - программа не завершена
    var isOver: Bool { currentDay == 100 }

    /// Инициализатор опциональный
    /// - Parameters:
    ///   - startDate: Дата старта сотки (на сайте или в приложении)
    ///   - endDate: Текущая дата, с которой нужно сравнить дату старта
    init?(_ startDate: Date?, _ endDate: Date) {
        guard let startDate else {
            let message = "Дата старта не настроена"
            logger.error("\(message)")
            return nil
        }
        self.init(startDate, endDate)
    }

    /// Инициализатор обычный
    /// - Parameters:
    ///   - startDate: Дата старта сотки (на сайте или в приложении)
    ///   - endDate: Текущая дата, с которой нужно сравнить дату старта
    init(_ startDate: Date, _ endDate: Date) {
        self.startDate = startDate
        if startDate > endDate {
            // Старт в будущем: программа ещё не началась
            self.currentDay = 1
            self.daysLeft = 99
        } else {
            let daysBetween = DateFormatterService.days(from: startDate, to: endDate)
            let currentDay = min(daysBetween + 1, 100)
            self.currentDay = currentDay
            self.daysLeft = 100 - currentDay
        }
    }
}
