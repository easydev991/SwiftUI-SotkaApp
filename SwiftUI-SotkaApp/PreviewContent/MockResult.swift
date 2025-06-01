import Foundation

/// Результат-заглушка для мок-сервисов
enum MockResult {
    case success
    case failure(error: Error = MockError())
}

extension MockResult {
    struct MockError: Error {}
}
