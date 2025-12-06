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
    @ObservationIgnored private let connectivityService: any WatchConnectivityServiceProtocol
    @ObservationIgnored private let appGroupHelper: any WatchAppGroupHelperProtocol

    var isLoading = false
    var error: Error?
    var currentDay: Int?
    var currentActivity: DayActivityType?
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

        guard let day = currentDayValue else {
            logger.warning("Не удалось вычислить текущий день: startDate отсутствует в App Group")
            return
        }

        do {
            let activity = try await connectivityService.requestCurrentActivity(day: day)
            currentActivity = activity
            if let activity {
                logger.info("Загружена активность дня \(day): \(activity.rawValue)")
            } else {
                logger.info("Активность дня \(day) не установлена")
            }
        } catch {
            logger.error("Ошибка загрузки активности дня \(day): \(error.localizedDescription)")
            self.error = error
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
            let workoutData = try await connectivityService.requestWorkoutData(day: day)
            logger.info("Получены данные тренировки для дня \(day)")
            return workoutData
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
