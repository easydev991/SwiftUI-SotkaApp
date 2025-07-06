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

    init(
        id: String,
        name: String,
        imageId: Int,
        createDate: Date,
        modifyDate: Date
    ) {
        self.id = id
        self.name = name
        self.imageId = imageId
        self.createDate = createDate
        self.modifyDate = modifyDate
    }

    /// Инициализатор из ответа сервера
    convenience init(from response: CustomExerciseResponse) {
        let createDate = DateFormatterService.dateFromString(response.createDate, format: .serverDateTimeSec)
        let modifyDate = DateFormatterService.dateFromString(response.modifyDate, format: .serverDateTimeSec)
        self.init(
            id: response.id,
            name: response.name,
            imageId: response.imageId,
            createDate: createDate,
            modifyDate: modifyDate
        )
    }
}
