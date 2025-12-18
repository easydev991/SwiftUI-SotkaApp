import Foundation
import Observation
import OSLog
import SwiftData
import SWUtils
import WatchConnectivity

@MainActor
@Observable
final class StatusManager {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: StatusManager.self)
    )
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored let customExercisesService: CustomExercisesService
    @ObservationIgnored let infopostsService: InfopostsService
    @ObservationIgnored let progressSyncService: ProgressSyncService
    @ObservationIgnored let dailyActivitiesService: DailyActivitiesService
    @ObservationIgnored private var isJournalSyncInProgress = false
    @ObservationIgnored private(set) var syncReadPostsTask: Task<Void, Error>?
    @ObservationIgnored var watchConnectivityManager: WatchConnectivityManager!
    private let statusClient: StatusClient

    /// Дата старта сотки
    private var startDate: Date? {
        get {
            access(keyPath: \.startDate)
            let storedTime = defaults.double(
                forKey: Constants.startDateKey
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
                        forKey: Constants.startDateKey
                    )
                } else {
                    defaults.removeObject(forKey: Constants.startDateKey)
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
        dailyActivitiesService: DailyActivitiesService,
        statusClient: StatusClient,
        userDefaults: UserDefaults? = nil,
        watchConnectivitySessionProtocol: WCSessionProtocol? = nil
    ) {
        self.customExercisesService = customExercisesService
        self.infopostsService = infopostsService
        self.progressSyncService = progressSyncService
        self.dailyActivitiesService = dailyActivitiesService
        self.statusClient = statusClient
        if let userDefaults {
            self.defaults = userDefaults
        } else {
            self.defaults = UserDefaults.standard
        }
        // Инициализируем watchConnectivityManager после всех свойств
        // Используем unowned reference для избежания циклической ссылки
        unowned let tempStatusManager = self
        self.watchConnectivityManager = WatchConnectivityManager(
            statusManager: tempStatusManager,
            sessionProtocol: watchConnectivitySessionProtocol
        )
    }

    /// Получает статус прохождения пользователя
    /// - Parameters:
    ///   - client: Сервис для загрузки статуса
    func getStatus(context: ModelContext) async {
        let now = Date.now
        currentDayCalculator = .init(startDate, now)
        guard !state.isLoading else { return }
        state = .init(didLoadInitialData: didLoadInitialData)
        do {
            let currentRun = try await statusClient.current()
            let siteStartDate = currentRun.date
            maxReadInfoPostDay = currentRun.maxForAllRunsDay ?? 0
            switch (startDate, siteStartDate) {
            case (.none, .none):
                logger.info("Сотку еще не стартовали")
                await start(appDate: nil, context: context)
            case let (.some(date), .none):
                // Приложение - источник истины
                logger.info("Дата старта есть только в приложении: \(date.description)")
                await start(appDate: date, context: context)
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

            // Отправка данных на часы при обновлении статуса
            sendDayDataToWatch(currentDay: currentDayCalculator?.currentDay, context: context)

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

    func startNewRun(appDate: Date?) async {
        let newStartDate = appDate ?? .now
        let isoDateString = DateFormatterService.stringFromFullDate(newStartDate, iso: true)
        let currentRun = try? await statusClient.start(date: isoDateString)
        startDate = if let siteStartDate = currentRun?.date {
            siteStartDate
        } else {
            newStartDate
        }
        let now = Date.now
        currentDayCalculator = .init(startDate, now)
    }

    func start(appDate: Date?, context: ModelContext) async {
        await startNewRun(appDate: appDate)
        await syncJournalAndProgress(context: context)
    }

    func syncWithSiteDate(siteDate: Date, context: ModelContext) async {
        startDate = siteDate
        let now = Date.now
        currentDayCalculator = .init(startDate, now)
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
            syncReadPostsTask?.cancel()
            syncReadPostsTask = Task {
                do {
                    try await infopostsService.syncReadPosts(context: context)
                } catch {
                    logger.error("Ошибка синхронизации прочитанных инфопостов: \(error.localizedDescription)")
                }
            }
        } catch {
            logger.error("Не удалось загрузить инфопосты: \(error.localizedDescription)")
        }
    }

    func didLogout() {
        syncReadPostsTask?.cancel()
        syncReadPostsTask = nil
        startDate = nil
        currentDayCalculator = nil
        maxReadInfoPostDay = 0
        infopostsService.didLogout()
        // Отправка команды логаута на часы
        watchConnectivityManager.sendAuthStatusChanged(false)
    }

    /// Обрабатывает изменение статуса авторизации
    /// - Parameters:
    ///   - isAuthorized: Статус авторизации
    ///   - context: Контекст SwiftData для получения активности дня
    func processAuthStatus(isAuthorized: Bool, context: ModelContext) {
        if isAuthorized {
            let currentDay = currentDayCalculator?.currentDay
            watchConnectivityManager.sendAuthStatusChanged(
                true,
                currentDay: currentDay,
                context: context
            )
        } else {
            didLogout()
            do {
                try context.delete(model: User.self)
            } catch {
                logger.error("Не удалось удалить данные пользователя: \(error.localizedDescription)")
                fatalError("Не удалось удалить данные пользователя: \(error.localizedDescription)")
            }
        }
    }

    /// Отправляет данные текущего дня на часы
    /// - Parameters:
    ///   - currentDay: Номер текущего дня (опционально)
    ///   - context: Контекст SwiftData для получения активности дня
    func sendDayDataToWatch(currentDay: Int?, context _: ModelContext) {
        guard let currentDay else {
            return
        }

        watchConnectivityManager.sendCurrentDayChanged(currentDay)
    }

    /// Сбрасывает программу: удаляет все данные прохождения программы и начинает заново
    /// - Parameter context: Контекст модели SwiftData
    func resetProgram(context: ModelContext) async {
        state = .isLoadingInitialData
        guard let user = try? context.fetch(FetchDescriptor<User>()).first else {
            logger.error("Пользователь не найден для сброса программы")
            state = .idle
            return
        }
        // Удаление всех DayActivity пользователя (DayActivityTraining удалятся автоматически через каскад)
        let activities = user.dayActivities
        activities.forEach { context.delete($0) }
        // Удаление всех UserProgress пользователя (локальные фото dataPhoto* удалятся вместе с записями)
        let progress = user.progressResults
        progress.forEach { context.delete($0) }
        // Очистка данных инфопостов в User
        user.setFavoriteInfopostIds([])
        user.setReadInfopostDays([])
        user.setUnsyncedReadInfopostDays([])
        // Сохраняем изменения перед вызовом startNewRun
        try? context.save()
        // Метод startNewRun сделает запрос к серверу через StatusClient.start(date:) и установит новую startDate
        let now = Date.now
        await startNewRun(appDate: now)
        currentDayCalculator = .init(startDate, now)
        state = .idle
    }

    #if DEBUG
    /// Устанавливает текущий день программы для дебага и тестирования
    /// - Parameter day: Номер дня от 1 до 100
    func setCurrentDayForDebug(_ day: Int) {
        guard (1 ... 100).contains(day) else {
            logger.error("Попытка установить невалидный день: \(day). День должен быть от 1 до 100")
            return
        }
        let now = Date.now
        let daysToSubtract = day - 1
        guard let newStartDate = Calendar.current.date(byAdding: .day, value: -daysToSubtract, to: now) else {
            logger.error("Не удалось вычислить новую дату старта для дня \(day)")
            return
        }
        logger.info("Установка дня \(day) для дебага. Новая дата старта: \(newStartDate.description)")
        startDate = newStartDate
        currentDayCalculator = .init(newStartDate, now)
    }
    #endif
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

        let startDate = Date.now
        let user = try? context.fetch(FetchDescriptor<User>()).first
        let entry = SyncJournalEntry(
            startDate: startDate,
            result: .success,
            user: user
        )
        context.insert(entry)

        var allErrors: [SyncError] = []
        var progressStats: SyncStats?
        var exercisesStats: SyncStats?
        var activitiesStats: SyncStats?

        do {
            let result = try await progressSyncService.syncProgress(context: context)
            progressStats = result.details.progress
            if let errors = result.details.errors {
                allErrors.append(contentsOf: errors)
            }
        } catch {
            logger.error("Ошибка синхронизации прогресса: \(error.localizedDescription)")
            allErrors.append(
                SyncError(
                    type: "ProgressSyncError",
                    message: error.localizedDescription,
                    entityType: "progress",
                    entityId: nil
                )
            )
        }

        do {
            let result = try await customExercisesService.syncCustomExercises(context: context)
            exercisesStats = result.details.exercises
            if let errors = result.details.errors {
                allErrors.append(contentsOf: errors)
            }
        } catch {
            logger.error("Ошибка синхронизации упражнений: \(error.localizedDescription)")
            allErrors.append(
                SyncError(
                    type: "CustomExercisesSyncError",
                    message: error.localizedDescription,
                    entityType: "exercise",
                    entityId: nil
                )
            )
        }

        do {
            let result = try await dailyActivitiesService.syncDailyActivities(context: context)
            activitiesStats = result.details.activities
            if let errors = result.details.errors {
                allErrors.append(contentsOf: errors)
            }
        } catch {
            logger.error("Ошибка синхронизации активностей: \(error.localizedDescription)")
            allErrors.append(
                SyncError(
                    type: "DailyActivitiesSyncError",
                    message: error.localizedDescription,
                    entityType: "activity",
                    entityId: nil
                )
            )
        }

        let combinedStats = SyncStats(combining: progressStats, exercises: exercisesStats, activities: activitiesStats)
        let syncResult = SyncResultType(
            errors: allErrors.isEmpty ? nil : allErrors,
            stats: combinedStats
        )

        let details = SyncResultDetails(
            progress: progressStats,
            exercises: exercisesStats,
            activities: activitiesStats,
            errors: allErrors.isEmpty ? nil : allErrors
        )

        entry.endDate = Date.now
        entry.result = syncResult
        entry.details = details
        try? context.save()

        conflictingSyncModel = nil
        state = .idle
    }
}

// MARK: - WatchConnectivityManager

private let watchConnectivityLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "SotkaApp",
    category: "WatchConnectivityManager"
)

