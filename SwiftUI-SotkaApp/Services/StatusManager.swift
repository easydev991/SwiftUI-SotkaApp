import Foundation
import Observation
import OSLog
import SWUtils

@MainActor
@Observable
final class StatusManager {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: StatusManager.self)
    )
    private let defaults = UserDefaults.standard

    /// Дата старта сотки
    private var startDate: Date? {
        get {
            access(keyPath: \.startDate)
            let storedTime = defaults.double(
                forKey: Key.startDate.rawValue
            )
            guard storedTime != 0 else {
                logger.debug("Обратились к startDate, но он не был установлен")
                return nil
            }
            return Date(timeIntervalSinceReferenceDate: storedTime)
        }
        set {
            withMutation(keyPath: \.startDate) {
                if let newValue {
                    defaults.set(
                        newValue.timeIntervalSinceReferenceDate,
                        forKey: Key.startDate.rawValue
                    )
                } else {
                    defaults.removeObject(forKey: Key.startDate.rawValue)
                }
            }
        }
    }

    /// Калькулятор текущего дня сотки
    private(set) var currentDayCalculator: DayCalculator?
    /// Конфликтующие даты начала программы
    var conflictingSyncModel: ConflictingStartDate?

    private(set) var isLoading = false

    /// Получает статус прохождения пользователя
    /// - Parameters:
    ///   - client: Сервис для загрузки статуса
    func getStatus(client: StatusClient) async {
        guard !isLoading else { return }
        isLoading = true
        do {
            let currentRun = try await client.current()
            let siteStartDate = currentRun.date
            switch (startDate, siteStartDate) {
            case (.none, .none):
                logger.info("Сотку еще не стартовали")
                await start(client: client, appDate: nil)
            case let (.some(date), .none):
                // Приложение - источник истины
                logger.info("Дата старта есть только в приложении: \(date.description)")
                await start(client: client, appDate: date)
            case let (.none, .some(date)):
                // Сайт - источник истины
                logger.info("Дата старта есть только на сайте: \(date.description)")
                await syncWithSiteDate(client: client, siteDate: date)
            case let (.some(appDate), .some(siteDate)):
                logger.info("Дата старта в приложении: \(appDate.description), и на сайте: \(siteDate.description)")
                if appDate.isTheSameDayIgnoringTime(siteDate) {
                    await syncJournalAndProgress()
                } else {
                    conflictingSyncModel = .init(appDate, siteDate)
                }
            }
            currentDayCalculator = .init(startDate, .now)
        } catch {
            logger.error("\(error.localizedDescription)")
        }
        isLoading = false
    }

    func start(client: StatusClient, appDate: Date?) async {
        isLoading = true
        let newStartDate = appDate ?? .now
        let isoDateString = DateFormatterService.stringFromFullDate(newStartDate, iso: true)
        let currentRun = try? await client.start(date: isoDateString)
        startDate = if let siteStartDate = currentRun?.date {
            siteStartDate
        } else {
            newStartDate
        }
        await syncJournalAndProgress()
    }

    func syncWithSiteDate(client _: StatusClient, siteDate: Date) async {
        startDate = siteDate
        await syncJournalAndProgress()
    }

    func didLogout() {
        startDate = nil
        currentDayCalculator = nil
    }
}

private extension StatusManager {
    enum Key: String {
        /// Дата начала сотки
        ///
        /// Значение взял из старого приложения
        case startDate = "WorkoutStartDate"
    }
}

private extension StatusManager {
    func syncJournalAndProgress() async {
        currentDayCalculator = .init(startDate, .now)
        isLoading = true
        logger.error("Реализовать синхронизацию дневника и прогресса")
        conflictingSyncModel = nil
        isLoading = false
    }
}
