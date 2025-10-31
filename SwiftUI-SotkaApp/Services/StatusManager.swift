import Foundation
import Observation
import OSLog
import SwiftData
import SWUtils

@MainActor
@Observable
final class StatusManager {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: StatusManager.self)
    )
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored let customExercisesService: CustomExercisesService
    @ObservationIgnored let infopostsService: InfopostsService
    @ObservationIgnored let progressSyncService: ProgressSyncService
    @ObservationIgnored let dailyActivitiesService: DailyActivitiesService
    @ObservationIgnored private var isJournalSyncInProgress = false

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

    private(set) var state = State.idle

    /// Признак успешной первичной загрузки данных
    private var didLoadInitialData: Bool {
        get { defaults.bool(forKey: Key.didLoadInitialData.rawValue) }
        set {
            guard newValue != didLoadInitialData else { return }
            defaults.set(newValue, forKey: Key.didLoadInitialData.rawValue)
        }
    }

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
        infopostsService: InfopostsService,
        progressSyncService: ProgressSyncService,
        dailyActivitiesService: DailyActivitiesService
    ) {
        self.customExercisesService = customExercisesService
        self.infopostsService = infopostsService
        self.progressSyncService = progressSyncService
        self.dailyActivitiesService = dailyActivitiesService
    }

    /// Получает статус прохождения пользователя
    /// - Parameters:
    ///   - client: Сервис для загрузки статуса
    func getStatus(client: StatusClient, context: ModelContext) async {
        let now = Date.now
        currentDayCalculator = .init(startDate, now)
        guard !state.isLoading else { return }
        state = .init(didLoadInitialData: didLoadInitialData)
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
                await syncWithSiteDate(siteDate: date, context: context)
            case let (.some(appDate), .some(siteDate)):
                logger.info("Дата старта в приложении: \(appDate.description), и на сайте: \(siteDate.description)")
                if appDate.isTheSameDayIgnoringTime(siteDate) {
                    await syncJournalAndProgress(context: context)
                } else {
                    conflictingSyncModel = .init(appDate, siteDate)
                }
            }
            currentDayCalculator = .init(startDate, now)
            didLoadInitialData = true
            state = .idle
        } catch {
            logger.error("\(error.localizedDescription)")
            if !didLoadInitialData {
                state = .error(error.localizedDescription)
                SWAlert.shared.presentDefaultUIKit(error)
            }
        }
    }

    func start(client: StatusClient, appDate: Date?, context: ModelContext) async {
        state = .init(didLoadInitialData: didLoadInitialData)
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

    func syncWithSiteDate(siteDate: Date, context: ModelContext) async {
        startDate = siteDate
        await syncJournalAndProgress(context: context)
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
            Task {
                try await infopostsService.syncReadPosts(context: context)
            }
        } catch {
            logger.error("Не удалось загрузить инфопосты: \(error.localizedDescription)")
        }
    }

    func didLogout() {
        startDate = nil
        currentDayCalculator = nil
        maxReadInfoPostDay = 0
        infopostsService.didLogout()
    }
}

extension StatusManager {
    enum State {
        case idle
        case isLoadingInitialData
        case isSynchronizingData
        case error(String)

        var isLoading: Bool {
            isLoadingInitialData || isSyncing
        }

        var isLoadingInitialData: Bool {
            if case .isLoadingInitialData = self { true } else { false }
        }

        var isSyncing: Bool {
            if case .isSynchronizingData = self { true } else { false }
        }

        init(didLoadInitialData: Bool) {
            self = didLoadInitialData ? .isSynchronizingData : .isLoadingInitialData
        }
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
        /// Признак успешной первичной загрузки данных
        case didLoadInitialData = "DidLoadInitialData"
    }
}

private extension StatusManager {
    func syncJournalAndProgress(context: ModelContext) async {
        guard !isJournalSyncInProgress else { return }
        isJournalSyncInProgress = true
        defer { isJournalSyncInProgress = false }
        state = .init(didLoadInitialData: didLoadInitialData)
        await progressSyncService.syncProgress(context: context)
        await customExercisesService.syncCustomExercises(context: context)
        await dailyActivitiesService.syncDailyActivities(context: context)
        conflictingSyncModel = nil
        state = .idle
    }
}
