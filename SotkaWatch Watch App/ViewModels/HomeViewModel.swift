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
    @ObservationIgnored let appGroupHelper: any WatchAppGroupHelperProtocol

    private(set) var isLoading = false
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
    ///   - appGroupHelper: Хелпер для чтения данных из App Group UserDefaults (по умолчанию создается новый экземпляр)
    init(
        authService: any WatchAuthServiceProtocol,
        connectivityService: any WatchConnectivityServiceProtocol,
        appGroupHelper: (any WatchAppGroupHelperProtocol)? = nil
    ) {
        self.authService = authService
        self.connectivityService = connectivityService
        self.appGroupHelper = appGroupHelper ?? WatchAppGroupHelper()
    }

    /// Загрузка данных (проверка авторизации, вычисление текущего дня, запрос активности)
    func loadData() async {
        isLoading = true
        error = nil

        defer {
            isLoading = false
        }

        guard authService.checkAuthStatus() else {
            logger.info("Пользователь не авторизован, пропускаем загрузку данных")
            return
        }

        let currentDayValue = appGroupHelper.currentDay
        currentDay = currentDayValue

        guard let currentDayValue else {
            logger.warning("Не удалось вычислить текущий день: startDate отсутствует в App Group")
            return
        }

        do {
            let activity = try await connectivityService.requestCurrentActivity(day: currentDayValue)
            currentActivity = activity

            if let activity, activity == .workout {
                logger.info("Загружена активность дня \(currentDayValue): \(activity.rawValue)")
                // Загружаем данные тренировки, если активность типа .workout
                do {
                    let response = try await connectivityService.requestWorkoutData(day: currentDayValue)
                    workoutData = response.workoutData
                    workoutExecutionCount = response.executionCount
                    workoutComment = response.comment
                    logger.info("Загружены данные тренировки для дня \(currentDayValue)")
                } catch {
                    logger.error("Ошибка загрузки данных тренировки дня \(currentDayValue): \(error.localizedDescription)")
                    // Не устанавливаем error здесь, чтобы не перезаписать ошибку загрузки активности
                    // Не очищаем данные тренировки при ошибке - оставляем старые данные
                }
            } else {
                logger.info("Активность дня \(currentDayValue) не установлена")
                clearWorkoutData()
            }
        } catch {
            logger.error("Ошибка загрузки активности дня \(currentDayValue): \(error.localizedDescription)")
            self.error = error
            clearWorkoutData()
        }
    }

    /// Проверка статуса авторизации при активации приложения
    func checkAuthStatusOnActivation() async {
        let wasAuthorized = isAuthorized
        let newAuthStatus = authService.checkAuthStatus()

        if wasAuthorized != newAuthStatus {
            logger.info("Статус авторизации изменился при активации: \(newAuthStatus)")
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
}
