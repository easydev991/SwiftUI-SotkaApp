import Foundation

/// Модель запроса для создания/обновления дня тренировки
struct DayRequest: Codable, Sendable {
    /// День (1..100)
    let id: Int
    /// Тип активности
    let activityType: Int?
    /// Количество кругов/повторов за день
    let count: Int?
    /// Плановое количество повторений (опционально, поддерживается сервером)
    let plannedCount: Int?
    /// Тип выполнения
    let executeType: Int?
    /// Тип тренировки
    let trainingType: Int?
    /// ISO дата создания
    let createDate: String?
    /// ISO дата изменения (отсутствовует при создании)
    let modifyDate: String?
    /// Продолжительность (в минутах/секундах — как на сервере)
    let duration: Int?
    /// Произвольный комментарий к дню
    let comment: String?
    /// Массив тренировок
    let trainings: [Training]?
}

extension DayRequest {
    /// Тренировка внутри дня для запроса
    struct Training: Codable, Sendable, Hashable {
        /// Количество повторений/подходов по элементу
        let count: Int?
        /// Идентификатор стандартного типа упражнения (если задан)
        let typeId: Int?
        /// Идентификатор пользовательского типа упражнения (если задан)
        let customTypeId: String?
        /// Порядок следования в списке тренировок
        let sortOrder: Int?

        init(count: Int? = nil, typeId: Int? = nil, customTypeId: String? = nil, sortOrder: Int? = nil) {
            self.count = count
            self.typeId = typeId
            self.customTypeId = customTypeId
            self.sortOrder = sortOrder
        }
    }
}

extension DayRequest.Training {
    /// Инициализатор из снимка тренировки
    init(from snapshot: ActivitySnapshot.TrainingSnapshot) {
        self.init(
            count: snapshot.count,
            typeId: snapshot.typeId,
            customTypeId: snapshot.customTypeId,
            sortOrder: snapshot.sortOrder
        )
    }
}

extension DayRequest {
    /// Параметры формы для отправки на сервер (application/x-www-form-urlencoded)
    var formParameters: [String: String] {
        var parameters: [String: String] = [
            "id": String(id)
        ]
        if let activityType { parameters["activity_type"] = String(activityType) }
        if let count { parameters["count"] = String(count) }
        if let plannedCount { parameters["planned_count"] = String(plannedCount) }
        if let executeType { parameters["execute_type"] = String(executeType) }
        if let trainingType { parameters["training_type"] = String(trainingType) }
        if let duration { parameters["duration"] = String(duration) }
        if let comment { parameters["comment"] = comment }
        if let createDate { parameters["create_date"] = createDate }
        if let modifyDate { parameters["modify_date"] = modifyDate }

        if let trainings, !trainings.isEmpty {
            // Сортируем тренировки по sortOrder, чтобы индекс массива соответствовал sort_order
            let sortedTrainings = trainings.sorted { training1, training2 in
                let order1 = training1.sortOrder ?? Int.max
                let order2 = training2.sortOrder ?? Int.max
                return order1 < order2
            }
            for (index, training) in sortedTrainings.enumerated() {
                let base = "training[\(index)]"
                if let cnt = training.count { parameters["\(base)[count]"] = String(cnt) }
                if let customId = training.customTypeId {
                    parameters["\(base)[custom_type_id]"] = customId
                } else if let typeId = training.typeId {
                    parameters["\(base)[type_id]"] = String(typeId)
                }
                // Используем индекс массива как sort_order (после сортировки)
                parameters["\(base)[sort_order]"] = String(index)
            }
        }

        return parameters
    }
}