extension StatusManager {
    /// Типы запросов от часов для обработки в очереди
    enum WatchRequest {
        case setActivity(day: Int, activityType: DayActivityType)
        case saveWorkout(day: Int, result: WorkoutResult, executionType: ExerciseExecutionType, comment: String?)
        case getCurrentActivity(day: Int, replyHandler: ([String: Any]) -> Void)
        case getWorkoutData(day: Int, replyHandler: ([String: Any]) -> Void)
        case deleteActivity(day: Int)
    }

    /// Менеджер для связи с Apple Watch через WatchConnectivity
    @MainActor
    final class WatchConnectivityManager: NSObject {
        private weak var statusManager: StatusManager?
        private let sessionProtocol: WCSessionProtocol

        /// Очередь запросов от часов для обработки во вьюхе
        var pendingRequests: [WatchRequest] = []

        /// Счетчик для отслеживания изменений в pendingRequests (используется в onChange)
        var pendingRequestsCount: Int {
            pendingRequests.count
        }

        /// Реальная сессия для делегата (только для WCSession, не для моков)
        var session: WCSession? {
            sessionProtocol as? WCSession
        }

        /// Инициализатор
        /// - Parameters:
        ///   - statusManager: Менеджер статуса для доступа к сервисам
        ///   - sessionProtocol: Протокол сессии для тестирования. Если `nil`, используется `WCSession.default`
        init(
            statusManager: StatusManager,
            sessionProtocol: WCSessionProtocol? = nil
        ) {
            self.statusManager = statusManager

            if let sessionProtocol {
                self.sessionProtocol = sessionProtocol
            } else if WCSession.isSupported() {
                self.sessionProtocol = WCSession.default
            } else {
                fatalError("WCSession не поддерживается на этом устройстве")
            }

            super.init()

            let selfRef = self
            Task { @MainActor in
                if let session = selfRef.session {
                    session.delegate = selfRef
                    session.activate()
                } else {
                    selfRef.sessionProtocol.delegate = selfRef
                    selfRef.sessionProtocol.activate()
                }
            }
        }

