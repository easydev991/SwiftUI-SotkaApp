import Foundation

enum JournalGridPagination {
    static func shouldShowPaginationControls(totalDays: Int) -> Bool {
        totalDays > DayCalculator.baseProgramDays
    }

    static func pageCount(totalDays: Int) -> Int {
        let normalizedTotalDays = max(1, totalDays)
        return max(1, Int(ceil(Double(normalizedTotalDays) / Double(DayCalculator.extensionBlockDays))))
    }

    static func clampPage(_ page: Int, totalDays: Int) -> Int {
        min(max(0, page), pageCount(totalDays: totalDays) - 1)
    }

    static func pageRange(page: Int, totalDays: Int) -> ClosedRange<Int> {
        let normalizedTotalDays = max(1, totalDays)
        let safePage = clampPage(page, totalDays: normalizedTotalDays)
        let startDay = safePage * DayCalculator.extensionBlockDays + 1
        let endDay = min(startDay + DayCalculator.extensionBlockDays - 1, normalizedTotalDays)
        let safeStartDay = min(startDay, endDay)
        return safeStartDay ... endDay
    }

    static func pageTitle(page: Int, totalDays: Int) -> String {
        let range = pageRange(page: page, totalDays: totalDays)
        return "\(range.lowerBound)-\(range.upperBound)"
    }

    static func previousPage(from page: Int, totalDays: Int) -> Int {
        max(0, clampPage(page, totalDays: totalDays) - 1)
    }

    static func nextPage(from page: Int, totalDays: Int) -> Int {
        min(pageCount(totalDays: totalDays) - 1, clampPage(page, totalDays: totalDays) + 1)
    }

    static func makeSections(totalDays: Int, page: Int) -> [JournalSection] {
        let safePage = clampPage(page, totalDays: totalDays)

        if safePage == 0 {
            return JournalSectionsBuilder.make(
                totalDays: min(totalDays, DayCalculator.baseProgramDays),
                sortOrder: .forward
            )
        }

        let range = pageRange(page: safePage, totalDays: totalDays)
        let section = JournalSection(
            title: "\(range.lowerBound)-\(range.upperBound)",
            days: Array(range)
        )
        return [section]
    }

    static func isDayEnabled(day: Int, currentDay: Int) -> Bool {
        day <= currentDay
    }
}
