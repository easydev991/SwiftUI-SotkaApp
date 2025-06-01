import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct DayCalculatorTests {
    private let calendar = Calendar.current
    private let now = Date.now

    @Test
    func initializesWithValidDates() throws {
        let startDate = calendar.date(byAdding: .day, value: -5, to: now)
        let endDate = now
        let calculator = try #require(DayCalculator(startDate, endDate))
        #expect(calculator.currentDay == 6)
        #expect(calculator.daysLeft == 94)
        #expect(!calculator.isOver)
    }

    @Test
    func handlesNilStartDate() {
        #expect(DayCalculator(nil, now) == nil)
    }

    @Test
    func calculatesMaxCurrentDay() throws {
        let startDate = calendar.date(byAdding: .day, value: -150, to: now)
        let endDate = now

        let calculator = try #require(DayCalculator(startDate, endDate))
        #expect(calculator.currentDay == 100)
        #expect(calculator.daysLeft == 0)
        #expect(calculator.isOver)
    }

    @Test
    func calculatesEdgeDays() throws {
        // Case 1: 0 days between
        let date = now
        let calculator1 = DayCalculator(date, date)
        #expect(calculator1.daysLeft == 99)

        // Case 2: Max days
        let futureDate = try #require(calendar.date(byAdding: .day, value: 100, to: date))
        let calculator2 = DayCalculator(date, futureDate)
        #expect(calculator2.daysLeft == 0)
    }

    @Test
    func verifiesProgramCompletion() throws {
        let startDate = calendar.date(byAdding: .day, value: -99, to: now)
        let endDate = now
        let calculator = try #require(DayCalculator(startDate, endDate))
        #expect(calculator.isOver)
    }
}
