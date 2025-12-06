import Foundation

/// Структура для передачи данных тренировки между iPhone и Apple Watch
struct WorkoutData: Codable, Equatable {
    /// Номер дня программы
    let day: Int
    /// Тип выполнения упражнений (ExerciseExecutionType.rawValue)
    let executionType: Int
    /// Массив упражнений тренировки
    let trainings: [WorkoutPreviewTraining]
    /// Плановое количество кругов/подходов для отображения в UI
    let plannedCount: Int?

    /// Преобразует executionType (Int) в ExerciseExecutionType
    var exerciseExecutionType: ExerciseExecutionType? {
        ExerciseExecutionType(rawValue: executionType)
    }
}
