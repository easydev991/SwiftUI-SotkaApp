import Foundation
import Observation
import OSLog
import SwiftData
import SWUtils

@MainActor
@Observable
final class StatusManager {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: StatusManager.self)
    )
    private let defaults = UserDefaults.standard
    @ObservationIgnored let customExercisesService: CustomExercisesService
    @ObservationIgnored let infopostsService: InfopostsService
    private var isJournalSyncInProgress = false

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

    /// Максимальный день, до которого доступны инфопосты
    private(set) var maxReadInfoPostDay: Int {
        get {
            access(keyPath: \.maxReadInfoPostDay)
            return defaults.integer(forKey: Key.maxReadInfoPostDay.rawValue)
        }
        set {
            withMutation(keyPath: \.maxReadInfoPostDay) {
                defaults.set(newValue, forKey: Key.maxReadInfoPostDay.rawValue)
            }
        }
    }

    init(
        customExercisesService: CustomExercisesService,
        infopostsService: InfopostsService
    ) {
        self.customExercisesService = customExercisesService
        self.infopostsService = infopostsService
    }

    /// Получает статус прохождения пользователя
    /// - Parameters:
    ///   - client: Сервис для загрузки статуса
    func getStatus(client: StatusClient, context: ModelContext) async {
        guard !isLoading else { return }
        isLoading = true
        do {
            let currentRun = try await client.current()
            let siteStartDate = currentRun.date
            maxReadInfoPostDay = currentRun.maxForAllRunsDay ?? 0
            switch (startDate, siteStartDate) {
            case (.none, .none):
                logger.info("Сотку еще не стартовали")
                await start(client: client, appDate: nil, context: context)
            case let (.some(date), .none):
                // Приложение - источник истины
                logger.info("Дата старта есть только в приложении: \(date.description)")
                await start(client: client, appDate: date, context: context)
            case let (.none, .some(date)):
                // Сайт - источник истины
                logger.info("Дата старта есть только на сайте: \(date.description)")
                await syncWithSiteDate(client: client, siteDate: date, context: context)
            case let (.some(appDate), .some(siteDate)):
                logger.info("Дата старта в приложении: \(appDate.description), и на сайте: \(siteDate.description)")
                if appDate.isTheSameDayIgnoringTime(siteDate) {
                    await syncJournalAndProgress(context: context)
                } else {
                    conflictingSyncModel = .init(appDate, siteDate)
                }
            }
            currentDayCalculator = .init(startDate, .now)
        } catch {
            logger.error("\(error.localizedDescription)")
        }
        // Загружаем инфопосты с учетом пола пользователя
        loadInfopostsWithUserGender(context: context)
        isLoading = false
    }

    func start(client: StatusClient, appDate: Date?, context: ModelContext) async {
        isLoading = true
        let newStartDate = appDate ?? .now
        let isoDateString = DateFormatterService.stringFromFullDate(newStartDate, iso: true)
        let currentRun = try? await client.start(date: isoDateString)
        startDate = if let siteStartDate = currentRun?.date {
            siteStartDate
        } else {
            newStartDate
        }
        await syncJournalAndProgress(context: context)
    }

    func syncWithSiteDate(client _: StatusClient, siteDate: Date, context: ModelContext) async {
        startDate = siteDate
        await syncJournalAndProgress(context: context)
    }

    func didLogout() {
        startDate = nil
        currentDayCalculator = nil
        maxReadInfoPostDay = 0
        infopostsService.didLogout()
    }
}

private extension StatusManager {
    enum Key: String {
        /// Дата начала сотки
        ///
        /// Значение взял из старого приложения
        case startDate = "WorkoutStartDate"
        /// Максимальный день, до которого доступны инфопосты
        ///
        /// Значение взял из старого приложения
        case maxReadInfoPostDay = "WorkoutMaxReadInfoPostDay"
    }

    func loadInfopostsWithUserGender(context: ModelContext) {
        do {
            let user = try context.fetch(FetchDescriptor<User>()).first
            try infopostsService.loadAvailableInfoposts(
                currentDay: currentDayCalculator?.currentDay,
                maxReadInfoPostDay: maxReadInfoPostDay,
                userGender: user?.gender,
                force: true
            )
        } catch {
            logger.error("Не удалось загрузить инфопосты: \(error.localizedDescription)")
        }
    }
}

private extension StatusManager {
    func syncJournalAndProgress(context: ModelContext) async {
        guard !isJournalSyncInProgress else { return }
        isJournalSyncInProgress = true
        defer { isJournalSyncInProgress = false }

        currentDayCalculator = .init(startDate, .now)
        isLoading = true
        logger.debug("Запускаем синхронизацию упражнений после авторизации")
        await customExercisesService.syncCustomExercises(context: context)
        logger.info("Синхронизация упражнений завершена")
        conflictingSyncModel = nil
        isLoading = false
    }
}
