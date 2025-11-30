import Foundation
import SWUtils

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
    /// Дата создания в формате server date time
    let createDate: Date
    /// Дата изменения в формате server date time
    let modifyDate: Date?
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
        createDate: Date,
        modifyDate: Date?,
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

    enum CodingKeys: String, CodingKey {
        case id
        case pullups
        case pushups
        case squats
        case weight
        case createDate
        case modifyDate
        case photoFront
        case photoBack
        case photoSide
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIntOrString(.id)
        self.pullups = (try? container.decode(Int.self, forKey: .pullups)) ?? container.decodeIntOrStringIfPresent(.pullups)
        self.pushups = (try? container.decode(Int.self, forKey: .pushups)) ?? container.decodeIntOrStringIfPresent(.pushups)
        self.squats = (try? container.decode(Int.self, forKey: .squats)) ?? container.decodeIntOrStringIfPresent(.squats)
        self.weight = (try? container.decode(Float.self, forKey: .weight)) ?? container.decodeFloatOrStringIfPresent(.weight)

        self.createDate = try container.decode(Date.self, forKey: .createDate)
        self.modifyDate = try? container.decodeIfPresent(Date.self, forKey: .modifyDate)

        self.photoFront = try container.decodeIfPresent(String.self, forKey: .photoFront)
        self.photoBack = try container.decodeIfPresent(String.self, forKey: .photoBack)
        self.photoSide = try container.decodeIfPresent(String.self, forKey: .photoSide)
    }
}
