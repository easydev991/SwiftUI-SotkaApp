import Foundation

extension DayCalculator {
    init(previewDay: Int, extensionCount: Int = 0) {
        let normalizedExtensionCount = max(0, min(extensionCount, Self.maxExtensionCount))
        let totalDays = Self.baseProgramDays + normalizedExtensionCount * Self.extensionBlockDays
        let currentDay = min(max(1, previewDay), totalDays)

        self.extensionCount = normalizedExtensionCount
        self.currentDay = currentDay
        self.daysLeft = max(0, totalDays - currentDay)
        self.startDate = .now
    }
}
