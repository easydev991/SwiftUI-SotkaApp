#if DEBUG
import Foundation
import WatchConnectivity

/// Мок-реализация WatchSessionProtocol для UI-тестов
/// Предоставляет заранее подготовленные данные без реальной связи с iPhone
@MainActor
final class MockWatchSession: NSObject, WatchSessionProtocol {
    var isReachable = true
    weak var delegate: WCSessionDelegate?
    var receivedApplicationContext: [String: Any] = [:]

    /// Текущий день программы для мок-данных
    private let mockCurrentDay = 12

    /// Текущая активность дня для мок-данных
    private let mockCurrentActivity: DayActivityType = .workout

    /// Мок-данные тренировки
    private var mockWorkoutData: WorkoutData {
        WorkoutData(
            day: mockCurrentDay,
            executionType: ExerciseExecutionType.cycles.rawValue,
            trainings: .previewCycles,
            plannedCount: 4
        )
    }

    override init() {
        super.init()
        // Инициализируем applicationContext с начальными данными
        self.receivedApplicationContext = makeAuthStatusMessage()
    }

    func activate() {
        // Симулируем активацию сессии
        // WatchConnectivityService проверяет receivedApplicationContext в init после активации
        // и вызывает handleApplicationContext, если контекст не пустой
        // Для мока applicationContext уже установлен в init, поэтому обработка произойдет автоматически
    }

    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
        // Обрабатываем команды от Watch App
        guard let commandString = message["command"] as? String,
              let command = Constants.WatchCommand(rawValue: commandString) else {
            errorHandler?(WatchConnectivityError.invalidResponse)
            return
        }

        switch command {
        case .getCurrentActivity:
            // Возвращаем текущую активность
            let reply: [String: Any] = [
                "command": Constants.WatchCommand.currentActivity.rawValue,
                "activityType": mockCurrentActivity.rawValue
            ]
            replyHandler?(reply)

        case .getWorkoutData:
            // Возвращаем данные тренировки
            let response = WorkoutDataResponse(
                workoutData: mockWorkoutData,
                executionCount: nil,
                comment: nil
            )

            // Сериализуем ответ
            let encoder = JSONEncoder()
            if let jsonData = try? encoder.encode(response),
               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                var reply = jsonObject
                reply["command"] = Constants.WatchCommand.sendWorkoutData.rawValue
                replyHandler?(reply)
            } else {
                errorHandler?(WatchConnectivityError.serializationError)
            }

        case .setActivity, .saveWorkout, .deleteActivity:
            // Просто подтверждаем успешную отправку
            replyHandler?([:])

        default:
            errorHandler?(WatchConnectivityError.invalidResponse)
        }
    }

    /// Создает сообщение PHONE_COMMAND_AUTH_STATUS с мок-данными
    private func makeAuthStatusMessage() -> [String: Any] {
        [
            "command": Constants.WatchCommand.authStatus.rawValue,
            "isAuthorized": true,
            "currentDay": mockCurrentDay,
            "currentActivity": mockCurrentActivity.rawValue
        ]
    }
}
#endif
