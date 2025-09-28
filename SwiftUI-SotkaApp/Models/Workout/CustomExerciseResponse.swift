import Foundation

/// Модель пользовательского упражнения
struct CustomExerciseResponse: Codable, Identifiable, Hashable, Sendable {
    /// Уникальный идентификатор упражнения
    let id: String
    /// Название упражнения
    let name: String
    /// Номер стандартной картинки упражнения
    let imageId: Int
    /// Дата создания упражнения в формате ISO 8601
    let createDate: String
    /// Дата последнего изменения упражнения в формате ISO 8601
    let modifyDate: String
    /// Признак сокрытия упражнения
    let isHidden: Bool

    /// Обычный инициализатор
    init(id: String, name: String, imageId: Int, createDate: String, modifyDate: String, isHidden: Bool = false) {
        self.id = id
        self.name = name
        self.imageId = imageId
        self.createDate = createDate
        self.modifyDate = modifyDate
        self.isHidden = isHidden
    }

    /// Кастомный инициализатор - обрабатывает `imageId` как строку и конвертирует в число
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.createDate = try container.decode(String.self, forKey: .createDate)
        self.modifyDate = try container.decode(String.self, forKey: .modifyDate)
        self.isHidden = try container.decode(Bool.self, forKey: .isHidden)
        if let imageIdString = try? container.decode(String.self, forKey: .imageId) {
            self.imageId = Int(imageIdString) ?? 1
        } else {
            self.imageId = try container.decode(Int.self, forKey: .imageId)
        }
    }
}
