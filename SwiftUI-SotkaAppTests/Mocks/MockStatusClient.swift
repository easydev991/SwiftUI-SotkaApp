import Foundation
@testable import SwiftUI_SotkaApp
import SWUtils

/// Мок для StatusClient для тестирования
final class MockStatusClient: StatusClient, @unchecked Sendable {
    /// Результат для метода start
    var startResult: Result<CurrentRunResponse, Error> = .success(
        CurrentRunResponse(date: Date.now, maxForAllRunsDay: nil)
    )

    /// Результат для метода current
    var currentResult: Result<CurrentRunResponse, Error> = .success(
        CurrentRunResponse(date: Date.now, maxForAllRunsDay: nil)
    )

    /// Инициализатор для создания мока с кастомными результатами
    init(
        startResult: Result<CurrentRunResponse, Error>? = nil,
        currentResult: Result<CurrentRunResponse, Error>? = nil
    ) {
        if let startResult {
            self.startResult = startResult
        }
        if let currentResult {
            self.currentResult = currentResult
        }
    }

    /// Счетчики вызовов методов
    var startCallCount = 0
    var currentCallCount = 0

    /// Последний переданный параметр date в start
    var lastStartDate: String?

    /// Массив всех вызовов start
    var startCalls: [String] = []

    func start(date: String) async throws -> CurrentRunResponse {
        startCallCount += 1
        lastStartDate = date
        startCalls.append(date)

        switch startResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    func current() async throws -> CurrentRunResponse {
        currentCallCount += 1

        switch currentResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    /// Сброс всех счетчиков и состояний
    func reset() {
        startCallCount = 0
        currentCallCount = 0
        lastStartDate = nil
        startCalls.removeAll()
        startResult = .success(CurrentRunResponse(date: Date.now, maxForAllRunsDay: nil))
        currentResult = .success(CurrentRunResponse(date: Date.now, maxForAllRunsDay: nil))
    }
}
