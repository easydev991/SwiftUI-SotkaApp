import Foundation

extension DayCalculator {
    init(previewDay: Int) {
        let currentDay = min(previewDay, 100)
        self.currentDay = currentDay
        self.daysLeft = 100 - currentDay
    }
}
