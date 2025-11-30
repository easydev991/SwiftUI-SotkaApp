import Foundation

public extension JSONDecoder.DateDecodingStrategy {
    /// Гибкая стратегия декодирования дат
    ///
    /// Поддерживает форматы:
    /// - `2024-01-15T10:30:00Z` (стандартный ISO8601)
    /// - `2024-01-15T10:30:00.123Z` (с дробными секундами)
    /// - `2024-01-15T10:30:00` (server date time без часового пояса)
    /// - `2024-01-15` (ISO short date)
    ///
    /// - Note: Для опциональных полей `Date?` при использовании `decodeIfPresent` null значения обрабатываются автоматически.
    ///   При невалидной строке будет выброшена ошибка декодирования.
    static let flexibleDateDecoding = custom { decoder in
        let container = try decoder.singleValueContainer()

        let string = try container.decode(String.self)

        // Пробуем ISO8601 с дробными секундами
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = iso8601Formatter.date(from: string) {
            return date
        }

        // Пробуем ISO8601 без дробных секунд
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: string) {
            return date
        }

        // Пробуем server date time формат (без часового пояса): yyyy-MM-dd'T'HH:mm:ss
        let serverFormatter = DateFormatter()
        serverFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        serverFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = serverFormatter.date(from: string) {
            return date
        }

        // Пробуем ISO short date формат: yyyy-MM-dd
        let isoShortDateFormatter = DateFormatter()
        isoShortDateFormatter.dateFormat = "yyyy-MM-dd"
        isoShortDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        isoShortDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = isoShortDateFormatter.date(from: string) {
            return date
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Invalid date: \(string)"
            )
        )
    }
}
