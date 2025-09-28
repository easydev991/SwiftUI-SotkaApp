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
