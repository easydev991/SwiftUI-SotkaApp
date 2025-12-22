import Foundation
import Observation
import OSLog

/// ViewModel для главного экрана Apple Watch
@MainActor
@Observable
final class HomeViewModel {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaWatch",
        category: String(describing: HomeViewModel.self)
    )

    @ObservationIgnored private let authService: any WatchAuthServiceProtocol
    @ObservationIgnored let connectivityService: any WatchConnectivityServiceProtocol

    private(set) var isLoading = false
    private var lastLoggedActivityState: (day: Int, hasActivity: Bool)?
    private(set) var error: Error?
    private(set) var currentDay: Int?
    private(set) var currentActivity: DayActivityType?
    private(set) var workoutData: WorkoutData?
    private(set) var workoutExecutionCount: Int?
    private(set) var workoutComment: String?
    var isAuthorized: Bool {
        authService.isAuthorized
    }

    /// Инициализатор
    /// - Parameters:
    ///   - authService: Сервис авторизации
    ///   - connectivityService: Сервис связи с iPhone
    init(
        authService: any WatchAuthServiceProtocol,
        connectivityService: any WatchConnectivityServiceProtocol
    ) {
        self.authService = authService
        self.connectivityService = connectivityService

        // Подписываемся на изменения currentDay в WatchConnectivityService
        if let watchConnectivityService = connectivityService as? WatchConnectivityService {
            watchConnectivityService.onCurrentDayChanged = { [weak self] in
                self?.updateCurrentDayFromConnectivity()
            }
            // Подписываемся на изменения currentActivity в WatchConnectivityService
            watchConnectivityService.onCurrentActivityChanged = { [weak self] activity in
                self?.updateCurrentActivityFromConnectivity(activity)
            }
            // Подписываемся на получение данных тренировки
            watchConnectivityService.onWorkoutDataReceived = { [weak self] response in
                self?.updateWorkoutDataFromConnectivity(response)
            }
        }
    }

    /// Загрузка данных (проверка авторизации, получение текущего дня, запрос активности)
    func loadData() async {
        guard !isLoading else {
            logger.debug("loadData уже выполняется, пропускаем параллельный вызов")
            return
        }

        isLoading = true
        error = nil

        defer {
            isLoading = false
        }

        guard let currentDayValue = ensureAuthorizedAndGetCurrentDay() else {
            return
        }

        // Используем currentActivity из WatchConnectivityService, если он уже есть (из applicationContext)
        // Это избегает лишних запросов к iPhone
        if let activityFromContext = connectivityService.currentActivity {
            logger.info("Используем currentActivity из applicationContext: \(activityFromContext.rawValue)")
            await processActivityFromContext(activityFromContext, day: currentDayValue)
        } else {
            // Если currentActivity нет в applicationContext, запрашиваем с iPhone
            do {
                let activity = try await requestActivityFromPhone(day: currentDayValue)
                await processActivityFromContext(activity, day: currentDayValue)
            } catch {
                logger.error("Ошибка загрузки активности дня \(currentDayValue): \(error.localizedDescription)")
                self.error = error
                clearWorkoutData()
            }
        }
    }

    /// Проверка статуса авторизации при активации приложения
    func checkAuthStatusOnActivation() async {
        let wasAuthorized = isAuthorized
        let newAuthStatus = authService.checkAuthStatus()

        if wasAuthorized != newAuthStatus {
            logger.info("Статус авторизации изменился при активации: \(newAuthStatus)")
        }

        // Обновляем currentDay из WatchConnectivityService при активации
        updateCurrentDayFromConnectivity()
    }

    /// Обновление currentDay из WatchConnectivityService
    /// Вызывается при получении команды PHONE_COMMAND_CURRENT_DAY от iPhone
    func updateCurrentDayFromConnectivity() {
        let newCurrentDay = connectivityService.currentDay
        if newCurrentDay != currentDay {
            logger.info("Обновление currentDay из WatchConnectivityService: \(newCurrentDay ?? 0)")
            currentDay = newCurrentDay
            // Если currentDay изменился, перезагружаем данные
            if newCurrentDay != nil {
                Task {
                    await loadData()
                }
            }
        }
    }

    /// Обновление currentActivity из WatchConnectivityService
    /// Вызывается при получении applicationContext с currentActivity от iPhone
    /// - Parameter activity: Новая активность или `nil` если активность удалена
    func updateCurrentActivityFromConnectivity(_ activity: DayActivityType?) {
        if activity != currentActivity {
            let activityString = activity.map { String($0.rawValue) } ?? "nil"
            logger.info("Обновление currentActivity из WatchConnectivityService: \(activityString)")
            currentActivity = activity

            // Если активность изменилась на .workout, загружаем данные тренировки
            if let activity, activity == .workout, let day = currentDay {
                Task {
                    await loadWorkoutData(day: day)
                }
            } else {
                // Если активность изменилась на другой тип или удалена, очищаем данные тренировки
                clearWorkoutData()
            }
        }
    }

    /// Загрузка данных тренировки для указанного дня
    /// - Parameter day: Номер дня программы
    private func loadWorkoutData(day: Int) async {
        isLoading = true
        error = nil

        defer {
            isLoading = false
        }

        do {
            let response = try await connectivityService.requestWorkoutData(day: day)
            workoutData = response.workoutData
            workoutExecutionCount = response.executionCount
            workoutComment = response.comment
            logger.info("Загружены данные тренировки для дня \(day) из applicationContext")
        } catch {
            logger.error("Ошибка загрузки данных тренировки дня \(day): \(error.localizedDescription)")
            // Не устанавливаем error здесь, чтобы не перезаписать ошибку загрузки активности
            // Не очищаем данные тренировки при ошибке - оставляем старые данные
        }
    }

    /// Выбор типа активности (отправка на iPhone)
    /// - Parameter activityType: Тип активности
    func selectActivity(_ activityType: DayActivityType) async {
        guard let day = currentDay else {
            logger.warning("Попытка выбрать активность без текущего дня")
            error = WatchConnectivityError.sessionUnavailable
            return
        }

        isLoading = true
        error = nil

        defer {
            isLoading = false
        }

        do {
            try await connectivityService.sendActivityType(day: day, activityType: activityType)
            currentActivity = activityType
            logger.info("Активность \(activityType.rawValue) успешно отправлена на iPhone для дня \(day)")
        } catch {
            logger.error("Ошибка отправки активности на iPhone: \(error.localizedDescription)")
            self.error = error
        }
    }

    /// Начало тренировки (запрос данных тренировки)
    /// - Returns: Данные тренировки или `nil` если произошла ошибка
    func startWorkout() async -> WorkoutData? {
        guard let day = currentDay else {
            logger.warning("Попытка начать тренировку без текущего дня")
            error = WatchConnectivityError.sessionUnavailable
            return nil
        }

        isLoading = true
        error = nil

        defer {
            isLoading = false
        }

        do {
            let response = try await connectivityService.requestWorkoutData(day: day)
            logger.info("Получены данные тренировки для дня \(day)")
            return response.workoutData
        } catch {
            logger.error("Ошибка запроса данных тренировки: \(error.localizedDescription)")
            self.error = error
            return nil
        }
    }

    /// Обновление данных тренировки из WatchConnectivityService
    /// - Parameter response: Полные данные тренировки с iPhone
    func updateWorkoutDataFromConnectivity(_ response: WorkoutDataResponse) {
        logger.info("Обновление данных тренировки из WatchConnectivityService для дня \(response.workoutData.day)")
        workoutData = response.workoutData
        workoutExecutionCount = response.executionCount
        workoutComment = response.comment
    }

    /// Удаление активности дня (отправка на iPhone)
    /// - Parameter day: Номер дня программы
    func deleteActivity(day: Int) async {
        isLoading = true
        error = nil

        defer {
            isLoading = false
        }

        do {
            try await connectivityService.deleteActivity(day: day)
            // После успешного удаления обновляем текущую активность
            if day == currentDay {
                currentActivity = nil
            }
            logger.info("Активность дня \(day) успешно удалена")
        } catch {
            logger.error("Ошибка удаления активности дня \(day): \(error.localizedDescription)")
            self.error = error
        }
    }
}

