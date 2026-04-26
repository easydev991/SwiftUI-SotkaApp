import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
struct HomeScreenAnalyticsTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("Событие продления хранит целевой totalDays")
    func extendCalendarEventStoresTargetTotalDays() {
        let event = AnalyticsEvent.userAction(action: .extendCalendar(targetTotalDays: 300))
        var capturedTargetTotalDays: Int?

        if case let .userAction(action) = event,
           case let .extendCalendar(targetTotalDays) = action {
            capturedTargetTotalDays = targetTotalDays
        }

        #expect(capturedTargetTotalDays == 300)
    }

    @Test("targetTotalDays вычисляется как следующий блок по 100 дней")
    func nextExtensionTargetTotalDaysIsCalculatedFromCalculator() {
        let startDate = Calendar.current.date(byAdding: .day, value: -199, to: now) ?? now
        let calculator = DayCalculator(startDate, now, extensionCount: 1)
        let targetTotalDays = calculator.nextExtensionTotalDays

        #expect(calculator.currentDay == 200)
        #expect(targetTotalDays == 300)
    }
}
