import Foundation
import SwiftData

/// Модель тренировки для активности дня
@Model
final class DayActivityTraining {
    /// Количество повторений/подходов
    var count: Int?
    /// Идентификатор стандартного типа упражнения (соответствует `ExerciseType.rawValue`)
    var typeId: Int?
    /// Идентификатор пользовательского типа упражнения (соответствует `CustomExercise.id`)
    var customTypeId: String?
    /// Порядок следования в списке тренировок
    var sortOrder: Int?

    /// Активность дня, к которой принадлежит тренировка
    @Relationship(inverse: \DayActivity.trainings) var dayActivity: DayActivity?

    init(
        count: Int? = nil,
        typeId: Int? = nil,
        customTypeId: String? = nil,
        sortOrder: Int? = nil,
        dayActivity: DayActivity? = nil
    ) {
        self.count = count
        self.typeId = typeId
        self.customTypeId = customTypeId
        self.sortOrder = sortOrder
        self.dayActivity = dayActivity
    }

    /// Инициализатор из ответа сервера
    convenience init(from training: DayResponse.Training, dayActivity: DayActivity? = nil) {
        self.init(
            count: training.count,
            typeId: training.typeId,
            customTypeId: training.customTypeId,
            sortOrder: training.sortOrder,
            dayActivity: dayActivity
        )
    }
}

extension DayActivityTraining {
    /// Тип упражнения (если это стандартное упражнение)
    var exerciseType: ExerciseType? {
        get {
            guard let typeId else { return nil }
            return ExerciseType(rawValue: typeId)
        }
        set {
            typeId = newValue?.rawValue
        }
    }

    /// Инициализатор из WorkoutPreviewTraining
    convenience init(from preview: WorkoutPreviewTraining, dayActivity: DayActivity?) {
        self.init(
            count: preview.count,
            typeId: preview.typeId,
            customTypeId: preview.customTypeId,
            sortOrder: preview.sortOrder,
            dayActivity: dayActivity
        )
    }

    /// Преобразование в DayRequest.Training для отправки на сервер
    var dayRequestTraining: DayRequest.Training {
        .init(
            count: count,
            typeId: typeId,
            customTypeId: customTypeId,
            sortOrder: sortOrder
        )
    }

    /// Преобразование в ActivitySnapshot.TrainingSnapshot для снимков синхронизации
    var trainingSnapshot: ActivitySnapshot.TrainingSnapshot {
        .init(
            count: count,
            typeId: typeId,
            customTypeId: customTypeId,
            sortOrder: sortOrder
        )
    }
}

extension [DayActivityTraining] {
    /// Отсортированный массив тренировок по порядку следования (`sortOrder`)
    var sorted: [DayActivityTraining] {
        sorted(by: { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) })
    }
}
