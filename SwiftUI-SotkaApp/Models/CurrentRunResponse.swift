import Foundation
import SWUtils

/// Текущее прохождение программы
struct CurrentRunResponse: Decodable {
    /// Дата начала программы
    ///
    /// `nil`, если пользователь не стартовал сотку
    let date: Date?

    /// Максимальный день, до которого доступны инфопосты
    let maxForAllRunsDay: Int?

    enum CodingKeys: String, CodingKey {
        case date
        case maxForAllRunsDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.date = container.decodeISO8601DateIfPresent(.date)
        self.maxForAllRunsDay = container.decodeIntOrNilIfPresent(.maxForAllRunsDay)
    }

    init(date: Date? = nil, maxForAllRunsDay: Int? = nil) {
        self.date = date
        self.maxForAllRunsDay = maxForAllRunsDay
    }
}