private extension HomeViewModel {
    func clearWorkoutData() {
        workoutData = nil
        workoutExecutionCount = nil
        workoutComment = nil
    }

    /// Проверка авторизации и получение текущего дня
    /// - Returns: Номер текущего дня или `nil` если пользователь не авторизован или день не получен
    func ensureAuthorizedAndGetCurrentDay() -> Int? {
        guard authService.checkAuthStatus() else {
            logger.info("Пользователь не авторизован, пропускаем загрузку данных")
            return nil
        }

        // Получаем currentDay из WatchConnectivityService (обновляется при получении команды от iPhone)
        let currentDayValue = connectivityService.currentDay
        currentDay = currentDayValue

        guard let currentDayValue else {
            logger.warning("Текущий день еще не получен от iPhone, ожидаем команду PHONE_COMMAND_CURRENT_DAY")
            error = WatchConnectivityError.sessionUnavailable
            return nil
        }

        return currentDayValue
    }

    /// Обработка активности из applicationContext или запрошенной с iPhone
    /// - Parameters:
    ///   - activity: Активность или `nil` если активность не установлена
    ///   - day: Номер дня программы
    func processActivityFromContext(_ activity: DayActivityType?, day: Int) async {
        currentActivity = activity

        if let activity {
            if activity == .workout {
                await loadWorkoutDataIfNeeded(day: day, activity: activity)
            } else {
                let shouldLog = lastLoggedActivityState?.day != day || lastLoggedActivityState?.hasActivity != true
                if shouldLog {
                    logger.info("Активность дня \(day) не является тренировкой")
                    lastLoggedActivityState = (day: day, hasActivity: true)
                }
                clearWorkoutData()
            }
        } else {
            let shouldLog = lastLoggedActivityState?.day != day || lastLoggedActivityState?.hasActivity != false
            if shouldLog {
                logger.info("Активность дня \(day) не установлена")
                lastLoggedActivityState = (day: day, hasActivity: false)
            }
            clearWorkoutData()
        }
    }

