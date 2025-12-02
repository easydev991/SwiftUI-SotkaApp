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
    private let sessionProtocol: WCSessionProtocol?

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
        sessionProtocol: WCSessionProtocol? = nil
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
    func sendWorkoutResult(day: Int, result: WorkoutResult, executionType: ExerciseExecutionType) async throws {
        guard let sessionProtocol, sessionProtocol.isReachable else {
            throw WatchConnectivityError.sessionUnavailable
        }

        let encoder = JSONEncoder()
        let resultData = try encoder.encode(result)
        guard let resultJSON = try JSONSerialization.jsonObject(with: resultData) as? [String: Any] else {
            throw WatchConnectivityError.serializationError
        }

        let message: [String: Any] = [
            "command": Constants.WatchCommand.saveWorkout.rawValue,
            "day": day,
            "result": resultJSON,
            "executionType": executionType.rawValue
        ]

        logger.info("Отправка результата тренировки на iPhone: день \(day), количество \(result.count)")

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
    /// - Returns: Данные тренировки
    func requestWorkoutData(day: Int) async throws -> WorkoutData {
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
                    let workoutData = try decoder.decode(WorkoutData.self, from: jsonData)
                    self.logger.info("Получены данные тренировки дня \(day)")
                    continuation.resume(returning: workoutData)
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
}

extension WatchConnectivityService: WCSessionDelegate {
    func session(_: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            logger.error("Ошибка активации WCSession: \(error.localizedDescription)")
        } else {
            logger.info("WCSession активирована с состоянием: \(activationState.rawValue)")
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
}

private extension WatchConnectivityService {
    func handleReceivedMessage(_ message: [String: Any]) {
        guard let commandString = message["command"] as? String,
              let command = Constants.WatchCommand(rawValue: commandString) else {
            logger.warning("Неизвестная команда в сообщении: \(message)")
            return
        }

        switch command {
        case .authStatusChanged:
            if let isAuthorized = message["isAuthorized"] as? Bool {
                logger.info("Получена команда изменения статуса авторизации: \(isAuthorized)")
                authService.updateAuthStatus(isAuthorized)
            } else {
                logger.warning("Отсутствует значение isAuthorized в команде PHONE_COMMAND_AUTH_STATUS_CHANGED")
            }
        case .currentActivity, .sendWorkoutData:
            // Эти команды обрабатываются через replyHandler в методах запроса
            break
        case .setActivity, .saveWorkout, .getCurrentActivity, .getWorkoutData:
            // Эти команды отправляются с часов, не обрабатываются здесь
            break
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
