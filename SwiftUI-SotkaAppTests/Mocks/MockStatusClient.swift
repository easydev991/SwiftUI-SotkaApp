import Foundation
@testable import SwiftUI_SotkaApp
import SWUtils

actor AsyncTestGate {
    private var didArrive = false
    private var isReleased = false
    private var arrivalContinuations: [CheckedContinuation<Void, Never>] = []
    private var releaseContinuations: [CheckedContinuation<Void, Never>] = []

    func arriveAndWait() async {
        didArrive = true

        let continuations = arrivalContinuations
        arrivalContinuations.removeAll()
        continuations.forEach { $0.resume() }

        guard !isReleased else { return }

        await withCheckedContinuation { continuation in
            releaseContinuations.append(continuation)
        }
    }

    func waitUntilArrived() async {
        guard !didArrive else { return }

        await withCheckedContinuation { continuation in
            arrivalContinuations.append(continuation)
        }
    }

    func release() {
        isReleased = true

        let continuations = releaseContinuations
        releaseContinuations.removeAll()
        continuations.forEach { $0.resume() }
    }
}

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

    /// Управляемая точка остановки для метода start
    var startGate: AsyncTestGate?

    /// Управляемая точка остановки для метода current
    var currentGate: AsyncTestGate?

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

        if let startGate {
            await startGate.arriveAndWait()
        }

        switch startResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    func current() async throws -> CurrentRunResponse {
        currentCallCount += 1

        if let currentGate {
            await currentGate.arriveAndWait()
        }

        switch currentResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}

extension MockStatusClient {
    /// Ошибка для тестирования
    enum MockError: Error {
        case demoError
    }
}
