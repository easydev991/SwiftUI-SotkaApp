import Foundation

public enum DateFormatterService {
    /// Конвертирует строку в дату
    ///
    /// Возвращает `.now` для невалидной строки
    public static func dateFromString(
        _ string: String?,
        format: DateFormat,
        timeZone: TimeZone? = nil
    ) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = format.rawValue
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string ?? "") ?? .now
    }

    /// Форматирует дату в читаемый формат с днём недели
    /// - Parameters:
    ///   - date: Дата для форматирования
    ///   - locale: Локаль для форматирования (по умолчанию текущая локаль системы)
    /// - Returns: Отформатированная строка в формате "d MMM yyyy (EEEE)" или аналогичном для текущей локали
    public static func dateWithWeekday(
        _ date: Date,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        // Форматируем дату: день, месяц, год
        formatter.dateFormat = DateFormat.dayMonthYear.rawValue
        let datePart = formatter.string(from: date)
        // Форматируем день недели
        formatter.dateFormat = "EEEE"
        let weekdayPart = formatter.string(from: date)
        return "\(datePart) (\(weekdayPart))"
    }
}

public extension DateFormatterService {
    enum DateFormat: String {
        case isoShortDate = "yyyy-MM-dd"
        case serverDateTimeSec = "yyyy-MM-dd'T'HH:mm:ss"
        case isoDateTimeSec = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        case dayMonthYear = "d MMM yyyy"
    }
}