        /// Обработка всех накопленных запросов от часов
        /// - Parameter context: Контекст модели SwiftData для доступа к данным
        @MainActor
        func processPendingRequests(context: ModelContext) {
            let requests = pendingRequests
            pendingRequests = [] // Очищаем очередь перед обработкой
            for request in requests {
                switch request {
                case let .setActivity(day, activityType):
                    _ = handleSetActivity(day: day, activityType: activityType, context: context)
                case let .saveWorkout(day, result, executionType, comment):
                    _ = handleSaveWorkout(
                        day: day,
                        result: result,
                        executionType: executionType,
                        comment: comment,
                        context: context
                    )
                case let .getCurrentActivity(day, replyHandler):
                    let reply = handleGetCurrentActivity(day: day, context: context)
                    replyHandler(reply)
                case let .getWorkoutData(day, replyHandler):
                    let reply = handleGetWorkoutData(day: day, context: context)
                    replyHandler(reply)
                case let .deleteActivity(day):
                    _ = handleDeleteActivity(day: day, context: context)
                }
            }
        }

        /// Отправка команды изменения статуса авторизации на часы
        /// - Parameters:
        ///   - isAuthorized: Статус авторизации
        ///   - currentDay: Номер текущего дня (опционально)
        ///   - context: Контекст SwiftData для получения активности дня (опционально)
        @MainActor
        func sendAuthStatusChanged(_ isAuthorized: Bool, currentDay: Int? = nil, context _: ModelContext? = nil) {
            guard sessionProtocol.isReachable else {
                watchConnectivityLogger.debug("Часы недоступны для отправки команды изменения статуса авторизации")
                return
            }

            var message: [String: Any] = [
                "command": Constants.WatchCommand.authStatus.rawValue,
                "isAuthorized": isAuthorized
            ]

            if let currentDay {
                message["currentDay"] = currentDay
            }

            sessionProtocol.sendMessage(message, replyHandler: nil) { error in
                watchConnectivityLogger.error("Ошибка отправки команды изменения статуса авторизации: \(error.localizedDescription)")
            }
        }

