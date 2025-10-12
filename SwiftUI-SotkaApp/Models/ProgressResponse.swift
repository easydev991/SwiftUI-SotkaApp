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

    /// Инициализатор для создания ответа сервера
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
}
