import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct DayCalculatorTests {
    private let calendar = Calendar(identifier: .iso8601)

    @Test("Обработка nil стартовой даты")
    func handlesNilStartDate() {
        #expect(DayCalculator(nil, .now, extensionCount: 0) == nil)
    }

    @Test("День 1 без продлений")
    func calculatesDayOneWithoutExtensions() {
        let now = Date.now
        let calculator = DayCalculator(now, now, extensionCount: 0)

        #expect(calculator.currentDay == 1)
        #expect(calculator.daysLeft == 99)
        #expect(calculator.totalDays == 100)
        #expect(!calculator.shouldShowExtensionButton)
        #expect(!calculator.isOver)
    }

    @Test("День 100 без продлений")
    func showsExtensionOnDayHundredWithoutExtensions() throws {
        let now = Date.now
        let startDate = try makeDate(byAddingDays: -99, to: now)
        let calculator = DayCalculator(startDate, now, extensionCount: 0)

        #expect(calculator.currentDay == 100)
        #expect(calculator.daysLeft == 0)
        #expect(calculator.totalDays == 100)
        #expect(calculator.shouldShowExtensionButton)
        #expect(calculator.isOver)
    }

    @Test("День 100 с одним продлением")
    func extendsToTwoHundredDaysAtBoundary() throws {
        let now = Date.now
        let startDate = try makeDate(byAddingDays: -99, to: now)
        let calculator = DayCalculator(startDate, now, extensionCount: 1)

        #expect(calculator.currentDay == 100)
        #expect(calculator.totalDays == 200)
        #expect(calculator.daysLeft == 100)
        #expect(!calculator.shouldShowExtensionButton)
        #expect(!calculator.isOver)
    }

    @Test("Отложенное продление догоняет текущий день")
    func delayedExtensionCatchesUpCurrentDay() throws {
        let now = Date.now
        let startDate = try makeDate(byAddingDays: -129, to: now)

        let beforeExtension = DayCalculator(startDate, now, extensionCount: 0)
        #expect(beforeExtension.currentDay == 100)
        #expect(beforeExtension.totalDays == 100)

        let afterExtension = DayCalculator(startDate, now, extensionCount: 1)
        #expect(afterExtension.currentDay == 130)
        #expect(afterExtension.totalDays == 200)
        #expect(afterExtension.daysLeft == 70)
    }

    @Test("День 150 в блоке 200 дней")
    func calculatesDayOneHundredFiftyWithOneExtension() throws {
        let now = Date.now
        let startDate = try makeDate(byAddingDays: -149, to: now)
        let calculator = DayCalculator(startDate, now, extensionCount: 1)

        #expect(calculator.currentDay == 150)
        #expect(calculator.daysLeft == 50)
        #expect(calculator.totalDays == 200)
    }

    @Test("Граница 200 дней с одним продлением")
    func marksOverAtTwoHundredBoundaryWithoutSecondExtension() throws {
        let now = Date.now
        let startDate = try makeDate(byAddingDays: -199, to: now)
        let calculator = DayCalculator(startDate, now, extensionCount: 1)

        #expect(calculator.currentDay == 200)
        #expect(calculator.daysLeft == 0)
        #expect(calculator.shouldShowExtensionButton)
        #expect(calculator.isOver)
    }

    @Test("Старт в будущем с продлением")
    func futureStartUsesTotalDaysForDaysLeft() throws {
        let now = Date.now
        let startDate = try makeDate(byAddingDays: 5, to: now)
        let calculator = DayCalculator(startDate, now, extensionCount: 1)

        #expect(calculator.currentDay == 1)
        #expect(calculator.totalDays == 200)
        #expect(calculator.daysLeft == 199)
    }

    @Test("Лимит продлений: кнопка скрыта на верхней границе")
    func hidesExtensionButtonAtMaxExtensionLimit() throws {
        let now = Date.now
        let startDate = try makeDate(byAddingDays: -10_099, to: now)
        let calculator = DayCalculator(startDate, now, extensionCount: 100)

        #expect(calculator.currentDay == 10_100)
        #expect(calculator.totalDays == 10_100)
        #expect(calculator.daysLeft == 0)
        #expect(!calculator.shouldShowExtensionButton)
        #expect(calculator.isOver)
    }

    @Test("extensionCount > лимита нормализуется")
    func normalizesExtensionCountAboveMax() {
        let now = Date.now
        let calculator = DayCalculator(now, now, extensionCount: 101)

        #expect(calculator.normalizedExtensionCount == 100)
        #expect(calculator.totalDays == 10_100)
        #expect(!calculator.shouldShowExtensionButton)
    }

    @Test("id меняется при изменении daysLeft")
    func idChangesWhenDaysLeftChanges() throws {
        let now = Date.now
        let startDate = try makeDate(byAddingDays: -99, to: now)
        let beforeExtension = DayCalculator(startDate, now, extensionCount: 0)
        let afterExtension = DayCalculator(startDate, now, extensionCount: 1)

        #expect(beforeExtension.id != afterExtension.id)
    }

    @Test("nextExtensionTotalDays считает targetTotalDays для следующего продления")
    func calculatesNextExtensionTotalDays() {
        let now = Date.now

        let withoutExtensions = DayCalculator(now, now, extensionCount: 0)
        #expect(withoutExtensions.nextExtensionTotalDays == 200)

        let withOneExtension = DayCalculator(now, now, extensionCount: 1)
        #expect(withOneExtension.nextExtensionTotalDays == 300)
    }

    @Test("nextExtensionTotalDays ограничен maxExtensionCount")
    func capsNextExtensionTotalDaysAtMax() {
        let now = Date.now
        let calculator = DayCalculator(now, now, extensionCount: 100)

        #expect(calculator.nextExtensionTotalDays == 10_100)
    }

    private func makeDate(byAddingDays days: Int, to date: Date) throws -> Date {
        try #require(calendar.date(byAdding: .day, value: days, to: date))
    }
}