        /// Отправляет команду об изменении текущего дня на часы
        /// - Parameter currentDay: Номер текущего дня
        @MainActor
        func sendCurrentDayChanged(_ currentDay: Int) {
            guard sessionProtocol.isReachable else {
                watchConnectivityLogger.debug("Часы недоступны для отправки команды изменения текущего дня")
                return
            }

            let message: [String: Any] = [
                "command": Constants.WatchCommand.currentDay.rawValue,
                "currentDay": currentDay
            ]

            sessionProtocol.sendMessage(message, replyHandler: nil) { error in
                watchConnectivityLogger.error("Ошибка отправки команды изменения текущего дня: \(error.localizedDescription)")
            }
        }

        // MARK: - Обработка команд (вызывается из вьюхи)

        /// Обрабатывает запрос установки активности
        /// - Parameters:
        ///   - day: Номер дня
        ///   - activityType: Тип активности
        ///   - context: Контекст SwiftData
        /// - Returns: Ответ для часов (если нужен)
        @MainActor
        func handleSetActivity(day: Int, activityType: DayActivityType, context: ModelContext) -> [String: Any] {
            guard let statusManager else {
                watchConnectivityLogger.error("StatusManager недоступен для установки активности дня")
                return ["error": "StatusManager недоступен"]
            }

            guard let user = try? context.fetch(FetchDescriptor<User>()).first else {
                watchConnectivityLogger.error("Пользователь не найден для установки активности дня")
                return ["error": "Пользователь не найден"]
            }

            // Проверка конфликтов: перед сохранением проверить существующую активность для дня
            let userId = user.id
            let predicate = #Predicate<DayActivity> { activity in
                activity.day == day && !activity.shouldDelete
            }
            let descriptor = FetchDescriptor<DayActivity>(predicate: predicate)
            let allActivities = (try? context.fetch(descriptor)) ?? []
            let existingActivity = allActivities.first { $0.user?.id == userId }

