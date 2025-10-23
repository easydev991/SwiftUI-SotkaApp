import Foundation

#warning("TODO: написать тесты для TempPhotoModel")
/// Модель для временной фотографии, пока ее не сохранят в `SwiftData`
struct TempPhotoModel: Identifiable, Equatable {
    let id: String
    let type: ProgressPhotoType
    let urlString: String?
    let data: Data?
    let canBeDeleted: Bool
    let isMarkedForDeletion: Bool

    init(
        type: ProgressPhotoType,
        urlString: String?,
        data: Data?
    ) {
        let isMarkedForDeletion = data == UserProgress.DELETED_DATA
        self.id = type.requestName
        self.type = type
        self.urlString = isMarkedForDeletion ? nil : urlString
        self.data = data
        self.canBeDeleted = !isMarkedForDeletion && (data != nil || urlString != nil)
        self.isMarkedForDeletion = isMarkedForDeletion
    }
}

extension TempPhotoModel: CustomStringConvertible {
    var description: String {
        let typeDescription = type.description
        let urlDescription = "ссылка: \(urlString.map(\.description) ?? "отсутствует")"
        let dataStateDescription = data != nil && data != UserProgress.DELETED_DATA
            ? "данные для картинки есть"
            : "нет данных для картинки"
        let isMarkedForDeletionDescription = isMarkedForDeletion
            ? "картинка помечена на удаление"
            : "картинка не помечена на удаление"
        return [typeDescription, urlDescription, dataStateDescription, isMarkedForDeletionDescription].joined(separator: ", ")
    }
}
