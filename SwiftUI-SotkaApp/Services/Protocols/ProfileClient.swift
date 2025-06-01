import Foundation

protocol ProfileClient: Sendable {
    /// Изменяет данные пользователя
    /// - Parameters:
    ///   - id: `id` пользователя
    ///   - model: данные для изменения
    /// - Returns: Актуальные данные пользователя
    func editUser(_ id: Int, model: MainUserForm) async throws -> UserResponse

    /// Меняет текущий пароль на новый
    /// - Parameters:
    ///   - current: текущий пароль
    ///   - new: новый пароль
    func changePassword(current: String, new: String) async throws
}