            if let existingActivity {
                // Если активность существует и имеет тип .workout и не завершена (нет count или duration) → отклонить изменение
                if existingActivity.activityType == .workout {
                    let isCompleted = existingActivity.count != nil || existingActivity.duration != nil
                    if !isCompleted {
                        watchConnectivityLogger.warning("Попытка изменить активность дня \(day) с незавершенной тренировкой")
                        return ["error": "Нельзя изменить активность: существует незавершенная тренировка"]
                    }
                }
            }

            // Если активность не существует или имеет другой тип или тренировка завершена → выполнить изменение
            statusManager.dailyActivitiesService.set(activityType, for: day, context: context)

            // Отправка обновленной активности на часы
            sendCurrentActivity(day: day, context: context)

            return [:]
        }

        /// Обрабатывает запрос сохранения тренировки
        /// - Parameters:
        ///   - day: Номер дня
        ///   - result: Результат тренировки
        ///   - executionType: Тип выполнения упражнений
        ///   - context: Контекст SwiftData
        /// - Returns: Ответ для часов (если нужен)
        @MainActor
        func handleSaveWorkout(
            day: Int,
            result: WorkoutResult,
            executionType: ExerciseExecutionType,
            comment: String?,
            context: ModelContext
        ) -> [String: Any] {
            guard let statusManager else {
                watchConnectivityLogger.error("StatusManager недоступен для сохранения тренировки")
                return ["error": "StatusManager недоступен"]
            }

            guard let user = try? context.fetch(FetchDescriptor<User>()).first else {
                watchConnectivityLogger.error("Пользователь не найден для сохранения тренировки")
                return ["error": "Пользователь не найден"]
            }

            // Получаем существующую активность или создаем новую через WorkoutProgramCreator
            let userId = user.id
            let predicate = #Predicate<DayActivity> { activity in
                activity.day == day && !activity.shouldDelete
            }
            let descriptor = FetchDescriptor<DayActivity>(predicate: predicate)
            let allActivities = (try? context.fetch(descriptor)) ?? []
            let existingActivity = allActivities.first { $0.user?.id == userId }

            let activity: DayActivity
            if let existingActivity,
               existingActivity.activityType == .workout {
                // Обновляем существующую активность
                activity = existingActivity
                activity.count = result.count
                activity.duration = result.duration
                activity.executeTypeRaw = executionType.rawValue
                activity.comment = comment
                activity.modifyDate = .now
                activity.isSynced = false
            } else {
                // Создаем новую активность через WorkoutProgramCreator
                let creator = WorkoutProgramCreator(day: day, executionType: executionType)
                activity = creator.dayActivity
                activity.count = result.count
                activity.duration = result.duration
                activity.comment = comment
                activity.user = user
            }

            let commentInfo = comment != nil ? ", комментарий: \(comment!)" : ""
            watchConnectivityLogger.info("Сохранение тренировки: день \(day), количество \(result.count)\(commentInfo)")

            // Сохранение через DailyActivitiesService
            statusManager.dailyActivitiesService.createDailyActivity(activity, context: context)

