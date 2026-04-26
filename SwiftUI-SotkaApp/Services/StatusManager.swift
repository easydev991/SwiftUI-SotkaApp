import Foundation
import Observation
import OSLog
import SwiftData
import SWUtils
import WatchConnectivity

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "SotkaApp",
    category: String(describing: StatusManager.self)
)

@MainActor
@Observable
final class StatusManager: NSObject {
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored let customExercisesService: CustomExercisesService
    @ObservationIgnored let infopostsService: InfopostsService
    @ObservationIgnored let progressSyncService: ProgressSyncService
    @ObservationIgnored let dailyActivitiesService: DailyActivitiesService
    @ObservationIgnored private let reviewEventReporter: (any ReviewEventReporting)?
    @ObservationIgnored private var isJournalSyncInProgress = false
    @ObservationIgnored private(set) var syncReadPostsTask: Task<Void, Error>?
    @ObservationIgnored private let sessionProtocol: WCSessionProtocol?
    @ObservationIgnored let modelContainer: ModelContainer
    private let statusClient: StatusClient
    private let purchasesClient: PurchasesClient?
    @ObservationIgnored private var extensionDateKeysSnapshot: Set<Int64> = []

    /// Последние отправленные данные статуса для дедупликации
    @ObservationIgnored private var lastSentStatus: (isAuthorized: Bool, currentDay: Int?, currentActivity: DayActivityType?)?

