import Foundation
@testable import SotkaWatch_Watch_App

/// Мок для WatchConnectivityService для тестирования
@MainActor
final class MockWatchConnectivityService: WatchConnectivityServiceProtocol {
    var shouldSucceed = true
    var mockError: Error?
    var mockCurrentActivity: DayActivityType?
    var mockWorkoutData: WorkoutData?

    private(set) var sentActivityType: (day: Int, activityType: DayActivityType)?
    private(set) var requestedCurrentActivityDay: Int?
    private(set) var requestedWorkoutDataDay: Int?
    private(set) var sentWorkoutResult: (day: Int, result: WorkoutResult, executionType: ExerciseExecutionType)?
    private(set) var deletedActivityDay: Int?

    func sendActivityType(day: Int, activityType: DayActivityType) async throws {
        sentActivityType = (day, activityType)
        if !shouldSucceed {
            throw mockError ?? WatchConnectivityError.sessionUnavailable
        }
    }

    func requestCurrentActivity(day: Int) async throws -> DayActivityType? {
        requestedCurrentActivityDay = day
        if !shouldSucceed {
            throw mockError ?? WatchConnectivityError.sessionUnavailable
        }
        return mockCurrentActivity
    }

    func requestWorkoutData(day: Int) async throws -> WorkoutData {
        requestedWorkoutDataDay = day
        if !shouldSucceed {
            throw mockError ?? WatchConnectivityError.sessionUnavailable
        }
        guard let mockWorkoutData else {
            throw WatchConnectivityError.invalidResponse
        }
        return mockWorkoutData
    }

    func sendWorkoutResult(day: Int, result: WorkoutResult, executionType: ExerciseExecutionType) async throws {
        sentWorkoutResult = (day, result, executionType)
        if !shouldSucceed {
            throw mockError ?? WatchConnectivityError.sessionUnavailable
        }
    }

    func deleteActivity(day: Int) async throws {
        deletedActivityDay = day
        if !shouldSucceed {
            throw mockError ?? WatchConnectivityError.sessionUnavailable
        }
    }
}
