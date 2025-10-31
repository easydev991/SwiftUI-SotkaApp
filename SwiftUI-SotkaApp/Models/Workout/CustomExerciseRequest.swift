import Foundation

/// Модель запроса для создания/обновления пользовательского упражнения
struct CustomExerciseRequest: Codable, Sendable {
    /// Уникальный идентификатор упражнения
    let id: String
    /// Название упражнения
    let name: String
    /// ID иконки упражнения
    let imageId: Int
    /// Дата создания упражнения (ISO формат)
    let createDate: String
    /// Дата изменения упражнения (ISO формат, опционально)
    let modifyDate: String?
    /// Скрыто ли упражнение
    let isHidden: Bool

    /// Инициализатор для создания нового упражнения
    /// - Parameters:
    ///   - id: Идентификатор упражнения
    ///   - name: Название упражнения
    ///   - imageId: ID иконки
    ///   - createDate: Дата создания
    init(
        id: String,
        name: String,
        imageId: Int,
        createDate: String
    ) {
        self.id = id
        self.name = name
        self.imageId = imageId
        self.createDate = createDate
        self.modifyDate = nil
        self.isHidden = false
    }

    /// Инициализатор для обновления существующего упражнения
    /// - Parameters:
    ///   - id: Идентификатор упражнения
    ///   - name: Название упражнения
    ///   - imageId: ID иконки
    ///   - createDate: Дата создания
    ///   - modifyDate: Дата изменения
    ///   - isHidden: Скрыто ли упражнение
    init(
        id: String,
        name: String,
        imageId: Int,
        createDate: String,
        modifyDate: String,
        isHidden: Bool = false
    ) {
        self.id = id
        self.name = name
        self.imageId = imageId
        self.createDate = createDate
        self.modifyDate = modifyDate
        self.isHidden = isHidden
    }
}

extension CustomExerciseRequest {
    /// Параметры формы для отправки на сервер (application/x-www-form-urlencoded)
    var formParameters: [String: String] {
        var parameters: [String: String] = [
            "id": id,
            "name": name,
            "image_id": String(imageId),
            "create_date": createDate,
            "is_hidden": String(isHidden)
        ]

        if let modifyDate {
            parameters["modify_date"] = modifyDate
        }

        return parameters
    }
}