    /// Запрос текущей активности с iPhone
    /// - Parameter day: Номер дня программы
    /// - Returns: Текущая активность или `nil` если активность не установлена
    /// - Throws: Ошибка при запросе активности
    func requestActivityFromPhone(day: Int) async throws -> DayActivityType? {
        let activity = try await connectivityService.requestCurrentActivity(day: day)

        if let activity {
            logger.info("Загружена активность дня \(day): \(activity.rawValue)")
            lastLoggedActivityState = (day: day, hasActivity: true)
        }

        return activity
    }

    /// Загрузка данных тренировки, если активность типа workout
    /// - Parameters:
    ///   - day: Номер дня программы
    ///   - activity: Тип активности
    func loadWorkoutDataIfNeeded(day: Int, activity: DayActivityType) async {
        guard activity == .workout else {
            return
        }

        do {
            let response = try await connectivityService.requestWorkoutData(day: day)
            workoutData = response.workoutData
            workoutExecutionCount = response.executionCount
            workoutComment = response.comment
            logger.info("Загружены данные тренировки для дня \(day)")
            lastLoggedActivityState = (day: day, hasActivity: true)
        } catch {
            logger.error("Ошибка загрузки данных тренировки дня \(day): \(error.localizedDescription)")
            // Не устанавливаем error здесь, чтобы не перезаписать ошибку загрузки активности
            // Не очищаем данные тренировки при ошибке - оставляем старые данные
        }
    }
}
