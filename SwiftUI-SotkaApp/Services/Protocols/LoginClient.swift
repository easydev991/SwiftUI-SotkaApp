protocol LoginClient: Sendable {
    /// Выполняет авторизацию
    /// - Parameter token: Токен авторизации
    /// - Returns: `id` авторизованного пользователя
    func logIn(with token: String?) async throws -> Int

    /// Запрашивает данные пользователя по `id`
    ///
    /// В случае успеха сохраняет данные главного пользователя в `defaults` и авторизует, если еще не авторизован
    /// - Parameters:
    ///   - userID: `id` пользователя
    /// - Returns: вся информация о пользователе
    func getUserByID(_ userID: Int) async throws -> UserResponse

    /// Сбрасывает пароль для неавторизованного пользователя с указанным логином
    /// - Parameter login: `login` пользователя
    func resetPassword(for login: String) async throws
}