    /// Проверяет, доступны ли часы для отправки сообщений
    var isReachable: Bool {
        sessionProtocol?.isReachable ?? false
    }

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
        purchasesClient: PurchasesClient? = nil,
        modelContainer: ModelContainer,
        userDefaults: UserDefaults? = nil,
        watchConnectivitySessionProtocol: WCSessionProtocol? = nil,
        reviewEventReporter: (any ReviewEventReporting)? = nil
    ) {
        self.customExercisesService = customExercisesService
        self.infopostsService = infopostsService
        self.progressSyncService = progressSyncService
        self.dailyActivitiesService = dailyActivitiesService
        self.statusClient = statusClient
        self.purchasesClient = purchasesClient
        self.modelContainer = modelContainer
        self.reviewEventReporter = reviewEventReporter
        if let userDefaults {
            self.defaults = userDefaults
        } else {
            self.defaults = UserDefaults.standard
        }

        // Инициализируем sessionProtocol
        if let sessionProtocol = watchConnectivitySessionProtocol {
            self.sessionProtocol = sessionProtocol
        } else if WCSession.isSupported() {
            self.sessionProtocol = WCSession.default
        } else {
            self.sessionProtocol = nil
        }

        super.init()

        // Устанавливаем делегат и активируем сессию только если она поддерживается
        if let sessionProtocol {
            sessionProtocol.delegate = self
            sessionProtocol.activate()
            logger.info("WCSession успешно активирована")
        } else {
            logger.warning("WCSession не удалось активировать, так как она не поддерживается на данном устройстве")
        }
    }

    /// Получает статус прохождения пользователя
    func getStatus() async {
        let context = modelContainer.mainContext
        let now = Date.now

        let user = try? context.fetch(FetchDescriptor<User>()).first
        refreshExtensionSnapshot(for: user, context: context)

        if let user, user.isOfflineOnly {
            if startDate == nil {
                startDate = now
            }
            rebuildCurrentDayCalculator(now: now)
            didLoadInitialData = true
            state = .idle
            return
        }

        rebuildCurrentDayCalculator(now: now)

        guard !state.isLoading else { return }
        state = .init(didLoadInitialData: didLoadInitialData)
        do {
            let currentRun = try await statusClient.current()
            let siteStartDate = currentRun.date
            maxReadInfoPostDay = currentRun.maxForAllRunsDay ?? 0
            switch (startDate, siteStartDate) {
            case (.none, .none):
                logger.info("Сотку еще не стартовали")
                await start(appDate: nil)
            case let (.some(date), .none):
                // Приложение - источник истины
                logger.info("Дата старта есть только в приложении: \(date.description)")
                await start(appDate: date)
            case let (.none, .some(date)):
                // Сайт - источник истины
                logger.info("Дата старта есть только на сайте: \(date.description)")
                await syncWithSiteDate(siteDate: date)
            case let (.some(appDate), .some(siteDate)):
                logger.info("Дата старта в приложении: \(appDate.description), и на сайте: \(siteDate.description)")
                if appDate.isTheSameDayIgnoringTime(siteDate) {
                    await syncJournalAndProgress()
                } else {
                    conflictingSyncModel = .init(appDate, siteDate)
                }
            }

            if let user {
                await syncCalendarPurchasesOnGetStatus(for: user, context: context, now: now)
            } else {
                rebuildCurrentDayCalculator(now: now)
            }

            // Отправляем текущий статус перед didLoadInitialData = true (после синхронизации)
            let updatedCurrentDay = currentDayCalculator?.currentDay
            let updatedCurrentActivity = updatedCurrentDay.map { dailyActivitiesService.getActivityType(day: $0, context: context) } ?? nil
            sendCurrentStatus(isAuthorized: true, currentDay: updatedCurrentDay, currentActivity: updatedCurrentActivity)

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

        let context = modelContainer.mainContext
        let user = try? context.fetch(FetchDescriptor<User>()).first
        refreshExtensionSnapshot(for: user, context: context)

        if let user, user.isOfflineOnly {
            startDate = newStartDate
            rebuildCurrentDayCalculator(now: .now)
            return
        }

        let isoDateString = DateFormatterService.stringFromFullDate(newStartDate, iso: true)
        let currentRun = try? await statusClient.start(date: isoDateString)
        startDate = if let siteStartDate = currentRun?.date {
            siteStartDate
        } else {
            newStartDate
        }
        rebuildCurrentDayCalculator(now: .now)
    }

    func start(appDate: Date?) async {
        await startNewRun(appDate: appDate)
        await syncJournalAndProgress()
    }

    func syncWithSiteDate(siteDate: Date) async {
        startDate = siteDate
        rebuildCurrentDayCalculator(now: .now)
        await syncJournalAndProgress()
    }

    func loadInfopostsWithUserGender() {
        let context = modelContainer.mainContext
        do {
            let user = try context.fetch(FetchDescriptor<User>()).first
            try infopostsService.loadAvailableInfoposts(
                currentDay: currentDayCalculator?.currentDay,
                maxReadInfoPostDay: maxReadInfoPostDay,
                userGender: user?.gender,
                force: true
            )

            if let user, user.isOfflineOnly {
                logger.debug("Пропуск syncReadPosts для офлайн-пользователя")
                return
            }

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
        clearExtensionDates()
        JournalPagePersistence.clear(defaults: defaults)
        startDate = nil
        currentDayCalculator = nil
        maxReadInfoPostDay = 0
        didLoadInitialData = false
        infopostsService.didLogout()
    }

    /// Обрабатывает изменение статуса авторизации
    /// - Parameters:
    ///   - isAuthorized: Статус авторизации
    func processAuthStatus(isAuthorized: Bool) {
        let context = modelContainer.mainContext
        if isAuthorized {
            let currentDay = currentDayCalculator?.currentDay
            let currentActivity = currentDay.map { dailyActivitiesService.getActivityType(day: $0, context: context) } ?? nil
            sendCurrentStatus(isAuthorized: true, currentDay: currentDay, currentActivity: currentActivity)
        } else {
            sendCurrentStatus(isAuthorized: false, currentDay: nil, currentActivity: nil)
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
    func sendDayDataToWatch(currentDay: Int?) {
        guard let currentDay else {
            return
        }

        // Не отправляем данные до завершения первичной загрузки (при запуске приложения)
        // Это предотвращает лишние синхронизации при первом изменении currentDayCalculator
        guard didLoadInitialData else {
            logger.debug("Пропускаем отправку данных на часы: первичная загрузка еще не завершена")
            return
        }

        // Получаем текущую активность из SwiftData
        let context = modelContainer.mainContext
        let currentActivity = dailyActivitiesService.getActivityType(day: currentDay, context: context)
        sendCurrentStatus(isAuthorized: true, currentDay: currentDay, currentActivity: currentActivity)
    }

    // MARK: - Методы отправки данных на часы

    /// Отправляет текущий статус на часы (статус авторизации, текущий день и текущая активность)
    /// - Parameters:
    ///   - isAuthorized: Статус авторизации
    ///   - currentDay: Номер текущего дня (опционально)
    ///   - currentActivity: Текущая активность (опционально)
    func sendCurrentStatus(isAuthorized: Bool, currentDay: Int?, currentActivity: DayActivityType?) {
        // Проверяем, изменились ли данные по сравнению с последними отправленными
        let hasStatusChanged = hasStatusChanged(
            isAuthorized: isAuthorized,
            currentDay: currentDay,
            currentActivity: currentActivity
        )

        // Отправляем applicationContext всегда, даже если часы недоступны (работает когда приложение закрыто)
        // Но applicationContext отправляется при каждом вызове, так как он может обновляться даже при одинаковых данных
        updateApplicationContextOnWatch(isAuthorized: isAuthorized, currentDay: currentDay, currentActivity: currentActivity)

        guard let sessionProtocol, sessionProtocol.isReachable else {
            logger.debug("Часы недоступны для отправки текущего статуса")
            // Обновляем lastSentStatus даже если часы недоступны, чтобы applicationContext не дублировался
            if hasStatusChanged {
                lastSentStatus = (isAuthorized: isAuthorized, currentDay: currentDay, currentActivity: currentActivity)
            }
            return
        }

        // Отправляем sendMessage только если данные изменились
        guard hasStatusChanged else {
            logger.debug("Статус не изменился, пропускаем отправку sendMessage")
            return
        }

        let model = WatchStatusMessage(
            isAuthorized: isAuthorized,
            currentDay: currentDay,
            currentActivity: currentActivity,
            restTime: restTimeFromUserDefaults
        )

        sessionProtocol.sendMessageToWatch(
            model.message,
            replyHandler: nil
        ) { error in
            logger.error("Ошибка отправки текущего статуса на часы: \(error.localizedDescription)")
        }

        // Обновляем последние отправленные данные
        lastSentStatus = (isAuthorized: isAuthorized, currentDay: currentDay, currentActivity: currentActivity)
    }

    /// Проверяет, изменился ли статус по сравнению с последними отправленными данными
    /// - Parameters:
    ///   - isAuthorized: Статус авторизации
    ///   - currentDay: Номер текущего дня (опционально)
    ///   - currentActivity: Текущая активность (опционально)
    /// - Returns: `true` если статус изменился, `false` если идентичен
    private func hasStatusChanged(
        isAuthorized: Bool,
        currentDay: Int?,
        currentActivity: DayActivityType?
    ) -> Bool {
        guard let lastSent = lastSentStatus else {
            // Если это первый вызов, считаем что статус изменился
            return true
        }

        // Сравниваем все поля
        return lastSent.isAuthorized != isAuthorized ||
            lastSent.currentDay != currentDay ||
            lastSent.currentActivity != currentActivity
    }

    /// Отправляет applicationContext при активации WCSession (если пользователь авторизован)
    func sendApplicationContextOnActivation() {
        let context = modelContainer.mainContext
        let isAuthorized = (try? context.fetch(FetchDescriptor<User>()).first) != nil

        // Если данные еще не загружены и пользователь авторизован, не отправляем Application Context
        // Application Context будет отправлен после завершения синхронизации с полными данными (currentDay)
        // Это предотвращает отображение неправильного дня на часах
        if !didLoadInitialData, isAuthorized {
            logger.debug("ApplicationContext не отправлен при активации: данные еще не загружены, будет отправлен после синхронизации")
            return
        }

        let currentDay: Int?
        let currentActivity: DayActivityType?

        if didLoadInitialData {
            // Данные загружены, можем получить currentDay
            currentDay = isAuthorized ? currentDayCalculator?.currentDay : nil
            currentActivity = currentDay.map { dailyActivitiesService.getActivityType(day: $0, context: context) } ?? nil
        } else {
            // Данные еще не загружены, пользователь не авторизован - отправляем статус неавторизации
            currentDay = nil
            currentActivity = nil
        }

        // Проверяем, не дублирует ли это данные, которые уже были отправлены через sendCurrentStatus
        let hasStatusChanged = hasStatusChanged(
            isAuthorized: isAuthorized,
            currentDay: currentDay,
            currentActivity: currentActivity
        )

        // Отправляем только если данные изменились или это первый вызов
        guard hasStatusChanged else {
            logger.debug("ApplicationContext не отправлен при активации: данные идентичны последним отправленным")
            return
        }

        if isAuthorized {
            updateApplicationContextOnWatch(isAuthorized: true, currentDay: currentDay, currentActivity: currentActivity)
            logger
                .debug(
                    "ApplicationContext отправлен при активации WCSession: пользователь авторизован, день \(currentDay?.description ?? "nil")"
                )
        } else {
            updateApplicationContextOnWatch(isAuthorized: false, currentDay: nil, currentActivity: nil)
            logger.debug("ApplicationContext отправлен при активации WCSession: пользователь не авторизован")
        }

        // Обновляем последние отправленные данные (только для applicationContext, не для sendMessage)
        // Это нужно для предотвращения дублирования при последующих вызовах
        lastSentStatus = (isAuthorized: isAuthorized, currentDay: currentDay, currentActivity: currentActivity)
    }

    /// Читает restTime из UserDefaults
    /// - Returns: Время отдыха в секундах (дефолтное значение, если не установлено)
    private var restTimeFromUserDefaults: Int {
        let storedValue = defaults.integer(forKey: Constants.restTimeKey)
        return storedValue == 0 ? Constants.defaultRestTime : storedValue
    }

    /// Обновляет applicationContext для часов (работает даже когда приложение закрыто)
    /// - Parameters:
    ///   - isAuthorized: Статус авторизации
    ///   - currentDay: Номер текущего дня (опционально)
    ///   - currentActivity: Текущая активность (опционально)
    private func updateApplicationContextOnWatch(isAuthorized: Bool, currentDay: Int?, currentActivity: DayActivityType?) {
        guard let sessionProtocol else {
            return
        }

        let statusMessage = WatchStatusMessage(
            isAuthorized: isAuthorized,
            currentDay: currentDay,
            currentActivity: currentActivity,
            restTime: restTimeFromUserDefaults
        )
        let applicationContext = statusMessage.applicationContext

        sessionProtocol.updateApplicationContextOnWatch(applicationContext)
        let restTimeForLogs = restTimeFromUserDefaults
        logger
            .debug(
                "ApplicationContext обновлен для часов: isAuthorized=\(isAuthorized), currentDay=\(currentDay?.description ?? "nil"), currentActivity=\(currentActivity?.rawValue.description ?? "nil"), restTime=\(restTimeForLogs)"
            )
    }

    /// Отправляет текущую активность конкретного дня на часы
    /// - Parameters:
    ///   - day: Номер дня
    func sendCurrentActivity(day: Int) {
        guard let sessionProtocol, sessionProtocol.isReachable else {
            logger.debug("Часы недоступны для отправки текущей активности дня \(day)")
            return
        }

        let context = modelContainer.mainContext
        let activityType = dailyActivitiesService.getActivityType(day: day, context: context)

        let model = WatchStatusMessage(
            isAuthorized: true,
            currentDay: day,
            currentActivity: activityType,
            restTime: restTimeFromUserDefaults
        )
        sessionProtocol.sendMessageToWatch(
            model.message,
            replyHandler: nil
        ) { error in
            logger.error("Ошибка отправки текущей активности на часы: \(error.localizedDescription)")
        }
    }

    /// Отправляет полные данные тренировки на часы для указанного дня
    /// - Parameters:
    ///   - day: Номер дня
    func sendWorkoutDataToWatch(day: Int) {
        guard let sessionProtocol, sessionProtocol.isReachable else {
            logger.debug("Часы недоступны для отправки данных тренировки дня \(day)")
            return
        }

        let context = modelContainer.mainContext
        let activity = dailyActivitiesService.getActivity(dayNumber: day, context: context)
        let workoutData: WorkoutData
        let executionCount: Int?
        let comment: String?

        if let existingActivity = activity {
            // Если активность существует, проверяем, является ли она тренировкой
            guard let existingWorkoutData = existingActivity.workoutData else {
                logger.debug("Активность дня \(day) не является тренировкой, данные не отправляются")
                return
            }
            // Используем существующую активность типа workout
            workoutData = existingWorkoutData
            executionCount = existingActivity.count
            comment = existingActivity.comment
        } else {
            // Если активность не найдена, создаем данные через WorkoutProgramCreator
            let creator = WorkoutProgramCreator(day: day)
            let newActivity = creator.dayActivity

            guard let newWorkoutData = newActivity.workoutData else {
                logger.debug("Не удалось создать данные тренировки для дня \(day)")
                return
            }

            workoutData = newWorkoutData
            executionCount = nil
            comment = nil
        }

        let response = WorkoutDataResponse(
            workoutData: workoutData,
            executionCount: executionCount,
            comment: comment
        )

        guard let message = response.makeMessageForWatch(command: Constants.WatchCommand.sendWorkoutData.rawValue) else {
            logger.error("Не удалось создать сообщение для отправки данных тренировки дня \(day)")
            return
        }

        sessionProtocol.sendMessageToWatch(
            message,
            replyHandler: nil
        ) { error in
            logger.error("Ошибка отправки данных тренировки на часы: \(error.localizedDescription)")
        }
    }

    // MARK: - Обработка команд от часов

    /// Обрабатывает команду от часов
    /// - Parameters:
    ///   - message: Сообщение от часов
    ///   - replyHandler: Обработчик ответа (опционально)
    func handleWatchCommand(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)? = nil
    ) {
        let context = modelContainer.mainContext

        guard let parsed = WatchStatusMessage.parseWatchCommand(message) else {
            logger.warning("Не удалось распарсить команду из сообщения: \(message)")
            replyHandler?(["error": "Неизвестная команда"])
            return
        }

        let command = parsed.command
        let data = parsed.data

        switch command {
        case .setActivity:
            handleSetActivityCommand(data: data, context: context, replyHandler: replyHandler)

        case .saveWorkout:
            handleSaveWorkoutCommand(data: data, context: context, replyHandler: replyHandler)

        case .getCurrentActivity:
            handleGetCurrentActivityCommand(data: data, context: context, replyHandler: replyHandler)

        case .getWorkoutData:
            handleGetWorkoutDataCommand(data: data, context: context, replyHandler: replyHandler)

        case .deleteActivity:
            handleDeleteActivityCommand(data: data, context: context, replyHandler: replyHandler)

        case .currentActivity, .sendWorkoutData, .authStatus, .currentDay:
            // Эти команды отправляются с iPhone на часы, не обрабатываются здесь
            logger.warning("Получена команда от iPhone на iPhone: \(command.rawValue)")
            replyHandler?(["error": "Команда предназначена для часов"])
        }
    }

    // MARK: - Обработка отдельных команд

    /// Обрабатывает команду установки активности
    private func handleSetActivityCommand(
        data: [String: Any],
        context: ModelContext,
        replyHandler: (([String: Any]) -> Void)?
    ) {
        guard let day = data["day"] as? Int,
              let activityTypeRaw = data["activityType"] as? Int,
              let activityType = DayActivityType(rawValue: activityTypeRaw)
        else {
            logger.error("Неверный формат данных для команды setActivity: \(data)")
            replyHandler?(["error": "Неверный формат данных"])
            return
        }

        // Проверка конфликта: если существует незавершенная тренировка, запрещаем изменение
        if let existingActivity = dailyActivitiesService.getActivity(dayNumber: day, context: context),
           existingActivity.activityType == .workout,
           existingActivity.count == nil {
            logger.warning("Попытка изменить активность дня \(day) с незавершенной тренировкой")
            replyHandler?(["error": "Нельзя изменить активность: на телефоне начата тренировка"])
            return
        }

        // Устанавливаем активность
        dailyActivitiesService.set(activityType, for: day, context: context)

        // Отправляем обновленную активность на часы
        sendCurrentActivity(day: day)

        // Если измененная активность относится к текущему дню, также отправляем статус
        if let currentDay = currentDayCalculator?.currentDay, currentDay == day {
            let currentActivity = dailyActivitiesService.getActivityType(day: day, context: context)
            sendCurrentStatus(
                isAuthorized: true,
                currentDay: currentDay,
                currentActivity: currentActivity
            )
        }

        replyHandler?([:])
    }

    /// Обрабатывает команду сохранения тренировки
    private func handleSaveWorkoutCommand(
        data: [String: Any],
        context: ModelContext,
        replyHandler: (([String: Any]) -> Void)?
    ) {
        guard let saveWorkoutData = WatchStatusMessage.decodeSaveWorkoutData(data) else {
            logger.error("Неверный формат данных для команды saveWorkout: \(data)")
            replyHandler?(["error": "Неверный формат данных"])
            return
        }

        let day = saveWorkoutData.day
        let workoutResult = saveWorkoutData.result
        let executionType = saveWorkoutData.executionType
        let trainings = saveWorkoutData.trainings
        let comment = saveWorkoutData.comment

        let creator = WorkoutProgramCreator(
            day: day,
            executionType: executionType,
            count: workoutResult.count,
            plannedCount: nil,
            trainings: trainings,
            comment: comment
        )

        let dayActivity = creator.dayActivity

        if let duration = workoutResult.duration {
            dayActivity.duration = duration
        }

        dailyActivitiesService.createDailyActivity(dayActivity, context: context)

        let reviewContext = ReviewContext(hadRecentError: false)
        if let reporter = reviewEventReporter {
            Task { @MainActor in
                await reporter.workoutCompletedSuccessfully(context: reviewContext)
            }
        }

        sendCurrentActivity(day: day)

        sendWorkoutDataToWatch(day: day)

        if let currentDay = currentDayCalculator?.currentDay, currentDay == day {
            let currentActivity = dailyActivitiesService.getActivityType(day: day, context: context)
            sendCurrentStatus(
                isAuthorized: true,
                currentDay: currentDay,
                currentActivity: currentActivity
            )
        }

        replyHandler?([:])
    }

    /// Обрабатывает команду получения текущей активности
    private func handleGetCurrentActivityCommand(
        data: [String: Any],
        context: ModelContext,
        replyHandler: (([String: Any]) -> Void)?
    ) {
        guard let day = data["day"] as? Int else {
            logger.error("Неверный формат данных для команды getCurrentActivity: \(data)")
            replyHandler?(["error": "Неверный формат данных"])
            return
        }

        let activityType = dailyActivitiesService.getActivityType(day: day, context: context)

        var reply: [String: Any] = [
            "command": Constants.WatchCommand.currentActivity.rawValue,
            "day": day
        ]

        if let activityType {
            reply["activityType"] = activityType.rawValue
        }

        replyHandler?(reply)
    }

    /// Обрабатывает команду получения данных тренировки
    private func handleGetWorkoutDataCommand(
        data: [String: Any],
        context: ModelContext,
        replyHandler: (([String: Any]) -> Void)?
    ) {
        guard let day = data["day"] as? Int else {
            logger.error("Неверный формат данных для команды getWorkoutData: \(data)")
            replyHandler?(["error": "Неверный формат данных"])
            return
        }

        let activity = dailyActivitiesService.getActivity(dayNumber: day, context: context)
        let workoutData: WorkoutData
        let executionCount: Int?
        let comment: String?

        if let existingActivity = activity, let existingWorkoutData = existingActivity.workoutData {
            // Используем существующую активность
            workoutData = existingWorkoutData
            executionCount = existingActivity.count
            comment = existingActivity.comment
        } else {
            // Если активность не найдена или не является тренировкой, создаем данные через WorkoutProgramCreator
            let baseCreator = WorkoutProgramCreator(day: day)

            // Получаем последнюю пройденную тренировку и подставляем данные
            let lastWorkout = dailyActivitiesService.getLastPassedNonTurboWorkoutActivity(context: context, currentDay: day)
            let creator: WorkoutProgramCreator

            if let lastWorkout {
                // Подставляем plannedCount, executionType и повторы из предыдущей тренировки
                logger.info("Используем данные из предыдущей тренировки (день \(lastWorkout.day))")
                creator = baseCreator.withData(from: lastWorkout)
            } else {
                // Fallback на дефолт
                logger.info("Предыдущая пройденная тренировка не найдена, используем дефолтные значения")
                creator = baseCreator
            }

            let newActivity = creator.dayActivity

            guard let newWorkoutData = newActivity.workoutData else {
                logger.error("Не удалось создать данные тренировки для дня \(day)")
                replyHandler?(["error": "Не удалось создать данные тренировки"])
                return
            }

            workoutData = newWorkoutData
            executionCount = nil
            comment = nil
        }

        let response = WorkoutDataResponse(
            workoutData: workoutData,
            executionCount: executionCount,
            comment: comment
        )

        let reply = response.makeMessageForWatch(command: Constants.WatchCommand.sendWorkoutData.rawValue) ?? [:]
        replyHandler?(reply)
    }

    /// Обрабатывает команду удаления активности
    private func handleDeleteActivityCommand(
        data: [String: Any],
        context: ModelContext,
        replyHandler: (([String: Any]) -> Void)?
    ) {
        guard let day = data["day"] as? Int else {
            logger.error("Неверный формат данных для команды deleteActivity: \(data)")
            replyHandler?(["error": "Неверный формат данных"])
            return
        }

        guard let activity = dailyActivitiesService.getActivity(dayNumber: day, context: context) else {
            // Активность не найдена - возвращаем пустой ответ
            replyHandler?([:])
            return
        }

        dailyActivitiesService.deleteDailyActivity(activity, context: context)

        // Отправляем обновленную активность на часы (nil после удаления)
        sendCurrentActivity(day: day)

        // Если удаленная активность относится к текущему дню, также отправляем статус
        if let currentDay = currentDayCalculator?.currentDay, currentDay == day {
            sendCurrentStatus(
                isAuthorized: true,
                currentDay: currentDay,
                currentActivity: nil
            )
        }

        replyHandler?([:])
    }

    /// Сбрасывает программу: удаляет все данные прохождения программы и начинает заново
    func resetProgram() async {
        let context = modelContainer.mainContext
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
        clearExtensionDates()
        JournalPagePersistence.clear(defaults: defaults)
        // Метод startNewRun сделает запрос к серверу через StatusClient.start(date:) и установит новую startDate
        let now = Date.now
        await startNewRun(appDate: now)
        rebuildCurrentDayCalculator(now: now)
        state = .idle
    }

    /// Добавляет дату продления календаря в локальное хранилище.
    /// - Parameters:
    ///   - date: Дата продления
    ///   - isSynced: Флаг синхронизации с сервером
    func addExtensionDate(_ date: Date = .now, isSynced: Bool = false) {
        let context = modelContainer.mainContext
        guard let user = fetchCurrentUser(context: context) else {
            logger.error("Не удалось добавить продление: пользователь не найден")
            return
        }

        let key = normalizedDateKey(date)
        let existingRecords = extensionRecords(for: user, context: context)
        if let existing = existingRecords.first(where: { normalizedDateKey($0.date) == key }) {
            var didUpdate = false
            if existing.shouldDelete {
                existing.shouldDelete = false
                didUpdate = true
            }
            if isSynced, !existing.isSynced {
                existing.isSynced = true
                didUpdate = true
            }
            if didUpdate {
                existing.lastModified = .now
            }
        } else {
            let record = CalendarExtensionRecord(
                date: dateFromKey(key),
                isSynced: isSynced,
                shouldDelete: false,
                lastModified: .now,
                user: user
            )
            context.insert(record)
        }

        do {
            try context.save()
        } catch {
            logger.error("Ошибка сохранения продления календаря: \(error.localizedDescription)")
        }

        refreshExtensionSnapshot(for: user, context: context)
        rebuildCurrentDayCalculator(now: .now)
    }

    /// Удаляет последнее продление календаря (внутренний rollback API).
    func removeLastExtensionDate() {
        let context = modelContainer.mainContext
        guard let user = fetchCurrentUser(context: context) else {
            logger.error("Не удалось удалить продление: пользователь не найден")
            return
        }

        let records = extensionRecords(for: user, context: context).sorted { $0.date > $1.date }
        guard let lastRecord = records.first else {
            return
        }

        context.delete(lastRecord)
        do {
            try context.save()
        } catch {
            logger.error("Ошибка удаления последнего продления: \(error.localizedDescription)")
        }

        refreshExtensionSnapshot(for: user, context: context)
        rebuildCurrentDayCalculator(now: .now)
    }

    /// Полностью очищает локальные продления календаря.
    ///
    /// При logout/reset используется физическое удаление, а не soft-delete.
    func clearExtensionDates() {
        let context = modelContainer.mainContext
        let currentUser = fetchCurrentUser(context: context)
        let allRecords = (try? context.fetch(FetchDescriptor<CalendarExtensionRecord>())) ?? []
        let recordsToDelete: [CalendarExtensionRecord] = if let currentUser {
            allRecords.filter { $0.user?.id == currentUser.id }
        } else {
            allRecords
        }

        recordsToDelete.forEach { context.delete($0) }

        do {
            try context.save()
        } catch {
            logger.error("Ошибка очистки продлений: \(error.localizedDescription)")
        }

        refreshExtensionSnapshot(for: currentUser, context: context)
        rebuildCurrentDayCalculator(now: .now)
    }

    /// Продлевает календарь на 100 дней при доступной кнопке продления.
    ///
    /// Локальное сохранение выполняется первым шагом. Сетевой sync запускается асинхронно для online-пользователя.
    func extendCalendar() {
        guard let calculator = currentDayCalculator else {
            logger.error("Не удалось продлить календарь: currentDayCalculator не инициализирован")
            return
        }

        guard calculator.shouldShowExtensionButton else {
            logger.debug("Продление пропущено: кнопка продления недоступна")
            return
        }

        let context = modelContainer.mainContext
        guard let user = fetchCurrentUser(context: context) else {
            logger.error("Не удалось продлить календарь: пользователь не найден")
            return
        }

        addExtensionDate(.now, isSynced: user.isOfflineOnly)

        let updatedCurrentDay = currentDayCalculator?.currentDay
        let updatedCurrentActivity = updatedCurrentDay.map {
            dailyActivitiesService.getActivityType(day: $0, context: context)
        } ?? nil
        sendCurrentStatus(
            isAuthorized: true,
            currentDay: updatedCurrentDay,
            currentActivity: updatedCurrentActivity
        )

        guard !user.isOfflineOnly else {
            return
        }

        Task { @MainActor in
            await syncCalendarPurchasesAfterLocalExtend(for: user, context: context, now: .now)
        }
    }

    #if DEBUG
    /// Устанавливает флаг didLoadInitialData для тестирования
    /// - Parameter value: Значение флага
    func setDidLoadInitialDataForDebug(_ value: Bool) {
        didLoadInitialData = value
    }

    var debugPickerMaxDay: Int {
        max(currentDayCalculator?.totalDays ?? DayCalculator.baseProgramDays, DayCalculator.baseProgramDays)
    }

    /// Устанавливает текущий день программы для дебага и тестирования.
    /// - Parameters:
    ///   - day: Номер дня в диапазоне `1...10100`
    ///   - extensionCount: Явное количество продлений. Если `nil`, вычисляется автоматически из `day`.
    func setCurrentDayForDebug(_ day: Int, extensionCount: Int? = nil) {
        let maxDebugDay = DayCalculator.baseProgramDays + DayCalculator.maxExtensionCount * DayCalculator.extensionBlockDays
        guard (1 ... maxDebugDay).contains(day) else {
            logger.error("Попытка установить невалидный день: \(day). День должен быть от 1 до \(maxDebugDay)")
            return
        }

        let resolvedExtensionCount = if let extensionCount {
            min(max(extensionCount, 0), DayCalculator.maxExtensionCount)
        } else {
            min(DayCalculator.maxExtensionCount, max(0, (day - 1) / DayCalculator.extensionBlockDays))
        }

        let context = modelContainer.mainContext

        let now = Date.now
        let daysToSubtract = day - 1
        guard let newStartDate = Calendar.current.date(byAdding: .day, value: -daysToSubtract, to: now) else {
            logger.error("Не удалось вычислить новую дату старта для дня \(day)")
            return
        }

        if let user = fetchCurrentUser(context: context) {
            replaceExtensionDatesForDebug(
                count: resolvedExtensionCount,
                user: user,
                context: context
            )
        } else {
            logger.warning("Debug-режим без пользователя: extension snapshot обновлён только в памяти")
            if resolvedExtensionCount > 0 {
                extensionDateKeysSnapshot = Set((1 ... resolvedExtensionCount).map { CalendarExtensionDateKey($0) })
            } else {
                extensionDateKeysSnapshot = []
            }
        }

        logger
            .info(
                "Установка дня \(day) для дебага с extensionCount \(resolvedExtensionCount). Новая дата старта: \(newStartDate.description)"
            )
        startDate = newStartDate
        rebuildCurrentDayCalculator(now: now)

        // Отправляем обновленный статус на часы
        let updatedCurrentDay = currentDayCalculator?.currentDay
        let updatedCurrentActivity = updatedCurrentDay.map {
            dailyActivitiesService.getActivityType(day: $0, context: modelContainer.mainContext)
        } ?? nil
        sendCurrentStatus(
            isAuthorized: true,
            currentDay: updatedCurrentDay,
            currentActivity: updatedCurrentActivity
        )
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
    typealias CalendarExtensionDateKey = Int64

    func fetchCurrentUser(context: ModelContext) -> User? {
        (try? context.fetch(FetchDescriptor<User>()).first)
    }

    func extensionRecords(for user: User, context: ModelContext) -> [CalendarExtensionRecord] {
        let allRecords = (try? context.fetch(FetchDescriptor<CalendarExtensionRecord>())) ?? []
        return allRecords
            .filter { $0.user?.id == user.id }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date {
                    return lhs.date < rhs.date
                }
                if lhs.lastModified != rhs.lastModified {
                    return lhs.lastModified < rhs.lastModified
                }
                if lhs.isSynced != rhs.isSynced {
                    return lhs.isSynced && !rhs.isSynced
                }
                return false
            }
    }

    func normalizedDateKey(_ date: Date) -> CalendarExtensionDateKey {
        CalendarExtensionDateKey(date.timeIntervalSince1970.rounded(.towardZero))
    }

    func dateFromKey(_ key: CalendarExtensionDateKey) -> Date {
        Date(timeIntervalSince1970: TimeInterval(key))
    }

    func refreshExtensionSnapshot(for user: User?, context: ModelContext) {
        guard let user else {
            extensionDateKeysSnapshot = []
            return
        }

        let keys = extensionRecords(for: user, context: context)
            .map { normalizedDateKey($0.date) }
        extensionDateKeysSnapshot = Set(keys)
    }

    func rebuildCurrentDayCalculator(now: Date = .now) {
        currentDayCalculator = .init(startDate, now, extensionCount: extensionDateKeysSnapshot.count)
    }

    #if DEBUG
    func replaceExtensionDatesForDebug(count: Int, user: User, context: ModelContext) {
        let currentRecords = extensionRecords(for: user, context: context)
        currentRecords.forEach { context.delete($0) }

        guard count > 0 else {
            do {
                try context.save()
            } catch {
                logger.error("Ошибка очистки продлений при debug-установке дня: \(error.localizedDescription)")
            }
            refreshExtensionSnapshot(for: user, context: context)
            return
        }

        for index in 0 ..< count {
            let debugDate = dateFromKey(CalendarExtensionDateKey(index + 1))
            let record = CalendarExtensionRecord(
                date: debugDate,
                isSynced: true,
                shouldDelete: false,
                lastModified: .now,
                user: user
            )
            context.insert(record)
        }

        do {
            try context.save()
        } catch {
            logger.error("Ошибка сохранения debug-продлений: \(error.localizedDescription)")
        }
        refreshExtensionSnapshot(for: user, context: context)
    }
    #endif

    func parseCalendarDate(_ rawValue: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: rawValue) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: rawValue) {
            return date
        }

        let serverDateFormatter = DateFormatter()
        serverDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        serverDateFormatter.dateFormat = DateFormatterService.DateFormat.serverDateTimeSec.rawValue
        serverDateFormatter.timeZone = TimeZone(identifier: "Europe/Moscow")
        if let date = serverDateFormatter.date(from: rawValue) {
            return date
        }

        logger.error("Пропуск невалидной даты продления из ответа сервера: \(rawValue)")
        return nil
    }

    @discardableResult
    func fetchAndMergeServerPurchases(for user: User, context: ModelContext) async -> Bool {
        guard let purchasesClient else {
            return false
        }

        do {
            let response = try await purchasesClient.getPurchases()
            let serverDates = response.calendars.compactMap(parseCalendarDate(_:))
            mergeServerPurchases(serverDates, for: user, context: context)
            return true
        } catch {
            logger.error("Ошибка получения покупок календаря: \(error.localizedDescription)")
            return false
        }
    }

    func mergeServerPurchases(_ serverDates: [Date], for user: User, context: ModelContext) {
        let localRecords = extensionRecords(for: user, context: context)
        var recordsByKey: [CalendarExtensionDateKey: [CalendarExtensionRecord]] = [:]

        for record in localRecords {
            let key = normalizedDateKey(record.date)
            recordsByKey[key, default: []].append(record)
        }

        // Удаляем локальные дубли и оставляем одну запись на ключ даты.
        for records in recordsByKey.values where records.count > 1 {
            let sortedRecords = records.sorted { lhs, rhs in
                if lhs.isSynced != rhs.isSynced {
                    return lhs.isSynced && !rhs.isSynced
                }
                if lhs.lastModified != rhs.lastModified {
                    return lhs.lastModified > rhs.lastModified
                }
                if lhs.date != rhs.date {
                    return lhs.date > rhs.date
                }
                return false
            }
            guard let keeper = sortedRecords.first else { continue }
            let containsSynced = records.contains(where: \.isSynced)
            if containsSynced {
                keeper.isSynced = true
                keeper.shouldDelete = false
                keeper.lastModified = .now
            }
            for duplicate in sortedRecords.dropFirst() {
                context.delete(duplicate)
            }
        }

        // Перечитываем дубли после удаления, чтобы корректно дообъединить серверные даты.
        let compactedLocalRecords = extensionRecords(for: user, context: context)
        var compactedByKey: [CalendarExtensionDateKey: CalendarExtensionRecord] = [:]
        for record in compactedLocalRecords {
            compactedByKey[normalizedDateKey(record.date)] = record
        }

        for serverDate in serverDates {
            let key = normalizedDateKey(serverDate)
            if let existing = compactedByKey[key] {
                if !existing.isSynced {
                    existing.isSynced = true
                    existing.shouldDelete = false
                    existing.lastModified = .now
                }
                continue
            }

            let newRecord = CalendarExtensionRecord(
                date: dateFromKey(key),
                isSynced: true,
                shouldDelete: false,
                lastModified: .now,
                user: user
            )
            context.insert(newRecord)
            compactedByKey[key] = newRecord
        }

        do {
            try context.save()
        } catch {
            logger.error("Ошибка сохранения merge покупок календаря: \(error.localizedDescription)")
        }

        refreshExtensionSnapshot(for: user, context: context)
    }

    @discardableResult
    func retryUnsyncedPurchases(for user: User, context: ModelContext) async -> Bool {
        guard let purchasesClient else {
            return false
        }

        let unsyncedRecords = extensionRecords(for: user, context: context)
            .filter { !$0.isSynced && !$0.shouldDelete }
            .sorted { $0.date < $1.date }

        guard !unsyncedRecords.isEmpty else {
            return false
        }

        var didSyncAny = false
        for record in unsyncedRecords {
            do {
                _ = try await purchasesClient.postCalendarPurchase(date: record.date)
                record.isSynced = true
                record.shouldDelete = false
                record.lastModified = .now
                didSyncAny = true
            } catch {
                logger.error("Ошибка отправки покупки продления: \(error.localizedDescription)")
            }
        }

        if didSyncAny {
            do {
                try context.save()
            } catch {
                logger.error("Ошибка сохранения retry продлений: \(error.localizedDescription)")
            }
        }

        refreshExtensionSnapshot(for: user, context: context)
        return didSyncAny
    }

    func syncCalendarPurchasesOnGetStatus(for user: User, context: ModelContext, now: Date) async {
        guard !user.isOfflineOnly else {
            refreshExtensionSnapshot(for: user, context: context)
            rebuildCurrentDayCalculator(now: now)
            return
        }

        _ = await fetchAndMergeServerPurchases(for: user, context: context)
        let didRetry = await retryUnsyncedPurchases(for: user, context: context)
        if didRetry {
            _ = await fetchAndMergeServerPurchases(for: user, context: context)
        }

        refreshExtensionSnapshot(for: user, context: context)
        rebuildCurrentDayCalculator(now: now)
    }

    func syncCalendarPurchasesOnSyncJournal(for user: User, context: ModelContext, now: Date) async {
        guard !user.isOfflineOnly else {
            refreshExtensionSnapshot(for: user, context: context)
            rebuildCurrentDayCalculator(now: now)
            return
        }

        _ = await fetchAndMergeServerPurchases(for: user, context: context)
        let didRetry = await retryUnsyncedPurchases(for: user, context: context)
        if didRetry {
            _ = await fetchAndMergeServerPurchases(for: user, context: context)
        }

        refreshExtensionSnapshot(for: user, context: context)
        rebuildCurrentDayCalculator(now: now)
    }

    func syncCalendarPurchasesAfterLocalExtend(for user: User, context: ModelContext, now: Date) async {
        guard !user.isOfflineOnly else {
            refreshExtensionSnapshot(for: user, context: context)
            rebuildCurrentDayCalculator(now: now)
            return
        }

        let didRetry = await retryUnsyncedPurchases(for: user, context: context)
        if didRetry {
            _ = await fetchAndMergeServerPurchases(for: user, context: context)
        }

        refreshExtensionSnapshot(for: user, context: context)
        rebuildCurrentDayCalculator(now: now)
    }

    func syncJournalAndProgress() async {
        let context = modelContainer.mainContext
        let user = try? context.fetch(FetchDescriptor<User>()).first
        if let user, user.isOfflineOnly {
            return
        }

        guard !isJournalSyncInProgress else { return }
        isJournalSyncInProgress = true
        defer { isJournalSyncInProgress = false }
        state = .init(didLoadInitialData: didLoadInitialData)

        let startDate = Date.now
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

        if let user {
            await syncCalendarPurchasesOnSyncJournal(for: user, context: context, now: .now)
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

// MARK: - WCSessionDelegate

nonisolated extension StatusManager: WCSessionDelegate {
    func sessionDidBecomeInactive(_: WCSession) {}

    func sessionDidDeactivate(_: WCSession) {}

    nonisolated func session(_: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            logger.error("Ошибка активации WCSession: \(error.localizedDescription)")
        } else {
            logger.info("WCSession активирована с состоянием: \(activationState.rawValue)")
            // Отправляем applicationContext при активации, если пользователь авторизован
            Task { @MainActor in
                sendApplicationContextOnActivation()
            }
        }
    }

    nonisolated func session(_: WCSession, didReceiveMessage message: [String: Any]) {
        logger.info("Получено сообщение от часов: \(message)")
        nonisolated(unsafe) let messageCopy = message
        Task { @MainActor in
            handleWatchCommand(messageCopy)
        }
    }

    nonisolated func session(_: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("Получено сообщение с ответом от часов: \(message)")
        nonisolated(unsafe) let messageCopy = message
        nonisolated(unsafe) let replyHandlerCopy = replyHandler
        Task { @MainActor in
            handleWatchCommand(messageCopy, replyHandler: replyHandlerCopy)
        }
    }
}
