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
            String(localized: .photoTypeFront)
        case .back:
            String(localized: .photoTypeBack)
        case .side:
            String(localized: .photoTypeSide)
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
