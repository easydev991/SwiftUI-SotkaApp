import Foundation
@testable import SWUtils
import Testing

struct DateFormatterServiceTests {
    @Test
    func dateFromString_isoShortDate() throws {
        var utcCalendar = Calendar(identifier: .iso8601)
        utcCalendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let components = DateComponents(
            year: 1992,
            month: 8,
            day: 12,
            hour: 0,
            minute: 0,
            second: 0
        )
        let expectedDate = try #require(utcCalendar.date(from: components))
        let formattedResult = DateFormatterService.dateFromString(
            "1992-08-12",
            format: .isoShortDate,
            timeZone: TimeZone(secondsFromGMT: 0)
        )
        #expect(utcCalendar.isDate(formattedResult, equalTo: expectedDate, toGranularity: .second))
    }
}
