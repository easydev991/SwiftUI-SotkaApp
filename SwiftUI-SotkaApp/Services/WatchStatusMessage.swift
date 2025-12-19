import Foundation

/// Структура для преобразования данных статуса в сообщение для отправки на часы
struct WatchStatusMessage {
    /// Статус авторизации
    let isAuthorized: Bool
    /// Номер текущего дня (опционально, обязателен если авторизован)
    let currentDay: Int?
    /// Текущая активность (опционально)
    let currentActivity: DayActivityType?

    /// Преобразует данные в словарь для отправки через WatchConnectivity
    /// - Returns: Словарь с данными для отправки на часы
    func toMessage() -> [String: Any] {
        var message: [String: Any] = [
            "command": Constants.WatchCommand.authStatus.rawValue,
            "isAuthorized": isAuthorized
        ]

        if let currentDay {
            message["currentDay"] = currentDay
        }

        if let currentActivity {
            message["currentActivity"] = currentActivity.rawValue
        }

        return message
    }
}

extension WatchStatusMessage {
    /// Парсит команду из сообщения WatchConnectivity
    /// - Parameter message: Сообщение от часов
    /// - Returns: Кортеж с командой и данными, или `nil` если команда не распознана
    static func parseWatchCommand(_ message: [String: Any]) -> (command: Constants.WatchCommand, data: [String: Any])? {
        guard let commandString = message["command"] as? String,
              let command = Constants.WatchCommand(rawValue: commandString)
        else {
            return nil
        }

        var data = message
        data.removeValue(forKey: "command")
        return (command, data)
    }
}
