import Foundation
import SWUtils

/// Модель пользовательского упражнения
struct CustomExerciseResponse: Codable, Identifiable, Hashable, Sendable {
    /// Уникальный идентификатор упражнения
    let id: String
    /// Название упражнения
    let name: String
    /// Номер стандартной картинки упражнения
    let imageId: Int
    /// Дата создания упражнения в формате server date time
    let createDate: Date
    /// Дата последнего изменения упражнения в формате server date time
    let modifyDate: Date?
    /// Признак сокрытия упражнения
    let isHidden: Bool

    /// Обычный инициализатор
    init(id: String, name: String, imageId: Int, createDate: Date, modifyDate: Date? = nil, isHidden: Bool = false) {
        self.id = id
        self.name = name
        self.imageId = imageId
        self.createDate = createDate
        self.modifyDate = modifyDate
        self.isHidden = isHidden
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageId
        case createDate
        case modifyDate
        case isHidden
    }

    /// Кастомный инициализатор - обрабатывает `imageId` как строку и конвертирует в число
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.createDate = try container.decode(Date.self, forKey: .createDate)
        self.modifyDate = try? container.decodeIfPresent(Date.self, forKey: .modifyDate)
        self.isHidden = try container.decode(Bool.self, forKey: .isHidden)

        if let imageIdString = try? container.decode(String.self, forKey: .imageId) {
            self.imageId = Int(imageIdString) ?? 1
        } else {
            self.imageId = try container.decode(Int.self, forKey: .imageId)
        }
    }
}
