import Foundation

/// Модель для синхронизации даты старта
struct ConflictingStartDate: Identifiable {
    let id: String
    /// Калькулятор для даты старта в приложении
    let appDayCalculator: DayCalculator
    /// Калькулятор для даты старта на сайте
    let siteDayCalculator: DayCalculator

    init(_ appDate: Date, _ siteDate: Date) {
        let now = Date.now
        self.appDayCalculator = .init(appDate, now)
        self.siteDayCalculator = .init(siteDate, now)
        self.id = "\(appDayCalculator.id)-\(siteDayCalculator.id)"
    }
}
