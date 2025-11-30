import Foundation
import SwiftData
import SWUtils

/// Модель активности дня для хранения в SwiftData
@Model
final class DayActivity {
    /// Номер дня (1..100)
    var day: Int
    /// Тип активности (rawValue для хранения в SwiftData)
    var activityTypeRaw: Int?
    /// Количество кругов/повторений за день
    var count: Int?
    /// Плановое количество повторений
    var plannedCount: Int?
    /// Тип выполнения (rawValue для хранения в SwiftData)
    var executeTypeRaw: Int?
    /// Тип тренировки (rawValue для хранения в SwiftData)
    var trainingTypeRaw: Int?
    /// Продолжительность в секундах/минутах
    var duration: Int?
    /// Комментарий пользователя
    var comment: String?
    /// Дата создания записи
    var createDate: Date
    /// Дата последнего изменения
    var modifyDate: Date

    /// Флаг синхронизации с сервером
    var isSynced = false
    /// Флаг для удаления с сервера
    var shouldDelete = false

    /// Пользователь, которому принадлежит активность
    @Relationship(inverse: \User.dayActivities) var user: User?

    /// Тренировки этого дня
    @Relationship(deleteRule: .cascade) var trainings: [DayActivityTraining] = []

    init(
        day: Int,
        activityTypeRaw: Int? = nil,
        count: Int? = nil,
        plannedCount: Int? = nil,
        executeTypeRaw: Int? = nil,
        trainingTypeRaw: Int? = nil,
        duration: Int? = nil,
        comment: String? = nil,
        createDate: Date,
        modifyDate: Date,
        user: User? = nil
    ) {
        self.day = day
        self.activityTypeRaw = activityTypeRaw
        self.count = count
        self.plannedCount = plannedCount
        self.executeTypeRaw = executeTypeRaw
        self.trainingTypeRaw = trainingTypeRaw
        self.duration = duration
        self.comment = comment
        self.createDate = createDate
        self.modifyDate = modifyDate
        self.user = user
        // Флаги синхронизации устанавливаются по умолчанию
        self.isSynced = false
        self.shouldDelete = false
    }

    /// Инициализатор из ответа сервера
    convenience init(from response: DayResponse, user: User? = nil) {
        let createDate = response.createDate ?? .now
        let modifyDate = response.modifyDate ?? .now
        self.init(
            day: response.id,
            activityTypeRaw: response.activityType,
            count: response.count,
            plannedCount: response.plannedCount,
            executeTypeRaw: response.executeType,
            trainingTypeRaw: response.trainType,
            duration: response.duration,
            comment: response.comment,
            createDate: createDate,
            modifyDate: modifyDate,
            user: user
        )
        // Данные с сервера считаются синхронизированными
        self.isSynced = true
        self.shouldDelete = false

        // Преобразуем trainings из ответа сервера
        if let responseTrainings = response.trainings {
            self.trainings = responseTrainings.map { training in
                DayActivityTraining(from: training, dayActivity: self)
            }
        }
    }
}

extension DayActivity {
    /// Тип активности
    var activityType: DayActivityType? {
        get {
            guard let activityTypeRaw else { return nil }
            return DayActivityType(rawValue: activityTypeRaw)
        }
        set {
            activityTypeRaw = newValue?.rawValue
        }
    }

    /// Тип выполнения упражнений
    var executeType: ExerciseExecutionType? {
        get {
            guard let executeTypeRaw else { return nil }
            return ExerciseExecutionType(rawValue: executeTypeRaw)
        }
        set {
            executeTypeRaw = newValue?.rawValue
        }
    }

    /// Тип тренировки
    var trainingType: ExerciseType? {
        get {
            guard let trainingTypeRaw else { return nil }
            return ExerciseType(rawValue: trainingTypeRaw)
        }
        set {
            trainingTypeRaw = newValue?.rawValue
        }
    }

    /// Пройден ли день (определяется по наличию count)
    var isPassed: Bool {
        count != nil
    }