            // Отправка обновленной активности на часы
            sendCurrentActivity(day: day, context: context)

            return [:]
        }

        /// Обрабатывает запрос получения текущей активности
        /// - Parameters:
        ///   - day: Номер дня
        ///   - context: Контекст SwiftData
        /// - Returns: Ответ для часов
        @MainActor
        func handleGetCurrentActivity(day: Int, context: ModelContext) -> [String: Any] {
            guard let user = try? context.fetch(FetchDescriptor<User>()).first else {
                watchConnectivityLogger.error("Пользователь не найден для получения текущей активности")
                return ["error": "Пользователь не найден"]
            }

            // Получение из SwiftData через FetchDescriptor<DayActivity>
            let userId = user.id
            let predicate = #Predicate<DayActivity> { activity in
                activity.day == day && !activity.shouldDelete
            }
            let descriptor = FetchDescriptor<DayActivity>(predicate: predicate)
            let allActivities = (try? context.fetch(descriptor)) ?? []
            guard let activity = allActivities.first(where: { $0.user?.id == userId }) else {
                // Активность не найдена
                return [
                    "command": Constants.WatchCommand.currentActivity.rawValue,
                    "day": day
                ]
            }

            guard let activityType = activity.activityType else {
                return [
                    "command": Constants.WatchCommand.currentActivity.rawValue,
                    "day": day
                ]
            }

            return [
                "command": Constants.WatchCommand.currentActivity.rawValue,
                "day": day,
                "activityType": activityType.rawValue
            ]
        }

        /// Обрабатывает запрос получения данных тренировки
        /// - Parameters:
        ///   - day: Номер дня
        ///   - context: Контекст SwiftData
        /// - Returns: Ответ для часов
        @MainActor
        func handleGetWorkoutData(day: Int, context: ModelContext) -> [String: Any] {
            guard let user = try? context.fetch(FetchDescriptor<User>()).first else {
                watchConnectivityLogger.error("Пользователь не найден для получения данных тренировки")
                return ["error": "Пользователь не найден"]
            }

            // Получаем существующую активность типа .workout для дня
            let userId = user.id
            let predicate = #Predicate<DayActivity> { activity in
                activity.day == day && !activity.shouldDelete
            }
            let descriptor = FetchDescriptor<DayActivity>(predicate: predicate)
            let allActivities = (try? context.fetch(descriptor)) ?? []
            let existingActivity = allActivities.first { $0.user?.id == userId }

            let workoutData: WorkoutData
            if let existingActivity,
               existingActivity.activityType == .workout,
               let data = existingActivity.workoutData {
                // Используем данные из существующей активности
                workoutData = data
            } else {
                // Создаем через WorkoutProgramCreator для нового дня
                let creator = WorkoutProgramCreator(day: day)
                let tempActivity = creator.dayActivity
                guard let data = tempActivity.workoutData else {
                    watchConnectivityLogger.error("Не удалось создать данные тренировки для дня \(day)")
                    return ["error": "Не удалось создать данные тренировки"]
                }
                workoutData = data
            }

            // Получаем count и comment из существующей активности
            let executionCount = existingActivity?.count
            let comment = existingActivity?.comment

            // Создаем ответ с полными данными
            let response = WorkoutDataResponse(
                workoutData: workoutData,
                executionCount: executionCount,
                comment: comment
            )

            // Создаем сообщение для отправки на часы
            guard let messageToSend = response.makeMessageForWatch(
                command: Constants.WatchCommand.sendWorkoutData.rawValue
            ) else {
                watchConnectivityLogger.error("Ошибка сериализации ответа с данными тренировки")
                return ["error": "Ошибка сериализации данных"]
            }

            if sessionProtocol.isReachable {
                sessionProtocol.sendMessage(messageToSend, replyHandler: nil) { error in
                    watchConnectivityLogger.error("Ошибка отправки данных тренировки на часы: \(error.localizedDescription)")
                }
            }

            return messageToSend
        }

        /// Обрабатывает запрос удаления активности
        /// - Parameters:
        ///   - day: Номер дня
        ///   - context: Контекст SwiftData
        /// - Returns: Ответ для часов (если нужен)
        @MainActor
        func handleDeleteActivity(day: Int, context: ModelContext) -> [String: Any] {
            guard let statusManager else {
                watchConnectivityLogger.error("StatusManager недоступен для удаления активности дня")
                return ["error": "StatusManager недоступен"]
            }

            guard let user = try? context.fetch(FetchDescriptor<User>()).first else {
                watchConnectivityLogger.error("Пользователь не найден для удаления активности")
                return ["error": "Пользователь не найден"]
            }

            // Получение активности для удаления
            let userId = user.id
            let predicate = #Predicate<DayActivity> { activity in
                activity.day == day && !activity.shouldDelete
            }
            let descriptor = FetchDescriptor<DayActivity>(predicate: predicate)
            let allActivities = (try? context.fetch(descriptor)) ?? []
            guard let activity = allActivities.first(where: { $0.user?.id == userId }) else {
                watchConnectivityLogger.warning("Активность дня \(day) не найдена для удаления")
                // Отправляем обновление на часы (активность уже удалена или не существует)
                sendCurrentActivity(day: day, context: context)
                return [:]
            }

            // Удаление через DailyActivitiesService
            statusManager.dailyActivitiesService.deleteDailyActivity(activity, context: context)
            watchConnectivityLogger.info("Активность дня \(day) помечена для удаления")

            // Отправка обновленной активности на часы (nil означает, что активность удалена)
            sendCurrentActivity(day: day, context: context)

            return [:]
        }

        // MARK: - Отправка обновлений на часы

        /// Отправляет обновленную активность дня на часы
        /// - Parameters:
        ///   - day: Номер дня
        ///   - context: Контекст SwiftData
        @MainActor
        func sendCurrentActivity(day: Int, context: ModelContext) {
            guard sessionProtocol.isReachable else {
                watchConnectivityLogger.debug("Часы недоступны для отправки обновленной активности дня \(day)")
                return
            }

            guard let user = try? context.fetch(FetchDescriptor<User>()).first else {
                watchConnectivityLogger.error("Пользователь не найден для отправки обновленной активности")
                return
            }

            let userId = user.id
            let predicate = #Predicate<DayActivity> { activity in
                activity.day == day && !activity.shouldDelete
            }
            let descriptor = FetchDescriptor<DayActivity>(predicate: predicate)
            let allActivities = (try? context.fetch(descriptor)) ?? []
            let activity = allActivities.first { $0.user?.id == userId }

            var message: [String: Any] = [
                "command": Constants.WatchCommand.currentActivity.rawValue,
                "day": day
            ]

            if let activity,
               let activityType = activity.activityType {
                message["activityType"] = activityType.rawValue
            }

            sessionProtocol.sendMessage(message, replyHandler: nil) { error in
                watchConnectivityLogger.error("Ошибка отправки обновленной активности на часы: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - WCSessionDelegate

nonisolated extension StatusManager.WatchConnectivityManager: WCSessionDelegate {
    func sessionDidBecomeInactive(_: WCSession) {}

    func sessionDidDeactivate(_: WCSession) {}

    nonisolated func session(_: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            watchConnectivityLogger.error("Ошибка активации WCSession: \(error.localizedDescription)")
        } else {
            watchConnectivityLogger.info("WCSession активирована с состоянием: \(activationState.rawValue)")
        }
    }

    nonisolated func session(_: WCSession, didReceiveMessage message: [String: Any]) {
        watchConnectivityLogger.info("Получено сообщение от часов: \(message)")
        nonisolated(unsafe) let messageCopy = message
        let managerRef = self
        Task { @MainActor in
            managerRef.addRequestToQueue(message: messageCopy)
        }
    }

    nonisolated func session(_: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        watchConnectivityLogger.info("Получено сообщение с ответом от часов: \(message)")
        nonisolated(unsafe) let messageCopy = message
        let managerRef = self
        nonisolated(unsafe) let replyHandlerCopy = replyHandler
        Task { @MainActor in
            managerRef.addRequestToQueue(message: messageCopy, replyHandler: replyHandlerCopy)
        }
    }
}

// MARK: - Добавление запросов в очередь

private extension StatusManager.WatchConnectivityManager {
    /// Добавляет запрос в очередь для обработки во вьюхе
    /// - Parameters:
    ///   - message: Сообщение от часов
    ///   - replyHandler: Обработчик ответа (если есть)
    @MainActor
    func addRequestToQueue(message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        guard let commandString = message["command"] as? String,
              let command = Constants.WatchCommand(rawValue: commandString)
        else {
            watchConnectivityLogger.error("Неизвестная команда от часов: \(message)")
            replyHandler?(["error": "Неизвестная команда"])
            return
        }

        switch command {
        case .setActivity:
            guard let day = message["day"] as? Int,
                  let activityTypeRaw = message["activityType"] as? Int,
                  let activityType = DayActivityType(rawValue: activityTypeRaw)
            else {
                watchConnectivityLogger.error("Неверный формат команды установки активности: \(message)")
                replyHandler?(["error": "Неверный формат команды"])
                return
            }
            pendingRequests.append(.setActivity(day: day, activityType: activityType))

        case .saveWorkout:
            guard let day = message["day"] as? Int,
                  let resultDict = message["result"] as? [String: Any],
                  let executionTypeRaw = message["executionType"] as? Int
            else {
                watchConnectivityLogger.error("Неверный формат команды сохранения тренировки: \(message)")
                replyHandler?(["error": "Неверный формат команды"])
                return
            }

            // Десериализация WorkoutResult из JSON
            guard let resultData = try? JSONSerialization.data(withJSONObject: resultDict),
                  let result = try? JSONDecoder().decode(WorkoutResult.self, from: resultData)
            else {
                watchConnectivityLogger.error("Ошибка десериализации результата тренировки: \(resultDict)")
                replyHandler?(["error": "Ошибка десериализации результата"])
                return
            }

            let executionType = ExerciseExecutionType(rawValue: executionTypeRaw) ?? .cycles
            let comment = message["comment"] as? String
            pendingRequests.append(.saveWorkout(day: day, result: result, executionType: executionType, comment: comment))

        case .getCurrentActivity:
            guard let day = message["day"] as? Int else {
                watchConnectivityLogger.error("Неверный формат команды получения текущей активности: \(message)")
                replyHandler?(["error": "Неверный формат команды"])
                return
            }
            if let replyHandler {
                pendingRequests.append(.getCurrentActivity(day: day, replyHandler: replyHandler))
            } else {
                watchConnectivityLogger.warning("Команда getCurrentActivity без replyHandler")
            }

        case .getWorkoutData:
            guard let day = message["day"] as? Int else {
                watchConnectivityLogger.error("Неверный формат команды получения данных тренировки: \(message)")
                replyHandler?(["error": "Неверный формат команды"])
                return
            }
            if let replyHandler {
                pendingRequests.append(.getWorkoutData(day: day, replyHandler: replyHandler))
            } else {
                watchConnectivityLogger.warning("Команда getWorkoutData без replyHandler")
            }

        case .deleteActivity:
            guard let day = message["day"] as? Int else {
                watchConnectivityLogger.error("Неверный формат команды удаления активности: \(message)")
                replyHandler?(["error": "Неверный формат команды"])
                return
            }
            pendingRequests.append(.deleteActivity(day: day))

        case .currentActivity, .sendWorkoutData, .authStatus, .currentDay:
            watchConnectivityLogger.warning("Команда \(commandString) не должна приходить от часов")
            replyHandler?(["error": "Неверная команда"])
        }
    }
}
