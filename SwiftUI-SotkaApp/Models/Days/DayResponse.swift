import Foundation

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

        // Вспомогательная функция для безопасного декодирования чисел из строк или чисел
        func decodeIntOrString(_ key: CodingKeys) throws -> Int? {
            // Сначала пытаемся декодировать как String, так как сервер иногда возвращает числа как строки
            if let stringValue = try? container.decodeIfPresent(String.self, forKey: key),
               let intValue = Int(stringValue) {
                return intValue
            }
            // Если не получилось как String, пытаемся как Int
            else if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
                return intValue
            }
            return nil
        }

        // Декодируем обязательное поле id с безопасной конвертацией
        self.id = try {
            // Сначала пытаемся декодировать как String, так как сервер иногда возвращает числа как строки
            if let idString = try? container.decodeIfPresent(String.self, forKey: .id),
               let idInt = Int(idString) {
                return idInt
            }
            // Если не получилось как String, пытаемся как Int
            else if let idInt = try? container.decodeIfPresent(Int.self, forKey: .id) {
                return idInt
            } else {
                throw DecodingError.typeMismatch(Int.self, DecodingError.Context(
                    codingPath: decoder.codingPath + [CodingKeys.id],
                    debugDescription: "Ожидали Int или String для конвертации в Int"
                ))
            }
        }()

        // Декодируем опциональные числовые поля с безопасной конвертацией
        self.activityType = try decodeIntOrString(.activityType)
        self.count = try decodeIntOrString(.count)
        self.plannedCount = try decodeIntOrString(.plannedCount)
        self.executeType = try decodeIntOrString(.executeType)
        self.trainType = try decodeIntOrString(.trainType)
        self.duration = try decodeIntOrString(.duration)

        // Декодируем строковые поля
        self.createDate = try container.decodeIfPresent(String.self, forKey: .createDate)
        self.modifyDate = try container.decodeIfPresent(String.self, forKey: .modifyDate)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)

        // Декодируем массив тренировок
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

            // Вспомогательная функция для безопасного декодирования чисел из строк или чисел
            func decodeIntOrString(_ key: CodingKeys) throws -> Int? {
                // Сначала пытаемся декодировать как String, так как сервер иногда возвращает числа как строки
                if let stringValue = try? container.decodeIfPresent(String.self, forKey: key),
                   let intValue = Int(stringValue) {
                    return intValue
                }
                // Если не получилось как String, пытаемся как Int
                else if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
                    return intValue
                }
                return nil
            }

            // Декодируем опциональные числовые поля с безопасной конвертацией
            self.typeId = try decodeIntOrString(.typeId)
            self.count = try decodeIntOrString(.count)
            self.sortOrder = try decodeIntOrString(.sortOrder)

            // Декодируем строковые поля
            self.customTypeId = try container.decodeIfPresent(String.self, forKey: .customTypeId)
        }
    }
}