    /// Преобразование в ActivitySnapshot для конкурентной синхронизации
    var activitySnapshot: ActivitySnapshot {
        ActivitySnapshot(
            day: day,
            activityTypeRaw: activityTypeRaw,
            count: count,
            plannedCount: plannedCount,
            executeTypeRaw: executeTypeRaw,
            trainingTypeRaw: trainingTypeRaw,
            duration: duration,
            comment: comment,
            createDate: createDate,
            modifyDate: modifyDate,
            isSynced: isSynced,
            shouldDelete: shouldDelete,
            userId: user?.id,
            trainings: trainings.isEmpty ? nil : trainings.map(\.trainingSnapshot)
        )
    }

    /// Преобразование в DayRequest для отправки на сервер
    var dayRequest: DayRequest {
        DayRequest(
            id: day,
            activityType: activityTypeRaw,
            count: count,
            plannedCount: plannedCount,
            executeType: executeTypeRaw,
            trainingType: trainingTypeRaw,
            createDate: DateFormatterService.stringFromFullDate(createDate, format: .isoDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(modifyDate, format: .isoDateTimeSec),
            duration: duration,
            comment: comment,
            trainings: trainings.isEmpty ? nil : trainings.map(\.dayRequestTraining)
        )
    }

    /// Проверяет, изменились ли данные активности по сравнению с ответом сервера
    /// - Parameter serverResponse: Ответ сервера для сравнения
    /// - Returns: `true` если данные изменились, `false` если идентичны
    func hasDataChanged(comparedTo serverResponse: DayResponse) -> Bool {
        // Проверяем основные поля активности
        let basicDataChanged = activityTypeRaw != serverResponse.activityType ||
            count != serverResponse.count ||
            plannedCount != serverResponse.plannedCount ||
            executeTypeRaw != serverResponse.executeType ||
            trainingTypeRaw != serverResponse.trainType ||
            duration != serverResponse.duration ||
            comment != serverResponse.comment

        // Проверяем изменения в trainings: сравниваем количество
        let serverTrainingsCount = serverResponse.trainings?.count ?? 0
        let localTrainingsCount = trainings.count
        let trainingsChanged = localTrainingsCount != serverTrainingsCount

        return basicDataChanged || trainingsChanged
    }

    /// Устанавливает тип активности для stretch/rest/sick и очищает тренировочные данные
    ///
    /// Используется для установки активности дня через главный экран
    /// - Parameters:
    ///   - activityType: Тип активности (`stretch`, `rest`, `sick`)
    ///   - user: Пользователь, которому принадлежит активность
    func setNonWorkoutType(_ activityType: DayActivityType, user: User) {
        let originalCreateDate = createDate

        // Устанавливаем тип активности
        activityTypeRaw = activityType.rawValue

        // Очищаем тренировочные данные
        count = nil
        trainings.removeAll()
        executeTypeRaw = nil
        trainingTypeRaw = nil

        // Очищаем дополнительные данные
        comment = nil
        duration = nil

        // Обновляем флаги синхронизации и даты
        modifyDate = .now
        isSynced = false
        shouldDelete = false

        // Сохраняем оригинальный createDate
        createDate = originalCreateDate

        // Убеждаемся, что активность привязана к пользователю
        self.user = user
    }

    /// Создает новую активность для stretch/rest/sick без тренировочных данных
    /// - Parameters:
    ///   - day: Номер дня (1-100)
    ///   - activityType: Тип активности (stretch, rest, sick)
    ///   - user: Пользователь, которому принадлежит активность
    /// - Returns: Новая активность дня
    static func createNonWorkoutActivity(day: Int, activityType: DayActivityType, user: User) -> DayActivity {
        let activity = DayActivity(
            day: day,
            activityTypeRaw: activityType.rawValue,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user
        )

        // Установка флагов синхронизации
        activity.isSynced = false
        activity.shouldDelete = false

        return activity
    }
}
