import Foundation

/// Текущее прохождение программы
struct CurrentRunResponse: Decodable {
    /// Дата начала программы
    ///
    /// `nil`, если пользователь не стартовал сотку
    let date: Date?

    /// Максимальный день, до которого доступны инфопосты
    let maxForAllRunsDay: Int?
}
