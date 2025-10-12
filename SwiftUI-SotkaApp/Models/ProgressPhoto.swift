import Foundation
import SwiftData

@Model
final class ProgressPhoto {
    var type: PhotoType
    var data: Data?
    var urlString: String?
    var isSynced: Bool
    var isDeleted: Bool
    var lastModified: Date
    @Relationship var progress: Progress?

    init(type: PhotoType, data: Data? = nil, urlString: String? = nil) {
        self.type = type
        self.data = data
        self.urlString = urlString
        self.isSynced = false
        self.isDeleted = false
        self.lastModified = Date()
    }
}

enum PhotoType: Int, Codable, CaseIterable {
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
}
