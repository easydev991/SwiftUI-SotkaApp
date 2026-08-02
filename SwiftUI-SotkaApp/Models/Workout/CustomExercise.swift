import Foundation
import SwiftData
import SwiftUI
import SWUtils

/// Модель пользовательского упражнения для хранения в Swift Data
@Model
final class CustomExercise {
    /// Уникальный идентификатор упражнения
    @Attribute(.unique) var id: String
    /// Название упражнения
    var name: String
    /// Номер стандартной картинки упражнения
    var imageId: Int
    /// Дата создания упражнения
    var createDate: Date
    /// Дата последнего изменения упражнения
    var modifyDate: Date

    /// Флаг синхронизации с сервером
    @available(*, deprecated, message: "Sync-флаг, оставлен для стабильности схемы (сервер закрыт 2026-08-01).")
    var isSynced = false
    /// Флаг для удаления с сервера
    var shouldDelete = false

    /// Пользователь, которому принадлежит упражнение
    @Relationship(inverse: \User.customExercises) var user: User?

    init(
        id: String,
        name: String,
        imageId: Int,
        createDate: Date,
        modifyDate: Date,
        user: User? = nil
    ) {
        self.id = id
        self.name = name
        self.imageId = imageId
        self.createDate = createDate
        self.modifyDate = modifyDate
        self.user = user
        // Флаги синхронизации устанавливаются по умолчанию
        self.isSynced = false
        self.shouldDelete = false
    }

    // Инициализатор из ответа сервера
}

extension CustomExercise {
    /// Получает пользовательское упражнение по идентификатору из контекста модели
    /// - Parameters:
    ///   - id: Идентификатор упражнения
    ///   - context: Контекст модели SwiftData
    /// - Returns: Найденное упражнение или `nil`, если не найдено
    static func fetch(by id: String, in context: ModelContext) -> CustomExercise? {
        let descriptor = FetchDescriptor<CustomExercise>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    var image: Image {
        guard let customType = ExerciseType.CustomType(rawValue: imageId) else {
            return Image(systemName: "questionmark.square")
        }
        return customType.image
    }

    /// Преобразование в ExerciseSnapshot для конкурентной синхронизации
    var exerciseSnapshot: ExerciseSnapshot {
        ExerciseSnapshot(
            id: id,
            name: name,
            imageId: imageId,
            createDate: createDate,
            modifyDate: modifyDate,
            isSynced: isSynced,
            shouldDelete: shouldDelete,
            userId: user?.id
        )
    }
}
