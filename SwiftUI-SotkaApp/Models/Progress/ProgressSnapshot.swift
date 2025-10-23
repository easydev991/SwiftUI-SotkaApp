import Foundation

/// Снимок локального прогресса для безопасной передачи в конкурентные задачи без доступа к ModelContext
struct ProgressSnapshot: Sendable, Hashable {
    let id: Int
    let pullups: Int?
    let pushups: Int?
    let squats: Int?
    let weight: Float?
    let lastModified: Date
    let isSynced: Bool
    let shouldDelete: Bool
    let userId: Int?
    let photoFront: String?
    let photoBack: String?
    let photoSide: String?
    let dataPhotoFront: Data?
    let dataPhotoBack: Data?
    let dataPhotoSide: Data?

    /// Проверяет, есть ли фотографии для удаления
    var shouldDeletePhoto: Bool {
        isDeletedPhoto(dataPhotoFront) || isDeletedPhoto(dataPhotoBack) || isDeletedPhoto(dataPhotoSide)
    }

    /// Проверяет, является ли данные фотографии помеченными для удаления
    private func isDeletedPhoto(_ data: Data?) -> Bool {
        guard let data else { return false }
        return data == UserProgress.DELETED_DATA
    }

    /// Создает словарь фотографий для отправки на сервер (только не удаленные)
    var photosForUpload: [String: Data] {
        var photos: [String: Data] = [:]

        // Обрабатываем фронтальную фотографию (только если не помечена для удаления)
        if let data = dataPhotoFront, !isDeletedPhoto(data) {
            photos["photo_front"] = data
        }

        // Обрабатываем заднюю фотографию (только если не помечена для удаления)
        if let data = dataPhotoBack, !isDeletedPhoto(data) {
            photos["photo_back"] = data
        }

        // Обрабатываем боковую фотографию (только если не помечена для удаления)
        if let data = dataPhotoSide, !isDeletedPhoto(data) {
            photos["photo_side"] = data
        }

        return photos
    }

    /// Создает ProgressSnapshot из UserProgress модели
    init(from progress: UserProgress) {
        self.id = progress.id
        self.pullups = progress.pullUps
        self.pushups = progress.pushUps
        self.squats = progress.squats
        self.weight = progress.weight
        self.lastModified = progress.lastModified
        self.isSynced = progress.isSynced
        self.shouldDelete = progress.shouldDelete
        self.userId = progress.user?.id
        self.photoFront = progress.urlPhotoFront
        self.photoBack = progress.urlPhotoBack
        self.photoSide = progress.urlPhotoSide
        self.dataPhotoFront = progress.dataPhotoFront
        self.dataPhotoBack = progress.dataPhotoBack
        self.dataPhotoSide = progress.dataPhotoSide
    }
}
