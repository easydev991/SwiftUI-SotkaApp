import Foundation

enum ProgressPhotoType: Int, Codable, CaseIterable {
    /// Фото спереди
    case front = 1
    /// Фото сзади
    case back = 2
    /// Фото сбоку
    case side = 3

    /// Локализованное название типа фотографии
    var localizedTitle: String {
        switch self {
        case .front:
            NSLocalizedString("PhotoType.front", comment: "Фото спереди")
        case .back:
            NSLocalizedString("PhotoType.back", comment: "Фото сзади")
        case .side:
            NSLocalizedString("PhotoType.side", comment: "Фото сбоку")
        }
    }

    /// Название типа для DELETE запроса
    var requestName: String {
        switch self {
        case .front: "front"
        case .back: "back"
        case .side: "side"
        }
    }
}

extension ProgressPhotoType: CustomStringConvertible {
    var description: String {
        "Тип фотографии: photo_\(requestName)"
    }
}
