import Foundation
import SWUtils

/// Модель ответа сервера для дня тренировки
struct DayResponse: Codable, Sendable, Hashable, Equatable {
    /// День (1..100)
    let id: Int
    /// Тип активности
    let activityType: Int?
    /// Количество кругов/повторов за день
    let count: Int?
    /// Плановое количество повторений (если поддерживается сервером)
    let plannedCount: Int?
    /// Тип выполнения
    let executeType: Int?
    /// Тип тренировки
    let trainType: Int?
    /// Массив тренировок
    let trainings: [Training]?
    /// ISO дата создания
    let createDate: String?
    /// ISO дата изменения
    let modifyDate: String?
    /// Продолжительность (в минутах/секундах — как на сервере)
    let duration: Int?
    /// Произвольный комментарий к дню
    let comment: String?

    init(
        id: Int,
        activityType: Int? = nil,
        count: Int? = nil,
        plannedCount: Int? = nil,
        executeType: Int? = nil,
        trainType: Int? = nil,
        trainings: [Training]? = nil,
        createDate: String? = nil,
        modifyDate: String? = nil,
        duration: Int? = nil,
        comment: String? = nil
    ) {
        self.id = id
        self.activityType = activityType
        self.count = count
        self.plannedCount = plannedCount
        self.executeType = executeType
        self.trainType = trainType
        self.trainings = trainings
        self.createDate = createDate
        self.modifyDate = modifyDate
        self.duration = duration
        self.comment = comment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIntOrString(.id)
        self.activityType = container.decodeIntOrStringIfPresent(.activityType)
        self.count = container.decodeIntOrStringIfPresent(.count)
        self.plannedCount = container.decodeIntOrStringIfPresent(.plannedCount)
        self.executeType = container.decodeIntOrStringIfPresent(.executeType)
        self.trainType = container.decodeIntOrStringIfPresent(.trainType)
        self.duration = container.decodeIntOrStringIfPresent(.duration)
        self.createDate = try container.decodeIfPresent(String.self, forKey: .createDate)
        self.modifyDate = try container.decodeIfPresent(String.self, forKey: .modifyDate)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        self.trainings = try container.decodeIfPresent([Training].self, forKey: .trainings)
    }
}

extension DayResponse {
    /// Тренировка внутри дня в ответе сервера
    struct Training: Codable, Sendable, Hashable, Equatable {
        /// Идентификатор стандартного типа упражнения (если задан)
        let typeId: Int?
        /// Идентификатор пользовательского типа упражнения (если задан)
        let customTypeId: String?
        /// Количество повторений/подходов по элементу
        let count: Int?
        /// Порядок следования в списке тренировок
        let sortOrder: Int?

        init(
            typeId: Int? = nil,
            customTypeId: String? = nil,
            count: Int? = nil,
            sortOrder: Int? = nil
        ) {
            self.typeId = typeId
            self.customTypeId = customTypeId
            self.count = count
            self.sortOrder = sortOrder
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.typeId = container.decodeIntOrStringIfPresent(.typeId)
            self.count = container.decodeIntOrStringIfPresent(.count)
            self.sortOrder = container.decodeIntOrStringIfPresent(.sortOrder)
            self.customTypeId = try container.decodeIfPresent(String.self, forKey: .customTypeId)
        }
    }
}
