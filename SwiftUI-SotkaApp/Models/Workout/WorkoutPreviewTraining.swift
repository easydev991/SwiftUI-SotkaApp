import Foundation

/// Простая структура для хранения данных упражнения в превью тренировки
struct WorkoutPreviewTraining: Equatable, Identifiable {
    /// Уникальный идентификатор для идентификации в ViewModel и UI (не передается на сервер)
    let id: String
    /// Количество повторений/подходов
    let count: Int?
    /// Идентификатор стандартного типа упражнения (соответствует `ExerciseType.rawValue`)
    let typeId: Int?
    /// Идентификатор пользовательского типа упражнения (соответствует `CustomExercise.id`)
    let customTypeId: String?
    /// Порядок следования в списке тренировок
    let sortOrder: Int?

    /// Инициализатор из DayActivityTraining для маппинга из SwiftData модели
    init(from training: DayActivityTraining) {
        self.init(
            id: UUID().uuidString,
            count: training.count,
            typeId: training.typeId,
            customTypeId: training.customTypeId,
            sortOrder: training.sortOrder
        )
    }

    /// Базовый инициализатор
    init(
        id: String = UUID().uuidString,
        count: Int? = nil,
        typeId: Int? = nil,
        customTypeId: String? = nil,
        sortOrder: Int? = nil
    ) {
        self.id = id
        self.count = count
        self.typeId = typeId
        self.customTypeId = customTypeId
        self.sortOrder = sortOrder
    }

    /// Создает новую модель с обновленным значением count
    /// - Parameter newCount: Новое значение count
    /// - Returns: Новая модель с обновленным count
    func withCount(_ newCount: Int?) -> WorkoutPreviewTraining {
        Self(
            id: id,
            count: newCount,
            typeId: typeId,
            customTypeId: customTypeId,
            sortOrder: sortOrder
        )
    }
}

extension [WorkoutPreviewTraining] {
    /// Отсортированный массив тренировок по порядку следования (`sortOrder`)
    var sorted: [WorkoutPreviewTraining] {
        sorted(by: { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) })
    }
}
