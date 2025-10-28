import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct HomeScreenModelTests {
    private let now = Date()

    @Test("Должен возвращать nil, если dayCalculator отсутствует")
    func returnsNilWhenDayCalculatorIsNil() {
        let model = HomeScreen.Model(
            currentDay: 1,
            dayCalculator: nil,
            isMaximumsFilled: false,
            todayInfopost: nil
        )
        #expect(model == nil)
    }

    @Test("Должен прокидывать калькулятор и инфопост в модель")
    func passesCalculatorAndInfopost() throws {
        let calculator = DayCalculator(now, now)
        let infopost = Infopost(
            id: "d1",
            title: "День 1. Старт",
            content: "<p>content</p>",
            section: .base,
            dayNumber: 1,
            language: "ru"
        )

        let model = try #require(
            HomeScreen.Model(
                currentDay: 1,
                dayCalculator: calculator,
                isMaximumsFilled: false,
                todayInfopost: infopost
            )
        )

        #expect(model.calculator.currentDay == calculator.currentDay)
        #expect(model.todayInfopost == infopost)
    }

    @Test(
        "Должен показывать секцию активности при текущем дне < 100",
        arguments: [1, 50, 99]
    )
    func showsActivitySectionForDaysBelow100(currentDay: Int) throws {
        let calculator = DayCalculator(now, now)
        let model = try #require(
            HomeScreen.Model(
                currentDay: currentDay,
                dayCalculator: calculator,
                isMaximumsFilled: false,
                todayInfopost: nil
            )
        )
        #expect(model.showActivitySection)
    }

    @Test(
        "Не должен показывать секцию активности при текущем дне >= 100",
        arguments: [100, 150]
    )
    func hidesActivitySectionForDays100AndAbove(currentDay: Int) throws {
        let calculator = DayCalculator(now, now)
        let model = try #require(
            HomeScreen.Model(
                currentDay: currentDay,
                dayCalculator: calculator,
                isMaximumsFilled: false,
                todayInfopost: nil
            )
        )
        #expect(!model.showActivitySection)
    }

    @Test("Должен инвертировать флаг isMaximumsFilled в showProgressSection (true → false)")
    func progressSectionHiddenWhenMaximumsFilled() throws {
        let calculator = DayCalculator(now, now)
        let model = try #require(
            HomeScreen.Model(
                currentDay: 10,
                dayCalculator: calculator,
                isMaximumsFilled: true,
                todayInfopost: nil
            )
        )
        #expect(!model.showProgressSection)
    }

    @Test("Должен инвертировать флаг isMaximumsFilled в showProgressSection (false → true)")
    func progressSectionShownWhenMaximumsNotFilled() throws {
        let calculator = DayCalculator(now, now)
        let model = try #require(
            HomeScreen.Model(
                currentDay: 10,
                dayCalculator: calculator,
                isMaximumsFilled: false,
                todayInfopost: nil
            )
        )
        #expect(model.showProgressSection)
    }
}
