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
    var message: [String: Any] {
        var result: [String: Any] = [
            "command": Constants.WatchCommand.authStatus.rawValue,
            "isAuthorized": isAuthorized
        ]

        if let currentDay {
            result["currentDay"] = currentDay
        }

        if let currentActivity {
            result["currentActivity"] = currentActivity.rawValue
        }

        return result
    }

    /// Создает applicationContext для часов (без поля "command", работает даже когда приложение закрыто)
    /// - Returns: Словарь с данными для applicationContext
    var applicationContext: [String: Any] {
        var context: [String: Any] = [
            "isAuthorized": isAuthorized
        ]

        if let currentDay {
            context["currentDay"] = currentDay
        }

        if let currentActivity {
            context["currentActivity"] = currentActivity.rawValue
        }

        return context
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
