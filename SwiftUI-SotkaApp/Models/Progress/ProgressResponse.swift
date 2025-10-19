import Foundation

/// Модель ответа сервера для прогресса пользователя
struct ProgressResponse: Codable, Sendable, Hashable, Equatable {
    /// День (соответствует полю "id" в ответе сервера)
    let id: Int
    /// Подтягивания
    let pullups: Int?
    /// Отжимания
    let pushups: Int?
    /// Приседания
    let squats: Int?
    /// Вес
    let weight: Float?
    /// ISO дата создания
    let createDate: String
    /// ISO дата изменения
    let modifyDate: String?
    /// URL фотографий прогресса
    let photoFront: String?
    let photoBack: String?
    let photoSide: String?

    init(
        id: Int,
        pullups: Int? = nil,
        pushups: Int? = nil,
        squats: Int? = nil,
        weight: Float? = nil,
        createDate: String,
        modifyDate: String?,
        photoFront: String? = nil,
        photoBack: String? = nil,
        photoSide: String? = nil
    ) {
        self.id = id
        self.pullups = pullups
        self.pushups = pushups
        self.squats = squats
        self.weight = weight
        self.createDate = createDate
        self.modifyDate = modifyDate
        self.photoFront = photoFront
        self.photoBack = photoBack
        self.photoSide = photoSide
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

        func decodeFloatOrString(_ key: CodingKeys) throws -> Float? {
            // Сначала пытаемся декодировать как String, так как сервер иногда возвращает числа как строки
            if let stringValue = try? container.decodeIfPresent(String.self, forKey: key),
               let floatValue = Float(stringValue) {
                return floatValue
            }
            // Если не получилось как String, пытаемся как Float
            else if let floatValue = try? container.decodeIfPresent(Float.self, forKey: key) {
                return floatValue
            }
            return nil
        }

        // Декодируем числовые поля с безопасной конвертацией
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

        self.pullups = try decodeIntOrString(.pullups)
        self.pushups = try decodeIntOrString(.pushups)
        self.squats = try decodeIntOrString(.squats)
        self.weight = try decodeFloatOrString(.weight)

        // Декодируем строковые поля
        self.createDate = try container.decode(String.self, forKey: .createDate)
        self.modifyDate = try container.decodeIfPresent(String.self, forKey: .modifyDate)
        self.photoFront = try container.decodeIfPresent(String.self, forKey: .photoFront)
        self.photoBack = try container.decodeIfPresent(String.self, forKey: .photoBack)
        self.photoSide = try container.decodeIfPresent(String.self, forKey: .photoSide)
    }
}
