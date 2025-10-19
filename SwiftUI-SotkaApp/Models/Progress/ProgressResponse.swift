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

        // Декодируем id как Int или String
        if let idInt = try container.decodeIfPresent(Int.self, forKey: .id) {
            self.id = idInt
        } else if let idString = try container.decodeIfPresent(String.self, forKey: .id),
                  let idInt = Int(idString) {
            self.id = idInt
        } else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(
                codingPath: decoder.codingPath + [CodingKeys.id],
                debugDescription: "Ожидали Int или String для конвертации в Int"
            ))
        }

        // Декодируем pullups как Int? или String?
        if let pullupsInt = try container.decodeIfPresent(Int.self, forKey: .pullups) {
            self.pullups = pullupsInt
        } else if let pullupsString = try container.decodeIfPresent(String.self, forKey: .pullups),
                  let pullupsInt = Int(pullupsString) {
            self.pullups = pullupsInt
        } else {
            self.pullups = nil
        }

        // Декодируем pushups как Int? или String?
        if let pushupsInt = try container.decodeIfPresent(Int.self, forKey: .pushups) {
            self.pushups = pushupsInt
        } else if let pushupsString = try container.decodeIfPresent(String.self, forKey: .pushups),
                  let pushupsInt = Int(pushupsString) {
            self.pushups = pushupsInt
        } else {
            self.pushups = nil
        }

        // Декодируем squats как Int? или String?
        if let squatsInt = try container.decodeIfPresent(Int.self, forKey: .squats) {
            self.squats = squatsInt
        } else if let squatsString = try container.decodeIfPresent(String.self, forKey: .squats),
                  let squatsInt = Int(squatsString) {
            self.squats = squatsInt
        } else {
            self.squats = nil
        }

        // Декодируем weight как Float? или String?
        if let weightFloat = try container.decodeIfPresent(Float.self, forKey: .weight) {
            self.weight = weightFloat
        } else if let weightString = try container.decodeIfPresent(String.self, forKey: .weight),
                  let weightFloat = Float(weightString) {
            self.weight = weightFloat
        } else {
            self.weight = nil
        }

        // Декодируем строковые поля
        self.createDate = try container.decode(String.self, forKey: .createDate)
        self.modifyDate = try container.decodeIfPresent(String.self, forKey: .modifyDate)
        self.photoFront = try container.decodeIfPresent(String.self, forKey: .photoFront)
        self.photoBack = try container.decodeIfPresent(String.self, forKey: .photoBack)
        self.photoSide = try container.decodeIfPresent(String.self, forKey: .photoSide)
    }
}
