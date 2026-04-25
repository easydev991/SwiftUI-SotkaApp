import Foundation

struct HomeDayCountModel {
    let currentDay: Int

    var isFirstProgramCompletionDay: Bool {
        currentDay == DayCalculator.baseProgramDays
    }

    static func formattedDayString(for day: Int) -> String {
        guard day < DayCalculator.baseProgramDays else {
            return String(day)
        }
        return String(format: "%02d", day)
    }
}
