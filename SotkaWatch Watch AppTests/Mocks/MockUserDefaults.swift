import Foundation

/// Мок для UserDefaults для тестирования
///
/// Создает изолированный UserDefaults для каждого теста, чтобы избежать конфликтов между тестами
enum MockUserDefaults {
    /// Ошибка создания изолированного UserDefaults
    enum Error: Swift.Error {
        case failedToCreateUserDefaults
    }

    /// Создает новый изолированный UserDefaults для тестирования
    /// - Returns: Изолированный UserDefaults
    /// - Throws: `Error.failedToCreateUserDefaults` если не удалось создать UserDefaults
    static func create() throws -> UserDefaults {
        let suiteName = UUID().uuidString
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw Error.failedToCreateUserDefaults
        }
        return userDefaults
    }
}
