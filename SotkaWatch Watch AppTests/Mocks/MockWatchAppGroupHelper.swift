import Foundation
@testable import SotkaWatch_Watch_App

/// Мок для WatchAppGroupHelper для тестирования
struct MockWatchAppGroupHelper: WatchAppGroupHelperProtocol {
    var isAuthorized: Bool
    var startDate: Date?
    var restTime: Int

    var currentDay: Int? {
        guard let startDate else {
            return nil
        }
        let calculator = DayCalculator(startDate, Date.now)
        return calculator.currentDay
    }

    init(
        isAuthorized: Bool = false,
        startDate: Date? = nil,
        restTime: Int = 60
    ) {
        self.isAuthorized = isAuthorized
        self.startDate = startDate
        self.restTime = restTime
    }
}
