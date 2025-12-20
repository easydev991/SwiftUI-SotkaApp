import Foundation
import Observation

@MainActor
@Observable
final class PreviewWatchAuthService: WatchAuthServiceProtocol {
    var isAuthorized: Bool

    init(isAuthorized: Bool = false) {
        self.isAuthorized = isAuthorized
    }

    func checkAuthStatus() -> Bool {
        isAuthorized
    }

    func updateAuthStatus(_ isAuthorized: Bool) {
        self.isAuthorized = isAuthorized
    }
}

@MainActor
final class PreviewWatchConnectivityService: WatchConnectivityServiceProtocol {
    var currentDay: Int?
    var currentActivity: DayActivityType?

    init(currentDay: Int? = 5, currentActivity: DayActivityType? = .workout) {
        self.currentDay = currentDay
        self.currentActivity = currentActivity
    }

    func sendActivityType(day _: Int, activityType _: DayActivityType) async throws {
        print("Заглушка sendActivityType")
    }

    func requestCurrentActivity(day _: Int) async throws -> DayActivityType? {
        .workout
    }

    func requestWorkoutData(day: Int) async throws -> WorkoutDataResponse {
        WorkoutDataResponse(
            workoutData: .init(
                day: day,
                executionType: 0,
                trainings: .previewSets,
                plannedCount: 4
            ),
            executionCount: nil,
            comment: nil
        )
    }

    func sendWorkoutResult(day _: Int, result _: WorkoutResult, executionType _: ExerciseExecutionType, comment _: String?) async throws {
        print("Заглушка sendWorkoutResult")
    }

    func deleteActivity(day _: Int) async throws {
        print("Заглушка deleteActivity")
    }
}
