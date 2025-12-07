import Foundation

/// Структура для передачи полных данных тренировки с iPhone на Apple Watch
struct WorkoutDataResponse: Codable, Equatable {
    /// Данные тренировки
    let workoutData: WorkoutData
    /// Количество выполнений (кругов/подходов) - фактическое значение из DayActivity.count
    let executionCount: Int?
    /// Комментарий к тренировке из DayActivity.comment
    let comment: String?
}

extension WorkoutDataResponse {
    /// Создает JSON словарь для отправки на Apple Watch через WatchConnectivity
    /// - Parameter command: Команда для отправки (например, Constants.WatchCommand.sendWorkoutData.rawValue)
    /// - Returns: JSON словарь с командой и всеми полями на верхнем уровне для обратной совместимости
    func makeMessageForWatch(command: String) -> [String: Any]? {
        // Сначала сериализуем всю структуру в JSON
        guard let jsonData = try? JSONEncoder().encode(self),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            return nil
        }

        // Создаем сообщение с командой и полями на верхнем уровне для обратной совместимости
        var message: [String: Any] = jsonObject
        message["command"] = command

        // Добавляем поля из workoutData на верхний уровень для совместимости с тестами
        message["day"] = workoutData.day
        message["executionType"] = workoutData.executionType
        // Сериализуем trainings в массив словарей
        let encoder = JSONEncoder()
        if let trainingsData = try? encoder.encode(workoutData.trainings),
           let trainingsArray = try? JSONSerialization.jsonObject(with: trainingsData) as? [[String: Any]] {
            message["trainings"] = trainingsArray
        } else {
            // Если не удалось сериализовать, используем пустой массив
            message["trainings"] = []
        }
        message["plannedCount"] = workoutData.plannedCount

        return message
    }
}
