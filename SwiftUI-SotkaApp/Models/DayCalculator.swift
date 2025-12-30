import Foundation
import OSLog

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
    ///   - currentDate: Текущая дата, с которой нужно сравнить дату старта
    init?(_ startDate: Date?, _ currentDate: Date) {
        guard let startDate else {
            logger.error("Дата старта не настроена")
            return nil
        }
        self.init(startDate, currentDate)
    }

    /// Инициализатор обычный
    /// - Parameters:
    ///   - startDate: Дата старта сотки (на сайте или в приложении)
    ///   - currentDate: Текущая дата, с которой нужно сравнить дату старта
    init(_ startDate: Date, _ currentDate: Date) {
        self.startDate = startDate
        if startDate > currentDate {
            // Старт в будущем: программа ещё не началась
            self.currentDay = 1
            self.daysLeft = 99
        } else {
            let daysBetween = Self.daysBetween(startDate, and: currentDate)
            let currentDay = min(daysBetween + 1, 100)
            self.currentDay = currentDay
            self.daysLeft = 100 - currentDay
        }
    }

    /// Считает количество дней между двумя датами
    /// - Parameters:
    ///   - date1: Дата 1
    ///   - date2: Дата 2
    /// - Returns: Количество дней между датами
    private static func daysBetween(_ date1: Date, and date2: Date) -> Int {
        let calendar = Calendar(identifier: .iso8601)
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date1),
            to: calendar.startOfDay(for: date2)
        )
        return components.day ?? 0
    }
}
