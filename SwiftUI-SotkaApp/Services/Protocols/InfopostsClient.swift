import Foundation

/// Протокол для работы с инфопостами на сервере
protocol InfopostsClient: Sendable {
    /// Получить список прочитанных дней инфопостов
    func getReadPosts() async throws -> [Int]

    /// Отметить инфопост как прочитанный
    /// - Parameter day: День инфопоста
    func setPostRead(day: Int) async throws

    /// Удалить все прочитанные инфопосты
    ///
    /// Только для отладки и тестирования
    func deleteAllReadPosts() async throws
}
