import Foundation
@testable import SwiftUI_SotkaApp

/// Mock клиент для тестирования логики индикатора и других функций инфопостов
struct MockInfopostsClient: InfopostsClient {
    let getReadPostsResult: Result<[Int], Error>
    let setPostReadResult: Result<Void, Error>
    let deleteAllReadPostsResult: Result<Void, Error>
    let setPostReadResultsByDay: [Int: Result<Void, Error>]

    init(
        getReadPostsResult: Result<[Int], Error> = .success([]),
        setPostReadResult: Result<Void, Error> = .success(()),
        deleteAllReadPostsResult: Result<Void, Error> = .success(()),
        setPostReadResultsByDay: [Int: Result<Void, Error>] = [:]
    ) {
        self.getReadPostsResult = getReadPostsResult
        self.setPostReadResult = setPostReadResult
        self.deleteAllReadPostsResult = deleteAllReadPostsResult
        self.setPostReadResultsByDay = setPostReadResultsByDay
    }

    func getReadPosts() async throws -> [Int] {
        switch getReadPostsResult {
        case let .success(days):
            return days
        case let .failure(error):
            throw error
        }
    }

    func setPostRead(day: Int) async throws {
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
