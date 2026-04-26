import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
struct HomeScreenTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("На 100-м дне кнопка продления доступна")
    func extensionButtonIsAvailableOnDay100() throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -99, to: now) ?? now
        let calculator = DayCalculator(startDate, now, extensionCount: 0)
        let model = try #require(
            HomeScreen.Model(
                currentDay: calculator.currentDay,
                dayCalculator: calculator,
                isMaximumsFilled: false,
                todayInfopost: nil
            )
        )
        let shouldShowExtensionButton = model.calculator.shouldShowExtensionButton

        #expect(shouldShowExtensionButton)
    }

    @Test("После продления на 101-м дне кнопка скрыта до следующей границы")
    func extensionButtonIsHiddenOnDay101AfterFirstExtension() throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -100, to: now) ?? now
        let calculator = DayCalculator(startDate, now, extensionCount: 1)
        let model = try #require(
            HomeScreen.Model(
                currentDay: calculator.currentDay,
                dayCalculator: calculator,
                isMaximumsFilled: false,
                todayInfopost: nil
            )
        )
        let currentDay = model.calculator.currentDay
        let shouldShowExtensionButton = model.calculator.shouldShowExtensionButton

        #expect(currentDay == 101)
        #expect(!shouldShowExtensionButton)
    }
}
