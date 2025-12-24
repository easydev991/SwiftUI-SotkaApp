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
    @ObservationIgnored private var isJournalSyncInProgress = false
    @ObservationIgnored private(set) var syncReadPostsTask: Task<Void, Error>?
    @ObservationIgnored private let sessionProtocol: WCSessionProtocol?
    @ObservationIgnored let modelContainer: ModelContainer
    private let statusClient: StatusClient

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
        modelContainer: ModelContainer,
        userDefaults: UserDefaults? = nil,
        watchConnectivitySessionProtocol: WCSessionProtocol? = nil
    ) {
        self.customExercisesService = customExercisesService
        self.infopostsService = infopostsService
        self.progressSyncService = progressSyncService
        self.dailyActivitiesService = dailyActivitiesService
        self.statusClient = statusClient
        self.modelContainer = modelContainer
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
            currentDayCalculator = .init(startDate, now)

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

    func start(appDate: Date?) async {
        await startNewRun(appDate: appDate)
        await syncJournalAndProgress()
    }

    func syncWithSiteDate(siteDate: Date) async {
        startDate = siteDate
        let now = Date.now
        currentDayCalculator = .init(startDate, now)
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
            currentActivity: currentActivity
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
            currentActivity: currentActivity
        )
        let applicationContext = statusMessage.applicationContext

        sessionProtocol.updateApplicationContextOnWatch(applicationContext)
        logger
            .debug(
                "ApplicationContext обновлен для часов: isAuthorized=\(isAuthorized), currentDay=\(currentDay?.description ?? "nil"), currentActivity=\(currentActivity?.rawValue.description ?? "nil")"
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
            currentActivity: activityType
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

        // Создаем WorkoutProgramCreator для дня
        let creator = WorkoutProgramCreator(
            day: day,
            executionType: executionType,
            count: workoutResult.count,
            plannedCount: nil, // plannedCount будет вычислен автоматически
            trainings: trainings, // Используем переданные trainings
            comment: comment
        )

        // Получаем DayActivity из creator
        let dayActivity = creator.dayActivity

        // Устанавливаем duration из результата тренировки
        if let duration = workoutResult.duration {
            dayActivity.duration = duration
        }

        // Сохраняем активность через DailyActivitiesService
        dailyActivitiesService.createDailyActivity(dayActivity, context: context)

        // Отправляем обновленную активность на часы
        sendCurrentActivity(day: day)

        // Отправляем обновленные данные тренировки на часы
        sendWorkoutDataToWatch(day: day)

        // Если сохраненная тренировка относится к текущему дню, также отправляем статус
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
            let creator = WorkoutProgramCreator(day: day)
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
        // Сохраняем изменения перед вызовом startNewRun
        try? context.save()
        // Метод startNewRun сделает запрос к серверу через StatusClient.start(date:) и установит новую startDate
        let now = Date.now
        await startNewRun(appDate: now)
        currentDayCalculator = .init(startDate, now)
        state = .idle
    }

    #if DEBUG
    /// Устанавливает флаг didLoadInitialData для тестирования
    /// - Parameter value: Значение флага
    func setDidLoadInitialDataForDebug(_ value: Bool) {
        didLoadInitialData = value
    }

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
    func syncJournalAndProgress() async {
        let context = modelContainer.mainContext
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
