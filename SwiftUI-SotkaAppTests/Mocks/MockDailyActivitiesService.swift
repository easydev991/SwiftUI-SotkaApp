import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp

/// Мок для DailyActivitiesService для тестирования ViewModel и WatchConnectivityManager
final class MockDailyActivitiesService {
    /// Счетчик вызовов createDailyActivity
    var createDailyActivityCallCount = 0

    /// Последняя переданная активность
    var lastActivity: DayActivity?

    /// Последний переданный контекст
    var lastContext: ModelContext?

    /// Счетчик вызовов set
    var setCallCount = 0

    /// Последние переданные параметры set
    var lastSetActivityType: DayActivityType?
    var lastSetDay: Int?
    var lastSetContext: ModelContext?

    /// Массив всех вызовов set
    var setCalls: [(activityType: DayActivityType, day: Int, context: ModelContext)] = []

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
        setCallCount = 0
        lastSetActivityType = nil
        lastSetDay = nil
        lastSetContext = nil
        setCalls.removeAll()
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

    /// Имитация метода set из DailyActivitiesService
    @MainActor
    func set(_ activityType: DayActivityType, for day: Int, context: ModelContext) {
        setCallCount += 1
        lastSetActivityType = activityType
        lastSetDay = day
        lastSetContext = context
        setCalls.append((activityType, day, context))

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
