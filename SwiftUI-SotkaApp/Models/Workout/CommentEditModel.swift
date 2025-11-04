import Foundation

/// Модель для редактирования комментария к активности дня
struct CommentEditModel {
    /// Исходное значение комментария при открытии редактора
    var initialComment: String?

    /// Проверяет, можно ли сохранить комментарий
    /// - Parameter currentComment: Текущее значение комментария
    /// - Returns: `true` если можно сохранить, `false` если нет изменений
    func canSave(_ currentComment: String?) -> Bool {
        let current = currentComment ?? ""
        let original = initialComment ?? ""
        return if original.isEmpty { !current.isEmpty } else { current != original }
    }
}
