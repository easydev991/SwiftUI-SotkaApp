import Foundation

public extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var isThisYear: Bool {
        Calendar.current.compare(Date.now, to: self, toGranularity: .year) == .orderedSame
    }
}

public extension Date {
    /// Cравнивает даты, игнорируя время (часы, минуты и секунды)
    ///
    /// Используется для синхронизации данных сотки
    /// - Parameter date: Дата, с которой нужно выполнить сравнение
    /// - Returns: `true` - даты совпадают, `false` - даты не совпадают
    func isTheSameDayIgnoringTime(_ date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .day)
    }
}
