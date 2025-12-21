import Foundation
import OSLog
import WatchConnectivity

/// Сервис для связи с iPhone через WatchConnectivity
@MainActor
final class WatchConnectivityService: NSObject {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaWatch",
        category: String(describing: WatchConnectivityService.self)
    )

    private let authService: WatchAuthService
    private let sessionProtocol: WatchSessionProtocol?

    /// Последние обработанные данные статуса для дедупликации
    private var lastProcessedStatus: (isAuthorized: Bool, currentDay: Int?, currentActivity: DayActivityType?)?

    /// Текущий день программы (обновляется при получении команды PHONE_COMMAND_CURRENT_DAY или applicationContext)
    private(set) var currentDay: Int? {
        didSet {
            if currentDay != oldValue {
                onCurrentDayChanged?()
            }
        }
    }

    /// Callback для уведомления об изменении currentDay
    var onCurrentDayChanged: (() -> Void)?

    /// Текущая активность дня (обновляется при получении applicationContext)
    private(set) var currentActivity: DayActivityType? {
        didSet {
            if currentActivity != oldValue {
                onCurrentActivityChanged?(currentActivity)
            }
        }
    }

    /// Callback для уведомления об изменении currentActivity
    /// - Parameter activity: Новая активность или `nil` если активность удалена
    var onCurrentActivityChanged: ((DayActivityType?) -> Void)?

    /// Callback для уведомления о получении данных тренировки
    /// - Parameter response: Полные данные тренировки с iPhone
    var onWorkoutDataReceived: ((WorkoutDataResponse) -> Void)?

    /// Реальная сессия для делегата (только для WCSession, не для моков)
    var session: WCSession? {
        sessionProtocol as? WCSession
    }

    /// Инициализатор
    /// - Parameters:
    ///   - authService: Сервис авторизации для обновления статуса авторизации
    ///   - sessionProtocol: Протокол сессии для тестирования. Если `nil`, используется `WCSession.default`
    init(
        authService: WatchAuthService,
        sessionProtocol: WatchSessionProtocol? = nil
    ) {
        self.authService = authService
        if let sessionProtocol {
            self.sessionProtocol = sessionProtocol
        } else if WCSession.isSupported() {
            self.sessionProtocol = WCSession.default
        } else {
            self.sessionProtocol = nil
            logger.warning("WCSession не поддерживается на этом устройстве")
        }
        super.init()
        if let session {
            // Устанавливаем делегат только для реальной сессии
            session.delegate = self
            session.activate()
        } else {
            // Для моков активируем через протокол
            sessionProtocol?.activate()
        }
    }

    /// Отправка типа активности на iPhone
    /// - Parameters:
    ///   - day: Номер дня программы
    ///   - activityType: Тип активности
    func sendActivityType(day: Int, activityType: DayActivityType) async throws {
        guard let sessionProtocol, sessionProtocol.isReachable else {
            throw WatchConnectivityError.sessionUnavailable
        }

        let message: [String: Any] = [
            "command": Constants.WatchCommand.setActivity.rawValue,
            "day": day,
            "activityType": activityType.rawValue
        ]

        logger.info("Отправка типа активности на iPhone: день \(day), тип \(activityType.rawValue)")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionProtocol.sendMessage(message) { _ in
                self.logger.info("Тип активности успешно отправлен на iPhone")
                continuation.resume()
            } errorHandler: { error in
                self.logger.error("Ошибка отправки типа активности: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }

    /// Отправка результата тренировки на iPhone
    /// - Parameters:
    ///   - day: Номер дня программы
    ///   - result: Результат тренировки
    ///   - executionType: Тип выполнения упражнений
    ///   - trainings: Список упражнений тренировки
    ///   - comment: Комментарий к тренировке (опционально)
    func sendWorkoutResult(
        day: Int,
        result: WorkoutResult,
        executionType: ExerciseExecutionType,
        trainings: [WorkoutPreviewTraining],
        comment: String?
    ) async throws {
        guard let sessionProtocol, sessionProtocol.isReachable else {
            throw WatchConnectivityError.sessionUnavailable
        }

        let encoder = JSONEncoder()
        let resultData = try encoder.encode(result)
        guard let resultJSON = try JSONSerialization.jsonObject(with: resultData) as? [String: Any] else {
            throw WatchConnectivityError.serializationError
        }

        let trainingsData = try encoder.encode(trainings)
        guard let trainingsJSON = try JSONSerialization.jsonObject(with: trainingsData) as? [[String: Any]] else {
            throw WatchConnectivityError.serializationError
        }

        var message: [String: Any] = [
            "command": Constants.WatchCommand.saveWorkout.rawValue,
            "day": day,
            "result": resultJSON,
            "executionType": executionType.rawValue,
            "trainings": trainingsJSON
        ]

        if let comment {
            message["comment"] = comment
        }

        let commentInfo = comment != nil ? ", комментарий: \(comment!)" : ""
        logger
            .info(
                "Отправка результата тренировки на iPhone: день \(day), количество \(result.count), упражнений \(trainings.count)\(commentInfo)"
            )

        try await withCheckedThrowingContinuation { continuation in
            sessionProtocol.sendMessage(message) { _ in
                self.logger.info("Результат тренировки успешно отправлен на iPhone")
                continuation.resume()
            } errorHandler: { error in
                self.logger.error("Ошибка отправки результата тренировки: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }

    /// Запрос текущей активности дня с iPhone
    /// - Parameter day: Номер дня программы
    /// - Returns: Тип активности дня или `nil` если активность не установлена
    func requestCurrentActivity(day: Int) async throws -> DayActivityType? {
        guard let sessionProtocol, sessionProtocol.isReachable else {
            throw WatchConnectivityError.sessionUnavailable
        }

        let message: [String: Any] = [
            "command": Constants.WatchCommand.getCurrentActivity.rawValue,
            "day": day
        ]

        logger.info("Запрос текущей активности дня \(day) с iPhone")

        return try await withCheckedThrowingContinuation { continuation in
            sessionProtocol.sendMessage(message) { reply in
                guard let commandString = reply["command"] as? String,
                      commandString == Constants.WatchCommand.currentActivity.rawValue else {
                    continuation.resume(returning: nil)
                    return
                }

                if let activityTypeRaw = reply["activityType"] as? Int,
                   let activityType = DayActivityType(rawValue: activityTypeRaw) {
                    self.logger.info("Получена текущая активность дня \(day): \(activityType.rawValue)")
                    continuation.resume(returning: activityType)
                } else {
                    self.logger.info("Активность дня \(day) не установлена")
                    continuation.resume(returning: nil)
                }
            } errorHandler: { error in
                self.logger.error("Ошибка запроса текущей активности: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }

    /// Запрос данных тренировки с iPhone
    /// - Parameter day: Номер дня программы
    /// - Returns: Полные данные тренировки (WorkoutData, executionCount, comment)
    func requestWorkoutData(day: Int) async throws -> WorkoutDataResponse {
        guard let sessionProtocol, sessionProtocol.isReachable else {
            throw WatchConnectivityError.sessionUnavailable
        }

        let message: [String: Any] = [
            "command": Constants.WatchCommand.getWorkoutData.rawValue,
            "day": day
        ]

        logger.info("Запрос данных тренировки дня \(day) с iPhone")

        return try await withCheckedThrowingContinuation { continuation in
            sessionProtocol.sendMessage(message) { reply in
                guard let commandString = reply["command"] as? String,
                      commandString == Constants.WatchCommand.sendWorkoutData.rawValue else {
                    continuation.resume(throwing: WatchConnectivityError.invalidResponse)
                    return
                }

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: reply)
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(WorkoutDataResponse.self, from: jsonData)
                    self.logger.info("Получены данные тренировки дня \(day)")
                    continuation.resume(returning: response)
                } catch {
                    self.logger.error("Ошибка десериализации данных тренировки: \(error.localizedDescription)")
                    continuation.resume(throwing: WatchConnectivityError.deserializationError)
                }
            } errorHandler: { error in
                self.logger.error("Ошибка запроса данных тренировки: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }

    /// Удаление активности дня (отправка на iPhone)
    /// - Parameter day: Номер дня программы
    func deleteActivity(day: Int) async throws {
        guard let sessionProtocol, sessionProtocol.isReachable else {
            throw WatchConnectivityError.sessionUnavailable
        }

        let message: [String: Any] = [
            "command": Constants.WatchCommand.deleteActivity.rawValue,
            "day": day
        ]

        logger.info("Отправка команды удаления активности дня \(day) на iPhone")

        try await withCheckedThrowingContinuation { continuation in
            sessionProtocol.sendMessage(message) { _ in
                self.logger.info("Команда удаления активности успешно отправлена на iPhone")
                continuation.resume()
            } errorHandler: { error in
                self.logger.error("Ошибка отправки команды удаления активности: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
}

extension WatchConnectivityService: WCSessionDelegate {
    func session(_: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            logger.error("Ошибка активации WCSession: \(error.localizedDescription)")
        } else {
            logger.info("WCSession активирована с состоянием: \(activationState.rawValue)")
            // Проверяем receivedApplicationContext при активации
            if let sessionProtocol, !sessionProtocol.receivedApplicationContext.isEmpty {
                logger.info("Получен Application Context при активации: \(sessionProtocol.receivedApplicationContext)")
                handleApplicationContext(sessionProtocol.receivedApplicationContext)
            }
        }
    }

    func session(_: WCSession, didReceiveMessage message: [String: Any]) {
        logger.info("Получено сообщение от iPhone: \(message)")
        handleReceivedMessage(message)
    }

    func session(_: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("Получено сообщение с ответом от iPhone: \(message)")
        handleReceivedMessage(message)
        replyHandler([:])
    }

    func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        logger.info("Получен Application Context от iPhone: \(applicationContext)")
        handleApplicationContext(applicationContext)
    }

    #if os(iOS)
    // Примечание: sessionDidBecomeInactive и sessionDidDeactivate вызываются только на iOS,
    // когда пользователь переключается между несколькими сопряженными Apple Watch.
    // На watchOS эти методы не вызываются, поэтому оставляем их пустыми.
    func sessionDidBecomeInactive(_: WCSession) {
        // Не вызывается на watchOS
    }

    func sessionDidDeactivate(_: WCSession) {
        // Не вызывается на watchOS
    }
    #endif
}

extension WatchConnectivityService {
    #if DEBUG
    /// Тестовый метод для обработки сообщения (доступен только в тестах)
    func testHandleReceivedMessage(_ message: [String: Any]) {
        handleReceivedMessage(message)
    }

    /// Тестовый метод для обработки applicationContext (доступен только в тестах)
    func testHandleApplicationContext(_ context: [String: Any]) {
        handleApplicationContext(context)
    }

    /// Тестовый метод для симуляции активации WCSession (доступен только в тестах)
    func testHandleWCSessionActivation() {
        if let sessionProtocol, !sessionProtocol.receivedApplicationContext.isEmpty {
            handleApplicationContext(sessionProtocol.receivedApplicationContext)
        }
    }
    #endif
}

private extension WatchConnectivityService {
    func handleReceivedMessage(_ message: [String: Any]) {
        guard let commandString = message["command"] as? String,
              let command = Constants.WatchCommand(rawValue: commandString) else {
            logger.warning("Неизвестная команда в сообщении: \(message)")
            return
        }

        switch command {
        case .authStatus:
            if let isAuthorized = message["isAuthorized"] as? Bool {
                let currentDay = message["currentDay"] as? Int
                let currentActivityRaw = message["currentActivity"] as? Int
                let currentActivity = currentActivityRaw.flatMap { DayActivityType(rawValue: $0) }

                // Дедупликация только для isAuthorized - проверяем, изменился ли статус авторизации
                let shouldUpdateAuth = lastProcessedStatus?.isAuthorized != isAuthorized

                // Обновляем isAuthorized только если он изменился (дедупликация)
                if shouldUpdateAuth {
                    logger.info("Получена команда изменения статуса авторизации: \(isAuthorized)")
                    authService.updateAuthStatus(isAuthorized)
                } else {
                    logger.debug("Статус авторизации не изменился, пропускаем обновление isAuthorized")
                }

                // Всегда обновляем currentDay и currentActivity, если они присутствуют в сообщении
                // Это необходимо для загрузки данных тренировки
                if let currentDay {
                    logger.info("Обновление currentDay из PHONE_COMMAND_AUTH_STATUS: \(currentDay)")
                    self.currentDay = currentDay
                }

                if let currentActivity {
                    logger.info("Обновление currentActivity из PHONE_COMMAND_AUTH_STATUS: \(currentActivity.rawValue)")
                    self.currentActivity = currentActivity
                }

                // Обновляем последние обработанные данные
                lastProcessedStatus = (isAuthorized: isAuthorized, currentDay: currentDay, currentActivity: currentActivity)
            } else {
                logger.warning("Отсутствует значение isAuthorized в команде PHONE_COMMAND_AUTH_STATUS")
            }
        case .currentDay:
            if let currentDay = message["currentDay"] as? Int {
                logger.info("Получена команда изменения текущего дня: \(currentDay)")
                self.currentDay = currentDay
            } else {
                logger.warning("Отсутствует значение currentDay в команде PHONE_COMMAND_CURRENT_DAY")
            }
        case .currentActivity:
            // Эта команда обрабатывается через replyHandler в методах запроса
            break
        case .sendWorkoutData:
            handleSendWorkoutDataCommand(message)
        case .setActivity, .saveWorkout, .getCurrentActivity, .getWorkoutData, .deleteActivity:
            // Эти команды отправляются с часов, не обрабатываются здесь
            break
        }
    }

    /// Проверяет, изменился ли статус по сравнению с последними обработанными данными
    /// - Parameters:
    ///   - isAuthorized: Статус авторизации
    ///   - currentDay: Номер текущего дня (опционально)
    ///   - currentActivity: Текущая активность (опционально)
    /// - Returns: `true` если статус изменился, `false` если идентичен
    func hasStatusChanged(
        isAuthorized: Bool,
        currentDay: Int?,
        currentActivity: DayActivityType?
    ) -> Bool {
        guard let lastProcessed = lastProcessedStatus else {
            // Если это первая обработка, считаем что статус изменился
            return true
        }

        // Сравниваем все поля
        return lastProcessed.isAuthorized != isAuthorized ||
            lastProcessed.currentDay != currentDay ||
            lastProcessed.currentActivity != currentActivity
    }

    func handleApplicationContext(_ context: [String: Any]) {
        // Извлекаем данные из контекста
        let isAuthorized = context["isAuthorized"] as? Bool
        let currentDay = context["currentDay"] as? Int
        let currentActivityRaw = context["currentActivity"] as? Int
        let currentActivity = currentActivityRaw.flatMap { DayActivityType(rawValue: $0) }

        // Если isAuthorized отсутствует, используем текущее значение
        let finalIsAuthorized = isAuthorized ?? authService.isAuthorized

        // Дедупликация только для isAuthorized - проверяем, изменился ли статус авторизации
        let shouldUpdateAuth = lastProcessedStatus?.isAuthorized != finalIsAuthorized

        // Обновляем isAuthorized только если он изменился (дедупликация)
        if shouldUpdateAuth, let isAuthorized {
            logger.info("Обновление статуса авторизации из Application Context: \(isAuthorized)")
            authService.updateAuthStatus(isAuthorized)
        } else if !shouldUpdateAuth {
            logger.debug("Статус авторизации не изменился, пропускаем обновление isAuthorized")
        }

        // Всегда обновляем currentDay и currentActivity, если они присутствуют в контексте
        // Это необходимо для загрузки данных тренировки
        if let currentDay {
            logger.info("Обновление currentDay из Application Context: \(currentDay)")
            self.currentDay = currentDay
        }

        // Обработка currentActivity
        if let currentActivity {
            logger.info("Обновление currentActivity из Application Context: \(currentActivity.rawValue)")
            self.currentActivity = currentActivity
        } else if context["currentActivity"] == nil, context["currentDay"] != nil {
            // Если currentActivity отсутствует в контексте, но есть currentDay, значит активность была удалена
            logger.info("Удаление currentActivity из Application Context (активность удалена)")
            self.currentActivity = nil
        }

        // Обновляем последние обработанные данные
        lastProcessedStatus = (isAuthorized: finalIsAuthorized, currentDay: currentDay, currentActivity: currentActivity)
    }

    func handleSendWorkoutDataCommand(_ message: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message)
            let decoder = JSONDecoder()
            let response = try decoder.decode(WorkoutDataResponse.self, from: jsonData)
            logger.info("Получены данные тренировки для дня \(response.workoutData.day) через PHONE_COMMAND_SEND_WORKOUT_DATA")
            onWorkoutDataReceived?(response)
        } catch {
            logger.error("Ошибка декодирования данных тренировки из PHONE_COMMAND_SEND_WORKOUT_DATA: \(error.localizedDescription)")
        }
    }
}

/// Ошибки `WatchConnectivity`
enum WatchConnectivityError: LocalizedError {
    case sessionUnavailable
    case serializationError
    case deserializationError
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .sessionUnavailable:
            "Сессия WatchConnectivity недоступна"
        case .serializationError:
            "Ошибка сериализации данных"
        case .deserializationError:
            "Ошибка десериализации данных"
        case .invalidResponse:
            "Неверный формат ответа от iPhone"
        }
    }
}
