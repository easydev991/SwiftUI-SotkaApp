import Foundation

/// Модель запроса для создания/обновления прогресса пользователя
struct ProgressRequest: Codable, Sendable {
    /// День (1, 50, 100)
    let id: Int
    /// Подтягивания
    let pullups: Int?
    /// Отжимания
    let pushups: Int?
    /// Приседания
    let squats: Int?
    /// Вес
    let weight: Float?
    /// ISO дата изменения
    let modifyDate: String
    /// Фотографии для отправки (используется локально, не сериализуется в JSON)
    let photos: [String: Data]?
    /// Фотографии для удаления (используется локально, не сериализуется в JSON)
    let photosToDelete: [String]?

    /// Инициализатор для создания нового прогресса
    init(
        id: Int,
        pullups: Int? = nil,
        pushups: Int? = nil,
        squats: Int? = nil,
        weight: Float? = nil,
        modifyDate: String,
        photos: [String: Data]? = nil,
        photosToDelete: [String]? = nil
    ) {
        self.id = id
        self.pullups = pullups
        self.pushups = pushups
        self.squats = squats
        self.weight = weight
        self.modifyDate = modifyDate
        self.photos = photos
        self.photosToDelete = photosToDelete
    }
}

extension ProgressRequest {
    /// Параметры для запроса создания/обновления прогресса
    var requestParameters: [String: String] {
        [
            "id": String(id),
            "pullups": String(pullups ?? 0),
            "pushups": String(pushups ?? 0),
            "squats": String(squats ?? 0),
            "weight": String(weight ?? 0),
            "modify_date": modifyDate
        ]
    }
}
