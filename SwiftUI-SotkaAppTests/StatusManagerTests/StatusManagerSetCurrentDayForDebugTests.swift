import Foundation
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

extension StatusManagerTests {
    @Suite("Тесты для setCurrentDayForDebug")
    @MainActor
    struct SetCurrentDayForDebugTests {
        @Test("Отклоняет день меньше 1")
        func rejectsDayLessThanOne() async throws {
            let now = Date.now
            let initialStartDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: initialStartDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManager.startNewRun(appDate: initialStartDate)
            let initialCalculator = try #require(statusManager.currentDayCalculator)
            let initialStartDateValue = initialCalculator.startDate

            statusManager.setCurrentDayForDebug(0)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(initialStartDateValue))
        }

        @Test("Отклоняет день больше 100")
        func rejectsDayGreaterThan100() async throws {
            let now = Date.now
            let initialStartDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: initialStartDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManager.startNewRun(appDate: initialStartDate)
            let initialCalculator = try #require(statusManager.currentDayCalculator)
            let initialStartDateValue = initialCalculator.startDate

            statusManager.setCurrentDayForDebug(101)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(initialStartDateValue))
        }

        @Test("Отклоняет отрицательный день")
        func rejectsNegativeDay() async throws {
            let now = Date.now
            let initialStartDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: initialStartDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManager.startNewRun(appDate: initialStartDate)
            let initialCalculator = try #require(statusManager.currentDayCalculator)
            let initialStartDateValue = initialCalculator.startDate

            statusManager.setCurrentDayForDebug(-1)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(initialStartDateValue))
        }

        @Test("Устанавливает валидный день и обновляет startDate", arguments: [1, 25, 50, 75, 100])
        func setsValidDayAndUpdatesStartDate(day: Int) throws {
            let now = Date.now
            let daysToSubtract = day - 1
            let expectedStartDate = try #require(Calendar.current.date(byAdding: .day, value: -daysToSubtract, to: now))
            let statusManager = try MockStatusManager.create()

            statusManager.setCurrentDayForDebug(day)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.currentDay == day)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(expectedStartDate))
        }

        @Test("Обновляет startDate в UserDefaults")
        func updatesStartDateInUserDefaults() throws {
            let userDefaults = try MockUserDefaults.create()
            let statusManager = try MockStatusManager.create(userDefaults: userDefaults)
            let now = Date.now
            let expectedStartDate = try #require(Calendar.current.date(byAdding: .day, value: -49, to: now))

            statusManager.setCurrentDayForDebug(50)

            let key = "WorkoutStartDate"
            let storedTime = userDefaults.double(forKey: key)
            let storedDate = Date(timeIntervalSinceReferenceDate: storedTime)
            #expect(storedDate.isTheSameDayIgnoringTime(expectedStartDate))
        }

        @Test("Обновляет currentDayCalculator после установки дня")
        func updatesCurrentDayCalculator() throws {
            let statusManager = try MockStatusManager.create()

            statusManager.setCurrentDayForDebug(75)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.currentDay == 75)
            #expect(calculator.daysLeft == 25)
        }

        @Test("Обновляет startDate при уже установленной дате")
        func updatesStartDateWhenAlreadySet() async throws {
            let now = Date.now
            let initialStartDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: initialStartDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManager.startNewRun(appDate: initialStartDate)
            let initialCalculator = try #require(statusManager.currentDayCalculator)
            #expect(initialCalculator.currentDay == 31)

            let newDay = 50
            let expectedNewStartDate = try #require(Calendar.current.date(byAdding: .day, value: -(newDay - 1), to: now))
            statusManager.setCurrentDayForDebug(newDay)

            let updatedCalculator = try #require(statusManager.currentDayCalculator)
            #expect(updatedCalculator.currentDay == newDay)
            #expect(updatedCalculator.startDate.isTheSameDayIgnoringTime(expectedNewStartDate))
        }
    }
}
