import Foundation
import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: DayCalculator.self)
)

struct DayCalculator: Identifiable, Equatable {
    static let baseProgramDays = 100
    static let extensionBlockDays = 100
    static let maxExtensionCount = 100

    var id: String {
        "\(currentDay)-\(daysLeft)"
    }

    /// Дата начала прохождения программы
    let startDate: Date
    /// Количество продлений календаря
    let extensionCount: Int
    /// Номер текущего дня
    let currentDay: Int
    /// Количество дней, оставшихся для завершения программы
    let daysLeft: Int

    /// Количество продлений с учётом верхнего лимита
    var normalizedExtensionCount: Int {
        min(max(extensionCount, 0), Self.maxExtensionCount)
    }

    /// Общее количество дней с учётом продлений
    var totalDays: Int {
        Self.baseProgramDays + normalizedExtensionCount * Self.extensionBlockDays
    }

    /// `true` - нужно показать кнопку продления календаря, `false` - скрыть
    var shouldShowExtensionButton: Bool {
        currentDay > 0 &&
            currentDay % Self.extensionBlockDays == 0 &&
            normalizedExtensionCount < currentDay / Self.extensionBlockDays &&
            normalizedExtensionCount < Self.maxExtensionCount
    }

    /// Целевое значение totalDays после следующего продления.
    var nextExtensionTotalDays: Int {
        let nextCount = min(normalizedExtensionCount + 1, Self.maxExtensionCount)
        return Self.baseProgramDays + nextCount * Self.extensionBlockDays
    }

    /// `true` - программа завершена, `false` - программа не завершена
    var isOver: Bool {
        currentDay >= totalDays
    }

    /// `true` - показать инфопосты, `false` - скрыть
    var shouldShowInfopost: Bool {
        currentDay <= Self.baseProgramDays
    }

    /// Инициализатор опциональный
    /// - Parameters:
    ///   - startDate: Дата старта сотки (на сайте или в приложении)
    ///   - currentDate: Текущая дата, с которой нужно сравнить дату старта
    init?(_ startDate: Date?, _ currentDate: Date, extensionCount: Int = 0) {
        guard let startDate else {
            logger.error("Дата старта не настроена")
            return nil
        }
        self.init(startDate, currentDate, extensionCount: extensionCount)
    }

    /// Инициализатор обычный
    /// - Parameters:
    ///   - startDate: Дата старта сотки (на сайте или в приложении)
    ///   - currentDate: Текущая дата, с которой нужно сравнить дату старта
    init(_ startDate: Date, _ currentDate: Date, extensionCount: Int = 0) {
        self.startDate = startDate
        self.extensionCount = extensionCount
        let normalizedExtensionCount = min(max(extensionCount, 0), Self.maxExtensionCount)
        let totalDays = Self.baseProgramDays + normalizedExtensionCount * Self.extensionBlockDays
        if startDate > currentDate {
            // Старт в будущем: программа ещё не началась
            self.currentDay = 1
            self.daysLeft = totalDays - 1
        } else {
            let daysBetween = Self.daysBetween(startDate, and: currentDate)
            let currentDay = min(daysBetween + 1, totalDays)
            self.currentDay = currentDay
            self.daysLeft = totalDays - currentDay
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
