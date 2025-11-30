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
        self.date = try container.decodeIfPresent(Date.self, forKey: .date)
        self.maxForAllRunsDay = try? container.decode(Int.self, forKey: .maxForAllRunsDay)
    }

    init(date: Date? = nil, maxForAllRunsDay: Int? = nil) {
        self.date = date
        self.maxForAllRunsDay = maxForAllRunsDay
    }
}
