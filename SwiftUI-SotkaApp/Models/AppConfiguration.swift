import Foundation

enum AppConfiguration {
    /// Глобальный флаг read-only режима.
    ///
    /// Сервер переходит в режим read-only (в том числе без авторизации и регистрации),
    /// поэтому добавлен этот флаг
    /// - `true` — все авторизованные пользователи ведут себя как offline-only
    /// - `false` — нормальная работа
    static let isReadOnlyMode = true
}
