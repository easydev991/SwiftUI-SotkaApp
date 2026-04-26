import Foundation
@testable import SwiftUI_SotkaApp

actor MockInfopostsClientRecorder {
    private(set) var getReadPostsCallCount = 0
    private(set) var setPostReadDays: [Int] = []

    func recordGetReadPosts() {
        getReadPostsCallCount += 1
    }

    func recordSetPostRead(day: Int) {
        setPostReadDays.append(day)
    }

    var setPostReadCallCount: Int {
        setPostReadDays.count
    }
}

/// Mock клиент для тестирования логики индикатора и других функций инфопостов
struct MockInfopostsClient: InfopostsClient {
    let getReadPostsResult: Result<[Int], Error>
    let setPostReadResult: Result<Void, Error>
    let deleteAllReadPostsResult: Result<Void, Error>
    let setPostReadResultsByDay: [Int: Result<Void, Error>]
    let recorder: MockInfopostsClientRecorder?

    init(
        getReadPostsResult: Result<[Int], Error> = .success([]),
        setPostReadResult: Result<Void, Error> = .success(()),
        deleteAllReadPostsResult: Result<Void, Error> = .success(()),
        setPostReadResultsByDay: [Int: Result<Void, Error>] = [:],
        recorder: MockInfopostsClientRecorder? = nil
    ) {
        self.getReadPostsResult = getReadPostsResult
        self.setPostReadResult = setPostReadResult
        self.deleteAllReadPostsResult = deleteAllReadPostsResult
        self.setPostReadResultsByDay = setPostReadResultsByDay
        self.recorder = recorder
    }

    func getReadPosts() async throws -> [Int] {
        if let recorder {
            await recorder.recordGetReadPosts()
        }

        switch getReadPostsResult {
        case let .success(days):
            return days
        case let .failure(error):
            throw error
        }
    }

    func setPostRead(day: Int) async throws {
        if let recorder {
            await recorder.recordSetPostRead(day: day)
        }

        // Если есть специфичный результат для этого дня, используем его
        if let specificResult = setPostReadResultsByDay[day] {
            switch specificResult {
            case .success:
                return
            case let .failure(error):
                throw error
            }
        }

        // Иначе используем общий результат
        switch setPostReadResult {
        case .success:
            return
        case let .failure(error):
            throw error
        }
    }

    func deleteAllReadPosts() async throws {
        switch deleteAllReadPostsResult {
        case .success:
            return
        case let .failure(error):
            throw error
        }
    }
}

extension MockInfopostsClient {
    /// Ошибка для тестирования
    enum MockError: Error {
        case serverError
        case syncError
        case networkError
    }
}
