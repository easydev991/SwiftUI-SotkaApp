import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

extension StatusManagerTests {
    @Suite("Тесты для startNewRun")
    @MainActor
    struct StartNewRunTests {
        @Test("Использует дату из ответа сервера, если она есть")
        func startNewRunUsesServerDate() async throws {
            let now = Date.now
            let serverDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let appDate = try #require(Calendar.current.date(byAdding: .day, value: -25, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: serverDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManager.startNewRun(appDate: appDate)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(serverDate))
            #expect(mockStatusClient.startCallCount == 1)
        }

        @Test("Использует appDate, если дата от сервера отсутствует")
        func startNewRunUsesAppDateWhenServerDateNil() async throws {
            let now = Date.now
            let appDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManager.startNewRun(appDate: appDate)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(appDate))
        }

        @Test("Использует Date.now, если appDate == nil")
        func startNewRunUsesCurrentDateWhenAppDateNil() async throws {
            let beforeStart = Date.now
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManager.startNewRun(appDate: nil)

            let afterStart = Date.now
            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate >= beforeStart)
            #expect(calculator.startDate <= afterStart)
        }

        @Test("Продолжает работу при ошибке API")
        func startNewRunContinuesOnAPIError() async throws {
            let now = Date.now
            let appDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let error = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
            let mockStatusClient = MockStatusClient(
                startResult: .failure(error)
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManager.startNewRun(appDate: appDate)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(appDate))
        }

        @Test("Вызывает statusClient.start с ISO строкой даты")
        func startNewRunCallsStatusClientWithISODate() async throws {
            let now = Date.now
            let appDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManager.startNewRun(appDate: appDate)

            let lastStartDate = try #require(mockStatusClient.lastStartDate)
            let expectedDateString = DateFormatterService.stringFromFullDate(appDate, iso: true)
            #expect(lastStartDate == expectedDateString)
        }

        @Test("Обновляет currentDayCalculator с установленной датой")
        func startNewRunUpdatesCurrentDayCalculator() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManager.startNewRun(appDate: nil)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(startDate))
            #expect(calculator.currentDay > 0)
        }
    }
}
