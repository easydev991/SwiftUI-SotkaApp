import Foundation

/// Текущее прохождение программы
struct CurrentRun: Decodable {
    /// Дата начала программы
    ///
    /// `nil`, если пользователь не стартовал сотку
    let date: Date?
}
