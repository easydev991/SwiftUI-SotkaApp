import Foundation
import SwiftData
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
    var isSynced = false
    /// Флаг для удаления с сервера
    var shouldDelete = false
    /// Количество использований упражнения (для сортировки по частоте)
    var usageCount = 0

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
        self.usageCount = 0
    }

    /// Инициализатор из ответа сервера
    convenience init(from response: CustomExerciseResponse, user: User? = nil) {
        let createDate = DateFormatterService.dateFromString(response.createDate, format: .serverDateTimeSec)
        let modifyDate = DateFormatterService.dateFromString(response.modifyDate, format: .serverDateTimeSec)
        self.init(
            id: response.id,
            name: response.name,
            imageId: response.imageId,
            createDate: createDate,
            modifyDate: modifyDate,
            user: user
        )
        // Данные с сервера считаются синхронизированными
        self.isSynced = true
        self.shouldDelete = false
    }
}

import SwiftUI

extension CustomExercise {
    var image: Image {
        guard let customType = ExerciseType.CustomType(rawValue: imageId) else {
            return Image(systemName: "questionmark.square")
        }
        return customType.image
    }
}
