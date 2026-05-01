import Foundation

/// Модель фотографии для отправки на сервер
struct MediaFile: Codable, Equatable {
    let data: Data
    let mimeType: String

    /// Инициализатор для добавления фото площадки/мероприятия
    /// - Parameters:
    ///   - imageData: Данные для картинки
    init(imageData: Data) {
        self.mimeType = "image/jpeg"
        self.data = imageData
    }
}
