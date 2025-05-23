import Foundation

/// Модель фотографии для отправки на сервер
struct MediaFile: Codable, Equatable, Sendable {
    let key: String
    let filename: String
    let data: Data
    let mimeType: String

    /// Инициализатор для добавления фото площадки/мероприятия
    /// - Parameters:
    ///   - imageData: Данные для картинки
    ///   - key: Индекс
    init(imageData: Data, forKey key: String) {
        self.key = "photo\(key)"
        self.mimeType = "image/jpeg"
        self.filename = "photo\(key).jpg"
        self.data = imageData
    }
}
