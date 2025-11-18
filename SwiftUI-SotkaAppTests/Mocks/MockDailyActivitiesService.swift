import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp

/// Мок для DailyActivitiesService для тестирования ViewModel
final class MockDailyActivitiesService {
    /// Счетчик вызовов createDailyActivity
    var createDailyActivityCallCount = 0

    /// Последняя переданная активность
    var lastActivity: DayActivity?

    /// Последний переданный контекст
    var lastContext: ModelContext?

    /// Флаг для имитации ошибок
    var shouldThrowError = false

    /// Кастомная ошибка для выброса
    var errorToThrow: Error = MockDailyActivitiesService.MockError.demoError

    /// Массив всех вызовов createDailyActivity
    var createDailyActivityCalls: [(activity: DayActivity, context: ModelContext)] = []

    /// Сброс всех счетчиков и состояний
    func reset() {
        createDailyActivityCallCount = 0
        lastActivity = nil
        lastContext = nil
        shouldThrowError = false
        createDailyActivityCalls.removeAll()
    }
}

extension MockDailyActivitiesService {
    /// Имитация метода createDailyActivity из DailyActivitiesService
    @MainActor
    func createDailyActivity(_ activity: DayActivity, context: ModelContext) {
        createDailyActivityCallCount += 1
        lastActivity = activity
        lastContext = context
        createDailyActivityCalls.append((activity, context))

        if shouldThrowError {
            // В реальном сервисе ошибки обрабатываются внутри, но для тестов мы можем проверить факт вызова
        }
    }
}

extension MockDailyActivitiesService {
    /// Ошибка для тестирования
    enum MockError: Error {
        case demoError
    }
}
